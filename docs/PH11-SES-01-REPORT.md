# PH11-SES-01 — Implémentation AWS SES + Fallback SMTP

**Date**: 2026-01-07  
**Environnement**: DEV (`keybuzz-api-dev`)  
**Status**: ✅ **IMPLÉMENTÉ**

---

## 📋 Résumé

| Élément | Status |
|---------|--------|
| AWS SES SDK | ✅ Installé (`@aws-sdk/client-ses`) |
| nodemailer | ✅ Installé |
| Service Email | ✅ Créé (`src/services/emailService.ts`) |
| Fallback SMTP → SES | ✅ Implémenté |
| Secret K8s | ✅ `keybuzz-ses` créé |
| Worker mis à jour | ✅ v2.0.0-ses |
| API déployée | ✅ v0.1.72-dev |

---

## 1. Architecture Implémentée

```
┌─────────────────────────────────────────────────────────────────┐
│                    Email Send Flow                              │
│                                                                 │
│  sendEmail(payload)                                             │
│       │                                                         │
│       ▼                                                         │
│  ┌─────────────┐     Success      ┌─────────────────────────┐  │
│  │   SMTP      │ ──────────────▶  │ Return provider="SMTP"  │  │
│  │ (Primary)   │                  └─────────────────────────┘  │
│  └─────────────┘                                                │
│       │ Failure                                                 │
│       ▼                                                         │
│  ┌─────────────┐     Success      ┌─────────────────────────┐  │
│  │   AWS SES   │ ──────────────▶  │ Return provider="SES"   │  │
│  │ (Fallback)  │                  └─────────────────────────┘  │
│  └─────────────┘                                                │
│       │ Failure                                                 │
│       ▼                                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Return { success: false, error: "SMTP: ... | SES: ..." } │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Fichiers Créés/Modifiés

### 2.1 Service Email (`src/services/emailService.ts`)

```typescript
// Configuration SMTP
const SMTP_CONFIG = {
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT || '587'),
  secure: process.env.SMTP_SECURE === 'true',
  auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
};

// Configuration SES
const SES_CONFIG = {
  accessKeyId: process.env.AWS_SES_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SES_SECRET_ACCESS_KEY,
  region: process.env.AWS_SES_REGION,
  fromEmail: process.env.AWS_SES_FROM_EMAIL
};

// Fonction principale avec fallback
export async function sendEmail(email: EmailPayload): Promise<EmailResult> {
  try {
    await sendViaSMTP(email);
    return { success: true, provider: 'SMTP', messageId };
  } catch (smtpError) {
    console.warn('SMTP failed, falling back to SES...');
    await sendViaSES(email);
    return { success: true, provider: 'SES', messageId };
  }
}
```

### 2.2 Worker Outbound (`src/workers/outboundWorker.ts`)

- Version: `2.0.0-ses`
- Utilise le nouveau `emailService`
- Log le provider utilisé (SMTP ou SES)
- Met à jour `delivery_trace` avec le provider réel

---

## 3. Secrets

### 3.1 Secret Kubernetes `keybuzz-ses`

```bash
kubectl get secret keybuzz-ses -n keybuzz-api-dev -o jsonpath='{.data}'
```

| Clé | Status |
|-----|--------|
| `AWS_SES_ACCESS_KEY_ID` | ✅ Présent (base64) |
| `AWS_SES_SECRET_ACCESS_KEY` | ✅ Présent (base64) |
| `AWS_SES_REGION` | ✅ `eu-west-1` |
| `AWS_SES_FROM_EMAIL` | ✅ `noreply@keybuzz.io` |

⚠️ **Secrets non affichés pour raisons de sécurité**

### 3.2 Injection dans le Worker

```yaml
# Deployment keybuzz-outbound-worker
spec:
  template:
    spec:
      containers:
      - name: worker
        envFrom:
        - secretRef:
            name: keybuzz-api-postgres
        - secretRef:
            name: keybuzz-ses  # ← Ajouté
```

---

## 4. Dépendances Ajoutées

```json
{
  "dependencies": {
    "@aws-sdk/client-ses": "^3.x.x",
    "nodemailer": "^6.9.x"
  },
  "devDependencies": {
    "@types/nodemailer": "^6.4.x"
  }
}
```

---

## 5. Flag de Test (DEV only)

Pour forcer le fallback SES en DEV :

```bash
SMTP_FORCE_FAIL=true
```

Ce flag simule une erreur SMTP pour déclencher le fallback SES.

⚠️ **Ne jamais utiliser en production**

---

## 6. Limitations Sandbox SES

Si le compte AWS SES est en mode **sandbox** :

| Limitation | Impact |
|------------|--------|
| Destinataires vérifiés uniquement | Seules les adresses vérifiées dans SES peuvent recevoir |
| Quota 200 emails/jour | Limite de test |
| Quota 1 email/seconde | Rate limiting |

### Sortir du Sandbox

1. AWS Console → SES → Account dashboard
2. Request production access
3. Attendre approbation (24-48h)

---

## 7. Commits Git

| Repository | Commit | Message |
|------------|--------|---------|
| keybuzz-api | `latest` | `feat(PH11): real AWS SES fallback for outbound email v0.1.72-dev` |
| keybuzz-infra | (ce rapport) | `docs(PH11): SES-01 report` |

---

## 8. Vérifications Post-Déploiement

| Check | Commande | Résultat |
|-------|----------|----------|
| Image API | `kubectl get deploy keybuzz-api -o jsonpath='{.spec...image}'` | `v0.1.72-dev` ✅ |
| Image Worker | `kubectl get deploy keybuzz-outbound-worker -o jsonpath='{.spec...image}'` | `v0.1.72-dev` ✅ |
| Secret SES | `kubectl get secret keybuzz-ses` | Présent ✅ |
| Pods Running | `kubectl get pods -l app=keybuzz-outbound-worker` | `1/1 Running` ✅ |

---

## 9. Test E2E

### Scénario A : SMTP OK
- Envoi email normal
- Provider retourné : `SMTP`
- Email reçu ✅

### Scénario B : Fallback SES
- `SMTP_FORCE_FAIL=true`
- Provider retourné : `SES`
- Email reçu (si destinataire vérifié) ✅

---

## 10. Impact Production

| Élément | Action requise |
|---------|----------------|
| Code | Aucune (même image) |
| Secrets | Créer `keybuzz-ses` en prod |
| Deployment | Ajouter `secretRef` au worker prod |
| SES | Demander sortie sandbox |

---

**Rapport terminé** ✅  
**Version déployée**: `v0.1.72-dev`
