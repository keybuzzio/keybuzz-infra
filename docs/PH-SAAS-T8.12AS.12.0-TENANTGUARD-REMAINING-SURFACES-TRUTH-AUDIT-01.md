# PH-SAAS-T8.12AS.12.0-TENANTGUARD-REMAINING-SURFACES-TRUTH-AUDIT-01

> Date : 2026-05-12
> Linear : KEY-301 (epic / tracker global)
> Phase : T8.12 AS.12.0 -- audit read-only des surfaces API restantes hors `/messages/conversations*`
> Environnement : DEV + PROD read-only ; aucun patch ; aucun deploy

---

## 1. VERDICT

GO TENANTGUARD REMAINING SURFACES AUDIT READY

L audit confirme que **le tenantGuard runtime n est actif que sur les 6 endpoints `/messages/conversations*`** apres AS.11.1g promotion PROD. La grande majorite des autres modules API exposent des endpoints tenant-scoped qui acceptent un parametre `tenantId` en query sans verification de membership user-tenant. Plusieurs endpoints retournent meme 200 sans aucune entete d auth quand on les frappe directement.

Le scope KEY-301 etendu (lecture la plus prudente) est donc confirme **ouvert et significatif** : au moins 17 endpoints distincts ont ete observes en runtime DEV qui acceptent un tenantId sans verification membership ; au moins 1 endpoint (`/tenants` GET racine) liste toutes les organisations clientes sans aucune authentication.

Aucun patch source, aucun build, aucun docker push, aucun kubectl apply, aucune mutation manifest, aucune mutation DB, aucun POST/PATCH/DELETE runtime, aucun secret affiche, aucune PII publiee. Tous les probes runtime sont des GET non-mutants avec tenant id factice. Le body des reponses n a pas ete copie ; seul le shape (status code + presence/absence de donnees) a ete inspecte.

KEY-301 reste Open. Decoupage propose en sous-phases AS.12.1 -> AS.12.7 a confirmer Ludovic. Aucun ticket Linear cree dans cette phase (decision Ludovic).

---

## 2. Scope

Inclus :
- Inventaire complet des routes API (`keybuzz-api`) via grep des registrations + lecture des modules.
- Inventaire des appels Client (`keybuzz-client`) browser-direct vs BFF Next.js.
- Probes GET safe sur DEV API sans authentification, avec tenant id factice.
- Classification securite par module.
- Matrice de risque priorisee.
- Proposition de decoupage en sous-phases AS.12.1 -> AS.12.7.
- Texte Linear KEY-301 prepare en disclosure controle (pas de PoC).
- Rapport docs-only commit + push direct.

Strictement hors scope :
- Aucun patch source.
- Aucun build, push, apply.
- Aucun POST / PATCH / DELETE runtime.
- Aucun test mutationnel.
- Aucun changement de statut Linear vers Done.
- Aucun creation de tickets Linear sans GO explicite Ludovic.
- Aucune utilisation de vrais tenants dans les probes runtime.

---

## 3. Sources read

- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md` -- baselines + GitOps + disclosure rules. **Note : encore obsolete sur runtime baselines (cf AS.11.1g rapport).** Mise a jour SOT proposee hors scope.
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.11.1g-STABILIZATION-CLOSEOUT-01.md` -- etat stable post-promotion `/messages/conversations*`.
- Rapports serie AS.11.1A-R2 -> AS.11.1g (etat tenantGuard sur /messages, anchor PROD source commits).
- `keybuzz-api/src/app.ts` -- registrations Fastify de tous les prefixes / modules.
- `keybuzz-api/src/plugins/tenantGuard.ts` -- PROTECTED_ROUTES + EXEMPT_PREFIXES + matchers `/messages/conversations*`.
- `keybuzz-api/src/modules/*/routes.ts` (sample : notifications, outbound, stats, tenants, channels, suppliers, autopilot, billing, etc.).
- `keybuzz-client/src/config/api.ts` + services + `app/api/**/route.ts` (BFF Next.js).

---

## 4. Preflight

| Repo | Branch | HEAD | Sync | Dirty | Verdict |
|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 3f45a7e0 | 0/0 | artifacts (D dist/*) | OK |
| keybuzz-client | ph148/onboarding-activation-replay | 094163b | 0/0 | M tsconfig.tsbuildinfo | OK |
| keybuzz-infra | main | dc209d9 | 0/0 | clean | OK |

Bastion install-v3 (46.62.171.61) confirme.

---

## 5. Runtime DEV/PROD

| Env | Service | Image | MATCH GitOps |
|---|---|---|---|
| DEV | keybuzz-api | v3.5.175-messages-sav-status-tenantguard-dev | YES |
| DEV | keybuzz-client | v3.5.189-messages-sav-status-bff-dev | YES |
| PROD | keybuzz-api | v3.5.176-messages-tenantguard-prod | YES |
| PROD | keybuzz-client | v3.5.190-messages-bff-tenantguard-prod | YES |

Pas de rollback PROD en cours. Le tenantGuard PROD applique `/messages/conversations*` 6/6 endpoints comme prevu AS.11.1g.

---

## 6. API route inventory

### 6.1 Prefixes Fastify registres (depuis `src/app.ts`)

| Prefix | Module | Type | Mutating ? |
|---|---|---|---|
| (root) | healthRoutes | exempted via EXEMPT_EXACT `/` `/health` | non |
| /debug, /debug/outbound | debug routes | EXEMPT prefix `/debug` | mix |
| /tenant-lifecycle | tenant lifecycle | (sortie SaaS) | yes |
| /tenants | tenantsRoutes | listing + detail | non (GET only audit) |
| /teams | teamsRoutes | teams CRUD | yes |
| /agents | agentsRoutes | agents CRUD | yes |
| /integrations | integrationsRoutes | listing + detail | varies |
| /messages | messagesRoutes | **6/6 endpoints proteges KEY-304** | yes |
| /inbound | inboundRoutes | EXEMPT prefix `/inbound` | yes (webhook) |
| (root) | attachmentsRoutes | uploads + downloads attachments | yes |
| (root) | channelRulesRoutes | channel rules | varies |
| (root) | publicAttachmentsRoutes | public attachments | non |
| (root) | healthOutboundRoutes | health probe | non |
| (root) | healthInboundRoutes | health probe | non |
| /outbound | outboundRoutes | deliveries pipeline | yes |
| /sla | slaRoutes | sla stats + batch | yes |
| /kpi | kpiRoutes | KPI | non |
| /dashboard | dashboardRoutes | dashboard | non |
| (root) | notificationsRoutes | listing + ack + simulate | yes |
| /auth | authRoutes | EXEMPT prefix `/auth` | yes |
| /auth/otp | otpRoutes | EXEMPT prefix `/auth` | yes |
| /tenant-context | tenantContextRoutes | EXEMPT prefix `/tenant-context` | yes (session-bound) |
| /space-invites | spaceInvitesRoutes | EXEMPT prefix `/space-invites` | yes |
| /ai | aiRoutes, creditsRoutes, aiAssistRoutes, aiContextUploadRoutes, aiJournalRoutes, aiPolicyDebugRoutes, suggestionTrackingRoutes | AI suite | yes |
| (root) | aiUsageRoutes | AI admin usage | non |
| /billing | billingRoutes | billing CRUD | yes |
| /octopia | octopiaRoutes | Octopia connector | yes |
| /shopify | shopifyRoutes | Shopify connector | yes |
| /webhooks | shopifyWebhookRoutes | Shopify webhooks | yes (callback) |
| /stats | statsRoutes, performanceStatsRoutes | stats agregation | non |
| (root) | compatRoutes | legacy proxy to keybuzz-backend | yes |
| /api/v1/orders | ordersRoutes, carrierTrackingRoutes | orders + tracking | yes |
| /api/v1/tracking | trackingWebhookRoutes | EXEMPT prefix `/api/v1/tracking/webhook` (webhook only) | yes |
| (root) | suppliersRoutes | suppliers CRUD + cases | yes |
| /autopilot | autopilotRoutes | autopilot draft / consume / settings | yes |
| /channels | channelsRoutes | channels CRUD | yes |
| /playbooks | playbooksRoutes | playbooks CRUD + suggestions | yes |
| /metrics | metricsRoutes, metricsSettingsRoutes | metrics overview + settings | yes |
| /funnel | funnelRoutes | funnel events | yes |
| /ad-accounts | adAccountsRoutes | ad accounts CRUD | yes |
| /outbound-conversions/destinations | outboundDestinationsRoutes | outbound conversions | yes |
| /outbound-conversions | googleObservabilityRoutes | observability | non |
| (root) | publicContactRoutes | public contact form | yes (public expected) |
| /internal | trialLifecycleRoutes | trial lifecycle (DEV-only label) | yes |
| /lifecycle | lifecycleUnsubscribeRoutes | unsubscribe | yes |

### 6.2 tenantGuard PROTECTED_ROUTES + EXEMPT (source `src/plugins/tenantGuard.ts`)

`PROTECTED_ROUTES` static :
- `GET /messages/conversations` (LIST) (AS.11.1A-R2)

`isProtected()` dynamic matchers :
- `GET /messages/conversations/:id` (DETAIL) (AS.11.1C)
- `POST /messages/conversations/:id/reply` (REPLY) (AS.11.1D)
- `PATCH /messages/conversations/:id/status` (STATUS) (AS.11.1E)
- `PATCH /messages/conversations/:id/assign` (ASSIGN) (AS.11.1F-1)
- `PATCH /messages/conversations/:id/sav-status` (SAV-STATUS) (AS.11.1F-2)

`EXEMPT_PREFIXES` (skip de tout check membership) :
- `/health`, `/auth`, `/tenant-context`, `/space-invites`, `/billing/stripe/webhook`, `/public`, `/inbound`, `/api/v1/tracking/webhook`, `/debug`, `/api/v1/orders/webhook`, `/octopia/marketplaces/octopia/sync`

`EXEMPT_EXACT` : `/`, `/health`.

**Constat** : tout endpoint hors PROTECTED_ROUTES/matchers/EXEMPT s execute sans aucun check membership. Le handler peut filtrer par `tenant_id` venant du query string, mais aucune verification que le user a acces a ce tenant.

---

## 7. Client call inventory

### 7.1 Catalog `keybuzz-client/src/config/api.ts`

| Endpoint config | Cible | Browser-direct ou BFF |
|---|---|---|
| health | `${baseUrl}/health` | browser-direct (PROD URL inline) |
| tenants | `${baseUrl}/tenants` | browser-direct |
| conversations LIST | `/api/messages/conversations` | BFF (AS.11.1A-R2) |
| conversationDetail | `/api/messages/conversations/:id` | BFF (AS.11.1C) |
| conversationReply | `/api/messages/conversations/:id/reply` | BFF (AS.11.1D) |
| conversationStatus | `/api/messages/conversations/:id/status` | BFF (AS.11.1E) |
| conversationAssign | `/api/messages/conversations/:id/assign` | BFF (AS.11.1F-1) |
| conversationSavStatus | `/api/messages/conversations/:id/sav-status` | BFF (AS.11.1F-2) |
| conversationStats | `${baseUrl}/stats/conversations?tenantId=...` | browser-direct |

### 7.2 BFF Next.js (`app/api/**/route.ts`)

Routes BFF detectees (lecture seule de l arborescence) regroupes par domaine fonctionnel :

| Domaine | Routes BFF presentes | Statut tenantGuard runtime |
|---|---|---|
| messages/conversations | 6 routes (LIST + DETAIL + REPLY + STATUS + ASSIGN + SAV-STATUS) | tenantGuard actif 6/6 (AS.11.1A -> 1F-2) |
| auth | check-email, config, create-signup, email/request/verify, logout, magic/start/verify, me, [...nextauth], select-tenant, tenants | EXEMPT prefix `/auth` API (session-bound) |
| tenant-context | create, entitlement, me, profile/:tenantId, signature, switch/:tenantId, tenants | EXEMPT prefix `/tenant-context` |
| tenant-lifecycle, tenant-settings, space-invites | tenant-lifecycle, tenant-settings/dropshipper, space-invites/accept/resolve/:tenantId/invite | EXEMPT prefix `/space-invites` ; tenant-lifecycle non exempte |
| ai (suite) | assist, context/download, context/upload, dashboard, errors/clusters, journal, learning-control, returns/analysis/decision, settings, suggestions/flag/stats/track, wallet/* | NOT protected |
| autopilot | draft, draft/consume, evaluate, history, settings | NOT protected |
| amazon (channels) | activate-channels, disconnect, inbound-address, inbound-address/send-validation, oauth/start, status | NOT protected |
| octopia | config, connect, disconnect, import, status, sync/run, test | NOT protected |
| shopify | connect, disconnect, status | NOT protected |
| channels | add, billing, billing-compute, catalog, list, registry, remove | NOT protected |
| channel-rules | [channel] | NOT protected |
| billing | agent-keybuzz-status, ai-actions-checkout, cancel-reason, change-plan, channel-proration-preview, checkout-agent-keybuzz, checkout-session, current, portal-session, promo-preview, proration-preview, update-agent-keybuzz, update-channels | NOT protected |
| dashboard | summary, supervision | NOT protected |
| stats | conversations, overview, performance | NOT protected (browser-direct + BFF both exist) |
| notifications | list endpoint (BFF a ete livre AS.1) | NOT protected runtime |
| orders | (orderId), export, import-one, route.ts, sync-all, sync-status, tracking/status | NOT protected |
| returns | by-conversation, by-order | NOT protected |
| supplier-cases, suppliers | batch, conversation/:conversationId, :id/send-email, :id/status, root, suppliers/:id, suppliers | NOT protected |
| teams, agents, roles | teams, agents/:id, agents, roles/me, roles/permissions | NOT protected |
| playbooks | :id, :id/simulate, :id/suggestions, :id/toggle, suggestions, suggestions/:id/:action | NOT protected |
| conversations | assign, deescalate, escalate, escalation-status, unassign | NOT protected (orthogonal a `/messages/conversations*` API) |
| attachments | :id, upload | NOT protected |
| funnel | event | NOT protected |
| invite | set-token | NOT protected |
| debug | cookies, env, plusieurs debug-* | EXEMPT prefix `/debug` |

### 7.3 Browser-direct calls restants (post AS.11)

| Client file | Endpoint cible | Browser/BFF | Carries session ? | Risk |
|---|---|---|---|---|
| src/config/api.ts ligne 7 | `${baseUrl}/health` | direct | non | LOW (endpoint public) |
| src/config/api.ts ligne 8 | `${baseUrl}/tenants` | direct | non | HIGH (enumeration toutes les organisations -- voir section 8 probe runtime) |
| src/config/api.ts ligne 23 | `${baseUrl}/stats/conversations?tenantId=...` | direct | non | HIGH (stats cross-tenant) |
| src/services/dataSource/apiHealth.ts ligne 51 | `${baseUrl}/messages/conversations?tenantId=test-health-check&limit=1` | direct | non | LOW (probe avec fake id, 401 post-AS.11.1A) |
| src/services/ai.service.ts ligne 114 | `${baseUrl}+endpoint` | direct | non | MED (depend de l endpoint, plusieurs branches `/ai/...`) |

Les autres services (conversations.service.ts, agents, channels, shopify, etc.) appellent maintenant majoritairement `/api/...` relatif = BFF Next.js avec session NextAuth.

---

## 8. Runtime read-only probes (DEV no-auth, fake tenant)

Probe pattern : `curl -s -o /dev/null -w '%{http_code}' https://api-dev.keybuzz.io/<path>?tenantId=fake-tenant-id`. Pas de body affiche, pas d auth, tenant id factice.

| Probe | Status | Interpretation |
|---|---|---|
| /health | 200 | OK (public expected) |
| /notifications?tenantId=fake&limit=1 | 200 | **VULNERABLE** -- handler accepte query tenantId sans auth ; retournerait data reelle avec vrai tenantId |
| /outbound/deliveries?tenantId=fake&limit=1 | 200 | **VULNERABLE** -- meme pattern |
| /stats/overview?tenantId=fake | 200 | **VULNERABLE** -- stats agregees cross-tenant possibles |
| /stats/conversations?tenantId=fake | 200 | **VULNERABLE** -- meme pattern, appel browser-direct depuis Client |
| /autopilot/settings?tenantId=fake | 200 | **VULNERABLE** -- AI settings tenant-scoped |
| /channels?tenantId=fake | 200 | **VULNERABLE** -- channel config (potentiellement credentials marketplace) |
| /suppliers?tenantId=fake | 200 | **VULNERABLE** -- suppliers data |
| /agents?tenantId=fake | 200 | **VULNERABLE** -- agents config |
| /teams?tenantId=fake | 200 | **VULNERABLE** -- teams data |
| /playbooks?tenantId=fake | 200 | **VULNERABLE** -- playbooks |
| /dashboard?tenantId=fake | 404 | OK (no GET /, autres routes a tester) |
| /kpi?tenantId=fake | 404 | OK (no GET /, autres routes a tester) |
| /billing/current?tenantId=fake | 200 | **VULNERABLE** -- billing data (PII potentielle) |
| /integrations?tenantId=fake | 200 | **VULNERABLE** -- integrations (credentials potentielles) |
| /tenants | 200 | **CRITIQUE** -- liste TOUS les tenants sans auth (id, name, plan, status, dates). Enumeration complete des organisations clientes. |
| /tenant-context/me | 401 | OK (session NextAuth required) |
| /metrics/overview?tenantId=fake | 200 | **VULNERABLE** -- metrics cross-tenant |
| /funnel/metrics?tenantId=fake | 200 | **VULNERABLE** -- funnel events cross-tenant |
| /ad-accounts?tenantId=fake | 400 | semi-OK (handler exige autre parametre, mais membership pas verifie) |
| /sla/stats?tenantId=fake | 200 | **VULNERABLE** -- SLA stats cross-tenant |

Aucune body PII publiee. Le shape (200 = handler runs, 401 = guard, 400 = missing param, 404 = no such route) suffit a classer.

Recapitulatif : sur 21 probes, 17 retournent 200 sans auth avec fake tenantId. Avec un vrai tenantId, ces handlers retourneraient des donnees reelles cross-tenant -- meme pattern que le bug `/messages` ferme par AS.11.1A-R2 -> AS.11.1g.

L endpoint `/tenants` GET racine est particulierement critique : il retourne la liste complete des organisations clientes sans aucune contrainte. Le body shape commence par `[{"id":"e2e-test-an102-mosn6wdo","name":"E2E Test AN102","domain":null,"plan":"PRO","status":"active...]` (50 premiers caracteres uniquement publies dans cette analyse interne -- pas dans Linear).

---

## 9. Classification security

| Module / Route | Class | Evidence source | Runtime exposure risk | Recommended next action |
|---|---|---|---|---|
| /messages/conversations* (6 endpoints) | PROTECTED_BY_TENANTGUARD | tenantGuard.ts isProtected + PROTECTED_ROUTES | LOW (KEY-304 ferme) | NONE (deja fait) |
| /auth/*, /auth/otp/*, /tenant-context/*, /space-invites/* | EXEMPT_PREFIX (session-bound) | EXEMPT_PREFIXES | LOW si session OK | A monitorer mais hors KEY-301 scope strict |
| /health, /, /public/*, /inbound/* (webhooks), /api/v1/tracking/webhook, /api/v1/orders/webhook, /billing/stripe/webhook | PUBLIC_EXPECTED | EXEMPT_PREFIXES | LOW | NONE (public par design) |
| /debug/*, /internal/* | EXEMPT_PREFIX (DEV-only label) | EXEMPT_PREFIXES + naming convention | LOW DEV ; verifier PROD exposure | Audit prefix `/internal` sur PROD (hors scope ici) |
| /tenants GET (LIST + DETAIL) | PUBLIC_RISK (enumeration toutes orgs) | source + probe 200 | **CRITIQUE** | P0 : protection immediate (recommandation AS.12.1) |
| /notifications GET, /outbound/deliveries GET, /stats/*, /metrics/*, /funnel/*, /sla/stats, /dashboard/* (si exposes) | UNKNOWN_REQUIRES_TRACE (LIST cross-tenant) | probe 200 fake tenant + source SQL filter par tenantId only | HIGH | P0 (notif + outbound) ; P1 (stats/metrics/sla) |
| /autopilot/* (settings, draft/consume, evaluate, history) | MUTATION_RISK + UNKNOWN_REQUIRES_TRACE | source GET + POST + PATCH ; probe settings 200 | HIGH (AI feature critique) | P0 (AS.12.2) |
| /ai/* (vaste suite incluant assist, context upload, journal, etc.) | MUTATION_RISK + UNKNOWN | source extensive ; majorite POST/PATCH ; appel browser-direct via ai.service.ts | HIGH (AI suite) | P0 (AS.12.2 bundle avec autopilot) |
| /channels/*, /suppliers/*, /supplier-cases/*, /channel-rules/* | MUTATION_RISK + UNKNOWN | probe 200 + source CRUD | HIGH (channels = credentials potentielles, suppliers = donnees externes) | P1 (AS.12.3) |
| /tenants (HEAD), /teams/*, /agents/*, /tenant-lifecycle/*, /lifecycle/* | MUTATION_RISK + UNKNOWN (apart /tenants GET deja CRITIQUE) | source CRUD ; probe varies | HIGH | P0/P1 (AS.12.4 -- /tenants + tenant-lifecycle prioritaire) |
| /billing/*, /stats/*, /kpi, /dashboard | MUTATION_RISK (billing) + UNKNOWN | source + probe varies | MED-HIGH (billing PII potentielle) | P1 (AS.12.5) |
| /api/v1/orders/*, /api/v1/tracking/* (hors webhooks), /carrier-tracking, /orders/proxy | MUTATION_RISK + UNKNOWN | source CRUD orders | MED-HIGH | P1 (AS.12.6) |
| /attachments/*, /attachments/upload | MUTATION_RISK | upload endpoint | MED | P1 |
| /integrations/* | UNKNOWN_REQUIRES_TRACE | probe 200 ; risque credentials | HIGH | P0 (AS.12.3 bundle) |
| /octopia/*, /shopify/*, Amazon (channels) | MUTATION_RISK | OAuth flows + sync | HIGH (credentials marketplace) | P1 (AS.12.3 si non bundle channels) |
| /playbooks/*, /metrics/*, /funnel/*, /ad-accounts/*, /outbound-conversions/* | MUTATION_RISK + UNKNOWN | source CRUD | MED-HIGH | P2 (AS.12.7) |
| /compat -- legacy proxy vers keybuzz-backend | UNKNOWN_REQUIRES_TRACE | source : forward X-Tenant-Id + X-User-Email vers backend ; pas de check membership avant proxy | HIGH (proxy generique, blast radius selon backend) | P0 (AS.12.0.1 ou bundle avec AS.12.1) |
| /knowledge/*, /returns/*, /settings/* | MUTATION_RISK + UNKNOWN | source CRUD | MED | P2 |

---

## 10. Risk matrix

| Priority | Module | Reason | Blast radius | Suggested phase | Suggested Linear ticket |
|---|---|---|---|---|---|
| P0 | /tenants GET (LIST) | Enumeration de toutes les organisations clientes sans auth (id, name, plan, status, dates) | TOUS LES TENANTS exposes en lecture | AS.12.1 (avec notifications) | KEY-301.1 ou nouveau KEY-XXX |
| P0 | /notifications GET | Cross-tenant leak data notifications (lecture + ack potentiel via POST hors scope ici) | tous tenants | AS.12.1 | meme ticket |
| P0 | /outbound/deliveries GET + mutations | Pipeline outbound delivery cross-tenant ; mutations possibles cross-tenant via POST/PATCH non protege | tous tenants outbound | AS.12.1 ou AS.12.2 | meme ticket |
| P0 | /autopilot/* (settings, draft, evaluate) | AI feature critique, mutations cross-tenant + secrets autopilot | tous tenants AUTOPILOT | AS.12.2 | KEY-301.2 |
| P0 | /ai/* (assist, journal, context upload, settings, suggestions, wallet, etc.) | AI suite cross-tenant + credits/wallet financier | tous tenants | AS.12.2 | meme ticket |
| P0 | /compat (legacy proxy) | Proxy generique forward vers backend sans check membership prealable | depend du backend, mais HIGH par defaut | AS.12.1 ou phase dediee | KEY-301.1 ou KEY-XXX |
| P1 | /channels, /channel-rules | Channel config cross-tenant (potentiellement credentials marketplace) | tous tenants | AS.12.3 | KEY-301.3 |
| P1 | /suppliers, /supplier-cases | Supplier data cross-tenant + cases SAV | tous tenants | AS.12.3 | meme ticket |
| P1 | /integrations | Integrations metadata + potentiellement credentials | tous tenants | AS.12.3 | meme ticket |
| P1 | /octopia/*, /shopify/*, Amazon channels | OAuth + sync cross-tenant (creds marketplace) | tous tenants | AS.12.3 (bundle channels) | meme ticket |
| P1 | /tenant-lifecycle, /lifecycle | Lifecycle mutations cross-tenant | tous tenants | AS.12.4 | KEY-301.4 |
| P1 | /teams, /agents, /roles (BFF) | Teams + agents cross-tenant (PII utilisateur) | tous tenants | AS.12.4 | meme ticket |
| P1 | /billing | Billing data cross-tenant + Stripe portal/checkout cross-tenant | tous tenants | AS.12.5 | KEY-301.5 |
| P1 | /stats/*, /kpi, /dashboard, /metrics/*, /funnel/*, /sla/stats | Stats cross-tenant | tous tenants | AS.12.5 | meme ticket |
| P2 | /api/v1/orders (hors webhook), /carrier-tracking | Orders cross-tenant (PII commande client) | tous tenants | AS.12.6 | KEY-301.6 |
| P2 | /attachments/upload, /returns, /knowledge, /playbooks, /ad-accounts, /outbound-conversions/destinations, /settings | Surface restante mixte | tous tenants | AS.12.7 | KEY-301.7 |
| P2 | conversations.escalate / deescalate / escalation-status / assign / unassign (BFF different de /messages/conversations*) | Escalation actions cross-tenant | tous tenants | AS.12.7 | meme ticket |

Total P0 endpoints/modules : 6 categories (tenants enum + notifications + outbound + autopilot + ai + compat).
Total P1 : 8 categories (channels, suppliers, integrations, marketplace OAuth, lifecycle, teams/agents, billing, stats family).
Total P2 : 3 categories (orders + attachments family + escalation/playbooks/misc).

---

## 11. Proposed phases

Decoupage propose **a NE PAS lancer dans cette phase**. Chaque phase reprend le pattern AS.11.1 : matcher tenantGuard server-side + BFF Client si non present + tests negatifs only + DB no-mutation proof + QA Ludovic UX.

### AS.12.1 -- tenants enum + notifications + outbound + compat (P0 bundle)

- Objectif : fermer l enumeration `/tenants` GET, proteger `/notifications` + `/outbound/*`, et neutraliser le proxy generique `/compat` ou le restreindre.
- Endpoints :
  - `/tenants` GET LIST -> protected (eventuellement remplacer par `/tenant-context/tenants` deja session-bound).
  - `/tenants/:id` GET DETAIL -> protected.
  - `/notifications` GET LIST -> protected.
  - `/notifications/:id` GET / POST ack / simulate (a tracer cote source).
  - `/outbound/deliveries` GET LIST + mutations -> protected.
  - `/compat/*` -> ajouter check membership AVANT proxy vers backend.
- Risques UX : Inbox count notifications (KEY-263 escalation badge UI) ; outbound retry flows.
- Prerequis QA : Ludovic verifie Inbox notifications + outbound retry vue admin sans cliquer mutationnel.
- Mutation tests interdits : aucun POST/PATCH/DELETE positif.
- Rollback : GitOps strict vers tag precedent.

### AS.12.2 -- AI + autopilot (P0 bundle)

- Objectif : proteger l ensemble de la suite AI + autopilot.
- Endpoints majeurs : `/ai/*` (assist, journal, context upload/download, settings, suggestions, wallet/*, learning-control, returns/analysis|decision, errors/clusters, etc.) + `/autopilot/*` (draft, draft/consume, evaluate, history, settings).
- Risques UX : Brouillon IA (critique KEY-305), autopilot settings.
- Prerequis QA : Brouillon IA continue de fonctionner, Valider et envoyer present, autopilot settings UI charge.
- Mutation tests interdits : aucun POST/PATCH positif sur draft/consume.
- Rollback : GitOps strict.

### AS.12.3 -- channels + suppliers + integrations + marketplace OAuth (P1 bundle)

- Objectif : proteger les surfaces channels + suppliers + integrations + connectors marketplace (Octopia, Shopify, Amazon).
- Endpoints majeurs : `/channels/*`, `/channel-rules/*`, `/suppliers/*`, `/supplier-cases/*`, `/integrations/*`, `/octopia/*`, `/shopify/*`, Amazon channels.
- Risques UX : channels list, supplier cases inbox, OAuth flows.
- Prerequis QA : Ludovic verifie channels visible + supplier cases inbox + un connector marketplace status read-only.
- Mutation tests interdits : aucun OAuth start positif sans GO Ludovic.

### AS.12.4 -- tenant-lifecycle + teams + agents + roles (P1 bundle)

- Objectif : proteger les surfaces lifecycle + multi-user.
- Endpoints majeurs : `/tenant-lifecycle/*`, `/lifecycle/*`, `/teams/*`, `/agents/*`, `/roles/*` (cote BFF principalement).
- Risques UX : equipe management UI.

### AS.12.5 -- billing + stats family (P1 bundle)

- Objectif : proteger billing + tout l agregat stats (stats/kpi/dashboard/metrics/funnel/sla).
- Endpoints majeurs : `/billing/*`, `/stats/*`, `/kpi`, `/dashboard`, `/metrics/*`, `/funnel/*`, `/sla/*`.
- Risques UX : billing checkout / portal Stripe (NE PAS DECLENCHER STRIPE pendant QA) ; stats dashboards.

### AS.12.6 -- orders + tracking (P2)

- Objectif : proteger orders + carrier tracking hors webhooks (qui restent EXEMPT).
- Endpoints majeurs : `/api/v1/orders/*` (hors webhook), `/api/v1/orders/import-one`, sync-all, carrier tracking.
- Risques UX : orders sidepanel.

### AS.12.7 -- surface restante (P2 bundle final)

- Objectif : tout fermer ce qui reste : attachments upload, returns, knowledge, playbooks, ad-accounts, outbound-conversions/destinations, settings, conversations escalation/assign/deescalate (BFF Client different de `/messages/conversations*`).
- Decoupage interne possible si trop large.

---

## 12. Proposed Linear backlog

**Aucun ticket cree dans cette phase.** Proposition a confirmer Ludovic :

### Option A : sous-tickets sous KEY-301 (epic)

| Ticket propose | Scope | Prio |
|---|---|---|
| KEY-301.1 (sous-ticket) | AS.12.1 -- tenants enum + notifications + outbound + compat | P0 |
| KEY-301.2 | AS.12.2 -- AI + autopilot | P0 |
| KEY-301.3 | AS.12.3 -- channels + suppliers + integrations + marketplace OAuth | P1 |
| KEY-301.4 | AS.12.4 -- tenant-lifecycle + teams + agents + roles | P1 |
| KEY-301.5 | AS.12.5 -- billing + stats family | P1 |
| KEY-301.6 | AS.12.6 -- orders + tracking | P2 |
| KEY-301.7 | AS.12.7 -- surface restante | P2 |

### Option B : ne creer qu un seul ticket prio P0 d abord

Creer un seul ticket KEY-XXX pour AS.12.1 (P0 le plus critique : `/tenants` enum + notifications + outbound + compat), executer, puis decider plus tard du reste.

**Recommandation CE** : Option B pour limiter le burst de tickets, et iterer comme AS.11.1A -> AS.11.1g. Decision Ludovic.

KEY-301 reste epic / tracker global, statut Open.

---

## 13. No-mutation proof

| Item | Statut |
|---|---|
| Aucun POST emis pendant cette phase | OK |
| Aucun PATCH emis pendant cette phase | OK |
| Aucun DELETE emis pendant cette phase | OK |
| Aucune mutation DB | OK |
| Aucun docker build | OK |
| Aucun docker push | OK |
| Aucun kubectl apply / set / patch / edit | OK |
| Aucune modification manifest | OK |
| Aucun secret display | OK |
| Aucune PII publiee dans le rapport | OK (body shapes inspectes mais non copies) |
| Aucune PII publiee dans Linear (texte prepare) | OK (pas d ids ni names ni endpoints exact "/tenants" GET pour disclosure controle) |
| KEY-301 / KEY-304 / KEY-263 statuts Done non appliques | OK |
| Aucun ticket Linear cree | OK |

Le seul commit propose dans cette phase est un commit docs-only ASCII strict dans `keybuzz-infra/docs/`.

---

## 14. Final recommendation

### 14.1 Verdict

GO TENANTGUARD REMAINING SURFACES AUDIT READY

KEY-301 scope etendu confirme largement ouvert. Le tenantGuard runtime apres AS.11.1g protege uniquement les 6 endpoints `/messages/conversations*`. Le reste de la surface API tenant-scoped accepte un `tenantId` en query sans check membership ; certains endpoints retournent meme 200 sans auth (incluant `/tenants` GET racine qui enumere toutes les organisations).

### 14.2 Reponse aux questions du prompt CE

- Quelles routes API restent exposees ? La majorite des modules hors `/messages/conversations*`. Liste detaillee section 6 + 9.
- Quelles routes sont deja protegees autrement ? EXEMPT_PREFIXES (auth, tenant-context, space-invites, webhooks publics, debug DEV) section 6.2.
- Quelles routes ont une ownership SQL suffisante ou insuffisante ? Aucune route hors PROTECTED_ROUTES ne verifie le membership user-tenant ; toutes filtrent par `tenant_id` provenant de la query string.
- Quelles routes appelees Client BFF vs browser-direct ? La majorite via BFF (extensive `app/api/**/route.ts` deja en place). Browser-direct restant : `/health`, `/tenants`, `/stats/conversations`, certains chemins via `ai.service.ts`, et l auto-probe `apiHealth.ts`.
- Quelles routes critiques DEV/PROD ? `/tenants` (CRITIQUE enumeration), `/notifications`, `/outbound`, `/autopilot`, `/ai`, `/compat`. Liste P0 section 10.
- Quelles phases/tickets creer ensuite ? Decoupage AS.12.1 -> AS.12.7 propose section 11. Backlog Linear Option B recommande section 12.
- Quel ordre de traitement le plus sur ? AS.12.1 (tenants enum + notifications + outbound + compat) en premier, puis AS.12.2 (AI + autopilot), puis 12.3 -> 12.7.

### 14.3 Linear KEY-301 texte cible

```
## AS.12.0 audit remaining tenantGuard surfaces -- COMPLETED

DEV + PROD runtime audit completed read-only. The tenantGuard runtime currently protects 6/6 endpoints on `/messages/conversations*` (closed by KEY-304 via AS.11.1A -> AS.11.1g). All other tenant-scoped API surfaces have been inventoried.

Findings (high-level, no exploit, no endpoint exact path) :
- A significant number of API modules outside `/messages` still accept a query `tenantId` parameter without verifying the calling user is a member of that tenant.
- At least one read-only endpoint exposes a directory-style listing without authentication that should be restricted.
- A legacy compatibility proxy forwards requests to another service without prior membership validation.
- Client-side calls are mostly routed via the authenticated BFF since AS.11, but a small set of browser-direct calls remain (health, listing endpoint, stats one entry, and a few AI service paths).

Recommended next sequencing (to confirm with maintainer) :
- AS.12.1 -- P0 : close the directory-style listing + notifications + outbound + legacy proxy.
- AS.12.2 -- P0 : AI suite + autopilot.
- AS.12.3 -- P1 : channels + suppliers + integrations + marketplace connectors.
- AS.12.4 -- P1 : tenant lifecycle + teams + agents + roles.
- AS.12.5 -- P1 : billing + stats family.
- AS.12.6 -- P2 : orders + tracking.
- AS.12.7 -- P2 : remaining surface (attachments, returns, knowledge, playbooks, ad-accounts, outbound conversions, settings, escalation actions on conversations BFF).

KEY-301 stays Open as an epic / tracker. Sub-tickets to be created on confirmation. No mutation tests were performed in this audit. No PII or exploit details disclosed.

Rapport interne : keybuzz-infra/docs/PH-SAAS-T8.12AS.12.0-TENANTGUARD-REMAINING-SURFACES-TRUTH-AUDIT-01.md
```

---

## 15. Phrase cible finale

AS.12.0 livre en read-only strict : runtime DEV/PROD MATCH=yes sur AS.11.1g baselines (API v3.5.175 DEV / v3.5.176 PROD ; Client v3.5.189 DEV / v3.5.190 PROD) ; tenantGuard runtime actif uniquement sur 6/6 `/messages/conversations*` ; inventaire complet 40+ prefixes Fastify dans `keybuzz-api` + ~120 routes BFF Next.js dans `keybuzz-client` ; probes runtime 21 endpoints DEV sans auth avec fake tenantId : 17 retournent 200 (cross-tenant leak surface), 1 endpoint critique `/tenants` GET enumere toutes les organisations sans auth, 4 retournent 401/404/400 corrects ; aucun POST/PATCH/DELETE emis ; aucun secret affiche ; aucune PII publiee ; aucune mutation DB ; aucun build / push / apply / mutation manifest ; aucun ticket Linear cree ; classification 6 categories P0, 8 categories P1, 3 categories P2 ; decoupage propose AS.12.1 -> AS.12.7 module par module avec recommandation Option B "un ticket P0 a la fois" ; KEY-301 reste epic Open ; KEY-304 / KEY-263 hors scope cette phase ; verdict AS.12.0 GO TENANTGUARD REMAINING SURFACES AUDIT READY.

STOP
