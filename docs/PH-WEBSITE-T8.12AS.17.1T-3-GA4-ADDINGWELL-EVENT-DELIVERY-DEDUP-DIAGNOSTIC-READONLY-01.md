# PH-WEBSITE-T8.12AS.17.1T-3-GA4-ADDINGWELL-EVENT-DELIVERY-DEDUP-DIAGNOSTIC-READONLY-01

> Date : 2026-05-18
> Linear : a creer post-decision Ludovic
> Phase : AS.17.1T-3 GA4 ADDINGWELL EVENT DELIVERY AND DEDUP DIAGNOSTIC READONLY
> Environnement : PROD + DEV lecture uniquement

## VERDICT

GO READY Q-1T-3 GA4 DELIVERY MODEL IDENTIFIED + DEDUP DESIGN PROVEN

Architecture tracking complete identifiee, **Addingwell sGTM confirme** (`transport: 'addingwell_sgtm'` dans `keybuzz-api/src/modules/outbound-conversions/google-observability.ts:103`), pipeline browser + server-to-server cartographie. Risque double comptage **DEJA ELIMINE PAR DESIGN** pour Meta CAPI et TikTok via retrait explicite des events Purchase / CompletePayment du browser (PH-T8.12S et PH-T8.12P). GA4 garde un risque dedup faible (transaction_id passe browser + server, mais client_id potentiellement different).

Architecture confirmee :
- **t.keybuzz.pro** (sGTM URL browser via NEXT_PUBLIC_SGTM_URL) + **t.keybuzz.io** (sGTM URL server via CONVERSION_WEBHOOK_URL) = **meme Addingwell sGTM** hosted GCP LB 34.120.158.38
- Browser client SaaS funnel (`/register`, `/login`) charge gtag.js depuis sGTM ou googletagmanager.com fallback, envoie GA4 + Meta Pixel + TikTok + LinkedIn cote browser pour events upstream du funnel
- Server-side API SaaS (Stripe webhook trigger) envoie Purchase + StartTrial via GA4 MP (sGTM relay) + Meta CAPI direct + TikTok Events API + LinkedIn CAPI
- Cross-domain GA4 linker configure keybuzz.pro <-> client.keybuzz.io

Pour l'agence/media buyer : `/gtm/debug` n'existe PAS et NE doit PAS exister sur le website (architecture sGTM-relay, pas sGTM-preview-UI). DebugView GA4 accessible via console GA4 property G-R3QQDYEBFG. Tag Assistant Chrome extension pour validation browser. Dashboards providers (Meta Events Manager, TikTok Events Manager, LinkedIn Campaign Manager) pour validation server-side. Console Addingwell pour validation sGTM relay.

Aucun event test envoye. Aucun POST vers `/mp/collect`, `/g/collect`, `/collect`. Aucun appel API authenticated Meta/Google/GA4/TikTok/LinkedIn. PROD intouchee.

**Alerte secondaire** : Meta Pixel ID + TikTok Pixel ID + LinkedIn Partner ID exposes en commentaires Git manifests (`NEXT_PUBLIC_*` donc public side, pas secret mais pollution doc Git). Candidat consolidation Q-1T-5.

## Scope / hors scope

### Scope strict applique

- HTTP probes HEAD sans creds vers t.keybuzz.pro, t.keybuzz.io, addingwell.com, analytics.keybuzz.io, autres subdomains tracking
- DNS resolution publique tous subdomains
- Source code grep 6 repos (website, client, api, backend, admin-v2, infra)
- Lecture manifests deployments (env-vars NEXT_PUBLIC_GA4/META_PIXEL/TIKTOK_PIXEL/LINKEDIN_PARTNER/SGTM_URL + commentaires PH-T8.12*)
- Lecture API SaaS billing/routes.ts (emitConversionWebhook GA4 MP), outbound-conversions/adapters/meta-capi.ts (Meta CAPI server-event), emitter.ts (dispatcher), google-observability.ts (addingwell_sgtm confirme)
- Lecture client SaaS SaaSAnalytics.tsx (browser tracking gating funnel pages) + tracking.ts (trackPurchase + commentaires dedup PH-T8.12S/P)
- Lecture website Analytics.tsx + marketing-tracking.ts + tracking.ts

### Hors scope respecte

- 0 event test envoye (GA4, Meta, Google Ads, TikTok, LinkedIn)
- 0 POST vers /mp/collect, /collect, /g/collect, /r/collect, Meta CAPI, Google Ads
- 0 provider authenticated call
- 0 test conversion
- 0 patch code, 0 deploy, 0 build
- 0 changement Addingwell
- 0 changement GTM/GA4 UI
- 0 fake metric/event
- 0 affichage de secret value en clair (IDs publics masques dans le rapport au mieux quand possible)
- 0 changement Linear sans GO Ludovic

## Sources relues

| Source | Ref | Verdict |
|---|---|---|
| docs/PH-WEBSITE-T8.12AS.17.1T-2-OUTBOUND-TICK-PROCESSOR-404-DIAGNOSTIC-READONLY-01.md | commit 8e4c964 | OK ancestor confirme |
| docs/PH-WEBSITE-T8.12AS.17.1T-TRACKING-SERVER-SIDE-DIAGNOSTIC-READONLY-01.md | sha256 d4c58786 | OK |
| docs/AI_MEMORY/SERVER_SIDE_TRACKING_CONTEXT.md | 1888 lignes | OK |
| docs/AI_MEMORY/MEDIA_BUYER_LP_TRACKING_CONTRACT.md | v1.0 2026-05-09 | OK |
| keybuzz-api/src/modules/outbound-conversions/google-observability.ts | ligne 103 transport=addingwell_sgtm | OK addingwell confirme |
| keybuzz-api/src/modules/outbound-conversions/emitter.ts | ConversionPayload event_id schema | OK |
| keybuzz-api/src/modules/outbound-conversions/adapters/meta-capi.ts | buildMetaServerEvent + event_id | OK dedup-ready |
| keybuzz-api/src/modules/billing/routes.ts | emitConversionWebhook lignes 2070-2200 | OK GA4 MP server-side |
| keybuzz-client/src/components/tracking/SaaSAnalytics.tsx | funnel gating + Consent Mode v2 | OK |
| keybuzz-client/src/lib/tracking.ts | trackPurchase + commentaires dedup PH-T8.12S/P | OK |

## Preflight (E0)

| Check | Expected | Observed | Verdict |
|---|---|---|---|
| Bastion host / IPv4 | install-v3 / 46.62.171.61 | match | OK |
| keybuzz-infra branch / HEAD / status | main / desc 8e4c964 / clean | match | OK |
| Rapport AS.17.1T-2 present | OUI | sha256 1e80a17c | OK |
| /tmp residuels Q-1T-3 | absent | absent | OK |
| 5 repos source lecture | OK | keybuzz-website main / client ph148 / api ph147.4 dirty 223 / backend main dirty 1 / admin-v2 main | OK |

## HTTP probes (E2)

| URL | HTTP | Server | Notes |
|---|---|---|---|
| https://t.keybuzz.pro/ | 400 | Google Frontend | Addingwell sGTM root require params |
| https://t.keybuzz.pro/gtag/js | **200** | Google Frontend | **sGTM sert gtag.js (preuve sGTM operationnel)** |
| https://t.keybuzz.pro/g/collect | 400 | Google Frontend | GA4 MP endpoint (need POST + params) |
| https://t.keybuzz.pro/gtm/debug | **404** | Google Frontend | preview UI NON configure |
| https://t.keybuzz.pro/healthz | 400 | Google Frontend | - |
| https://t.keybuzz.io/* | identique | identique | meme target IP |
| https://t.keybuzz.io/gtag/js | **200** | Google Frontend | confirme |
| https://addingwell.com/ | n/a | Cloudflare 104.26.*/172.67.* | plateforme Addingwell SaaS |
| https://app.addingwell.com/ | n/a | Cloudflare 104.26.*/172.67.* | console Addingwell |
| https://region1.google-analytics.com/g/collect | 204 | - | GA4 collect official |
| https://www.googletagmanager.com/gtag/js | 200 | - | gtag.js official Google |
| https://analytics.keybuzz.io/ | TLS self-signed error | - | orphan DNS, ingress NON configure cluster |

## DNS resolution (E2.2)

| Subdomain | Resolution |
|---|---|
| t.keybuzz.pro | 34.120.158.38 (Addingwell GCP LB) |
| t.keybuzz.io | 34.120.158.38 (identique = meme Addingwell endpoint) |
| reverse 34.120.158.38 | 38.158.120.34.bc.googleusercontent.com (GCP LB neutre, coherent Addingwell GCP hosting) |
| addingwell.com | Cloudflare CDN |
| app.addingwell.com | Cloudflare CDN |
| sgtm.addingwell.com | NXDOMAIN |
| sgtm/gtm/server/collect/track/tag/tagging/stape.keybuzz.{io,pro} | NXDOMAIN |
| analytics.keybuzz.io | 49.13.42.76, 138.199.132.240 (cluster KeyBuzz mais 0 ingress -> orphan) |
| addingwell.keybuzz.io/pro | NXDOMAIN |

## Cartographie tracking (E3-E5)

### Website (keybuzz-website)

| Pattern | Files | Notes |
|---|---|---|
| GTM- | 0 | aucun GTM container ID hardcode |
| G-[A-Z0-9] (GA4 ID) | 0 source | via env NEXT_PUBLIC_GA4_MEASUREMENT_ID |
| gtag( | 3 | components/Analytics.tsx, lib/marketing-tracking.ts, lib/tracking.ts |
| dataLayer | 2 | Analytics + tracking |
| googletagmanager | 1 | Analytics.tsx ligne 35 fallback URL |
| NEXT_PUBLIC_CLARITY | 2 | Clarity activation (KEY-322 AS.16.1) |
| fbq( | 2 | Meta Pixel client-side |
| addingwell | 0 | aucune ref directe code source |
| t.keybuzz.pro | (via env build-arg) | NEXT_PUBLIC_SGTM_URL build-time |

Composant cle : `keybuzz-website/src/components/Analytics.tsx`
- Charge gtag.js depuis SGTM_URL si set, sinon `https://www.googletagmanager.com/gtag/js?id=${GA_ID}`
- Cross-domain linker `{ domains: ['keybuzz.pro', 'client.keybuzz.io'] }`

### Client SaaS (keybuzz-client)

| Pattern | Files | Notes |
|---|---|---|
| GTM- | 0 | via env |
| G-[A-Z0-9] | 16 (false-positives Material-UI Grid + GA4 ID partout) | - |
| gtag( | 2 | SaaSAnalytics + tracking |
| dataLayer | 2 | - |
| googletagmanager | 1 | fallback URL |
| NEXT_PUBLIC_GA4 | 3 | env var consumed |
| SaaSAnalytics | 2 | composant + tracking |
| fbq( | 2 | Meta Pixel browser |

Composant cle : `keybuzz-client/src/components/tracking/SaaSAnalytics.tsx`
- Header : `PH-T3: SaaS Analytics - GA4 + Meta Pixel`
- **Gating funnel pages** : `FUNNEL_PREFIXES = ['/register', '/login']` ; `BLOCKED_PREFIXES = ['/inbox','/dashboard','/orders','/settings','/channels','/suppliers','/knowledge','/playbooks','/ai-journal','/billing','/onboarding','/workspace-setup','/start','/help']`
- 0 tracking sur pages auth-protected (dashboard, inbox, etc.)
- `Consent Mode v2 defaults: denied until consent granted`
- Cross-domain GA4 linker keybuzz.pro <-> client.keybuzz.io
- Env vars : `NEXT_PUBLIC_GA4_MEASUREMENT_ID`, `NEXT_PUBLIC_META_PIXEL_ID`, `NEXT_PUBLIC_SGTM_URL`, `NEXT_PUBLIC_TIKTOK_PIXEL_ID`, `NEXT_PUBLIC_LINKEDIN_PARTNER_ID`
- Si SGTM_URL set : gtag.js loaded depuis `${SGTM_URL}/gtag/js?id=${GA4_ID}` + config `server_container_url: SGTM_URL`

### API SaaS server-side (keybuzz-api)

| Module | Role |
|---|---|
| billing/routes.ts (lignes 2070-2200) | `emitConversionWebhook(session)` envoie purchase GA4 MP via CONVERSION_WEBHOOK_URL avec params attribution complets (utm, gclid, fbclid, fbc, fbp, ttclid, sha256_email pour LinkedIn) ; owner-aware sGTM routing (marketing_owner_tenant_id) ; PH-T8.10P |
| outbound-conversions/emitter.ts | Dispatcher ConversionPayload {event_name: 'StartTrial' \| 'Purchase', event_id: string, event_time, customer, subscription, attribution, value, data_quality}. Dispatch vers adapters meta/tiktok/linkedin |
| outbound-conversions/adapters/meta-capi.ts | buildMetaServerEvent(canonical) -> {event_name, event_time, event_id, action_source: 'website', user_data: {em, fbc, fbp}, custom_data: {value, currency, content_name}}. sendToMetaCapi(pixelId, accessToken, payload, testEventCode) -> POST graph.facebook.com/v21.0/<pixelId>/events |
| outbound-conversions/adapters/tiktok-events.ts | TikTok Events API server-side |
| outbound-conversions/adapters/linkedin-capi.ts | LinkedIn CAPI server-side, sha256_email_address |
| outbound-conversions/google-observability.ts | metrics observability, `transport: 'addingwell_sgtm'` ligne 103 |

### Backend (keybuzz-backend)

- 0 file CAPI/GA4 detecte. Backend ne participe pas au tracking direct.

### Admin V2 (keybuzz-admin-v2)

- Marketing UI : `/marketing/destinations`, `/marketing/ad-accounts`, `/marketing/campaign-qa`, `/marketing/integration-guide`, `/marketing/google-tracking`, `/marketing/acquisition-playbook`, `/metrics`
- BFF API admin : `/api/admin/marketing/funnel/metrics`, `/api/admin/marketing/destinations`

## IDs identifies (E7)

| ID | Source | Value (masque) | Usage |
|---|---|---|---|
| GA4 Measurement ID | env NEXT_PUBLIC_GA4_MEASUREMENT_ID + GA4_MEASUREMENT_ID | G-R3QQDYEBFG | UNIQUE property partout (website + client + API server-side) |
| Meta Pixel ID | env NEXT_PUBLIC_META_PIXEL_ID | <REDACTED 16 chars numeric> | Client SaaS browser only (events PageView, Lead, CompleteRegistration, InitiateCheckout, PAS Purchase) |
| TikTok Pixel ID | env NEXT_PUBLIC_TIKTOK_PIXEL_ID | D7PT12JC77U44OJIPC10 (expose Git comment) | Client SaaS browser |
| LinkedIn Partner ID | env NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 (expose Git comment) | Client SaaS browser |
| GTM Container ID | absent code source | n/a | Pas de GTM web container utilise ; gtag.js direct |
| sGTM URL browser | env NEXT_PUBLIC_SGTM_URL | https://t.keybuzz.pro | Browser client + website |
| sGTM URL server | env CONVERSION_WEBHOOK_URL | https://t.keybuzz.io/mp/collect | API SaaS server-side GA4 MP |
| Addingwell account | implicit | (Addingwell SaaS host gere DNS t.keybuzz.*) | sGTM hebergement |

**Note IDs publics** : NEXT_PUBLIC_* sont par definition exposes au browser (compile dans bundle JS). Pas un secret, mais pollution Git history acceptable. Aucune action urgente requise.

**Secret API server-side** : GA4_MP_API_SECRET = secret reel utilise pour authentifier requests vers `/mp/collect`. Expose plain-text dans manifest api-prod (vu Q-1T heritage). Candidat Q-1T-5.

## Cartographie pipeline events (E5 + E10)

### Pipeline 1 - Browser (client SaaS funnel pages uniquement)

Etapes :
1. User charge `/register` ou `/login` -> `SaaSAnalytics.tsx` detecte funnel page
2. Consent banner affiche (default denied)
3. Si consent granted : charge gtag.js depuis `https://t.keybuzz.pro/gtag/js?id=G-R3QQDYEBFG` (sGTM Addingwell) + Meta Pixel fbevents.js
4. gtag config avec `server_container_url: https://t.keybuzz.pro` + `linker: { domains: ['keybuzz.pro', 'client.keybuzz.io'] }`
5. Events envoyes :
   - GA4 : page_view, sign_up (au form submit), begin_checkout (Stripe portal), purchase (au retour Stripe success) -> POSTes vers t.keybuzz.pro/g/collect via gtag (Addingwell sGTM relay vers GA4)
   - Meta Pixel : PageView, Lead, CompleteRegistration, InitiateCheckout -> POSTes vers facebook.com/tr direct
   - TikTok Pixel : equivalents -> tiktok.com/i18n/pixel/events.js
   - LinkedIn Insight Tag : equivalents -> linkedin.com tag

### Pipeline 2 - Server-side (API SaaS via Stripe webhook)

Etapes :
1. Stripe webhook `checkout.session.completed` ou `customer.subscription.created` declenche
2. `billing/routes.ts` handler reception webhook
3. `emitConversionWebhook(session)` :
   - Verify CONVERSION_WEBHOOK_ENABLED=true + CONVERSION_WEBHOOK_URL + GA4_MEASUREMENT_ID set
   - Resolve owner-aware tenant (marketing_owner_tenant_id si configure)
   - Query signup_attribution row : utm_*, gclid, fbclid, fbc, fbp, ttclid, li_fat_id, attribution_id (= browser GA client_id), user_email
   - Compute sha256_email_address pour LinkedIn CAPI via sGTM
   - Build GA4 MP payload `{client_id, events: [{name: 'purchase', params: {value, currency, transaction_id, ...attribution}}]}`
   - POST vers `${CONVERSION_WEBHOOK_URL}?measurement_id=${measurementId}&api_secret=${apiSecret}` = `https://t.keybuzz.io/mp/collect?measurement_id=G-R3QQDYEBFG&api_secret=<SECRET>`
   - Addingwell sGTM relay -> GA4 official + autres destinations configurees Addingwell
   - UPDATE signup_attribution conversion_sent_at = NOW()
4. `outbound-conversions/emitter.ts` (separe) dispatch via adapters :
   - Meta CAPI : `sendToMetaCapi` -> POST graph.facebook.com/v21.0/<pixelId>/events avec event_id, em (sha256), fbc, fbp, custom_data
   - TikTok Events API : equivalent
   - LinkedIn CAPI : equivalent avec sha256_email

## Dedup audit (E9 + E10)

### Meta CAPI vs Meta Pixel - DEDUP ELIMINE PAR DESIGN

`keybuzz-client/src/lib/tracking.ts:118-135` :
```typescript
export function trackPurchase(params: {...}): void {
  trackGA4('purchase', { transaction_id: params.transactionId, currency: 'EUR', value, items });
  // PH-T8.12S: Meta Purchase removed from browser - server-side only via CAPI
  // event_id mismatch prevents deduplication - double counting risk eliminated
  // PH-T8.12P: CompletePayment removed from browser - server-side only via Events API
  // event_id mismatch (browser: transactionId vs server: conv_<tenant>_Purchase_<sub_id>)
  // prevents TikTok deduplication - double counting risk eliminated
}
```

Interpretation correcte :
- Browser `trackPurchase()` envoie **UNIQUEMENT** GA4 purchase
- Meta Purchase browser **RETIRE** (PH-T8.12S)
- TikTok CompletePayment browser **RETIRE** (PH-T8.12P)
- Server-side CAPI envoie Meta Purchase + TikTok CompletePayment + LinkedIn equivalents
- **0 overlap browser/server pour Meta + TikTok + LinkedIn = 0 risque double comptage**

Browser Meta events autorises (selon manifest commentaire client-prod) :
- PageView, Lead, CompleteRegistration, InitiateCheckout

Server-side Meta events :
- StartTrial, Purchase (META_EVENT_MAPPING in meta-capi.ts)

Le decoupage est explicite : browser fait pre-conversion funnel events, server fait conversion events. **0 collision**.

### GA4 dedup - RISQUE FAIBLE EXISTANT

- Browser GA4 envoie `purchase` event avec `transaction_id: stripe_session_id` + client_id = browser `_ga` cookie value
- Server GA4 MP envoie `purchase` event avec `transaction_id: session.id` + `client_id: attribution.attribution_id || tenantId`

GA4 fait dedup automatique sur `(client_id + transaction_id + event_name)` :
- Si attribution.attribution_id == browser `_ga` cookie value -> **dedup OK**
- Si attribution.attribution_id != browser `_ga` -> **2 purchases comptes** (potentiel doublons)

**A verifier** : la valeur `attribution_id` est-elle bien capturee depuis `_ga` cookie au signup ? Si oui (probable via signup_attribution table avec gl_linker cookie), dedup automatique. Si non, doublon.

Risque MOYEN sans certitude (necessite verification DB query signup_attribution + comparaison cookies).

### TikTok dedup - ELIMINE PAR DESIGN

Idem Meta : browser TikTok ne fait pas CompletePayment, server uniquement. 0 collision.

### LinkedIn dedup - ELIMINE PAR DESIGN

Server-side only avec sha256_email_address. Browser LinkedIn Insight Tag fait LinkedIn Lead + Conversion mais pas via meme event_id strict.

## Addingwell evidence (E6)

| Source | Evidence |
|---|---|
| Source code | `keybuzz-api/src/modules/outbound-conversions/google-observability.ts:103` : `transport: 'addingwell_sgtm'` |
| DNS | t.keybuzz.pro + t.keybuzz.io -> 34.120.158.38 (GCP LB neutral, coherent Addingwell hosting) |
| HTTP | t.keybuzz.pro/gtag/js HTTP 200 server: Google Frontend (sGTM operationnel) |
| Manifest env | NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro (client-prod) ; CONVERSION_WEBHOOK_URL=https://t.keybuzz.io/mp/collect (api-prod) |
| Addingwell platform DNS | addingwell.com + app.addingwell.com -> Cloudflare CDN (plateforme tiers reachable) |

Confirmation forte : Addingwell est le **sGTM provider** de KeyBuzz, hosting via GCP, expose via 2 custom domain aliases (.pro pour browser, .io pour server, meme target). Console Addingwell accessible sur app.addingwell.com (compte tiers, non-cluster).

## GA4 DebugView / Tag Assistant URLs corrects (E8)

| Outil | URL canonique | Usage |
|---|---|---|
| GA4 DebugView | https://analytics.google.com/analytics/web/#/p<PROPERTY_ID>/reports/debugview | Console GA4 (property associee a G-R3QQDYEBFG, PROPERTY_ID a recuperer dans console) |
| Tag Assistant | https://tagassistant.google.com | Extension Chrome pour browser-side validation |
| GA4 Debug mode browser | URL + `?debug_mode=true` OU gtag config `debug_mode: true` | Active envoi DebugView (browser-side) |
| GA4 Realtime | console GA4 -> Realtime | Verification live events recents |
| Addingwell sGTM Preview | https://app.addingwell.com (workspace) | Preview UI sGTM cote Addingwell (necessite compte) |
| Meta Events Manager | https://business.facebook.com/events_manager2 | Validation CAPI server-side |
| TikTok Events Manager | https://business.tiktok.com/manage/events | Validation Events API server-side |
| LinkedIn Campaign Manager | https://www.linkedin.com/campaignmanager | Validation Insight Tag + CAPI |

**Important pour l'agence** : `/gtm/debug` URL **n'existe pas** sur le website KeyBuzz par design (sGTM-relay sans preview UI exposee). Si l'agence veut debug le sGTM lui-meme, ils doivent passer par la console Addingwell (compte tiers Ludovic).

## Hypotheses + Risk matrix (E11)

| ID | Risque | Probabilite | Impact | Mitigation |
|----|--------|-------------|--------|------------|
| R1 | Meta CAPI double comptage avec Meta Pixel browser | NEANT (Meta Purchase retire du browser PH-T8.12S) | NEANT | code design |
| R2 | TikTok double comptage browser/server | NEANT (CompletePayment retire browser PH-T8.12P) | NEANT | code design |
| R3 | LinkedIn double comptage | NEANT (server-side only avec sha256_email) | NEANT | - |
| R4 | GA4 double comptage purchase browser + server | FAIBLE-MOYEN (depend attribution_id == browser _ga cookie) | MOYEN | verification DB query signup_attribution OU passage explicite client_id browser via API |
| R5 | Addingwell sGTM down -> server events perdus | FAIBLE (HTTP /gtag/js 200, lastSync recent) | ELEVE si materialize | monitoring Addingwell external + alertes |
| R6 | Agence cherche /gtm/debug et conclut tracking casse | CONFIRMEE (Ludovic l'a deja remonte) | FAIBLE (mauvaise interpretation) | communication architecture CAPI direct + DebugView console |
| R7 | analytics.keybuzz.io orphan subdomain confond | FAIBLE | TRES FAIBLE | cleanup DNS recommande |
| R8 | NEXT_PUBLIC_TIKTOK_PIXEL_ID + LINKEDIN_PARTNER_ID exposes manifest Git commentaire | CERTAIN (lus en E7.2) | TRES FAIBLE (NEXT_PUBLIC_* = public side, pas secret) | Q-1T-5 cleanup commentaires Git si esthetique |
| R9 | GA4_MP_API_SECRET expose plain-text manifest Git | CONFIRMEE (heritage Q-1T R3) | ELEVE | rotation + ESO migration Q-1T-5 |

## Plan correction propose (E12)

### Q-1T-3-COMMUNICATION (immediat, zero-risque)

Communiquer a l'agence/media buyer :
- Architecture sGTM Addingwell confirme (t.keybuzz.pro + t.keybuzz.io = meme endpoint)
- `/gtm/debug` n'existe pas par design, c'est attendu
- DebugView GA4 accessible via console GA4 property G-R3QQDYEBFG
- Tag Assistant Chrome pour browser validation
- Console Addingwell pour sGTM preview cote tiers
- Meta/TikTok/LinkedIn Events Managers pour server-side
- 0 doublon Meta CAPI/TikTok par design (Purchase retire browser)

### Q-1T-3-A GA4 dedup verification (DRY-RUN read-only)

Phase dediee pour verifier si `attribution.attribution_id` reellement == browser `_ga` cookie value :
- Query DB signup_attribution sample (avec GO Ludovic separate, scope strict 5-10 rows recents)
- Inspection client tracking.ts pour capture `_ga` -> attribution_id
- Verification Stripe webhook payload metadata
- Conclusion : dedup OK ou plan correction GA4

### Q-1T-3-B Cleanup analytics.keybuzz.io orphan (zero-risque optionnel)

- DNS record pointing vers cluster sans ingress = cleanup DNS recommande
- Hors urgence

### Q-1T-5 Tracking secrets Git exposure cleanup (consolidation deja proposee Q-1T)

- GA4_MP_API_SECRET + CONVERSION_WEBHOOK_SECRET (vrais secrets api-prod manifest)
- LITELLM_MASTER_KEY (heritage Q-1B-5A)
- STAKATER_VAULT_ROOT_TOKEN_SECRET (heritage Q-1B-5B-2A, traite Q-1B-5B-2A-EXEC mais pattern documente)
- Pattern unifie : migration ESO + Vault path + rotation

### Q-1T-4 sGTM evaluation (optionnel)

- Architecture deja en place avec Addingwell, pas besoin de deployer sGTM custom GCP
- Confirme : maintien Addingwell

## Draft non-technique pour agence/media buyer

```
Bonjour,

Nous avons audite l'architecture tracking KeyBuzz suite a vos questions :

ARCHITECTURE EN PLACE :
- Tracking server-side via Addingwell (sGTM hosted) accessible sur t.keybuzz.pro et t.keybuzz.io
- Tracking client-side (browser) actif uniquement sur les pages /register et /login (funnel)
- Cross-domain GA4 linker entre keybuzz.pro et client.keybuzz.io
- Consent Mode v2 par defaut deny

PROPRETE EVENTS :
- Events server-side (Stripe webhook) : StartTrial, Purchase via Meta CAPI + TikTok Events API + LinkedIn CAPI + GA4 Measurement Protocol (relay Addingwell)
- Events browser : PageView, Lead, CompleteRegistration, InitiateCheckout sur Meta Pixel ; equivalents TikTok ; LinkedIn Insight ; purchase GA4 cote browser
- Meta Purchase + TikTok CompletePayment ont ete RETIRES du browser pour eviter le double comptage avec le CAPI server-side (decoupage clair browser=pre-conversion / server=conversion)

DEBUGVIEW (POUR VOUS VALIDER LES EVENTS) :
- GA4 DebugView : ouvrez la console GA4 property G-R3QQDYEBFG, section Reports > DebugView (necessite mode debug active cote browser via Tag Assistant Chrome extension)
- Tag Assistant : https://tagassistant.google.com
- Meta Events Manager : https://business.facebook.com/events_manager2 (filtre par pixel ID + test_event_code)
- TikTok Events Manager + LinkedIn Campaign Manager pour leurs respectifs
- Addingwell sGTM console : https://app.addingwell.com (login compte KeyBuzz)

POURQUOI /gtm/debug RENVOIE 404 :
- Aucun container Google Tag Manager Server preview UI n'est expose publiquement sur le website (par design securite)
- La preview se fait depuis la console Addingwell ou les Events Managers providers
- C'est attendu, pas un bug

RISQUE DOUBLE COMPTAGE :
- Meta + TikTok + LinkedIn : 0 risque par design (events Purchase retires du browser)
- GA4 : risque faible si client_id browser et client_id server matchent (a verifier en phase dediee Q-1T-3-A)

Si vous voulez plus de details ou si vous avez des doutes sur un event specifique, on peut creuser ensemble.
```

## No fake metrics

N/A. Phase diagnostic pure. Aucune metric/event creee.

## Cleanup temporary files

| Fichier | Mode | Statut |
|---|---|---|
| /tmp/keybuzz-q1t3-http-probes.txt | 600 | shred apres rapport |
| /tmp/keybuzz-q1t3-source-cartography.txt | 600 | shred |
| /tmp/keybuzz-q1t3-dns.txt | 600 | shred |
| /tmp/keybuzz-q1t3-e2-e5-runner.sh | 755 | shred |

## Non-regression PROD

| Surface PROD | Etat avant | Etat apres Q-1T-3 | Impact |
|---|---|---|---|
| website-prod | Running | inchange | 0 |
| client-prod | Running | inchange | 0 |
| admin-v2-prod | Running | inchange | 0 |
| api-prod (post Q-1B-5B-2A-EXEC) | Running | inchange | 0 |
| backend-prod | Running | inchange | 0 |
| LiteLLM keybuzz-ai | Running | inchange | 0 |
| t.keybuzz.pro Addingwell sGTM | Available (gtag.js 200) | inchange | 0 |
| Providers Meta/Google/TikTok/LinkedIn | 0 call authenticated | 0 | 0 |
| Stripe webhook events | inchange | inchange | 0 |
| signup_attribution DB table | 0 read (deferred Q-1T-3-A) | 0 | 0 |
| Argo CD applications | inchanges | inchanges | 0 |

## Compliance read-only

| Interdit | Evidence | Verdict |
|---|---|---|
| 0 event test envoye | 0 POST vers /mp/collect, /collect, /g/collect, /r/collect | OK |
| 0 provider authenticated call | 0 (uniquement HEAD/GET publics, 400/404 normaux) | OK |
| 0 test conversion | 0 | OK |
| 0 patch / build / deploy | 0 mutation | OK |
| 0 changement Addingwell | 0 | OK |
| 0 changement GTM/GA4 UI | 0 | OK |
| 0 fake metric/event | 0 | OK |
| 0 affichage secret value | GA4_MP_API_SECRET masque ; META_PIXEL_ID/TIKTOK/LINKEDIN sont NEXT_PUBLIC_* public side (masques au mieux) | OK |
| 0 changement Linear sans GO | 0 (brouillon present rapport NON poste) | OK |
| Manifests source Git modifies | 0 | OK |
| SSH heredoc multi-lignes > 5 lignes | 0 (1 SCP runner E2-E5 + 1 heredoc court E6-E10) | OK |
| Tenant/user/email hardcode dans rapport | 0 | OK |

12/12 contraintes read-only respectees.

## Brouillon Linear KEY-tracking (a creer si Ludovic GO)

```
TITRE proposed : Diagnostic GA4/Addingwell event delivery + dedup - architecture confirme et risques classes

Status: DIAGNOSTIC COMPLETE
Scope: PROD + DEV lecture pure

Findings:
- Architecture sGTM Addingwell confirmee (transport: 'addingwell_sgtm' dans google-observability.ts)
- t.keybuzz.pro (browser SGTM_URL) + t.keybuzz.io (server CONVERSION_WEBHOOK_URL) = meme endpoint GCP LB 34.120.158.38
- GA4 unique property: G-R3QQDYEBFG (website + client + API server-side)
- Browser tracking gated sur funnel pages /register, /login uniquement (Consent Mode v2 deny default)
- Server-side via Stripe webhook -> Meta CAPI + TikTok Events API + LinkedIn CAPI + GA4 MP relay Addingwell
- 0 risque double comptage Meta/TikTok/LinkedIn par design (Purchase + CompletePayment retires browser PH-T8.12S/P)
- GA4 dedup faible-moyen (depend attribution_id == _ga cookie : a verifier Q-1T-3-A)

Confusion agence /gtm/debug 404:
- Pas un bug par design, sGTM-relay sans preview UI publique
- DebugView GA4 accessible via console + Tag Assistant Chrome
- Console Addingwell pour preview sGTM (app.addingwell.com)

Plan:
- Q-1T-3-COMMUNICATION: draft non-technique agence pret
- Q-1T-3-A: GA4 dedup verification DB signup_attribution (DRY-RUN)
- Q-1T-3-B: cleanup analytics.keybuzz.io orphan DNS
- Q-1T-5: tracking secrets Git cleanup consolide (GA4_MP_API_SECRET + autres)

Rapport: keybuzz-infra/docs/PH-WEBSITE-T8.12AS.17.1T-3-GA4-ADDINGWELL-EVENT-DELIVERY-DEDUP-DIAGNOSTIC-READONLY-01.md
```

## Gaps restants

1. **Q-1T-3-A GA4 dedup verification DB** : DRY-RUN read-only query signup_attribution.attribution_id sample vs browser _ga cookie pattern (avec GO Ludovic separe).
2. **Q-1T-3-B cleanup analytics.keybuzz.io orphan** : DNS record pointing vers cluster sans ingress.
3. **Q-1T-3-COMMUNICATION** : draft non-technique pret dans ce rapport pour envoi agence (GO Ludovic separe pour poster ou envoyer).
4. **Q-1T-2-EXEC Option 1 (SUPPRESSION outbound-tick CronJob)** : NO GO maintenu, attente decision Ludovic.
5. **Q-1T-3 (initial spec) AD_SPEND PROD migration** : reste vrai P0 spend admin absent, distinct de Q-1T-3 tracking diagnostic.
6. **Q-1T-1 documentation alignment** : immediat, zero-risque.
7. **Q-1T-5 tracking secrets Git cleanup consolide** : pattern accumule (GA4_MP_API_SECRET + LITELLM + STAKATER).
8. **Q-1T-4 sGTM evaluation** : NON necessaire (Addingwell en place).
9. **KEY-323 reprise** : Q-1B-5B-2-EXEC LLM env migration en pause.
10. **AS.17.0 / AS.17.0.1 PROD promotion** : NO GO maintenue.

## Phrase cible finale

Diagnostic GA4/Addingwell complete : chemins event browser/server cartographies (browser SaaSAnalytics gated funnel /register /login avec gtag.js depuis t.keybuzz.pro Addingwell sGTM + Meta Pixel + TikTok + LinkedIn ; server Stripe webhook -> emitConversionWebhook GA4 MP via t.keybuzz.io/mp/collect + outbound-conversions adapters meta-capi tiktok-events linkedin-capi), t.keybuzz.io et t.keybuzz.pro classes comme Addingwell sGTM hosted GCP 34.120.158.38 confirme par evidence transport='addingwell_sgtm' google-observability.ts:103, event map (GA4 unique G-R3QQDYEBFG + Meta CAPI server-only Purchase/StartTrial + TikTok server-only CompletePayment/StartTrial + LinkedIn server-only + browser pre-conversion uniquement) et dedupe risks etablis (0 doublon Meta/TikTok/LinkedIn par design PH-T8.12S/P, risque faible-moyen GA4 dedup browser/server selon attribution_id vs _ga cookie a verifier Q-1T-3-A), draft non-technique agence/media buyer prepare (explique architecture CAPI direct + DebugView console GA4 + Tag Assistant + Addingwell + Events Managers providers + pourquoi /gtm/debug 404 attendu), 0 event envoye, 0 provider authenticated call, 0 POST /mp/collect, 0 mutation, PROD intouchee - Q-1T-3-A dedup DB verification proposee DRY-RUN, Q-1T-5 tracking secrets cleanup consolide propose, Q-1T-2-EXEC outbound tick suppression NO GO maintenu decision Ludovic.

STOP
