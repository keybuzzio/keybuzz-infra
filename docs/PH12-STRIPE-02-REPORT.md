# PH12-STRIPE-02 — Stripe Customer Portal

**Date:** 2026-01-06
**Statut:** ✅ COMPLÉTÉ

---

## 📋 Résumé

Activation du Stripe Customer Portal en DEV, permettant aux utilisateurs de gérer leur abonnement, modifier leurs moyens de paiement et consulter l'historique des factures.

---

## 🎯 Objectifs Réalisés

| Étape | Statut | Détails |
|-------|--------|---------|
| Configuration Portal Stripe | ✅ | Créé via API |
| Endpoint API portal-session | ✅ | POST /billing/portal-session |
| Bouton UI "Gérer mon abonnement" | ✅ | Sur /billing/plan |
| Correction connexion DB | ✅ | PGHOST via secret K8s |
| Test E2E | ✅ | URL Portal générée |

---

## 🔧 Configuration Portal Stripe

```
Portal Config ID: bpc_1SmTn2FC0QQLHISRWBRhUOQA
Return URL: https://client-dev.keybuzz.io/billing/plan

Fonctionnalités activées:
  ✅ customer_update (email, nom)
  ✅ payment_method_update
  ✅ invoice_history
  ✅ subscription_cancel (fin de période)
```

---

## 🔌 Endpoints API

### GET /billing/status

```json
{
  "stripeConfigured": true,
  "webhookConfigured": true,
  "tablesReady": true,
  "appBaseUrl": "https://client-dev.keybuzz.io",
  "apiBaseUrl": "https://api-dev.keybuzz.io"
}
```

### POST /billing/portal-session

**Requête:**
```json
{
  "tenantId": "kbz-001"
}
```

**Réponse (succès):**
```json
{
  "url": "https://billing.stripe.com/p/session/test_..."
}
```

**Réponse (sans subscription):**
```json
{
  "error": "Aucun abonnement actif",
  "message": "Vous devez d'abord souscrire à un plan pour accéder au portail de gestion."
}
```

### GET /billing/debug-db (DEV ONLY)

Endpoint de debug pour vérifier la connexion DB:
```json
{
  "env": {
    "PGHOST": "10.0.0.121",
    "PGUSER": "v-kubernet-keybuzz--...",
    "PGDATABASE": "keybuzz"
  },
  "secretsMounted": true,
  "dbTestResult": {
    "success": true,
    "row": {
      "current_user": "v-kubernet-keybuzz--...",
      "server": "10.0.0.121"
    }
  }
}
```

---

## 🖥️ Client UI

### Page /billing/plan

Nouveau bouton "Gérer mon abonnement" ajouté:
- Appelle POST /billing/portal-session
- Redirige vers Stripe Portal
- Désactivé en mode fallback
- Affiche erreur en cas d'échec

**Message UX:**
> "Vous serez redirigé vers Stripe pour gérer votre abonnement en toute sécurité."

---

## 📊 Versions

| Service | Version |
|---------|---------|
| keybuzz-api | v0.1.54-dev |
| keybuzz-client | v0.2.24-dev |

---

## 🔧 Corrections Techniques

### PGHOST corrigé

Le deployment utilisait PGHOST hardcodé (10.0.0.122 - réplica) au lieu du leader.

**Avant:**
```yaml
- name: PGHOST
  value: 10.0.0.122  # Réplica - ERREUR
```

**Après:**
```yaml
- name: PGHOST
  valueFrom:
    secretKeyRef:
      key: PGHOST
      name: keybuzz-api-postgres  # Contient 10.0.0.121 (leader)
```

### Pool DB corrigé

Le code billing utilisait `(app as any).pg` (undefined) au lieu de `getPool()` de database.ts.

**Correction:**
```typescript
// Avant
const pool: Pool = (app as any).pg;

// Après
async function getDbPool(): Promise<Pool> {
  return await getPool();
}
```

---

## 🧪 Tests E2E

| Test | Résultat |
|------|----------|
| /billing/status | ✅ tablesReady: true |
| /billing/portal-session (avec customer) | ✅ URL Stripe générée |
| /billing/portal-session (sans customer) | ✅ Erreur claire |
| /billing/portal-session (tenantId invalide) | ✅ Erreur validation |
| /billing/debug-db | ✅ Connexion DB OK |

---

## 📁 Fichiers Modifiés

### API
- `src/modules/billing/routes.ts` - Ajout endpoint portal-session
- `src/modules/billing/routes.ts` - Correction pool DB

### Client
- `app/billing/plan/page.tsx` - Bouton "Gérer mon abonnement"

### Infra
- `k8s/keybuzz-api-dev/deployment.yaml` - PGHOST via secretKeyRef

---

## ⚠️ À faire

1. **Supprimer /billing/debug-db** avant passage en PROD
2. Obtenir le tenantId depuis le contexte auth (actuellement hardcodé)
3. Tester le flux complet: checkout → webhook → portal

---

## 🔒 Sécurité

- ✅ Aucun secret affiché, loggé ou commité
- ✅ Portal config créée via API (pas d'accès dashboard)
- ✅ Endpoint portal-session valide le tenantId

---

**Fin du rapport PH12-STRIPE-02**
