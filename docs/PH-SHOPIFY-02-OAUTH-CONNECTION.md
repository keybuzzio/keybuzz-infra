# PH-SHOPIFY-02 — OAuth + Connexion Shopify

> Date : 2026-04-08  
> Environnement : DEV uniquement  
> API : `v3.5.226-ph-shopify-02-dev`  
> Client : `v3.5.226-ph-shopify-02-dev`  
> PROD : inchangé (`v3.5.225-ph-playbooks-v2-prod`)

---

## Objectif

Implémenter la fondation de connexion Shopify via OAuth 2.0, sans import de données métier.

## Résultat

**SHOPIFY CONNECTOR DEPLOYED — DEV ONLY — OAUTH FOUNDATION READY**

---

## Changements

### 1. Modèle DB

Tables créées :

| Table | Colonnes clés | Usage |
|---|---|---|
| `shopify_connections` | id, tenant_id, shop_domain, access_token_enc (AES-256-GCM), scopes, status | Connexions Shopify par tenant |
| `shopify_webhook_events` | id, tenant_id, connection_id, topic, payload, processed | Log webhooks (non traités en PH-02) |

Index : `idx_shopify_conn_tenant`, `idx_shopify_conn_shop`, `idx_shopify_wh_tenant`, `idx_shopify_wh_topic`

### 2. Module API (`src/modules/marketplaces/shopify/`)

| Fichier | Rôle |
|---|---|
| `index.ts` | Export module |
| `shopify.routes.ts` | Routes Fastify : GET /status, POST /connect, GET /callback, POST /disconnect |
| `shopifyAuth.service.ts` | OAuth (state Redis, HMAC, token exchange, save/get/disconnect) |
| `shopifyCrypto.service.ts` | AES-256-GCM encrypt/decrypt (clé via `SHOPIFY_ENCRYPTION_KEY`) |
| `shopifyWebhook.routes.ts` | POST /webhooks/shopify (HMAC verification + log DB) |

### 3. Enregistrement API (`app.ts`)

```
app.register(shopifyRoutes, { prefix: '/shopify' });
app.register(shopifyWebhookRoutes, { prefix: '/webhooks' });
```

### 4. TenantGuard

Exclusions ajoutées : `/shopify/callback`, `/webhooks/shopify`

### 5. Catalogue channels

Entrée Shopify ajoutée dans `channelsService.ts` :
```
{ provider: "shopify", marketplace_key: "shopify-global", supports_orders: true }
```

### 6. Client

| Fichier | Type |
|---|---|
| `src/services/shopify.service.ts` | Service API (status, connect, disconnect) |
| `app/api/shopify/status/route.ts` | BFF proxy GET |
| `app/api/shopify/connect/route.ts` | BFF proxy POST |
| `app/api/shopify/disconnect/route.ts` | BFF proxy POST |
| `app/api/channels/registry/route.ts` | Shopify ajouté au registry |
| `app/channels/page.tsx` | Section Shopify (input domain + connect/disconnect) |
| `public/marketplaces/shopify.svg` | Logo SVG |

---

## Flow OAuth

```
1. User entre shop domain → clique "Connecter"
2. Client POST /api/shopify/connect { shopDomain }
3. BFF → API POST /shopify/connect
4. API : génère nonce, stocke state dans Redis (TTL 10min)
5. API retourne { authUrl }
6. Client redirige vers authUrl (Shopify OAuth)
7. Shopify redirige vers API GET /shopify/callback?code=&hmac=&shop=&state=
8. API : vérifie HMAC, pop state Redis, exchange code→token
9. API : chiffre token (AES-256-GCM), save dans shopify_connections
10. API redirige vers client /channels?shopify_connected=true
```

## Sécurité

- Token chiffré AES-256-GCM (IV + AuthTag + ciphertext)
- Clé via env `SHOPIFY_ENCRYPTION_KEY` (32 bytes hex)
- HMAC vérifié avec `crypto.timingSafeEqual`
- State OAuth éphémère Redis (TTL 600s)
- Webhook HMAC vérifié avant logging
- Aucun accès cross-tenant possible

---

## Variables d'environnement (API DEV)

| Variable | Valeur | Rôle |
|---|---|---|
| `SHOPIFY_CLIENT_ID` | *(vide — en attente de Shopify App)* | Client ID OAuth |
| `SHOPIFY_CLIENT_SECRET` | *(vide)* | Client Secret OAuth |
| `SHOPIFY_ENCRYPTION_KEY` | `0c33...80fc` | Clé AES-256 pour tokens |
| `SHOPIFY_REDIRECT_URI` | `https://api-dev.keybuzz.io/shopify/callback` | Callback OAuth |
| `SHOPIFY_CLIENT_REDIRECT_URL` | `https://client-dev.keybuzz.io/channels` | Redirect post-OAuth |

---

## Validation

| Test | Résultat |
|---|---|
| API health | OK |
| GET /shopify/status (ecomlg-001) | `{"connected":false}` |
| POST /shopify/connect (no creds) | `503 Shopify OAuth not configured` |
| POST /shopify/disconnect | `{"disconnected":false}` (aucune connexion) |
| POST /webhooks/shopify (no HMAC) | `401 Unauthorized` |
| DB tables shopify_* | 2 tables + 4 indexes |
| Multi-tenant (tenant 2 isolé) | `{"connected":false}` indépendant |
| Shopify in catalog API | OK |
| Non-régression /health | 200 |
| Non-régression /channels | 200 |
| Non-régression /playbooks | 200 |
| Non-régression /ai/wallet/status | 200 |
| Registry BFF (Shopify visible) | OK |
| PROD inchangé | `v3.5.225-ph-playbooks-v2-prod` |

---

## Multi-tenant

- 1 connexion = 1 tenant (`tenant_id` dans toutes les tables)
- Aucun partage de token ou shop_domain
- Aucun fallback global
- TenantGuard actif sur /status, /connect, /disconnect
- Callback + webhook exemptés car input externe (Shopify redirect)

---

## Rollback

```bash
# API
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.225-ph-playbooks-v2-dev -n keybuzz-api-dev

# Client
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.225-ph-playbooks-v2-dev -n keybuzz-client-dev
```

---

## Prochaine étape

**PH-SHOPIFY-03** : Sync commandes Shopify → table `orders` + conversation auto-create

Prérequis :
- Créer une Shopify App (obtenir CLIENT_ID / CLIENT_SECRET)
- Configurer les scopes finaux
- Activer les webhooks Shopify (orders/create, orders/updated)
