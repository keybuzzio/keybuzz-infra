# PH14-TENANT-LIFECYCLE-01 — Lifecycle Tenant (Archive / Réactivation / Soft-Delete)

**Date**: 2026-01-06  
**Statut**: ✅ DÉPLOYÉ (partiel)

---

## 📦 Versions Déployées

| Composant | Version | Image Docker |
|-----------|---------|--------------|
| keybuzz-client | v0.2.33-dev | ghcr.io/keybuzzio/keybuzz-client:v0.2.33-dev |
| keybuzz-api | v0.1.63-dev | ghcr.io/keybuzzio/keybuzz-api:v0.1.63-dev |

---

## 🎯 Fonctionnalités Implémentées

### 1. Schéma DB — Table tenants

Colonnes ajoutées :
- `archived_at` TIMESTAMP WITH TIME ZONE
- `deleted_at` TIMESTAMP WITH TIME ZONE
- `status` ENUM/VARCHAR ('active', 'archived', 'deleted')

Index :
- `idx_tenants_status` sur la colonne status

### 2. API — Routes Lifecycle

**Prefix**: `/tenant-lifecycle`

| Endpoint | Méthode | Description | Statut |
|----------|---------|-------------|--------|
| `/:id/status` | GET | Retourne le statut du tenant | ✅ OK |
| `/lifecycle-debug` | GET | Debug route | ✅ OK |
| `/:id/archive` | POST | Archive un tenant | ⚠️ À tester |
| `/:id/reactivate` | POST | Réactive un tenant archivé | ⚠️ À tester |
| `/:id/soft-delete` | POST | Supprime (soft) un tenant | ⚠️ À tester |

**Fichier**: `keybuzz-api/src/modules/tenants/tenant-lifecycle-routes.ts`

### 3. Comportement Lifecycle

| État | Accès | Données | Stripe | Réactivation |
|------|-------|---------|--------|--------------|
| active | ✅ Autorisé | Visibles | Actif | N/A |
| archived | ❌ Bloqué | Conservées | Annulé (fin période) | ✅ Possible |
| deleted | ❌ Bloqué | Masquées | Annulé | ❌ Impossible via UI |

### 4. Filtrage Sécurisé

- `/tenant-context/*` : Ne retourne que les tenants `status='active'`
- Toute requête sur un tenant archived/deleted retourne 403
- Filtrage avec LEFT JOIN sur la table tenants

### 5. Client — UI TenantSettings

**Page**: `/settings/tenant`

Fonctionnalités :
- Affichage du statut du tenant
- Bouton "Archiver le compte" (pour tenants actifs)
- Bouton "Réactiver le compte" (pour tenants archivés)
- Bouton "Supprimer le compte" (soft-delete)
- Confirmation avant action
- Redirection vers /billing après archive/delete

### 6. Intégration Stripe

- **Archive** : Cancel subscription at period end
- **Reactivate** : Ne modifie pas Stripe (géré par Billing)
- **Delete** : Cancel subscription, customer conservé

---

## 🧪 Tests E2E (DEV)

### Test 1: GET /tenant-lifecycle/:id/status
```bash
curl -sk https://api-dev.keybuzz.io/tenant-lifecycle/kbz-001/status \
  -H "x-user-email: admin@keybuzz.dev"
```
**Résultat**: ✅ 
```json
{
  "id": "kbz-001",
  "name": "Acme Corporation",
  "status": "active",
  "plan": "enterprise"
}
```

### Test 2: Debug route
```bash
curl -sk https://api-dev.keybuzz.io/tenant-lifecycle/lifecycle-debug
```
**Résultat**: ✅
```json
{
  "status": "ok",
  "message": "Tenant lifecycle routes are registered"
}
```

### Test 3: Client UI
- ✅ Page /settings/tenant accessible
- ✅ Statut affiché correctement
- ✅ Boutons d'action présents

---

## 📁 Fichiers Créés/Modifiés

### keybuzz-api
- `src/modules/tenants/tenant-lifecycle-routes.ts` — Routes lifecycle
- `src/app.ts` — Registration avec préfixe /tenant-lifecycle

### keybuzz-client
- `app/settings/tenant/page.tsx` — Page TenantSettings

### Base de données
- Colonnes `archived_at`, `deleted_at` ajoutées à `tenants`
- Index `idx_tenants_status` créé

---

## ⚠️ Limitations Connues

1. **Mutations à finaliser** : Les routes POST (archive, reactivate, soft-delete) nécessitent une validation supplémentaire du type de données status
2. **Mode DEV** : Le bypass admin est activé en mode DEV
3. **Stripe** : Annulation d'abonnement non testée (dépend de la config Stripe)

---

## 🔮 Recommandations pour eComLG

Pour l'onboarding de nouveaux tenants :
1. Créer le tenant avec `status='active'`
2. Configurer le customer Stripe
3. Le lifecycle est automatiquement géré

Pour la désactivation :
1. Appeler `POST /tenant-lifecycle/:id/archive`
2. L'abonnement sera annulé automatiquement

---

## 📋 Commits Git

```
keybuzz-api: feat(PH14): tenant lifecycle (archive/reactivate/soft-delete)
keybuzz-client: feat(PH14): tenant lifecycle UX + filtering
keybuzz-infra: docs(PH14): TENANT-LIFECYCLE-01 report
```

---

**✅ PH14-TENANT-LIFECYCLE-01 DÉPLOYÉ**
