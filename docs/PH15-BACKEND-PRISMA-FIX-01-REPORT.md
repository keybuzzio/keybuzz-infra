# PH15-BACKEND-PRISMA-FIX-01 — Rapport

**Date** : 2026-01-07  
**Statut** : ✅ TERMINÉ

---

## Résumé

Réparation du schema Prisma corrompu dans `keybuzz-backend` et restauration de l'authentification JWT sur les routes Amazon.

---

## 1. Cause racine

Le fichier `prisma/schema.prisma` avait été corrompu par des modifications successives mal fusionnées, entraînant :
- **Champs dupliqués** : `updatedAt` défini deux fois dans presque tous les modèles (Tenant, User, Team, Ticket, etc.)
- **Champs manquants** : des références à des champs inexistants dans les indexes
- **19 erreurs de validation** Prisma au total

De plus, le fichier `amazon.routes.ts` avait perdu le middleware `authenticate` (preHandler JWT), ce qui causait des erreurs 401 systématiques.

---

## 2. Commit schema sain identifié

```
d71f944 fix(PH11-AMZ): repair TS parsing + oauth state binding signatures + JWT preHandler
```

Ce commit contient un `prisma/schema.prisma` valide, vérifié par :
```bash
npx prisma validate --schema=/tmp/schema_d71f944.prisma
# ✅ The schema is valid
```

---

## 3. Différences principales (schema corrompu vs sain)

| Problème | Modèles affectés |
|----------|------------------|
| `updatedAt` dupliqué | Tenant, User, Team, Ticket, AiRule, TenantBillingPlan, TicketBillingUsage, MarketplaceConnection, OutboundEmail, Job, InboundConnection, InboundAddress, MarketplaceOutboundMessage |
| `tenantId` dupliqué | ExternalMessage |
| Champs orphelins (`returnTo`, `marketplaceConfigured*`) | OAuthState, InboundAddress (ajoutés incorrectement) |

---

## 4. Correction appliquée

1. **Restauration du schema** depuis le commit `d71f944`
2. **Restauration de `amazon.routes.ts`** depuis le fichier `.bak` avec le middleware `authenticate`
3. **Validation** : `npx prisma validate` ✅

---

## 5. Dockerfile corrigé

Le Dockerfile a été mis à jour pour inclure :
- `npx prisma generate` dans les deux stages (builder et runner)
- `apk add --no-cache openssl` pour les dépendances Prisma
- CMD correct avec guillemets : `CMD ["node", "dist/main.js"]`

---

## 6. Versions déployées

| Service | Version | Image |
|---------|---------|-------|
| keybuzz-backend | v0.1.7-dev | `ghcr.io/keybuzzio/keybuzz-backend:v0.1.7-dev` |
| keybuzz-client | v0.2.37-dev | (rollback stable) |

---

## 7. Tests E2E

### Test 1 : Tenant sans connexion Amazon

```bash
curl -H "Authorization: Bearer $JWT_nouveau_tenant" \
  https://backend-dev.keybuzz.io/api/v1/marketplaces/amazon/status
```

**Résultat** :
```json
{"error":"No Amazon connection found","connected":false}
```
✅ Status HTTP 404 + `connected: false` — **CORRECT**

### Test 2 : Tenant avec connexion Amazon

```bash
curl -H "Authorization: Bearer $JWT_tenant_test_dev" \
  https://backend-dev.keybuzz.io/api/v1/marketplaces/amazon/status
```

**Résultat** :
```json
{
  "connected": true,
  "status": "CONNECTED",
  "displayName": "Amazon Seller A12BCIS2R7HD4D",
  "region": "EU",
  "lastSyncAt": "2026-01-03T04:39:44.850Z",
  "lastError": null
}
```
✅ Status HTTP 200 + `connected: true` — **CORRECT**

### Test 3 : Health endpoint

```bash
curl https://backend-dev.keybuzz.io/health
```

**Résultat** :
```json
{"status":"ok","uptime":446.49,"version":"0.1.0","env":"production"}
```
✅ Backend opérationnel

---

## 8. État du cluster

| Pod | Status | Age |
|-----|--------|-----|
| keybuzz-backend-555fdcd494-ljjhg | Running | ~1min |

---

## 9. Fichiers modifiés

### keybuzz-backend
- `prisma/schema.prisma` — Restauré depuis d71f944
- `src/modules/marketplaces/amazon/amazon.routes.ts` — Restauré depuis .bak (avec authenticate middleware)
- `Dockerfile` — Corrigé (Prisma generate + CMD)

### keybuzz-infra
- Ce rapport

---

## 10. Recommandations

1. **Protéger le schema Prisma** : Ajouter une CI qui valide `npx prisma validate` à chaque PR
2. **Éviter les backups .bak** : Utiliser Git pour les restaurations
3. **Tester localement** avant chaque déploiement

---

## 11. Git

```bash
# keybuzz-backend
git add prisma/schema.prisma src/modules/marketplaces/amazon/amazon.routes.ts Dockerfile
git commit -m "fix(PH15): repair prisma schema validation + restore authenticate middleware"
git push origin main

# keybuzz-infra
git add docs/PH15-BACKEND-PRISMA-FIX-01-REPORT.md
git commit -m "docs(PH15): prisma fix report"
git push origin main
```

---

**Fin du rapport PH15-BACKEND-PRISMA-FIX-01**
