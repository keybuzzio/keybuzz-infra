# PH-SAAS-T8.12AS.21.224 - Readonly Shopify connector truth audit DEV/PROD

## Verdict

NO_GO_ACTIVATION_REQUIRED.

Le connecteur Shopify n'est pas pret a etre ouvert a des societes clientes supplementaires.

Le socle existe encore en source/runtime et les tables/secrets sont presents, mais l'UX est volontairement desactivee depuis PH-SAAS-T8.12AP.4.2A/4.2B et plusieurs risques bloquants doivent etre corriges avant activation :

1. Les routes API Shopify ne sont pas protegees par le tenantGuard.
2. Les webhooks Shopify verifient le HMAC sur `JSON.stringify(request.body)` au lieu du raw body.
3. La version Admin API Shopify codee est `2024-10`, trop ancienne pour une activation 2026 durable.
4. Shopify est presente comme `supports_messaging: true`, mais le code actuel couvre OAuth, commandes et webhooks commandes, pas une vraie ingestion de messages Shopify.
5. La sync initiale est limitee a 50 commandes et il n'existe pas de CronJob Shopify observe.
6. L'activation UX reste coupee en DEV et PROD par `coming_soon: true` / `comingSoon: true`.

## Scope

Audit lecture seule :

- keybuzz-api source/runtime.
- keybuzz-client source/runtime.
- keybuzz-infra docs/manifests/scripts.
- DB metadata-only via pods API DEV/PROD.
- Secrets metadata-only : noms de secret et cles, aucune valeur decodee.
- Docs Shopify officielles uniquement pour versioning et verification webhook.

Hors scope :

- Aucun OAuth Shopify reel.
- Aucun webhook fake.
- Aucun POST `/shopify/connect`, `/shopify/disconnect`, `/shopify/orders/sync`.
- Aucun build, push image, deploy, apply, DB mutation, secret read/decode, Linear mutation.

## Preflight

| Repo | Branche | HEAD | Ahead/behind | Dirty |
| --- | --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | f030088d9132 | 0/0 | 0 |
| keybuzz-client | ph148/onboarding-activation-replay | e7aefa15ee2c | 0/0 | 0 |
| keybuzz-admin-v2 | main | af5eaaaf1d87 | 0/0 | 0 |
| keybuzz-backend | main | c38583a8548e | 0/0 | 1 untracked `.bak` Amazon hors scope |
| keybuzz-infra | main | 47a4a6208d70 | 0/0 | 0 |

Dirty backend observe :

- `src/modules/marketplaces/amazon/amazon.routes.ts.bak`
- Non suivi, hors Shopify, non modifie.

## Source de verite relue

| Document | Decision / preuve |
| --- | --- |
| PH-SAAS-T8.12AK-SHOPIFY-API-SOURCE-RESTORE-DEV-01.md | API Shopify restauree en DEV : routes, HMAC invalide, status/connect/callback/sync. |
| PH-SAAS-T8.12AL-SHOPIFY-DEV-STORE-E2E-VALIDATION-01.md | E2E bloque par app review Shopify ; socle validable OK ; OAuth reel non termine. |
| PH-SAAS-T8.12AP.4.2A-SHOPIFY-CONNECTOR-DISABLED-UNTIL-APP-APPROVAL-DEV-PROD-01.md | Decision produit : Shopify visible mais non connectable tant que l'app n'est pas approuvee. |
| PH-SAAS-T8.12AP.4.2B-SHOPIFY-VISIBLE-DISABLED-IN-CHANNELS-PROD-FIX-01.md | Shopify doit apparaitre dans "Bientot disponible" mais rester non cliquable. |
| Shopify docs - API versioning | Versions stables supportees 2025-07+ ; `2024-10` n'est plus dans la table accessible. |
| Shopify docs - Webhook verification | HMAC a calculer sur le raw request body, pas sur un objet JSON reserialize. |

## Source actuelle

### API

Fichiers Shopify presents :

- `src/modules/marketplaces/shopify/index.ts`
- `src/modules/marketplaces/shopify/shopify.routes.ts`
- `src/modules/marketplaces/shopify/shopifyAuth.service.ts`
- `src/modules/marketplaces/shopify/shopifyCrypto.service.ts`
- `src/modules/marketplaces/shopify/shopifyOrders.service.ts`
- `src/modules/marketplaces/shopify/shopifyWebhook.routes.ts`

Registration presente dans `src/app.ts` :

- `app.register(shopifyRoutes, { prefix: '/shopify' })`
- `app.register(shopifyWebhookRoutes, { prefix: '/webhooks' })`

### Client

Fichiers Shopify presents :

- `app/api/shopify/connect/route.ts`
- `app/api/shopify/status/route.ts`
- `app/api/shopify/disconnect/route.ts`
- `src/services/shopify.service.ts`
- `app/channels/page.tsx`
- `src/features/onboarding/components/OnboardingHub.tsx`
- `src/features/onboarding/hooks/useOnboardingState.ts`

UX actuelle :

- `/start` : Shopify `comingSoon: true`.
- `/channels` : Shopify injecte dans catalogue avec `coming_soon: true`.
- Clic catalogue Shopify : `return`, pas d'ouverture de modal.
- Modal Shopify encore dans le code mais inatteignable par le chemin utilisateur normal.

## Runtime

### Deployments

| Service | Env | Image | Ready |
| --- | --- | --- | --- |
| API | DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.279-ai-response-humanness-dev | 1/1 |
| API | PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.279-ai-response-humanness-prod | 1/1 |
| Client | DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.278-auth-shell-bypass-dev | 1/1 |
| Client | PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.278-auth-shell-bypass-prod | 1/1 |

### Env Shopify metadata-only

| Env | Resultat |
| --- | --- |
| API DEV | `SHOPIFY_CLIENT_ID`, `SHOPIFY_CLIENT_SECRET`, `SHOPIFY_ENCRYPTION_KEY` via secret `keybuzz-shopify`; redirect DEV OK. |
| API PROD | `SHOPIFY_CLIENT_ID`, `SHOPIFY_CLIENT_SECRET`, `SHOPIFY_ENCRYPTION_KEY` via secret `keybuzz-shopify`; redirect PROD OK; `SHOPIFY_WEBHOOK_URL=https://api.keybuzz.io/webhooks/shopify`. |
| Secret DEV | `keybuzz-shopify` present, cles attendues presentes. |
| Secret PROD | `keybuzz-shopify` present, cles attendues presentes. |

Aucune valeur de secret lue ou decodee.

### Runtime bundle markers

API DEV/PROD contiennent :

- `dist/modules/marketplaces/shopify/index.js`
- `dist/modules/marketplaces/shopify/shopify.routes.js`
- `dist/modules/marketplaces/shopify/shopifyAuth.service.js`
- `dist/modules/marketplaces/shopify/shopifyCrypto.service.js`
- `dist/modules/marketplaces/shopify/shopifyOrders.service.js`
- `dist/modules/marketplaces/shopify/shopifyWebhook.routes.js`

Client DEV/PROD contiennent les markers Shopify dans `app_channels_page`.

### Passive HTTP smoke

| URL | Status | Interpretation |
| --- | --- | --- |
| https://api-dev.keybuzz.io/shopify/status | 400 | Route active, tenantId requis. |
| https://api.keybuzz.io/shopify/status | 400 | Route active, tenantId requis. |
| https://client-dev.keybuzz.io/channels | 307 | Auth redirect normal. |
| https://client.keybuzz.io/channels | 307 | Auth redirect normal. |
| https://client-dev.keybuzz.io/start | 307 | Auth redirect normal. |
| https://client.keybuzz.io/start | 307 | Auth redirect normal. |

## DB metadata-only

### DEV

Tables presentes :

- `shopify_connections`
- `shopify_webhook_events`
- `orders`
- `conversations`

`shopify_connections` colonnes :

- `id`, `tenant_id`, `shop_domain`, `access_token_enc`, `scopes`, `status`, `created_at`, `updated_at`, `token_expires_at`, `refresh_token_enc`

Connexions :

| Status | Count |
| --- | ---: |
| active | 1 |
| disconnected | 11 |

Connexion active metadata-only :

- tenant `keybuzz-mnqnjna8`
- shop `keybuzz-dev.myshopify.com`
- scopes `read_customers,read_fulfillments,read_orders,read_returns`
- created `2026-04-09T19:09:20.340Z`

Webhooks DEV :

- `orders/create` processed true : 4
- `orders/updated` processed true : 6
- compliance/app topics presents.

Orders Shopify DEV :

- tenant `keybuzz-mnqnjna8` : 2 commandes Shopify, latest `2026-04-09T20:59:09.892Z`

### PROD

Tables presentes :

- `shopify_connections`
- `shopify_webhook_events`
- `orders`
- `conversations`

Connexions :

- `shopify_connections` active/disconnected : 0.

Webhooks PROD :

- `shop/redact` : 1 event, processed false, latest `2026-04-11T20:25:26.869Z`

Orders Shopify PROD :

- tenant `ecomlg-001` : 1 commande Shopify historique, latest `2026-04-10T11:57:00.518Z`

Conversations Shopify PROD :

- tenant `ecomlg-001` : 1 conversation historique, latest `2026-04-13T08:54:48.000Z`

## Findings

### P0 - Shopify API routes are not tenantGuard-protected

Routes concernees :

- `GET /shopify/status`
- `POST /shopify/connect`
- `POST /shopify/disconnect`
- `POST /shopify/orders/sync`

Le Client BFF injecte bien `X-User-Email` et `X-Tenant-Id`, mais l'API Shopify elle-meme lit `tenantId` depuis body/query/header et n'est pas dans la matrice `tenantGuard`.

Risque si Shopify est active :

- lecture de metadata de connexion par tenantId connu;
- creation d'un OAuth state pour un tenant cible;
- deconnexion d'une boutique d'un autre tenant;
- declenchement de sync commandes avec token stocke.

Decision : ne pas ouvrir Shopify tant que ces routes ne sont pas hardenees.

### P0 - HMAC webhook Shopify probablement incorrect

Le code actuel :

- `const bodyStr = JSON.stringify(request.body);`
- HMAC calcule sur `bodyStr`.

La doc Shopify exige le raw request body pour calculer le HMAC. L'app Fastify stocke deja `(req as any).rawBody`, mais `shopifyWebhook.routes.ts` ne l'utilise pas.

Risque :

- rejet de webhooks reels selon ordre/format JSON;
- ingestion instable;
- compliance webhooks non fiables.

### P1 - Shopify Admin API version obsolete

Le code utilise :

- `const SHOPIFY_API_VERSION = '2024-10';`

La doc Shopify indique un calendrier trimestriel et recommande d'utiliser la derniere version stable. Au 2026-06-30, la version stable prudente est `2026-04`; `2024-10` n'est plus dans la table des versions accessibles publiees. Shopify peut "fall forward", mais ce comportement cache les incompatibilites.

Decision : migrer explicitement vers `2026-04` avant activation.

### P1 - Scope fonctionnel actuel : commandes, pas messages Shopify

Ce qui existe :

- OAuth Shopify.
- Token chiffre AES-256-GCM.
- GraphQL orders sync.
- Webhooks `orders/create`, `orders/updated`.
- Order mapping vers `orders`.
- Context IA Shopify `direct_seller_controlled`.

Ce qui n'est pas prouve :

- ingestion de messages Shopify/Shopify Inbox;
- creation automatique de conversations depuis un message Shopify reel;
- reponse outbound vers Shopify;
- handoff IA complet sur message Shopify reel.

Risque produit :

- le terme "connecteur Shopify" peut laisser croire a une centralisation SAV complete, alors que le socle actuel est surtout order context + webhooks commandes.

### P1 - Sync initiale insuffisante pour de vrais clients

Le callback lance :

- `syncOrders(tenantId, 50)`

Pas de CronJob Shopify observe et pas d'UI de periode Shopify comparable au besoin Amazon des 3 derniers mois.

Risque :

- les societes Shopify branchees voient trop peu d'historique;
- l'IA manque de contexte commandes;
- onboarding moins convaincant.

### P2 - UX volontairement desactivee

Shopify reste en "Bientot disponible" :

- `/start` : `comingSoon: true`.
- `/channels` : `coming_soon: true`.
- modal de connexion inatteignable.

C'est conforme aux rapports AP.4.2A/4.2B, mais incompatible avec une activation immediate.

### P2 - Hygiene lifecycle Shopify incomplete

Observations :

- `app/uninstalled` est logge mais pas traite pour desactiver proprement la connexion.
- compliance topics sont logges mais pas marques processed.
- duplication webhook : pas de stockage/verrou `X-Shopify-Webhook-Id`.

Risque :

- connexion affichant active apres uninstall;
- reprocess possible en cas de retry Shopify;
- compliance/audit a clarifier.

## AI feature parity / anti-regression

| Feature | Etat |
| --- | --- |
| Context IA Shopify | Present : `resolveMarketplaceContext("shopify")` => `direct_seller_controlled`. |
| Refund protection | Shopify traite comme vente directe, pas marketplace stricte. |
| Order context | Present si orders Shopify existent. |
| Messages/inbox Shopify reels | Non prouve. |
| Auto-draft/Autopilot Shopify reel | Non prouve bout-en-bout sur message Shopify reel. |
| Amazon/Octopia | Non modifies par audit. |

## Recommendation

Ne pas brancher tes autres entreprises Shopify maintenant.

Plan conseille :

1. PH-21.225 READONLY DESIGN Shopify activation hardening DEV/PROD.
2. PH-21.226 SOURCE PATCH DEV :
   - ajouter Shopify routes dans tenantGuard ou middleware specifique;
   - utiliser rawBody pour webhook HMAC;
   - ajouter idempotence `X-Shopify-Webhook-Id`;
   - traiter `app/uninstalled`;
   - monter `SHOPIFY_API_VERSION` a `2026-04`;
   - clarifier `supports_messaging=false` tant qu'il n'y a pas de vraie ingestion messages;
   - garder UX disabled tant que l'audit DEV n'est pas vert.
3. Build/push/apply DEV API.
4. Verify DEV avec tests negatifs :
   - direct API sans membership => 403/401;
   - BFF authenticated OK;
   - webhook HMAC raw body OK;
   - webhook duplicate ignored;
   - uninstall desactive connection.
5. Activer Shopify DEV uniquement pour un tenant test apres validation.
6. E2E DEV avec vraie boutique Shopify :
   - OAuth;
   - sync 3 mois ou periode configurable;
   - webhook commande;
   - orders visibles;
   - IA seller-first sur conversation test reliee a commande.
7. Promotion PROD uniquement apres validation DEV et GO explicite.

## Sources externes

- Shopify API versioning: https://shopify.dev/docs/api/usage/versioning
- Shopify webhook delivery verification: https://shopify.dev/docs/apps/build/webhooks/verify-deliveries

## No side-effect

- 0 build.
- 0 docker push.
- 0 deploy/apply.
- 0 OAuth Shopify.
- 0 webhook fake.
- 0 DB mutation.
- 0 secret value read/decode.
- 0 event tracking.
- 0 billing mutation.

STOP.
