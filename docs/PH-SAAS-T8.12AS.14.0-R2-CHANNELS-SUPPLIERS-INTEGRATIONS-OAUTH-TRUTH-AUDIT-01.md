# PH-SAAS-T8.12AS.14.0-R2-CHANNELS-SUPPLIERS-INTEGRATIONS-OAUTH-TRUTH-AUDIT-01

> Date : 2026-05-14
> Linear : KEY-314 (parent KEY-301 Done, KEY-313 Done)
> Phase : T8.12AS.14.0 (R2 truth audit)
> Environnement : DEV + PROD read-only (aucune mutation, aucun build, aucun deploy)

---

## 0. VERDICT

GO R2 CHANNELS INTEGRATIONS DESIGN READY.

Surface R2 cartographiee. Modules confirmes registered : channels, channel-rules (attachments), suppliers, integrations, marketplaces/octopia, shopify, shopifyWebhook, compat Amazon (deja ferme par KEY-313). 35 endpoints au total dont 6 deja proteges (compat Amazon AS.13.3A). Probes runtime safe DEV confirment l absence de membership check sur 6 surfaces representatives (channels, suppliers, integrations, shopify/status) : HTTP 200 retourne sans authentification ni appartenance, simplement sur presentation d un tenantId arbitraire. Risque cross-tenant disclosure-controlled : eleve. Decoupage AS.14.1+ propose en 6 sous-phases DEV first, chacune validee negative-only, avec exemptions explicites pour OAuth callbacks Shopify et webhook HMAC Shopify. Trois cas dead code identifies (modules/octopia/routes.ts, modules/channel-rules/routes.ts, modules/suppliers/routes.ts). Un bug de prefix Octopia confirme en runtime (`/octopia/marketplaces/octopia/*` au lieu de `/marketplaces/octopia/*`). Backend keybuzz-backend tient le fichier .bak `amazon.routes.ts.bak` (left-over PH-SAAS-T8.12AO.2) en untracked sur main : a nettoyer hors-scope security.

Pas de patch, pas de build, pas de docker push, pas de kubectl apply, pas de mutation DB, pas d operation Linear avant GO Ludovic.

---

## 1. PREFLIGHT

### 1.1 Repos / branches / HEAD

| Repo | Branche reelle | Branche imposee | HEAD | Sync | Dirty | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | ph147.4/source-of-truth | 8f162dde | 0 / 0 | dist/ files deleted (build cache, hors source) | OK |
| keybuzz-client | ph148/onboarding-activation-replay | ph148/onboarding-activation-replay | b726970 | 0 / 0 | clean | OK |
| keybuzz-backend | main | main | b183817 | 0 / 0 | untracked: src/modules/marketplaces/amazon/amazon.routes.ts.bak | WARN |
| keybuzz-admin-v2 | main | main | 3707c83 | 0 / 0 | clean | OK |
| keybuzz-infra | main | main | 4006e12 | 0 / 0 | clean (post AS.13.4A) | OK |

Warning backend : fichier .bak resultant d un edit pre-PH-SAAS-T8.12AO.2 (buildSafeRedirectUrl). Sans impact runtime (non importe) ; nettoyage hors-scope security.

### 1.2 Runtime images live (kubectl)

| Service | DEV namespace | DEV image | PROD namespace | PROD image | Attendu prompt | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | keybuzz-api-dev | ghcr.io/keybuzzio/keybuzz-api:v3.5.189-compat-amazon-tenantguard-dev | keybuzz-api-prod | ghcr.io/keybuzzio/keybuzz-api:v3.5.189-compat-amazon-tenantguard-prod | v3.5.189-compat-amazon-tenantguard | MATCH |
| keybuzz-client | keybuzz-client-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.196-ai-rules-bff-dev | keybuzz-client-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.196-ai-rules-bff-prod | v3.5.196-ai-rules-bff | MATCH |
| keybuzz-backend | keybuzz-backend-dev | ghcr.io/keybuzzio/keybuzz-backend:v1.0.47-cross-env-guard-fix-dev | keybuzz-backend-prod | ghcr.io/keybuzzio/keybuzz-backend:v1.0.47-cross-env-guard-fix-prod | n/a | OK |
| keybuzz-admin-v2 | keybuzz-admin-v2-dev | ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-dev | keybuzz-admin-v2-prod | ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-prod | inchange | MATCH |

Aucune divergence Git / runtime. Pas de drift.

---

## 2. INVENTAIRE SOURCE R2

Cinq dimensions analysees :
- registration map dans `keybuzz-api/src/app.ts`
- chaque module R2 (fichiers `.routes.ts`)
- entrees `PROTECTED_ROUTES` actuelles du `tenantGuard.ts`
- code Client direct vs BFF
- references backend keybuzz-backend

### 2.1 Modules registered dans app.ts

| Ligne | Register | Prefix effectif | Module source |
|---|---|---|---|
| 151 | integrationsRoutes | /integrations | modules/integrations/routes.ts |
| 155 | channelRulesRoutes | (root, paths internes) | modules/attachments/channel-rules.ts |
| 188 | octopiaRoutes | /octopia | modules/marketplaces/octopia/octopia.routes.ts (DOUBLE-PREFIX BUG) |
| 189 | shopifyRoutes | /shopify | modules/marketplaces/shopify/shopify.routes.ts |
| 190 | shopifyWebhookRoutes | /webhooks | modules/marketplaces/shopify/shopifyWebhook.routes.ts |
| 197 | compatRoutes | (root, paths internes) | modules/compat/routes.ts (AS.13.3A protege) |
| 203 | suppliersRoutes | (root, paths internes) | modules/suppliers/suppliers.routes.ts |
| 205 | channelsRoutes | /channels | modules/channels/channelsRoutes.ts |

### 2.2 Dead code identifie (non importe, non registered)

| Fichier | Statut | Constat |
|---|---|---|
| modules/octopia/routes.ts | DEAD | `octopiaRoutes` defini mais l import app.ts:48 vient de marketplaces/octopia. Probe `/octopia/status` -> 404. |
| modules/channel-rules/routes.ts | DEAD | `channelRulesCrudRoutes` defini ; l import app.ts:25 vient de attachments/channel-rules.ts. Probe `/channel-rules?tenantId=...` -> 404. |
| modules/suppliers/routes.ts | DEAD | 5 endpoints minimaux ; l import app.ts:58 vient de suppliers/suppliers.routes.ts. |

Aucun deces de fonctionnalite a craindre cote runtime ; ces fichiers consomment du source mais ne sont pas mountes. Hors scope R2 security ; cleanup separe possible.

### 2.3 Bug de double-prefix Octopia (constate runtime)

Le module `modules/marketplaces/octopia/octopia.routes.ts` declare 13 routes avec paths hardcoded en `/marketplaces/octopia/*`. Le `app.register(octopiaRoutes, { prefix: '/octopia' })` les remonte sous `/octopia/marketplaces/octopia/*` au lieu du `/marketplaces/octopia/*` attendu par les commentaires de code.

Probes runtime DEV (read-only, no auth) :
- `GET /marketplaces/octopia/config` -> 404
- `GET /octopia/marketplaces/octopia/config` -> 200 (public, no tenant scope)

Impact : le frontend Client n appelle pas ces routes (aucune reference dans `app/`, `components/`, `lib/`). Pas d urgence security mais bug fonctionnel a connaitre pour AS.14.x.

### 2.4 Endpoints R2 inventory complet

A. **channels** (prefix `/channels`) - 8 endpoints (channelsRoutes.ts)

| Endpoint | Tenant source | Membership | Risk |
|---|---|---|---|
| GET /channels/ | query tenantId or header | NONE | High |
| GET /channels/catalog | query or header | NONE | High |
| POST /channels/add | body or header | NONE | High |
| POST /channels/remove | body or header | NONE | High |
| GET /channels/billing | query or header | NONE | Medium |
| GET /channels/billing-compute | query or header | NONE | Medium |
| GET /channels/by-key | query or header | NONE | High |
| POST /channels/activate-amazon | header or body (PH-SAAS-T8.12AM.2/AM.9) | NONE | High (post Amazon OAuth handoff) |

B. **channel-rules attachments** (root mount) - 1 endpoint (attachments/channel-rules.ts)

| Endpoint | Tenant scope | Membership | Risk |
|---|---|---|---|
| GET /attachments/channel-rules/:channel | NONE (static config) | n/a | Low (public legitimate, no tenant data) |

C. **suppliers** (root mount) - 12 endpoints (suppliers/suppliers.routes.ts)

| Endpoint | Tenant source | Membership | Risk |
|---|---|---|---|
| GET /suppliers | query | NONE | High |
| POST /suppliers | body | NONE | High |
| PUT /suppliers/:id | body + tenantId | NONE | High |
| DELETE /suppliers/:id | query | NONE | High |
| GET /suppliers/:id/cases | query | NONE | High |
| POST /supplier-cases | body | NONE | High |
| PATCH /supplier-cases/:id/status | body | NONE | High |
| GET /supplier-cases/conversation/:conversationId | query/header | NONE | High |
| GET /supplier-cases/batch | query | NONE | Medium |
| GET /tenant-settings/dropshipper | query | NONE | Medium |
| POST /supplier-inbound | localPart token in `to` field (sav.<tenantId>.<caseId>@inbound.keybuzz.io) | TOKEN-based (email gateway) | Low if reachable only via inbound gateway, High if public |
| POST /supplier-cases/:id/send-email | body | NONE | High |

D. **integrations** (prefix `/integrations`) - 2 endpoints

| Endpoint | Tenant source | Membership | Risk |
|---|---|---|---|
| GET /integrations/ | query | NONE | Medium |
| GET /integrations/:pk | query + path | NONE | Medium |

E. **marketplaces/octopia** (effectif `/octopia/marketplaces/octopia/*` apres double prefix) - 13 endpoints

| Endpoint (effectif) | Tenant source | Membership | Risk |
|---|---|---|---|
| GET /octopia/marketplaces/octopia/config | none | n/a | Low (public, KeyBuzz aggregator metadata) |
| GET /octopia/marketplaces/octopia/status | query | NONE | High |
| POST /octopia/marketplaces/octopia/test | body | NONE | Medium |
| POST /octopia/marketplaces/octopia/connect | body | NONE | High |
| POST /octopia/marketplaces/octopia/disconnect | body | NONE | High |
| POST /octopia/marketplaces/octopia/sync/run | body | NONE | Medium |
| GET /octopia/marketplaces/octopia/sync/status | query | NONE | Medium |
| GET /octopia/marketplaces/octopia/orders | query | NONE | High |
| GET /octopia/marketplaces/octopia/orders/:orderId | query + path | NONE | High |
| GET /octopia/marketplaces/octopia/config/status | query | NONE | Medium |
| POST /octopia/marketplaces/octopia/import | body | NONE | High |
| POST /octopia/marketplaces/octopia/backfill | body | NONE | High |
| POST /octopia/marketplaces/octopia/sync | body | NONE | High |

F. **shopify** (prefix `/shopify`) - 5 endpoints

| Endpoint | Tenant source | Membership | Risk | Note |
|---|---|---|---|---|
| GET /shopify/status | query / header | NONE | High | provider state leak |
| POST /shopify/connect | body | NONE | High | OAuth start (build authUrl, store oauth state) |
| GET /shopify/callback | OAuth state (Redis) | OAuth provider (Shopify) | n/a | DO NOT GUARD : provider browser redirect with HMAC |
| POST /shopify/disconnect | body / header | NONE | High |  |
| POST /shopify/orders/sync | body / header | NONE | High |  |

G. **shopifyWebhook** (prefix `/webhooks`) - 1 endpoint

| Endpoint | Auth | Membership | Risk | Note |
|---|---|---|---|---|
| POST /webhooks/shopify | HMAC SHA256 with SHOPIFY_CLIENT_SECRET | tenant derived via shop_domain lookup | n/a | DO NOT GUARD : provider HMAC pattern |

H. **compat Amazon** (root mount) - 6 endpoints (AS.13.3A KEY-313 closed)

Already in `PROTECTED_ROUTES` static list (verified line 181 onwards of tenantGuard.ts).

### 2.5 Resume volume R2

| Surface | Endpoints | Deja proteges | Manquent | Exempts a documenter |
|---|---|---|---|---|
| channels | 8 | 0 | 8 | 0 |
| channel-rules attachments | 1 | 0 | 0 | 1 (static config) |
| suppliers | 12 | 0 | 11 | 1 (/supplier-inbound, inbound gateway) |
| integrations | 2 | 0 | 2 | 0 |
| marketplaces/octopia | 13 | 0 | 12 | 1 (/config public) |
| shopify | 5 | 0 | 3 | 2 (callback OAuth, status pending review) |
| shopifyWebhook | 1 | 0 | 0 | 1 (HMAC provider) |
| compat Amazon | 6 | 6 | 0 | 0 |
| **Total R2** | **48** | **6** | **36** | **6** |

Cible R2 hardening : 36 endpoints. 6 endpoints publics/protocole-driven a exempter explicitement.

---

## 3. CLASSIFICATION

Conventions :
- T = tenant-scoped a proteger via membership user_tenants
- O = OAuth callback (browser redirect from provider, HMAC + state)
- W = webhook public (HMAC-signed external)
- I = internal / inbound gateway token
- P = public configuration (no tenant data)
- A = admin-only
- C = compat closed (KEY-313)
- U = unknown / a investiguer en AS.14.x

| Endpoint | Classif | Current guard | Required guard | Exemption justifie | Justification |
|---|---|---|---|---|---|
| GET /channels/ | T | none | tenantGuard | no | tenant data |
| GET /channels/catalog | T | none | tenantGuard | no | tenant scope |
| POST /channels/add | T | none | tenantGuard | no | mutation tenant |
| POST /channels/remove | T | none | tenantGuard | no | mutation tenant |
| GET /channels/billing | T | none | tenantGuard | no | billing data |
| GET /channels/billing-compute | T | none | tenantGuard | no | billing data |
| GET /channels/by-key | T | none | tenantGuard | no | tenant scope |
| POST /channels/activate-amazon | T | none | tenantGuard + verify BFF path | no | post OAuth handoff sensible |
| GET /attachments/channel-rules/:channel | P | none | none | yes | static config (Amazon/email policies), no tenant data |
| GET /suppliers | T | none | tenantGuard | no | tenant data |
| POST /suppliers | T | none | tenantGuard | no | mutation |
| PUT /suppliers/:id | T | none | tenantGuard + WHERE tenant_id | no | mutation |
| DELETE /suppliers/:id | T | none | tenantGuard + WHERE tenant_id | no | mutation |
| GET /suppliers/:id/cases | T | none | tenantGuard + WHERE tenant_id | no | tenant scope |
| POST /supplier-cases | T | none | tenantGuard | no | mutation |
| PATCH /supplier-cases/:id/status | T | none | tenantGuard + WHERE tenant_id | no | mutation |
| GET /supplier-cases/conversation/:conversationId | T | none | tenantGuard | no | tenant data |
| GET /supplier-cases/batch | T | none | tenantGuard | no | tenant data |
| GET /tenant-settings/dropshipper | T | none | tenantGuard | no | tenant settings |
| POST /supplier-inbound | I | localPart parse + DB lookup | confirm gateway-only ingress (NetworkPolicy or token) | yes (subject to confirm) | inbound email gateway path - need infra verification, NOT tenant-guarded |
| POST /supplier-cases/:id/send-email | T | none | tenantGuard | no | mutation + outbound effect |
| GET /integrations/ | T | none | tenantGuard | no | tenant data |
| GET /integrations/:pk | T | none | tenantGuard | no | tenant data |
| GET /octopia/marketplaces/octopia/config | P | none | none | yes | aggregator static config |
| GET /octopia/marketplaces/octopia/status | T | none | tenantGuard | no | tenant integration state |
| POST /octopia/marketplaces/octopia/test | T | none | tenantGuard | no | tenant scope |
| POST /octopia/marketplaces/octopia/connect | T | none | tenantGuard | no | mutation |
| POST /octopia/marketplaces/octopia/disconnect | T | none | tenantGuard | no | mutation |
| POST /octopia/marketplaces/octopia/sync/run | T | none | tenantGuard | no | mutation + provider call |
| GET /octopia/marketplaces/octopia/sync/status | T | none | tenantGuard | no | tenant state |
| GET /octopia/marketplaces/octopia/orders | T | none | tenantGuard | no | order data |
| GET /octopia/marketplaces/octopia/orders/:orderId | T | none | tenantGuard | no | order data |
| GET /octopia/marketplaces/octopia/config/status | T | none | tenantGuard | no | tenant state |
| POST /octopia/marketplaces/octopia/import | T | none | tenantGuard | no | mutation |
| POST /octopia/marketplaces/octopia/backfill | T | none | tenantGuard | no | mutation |
| POST /octopia/marketplaces/octopia/sync | T | none | tenantGuard | no | mutation |
| GET /shopify/status | T | none | tenantGuard | no | provider state |
| POST /shopify/connect | T | none | tenantGuard | no | OAuth start (server emits authUrl) |
| GET /shopify/callback | O | HMAC + Redis state | none | yes | Shopify browser redirect, must NOT receive cookie/header constraints |
| POST /shopify/disconnect | T | none | tenantGuard | no | mutation |
| POST /shopify/orders/sync | T | none | tenantGuard | no | mutation |
| POST /webhooks/shopify | W | HMAC SHA256 | none | yes | Shopify HMAC public webhook |
| compat Amazon (6) | C | tenantGuard (KEY-313) | already protected | n/a | n/a |

Total apres classification : 30 endpoints "T" a proteger via tenantGuard, 6 exemptions documentees (P / O / W / I), 6 deja "C" fermes par KEY-313.

NOTE : POST /shopify/connect (OAuth start) est classe "T" car cote serveur, c est une mutation tenant-scoped (insert oauth_state, return authUrl). Le browser appelle ensuite Shopify, puis Shopify rappelle `/shopify/callback`. Donc `/shopify/connect` peut etre tenantGuarded. Seul `/shopify/callback` doit rester libre.

---

## 4. CONSUMERS TRACING

### 4.1 Client (keybuzz-client)

Trois patterns observes :

A. **Pas de BFF intermediate pour R2** : aucun fichier `app/api/(channels|suppliers|integrations|shopify|octopia|marketplaces)/route.ts` n existe cote Client. Les appels Client vers les routes R2 API se font donc :
- soit direct `fetch('https://api.keybuzz.io/channels?...')`
- soit via une couche utilitaire `fetchKBApi` qu il faudra inventorier en AS.14.x

B. **api-client.ts direct backend pour Amazon** :
- `fetchBackend('/api/v1/marketplaces/amazon/oauth/start', ...)` pointe vers keybuzz-backend directement
- consequence : le compat Amazon AS.13.3A n a effectivement aucun consumer Client legitime via api.keybuzz.io ; il etait protege en defense-in-depth

C. **routeAccessGuard.ts (UI only)** decrit les routes Client UI :
- ADMIN_ONLY_ROUTES inclut `/channels` (admin-only UI for channels page)
- ACTION_ROUTES inclut `/suppliers` (viewer cannot mutate)
- API_PUBLIC_PREFIXES inclut `/api/channels/registry`, `/api/channel-rules`, `/api/attachments` (BFF allowlist UI side)

| Consumer | Cible API | Headers transmis | Risk si on guard | Notes |
|---|---|---|---|---|
| Client UI channels page | GET /channels, GET /channels/catalog, POST /channels/add, POST /channels/remove | session JWT (NextAuth) + tenantId from `useTenant()` | low (legit flow renvoie 200) | Owner/admin only via Client UI gate |
| Client UI suppliers page | GET /suppliers, CRUD | session JWT + tenantId | low | role gating Client side |
| Client UI integrations | GET /integrations | session JWT + tenantId | low | data dropshipper, tenant settings |
| Client UI channels Amazon flow | POST /channels/activate-amazon | session JWT + tenantId + backendConnection | low | called after Amazon OAuth backend success |
| Client UI Shopify flow | POST /shopify/connect (OAuth start), POST /shopify/disconnect, POST /shopify/orders/sync | session JWT + tenantId | low | `/shopify/callback` reached by browser via Shopify redirect (no cookies forwarded by Shopify) |
| Client UI Octopia flow | /octopia/marketplaces/octopia/* | session JWT + tenantId | low | aggregator/direct flow |
| Inbound email gateway | POST /supplier-inbound | parsed `to` field | high if guarded (gateway has no tenantId concept) | classe I, NOT tenant-guarded |
| Shopify provider browser | GET /shopify/callback | shop, code, state, hmac | high if guarded (Shopify never carries our session) | classe O, NOT tenant-guarded |
| Shopify provider server | POST /webhooks/shopify | x-shopify-hmac-sha256 + topic + shop-domain | high if guarded | classe W, NOT tenant-guarded |

### 4.2 Admin v2 (keybuzz-admin-v2)

Aucune reference aux routes R2 trouvee dans `app/`, `components/`, `lib/` (grep complet sur channels|suppliers|integrations|shopify|octopia|marketplaces|amazon). Admin v2 ne touche pas R2.

### 4.3 Backend (keybuzz-backend)

keybuzz-backend porte sa propre famille de routes Amazon (`modules/marketplaces/amazon/*.ts`), incluant amazon.oauth.ts, amazon.routes.ts. Ces routes sont APPELEES DIRECTEMENT par le Client via `fetchBackend('/api/v1/marketplaces/amazon/oauth/start')`. Le compat keybuzz-api (AS.13.3A) sert de facade defensive.

Pas de consumer backend des routes R2 keybuzz-api detecte (pas de proxy inverse vers `/channels`, `/suppliers`, etc.).

### 4.4 Worker / cron

`startOctopiaSyncWorker` importe dans app.ts:2. Worker interne au pod keybuzz-api. Pas de probe externe declenchee par audit (read-only strict). A confirmer en AS.14.x : ce worker bouge des donnees per-tenant et appelle des services Octopia sans passer par les routes HTTP, donc pas de surface externe a guarder.

---

## 5. RUNTIME READ-ONLY PROBES

Probes safe GET/HEAD uniquement, DEV `api-dev.keybuzz.io`. Aucun POST/PATCH/DELETE. Aucun OAuth start. Aucun provider call. Aucun disconnect. Aucun login.

| Probe (DEV) | Resultat HTTP | Interpretation |
|---|---|---|
| `GET /channels` (no params) | 400 | tenantId required - validation OK, mais pas membership |
| `GET /channels?tenantId=00000000-0000-0000-0000-000000000000` | **200** | Membership ABSENT - any user can hit with arbitrary tenantId |
| `GET /channels/catalog?tenantId=fake` | **200** | Membership ABSENT |
| `GET /integrations/?tenantId=fake` | **200** | Membership ABSENT |
| `GET /integrations?tenantId=fake` | **200** | Membership ABSENT (trailing slash optional) |
| `GET /suppliers?tenantId=fake` | **200** | Membership ABSENT |
| `GET /shopify/status?tenantId=fake` | **200** | Membership ABSENT - provider state leak |
| `GET /attachments/channel-rules/amazon` (no tenant) | 200 | Public legitime (static config) |
| `GET /octopia/marketplaces/octopia/config` (no tenant) | 200 | Public legitime (aggregator config) |
| `GET /marketplaces/octopia/config` | 404 | Confirms double-prefix bug |
| `GET /octopia/status` | 404 | Confirms modules/octopia/routes.ts dead code |
| `GET /channel-rules?tenantId=fake` | 404 | Confirms modules/channel-rules/routes.ts dead code |

Aucune mutation declenchee. Aucun provider externe contacte. Aucun cookie de session presente dans les probes.

Logs DEV API 10 min : non scannes durant cette phase (read-only audit ne traverse pas plus loin pour eviter exposure secret). A relire en AS.14.x avant patch.

---

## 6. RISK MATRIX (disclosure-controlled, no PoC, no payload)

| ID | Risque | Surface | Impact | Severity | Confidence | Mitigation cible |
|---|---|---|---|---|---|---|
| R-CH-01 | Cross-tenant listing channels via tenantId arbitraire | GET /channels/, /channels/catalog, /channels/by-key | Disclosure liste channels + billing per-tenant | High | Confirmed | tenantGuard AS.14.1 |
| R-CH-02 | Cross-tenant mutation channels | POST /channels/add, /channels/remove, /channels/activate-amazon | Add/remove channels arbitrary tenant + Amazon activation hijack | Critical | Confirmed source-side | tenantGuard AS.14.1 |
| R-CH-03 | Billing exposure per-tenant | GET /channels/billing, /billing-compute | Pricing tier disclosure | Medium | Confirmed | tenantGuard AS.14.1 |
| R-SU-01 | Cross-tenant listing suppliers | GET /suppliers, /suppliers/:id/cases | Supplier names, addresses, support email | High | Confirmed | tenantGuard AS.14.2 |
| R-SU-02 | Cross-tenant mutation suppliers | POST /suppliers, PUT/DELETE /:id, /supplier-cases/* | CRUD suppliers + send-email outbound | Critical | Confirmed source-side | tenantGuard AS.14.2 |
| R-SU-03 | Outbound email send hijack | POST /supplier-cases/:id/send-email | Send arbitrary email per tokenized Reply-To | Critical | Confirmed source-side | tenantGuard AS.14.2 + WHERE tenant_id |
| R-SU-04 | Supplier inbound webhook reachability | POST /supplier-inbound | If publicly reachable, inject fake supplier replies | High | Unknown until infra check | NetworkPolicy or X-Internal-Token verification (AS.14.2b infra) |
| R-IN-01 | Cross-tenant integrations | GET /integrations/, /:pk | Read integrations config | Medium | Confirmed | tenantGuard AS.14.3 |
| R-OC-01 | Cross-tenant Octopia state + orders | 12 endpoints under /octopia/marketplaces/octopia/* | Order data + tenant integration state | High | Confirmed source-side | tenantGuard AS.14.6 |
| R-OC-02 | Cross-tenant Octopia mutation (sync/connect/disconnect/import/backfill) | POST /octopia/marketplaces/octopia/{connect,disconnect,sync,import,backfill} | Trigger imports + provider calls for other tenants | Critical | Confirmed source-side | tenantGuard AS.14.6 |
| R-SH-01 | Cross-tenant Shopify state | GET /shopify/status | Provider connection state per tenant | High | Confirmed | tenantGuard AS.14.5 |
| R-SH-02 | Cross-tenant Shopify mutation | POST /shopify/connect, /disconnect, /orders/sync | OAuth init + sync trigger + disconnect for other tenants | Critical | Confirmed source-side | tenantGuard AS.14.5, exempt /shopify/callback |
| R-WK-01 | Shopify webhook bypass HMAC | POST /webhooks/shopify | Theoretical (HMAC pinned) | Low | Mitigated | n/a (KEEP exempt) |
| R-PR-01 | Octopia double-prefix bug | All 13 octopia routes | Confusion functional, frontend not affected | Low | Confirmed | Out of scope security ; fix in AS.14.6 documentation |

Total risques heritage R2 : 14 dont 1 deja mitigated (R-WK-01) et 1 hors-scope security (R-PR-01).

---

## 7. PLAN AS.14.x (decoupage propose)

Six sous-phases DEV first, chacune small scope, build + GitOps + validation negative-only par phase, QA Ludovic UI legitime obligatoire avant promotion PROD. Rollback par phase via tag immuable precedent.

| Phase | Scope | Endpoints | Priority | Repos build | QA UI obligatoire | Rollback tag |
|---|---|---|---|---|---|---|
| AS.14.1 | channels | 8 (incl activate-amazon) | High | keybuzz-api | Channels page (admin) + Amazon activation flow | v3.5.189-compat-amazon-tenantguard |
| AS.14.2 | suppliers | 11 protected + clarify /supplier-inbound | High | keybuzz-api | Suppliers page + supplier-cases flow + outbound email simulation | v3.5.190 (AS.14.1) |
| AS.14.3 | integrations | 2 | Medium | keybuzz-api | Integrations settings page | v3.5.191 (AS.14.2) |
| AS.14.4 | (skip) channel-rules attachments static | 0 (no patch) | n/a | n/a | confirm public legitimate | n/a |
| AS.14.5 | shopify (3 to protect + exempt /callback + KEEP /webhooks/shopify) | 4 protected | High | keybuzz-api | Shopify connect/disconnect flow + sync UI + webhook smoke (HMAC test in DEV only) | v3.5.192 (AS.14.3) |
| AS.14.6 | marketplaces/octopia | 12 protected + exempt /config | High | keybuzz-api | Octopia connect + sync UI + orders display | v3.5.193 (AS.14.5) |
| AS.14.7 | closeout audit + DB AND tenant_id defense-in-depth follow-up tickets | 0 patch (audit) | Medium | n/a | n/a | n/a |

Sous-phase optionnelle :
- **AS.14.2b infra** : verifier `/supplier-inbound` ingress NetworkPolicy ou X-Internal-Token (out of source code scope) avant promotion PROD AS.14.2.

Pattern technique recommande :
- AS.14.1, AS.14.3, AS.14.5, AS.14.6 : `PROTECTED_ROUTES` static list (paths fixes connus).
- AS.14.2 : mix static (suppliers root paths) + matcher dynamique pour `/suppliers/:id`, `/supplier-cases/:id/...` (params variables).
- Toutes phases : reutiliser `extractTenantId` existant ; pas de nouveau plugin.
- Toutes phases : confirmer aucun BFF cote Client a creer (consumer existant utilise session JWT + tenantId).

Build-from-Git pattern KEY-309 + KEY-308 (OCI labels) deja en place. Aucun changement de scripts.

---

## 8. RAPPORT

Ce document publie : `keybuzz-infra/docs/PH-SAAS-T8.12AS.14.0-R2-CHANNELS-SUPPLIERS-INTEGRATIONS-OAUTH-TRUTH-AUDIT-01.md`. ASCII strict, LF only, no BOM. Commit docs-only `docs(security): R2 channels suppliers integrations OAuth truth audit (KEY-314)`. Push direct sur `origin/main`.

---

## 9. LINEAR

Commentaire propose pour KEY-314 (disclosure-controlled, sans PoC, sans payload, sans secret) :

```
PH-SAAS-T8.12AS.14.0 truth audit livre.

Perimetre R2 cartographie : channels (8), suppliers (12), integrations (2), marketplaces/octopia (13), shopify (5), shopifyWebhook (1). Plus compat Amazon (6) deja ferme par KEY-313 AS.13.3A.

Total inventaire : 48 endpoints. Statut actuel :
- 6 deja proteges (compat Amazon)
- 30 a proteger via tenantGuard (T)
- 6 exempts documentes : 1 inbound gateway (I), 1 OAuth callback Shopify (O), 1 webhook HMAC Shopify (W), 3 publics sans tenant data (P)

Probes runtime DEV read-only :
- GET /channels, /integrations, /suppliers, /shopify/status retournent 200 avec tenantId arbitraire et sans auth
- Confirmation absence membership check sur 6 surfaces probed

Risques cross-tenant identifies (sans PoC) :
- R-CH-* channels listing + mutation + billing (8 endpoints)
- R-SU-* suppliers listing + mutation + outbound email send (11 endpoints) + 1 inbound gateway (a confirmer infra)
- R-IN-* integrations listing (2 endpoints)
- R-OC-* octopia status + orders + mutation (12 endpoints)
- R-SH-* shopify status + mutation (3 endpoints, exempt /callback)
- R-PR-01 bug double-prefix octopia (fonctionnel non-security, a corriger en AS.14.6)
- R-WK-01 webhook HMAC pinned : already mitigated, keep exempt

Decoupage AS.14.x propose :
- AS.14.1 channels
- AS.14.2 suppliers (avec verification ingress /supplier-inbound)
- AS.14.3 integrations
- AS.14.4 (no patch) channel-rules attachments
- AS.14.5 shopify (exempt /callback + KEEP /webhooks/shopify HMAC)
- AS.14.6 marketplaces/octopia (exempt /config)
- AS.14.7 closeout + tickets defense-in-depth

Hors scope security mais a noter :
- 3 fichiers dead code (modules/octopia/routes.ts, modules/channel-rules/routes.ts, modules/suppliers/routes.ts)
- 1 fichier .bak left-over keybuzz-backend (amazon.routes.ts.bak)

KEY-314 reste Open. KEY-301 et KEY-313 restent Done. Aucun patch, build, deploy, mutation DB ou changement Linear status sans GO Ludovic.

Rapport : keybuzz-infra/docs/PH-SAAS-T8.12AS.14.0-R2-CHANNELS-SUPPLIERS-INTEGRATIONS-OAUTH-TRUTH-AUDIT-01.md
```

Aucun changement de statut Linear effectue par cette phase.

---

## 10. NO FAKE EVENTS / NO PROVIDER CALLS

Confirme :
- Aucun OAuth start declenche
- Aucun callback OAuth simule
- Aucun disconnect provider
- Aucune mutation DB
- Aucun token exchange
- Aucun refresh token
- Aucun webhook emis
- Aucun email envoye
- Aucune connexion provider tierce contactee (Shopify, Octopia, Amazon)
- Probes runtime limites a GET safe avec tenantId factice 00000000-0000-0000-0000-000000000000 sans cookie

---

## 11. GAPS / UNKNOWNS

| Gap | Statut | Resolution AS.14.x |
|---|---|---|
| /supplier-inbound : protocole d acces (NetworkPolicy ? X-Internal-Token ? gateway pull ?) | UNKNOWN | AS.14.2b infra check pre-patch |
| Worker octopiaSyncWorker : surface interne, pas de route HTTP exposee | UNKNOWN | Confirmer en AS.14.6 (lecture code worker) |
| Logs API DEV 10 min : non scannes (eviter exposure) | DEFERRED | A relire en AS.14.x si suspicion de consumer ignore |
| Channel-rules ?api-only? : Client UI utilise /api/channels/registry et /api/channel-rules en BFF Next, alors que API expose seulement /attachments/channel-rules/:channel. Verifier consumer BFF Client | UNKNOWN | AS.14.4 (out of scope security, simple confirmation) |
| Amazon callback chemin reel : `fetchBackend(/api/v1/marketplaces/amazon/oauth/start)` pointe backend, mais le retour Amazon va ou ? Verifier en AS.14.x avant tout patch sur /channels/activate-amazon | UNKNOWN | AS.14.1 dependency on Amazon flow trace |

Aucun de ces gaps n est bloquant pour la decision AS.14.1+ DEV first. Tous sont resolvables au pre-flight de chaque sous-phase.

---

## 12. PHRASE CIBLE FINALE

R2 surface cartographiee : 48 endpoints inventories, 30 a proteger via tenantGuard, 6 exempts documentes, 6 deja fermes. Risques cross-tenant disclosure-controlled. Decoupage AS.14.1+ DEV first valide. Aucun patch sans GO Ludovic. KEY-314 reste Open.

STOP
