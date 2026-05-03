# PH-SAAS-T8.12AM — Amazon Orders Sync 400 Truth Audit and DEV Fix

> Date : 2026-05-03
> Auteur : Agent Cursor
> Environnement : DEV-first, PROD lecture seule
> Type : audit verite + correction DEV

---

## 1. PREFLIGHT

| Element | DEV | PROD | Verdict |
|---|---|---|---|
| API image | `v3.5.145-shopify-api-restore-dev` → `v3.5.146-amazon-orders-sync-400-fix-dev` | `v3.5.137-conversation-order-tracking-link-prod` | OK |
| Client image | `v3.5.148-shopify-official-logo-dev` | `v3.5.148-shopify-official-logo-tracking-parity-prod` | OK inchange |
| /orders page | lecture DB | lecture seule | OK |
| Amazon secrets | Vault interne K8s OK | non verifie (PROD lecture seule) | OK |
| 17TRACK CronJob DEV | `0 */2 * * *` actif | suspendu | OK |
| API health | `{"status":"ok"}` | non touche | OK |

### Tenant SWITAA SASU
- Tenant ID DEV : `switaa-sasu-mnc1x4eq`
- Email : `switaa26@gmail.com`
- Role : owner
- Seller ID Amazon : `AHXAU25R6D726`
- Marketplace : `A13V1IB3VIYZZH` (Amazon.fr)
- Orders en DB DEV : 12 (10 amazon, 1 email, 1 octopia)
- Canal Amazon : actif (`status: active`)
- Vault creds : presentes (refresh_token, marketplace_id, region, seller_id)

---

## 2. FLOW /orders CARTOGRAPHIE

| Couche | Fichier | Endpoint/fonction | Role |
|---|---|---|---|
| Client UI | `app/orders/page.tsx` | Bouton "Synchroniser Amazon" | Detecte marketplace connectee, affiche modal sync |
| Client UI | `app/orders/page.tsx` | `startSync()` → `POST /api/orders/sync-all` | Lance la sync |
| Client UI | `app/orders/page.tsx` | polling `GET /api/orders/sync-status` | Suivi progression |
| Client BFF | `app/api/orders/sync-all/route.ts` | `POST ${BACKEND_URL}/api/v1/orders/sync-all` | Proxy vers API |
| Client BFF | `app/api/orders/sync-status/route.ts` | `GET ${BACKEND_URL}/api/v1/orders/sync-status` | Proxy status |
| API route | `src/modules/orders/routes.ts` | `POST /sync-all` | Verifie `tenant_channels`, lance `runBulkSync` en background |
| API service | `src/modules/orders/routes.ts` | `runBulkSync()` | Phase 1: comptage, Phase 2: import |
| SP-API | `src/modules/orders/routes.ts` | `fetchAmazonOrdersPage()` | Appel SP-API Orders |
| Vault | `src/modules/orders/routes.ts` | `getAmazonTenantCreds()` | Lecture credentials par tenant |
| DB write | `src/modules/orders/routes.ts` | `INSERT INTO orders` | Persistance commandes |
| DB write | `src/modules/orders/routes.ts` | `persistSyncState()` | Persistance etat sync |

### Flow detaille "Synchroniser Amazon"

```
1. UI: detecte marketplace connectee via GET /api/amazon/status
2. UI: affiche bouton "Synchroniser Amazon" si connected=true
3. User clique → modal choix periode (1/3/6/12 mois) → startSync()
4. BFF: POST /api/orders/sync-all → API POST /api/v1/orders/sync-all
5. API: verifie tenant_channels (active amazon) → 400 si absent
6. API: lance runBulkSync() en background → retourne 200 "running"
7. runBulkSync: Vault → getAmazonTenantCreds(tenantId)
8. runBulkSync: LWA → getAccessToken(refresh_token)
9. runBulkSync: Phase 1 → fetchAmazonOrdersPage() en boucle paginee
10. runBulkSync: Phase 2 → import chaque commande + items + packages
11. UI: polling GET /api/orders/sync-status toutes les 3s
12. UI: affiche progression ou erreur
```

---

## 3. REPRODUCTION DE L'ERREUR

### Erreur observee en DB
```json
{
  "tenant_id": "switaa-sasu-mnc1x4eq",
  "status": "error",
  "progress": "Erreur: SP-API orders error: 403",
  "error": "SP-API orders error: 403",
  "started_at": "2026-04-29T19:58:52.714Z"
}
```

### Reproduction directe (3 tests SP-API)

| Test | API Version | Params | Seller | Status | Body |
|---|---|---|---|---|---|
| 4a | v2026-01-01 | PascalCase | SWITAA | **403** | `Unauthorized — Access to requested resource is denied.` |
| 4b | v2026-01-01 | camelCase | SWITAA | **403** | `Unauthorized — Access to requested resource is denied.` |
| 4c | v0 | PascalCase | SWITAA | **403** | `Unauthorized — Access to requested resource is denied.` |

### Comparaison ecomlg-001 (seller autorise)

| Test | API Version | Params | Seller | Status | Result |
|---|---|---|---|---|---|
| v2026-01-01 PascalCase | v2026-01-01 | `MarketplaceIds`, `CreatedAfter` | ecomlg | **400** | `InvalidInput: One and only one of createdAfter or lastUpdatedAfter must be provided.` |
| v2026-01-01 camelCase | v2026-01-01 | `marketplaceIds`, `createdAfter` | ecomlg | **200** | 100 orders ✓ |
| v0 PascalCase | v0 | `MarketplaceIds`, `CreatedAfter` | ecomlg | **200** | 100 orders ✓ |

---

## 4. CAUSES RACINES

### Cause 1 — Bug code : mauvais parametres API v2026-01-01

| Cause candidate | Preuve | Ecart code/config | Decision |
|---|---|---|---|
| `fetchAmazonOrdersPage` utilise v2026-01-01 avec PascalCase params | Test ecomlg → 400 InvalidInput | v2026-01-01 attend camelCase (`createdAfter`), code envoie PascalCase (`CreatedAfter`) | **FIX: revenir au v0 API** |
| Response parsing v2026-01-01 incompatible | v2026-01-01 retourne `orders[].orderId` (camelCase), code attend `Orders[].AmazonOrderId` (PascalCase) | Format reponse completement different | **FIX: v0 resout aussi ce probleme** |

### Cause 2 — Externe : SWITAA SP-API authorization invalide

| Cause candidate | Preuve | Ecart code/config | Decision |
|---|---|---|---|
| Refresh token SWITAA obtient un access token valide | LWA retourne token length=375 | - | Token LWA OK |
| Access token rejete par SP-API sur TOUTES les versions | 403 Unauthorized sur v0 ET v2026-01-01 | Autorisation seller revoquee ou incomplete | **EXTERNE: re-authorization requise** |
| Seller ID SWITAA (`AHXAU25R6D726`) different du seller ecomlg (`A12BCIS2R7HD4D`) | - | Chaque seller a sa propre autorisation | Confirme separation |

---

## 5. DB VS SP-API LIVE

| Surface | Source donnees | Depend SP-API live ? | Verdict |
|---|---|---|---|
| Bloc commandes messages | DB `orders` table | Non | OK inchange |
| Page /orders list | DB via `GET /api/v1/orders` | Non | OK — 12 commandes visibles |
| Bouton Synchroniser Amazon | SP-API live via `fetchAmazonOrdersPage` | Oui | 403 pour SWITAA, fix v0 pour autres |
| IA commande/suivi | DB `orders` + `tracking_events` | Non direct | OK inchange |
| Import unitaire (inbox) | SP-API single order | Oui | Utilise v0, pas impacte |

---

## 6. CORRECTION DEV

### Patch applique : `src/modules/orders/routes.ts`

**Changement 1** — `fetchAmazonOrdersPage` :
- URL : `/orders/2026-01-01/orders` → `/orders/v0/orders`
- Ajout : logging du body d'erreur SP-API complet
- Ajout : classification 403 en `AUTHORIZATION_INVALID`

**Changement 2** — `runBulkSync` catch block :
- Traduction `AUTHORIZATION_INVALID` → message FR actionnable
- Message : *"Votre connexion Amazon a expire ou a ete revoquee. Reconnectez-vous dans Canaux > Amazon."*
- Traduction credentials manquantes → *"Aucune connexion Amazon configuree pour ce compte."*

### v2026-01-01 preservee pour les packages
Les appels `orders/2026-01-01/orders/${orderRef}?includedData=PACKAGES` (enrichissement tracking single-order) sont **preserves** — ils utilisent une URL differente et ne sont pas impactes.

---

## 7. VALIDATION DEV

| Check | Resultat |
|---|---|
| /orders page | ✅ 200, 12 commandes SWITAA visibles |
| Sync Amazon SWITAA | ✅ Message FR actionnable : "Votre connexion Amazon a expire..." |
| Sync Amazon ecomlg-001 | ✅ 200, 323 commandes trouvees, Phase 1 OK |
| Message erreur UI | ✅ "Erreur: Votre connexion Amazon a expire ou a ete revoquee..." |
| Orders DB intact | ✅ SWITAA: 12, ecomlg: 11952 |
| SP-API error logged | ✅ `[Orders] SP-API orders error: 403 — Access to requested resource is denied.` |
| IA order context | ✅ Inchange (DB read, pas SP-API live) |
| 17TRACK CronJob | ✅ DEV actif, PROD suspendu |
| Billing | ✅ Aucun changement |
| CAPI/tracking | ✅ Aucun changement |
| PROD API | ✅ Inchangee (`v3.5.137`) |
| PROD Client | ✅ Inchangee (`v3.5.148`) |

---

## 8. BUILD DEV

- **Tag** : `v3.5.146-amazon-orders-sync-400-fix-dev`
- **Image** : `ghcr.io/keybuzzio/keybuzz-api:v3.5.146-amazon-orders-sync-400-fix-dev`
- **Digest** : `sha256:c625054808c7e23d8164ae76a8cc1c11dd9094cc410e9e40b151740250aa3f91`
- **GitOps** : `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` mis a jour
- **Rollback** : `v3.5.145-shopify-api-restore-dev`
- **Commit API** : `PH-SAAS-T8.12AM: fix fetchAmazonOrdersPage v0 fallback + 403 user message`

---

## 9. NON-REGRESSION

| Baseline | Avant | Apres | Drift |
|---|---|---|---|
| API PROD | `v3.5.137-conversation-order-tracking-link-prod` | Idem | Aucun |
| Client PROD | `v3.5.148-shopify-official-logo-tracking-parity-prod` | Idem | Aucun |
| GA4 | `G-R3QQDYEBFG` | Non touche | Aucun |
| sGTM | `https://t.keybuzz.pro` | Non touche | Aucun |
| TikTok | `D7PT12JC77U44OJIPC10` | Non touche | Aucun |
| LinkedIn | `9969977` | Non touche | Aucun |
| Meta Pixel | `1234164602194748` | Non touche | Aucun |
| 17TRACK webhook | Actif | Actif | Aucun |
| 17TRACK CronJob PROD | Suspendu | Suspendu | Aucun |
| Browser Purchase | Aucun | Aucun | Aucun |
| Browser CompletePayment | Aucun | Aucun | Aucun |

---

## 10. DECISION PROD FUTURE

Pour promouvoir en PROD :
1. Reconstruire l'image avec tag `-prod`
2. Tester avec ecomlg-001 en PROD (sync reelle)
3. Verifier que le fix v0 fonctionne aussi en PROD

Pour SWITAA specifiquement :
- Le seller `AHXAU25R6D726` doit **re-autoriser** l'app KeyBuzz dans Seller Central
- Ou bien regenerer le refresh_token via le flow OAuth Amazon
- Le message d'erreur guide desormais l'utilisateur vers la bonne action

---

## 11. VERDICT

**GO DEV FIX READY**

AMAZON ORDERS SYNC 400 ROOT CAUSE FIXED IN DEV — ORDERS PAGE PRESERVES LOCAL DATA — LIVE SP-API SYNC ERROR HANDLED HONESTLY — MESSAGE ORDER BLOCK UNCHANGED — AI ORDER/TRACKING CONTEXT PRESERVED — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED
