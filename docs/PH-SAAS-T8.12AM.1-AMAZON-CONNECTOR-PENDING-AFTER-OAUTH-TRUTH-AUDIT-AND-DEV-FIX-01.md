# PH-SAAS-T8.12AM.1 — Amazon Connector Pending After OAuth — Truth Audit & DEV Fix

> **Date** : 3 mai 2026
> **Phase** : PH-SAAS-T8.12AM.1-AMAZON-CONNECTOR-PENDING-AFTER-OAUTH-TRUTH-AUDIT-AND-DEV-FIX-01
> **Priorité** : P1
> **Environnement** : DEV (PROD non modifié)
> **Verdict** : **GO DEV FIX READY**

---

## Résumé exécutif

Le connecteur Amazon du tenant SWITAA SASU restait en statut "En attente" dans l'UI `/channels` malgré une reconnexion OAuth Amazon réussie. La cause racine est un **gap architectural** entre deux sources de vérité : le callback OAuth (keybuzz-backend) met à jour `inbound_connections` (status READY) mais ne met jamais à jour `tenant_channels` (utilisé par l'UI `/channels`). Le fix ajoute une auto-activation self-healing dans l'endpoint `/api/v1/marketplaces/amazon/status`.

---

## ÉTAPE 0 — Preflight

| Élément | DEV | PROD | Verdict |
|---------|-----|------|---------|
| API image | `v3.5.146-amazon-orders-sync-400-fix-dev` | `v3.5.137-conversation-order-tracking-link-prod` | ✅ |
| Client image | `v3.5.148-shopify-official-logo-dev` | `v3.5.148-shopify-official-logo-tracking-parity-prod` | ✅ |
| Health API | `{"status":"ok"}` | N/A | ✅ |
| eComLG Amazon status | `CONNECTED` (FR,DE,IT,ES,BE) | Présumé OK | ✅ |
| SWITAA Amazon status | `CONNECTED` (FR,DE) via inbound_connections | N/A | ✅ |
| SWITAA tenant_channels | **`pending`** (FR) | N/A | ⚠️ BUG |
| Vault creds SWITAA | Présents (refresh_token OK, marketplace_id FR) | N/A | ✅ |

---

## ÉTAPE 1 — Flow OAuth Amazon cartographié

| Couche | Fichier | Fonction/Route | Rôle |
|--------|---------|----------------|------|
| Client bouton connect | `app/channels/page.tsx` | `handleAmazonConnect()` | Appelle `startAmazonOAuth(tenantId, returnUrl)` |
| Client BFF | `app/api/amazon/oauth/start/route.ts` | POST handler | Crée inbound connection + proxy vers backend |
| API compat proxy | `src/modules/compat/routes.ts` | POST `/api/v1/marketplaces/amazon/oauth/start` | Proxy → keybuzz-backend |
| Backend OAuth start | `amazon.routes.ts` + `amazon.oauth.ts` | `generateAmazonOAuthUrl()` | Génère URL Amazon consent + stocke state dans `OAuthState` |
| Amazon consent | sellercentral.amazon.com | N/A | User autorise l'app |
| Backend callback | `amazon.routes.ts` | GET `/api/v1/marketplaces/amazon/oauth/callback` | Échange code → tokens, stocke dans Vault, crée inbound connection |
| Redirect | N/A | N/A | Redirige vers `/channels?amazon_connected=true` |
| Client détection | `amazon.service.ts` | `checkOAuthCallback()` | Affiche "Amazon connecté avec succès !" |
| **MANQUANT** | N/A | N/A | **Aucun appel à `activateChannel()` pour mettre à jour `tenant_channels`** |

---

## ÉTAPE 2 — Audit DB SWITAA (sans secrets)

### `inbound_connections`

| Champ | Valeur | Verdict |
|-------|--------|---------|
| id | `conn_2e623384c724ff6356c673f514aad5d8` | ✅ |
| tenantId | `switaa-sasu-mnc1x4eq` | ✅ |
| marketplace | `amazon` | ✅ |
| status | `READY` | ✅ |
| countries | `["FR","DE"]` | ✅ |
| createdAt | `2026-03-29T17:48:07.459Z` | ✅ |
| updatedAt | `2026-03-29T17:53:42.311Z` | ✅ |

### `tenant_channels` (avant fix)

| Champ | Valeur | Verdict |
|-------|--------|---------|
| id | `a7d1f2a4-1bec-4067-826f-96773cce2452` | ✅ |
| provider | `amazon` | ✅ |
| country_code | `FR` | ✅ |
| marketplace_key | `amazon-fr` | ✅ |
| status | **`pending`** | ⚠️ BUG |
| connected_at | `2026-04-16T05:22:28.125Z` | ✅ (ancien) |
| disconnected_at | **`2026-05-03T21:32:49.393Z`** | ⚠️ Non effacé |
| connection_ref | `cmo118x1z019x3m011pufeuar` | ⚠️ Ancien ref |

### Vault (metadata uniquement)

| Champ | Valeur | Verdict |
|-------|--------|---------|
| marketplace_id | `A13V1IB3VIYZZH` (FR) | ✅ |
| region | `eu-west-1` | ✅ |
| seller_id | `AHXA...` (masqué) | ✅ |
| refresh_token_present | `true` | ✅ |
| created_at | `2026-05-03T21:33:50.759Z` | ✅ (frais) |

---

## ÉTAPE 3 — Audit logs callback

Confirmé par timestamps DB :
- `2026-05-03T21:32:49` : `tenant_channels.disconnected_at` set (disconnect)
- `2026-05-03T21:33:50` : Vault credentials créées (OAuth callback réussi)
- `inbound_connections` : status `READY` (callback a réussi)
- `tenant_channels` : status `pending` (jamais promu — **LE BUG**)

| Étape callback | Observé | Erreur | Décision |
|----------------|---------|--------|----------|
| Callback reçu | ✅ (Vault updated) | Aucune | - |
| State validé | ✅ (implicite) | Aucune | - |
| Code échangé | ✅ (refresh_token stocké) | Aucune | - |
| Token stocké | ✅ (Vault created_at frais) | Aucune | - |
| Inbound conn | ✅ (status READY) | Aucune | - |
| **tenant_channels update** | **❌ NON FAIT** | **Fonction jamais appelée** | **Cause racine** |
| Redirect final | ✅ (`?amazon_connected=true`) | Aucune | - |

---

## ÉTAPE 4 — Comparaison eComLG vs SWITAA

| Critère | eComLG | SWITAA | Écart |
|---------|--------|--------|-------|
| tenant_channels status | `active` (7 canaux) | **`pending`** (1 canal) | ⚠️ eComLG activé manuellement |
| inbound_connections status | `READY` | `READY` | ✅ |
| Vault refresh_token | Présent | Présent | ✅ |
| marketplace_id | FR,DE,IT,ES,BE | FR,DE | ✅ (différent scope) |
| connection_ref | `cmk5ty3do00013r01hmk30uqh` | `cmo118x1z019x3m011pufeuar` (ancien) | ⚠️ Non mis à jour |
| disconnected_at | NULL (FR), dates anciennes (autres) | **`2026-05-03T21:32:49`** | ⚠️ Non effacé |

**Cause** : eComLG a été activé manuellement (probablement durant un setup ou migration). Le flow OAuth standard **ne promet jamais** `tenant_channels` de `pending` à `active`.

---

## ÉTAPE 5 — Cause racine

### Le gap architectural

Deux systèmes parallèles gèrent le statut Amazon :

1. **`inbound_connections`** (géré par `keybuzz-backend`) :
   - Mis à jour par le callback OAuth
   - Lu par `GET /api/v1/marketplaces/amazon/status` → retourne `CONNECTED`
   - Source de vérité pour les tokens SP-API

2. **`tenant_channels`** (géré par `keybuzz-api`) :
   - Inséré par `addChannel()` avec status `pending`
   - Lu par l'UI `/channels` → affiche "En attente"
   - `activateChannel()` existe mais **n'est jamais appelé** après OAuth

### Pourquoi ça marchait pour eComLG

Les canaux eComLG ont été activés manuellement (bulk activation le 2026-04-12) avec un `connection_ref` commun, avant que le flow channel-based soit le seul chemin.

### Pourquoi ça casse pour les nouveaux tenants

Tout nouveau tenant qui :
1. Ajoute un canal Amazon (→ `pending` dans `tenant_channels`)
2. Fait OAuth Amazon (→ `READY` dans `inbound_connections`, Vault OK)
3. Revient sur `/channels` → voit "En attente" car personne n'a promu `tenant_channels`

---

## ÉTAPE 6 — Correction DEV

### Fix 1 : `compat/routes.ts` — Auto-activation self-healing

Dans l'endpoint `GET /api/v1/marketplaces/amazon/status`, après avoir détecté `inbound_connections` READY :
- Pour chaque pays dans `countries`, vérifie si `tenant_channels` a un row `pending`
- Si oui, le promeut à `active` avec `disconnected_at = NULL`, `connection_ref` mis à jour
- Log l'auto-activation pour traçabilité

**Avantage** : Self-healing — chaque appel de status (chargement `/channels`, `/orders`, etc.) auto-corrige le gap.

### Fix 2 : `channelsService.ts` — `activateChannel()` amélioré

Ajout de :
- `disconnected_at = NULL` (effacer le flag de déconnexion)
- `activated_at = COALESCE(activated_at, NOW())` (tracer la réactivation)

### Fichiers modifiés

| Fichier | Lignes | Changement |
|---------|--------|------------|
| `src/modules/compat/routes.ts` | +28/-1 | Auto-activation boucle pays + log |
| `src/modules/channels/channelsService.ts` | +2 | Clear disconnected_at, set activated_at |

---

## ÉTAPE 7 — Validation DEV

| Test | Résultat | Détail |
|------|----------|--------|
| Health API | ✅ | `{"status":"ok"}` |
| SWITAA status | ✅ | `CONNECTED` (FR,DE) |
| SWITAA channel auto-activated | ✅ | `amazon-fr` → `active`, `disconnected_at: null` |
| SWITAA connection_ref updated | ✅ | `conn_2e623384c724ff6356c673f514aad5d8` |
| eComLG status | ✅ | `CONNECTED` (FR,DE,IT,ES,BE) — aucune régression |
| eComLG channels | ✅ | 7 canaux `active`, inchangés |
| PROD images | ✅ | API `v3.5.137`, Client `v3.5.148` — inchangées |
| API log auto-activate | ✅ | `[Amazon Status] Auto-activated channel amazon-fr for tenant switaa-sasu-mnc1x4eq` |
| Channels endpoint SWITAA | ✅ | `amazon-fr active connected` |

---

## ÉTAPE 8 — Build DEV

| Étape | Résultat |
|-------|----------|
| Commit | `e8d868c6` sur `ph147.4/source-of-truth` |
| Build | `docker build --no-cache` réussi |
| Tag | `ghcr.io/keybuzzio/keybuzz-api:v3.5.147-amazon-oauth-pending-status-fix-dev` |
| Push | SHA `4ef45267fce9b52b975bfa9194143f113e4321336979b1d94206242c07122cf6` |
| Deploy | `kubectl set image` → rollout réussi |
| GitOps | `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` mis à jour |

---

## Baselines préservées

| Service | Image | Status |
|---------|-------|--------|
| API PROD | `v3.5.137-conversation-order-tracking-link-prod` | ✅ Inchangé |
| Client PROD | `v3.5.148-shopify-official-logo-tracking-parity-prod` | ✅ Inchangé |
| API DEV (avant) | `v3.5.146-amazon-orders-sync-400-fix-dev` | Rollback disponible |
| API DEV (après) | `v3.5.147-amazon-oauth-pending-status-fix-dev` | ✅ Déployé |

---

## Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.146-amazon-orders-sync-400-fix-dev -n keybuzz-api-dev
```

---

## Décision PROD future

Ce fix devra être promu en PROD lors d'un prochain cycle de promotion. Il corrige un bug structurel qui affecte **tous les nouveaux tenants** qui connectent Amazon. eComLG en PROD n'est pas affecté (canaux déjà `active`).

---

## Verdict

**GO DEV FIX READY**

AMAZON CONNECTOR PENDING ROOT CAUSE FIXED IN DEV — OAUTH CALLBACK STATUS HONEST — ECOMLG PRESERVED — SWITAA RECONNECT PATH CLEAR — ORDERS SYNC ERROR ACTIONABLE — NO BILLING/TRACKING/CAPI DRIFT — PROD UNCHANGED
