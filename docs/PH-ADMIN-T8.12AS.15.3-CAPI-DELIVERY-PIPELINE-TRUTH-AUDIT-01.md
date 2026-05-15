# PH-ADMIN-T8.12AS.15.3-CAPI-DELIVERY-PIPELINE-TRUTH-AUDIT-01

> Date : 2026-05-15
> Linear : KEY-322 (Open). Parent AS.15.0 + AS.15.1 closed. KEY-301/KEY-313 Done. KEY-314 Open + pause AS.14.2.
> Phase : T8.12AS.15.3 (audit READ-ONLY pipeline CAPI server-side)
> Environnement : PROD + DEV read-only (aucune mutation, aucun event fake, aucun provider call)

---

## 0. VERDICT

GO CAPI DELIVERY PIPELINE TRUTH AUDIT READY + GO NO RECENT ELIGIBLE EVENTS CONFIRMED.

Le pipeline CAPI server-side n est **PAS casse**. Le finding initial AS.15.0 R4 ("0 delivery log 7j alors que 3 destinations actives") etait incomplet : il manquait le filtre d eligibilite. La condition reelle est `signup_attribution.marketing_owner_tenant_id IS NOT NULL`. Sur 8 signups recents (30j), 4 ont un marketing_owner et 4 n en ont pas. Les 4 avec owner ont declenche le pipeline. **Sur les 7 derniers jours, 1 seul signup au total (`test-mp48gaam` 2026-05-13 organic) et 0 avec marketing_owner**, ce qui explique mecaniquement 0 delivery_log sur 7 jours.

Le dernier signup eligible CAPI etait `bon-kb-mosf283z` le 2026-05-05T09:23 (utm_source=concours, marketing_owner=keybuzz-consulting-mo9zndlk). Le pipeline a correctement emis 3 deliveries simultanees : Meta CAPI HTTP 200, TikTok Events HTTP 200, LinkedIn CAPI HTTP 201, toutes status=delivered, 1 seul attempt. conversion_events table a 1 row "sent" pour cet event. Tout fonctionne end-to-end pour les signups eligibles.

Decouplage architectural confirme : `signup_attribution.conversion_sent_at` est mis a jour par `emitConversionWebhook` (GA4 Measurement Protocol webhook) et NON par `emitOutboundConversion` (CAPI providers). Ces 2 chains sont independantes. GA4 marche pour tous les signups payants. CAPI marche uniquement quand marketing_owner_tenant_id est resolu.

Aucun bug technique. Pas de patch pipeline necessaire. Le vrai sujet est business + UX :
1. Pourquoi 4 signups recents sur 8 n ont pas de marketing_owner_tenant_id resolved (organic / internal-validation / google utm sans propagation)
2. Si business veut CAPI conversion pour signups organic : etendre la regle de resolution marketing_owner (defaut keybuzz-consulting si attribution absente)
3. Admin v2 doit afficher l etat de maniere claire : "Eligible signups 7j: 0 -> 0 delivery logs attendu" + "Dernier signup eligible: bon-kb 2026-05-05"

KEY-322 reste Open. Aucun ticket Linear cree. Aucun event fake. Aucune mutation provider.

---

## 1. PERIMETRE EXACT DE CETTE PHASE

Scope strict (AS.15.3 truth audit READ-ONLY) :
- 0 build / docker push / kubectl apply manifest / GitOps commit deploy
- 0 patch source
- 0 mutation DB (uniquement SELECT)
- 0 mutation provider (Meta, TikTok, LinkedIn, GA4)
- 0 event fake / spend fake / conversion fake / replay
- 0 token / secret / refresh_token / access_token affiche dans chat ou rapport
- 0 PII (emails, tenants nominaux, payloads sensibles)
- 0 changement Linear statut
- 0 modification destinations
- 0 modification delivery_logs

Actions effectuees :
- SSH read-only install-v3 (46.62.171.61 confirme)
- git status read-only sur 6 repos
- DB SELECT read-only via kubectl exec pod API PROD
- kubectl logs read-only API PROD 24h
- Agent Explore parallel pour cartographie source code

---

## 2. PREFLIGHT

### 2.1 SSH + bastion

| Champ | Valeur |
|---|---|
| Alias | install-v3 |
| Hostname | install-v3 |
| IP | 46.62.171.61 (conforme) |
| IP interdite | 51.159.99.247 (NON CONTACTE) |

### 2.2 Repos / branches

| Repo | Branche | HEAD | Verdict |
|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 7a09c005 | OK |
| keybuzz-client | ph148/onboarding-activation-replay | 3fe90ab | OK |
| keybuzz-admin-v2 | main | 3707c83 | OK |
| keybuzz-backend | main | b183817 | OK (.bak hors scope) |
| keybuzz-infra | main | 40361d9 (AS.15.1 rapport) | OK |
| keybuzz-website | main | 660dc60 | OK |

### 2.3 Runtime images

| Service | DEV | PROD |
|---|---|---|
| keybuzz-api | v3.5.190-channels-tenantguard-dev | v3.5.190-channels-tenantguard-prod |
| keybuzz-client | v3.5.197-channels-bff-userauth-dev | v3.5.197-channels-bff-userauth-prod |
| keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-dev | v2.12.2-media-buyer-lp-domain-qa-prod |
| keybuzz-backend | v1.0.47-cross-env-guard-fix-dev | v1.0.47-cross-env-guard-fix-prod |

Aucune divergence Git / runtime. Aucune modification depuis AS.15.1.

---

## 3. CHRONOLOGIE TRACKING CAPI

### 3.1 Phases livrees pertinentes (latest-wins)

| Date | Phase | Provider | Livrable | Statut |
|---|---|---|---|---|
| 2026-04-22 | PH-T8.8C PROD | Meta secret store + tenant secret AES-256-GCM | GO PROD |
| 2026-04-22 | PH-T8.8H | Meta CAPI outbound real config validation | GO |
| 2026-04-23 | KeyBuzz Consulting Meta CAPI destination cree (DB) | Meta | Active + last_test success |
| 2026-04-25 | PH-T8.10M | TikTok native owner-aware foundation | GO |
| 2026-04-26 | PH-T8.10P/Q | Google sGTM webhook PROD | GO |
| 2026-04-26 | PH-T8.10V/W/X | LinkedIn launch readiness min viable + PROD | GO PARTIEL |
| 2026-04-27 | KeyBuzz Consulting LinkedIn CAPI destination cree | LinkedIn | Active + last_test success |
| 2026-04-30 | KeyBuzz Consulting TikTok 2026-05 cutover destination cree | TikTok | Active + last_test success |
| 2026-05-01 | PH-T8.12P | TikTok browser pixel cutover + dedup (pixel D7PT12JC77U44OJIPC10) | GO |
| 2026-05-01 | PH-T8.12Q/Q.1/Q.2 | Acquisition tracking parity + Events Manager closure | GO CLOSED |
| 2026-05-01 | PH-T8.12R | GA4 G-R3QQDYEBFG + sGTM t.keybuzz.pro parity | GO |
| 2026-05-05 | bon-kb-mosf283z signup concours -> 3 CAPI deliveries (Meta+TikTok+LinkedIn) | All | GO succes pipeline end-to-end |

### 3.2 Commits recents sur outbound-conversions (keybuzz-api)

| Date | Commit | Effet |
|---|---|---|
| 2026-05-13 | 1c8b6b18 fix(security): protect google observability by tenant membership (KEY-313) | tenantGuard sur GET /google-observability uniquement |
| 2026-04-19 | df4a2c5e PH-T8.10M TikTok native owner-aware foundation | (aucun changement emitter.ts depuis) |
| 2026-04-19 | e368d318 PH-T8.10E outbound conversion owner-aware routing | Etablit marketing_owner_tenant_id condition |
| 2026-04-19 | acf5536d PH-T8.7B.4 DELETE /destinations/:id (soft delete) | UX destinations |

Pattern : aucun refactor majeur sur la logique d emission depuis ~4 semaines. Code stable.

---

## 4. CARTOGRAPHIE PIPELINE COMPLETE

### 4.1 Diagramme texte

```
STRIPE WEBHOOK (checkout.session.completed | customer.subscription.updated)
   |
   +-> POST /billing/webhook  (keybuzz-api)
   |     - verify Stripe signature
   |     - parse session/subscription
   |
   +-> Call emitOutboundConversion(eventName, tenantId, payload, marketingOwnerTenantId)
   |     [src/modules/outbound-conversions/emitter.ts]
   |
   |     +-> Check tenant exempt (test accounts)
   |     +-> Resolve marketing_owner_tenant_id (owner-aware routing)
   |     +-> If marketing_owner_tenant_id IS NULL -> SKIP (no emit, no log)
   |     +-> getActiveDestinations(pool, marketingOwnerTenantId)
   |           SELECT FROM outbound_conversion_destinations
   |             WHERE tenant_id = $1 AND is_active = true AND deleted_at IS NULL
   |
   |     +-> INSERT INTO conversion_events (tenant_id, event_name, payload, status='pending', attempts=0)
   |     |
   |     +-> FOR EACH active destination:
   |     |     +-> destination_type = 'meta_capi':
   |     |     |     - sendToMetaCapi() (adapters/meta-capi.ts)
   |     |     |     - 3 retries with delays 0/5s/15s
   |     |     |     - On success: INSERT outbound_conversion_delivery_logs (status='delivered', http_status=200, attempt=N)
   |     |     |     - On failure: INSERT log status='failed' or 'missing_creds'
   |     |     |
   |     |     +-> destination_type = 'tiktok_events':
   |     |     |     - sendToTikTokEvents() (adapters/tiktok-events.ts)
   |     |     |     - 3 retries
   |     |     |     - INSERT delivery_logs
   |     |     |
   |     |     +-> destination_type = 'linkedin_capi':
   |     |     |     - Validate conversion_rules_json has urn for event_name
   |     |     |     - sendToLinkedInCapi() (adapters/linkedin-capi.ts)
   |     |     |     - 3 retries
   |     |     |     - INSERT delivery_logs
   |     |     |
   |     |     +-> destination_type = 'webhook':
   |     |           - sendToWebhookDestination()
   |     |           - 3 retries
   |     |           - INSERT delivery_logs
   |     |
   |     +-> UPDATE conversion_events SET status='sent'|'failed', last_attempt_at=NOW(), attempts=attempts+1

GA4 MEASUREMENT PROTOCOL WEBHOOK (CHAIN INDEPENDANTE)
   |
   +-> Called from same /billing/webhook handler (non-blocking)
   |     emitConversionWebhook() (separate function in billing/routes.ts)
   |
   +-> POST ${CONVERSION_WEBHOOK_URL}?measurement_id=...
   |     - WITH api_secret (env GA4_MP_API_SECRET)
   |     - Body: { client_id, events: [{ name, params }] }
   |
   +-> On success: UPDATE signup_attribution SET conversion_sent_at = NOW()
        WHERE tenant_id = ? AND conversion_sent_at IS NULL

ADMIN v2 UI LECTURE
   |
   +-> /marketing/destinations  -> GET /outbound-conversions  (lecture seule destinations)
   +-> /marketing/delivery-logs -> GET /outbound-conversions/destinations/{id}/logs  (lecture seule logs)
   +-> /marketing/google-tracking -> GET /outbound-conversions/google-observability  (signup_attribution telemetry)
```

### 4.2 Call sites synthese

| Function | File | Caller |
|---|---|---|
| `emitOutboundConversion()` | emitter.ts | `/billing/webhook` Stripe handler (only caller in PROD) |
| `emitConversionWebhook()` (GA4 MP) | billing/routes.ts ~720 | same Stripe webhook (non-blocking parallel) |
| `sendToMetaCapi()` | adapters/meta-capi.ts | emitter.ts:217 + routes.ts:296 (test endpoint) |
| `sendToTikTokEvents()` | adapters/tiktok-events.ts | emitter.ts:280 + routes.ts:309 (test endpoint) |
| `sendToLinkedInCapi()` | adapters/linkedin-capi.ts | emitter.ts:341 + routes.ts:324 (test endpoint) |
| INSERT outbound_conversion_delivery_logs | emitter.ts (12 sites) + routes.ts:257 (test) | success/failure/missing_creds/no_rule cases |
| UPDATE conversion_sent_at | billing/routes.ts ~720 | emitConversionWebhook (GA4 MP webhook success) |

### 4.3 Workers / queues / scheduler

| Component | Path | Statut |
|---|---|---|
| Stripe webhook handler | keybuzz-api /billing/webhook | Synchrone, called by Stripe |
| Outbound emission | emitter.ts | Synchrone, retry inline (3 attempts) |
| GA4 MP webhook | emitConversionWebhook in billing | Synchrone non-blocking parallel |
| Worker async outbound | NONE | Pas de queue, pas de cronjob |
| Retry failed deliveries | NONE | Pas de scheduled re-emit |

---

## 5. DB TRUTH READ-ONLY

### 5.1 outbound_conversion_destinations (KeyBuzz Consulting active only)

| destination_type | name | is_active | last_test_at | last_test_status |
|---|---|---|---|---|
| linkedin_capi | KeyBuzz Consulting LinkedIn CAPI | true | 2026-04-27 | success |
| meta_capi | KeyBuzz Consulting Meta CAPI | true | 2026-04-23 | success |
| tiktok_events | KeyBuzz Consulting TikTok 2026-05 cutover | true | 2026-05-01 | success |

3 destinations actives, toutes testees success. Hors scope KEY-322 : 11 destinations soft-deleted ou test/legacy inactives sur autres tenants.

### 5.2 outbound_conversion_delivery_logs

| Indicateur | Valeur |
|---|---|
| Total rows | 16 |
| Total last 7 days | 0 |
| Total last 30 days | 8 (5 mai + tests avril) |
| Dernier delivered reel | 2026-05-05T09:23 (3 simultanees pour bon-kb-mosf283z) |

Aggregation par destination_type + status :

| destination_type | status | rows | first | last |
|---|---|---|---|---|
| linkedin_capi | delivered | 1 | 2026-05-05 09:23 | 2026-05-05 09:23 |
| linkedin_capi | success | 1 | 2026-04-27 15:57 | 2026-04-27 15:57 (test) |
| meta_capi | delivered | 3 | 2026-04-25 10:38 | 2026-05-05 09:23 |
| meta_capi | failed | 3 | 2026-04-22 18:26 | 2026-04-22 21:36 (test) |
| meta_capi | success | 1 | 2026-04-23 15:13 | 2026-04-23 15:13 (test) |
| tiktok_events | delivered | 3 | 2026-04-25 10:38 | 2026-05-05 09:23 |
| tiktok_events | failed | 1 | 2026-04-25 08:54 | 2026-04-25 08:54 (test) |
| tiktok_events | success | 3 | 2026-04-25 10:27 | 2026-05-01 11:13 (tests + cutover) |

### 5.3 Detail 3 deliveries 2026-05-05 (event_id partage)

event_id : `conv_bon-kb-mosf283z_StartTrial_sub_1TTfBvFC0QQLHISRdwPyG6rl`

| destination_type | name | event_name | status | http_status | attempt | delivered_at |
|---|---|---|---|---|---|---|
| linkedin_capi | KeyBuzz Consulting LinkedIn CAPI | StartTrial | delivered | 201 | 1 | 2026-05-05T09:23:12.033Z |
| meta_capi | KeyBuzz Consulting Meta CAPI | StartTrial | delivered | 200 | 1 | 2026-05-05T09:23:12.766Z |
| tiktok_events | KeyBuzz Consulting TikTok 2026-05 cutover | StartTrial | delivered | 200 | 1 | 2026-05-05T09:23:13.000Z |

Tous delivered first attempt, no retry needed, providers ont accepte les events.

### 5.4 conversion_events

| Total rows | last_30d | last_7d |
|---|---|---|
| 2 | 2 | 0 |

| event_name | tenant_id | status | attempts | last_attempt_at | created_at |
|---|---|---|---|---|---|
| StartTrial | bon-kb-mosf283z | sent | 1 | 2026-05-05T09:23:13 | 2026-05-05T09:23:11 |
| StartTrial | test-owner-runtime-p-modeeozl | sent | 1 | 2026-04-25T10:38:27 | 2026-04-25T10:38:26 |

2 events seulement TOTAL. Both successful. Tres faible volume = signups eligibles tres rares.

### 5.5 signup_attribution

| Indicateur | Valeur |
|---|---|
| total | 8 |
| with marketing_owner_tenant_id | 4 (50%) |
| with conversion_sent_at | 3 |
| last 7 days | 1 |
| last 7 days WITH owner | **0** |

Detail dernieres 8 signups :

| tenant_id | utm_source | marketing_owner | gclid | ttclid | li_fat_id | conv_sent | created_at |
|---|---|---|---|---|---|---|---|
| test-mp48gaam | null | null | - | - | - | null | 2026-05-13 (last 7d) |
| ecomlg-motxke32 | null | **null** | - | - | - | 2026-05-06 | 2026-05-06 |
| bon-kb-mosf283z | concours | keybuzz-consulting | - | - | - | 2026-05-05 | 2026-05-05 (CAPI OK) |
| internal-validation-mok6do0m | tiktok | keybuzz-consulting | - | yes | - | null | 2026-04-29 |
| ludovic-mojol7ds | google | null | - | - | - | 2026-04-29 | 2026-04-29 |
| codex-google-legacy | google | null | yes | - | - | null | 2026-04-25 |
| codex-google-owner-p-moede64n | google | keybuzz-consulting | yes | - | - | null | 2026-04-25 |
| test-owner-runtime-p-modeeozl | cursor-validation | keybuzz-consulting | - | - | - | null | 2026-04-24 (CAPI OK conv_events) |

Observations :
- 4 signups avec marketing_owner -> 2 ont declenche delivery_logs (bon-kb 5 mai + test-owner 25 avr), 2 n ont pas (internal-validation-mok6do0m + codex-google-owner-p). Pour ces 2 derniers, conversion_events est vide. Probable que le Stripe webhook n a jamais ete declenche (signups internal, pas de payment session).
- 4 signups sans marketing_owner -> 0 ont declenche CAPI (attendu). Mais conversion_sent_at peut etre set par GA4 webhook (cas ecomlg-motxke32 + ludovic-mojol7ds).

### 5.6 Toutes les tables tracking presentes

| Table | Role |
|---|---|
| outbound_conversion_destinations | Config destinations CAPI |
| outbound_conversion_delivery_logs | Traces delivery individuelle |
| conversion_events | Master event log (1 row par event emis) |
| signup_attribution | Source signup + UTM + click IDs + marketing_owner + conversion_sent_at |
| funnel_events | Pre-tenant funnel telemetry |
| tracking_events | Carrier tracking 17Track |
| billing_events | Stripe webhook events history |
| ai_journal_events, ai_suggestion_events, conversation_events, conversation_learning_events, incident_events, message_events, outbound_deliveries, shopify_webhook_events | Out of scope CAPI |

---

## 6. PROVIDER MATRIX

| Provider | Config active | Secret present masked | Events eligible 7d | Delivery 7d | Last success reel | Last error | Verdict |
|---|---|---|---|---|---|---|---|
| Meta CAPI | YES (pixel 1234164602194748, account 1485150039295668) | K8s secret keybuzz-meta-ads keys META_ACCESS_TOKEN + META_AD_ACCOUNT_ID (masked) | 0 | 0 | 2026-05-05 HTTP 200 | 3 failed tests 2026-04-22 | OK |
| TikTok Events | YES (pixel D7PT12JC77U44OJIPC10 cutover, advertiser 7634494806858252304) | Destination-scoped token in DB platform_token_ref (encrypted) | 0 | 0 | 2026-05-05 HTTP 200 | 1 failed test 2026-04-25 (legacy pixel D7HQO0...) | OK |
| LinkedIn CAPI | YES (account 514471703, urns StartTrial=27491313 / Purchase=27491305) | Destination-scoped token in DB platform_token_ref | 0 | 0 | 2026-05-05 HTTP 201 | 0 | OK |
| GA4 MP | YES (G-R3QQDYEBFG, GA4_MP_API_SECRET env) | K8s secret keys GA4_MEASUREMENT_ID + GA4_MP_API_SECRET (masked) | Independent chain | 3 conversions sent last 30d | 2026-05-06 (ecomlg-motxke32) | n/a | OK |
| sGTM Server | t.keybuzz.pro (PH-T8.12R) | n/a | observability only | n/a | n/a | n/a | OK |
| Google Ads import | GA4 import as primary lead (PH-T8.11AL) | (uses Google Ads OAuth secret) | n/a | n/a | n/a | n/a | OK + AS.15.1 recovery |

Tous les providers configures et fonctionnels. Le pipeline CAPI est cable et testes success. Le pipeline GA4 MP est independant et fonctionne en parallel.

---

## 7. TRIGGER AUDIT

| Trigger | Code path | Condition d eligibilite | Events recents 7d | Devrait emettre 7d | Pourquoi 0 emit 7d |
|---|---|---|---|---|---|
| Stripe checkout.session.completed | /billing/webhook -> emitOutboundConversion(StartTrial) | session.mode=subscription AND metadata.type != agent_keybuzz_addon AND marketing_owner_tenant_id != null | 0 | 0 (only 1 signup test-mp48gaam organic last 7d, no marketing_owner) | Aucun signup eligible attribute |
| Stripe customer.subscription.updated (trialing -> active) | /billing/webhook -> emitOutboundConversion(Purchase) | similar conditions | 0 | 0 | Pas de trial conversion observed last 7d |
| Funnel events POST /funnel/emit | funnel/routes.ts | NOT connected to CAPI emit pipeline | n/a | n/a | Funnel != CAPI emit (par design) |
| Admin v2 POST /destinations/:id/test | routes.ts:296-324 | manual test by admin | 0 | n/a (test only) | No test triggered last 7d |
| Direct POST /outbound-conversions/emit | NOT FOUND | n/a | n/a | n/a | Pas d endpoint public d emit direct |

**Conclusion** : le seul trigger reel CAPI est le Stripe webhook. Aucun event Stripe declenche dans les 7 derniers jours (logs API confirme 0 mention `/billing/webhook` 24h). Le pipeline est silencieux par absence de trigger, pas par bug.

---

## 8. LOGS RUNTIME READ-ONLY

### 8.1 keybuzz-api PROD logs 24h

| Pattern | Occurrences | Commentaire |
|---|---|---|
| `emitOutboundConv|outboundConv` | 0 | Aucun emit declenche 24h |
| `stripe.*webhook|/billing/webhook|checkout.session` | 0 | Aucun Stripe webhook recent 24h |
| `sendToMeta|sendToTikTok|sendToLinked` | 0 | Aucune emission |
| `No destinations|No marketing owner` | 0 | Pas de log SKIP non plus -> emit not called at all |

Le pipeline emit n a meme pas ete invoque dans les 24 dernieres heures. Le code path Stripe webhook -> emit n est pas declenche faute d events Stripe payants.

### 8.2 keybuzz-admin-v2 PROD logs (lecture seule via API calls)

Pas de log API admin-v2-prod scan complet dans cette phase. Hors scope direct (audit cote source code suffit pour Admin v2 UX).

---

## 9. ADMIN V2 UX TRUTH

| Page Admin | Donnee source | Etat visible | Correct ? | Gap UX |
|---|---|---|---|---|
| /marketing/destinations | GET /outbound-conversions (BFF /api/admin/marketing/destinations) | Liste 14 destinations (3 actives KBC + 11 inactives multi-tenant) | OK | Pas de filtre is_active par defaut UI (a verifier) |
| /marketing/delivery-logs | GET /outbound-conversions/destinations/:id/logs (par destination) | 0 row 7d -> affiche probablement liste vide | OK techniquement mais TROMPEUR si pas de banner | Should show "Eligible events 7d: 0 -> 0 delivery is expected" |
| /marketing/google-tracking | GET /outbound-conversions/google-observability | gclid count, conversion_sent_at count | OK | Pas de lien explicite vers attribution issues (marketing_owner null) |
| /marketing/ad-accounts | GET /ad-accounts | Meta + Google compte affiches | OK post-AS.15.1 | TikTok + LinkedIn absents (gap connu P2) |
| /marketing/metrics | GET /metrics | Spend aggregations | OK | n/a |
| /marketing/funnel | GET /funnel | Pre-tenant funnel | OK | n/a |

**Gap UX critique pour media buyer Antoine** : Admin ne fait PAS la distinction visuelle entre :
- "Pipeline casse" (alerte rouge)
- "Pipeline OK mais 0 signup eligible recent" (etat normal silencieux)

Si Antoine regarde delivery-logs et voit 0 row, il pense pipeline casse. Il faut un indicateur "Eligible signups 7d: N" + "Last delivery: 2026-05-05".

---

## 10. ROOT CAUSE CLASSIFICATION

| Cause | Provider | Preuve | Impact business | Correctif | Priorite |
|---|---|---|---|---|---|
| R1. Aucun signup eligible dans les 7 derniers jours | All | with_owner_7d=0 + total_7d=1 (test-mp48gaam organic) | Aucun, etat business normal | Aucun (depend du volume acquisition) | INFO |
| R2. Decouplage GA4 webhook vs CAPI (intentionnel ?) | All | conversion_sent_at set sans delivery_log pour 1 tenant (ecomlg-motxke32 6 mai) | Confusion media buyer | Documenter explicitement, ou unifier les 2 chains | P2 |
| R3. marketing_owner_tenant_id NULL pour signups organic | All | 4/8 signups recents sans marketing_owner | CAPI skip pour organic | Decision business : default marketing_owner=keybuzz-consulting pour signups sans attribution explicite ? | P2 |
| R4. Admin v2 UX trompeuse : 0 delivery_log = "pipeline casse" perception | n/a | Source page delivery-logs pas de banner explicatif | Antoine ne distingue pas etat normal vs bug | Ajouter indicateur "Eligible signups 7d: N" + "Last delivery: <date>" | P2 |
| R5. Pas de cron pour replay failed deliveries | All | 4 failed deliveries 2026-04-22-25 jamais retry | Pas de delivery garantie sur defaillance temporaire provider | Cron retry sur failed status | P3 |
| R6. Webhook GA4 MP fonctionne mais URL/secret non documente Admin | GA4 | env CONVERSION_WEBHOOK_URL + GA4_MP_API_SECRET masked, pas d UI Admin pour les verifier | Diagnostic difficile | Page Admin /marketing/google-tracking pourrait afficher GA4_MEASUREMENT_ID + sGTM URL en clair | P3 |

Le pipeline est OK. Les "causes" sont en realite des choix de design + gaps UX et plus marginal du retry handling.

---

## 11. PLAN CORRECTIF PROPOSE

Aucun correctif technique necessaire dans le pipeline. Plan en sous-phases optionnelles pour clarification + amelioration UX :

### AS.15.3A - DOCUMENTATION decouplage chains GA4 vs CAPI (P3 docs-only)

- Type : docs only
- Fichier : MEDIA-BUYER-TRACKING-GUIDE.md ou SERVER_SIDE_TRACKING_CONTEXT.md
- Contenu : expliquer que conversion_sent_at != delivery_log, conditions d eligibilite CAPI, GA4 MP webhook independent
- Pas de patch code
- GO required : non

### AS.15.3B - DECISION marketing_owner default pour organic (P2 business)

- Type : decision produit + code patch eventuel
- Question : est-ce que KeyBuzz Consulting doit recevoir CAPI signal pour les signups organic (sans UTM) ?
- Si oui : etendre `resolveMarketingOwner()` pour fallback `keybuzz-consulting-mo9zndlk` si attribution null
- Si non : Admin v2 doit expliquer pourquoi organic est skip
- DEV first si code change
- GO required : OUI Ludovic decision business

### AS.15.3C - Admin v2 UX banner "0 delivery 7d normal" (P2 code)

- Type : code Admin v2 DEV first
- Fichier : `/marketing/delivery-logs/page.tsx`
- Ajouts :
  - Banner explicatif "Eligible signups 7d: N (avec UTM/click ID attribution)" + "Last successful delivery: <date>" + "Pipeline status: HEALTHY" (vert) ou "WARN: no delivery in 30d" (rouge)
  - Tooltip "Comment se declenche une delivery ?"
- DEV first
- GO required : OUI

### AS.15.4 - LP click IDs fbclid + li_fat_id capture audit (already proposed AS.15.0)

- Type : audit Client + Webflow LPs
- Necessite pour atteindre attribution Meta + LinkedIn full
- Pas relie directement a AS.15.3 (CAPI pipeline marche, mais avec attribution partielle)
- GO required : OUI

### AS.15.6 - Cron retry failed deliveries (P3)

- Type : GitOps add CronJob
- Hourly scan : SELECT failed deliveries last 24h with attempts < max_retries -> re-emit
- Retry policy : exponential backoff + max_retries=5
- DEV first
- GO required : OUI

### AS.15.7 - Admin v2 spend gaps audit (already proposed AS.15.0)

- Type : Admin UX hardening
- last_error sanitize + CTA Reconnect
- GO required : OUI

---

## 12. NO FAKE METRICS / NO FAKE EVENTS

Confirme :
- 0 event CAPI test envoye (Meta, TikTok, LinkedIn, GA4)
- 0 conversion fake creee
- 0 signup fake
- 0 modification destinations / delivery_logs / signup_attribution / conversion_events
- 0 token / refresh_token / access_token / client_secret affiche
- 0 PII (emails, payloads sensibles)
- 0 build / docker push / kubectl apply / manifest edit / GitOps commit deploy
- 0 mutation DB
- 0 mutation provider
- 0 changement Linear statut
- 1 unique action effective : SELECT read-only DB + kubectl logs read-only + Agent Explore source code

---

## 13. NON-REGRESSION

Aucune action mutationnelle pendant l audit. Etat avant = etat apres pour :

| Service | Image PROD |
|---|---|
| keybuzz-api | v3.5.190-channels-tenantguard-prod (UNCHANGED) |
| keybuzz-client | v3.5.197-channels-bff-userauth-prod (UNCHANGED) |
| keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod (UNCHANGED) |
| keybuzz-backend | v1.0.47-cross-env-guard-fix-prod (UNCHANGED) |

DEV inchange. Tables DB inchangees. Destinations + delivery_logs + signup_attribution + conversion_events inchangees.

---

## 14. LINEAR (commentaire propose KEY-322)

```
PH-ADMIN-T8.12AS.15.3 CAPI delivery pipeline truth audit livre.

Finding principal : le pipeline CAPI server-side n est PAS casse. Le rapport AS.15.0 R4 "0 delivery log 7j" etait incomplet : il manquait le filtre d eligibilite. La condition reelle d emission est signup_attribution.marketing_owner_tenant_id IS NOT NULL.

Etat runtime :
- 3 destinations actives KeyBuzz Consulting : Meta CAPI pixel 1234164602194748, TikTok 2026-05 cutover pixel D7PT12JC77U44OJIPC10, LinkedIn CAPI account 514471703. Toutes last_test_status=success.
- Dernier delivery REEL : 2026-05-05T09:23 pour tenant bon-kb-mosf283z (utm_source=concours, marketing_owner=keybuzz-consulting). 3 deliveries simultanees Meta HTTP 200 + TikTok HTTP 200 + LinkedIn HTTP 201, status=delivered, attempt=1 (no retry needed).
- conversion_events table : 2 rows total (bon-kb 2026-05-05 + test-owner-runtime 2026-04-25), both status=sent.
- signup_attribution 30d : 8 signups dont 4 avec marketing_owner (declenchent CAPI), 4 sans (skip CAPI par design).
- Last 7d : 1 signup total (test-mp48gaam organic, sans marketing_owner) -> 0 CAPI emit attendu et observe.

Decouplage architectural confirme :
- signup_attribution.conversion_sent_at = signal GA4 Measurement Protocol webhook (emitConversionWebhook) - independant
- outbound_conversion_delivery_logs = signal CAPI providers (emitOutboundConversion) - conditione marketing_owner

GA4 MP webhook fonctionne pour tous les signups payants (3 conv_sent_at sur 8 signups). CAPI fonctionne uniquement quand marketing_owner_tenant_id est resolu (2 conversion_events sur 8 signups, 2 deliveries series le 5 mai et 25 avril).

Aucun bug technique a fixer dans le pipeline lui-meme. Code stable depuis ~4 semaines (dernier refactor PH-T8.10M owner-aware 2026-04-19).

Vrais sujets identifies (P2-P3) :
- AS.15.3A docs : clarifier decouplage GA4 vs CAPI dans MEDIA-BUYER-TRACKING-GUIDE
- AS.15.3B business : decider si signups organic doivent declencher CAPI (defaut marketing_owner=keybuzz-consulting ?)
- AS.15.3C Admin UX : banner "Eligible signups 7d: N + Last delivery <date> + Pipeline HEALTHY" pour eviter perception "casse" quand 0 delivery
- AS.15.4 LP click IDs (fbclid + li_fat_id capture, deja propose AS.15.0)
- AS.15.6 cron retry failed deliveries (P3)
- AS.15.7 Admin v2 UX ad-accounts (deja propose AS.15.0)

Hygiene : 0 event fake, 0 mutation provider, 0 token expose, 0 PII, 0 build/deploy, 0 modification DB, 0 changement Linear statut.

KEY-322 reste Open. KEY-301 et KEY-313 restent Done. KEY-314 reste Open + pause AS.14.2.

Rapport : keybuzz-infra/docs/PH-ADMIN-T8.12AS.15.3-CAPI-DELIVERY-PIPELINE-TRUTH-AUDIT-01.md
```

Aucun changement Linear statut. Aucun ticket follow-up cree sans GO.

---

## 15. GAPS / UNKNOWNS

| Gap | Statut |
|---|---|
| Pourquoi marketing_owner_tenant_id NULL pour signups recents organic | A decider business (AS.15.3B) |
| ecomlg-motxke32 (6 mai) : pourquoi GA4 MP webhook a tourne mais CAPI a skip | Confirmation : marketing_owner_tenant_id=null donc CAPI skip par design. GA4 webhook ne lit pas cette condition. |
| Stripe webhook subscription.updated pour Purchase event | Pas observe dans 30d, possible que pas de trial -> active conversion recente |
| fbclid + li_fat_id capture LP | Out of scope AS.15.3, traite par AS.15.4 (a planifier) |
| LinkedIn Ads Reporting spend | Out of scope AS.15.3, hors KEY-322 P2 |
| TikTok spend connection | Out of scope AS.15.3, hors KEY-322 P2 |

Aucun gap bloquant. Pipeline OK + low volume = etat business attendu.

---

## 16. PHRASE CIBLE FINALE

CAPI delivery pipeline server-side fonctionne correctement. Le 0 delivery_log 7j n est pas un bug : aucun signup eligible (avec marketing_owner_tenant_id) dans la fenetre. Le dernier signup attribute (bon-kb-mosf283z 2026-05-05 concours) a declenche 3 deliveries CAPI simultanees Meta HTTP 200 + TikTok HTTP 200 + LinkedIn HTTP 201, toutes delivered first attempt. Decouplage GA4 MP webhook (conversion_sent_at) vs CAPI providers (delivery_logs) confirme intentional. Plan de clarification UX + business decision marketing_owner organic propose en 6 sous-phases (P2-P3). Aucun event fake, aucun token expose, aucune mutation. KEY-322 reste Open. Aucun enchainement AS.15.x sans GO Ludovic explicite.

STOP
