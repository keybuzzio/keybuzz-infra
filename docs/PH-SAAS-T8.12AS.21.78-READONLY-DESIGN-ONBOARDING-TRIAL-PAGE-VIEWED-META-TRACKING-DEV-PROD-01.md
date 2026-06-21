# PH-SAAS-T8.12AS.21.78 - Readonly design onboarding trial_page_viewed Meta tracking DEV PROD

## RESUME LUDOVIC - TERMINAL

PH-21.78 READONLY DESIGN ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV PROD : READY_SOURCE_PATCH_REQUIRED
Snippet Antoine : NOOP_PROBABLE ; Client PROD fbq_count=1 ; MetaPixelId_count=0 ; connect.facebook_count=0.
Distinction : trial_page_viewed = arrivee /register ; StartTrial = trial/subscription Stripe valide, intact et hors scope.
Recommendation : server-side Meta CAPI derive de register_started, avec event_id stable et idempotence ; browser-only refuse comme option principale.
Patch DEV requis : ajouter trial_page_viewed au pipeline API/funnel/outbound Meta custom sans toucher StartTrial/Purchase.
Test sans CB : hors scope, reporte ; validation reelle Ads Manager uniquement dans phase de trafic reel separee.
No side-effect : 0 event reel, 0 fake event, 0 formulaire, 0 checkout Stripe, 0 DB mutation, 0 build, 0 deploy.
GO READONLY DESIGN ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV PROD READY_SOURCE_PATCH_REQUIRED PH-SAAS-T8.12AS.21.78
STOP

## Scope

Mode READONLY DESIGN respecte.

- Aucun patch source.
- Aucun build.
- Aucun deploy.
- Aucun docker push.
- Aucun kubectl apply.
- Aucun event tracking volontaire.
- Aucun formulaire.
- Aucun checkout Stripe.
- Aucun POST externe Meta/TikTok/LinkedIn/GA4/sGTM.
- Aucun fake event.
- Aucune mutation DB.
- Aucun secret lu ou affiche.
- Aucun Webflow.
- Aucun Linear.
- Seule mutation autorisee : rapport docs-only.

## Sources relues

| Source | Statut |
| --- | --- |
| PH-21.78 mission locale | relue |
| AI_MEMORY CURRENT_STATE | relue |
| AI_MEMORY RULES_AND_RISKS | relue |
| AI_MEMORY DOCUMENT_MAP | relue |
| AI_MEMORY CE_PROMPTING_STANDARD | relue |
| Modele PH-T8.10J | relu |
| PH-21.55 retour local | relu |
| PH-21.56 retour local | relu |
| PH-21.77 retour local | relu |
| Source Client  | relue |
| Source Client tracking/funnel/attribution | relue |
| Source API funnel/outbound Meta CAPI | relue |

## Preflight

| Controle | Observe | Verdict |
| --- | --- | --- |
| Host | install-v3 | PASS |
| IPv4 obligatoire | 46.62.171.61 present | PASS |
| IPv4 interdite | 51.159.99.247 absente | PASS |
| Date UTC | 2026-06-21T09:30:56Z | PASS |
| Kube context | kubernetes-admin@kubernetes | PASS |

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | ---: | --- |
| keybuzz-infra | main | 249eff40 | 249eff40 | 0/0 | 0 | PASS |
| keybuzz-api | ph147.4/source-of-truth | 76483e3a | 76483e3a | 0/0 | 223 | READONLY_DIRTY_DOCUMENTED |
| keybuzz-client | ph148/onboarding-activation-replay | ad4e862a | ad4e862a | 0/0 | 1 | READONLY_DIRTY_DOCUMENTED |
| keybuzz-website | main | bd32fc8b | bd32fc8b | 0/0 | 0 | PASS |
| keybuzz-admin-v2 | main | 3707c834 | 3707c834 | 0/0 | 0 | PASS |
| keybuzz-backend | main | c38583a8 | c38583a8 | 0/0 | 1 | READONLY_DIRTY_DOCUMENTED |

Dirty details read-only :

```text
## Dirty details
### keybuzz-infra dirty=0
### keybuzz-api dirty=223
 D dist/app.js
 D dist/config/ai-budgets.js
 D dist/config/database.js
 D dist/config/db-conventions.js
 D dist/config/env.js
 D dist/config/historical-anti-patterns.js
 D dist/config/kbactions.js
 D dist/config/redis.js
 D dist/config/sav-decision-tree.js
 D dist/config/sav-policy.js
### keybuzz-client dirty=1
 M tsconfig.tsbuildinfo
### keybuzz-website dirty=0
### keybuzz-admin-v2 dirty=0
### keybuzz-backend dirty=1
?? src/modules/marketplaces/amazon/amazon.routes.ts.bak
```

## Runtime read-only

| Service | Env | Image | Digest/imageID | Ready | Restarts | Verdict |
| --- | --- | --- | --- | --- | ---: | --- |
| API | DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.263-llm-provider-credit-watcher-dev | sha256:93914a6861a2f2123aa7a32a6ab3cc56b937154ac709b47e4760f60346d0d996 | 1/1 gen 502/502 | 0 | PASS |
| API | PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod | sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6 | 1/1 gen 423/423 | 0 | PASS |
| Client | DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-dev | sha256:019dea6325fcdfba47ec0d9fa2ee425b30287eb2c7a6e4e58f6178cea82e104e | 1/1 gen 1024/1024 | 0 | PASS |
| Client | PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod | sha256:e63494dbe83368a300df4d199b6443ccef6442b5428edeca6cf94433b5abf791 | 1/1 gen 427/427 | 0 | PASS |
| Website | PROD | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod | sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4 | 2/2 gen 38/38 | 0 | PASS |
| Admin | PROD | ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-prod | sha256:ecc2080ff7fe5031eab812b1c32d330e4f7eea902d2a98e4d7bd7b409e0d5037 | 1/1 gen 102/102 | 0 | PASS |

## Clarification semantique

| Signal | Declencheur | Table/pipeline cible possible | Conversion business ? | Ads risk |
| --- | --- | --- | --- | --- |
|  | Arrivee sur  | Meta CAPI custom via premier  ou nouvel event dedie | Non | Micro-event haut de funnel, volume plus haut, qualite plus faible |
|  | Page  chargee et attribution/funnel id disponible |  interne existant | Non | Interne, pas Ads Manager aujourd'hui |
|  | Checkout/subscription Stripe valide |  + destinations outbound existantes | Oui | Conversion forte, ne doit pas etre simulee |
|  | Transition payante/trialing -> active selon billing |  + destinations outbound existantes | Oui | Conversion forte, hors scope |

Conclusion semantique :  ne prouve ni essai Stripe, ni paiement, ni checkout finalise. Il ne doit pas remplacer .

## Audit source Client / register

| Fichier | Point verifie | Resultat | Impact pour `trial_page_viewed` |
| --- | --- | --- | --- |
| `keybuzz-client/app/register/page.tsx` | Page `/register` | route localisee, `emitFunnelStep('register_started')` au mount | page-load onboarding deja mesure en micro-event interne |
| `keybuzz-client/src/lib/funnel.ts` | Emission funnel | `fetch('/api/funnel/event')`, dedup memoire par `funnelId:eventName` | base reutilisable, mais browser POST interne existe deja |
| `keybuzz-client/src/lib/tracking.ts` | Meta browser helper | `trackMetaCustom()` existe et no-op si `window.fbq` absent | snippet Antoine possible seulement si pixel runtime charge |
| `keybuzz-client/src/components/tracking/SaaSAnalytics.tsx` | Pixel browser | Meta Pixel charge seulement si `NEXT_PUBLIC_META_PIXEL_ID` est bake dans image | verifier bundle runtime obligatoire |
| `keybuzz-api/src/modules/funnel/routes.ts` | Allowlist | `trial_page_viewed` absent ; `register_started` present | patch API requis pour event dedie si on ne reutilise pas register_started |
| `keybuzz-api/src/modules/outbound-conversions/emitter.ts` | Outbound CAPI | `ConversionEvent = 'StartTrial' | 'Purchase'` | custom Meta event non supporte sans patch |
| `keybuzz-api/src/modules/outbound-conversions/adapters/meta-capi.ts` | Mapping Meta | mapping explicite StartTrial/Purchase, fallback possible mais type/pipeline limites | patch minimal recommande pour custom Meta safe |

Extraits grep source token-safe :

```text
## Client source grep
app/api/auth/magic/start/route.ts:13:  fetch(`${FUNNEL_API}/funnel/event`, {
app/api/auth/magic/verify/route.ts:10:  fetch(`${FUNNEL_API}/funnel/event`, {
app/api/funnel/event/route.ts:9:    const res = await fetch(`${API_URL}/funnel/event`, {
app/register/LegalModal.tsx:251:        [email]
app/register/page.tsx:16:import { trackSignupStart, trackSignupStep, trackSignupComplete, trackBeginCheckout } from '@/src/lib/tracking';
app/register/page.tsx:18:import { emitFunnelStep, getFunnelId } from '@/src/lib/funnel';
app/register/page.tsx:251:  // Funnel: emit register_started on mount (one-shot via emitFunnelStep dedup)
app/register/page.tsx:254:    if (fid) emitFunnelStep('register_started', { funnelId: fid, plan: effectivePlan || selectedPlan, cycle: effectiveCycle || billingCycle });
app/register/page.tsx:407:    if (planFid) emitFunnelStep('plan_selected', { funnelId: planFid, plan, cycle: billingCycle });
app/register/page.tsx:408:    trackSignupStart(plan, billingCycle);
app/register/page.tsx:426:      trackSignupStep('code', selectedPlan);
app/register/page.tsx:438:      if (otpFid) emitFunnelStep('otp_verified', { funnelId: otpFid, plan: selectedPlan, cycle: billingCycle });
app/register/page.tsx:440:      trackSignupStep('company', selectedPlan);
app/register/page.tsx:449:      if (oauthFid) emitFunnelStep('oauth_started', { funnelId: oauthFid, plan: selectedPlan || effectivePlan, cycle: billingCycle || effectiveCycle, properties: { provider: 'google' } });
app/register/page.tsx:458:      if (compFid) emitFunnelStep('company_completed', { funnelId: compFid, plan: selectedPlan || effectivePlan, cycle: billingCycle || effectiveCycle });
app/register/page.tsx:460:    trackSignupStep('user', selectedPlan);
app/register/page.tsx:472:    if (userFid) emitFunnelStep('user_completed', { funnelId: userFid, plan: selectedPlan || effectivePlan, cycle: billingCycle || effectiveCycle });
app/register/page.tsx:474:    trackSignupStep('plan', selectedPlan);
app/register/page.tsx:488:      // PH-SAAS-T8.12AS.19.4 (KEY-335): payload commun + retry safe si l API rejette le marketing_owner_tenant_id.
app/register/page.tsx:502:      const ownerCandidate = currentAttribution?.marketing_owner_tenant_id || undefined;
app/register/page.tsx:508:          marketing_owner_tenant_id: ownerCandidate,
app/register/page.tsx:512:      if (!res.ok && data?.error === 'invalid_marketing_owner_tenant_id' && ownerCandidate) {
app/register/page.tsx:513:        // Retry une seule fois sans marketing_owner_tenant_id. UTM/click IDs/_gl/promo restent dans attribution.
app/register/page.tsx:528:      trackSignupComplete(selectedPlan || 'starter', billingCycle, tid || '');
app/register/page.tsx:531:      trackSignupStep('checkout', selectedPlan);
src/components/tracking/SaaSAnalytics.tsx:62:      window.dataLayer = window.dataLayer || [];
src/components/tracking/SaaSAnalytics.tsx:65:        window.dataLayer!.push(arguments);
src/components/tracking/SaaSAnalytics.tsx:107:              {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
src/components/tracking/SaaSAnalytics.tsx:109:              if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
src/components/tracking/SaaSAnalytics.tsx:114:              fbq('init', '${META_PIXEL_ID}');
src/components/tracking/SaaSAnalytics.tsx:115:              fbq('track', 'PageView');
src/lib/tracking.ts:14:    fbq?: (...args: unknown[]) => void;
src/lib/tracking.ts:21:    dataLayer?: unknown[];
src/lib/tracking.ts:48:    if (typeof window === 'undefined' || !window.fbq) return;
src/lib/tracking.ts:49:    window.fbq('track', event, params || {});
src/lib/tracking.ts:56:    if (typeof window === 'undefined' || !window.fbq) return;
src/lib/tracking.ts:57:    window.fbq('trackCustom', event, params || {});
src/lib/tracking.ts:74:export function trackSignupStart(plan: string, cycle: string): void {
src/lib/tracking.ts:80:export function trackSignupStep(step: string, plan: string | null): void {
src/lib/tracking.ts:84:export function trackSignupComplete(plan: string, cycle: string, tenantId: string): void {
src/lib/tracking.ts:85:  trackGA4('signup_complete', {
src/lib/funnel.ts:3:export function emitFunnelStep(
src/lib/funnel.ts:29:  fetch('/api/funnel/event', {
src/lib/funnel.ts:78:  fetch('/api/funnel/event', {
src/lib/attribution.ts:28:  fbclid: string | null;
src/lib/attribution.ts:39:  marketing_owner_tenant_id: string | null;
src/lib/attribution.ts:63:const CLICK_ID_PARAMS = ['gclid', 'fbclid', 'ttclid', 'li_fat_id'] as const;
src/lib/attribution.ts:75: * Reconstruct Meta fbc parameter from fbclid.
src/lib/attribution.ts:76: * Format: fb.{version}.{creation_time}.{fbclid}
src/lib/attribution.ts:79:function buildFbc(fbclid: string): string {
src/lib/attribution.ts:80:  return `fb.1.${Date.now()}.${fbclid}`;
src/lib/attribution.ts:111:  const fbclid = get('fbclid');
src/lib/attribution.ts:112:  const fbp = readCookie('_fbp');
src/lib/attribution.ts:122:    fbclid,
src/lib/attribution.ts:123:    fbc: fbclid ? buildFbc(fbclid) : readCookie('_fbc') || null,
src/lib/attribution.ts:130:    marketing_owner_tenant_id: get('marketing_owner_tenant_id'),
src/lib/attribution.ts:154:    ctx.gclid || ctx.fbclid || ctx.ttclid || ctx.li_fat_id || ctx._gl
src/lib/attribution.ts:304:    gclid: null, fbclid: null, fbc: null, fbp: null, ttclid: null, li_fat_id: null, _gl: null,
src/lib/attribution.ts:306:    marketing_owner_tenant_id: null,

## API source grep
src/modules/metrics/routes.ts:95:    `SELECT id FROM tenants WHERE id = $1 OR marketing_owner_tenant_id = $1`,
src/modules/auth/tenant-context-routes.ts:622:      // PH-T8.10B: Validate marketing_owner_tenant_id if provided
src/modules/auth/tenant-context-routes.ts:623:      const marketingOwnerTenantId = body.marketing_owner_tenant_id || null;
src/modules/auth/tenant-context-routes.ts:632:            error: 'invalid_marketing_owner_tenant_id',
src/modules/auth/tenant-context-routes.ts:653:          'UPDATE tenants SET name = $1, plan = $2, marketing_owner_tenant_id = $3, selected_plan = $4, trial_entitlement_plan = $5, updated_at = NOW() WHERE id = $6',
src/modules/auth/tenant-context-routes.ts:672:          `INSERT INTO tenants (id, name, plan, status, created_at, updated_at, marketing_owner_tenant_id, selected_plan, trial_entitlement_plan)
src/modules/auth/tenant-context-routes.ts:746:              attribution_id, ttclid, marketing_owner_tenant_id, li_fat_id,
src/modules/billing/routes.ts:12:import { emitOutboundConversion } from '../outbound-conversions/emitter';
src/modules/billing/routes.ts:346:        if (a.marketing_owner_tenant_id) attrMeta.marketing_owner_tenant_id = String(a.marketing_owner_tenant_id).slice(0, 200);
src/modules/billing/routes.ts:633:        const { addPurchasedActions } = await import('../../services/ai-actions.service');
src/modules/billing/routes.ts:634:        const wallet = await addPurchasedActions(tenantId, actions, 'dev-stub-' + Date.now());
src/modules/billing/routes.ts:983:        `INSERT INTO billing_events (stripe_event_id, event_type, payload, processed, created_at)
src/modules/billing/routes.ts:985:         ON CONFLICT (stripe_event_id) DO NOTHING`,
src/modules/billing/routes.ts:1106:        'UPDATE billing_events SET processed = true WHERE stripe_event_id = $1',
src/modules/billing/routes.ts:1113:        'UPDATE billing_events SET error_message = $1 WHERE stripe_event_id = $2',
src/modules/billing/routes.ts:1730:        const { addPurchasedActions } = await import('../../services/ai-actions.service');
src/modules/billing/routes.ts:1731:        const wallet = await addPurchasedActions(tenantId, actions, 'stripe-' + session.id);
src/modules/billing/routes.ts:1752:  // PH-T8.4: Emit StartTrial outbound conversion (non-blocking)
src/modules/billing/routes.ts:1757:      await emitOutboundConversion('StartTrial', tenantId, {
src/modules/billing/routes.ts:1767:      console.warn('[Billing] StartTrial outbound conversion failed (non-blocking):', convErr.message?.substring(0, 100));
src/modules/billing/routes.ts:1889:  // PH-T8.4: Read previous status for Purchase detection
src/modules/billing/routes.ts:1928:  // PH-T8.4: Emit Purchase outbound conversion on trialing -> active transition
src/modules/billing/routes.ts:1938:      await emitOutboundConversion('Purchase', tenantId, {
src/modules/billing/routes.ts:1950:      console.warn('[Billing] Purchase outbound conversion failed (non-blocking):', convErr.message?.substring(0, 100));
src/modules/billing/routes.ts:2093:      'SELECT marketing_owner_tenant_id FROM tenants WHERE id = $1',
src/modules/billing/routes.ts:2096:    ownerTenantId = ownerRow.rows[0]?.marketing_owner_tenant_id || null;
src/modules/billing/routes.ts:2127:    ...(ownerTenantId ? { marketing_owner_tenant_id: ownerTenantId } : {}),
src/modules/outbound-conversions/adapters/tiktok-events.ts:6:  StartTrial: 'Subscribe',
src/modules/outbound-conversions/adapters/tiktok-events.ts:7:  Purchase: 'CompletePayment',
src/modules/outbound-conversions/adapters/tiktok-events.ts:24:  event_id: string;
src/modules/outbound-conversions/adapters/tiktok-events.ts:63:    event_id: canonicalPayload.event_id,
src/modules/outbound-conversions/adapters/linkedin-capi.ts:7:  StartTrial: 'StartTrial',
src/modules/outbound-conversions/adapters/linkedin-capi.ts:8:  Purchase: 'Purchase',
src/modules/outbound-conversions/adapters/linkedin-capi.ts:74:    eventId: canonicalPayload.event_id,
src/modules/outbound-conversions/adapters/meta-capi.ts:9: * StartTrial and Purchase are both Meta standard events.
src/modules/outbound-conversions/adapters/meta-capi.ts:12:export const META_EVENT_MAPPING: Record<string, string> = {
src/modules/outbound-conversions/adapters/meta-capi.ts:13:  StartTrial: 'StartTrial',
src/modules/outbound-conversions/adapters/meta-capi.ts:14:  Purchase: 'Purchase',
src/modules/outbound-conversions/adapters/meta-capi.ts:75:  event_id: string;
src/modules/outbound-conversions/adapters/meta-capi.ts:100:  const eventName = META_EVENT_MAPPING[canonicalPayload.event_name] || canonicalPayload.event_name;
src/modules/outbound-conversions/adapters/meta-capi.ts:140:    event_id: canonicalPayload.event_id,
src/modules/outbound-conversions/google-observability.ts:52:          ? `WHERE (marketing_owner_tenant_id = $1 OR tenant_id = $1)`
src/modules/outbound-conversions/google-observability.ts:68:          `SELECT tenant_id, gclid, utm_campaign, marketing_owner_tenant_id, created_at
src/modules/outbound-conversions/google-observability.ts:74:          `SELECT tenant_id, conversion_sent_at, marketing_owner_tenant_id
src/modules/outbound-conversions/google-observability.ts:95:            owner_tenant_id: g.marketing_owner_tenant_id || null,
src/modules/outbound-conversions/google-observability.ts:100:            owner_tenant_id: c.marketing_owner_tenant_id || null,
src/modules/outbound-conversions/emitter.ts:9:type ConversionEvent = 'StartTrial' | 'Purchase';
src/modules/outbound-conversions/emitter.ts:13:  event_id: string;
src/modules/outbound-conversions/emitter.ts:63:      'SELECT marketing_owner_tenant_id FROM tenants WHERE id = $1',
src/modules/outbound-conversions/emitter.ts:66:    const ownerTenantId = result.rows[0]?.marketing_owner_tenant_id || null;
src/modules/outbound-conversions/emitter.ts:82:    CREATE TABLE IF NOT EXISTS conversion_events (
src/modules/outbound-conversions/emitter.ts:84:      event_id TEXT UNIQUE NOT NULL,
src/modules/outbound-conversions/emitter.ts:104:       FROM outbound_conversion_destinations
src/modules/outbound-conversions/emitter.ts:177:              `INSERT INTO outbound_conversion_delivery_logs
src/modules/outbound-conversions/emitter.ts:178:               (destination_id, event_name, event_id, attempt, status, http_status, delivered_at)
src/modules/outbound-conversions/emitter.ts:197:        `INSERT INTO outbound_conversion_delivery_logs
src/modules/outbound-conversions/emitter.ts:198:         (destination_id, event_name, event_id, attempt, status, error_message, created_at)
src/modules/outbound-conversions/emitter.ts:220:          `INSERT INTO outbound_conversion_delivery_logs
src/modules/outbound-conversions/emitter.ts:221:           (destination_id, event_name, event_id, attempt, status, error_message, created_at)
src/modules/outbound-conversions/emitter.ts:238:          `INSERT INTO outbound_conversion_delivery_logs
src/modules/outbound-conversions/emitter.ts:239:           (destination_id, event_name, event_id, attempt, status, error_message, created_at)
src/modules/outbound-conversions/emitter.ts:268:            `INSERT INTO outbound_conversion_delivery_logs
src/modules/outbound-conversions/emitter.ts:269:             (destination_id, event_name, event_id, attempt, status, http_status, delivered_at)
src/modules/outbound-conversions/emitter.ts:285:        `INSERT INTO outbound_conversion_delivery_logs
src/modules/outbound-conversions/emitter.ts:286:         (destination_id, event_name, event_id, attempt, status, error_message, created_at)
src/modules/outbound-conversions/emitter.ts:287:         VALUES ($1, $2, $3, $4, 'failed', 'max attempts reached (meta_capi)', NOW())`,
src/modules/outbound-conversions/emitter.ts:308:          `INSERT INTO outbound_conversion_delivery_logs
src/modules/outbound-conversions/emitter.ts:309:           (destination_id, event_name, event_id, attempt, status, error_message, created_at)
src/modules/outbound-conversions/emitter.ts:326:          `INSERT INTO outbound_conversion_delivery_logs
src/modules/outbound-conversions/emitter.ts:327:           (destination_id, event_name, event_id, attempt, status, error_message, created_at)
src/modules/outbound-conversions/emitter.ts:361:            `INSERT INTO outbound_conversion_delivery_logs
src/modules/outbound-conversions/emitter.ts:362:             (destination_id, event_name, event_id, attempt, status, http_status, delivered_at)
src/modules/outbound-conversions/emitter.ts:378:        `INSERT INTO outbound_conversion_delivery_logs
src/modules/outbound-conversions/emitter.ts:379:         (destination_id, event_name, event_id, attempt, status, error_message, created_at)
src/modules/outbound-conversions/emitter.ts:402:          `INSERT INTO outbound_conversion_delivery_logs
src/modules/outbound-conversions/emitter.ts:403:           (destination_id, event_name, event_id, attempt, status, error_message, created_at)
src/modules/outbound-conversions/emitter.ts:418:          `INSERT INTO outbound_conversion_delivery_logs
src/modules/outbound-conversions/emitter.ts:419:           (destination_id, event_name, event_id, attempt, status, error_message, created_at)
src/modules/outbound-conversions/emitter.ts:436:          `INSERT INTO outbound_conversion_delivery_logs
src/modules/outbound-conversions/emitter.ts:437:           (destination_id, event_name, event_id, attempt, status, error_message, created_at)
src/modules/outbound-conversions/emitter.ts:469:            `INSERT INTO outbound_conversion_delivery_logs
src/modules/outbound-conversions/emitter.ts:470:             (destination_id, event_name, event_id, attempt, status, http_status, delivered_at)
src/modules/outbound-conversions/emitter.ts:486:        `INSERT INTO outbound_conversion_delivery_logs
src/modules/outbound-conversions/emitter.ts:487:         (destination_id, event_name, event_id, attempt, status, error_message, created_at)
src/modules/outbound-conversions/emitter.ts:498:export async function emitOutboundConversion(
src/modules/outbound-conversions/emitter.ts:536:    "SELECT id FROM conversion_events WHERE event_id = $1 AND status = 'sent'",
src/modules/outbound-conversions/emitter.ts:612:    event_id: eventId,
src/modules/outbound-conversions/emitter.ts:649:    `INSERT INTO conversion_events (event_id, tenant_id, event_name, payload, status, attempts, created_at)
src/modules/outbound-conversions/emitter.ts:651:     ON CONFLICT (event_id) DO NOTHING`,
src/modules/outbound-conversions/emitter.ts:659:    if (dest.destination_type === 'meta_capi') {
src/modules/outbound-conversions/emitter.ts:674:    `UPDATE conversion_events SET status = $1, attempts = attempts + 1, last_attempt_at = NOW() WHERE event_id = $2`,
src/modules/outbound-conversions/routes.ts:19:  'meta_capi',
src/modules/outbound-conversions/routes.ts:33:    CREATE TABLE IF NOT EXISTS outbound_conversion_destinations (
src/modules/outbound-conversions/routes.ts:51:    CREATE TABLE IF NOT EXISTS outbound_conversion_delivery_logs (
src/modules/outbound-conversions/routes.ts:55:      event_id TEXT NOT NULL,
src/modules/outbound-conversions/routes.ts:67:      ALTER TABLE outbound_conversion_destinations
src/modules/outbound-conversions/routes.ts:139:       FROM outbound_conversion_destinations
src/modules/outbound-conversions/routes.ts:171:    if (destinationType === 'meta_capi') {
src/modules/outbound-conversions/routes.ts:173:        return reply.status(400).send({ error: 'platform_pixel_id and platform_token_ref are required for meta_capi' });
src/modules/outbound-conversions/routes.ts:178:        return reply.status(400).send({ error: 'valid platform_token_ref is required for meta_capi' });
src/modules/outbound-conversions/routes.ts:209:      `INSERT INTO outbound_conversion_destinations
src/modules/outbound-conversions/routes.ts:240:      'SELECT id, destination_type, platform_token_ref FROM outbound_conversion_destinations WHERE id = $1 AND tenant_id = $2 AND deleted_at IS NULL',
src/modules/outbound-conversions/routes.ts:260:      if (destType === 'meta_capi') {
src/modules/outbound-conversions/routes.ts:290:      `UPDATE outbound_conversion_destinations SET ${sets.join(', ')} WHERE id = $${pi}
src/modules/outbound-conversions/routes.ts:318:      'SELECT * FROM outbound_conversion_destinations WHERE id = $1 AND tenant_id = $2 AND deleted_at IS NULL',
src/modules/outbound-conversions/routes.ts:327:      event_id: `test_${tenantId}_${Date.now()}`,
src/modules/outbound-conversions/routes.ts:342:    if (d.destination_type === 'meta_capi') {
src/modules/outbound-conversions/routes.ts:386:        event_name: 'StartTrial',
src/modules/outbound-conversions/routes.ts:410:          'X-KeyBuzz-Event-Id': testPayload.event_id,
src/modules/outbound-conversions/routes.ts:427:      `UPDATE outbound_conversion_destinations
src/modules/outbound-conversions/routes.ts:432:    const testEventName = d.destination_type === 'meta_capi' ? 'PageView'
src/modules/outbound-conversions/routes.ts:434:      : d.destination_type === 'linkedin_capi' ? 'StartTrial'
src/modules/outbound-conversions/routes.ts:438:      `INSERT INTO outbound_conversion_delivery_logs
src/modules/outbound-conversions/routes.ts:439:       (destination_id, event_name, event_id, attempt, status, http_status, error_message, delivered_at)
src/modules/outbound-conversions/routes.ts:441:      [id, testPayload.event_id, testStatus, httpStatus, errorMessage, testEventName]
src/modules/outbound-conversions/routes.ts:453:        event_id: testPayload.event_id,
src/modules/outbound-conversions/routes.ts:472:      'SELECT id FROM outbound_conversion_destinations WHERE id = $1 AND tenant_id = $2 AND deleted_at IS NULL',
src/modules/outbound-conversions/routes.ts:478:      'UPDATE outbound_conversion_destinations SET deleted_at = NOW(), deleted_by = $1, is_active = false, updated_at = NOW() WHERE id = $2',
src/modules/outbound-conversions/routes.ts:500:      'SELECT id FROM outbound_conversion_destinations WHERE id = $1 AND tenant_id = $2',
src/modules/outbound-conversions/routes.ts:506:      `SELECT id, destination_id, event_name, event_id, attempt, status,
src/modules/outbound-conversions/routes.ts:508:       FROM outbound_conversion_delivery_logs
src/modules/outbound-conversions/routes.ts:514:      'SELECT count(*) as total FROM outbound_conversion_delivery_logs WHERE destination_id = $1',
src/modules/funnel/routes.ts:4:const ALLOWED_EVENTS = [
src/modules/funnel/routes.ts:6:  'register_started',
src/modules/funnel/routes.ts:26:type FunnelEventName = typeof ALLOWED_EVENTS[number];
src/modules/funnel/routes.ts:139:    `SELECT id FROM tenants WHERE id = $1 OR marketing_owner_tenant_id = $1`,
src/modules/funnel/routes.ts:169:    if (!(ALLOWED_EVENTS as readonly string[]).includes(body.event_name)) {
src/modules/funnel/routes.ts:170:      return reply.status(400).send({ error: 'INVALID_EVENT_NAME', message: `event_name must be one of: ${ALLOWED_EVENTS.join(', ')}`, received: body.event_name });
src/modules/funnel/routes.ts:289:        const emptySteps = ALLOWED_EVENTS.map(name => ({ event_name: name, count: 0, conversion_rate_from_previous: name === 'register_started' ? 100 : 0 }));
src/modules/funnel/routes.ts:306:      const steps = ALLOWED_EVENTS.map(name => {
src/modules/orders/routes.ts:326:    orderDate: o?.PurchaseDate || new Date().toISOString(),
src/config/sav-decision-tree.ts:30:  daysSincePurchase?: number;
src/config/sav-decision-tree.ts:90:      { id: 'days_since', label: 'Date achat connue', check: s => s.daysSincePurchase !== undefined, weight: 2 },
src/config/sav-decision-tree.ts:117:      { id: 'days_since', label: 'Delai depuis livraison connu', check: s => s.daysSincePurchase !== undefined, weight: 3 },
src/config/sav-decision-tree.ts:168:      { id: 'days_since', label: 'Date achat connue (delai retractation)', check: s => s.daysSincePurchase !== undefined, weight: 4 },
src/config/sav-decision-tree.ts:181:      { condition: s => s.daysSincePurchase !== undefined && s.daysSincePurchase <= 14, action: 'confirmer que le retour est dans le delai legal' },
src/config/sav-decision-tree.ts:184:      if (s.daysSincePurchase !== undefined && s.daysSincePurchase > 14) return 'Informer que le delai de retractation de 14 jours est depasse';
src/config/sav-decision-tree.ts:196:      { id: 'warranty_check', label: 'Garantie verifiable (date achat)', check: s => s.daysSincePurchase !== undefined, weight: 3 },
src/config/sav-decision-tree.ts:209:      { condition: s => s.hasPhotos && s.daysSincePurchase !== undefined && s.daysSincePurchase <= 730, action: 'orienter vers la garantie legale (2 ans)' },
src/config/sav-decision-tree.ts:271:      { id: 'purchase_date', label: 'Date d\'achat connue', check: s => s.daysSincePurchase !== undefined, weight: 4 },
src/config/sav-decision-tree.ts:284:      { condition: s => s.daysSincePurchase !== undefined && s.daysSincePurchase <= 730, action: 'confirmer que le produit est sous garantie legale de conformite' },
src/config/sav-decision-tree.ts:285:      { condition: s => s.daysSincePurchase !== undefined && s.daysSincePurchase > 730, action: 'informer que la garantie legale est potentiellement expiree' },
src/config/sav-decision-tree.ts:288:      if (s.daysSincePurchase === undefined) return 'Identifier la date d\'achat pour verifier la garantie';
src/config/sav-decision-tree.ts:289:      if (s.daysSincePurchase <= 730) return 'Orienter vers la prise en charge garantie (legale ou constructeur)';
src/config/sav-decision-tree.ts:537:  let daysSincePurchase: number | undefined;
src/config/sav-decision-tree.ts:540:    daysSincePurchase = Math.floor((Date.now() - purchaseMs) / (1000 * 60 * 60 * 24));
src/config/sav-decision-tree.ts:559:    daysSincePurchase,
src/services/ai-actions.service.ts:338:export async function addPurchasedActions(
src/services/responseStrategyEngine.ts:158:    if (signals.deliveryWindowPassed || (signals.daysSincePurchase !== undefined && signals.daysSincePurchase > 14)) {
```

Constats :

-  emet deja  au montage via .
-  dedupe en memoire par , puis POST vers .
-  existe, mais ne fait rien si  est absent.
-  charge Meta uniquement si  existe au build/runtime bundle.
-  n'est pas present en source Client/API actuelle.

## Audit passif bundle / HTML Client

Fetch passif uniquement, sans navigateur JS.

```text
prod|register_code=200|bytes=9188
prod|assets=15
dev|register_code=200|bytes=9188
dev|assets=15
```

| Marker | Client PROD | Client DEV | Conclusion |
| --- | ---: | ---: | --- |
| `fbq(` | 1 | 1 | passive_count |
| `trackCustom` | 0 | 0 | passive_count |
| `1234164602194748` | 0 | 0 | passive_count |
| `connect.facebook.net` | 0 | 0 | passive_count |
| `fbevents.js` | 0 | 0 | passive_count |
| `t.keybuzz.pro` | 0 | 0 | passive_count |
| `G-R3QQDYEBFG` | 0 | 0 | passive_count |
| `9969977` | 1 | 1 | passive_count |
| `wuk12h9i33` | 1 | 1 | passive_count |
| `D7PT12JC77U44OJIPC10` | 0 | 0 | passive_count |
| `signup_complete` | 1 | 1 | passive_count |
| `register_started` | 1 | 1 | passive_count |
| `trial_page_viewed` | 0 | 0 | event_absent_current_runtime |
| `StartTrial` | 0 | 0 | static_only_if_present_no_event_triggered |
| `Purchase` | 0 | 0 | static_only_if_present_no_event_triggered |
| `CompletePayment` | 0 | 0 | static_only_if_present_no_event_triggered |
| `InitiateCheckout` | 1 | 1 | passive_count |

Conclusion snippet Antoine :

- Si , le snippet Antoine est un no-op probable sur Client PROD car  sera faux.
- Si le bundle contient , le snippet peut emettre un browser event, mais reste expose a adblock, consent, ITP, absence server-side et attribution partielle.
- Dans tous les cas, aucune livraison Ads Manager n'est prouvee par cette inspection passive.

Etat observe PH-21.78 :

| Point | Observe | Decision |
| --- | --- | --- |
| Client PROD  | 1 | NOOP_PROBABLE |
| Client PROD Meta Pixel ID | 0 | browser possible seulement si >0 |
| Client PROD connect.facebook | 0 | browser possible seulement si >0 |
| Client PROD  | 0 | absent, patch requis |
| Client PROD  | 1 | signal interne present dans bundle |
| Client PROD sGTM | 0 | contexte tracking passif conserve |
| Client PROD LinkedIn | 1 | contexte tracking passif conserve |
| Client PROD Clarity | 1 | contexte tracking passif conserve |
| Client DEV  | 1 | reference DEV |
| Client DEV Meta Pixel ID | 0 | reference DEV |

## Audit funnel / server-side existant

| Brique | Existe | Reutilisable | Risque | Decision proposee |
| --- | --- | --- | --- | --- |
|  | Oui | Oui | allowlist stricte, pas de outbound | Reutiliser comme trigger source |
|  | Oui | Oui | nom interne, pas visible Meta Ads | Deriver  depuis le premier  |
|  idempotence | Oui | Oui | unique  seulement | Ajouter idempotence outbound dediee |
|  | Oui | Partiel | fbp/fbc/fbclid peuvent etre absents | Enrichir CAPI si dispo, sinon event low EMQ assumee |
|  | Oui | Oui si present | absent sur direct traffic | Resolver owner depuis attribution ; fallback config explicite KBC a designer, pas hardcode |
|  | Oui | Partiel | type limite a StartTrial/Purchase | Extraire/genericiser pour custom Meta event |
| Meta CAPI adapter | Oui | Oui | mapping actuel StartTrial/Purchase seulement | Ajouter custom  avec  conserve |
| Destinations Meta KBC | Oui metadata-only | Oui | token secret non lu | Router Meta uniquement, pas TikTok/LinkedIn par defaut |

Reponse aux questions techniques :

-  correspond deja a l'arrivee sur  si un  existe.
- Il est dedupe cote Client en memoire et cote API via .
- L'event_id outbound conseille :  ou hash stable equivalent, jamais un event_id aleatoire par refresh.
- Le pipeline CAPI actuel n'accepte pas proprement les custom events sans patch : type  limite a .
- L'evenement doit partir uniquement vers Meta dans cette demande Antoine, pas vers toutes les destinations actives.
- Owner cible : tenant marketing owner KBC si present via ; sinon fallback explicite de configuration serveur a designer, pas hardcode source.
- Si aucun owner resolu et aucune config fallback, ne pas envoyer a Meta et logguer skip safe.

## DB read-only

Transactions via API pods avec  puis .

```text
DEV|pod=keybuzz-api-77cd59c478-jd994
DEV|db_info|{"db":"keybuzz","now_utc":"2026-06-21T09:30:55.804Z","readonly":"on"}
DEV|funnel_events.signals|[{"event_name":"register_started","total":39,"last30d":5,"last7d":0,"last48h":0,"first_seen":"2026-04-23T21:00:48.119Z","last_seen":"2026-06-09T20:47:57.660Z"},{"event_name":"tenant_created","total":2,"last30d":0,"last7d":0,"last48h":0,"first_seen":"2026-05-20T16:12:33.075Z","last_seen":"2026-05-22T00:06:43.920Z"}]
DEV|conversion_events.signals|[]
DEV|delivery_logs.signals|[{"event_name":"StartTrial","status":"delivered","total":1,"last30d":0,"last_seen":"2026-04-24T13:52:38.711Z"},{"event_name":"StartTrial","status":"failed","total":1,"last30d":0,"last_seen":"2026-04-25T08:17:06.237Z"},{"event_name":"StartTrial","status":"success","total":1,"last30d":0,"last_seen":"2026-04-27T15:38:25.609Z"}]
DEV|destinations.metadata|[{"tenant_id":"keybuzz-consulting-mo9y479d","destination":"linkedin_capi","active":true,"deleted":false,"token_metadata":"encrypted","n":1},{"tenant_id":"ecomlg-001","destination":"meta_capi","active":false,"deleted":true,"token_metadata":"encrypted","n":2},{"tenant_id":"keybuzz-consulting-mo9y479d","destination":"meta_capi","active":false,"deleted":true,"token_metadata":"encrypted","n":1},{"tenant_id":"keybuzz-consulting-mo9y479d","destination":"tiktok_events","active":false,"deleted":true,"token_metadata":"encrypted","n":1},{"tenant_id":"ecomlg-001","destination":"webhook","active":false,"deleted":true,"token_metadata":"missing","n":2},{"tenant_id":"keybuzz-consulting-mo9y479d","destination":"webhook","active":false,"deleted":true,"token_metadata":"missing","n":2}]
DEV|side_effect.counts_before_after_same_readonly_tx|{"before":{"funnel_events":113,"conversion_events":0,"outbound_conversion_delivery_logs":7,"outbound_conversion_destinations":9,"signup_attribution":10,"tenants":32},"after":{"funnel_events":113,"conversion_events":0,"outbound_conversion_delivery_logs":7,"outbound_conversion_destinations":9,"signup_attribution":10,"tenants":32}}
PROD|pod=keybuzz-api-57d574664f-twssl
PROD|db_info|{"db":"keybuzz_prod","now_utc":"2026-06-21T09:30:56.652Z","readonly":"on"}
PROD|funnel_events.signals|[{"event_name":"register_started","total":169,"last30d":78,"last7d":18,"last48h":6,"first_seen":"2026-04-24T07:59:18.555Z","last_seen":"2026-06-21T08:29:58.777Z"},{"event_name":"tenant_created","total":3,"last30d":3,"last7d":1,"last48h":0,"first_seen":"2026-06-08T00:27:02.908Z","last_seen":"2026-06-18T08:44:23.241Z"}]
PROD|conversion_events.signals|[{"event_name":"Purchase","status":"sent","total":1,"last30d":0,"last7d":0,"last_seen":"2026-05-19T09:23:46.265Z"},{"event_name":"StartTrial","status":"sent","total":2,"last30d":0,"last7d":0,"last_seen":"2026-05-05T09:23:11.459Z"}]
PROD|delivery_logs.signals|[{"event_name":"Purchase","status":"delivered","total":3,"last30d":0,"last_seen":"2026-05-19T09:23:47.831Z"},{"event_name":"StartTrial","status":"delivered","total":7,"last30d":0,"last_seen":"2026-05-05T09:23:13.000Z"},{"event_name":"StartTrial","status":"success","total":1,"last30d":0,"last_seen":"2026-04-27T15:57:16.005Z"}]
PROD|destinations.metadata|[{"tenant_id":"keybuzz-consulting-mo9zndlk","destination":"linkedin_capi","active":true,"deleted":false,"token_metadata":"encrypted","n":1},{"tenant_id":"keybuzz-consulting-mo9zndlk","destination":"meta_capi","active":true,"deleted":false,"token_metadata":"encrypted","n":1},{"tenant_id":"keybuzz-consulting-mo9zndlk","destination":"tiktok_events","active":true,"deleted":false,"token_metadata":"encrypted","n":1},{"tenant_id":"ecomlg-001","destination":"meta_capi","active":false,"deleted":true,"token_metadata":"encrypted","n":5},{"tenant_id":"keybuzz-consulting-mo9zndlk","destination":"meta_capi","active":false,"deleted":true,"token_metadata":"encrypted","n":1},{"tenant_id":"keybuzz-consulting-mo9zndlk","destination":"tiktok_events","active":false,"deleted":false,"token_metadata":"encrypted","n":1},{"tenant_id":"keybuzz-consulting-mo9zndlk","destination":"tiktok_events","active":false,"deleted":true,"token_metadata":"encrypted","n":1},{"tenant_id":"ecomlg-001","destination":"webhook","active":false,"deleted":true,"token_metadata":"missing","n":2},{"tenant_id":"keybuzz-consulting-mo9zndlk","destination":"webhook","active":false,"deleted":true,"token_metadata":"missing","n":1}]
PROD|side_effect.counts_before_after_same_readonly_tx|{"before":{"funnel_events":286,"conversion_events":3,"outbound_conversion_delivery_logs":19,"outbound_conversion_destinations":14,"signup_attribution":19,"tenants":21},"after":{"funnel_events":286,"conversion_events":3,"outbound_conversion_delivery_logs":19,"outbound_conversion_destinations":14,"signup_attribution":19,"tenants":21}}
```

Synthese DB :

| Env | Table | Signal | Fenetre | Count | Verdict |
| --- | --- | --- | --- | ---: | --- |
| DEV/PROD |  |  | 30j/7j/48h | voir raw ci-dessus | source interne existante |
| DEV/PROD |  |  | all/30j/7j/48h | voir raw ci-dessus | absent attendu |
| DEV/PROD |  |  | all/30j/7j | voir raw ci-dessus | absent attendu |
| DEV/PROD |  |  | all/30j | voir raw ci-dessus | absent attendu |
| DEV/PROD |  | Meta/TikTok/LinkedIn metadata | current | voir raw ci-dessus | metadata-only, token non lu |

## Options d'implementation

| Option | Avantage | Risque | Prerequis | Recommandation |
| --- | --- | --- | --- | --- |
| A - Browser-only Meta snippet | Simple, proche de la demande Antoine | No-op si  absent, adblock/consent/ITP, aucun server-side, dedup absent, attribution partielle | Meta Pixel charge sur Client  | Non recommande comme option principale |
| B - Server-side CAPI depuis API | Fiable, controle idempotence, pas dependant du navigateur, visible Meta CAPI | EMQ plus faible si fbp/fbc absents, necessite patch API et routing owner | Trigger , destination Meta KBC, event_id stable | Recommande |
| C - Hybrid browser + server-side dedup | Couverture maximale et dedup Meta possible | Complexite, risque double comptage si event_id diverge, necessite charger Meta browser |  present + event_id partage + consent strategy | A garder pour plus tard, pas en premier patch |

Recommendation unique : Option B, server-side Meta CAPI derive de , avec custom event , idempotence et routing owner explicite.

Raison : la demande d'Antoine vise un signal Ads Manager plus fiable que les boutons. Le server-side evite le no-op browser, ne depend pas des pixels charges, et garde  intact.

Limites restantes :

- Meta Ads Manager ne sera prouve qu'apres vrai trafic ou phase de test reel explicite.
- Sans , l'attribution Meta peut rester partielle.
- Le signal restera un micro-event haut de funnel, pas une conversion business.

## Design source patch futur DEV

| Fichier source probable | Changement futur | Risque | Test requis |
| --- | --- | --- | --- |
|  | Ajouter  ou derivation non-polluante depuis  | pollution funnel si mal nomme | tests allowlist/idempotence |
|  | Ajouter chemin custom Meta event pre-tenant/owner-aware | casser StartTrial/Purchase si refactor trop large | tests StartTrial/Purchase inchanges |
|  | Autoriser custom  et event_source_url  | mauvais mapping Meta | tests unit buildMetaServerEvent |
|  | Idealement aucun changement si derivation API depuis  suffit | si ajout browser, risque double event | verifier bundle seulement |
|  | Aucun changement recommande en premiere intention | dedup browser deja en place | tests offline si touche |
|  | Plus tard seulement : image DEV du patch | GitOps drift | phase build/apply separee |

Design recommande :

1. DEV source patch API uniquement en premier.
2. Ajouter un emitter Meta custom dedie .
3. Trigger exact : premier  recorde, pas les duplicates .
4. event_id stable : derive du , par exemple hash .
5. Owner resolution :  ou attribution stockee si presente ; fallback config serveur explicite si decidee par Ludovic/Ops ; jamais hardcode.
6. Destination : Meta CAPI uniquement pour cette phase.
7. Ne pas ecrire dans  business si l'on veut garder les business conversions propres ; utiliser soit une table/log dediee, soit delivery logs avec event custom clairement classe.
8. Aucun event live dans tests source ; tests offline/mock fetch uniquement.

Prochain GO recommande :

```
GO SOURCE PATCH ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV PH-SAAS-T8.12AS.21.79
```

## Non-regression obligatoire

| Surface | Baseline | Verification read-only | Verdict |
| --- | --- | --- | --- |
|  legacy | route localisee, flow email/OTP/company/user/checkout | source relue | PRESERVER |
| plan/cycle continuity | sessionStorage + URL params | source relue | PRESERVER |
| UTM/fbclid/fbc/fbp capture |  | source relue | PRESERVER |
|  | capture query + create-signup | source relue | PRESERVER |
| Stripe checkout |  | source relue, non execute | PRESERVER |
|  | billing webhook server-side | source relue, aucun test fake | PRESERVER |
|  | billing transition server-side | source relue, aucun test fake | PRESERVER |
|  business | StartTrial/Purchase | DB read-only | NE PAS POLLUER |
|  internal analytics | micro-events existants | DB read-only | PRESERVER |
| Clarity | Client marker passif | bundle passif | PRESERVER |
| LinkedIn | Client marker passif | bundle passif | PRESERVER |
| sGTM | Client marker passif | bundle passif | PRESERVER |
| Website PROD | clos PH-21.77 | rapport relu | NON TOUCHE |
| Webflow  | hors scope | aucune action | NON TOUCHE |
| Admin marketing/funnel | hors scope | runtime read-only | NON TOUCHE |
| Client GA4 dette | dette separee PH-21.55 | non masquee | OUVERTE |

## No fake metrics / no fake events

| Interdit | Resultat |
| --- | --- |
| Fake  | 0 |
| Fake  | 0 |
| Fake  | 0 |
| Fake checkout Stripe | 0 |
| Formulaire  | 0 |
| Browser JS tracking | 0 |
| POST Meta/TikTok/LinkedIn/GA4/sGTM | 0 |
| DB mutation | 0 |
| Build/deploy/apply | 0 |

## Linear

Pas de changement Linear.

LINEAR_PREPARED_TEXT :

```text
PH-21.78 confirme que trial_page_viewed doit rester distinct de StartTrial. Recommandation : patch DEV server-side Meta CAPI derive du premier register_started, event_id stable, Meta uniquement, aucun fake event. Browser-only snippet Antoine n'est pas retenu comme option principale car depend de fbq/runtime/adblock/consent et peut etre no-op.
```

## Dettes

| Dette | Priorite | Phase recommandee |
| --- | --- | --- |
| Patch source DEV  Meta CAPI | P1 | PH-21.79 |
| Preuve Ads Manager reelle | P1 marketing | phase real traffic explicite apres deploy |
| Event_id hybrid browser/server dedup | P2 | design separe si browser pixel redevient necessaire |
| Client GA4 runtime parity | P2 | dette PH-21.55 separee |
| Test sans CB | hors scope | phase produit/QA separee |

## Rollback futur

Aucun rollback execute ou necessaire dans PH-21.78.

Pour le futur patch PH-21.79, rollback devra etre GitOps strict si build/deploy a lieu dans phases suivantes :

1. Revenir au tag API precedent dans manifest DEV.
2. Commit + push.
3.  du manifest.
4. .

Interdits permanents : , , , .

## Verdict final

READY_SOURCE_PATCH_REQUIRED.

Phrase finale :

```
GO READONLY DESIGN ONBOARDING TRIAL_PAGE_VIEWED META TRACKING DEV PROD READY_SOURCE_PATCH_REQUIRED PH-SAAS-T8.12AS.21.78
STOP
```
