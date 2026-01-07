# PH11-MAIL-SES-AUDIT-01 — Audit AWS SES

**Date**: 2026-01-07  
**Status**: ✅ AUDIT COMPLÉTÉ  
**Environnement**: DEV (keybuzz-api-dev)

---

## 📋 Résumé Exécutif

| Composant | Status |
|-----------|--------|
| Vault accessible | ❌ NON |
| Secrets SES dans K8s | ❌ NON |
| Secrets SMTP dans K8s | ❌ NON |
| Code SMTP implémenté | ❌ NON |
| Code SES fallback implémenté | ❌ NON |
| Test E2E possible | ❌ NON |

**Conclusion : SES PAS PRÊT**

---

## 1. Vault — Vérification secrets SES

### Accès Vault
```
VAULT_ADDR: https://10.0.0.101:8200
Token présent: OUI (/root/.vault-token)
Status: ❌ Connection refused
```

**Résultat**: Vault inaccessible depuis install-v3. Impossible de vérifier les secrets.

### Paths attendus (selon documentation)
| Path | Clés attendues |
|------|----------------|
| secret/keybuzz/ses | AWS_SES_ACCESS_KEY, AWS_SES_SECRET_KEY, AWS_SES_REGION |
| secret/keybuzz/smtp | SMTP_USER, SMTP_PASSWORD, SMTP_HOST, SMTP_PORT |

---

## 2. K8s — Secrets et env vars

### Secrets dans namespace keybuzz-api-dev
```
NAME                   TYPE                             DATA
api-dev-tls            kubernetes.io/tls                2
ghcr-cred              kubernetes.io/dockerconfigjson   1
keybuzz-api-postgres   Opaque                           5
keybuzz-stripe         Opaque                           12
vault-root-token       Opaque                           1
```

**Secrets SES/SMTP trouvés**: ❌ AUCUN

### Env vars du déploiement keybuzz-api
| Variable | Source |
|----------|--------|
| PORT | value: 3001 |
| NODE_ENV | value: development |
| PGHOST | secretKeyRef: keybuzz-api-postgres |
| PGPORT | secretKeyRef: keybuzz-api-postgres |
| PGDATABASE | secretKeyRef: keybuzz-api-postgres |
| PGUSER | secretKeyRef: keybuzz-api-postgres |
| PGPASSWORD | secretKeyRef: keybuzz-api-postgres |
| STRIPE_* | secretKeyRef: keybuzz-stripe |

**Variables SES/SMTP**: ❌ AUCUNE

---

## 3. Code — Fallback SES

### Dépendances package.json
```json
{
  "@aws-sdk/client-s3": "^3.958.0",      // Pour S3 (attachments)
  "@aws-sdk/s3-request-presigner": "...", // Pour S3
  "stripe": "^14.11.0",                   // Paiements
  // ...
}
```

**Dépendances manquantes**:
- ❌ `@aws-sdk/client-ses` — Pour AWS SES
- ❌ `nodemailer` — Pour SMTP

### Module Outbound (src/workers/outboundWorker.ts)
```typescript
// Providers actuels:
if (delivery.provider === 'mock') {
  // Mock provider: instant delivered
} else if (delivery.provider === 'email_forward') {
  deliveryTrace.note = 'Simulated email forward (SMTP integration pending)';
}
```

**Implémentation réelle**: ❌ AUCUNE (mock uniquement)

### Recherche SES/SMTP dans le code
```bash
grep -rn "SES|SendEmail|nodemailer|smtp" src/
# Résultat: No matches found
```

---

## 4. Test E2E

**Status**: ❌ NON TESTABLE

**Raisons**:
1. Aucun secret SMTP/SES configuré
2. Aucun code d'envoi email implémenté
3. Le worker outbound utilise des providers "mock" uniquement

---

## 5. Ce qui manque pour SES

### Infrastructure
- [ ] Vault accessible
- [ ] Secret `keybuzz-ses` dans K8s avec:
  - AWS_SES_ACCESS_KEY
  - AWS_SES_SECRET_KEY
  - AWS_SES_REGION (eu-west-1)

### Code
- [ ] Installer `@aws-sdk/client-ses`
- [ ] Installer `nodemailer` (pour SMTP primaire)
- [ ] Implémenter provider SMTP dans outboundWorker
- [ ] Implémenter provider SES fallback
- [ ] Ajouter logique de fallback: SMTP → SES

### AWS
- [ ] Créer utilisateur IAM `keybuzz-ses`
- [ ] Vérifier domaine keybuzz.io dans SES
- [ ] Sortir du sandbox SES (production access)

---

## 6. Architecture cible

```
┌─────────────────────────────────────────────────────────┐
│                    keybuzz-api                          │
│                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │
│  │  Outbound   │───▶│    SMTP     │───▶│  mail-core  │ │
│  │   Worker    │    │  (primaire) │    │  (Postfix)  │ │
│  └─────────────┘    └─────────────┘    └─────────────┘ │
│         │                  │                            │
│         │           échec? │                            │
│         │                  ▼                            │
│         │           ┌─────────────┐    ┌─────────────┐ │
│         └──────────▶│    SES      │───▶│  AWS SES    │ │
│                     │ (fallback)  │    │  (eu-west-1)│ │
│                     └─────────────┘    └─────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## Conclusion

**SES n'est PAS prêt.**

L'intégration email (SMTP + SES fallback) n'est pas encore implémentée. Le code actuel utilise uniquement des providers "mock" pour simuler les envois.

### Prochaine phase recommandée
Créer une phase **PH11-MAIL-INTEGRATION** pour:
1. Configurer Vault avec les secrets SMTP/SES
2. Implémenter le provider SMTP (Postfix)
3. Implémenter le provider SES (fallback)
4. Créer les secrets K8s
5. Tester E2E

---

**Audit terminé** ✅
