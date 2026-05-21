# PH-SAAS-T8.12AS.20.1-ACQUISITION-TRACKING-GO-AUDIT-01

> Date : 2026-05-21
> Linear : KEY-338 (primary) ; KEY-337 (parent) ; KEY-339, KEY-340, KEY-341, KEY-336 (related)
> Phase : PH-SAAS-T8.12AS.20.1 ACQUISITION TRACKING GO AUDIT (READ-ONLY)
> Environnement : DEV + PROD lecture uniquement

## VERDICT

GO TRACKING AGENCE AVEC RESERVES PH-SAAS-T8.12AS.20.1

Le socle tracking publicitaire et server-side de KeyBuzz est suffisamment solide pour autoriser l agence a demarrer sa campagne :

- Website public PROD : GA4 G-R3QQDYEBFG actif via SGTM t.keybuzz.pro.
- Tracking server-side CAPI : pipeline operationnel, 14 destinations configurees PROD (Meta 7, TikTok 3, LinkedIn 1, webhooks 3), deliveries reelles observees sur 90 jours.
- Tunnel register Client PROD : v3.5.199-register-state-persistence-prod, no fake events, plan_selected unique, marketing_owner_tenant_id preserve.
- Meta ad_spend daily sync LIVE PROD depuis 2026-05-19 (max_date 2026-05-21).

Reserves explicites a partager avec l agence :

- R1 : Clarity client.keybuzz.io non activee. A traiter en PH-20.2 limite a /register et onboarding pre-auth.
- R2 : CTA home (8 Links) et pages features/about/contact/amazon/footer non trackes (0 callsites trackMarketingClick). A traiter en PH-20.3.
- R3 : Compte demo isole pour videos UGC/motion absent. A traiter en PH-20.4.
- R4 : Google Ads token KO (NO GO AS.15.0 maintenu), ad_spend Google stale (max_date 2026-04-28, 23 jours). Scope agence Meta only conseille jusqu a recovery Google.
- R5 : Pixels Meta/TikTok/LinkedIn ABSENTS du bundle Website (decision documentee : conversions deleguees server-side via CAPI). A confirmer avec agence si elle veut un Pixel client en complement.
- R6 : Hardening securite post-incident hors scope PH-20.1, suivi Vault/ESO continue sous KEY-323.

Aucune action mutante n a ete realisee dans cette phase. Aucun secret ou token n a ete affiche.

## E0 PREFLIGHT BASTION + RUNTIME

### Bastion install-v3

| Indicateur | Valeur |
|---|---|
| hostname | install-v3 |
| IP publique | 46.62.171.61 |
| date UTC | 2026-05-21 10:27:57 |
| OS | Ubuntu 6.8.0-88-generic |

### Repos Git

| Repo | Branche | HEAD | Dirty | Remote | Verdict |
|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 39e332ea fix(funnel): emet tenant_created | 223 | github.com/keybuzzio/keybuzz-api | OK branche imposee (dirty hors scope audit, probable noise build .next) |
| keybuzz-client | ph148/onboarding-activation-replay | 8553bad fix(register): persist draft sessionStorage | 1 | github.com/keybuzzio/keybuzz-client | OK branche imposee (dirty hors scope) |
| keybuzz-admin-v2 | main | 3707c83 chore(build): add OCI revision | 0 | github.com/keybuzzio/keybuzz-admin-v2 | OK clean |
| keybuzz-website | main | 3baecc2 fix(website): renomme flag GA4 _gl_present | 0 | github.com/keybuzzio/keybuzz-website | OK clean |
| keybuzz-infra | main | 8645f1d docs(register): rapports PH-19.7 train | 0 | github.com/keybuzzio/keybuzz-infra | OK clean |
| keybuzz-backend | main | b183817 chore(build): add OCI revision | 1 | github.com/keybuzzio/keybuzz-backend | OK branche imposee (dirty hors scope) |

### Runtime K8s

| Service | Namespace | Image runtime | Ready | Verdict |
|---|---|---|---|---|
| keybuzz-api | keybuzz-api-dev | v3.5.251-register-cro-dev | 1/1 | OK |
| keybuzz-api | keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | 1/1 | OK |
| keybuzz-outbound-worker | keybuzz-api-dev | v3.5.165-escalation-flow-dev | 1/1 | OK |
| keybuzz-outbound-worker | keybuzz-api-prod | v3.5.165-escalation-flow-prod | 1/1 | OK |
| keybuzz-client | keybuzz-client-dev | v3.5.205-register-state-persistence-dev | 1/1 | OK |
| keybuzz-client | keybuzz-client-prod | v3.5.199-register-state-persistence-prod | 1/1 | OK |
| keybuzz-website | keybuzz-website-dev | v0.6.18-ga4-cleanup-dev | 1/1 | OK |
| keybuzz-website | keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | 2/2 | OK |
| keybuzz-admin-v2 | keybuzz-admin-v2-dev | v2.12.2-media-buyer-lp-domain-qa-dev | 1/1 | OK |
| keybuzz-admin-v2 | keybuzz-admin-v2-prod | v2.12.2-media-buyer-lp-domain-qa-prod | 1/1 | OK |

Runtime conforme au contexte impose. Aucune mutation.

## E1 INVENTAIRE DOCUMENTAIRE TRACKING

| Rapport | Sujet | Environnement | Dernier verdict | A revalider PH-20.1 |
|---|---|---|---|---|
| PH-WEBSITE-T8.12AS.17.1T-3 GA4-ADDINGWELL DEDUP DIAGNOSTIC | GA4 delivery model + dedup design | PROD+DEV | GO READY (2026-05-18) | Non, conclusions integrees |
| PH-WEBSITE-T8.12AS.17.1T-3-A GA4 DEDUP DB | 0 risque double comptage | PROD+DEV | GO READY (2026-05-18) | Non |
| PH-WEBSITE-T8.12AS.17.1T TRACKING SERVER-SIDE DIAGNOSTIC | root causes server-side identifiees | PROD+DEV | GO READY (2026-05-18) | Non, status server-side reconsolide ici |
| PH-ADMIN-T8.12AS.15.0 SERVER-SIDE TRACKING ADS ACCOUNTS | Google token recovery KO | PROD | NO GO Google (2026-05-15) | Oui, Google KO maintenu, scope agence Meta only |
| PH-ADMIN-T8.12AS.15.3 CAPI DELIVERY PIPELINE | pipeline OK, 0 events recents | PROD | GO + 0 recent events (2026-05-15) | Oui, deliveries presentes depuis (Purchase x3 le 2026-05-19) |
| PH-WEBSITE-T8.12AS.17.1T-4-B AD SPEND META LIVE | Meta ad_spend daily sync LIVE | PROD | GO PROD (2026-05-19) | Non, sync confirmee 2026-05-21 |
| PH-T8.10J MARKETING OWNER STACK PROD | marketing_owner_tenant_id pipeline | PROD | GO PROD (anterieur) | Confirme present chunk Client |
| PH-T8.11AJ MARKETING OWNER TENANT ID CLIENT | playbook closure | PROD | VERDICT (frontmatter) | Confirme present |
| PH-T8.12Q ACQUISITION TRACKING PARITY | parity visual QA cleanup | PROD | (2026-05-01) | Etat respecte cote Client (pas de reactivation IDs) |
| PH-SAAS-T8.12AS.19.7 REGISTER STATE PERSISTENCE | PROD bundle PH-19.3 a PH-19.7 | PROD | GO PROD (2026-05-20) | Non |

## E2 AUDIT WEBSITE TRACKING

Repo : `keybuzz-website` branche `main` HEAD `3baecc2`.

### Source

- `src/components/Analytics.tsx` charge GA4 + Meta Pixel + TikTok Pixel + LinkedIn Insight, gates par presence ID env (NEXT_PUBLIC_*).
- `src/components/ClarityProvider.tsx` injecte Clarity uniquement si NEXT_PUBLIC_CLARITY_PROJECT_ID present ET consent localStorage `keybuzz_cookie_consent` == accepted.
- `src/lib/marketing-tracking.ts` envoie `marketing_cta_click` via gtag, consent-aware, presence flags only (gclid_present, fbclid_present, ttclid_present, li_fat_id_present, cross_domain_gl_present, marketing_owner_tenant_id_present). Aucun Lead / Purchase / Signup. Documente "INTENTION jamais conversion business".
- `src/lib/tracking.ts` : trackSelectPlan / trackClickSignup / trackContactSubmit declenchent fbq("track", "ViewContent") + ttq.track("ViewContent") cote Website. Pas de Lead/Purchase cote Website.

### Build args et runtime

- Dockerfile : ARGs declares pour NEXT_PUBLIC_SITE_MODE, _CLIENT_APP_URL, _GA_ID, _META_PIXEL_ID, _SGTM_URL, _TIKTOK_PIXEL_ID, _LINKEDIN_PARTNER_ID, _CLARITY_PROJECT_ID, _CONTACT_API_URL.
- Manifest PROD : aucun NEXT_PUBLIC_GA / META / TIKTOK / LINKEDIN / CLARITY en env runtime. Valeurs inlinees au build via --build-arg.
- ENV runtime PROD observe : NEXT_PUBLIC_SITE_MODE=production, NODE_ENV=production.

### Bundle live www.keybuzz.pro (HTML home 82 526 bytes)

| Destination | ID/URL attendu | Source presence | Bundle/runtime presence | Statut | Risque |
|---|---|---|---|---|---|
| GA4 | G-R3QQDYEBFG | OUI (NEXT_PUBLIC_GA_ID) | OUI (1 G-, src=t.keybuzz.pro/gtag/js?id=G-R3QQDYEBFG) | ACTIF | Aucun |
| SGTM (Addingwell) | t.keybuzz.pro | OUI (NEXT_PUBLIC_SGTM_URL) | OUI (1 occurrence t.keybuzz.pro/g) | ACTIF | Aucun |
| Meta Pixel | fbq init | OUI cond NEXT_PUBLIC_META_PIXEL_ID | NON (fbq 0 occurrence bundle) | INACTIF | Decision : conversions deleguees server-side via Meta CAPI. A confirmer agence. |
| TikTok Pixel | ttq.load | OUI cond NEXT_PUBLIC_TIKTOK_PIXEL_ID | NON (ttq 0 occurrence) | INACTIF | Decision : conversions deleguees server-side via TikTok Events API. |
| LinkedIn Insight | _linkedin_partner_id | OUI cond NEXT_PUBLIC_LINKEDIN_PARTNER_ID | NON (_linkedin_partner_id 0, le seul "linkedin" est href footer profil personnel) | INACTIF | Decision : conversions deleguees server-side via LinkedIn CAPI. |
| Microsoft Clarity | clarity.ms/tag | OUI cond NEXT_PUBLIC_CLARITY_PROJECT_ID | OUI selon AS.16.1 (active website, ID en build). Bundle home : 0 occurrence "clarity" => verifier consent path | A CLARIFIER | Si Clarity Website active, declenche au consent banner accepte. Documente comme actif en config mais non observe en HTML brut |

Note : la verification Clarity Website non observee dans le HTML peut s expliquer par injection conditionnelle apres consent. Le code source `ClarityProvider.tsx` confirme l injection conditionnelle.

### CTA Website

| Page | Total Links/CTA | Callsites trackMarketingClick | Manque | Priorite |
|---|---|---|---|---|
| `src/app/page.tsx` home | >=8 Links (pricing x4, features x3, amazon x1, comment anchor) | 0 | 8 CTA non trackes | P1 PH-20.3 |
| `src/app/pricing/page.tsx` | 7+ CTA (toggle monthly/yearly, plans, enterprise contact, final primary autopilot, final secondary features) | 7 | Aucun majeur | OK |
| `src/app/features/page.tsx` | N CTA | 0 | Pages content + CTA non trackes | P2 |
| `src/app/about/page.tsx` | N CTA | 0 | Non tracke | P3 |
| `src/app/contact/page.tsx` | N CTA + form | 0 | Form submit non tracke en marketing_cta_click (trackContactSubmit existe via tracking.ts) | P2 |
| `src/app/amazon/page.tsx` | N CTA | 0 | Non tracke | P3 |
| `src/components/Navbar.tsx` | global nav | 5 | Aucun majeur | OK |
| `src/components/Footer.tsx` | footer links | 0 | Non tracke | P2 |

Total callsites trackMarketingClick : 17 / pages publiques 10. Page home critique : 0 tracking.

### No fake metrics Website

- marketing-tracking : emit `marketing_cta_click` consent-aware, presence flags only.
- tracking.ts : trackSelectPlan + trackClickSignup + trackContactSubmit envoient ViewContent (Meta) et ViewContent (TikTok) cote Website pour mesurer intention. Pas de Lead / Purchase / StartTrial cote Website.
- Aucun pixel Lead emis cote Website.

## E3 AUDIT CLIENT TRACKING

Repo : `keybuzz-client` branche `ph148/onboarding-activation-replay` HEAD `8553bad`.

### Bundle live client.keybuzz.io/register?plan=autopilot

Chunk register : `/_next/static/chunks/app/register/page-f7808baeb00480d2.js` (75 113 bytes)

| Pattern | Attendu | Observe chunk | Verdict |
|---|---|---|---|
| kb_signup_form_draft_v1 | >=1 | 2 | OK PH-19.7 |
| kb_signup_cgu_accepted | >=1 | 2 | OK PH-19.6 |
| register-cgu-accepted-note | >=1 | 1 | OK PH-19.6 |
| Voir les CGU | >=1 | 1 | OK PH-19.6 |
| 0 EUR pendant 14 jours | >=1 | 2 | OK PH-19.6 |
| register-lead-shell | >=1 | 1 | OK PH-19.3 |
| register-confirm-plan | >=1 | 1 | OK PH-19.3 |
| data-selected | >=1 | 1 | OK PH-19.4 selection plan |
| aria-pressed | >=1 | 1 | OK PH-19.4 |
| invalid_marketing_owner_tenant_id | >=1 | 1 | OK PH-19.4 fallback |
| data-clarity-mask | >=13 PII inputs | 13 | OK protection PII preservee |
| plan_selected emit | 1 unique | 1 | OK KEY-331 |
| Clarity ms | 0 | 0 | OK Clarity NON activee Client |
| NEXT_PUBLIC_CLARITY | 0 | 0 | OK |
| wrff07upjx (candidat Clarity ID) | 0 | 0 | OK |
| G-R3QQDYEBFG | 0 (Client n a pas GA4 client-side direct) | 0 | OK iso baseline |
| fbq | 0 | 0 | OK pas Meta Pixel client |
| ttq | 0 | 0 | OK pas TikTok Pixel client |
| AW- (Google Ads tag direct) | 0 | 0 | OK |
| Lead | 0 | 0 | OK no fake |
| StartTrial | 0 | 0 | OK |
| Purchase | 0 | 0 | OK |
| CompletePayment | 0 | 0 | OK |
| SubmitForm | 0 | 0 | OK |
| InitiateCheckout | 0 | 0 | OK |

Smoke /register PROD :
- /register HTTP 200
- /register?plan=starter HTTP 200
- /register?plan=autopilot HTTP 200
- /register?plan=pro HTTP 200
- /login HTTP 200
- / HTTP 307 (redirect attendu)

Marketing IDs (GA4 G-R3QQDYEBFG, SGTM t.keybuzz.pro, Meta 1234164602194748, TikTok D7PT12JC77U44OJIPC10) omis volontairement du build Client PROD selon decision iso baseline v3.5.198 PH-19.3.

### Clarity Client

| Domaine | Zone | Clarity actuel | Risque PII | Recommandation |
|---|---|---|---|---|
| client.keybuzz.io | /register (pre-auth) | INACTIF | data-clarity-mask 13 inputs preserves | PH-20.2 : activer projet Clarity SEPARE limite a /register et /onboarding pre-auth |
| client.keybuzz.io | /login (pre-auth) | INACTIF | password / email visibles | PH-20.2 inclure /login si activation Clarity |
| client.keybuzz.io | /onboarding etapes | INACTIF | a auditer post-decision | A inclure pre-auth uniquement |
| client.keybuzz.io | /inbox messages | INACTIF | PII client final (emails clients, contenus messages) | NE PAS activer sans audit masking complet |
| client.keybuzz.io | /dashboard, /metrics | INACTIF | chiffres business sensibles | NE PAS activer sans accord explicite |

## E4 AUDIT API / SERVER-SIDE TRACKING

Repo : `keybuzz-api` branche `ph147.4/source-of-truth` HEAD `39e332ea`.

### Architecture server-side

- Module `src/modules/outbound-conversions/` :
  - `emitter.ts` : lit `outbound_conversion_destinations` par tenant, fallback no-op si vide
  - `adapters/meta-capi.ts` -> `https://graph.facebook.com`
  - `adapters/tiktok-events.ts` -> `https://business-api.tiktok.com/open_api/v1.3`
  - `adapters/linkedin-capi.ts` -> `https://api.linkedin.com/rest`
  - `redact-secrets.ts` : helper redaction tokens dans logs
- Module `src/modules/funnel/routes.ts` : `emitFunnelEvent(funnelId, event, source, payload)` events INTERNES produit (non-publicitaire).
- Module `src/modules/metrics/ad-platforms/` : adapters lecture Meta Insights et Google Ads (ad_spend daily sync KEY-322 Q-1T-4-B).
- Aucun GA4 Measurement Protocol server-side observe (GA4 reste 100% client-side via SGTM).

### Funnel events internes 30 jours (DB `funnel_events`)

| Event | Count 30j |
|---|---|
| register_started | 76 |
| email_submitted | 14 |
| otp_verified | 5 |
| plan_selected | 2 |
| company_completed | 7 |
| user_completed | 7 |
| onboarding_started | 6 |
| dashboard_first_viewed | 9 |
| success_viewed | 2 |
| first_response_sent | 2 |

Note : volumes coherents avec signups manuels. plan_selected = 2 confirme l emission unique post-OTP (KEY-331).

### Server-side conversions deliveries (DB `outbound_conversion_delivery_logs`)

Periode totale observee : 2026-04-22 a 2026-05-19 (19 deliveries totales sur la table).

| Event | Status | Count | Premiere delivery | Derniere delivery |
|---|---|---|---|---|
| PageView | failed | 3 | 2026-04-22 18:26 | 2026-04-22 21:36 |
| PageView | success | 1 | 2026-04-23 15:13 | 2026-04-23 15:13 |
| Purchase | delivered | 3 | 2026-05-19 09:23:46 | 2026-05-19 09:23:47 |
| StartTrial | delivered | 7 | 2026-04-25 10:38 | 2026-05-05 09:23 |
| StartTrial | success | 1 | 2026-04-27 15:57 | 2026-04-27 15:57 |
| ViewContent | failed | 1 | 2026-04-25 08:54 | 2026-04-25 08:54 |
| ViewContent | success | 3 | 2026-04-25 10:27 | 2026-05-01 11:13 |

Purchase x3 le 2026-05-19 : 3 destinations differentes HTTP 200/201 (UUID destinations 75a3..., 87f8..., b530...). Probablement Meta CAPI + TikTok + LinkedIn pour un meme evenement business reel (un fan-out CAPI canonique). A confirmer en regardant la nature business du Purchase (probable conversion d un signup anterieur a 30 jours, vu que `signup_attribution.with_checkout = 0` sur les 30 derniers jours).

### Destinations CAPI configurees PROD (DB `outbound_conversion_destinations`)

| destination_type | Count |
|---|---|
| meta_capi | 7 |
| tiktok_events | 3 |
| linkedin_capi | 1 |
| webhook (generic) | 3 |
| Total | 14 |

### signup_attribution agg 30 jours

| Metric | Value |
|---|---|
| total | 10 |
| with_fbclid | 0 |
| with_gclid | 2 |
| with_utm_source | 6 |
| with_checkout | 0 |

Coherence avec memoire `project_signups_manual_no_ads_yet.md` : signups recents = manuels, 0 fbclid. 2 with_gclid restent a verifier (test interne ou trafic organique Google avec gclid envoyes par redirection).

### Tableau Signal | Type | Source | Destination | Preuve | Statut | Risque

| Signal | Type | Source | Destination | Preuve | Statut | Risque |
|---|---|---|---|---|---|---|
| pageview anonyme | client GA4 | Website SGTM | GA4 G-R3QQDYEBFG via t.keybuzz.pro | HTML home 1 occ G-, gtag config | ACTIF | Aucun |
| marketing_cta_click | client GA4 | trackMarketingClick (consent) | GA4 | 17 callsites code | ACTIF presence flags only | OK no PII |
| ViewContent pricing | client Meta+TikTok | trackSelectPlan/trackClickSignup | Meta Pixel + TikTok via window | 4 fbq/ttq calls bundle Website (selon source) | ACTIF cond IDs presents | OK pas Lead |
| register_started | funnel interne | API otp-routes | DB funnel_events | 76 events 30j | ACTIF | OK |
| email_submitted | funnel interne | otp-routes store | DB funnel_events | 14 events 30j | ACTIF | OK |
| otp_verified | funnel interne | otp-routes verify | DB funnel_events | 5 events 30j | ACTIF | OK |
| tenant_created | funnel interne + outbound | tenant-context-routes + signup_attribution INSERT | DB funnel + signup_attribution | 10 lignes attribution 30j | ACTIF | OK |
| checkout_started | funnel interne | billing-routes Stripe session | DB funnel + signup_attribution UPDATE stripe_session_id | 0 with_checkout 30j (cf no signups paye recent) | ACTIF mais 0 instance | OK no fake |
| StartTrial | server-side outbound | billing/routes apres Stripe | emitter -> 14 destinations | 8 deliveries (2026-04-25 a 2026-05-05) | ACTIF | OK reel |
| Purchase | server-side outbound | billing/routes ? | emitter -> Meta+TikTok+LinkedIn (3 dest distinctes) | 3 deliveries 2026-05-19 09:23 HTTP 200/201 | ACTIF | A verifier nature business (probable renouvellement abonne pre-existant) |
| PageView | server-side outbound (legacy ?) | inconnu (pas de PageView dans modules billing) | webhooks | 4 deliveries en avril | ACTIF historique | LOW risk - emission ponctuelle, a clarifier source |
| ad_spend Meta | server-side ingest | CronJob ad_spend_sync_meta (Q-1T-4-B) | DB ad_spend_tenant | 25 lignes platform=meta, max_date 2026-05-21 | ACTIF LIVE | OK |
| ad_spend Google | server-side ingest | Google Ads API | DB ad_spend_tenant | 2 lignes platform=google, max_date 2026-04-28 | STALE | R4 : token a recuperer (NO GO AS.15.0) |

## E5 ANALYSE POST-INCIDENT (limitee au tracking)

Cette section n est pas un audit securite complet (suivi sous KEY-323 Vault/ESO/post-restore).

| Risque post-incident | Preuve lue | Impact tracking | Verdict | Suite recommandee |
|---|---|---|---|---|
| Token Google Ads invalide | AS.15.0/AS.15.1 NO GO 2026-05-15, ad_spend google stale | Bloque ad_spend Google daily sync, hors lecture insights | R4 documente | Recovery Google OAuth a planifier separement (KEY-322 hors PH-20.1) |
| Vault/ESO post-rotation | AS.17.1Q-1F-2 GO 2026 series Q-1B-2A/2B avec validation Stability | Aucun impact direct tracking (CAPI tokens distincts) | OK | Continue sous KEY-323 |
| Mail server keybuzz down | KEY-323 mail server KO | N affecte pas tracking publicitaire (Contact form mail KO separe) | OK pour tracking | KEY-323 mail recovery hors PH-20.1 |
| Backup/restore Postgres | AS.17.1H/AS.17.1N validations partielles | DB tracking accessible normalement, table outbound_conversion_delivery_logs lit OK | OK | OK |
| Token expose / log fuites | aucun token affiche dans code source grep | Pas de credential dans bundle Client ni Website | OK | Continuer policy redact-secrets dans logs |

Conclusion : stabilisation operationnelle tracking OK. Hardening securite restant reste hors scope PH-20.1.

## E6 VERIFICATION CTA PRICING + HOME

Voir tableau E2 (audit Website CTA).

Resume :

| Page | CTA | Type | Destination | Tracking actuel | Manque | Priorite |
|---|---|---|---|---|---|---|
| home | Header CTA pricing (x4 Links) | primary | /pricing | aucun | trackMarketingClick | P1 PH-20.3 |
| home | Header CTA features (x3 Links) | secondary | /features | aucun | trackMarketingClick | P1 PH-20.3 |
| home | Amazon link section | secondary | /amazon | aucun | trackMarketingClick | P2 PH-20.3 |
| home | Comment anchor | nav | #comment | aucun | irrelevant | P3 |
| pricing | toggle monthly | switch | n/a | OUI cta_id=pricing_toggle_monthly | aucun | OK |
| pricing | toggle yearly | switch | n/a | OUI cta_id=pricing_toggle_yearly | aucun | OK |
| pricing | CTA plan (boucle plans) | primary par plan | /client/register?plan=... | OUI cta_id=<dynamique> | aucun | OK |
| pricing | enterprise contact | secondary | /contact | OUI cta_id=pricing_enterprise_contact | aucun | OK |
| pricing | final primary autopilot | primary | /client/register?plan=autopilot | OUI cta_id=pricing_final_primary_autopilot | aucun | OK |
| pricing | final secondary features | secondary | /features | OUI cta_id=pricing_final_secondary_features | aucun | OK |
| features | Tous CTA | various | various | aucun | trackMarketingClick a ajouter | P2 |
| contact | Tous CTA + form submit | mixed | various | aucun callsites marketing (trackContactSubmit existe via tracking.ts) | trackMarketingClick a ajouter sur CTAs | P2 |
| amazon | Tous CTA | mixed | various | aucun | a ajouter | P3 |
| navbar | x5 navigation CTA | nav | various | OUI | aucun | OK |
| footer | links sociaux + nav | nav | various | aucun | a ajouter ou ignorer selon priorite agence | P2 |

Verdict CTA : OK pricing complet. NON OK home et autres pages -> R2.

## E7 CLARITY RECOMMENDATION POUR ANTOINE

### Domaine | Zone | Clarity actuel | Risque PII | Recommandation

| Domaine | Zone | Clarity actuel | Risque PII | Recommandation |
|---|---|---|---|---|
| www.keybuzz.pro | pages publiques (home, pricing, features, etc.) | Code present + consent gate (ClarityProvider.tsx), ID injectable via NEXT_PUBLIC_CLARITY_PROJECT_ID, etat actif a confirmer en navigation reelle post-consent | Bas (pas de PII utilisateur a ce stade) | Maintenir tel quel (Website PROD) ou clarifier l ID Clarity utilise pour Antoine |
| client.keybuzz.io | /register | INACTIF | Bas si data-clarity-mask preserve (13 inputs) | Activer en PH-20.2 avec projet Clarity SEPARE (Option A recommandee) |
| client.keybuzz.io | /login | INACTIF | Medium (email + password) | Inclure dans PH-20.2 SI cible analyse abandon login |
| client.keybuzz.io | /onboarding pre-auth | INACTIF | Bas | Inclure dans PH-20.2 |
| client.keybuzz.io | /inbox / /dashboard / /metrics (post-auth) | INACTIF | HAUT (PII clients final + chiffres business) | NE PAS activer dans PH-20.2 |

### Recommandation finale Option A (recommandee)

- Creer un projet Clarity dedie pour `client.keybuzz.io` (separe du projet Website).
- Activation strictement limitee a `/register` et `/onboarding` pre-auth (et eventuellement `/login` si decision produit explicite).
- Verifier masking via attributs `data-clarity-mask` (deja 13 inputs proteges en PH-19.x).
- Verifier exclusions via `clarity("set", "mask", selector)` ou regex URL exclusion pour empecher Clarity de tracker /inbox, /dashboard, /metrics.
- DEV avant PROD : tester activation `keybuzz-client-dev` ID temporaire d abord.

### Option B (non recommandee sauf demande explicite)

- Reutiliser le projet Clarity existant Website. Ne pas le faire : melangerait Website public et application connectee, complique le filtrage et l analyse, et augmente le risque PII.

## E8 VERDICT GO AGENCE

### Decision

GO TRACKING AGENCE AVEC RESERVES PH-SAAS-T8.12AS.20.1.

### Reserves a partager agence

| Reserve | Bloquant ? | Plan |
|---|---|---|
| R1 Clarity client absent | Non | PH-20.2 |
| R2 CTA home + pages secondaires non trackes | Non | PH-20.3 |
| R3 Compte demo absent | Non | PH-20.4 |
| R4 ad_spend Google stale (token KO) | Partiellement bloquant pour scope Google Ads | Recovery token planifie separement, scope agence Meta only conseille jusque la |
| R5 Pixels Meta/TikTok/LinkedIn ABSENTS Website (server-side only) | Non si agence comprend architecture CAPI | Decision strategique - delegation server-side - a expliciter avec agence |
| R6 Hardening post-incident hors scope | Non pour tracking | Continue sous KEY-323 |

### Phrase agence GO AVEC RESERVES (envoyable)

"Le tunnel register est repare et live en production. Le tracking server-side conversions est operationnel (14 destinations Meta CAPI / TikTok Events API / LinkedIn CAPI / webhooks). GA4 est actif cote Website via notre SGTM Addingwell. Nous avons quelques reserves cote retargeting client-side et UX analytics qui sont planifiees mais non bloquantes : Clarity sur l app cliente, tracking complementaire CTA secondaires, compte demo. Pour la partie Google Ads, il faut encore recuperer un token cote infra. Vous pouvez demarrer en scope Meta sur ce socle, on comblera les reserves au fil de l eau."

### Phrases agence alternatives

- Si l agence demande version "tout est pret" : utiliser GO TRACKING AGENCE READY apres PH-20.2 + PH-20.3.
- Si l agence trouve les reserves bloquantes : passer en NO GO TRACKING AGENCE.

## E9 LINEAR

Cette phase est read-only. Aucun ticket Linear cree, ferme, ou commente automatiquement par CE.

Brouillon de commentaire pour KEY-338 (a poster manuellement par Ludovic ou via session authentifiee) :

```
PH-SAAS-T8.12AS.20.1 audit tracking read-only complet (2026-05-21).

Verdict : GO TRACKING AGENCE AVEC RESERVES.

Etat tracking actuel :
- Website PROD : GA4 G-R3QQDYEBFG via SGTM t.keybuzz.pro actif.
- Pixels Meta/TikTok/LinkedIn ABSENTS Website (delegues server-side via CAPI).
- Tunnel register Client PROD : v3.5.199-register-state-persistence-prod, no fake events, plan_selected unique, marketing_owner_tenant_id preserve.
- Server-side CAPI : pipeline OK, 14 destinations PROD (Meta 7, TikTok 3, LinkedIn 1, webhooks 3).
- Deliveries observees : Purchase x3 le 2026-05-19, StartTrial x8 entre 2026-04-25 et 2026-05-05.
- ad_spend Meta daily sync LIVE PROD (max_date 2026-05-21). ad_spend Google stale (2026-04-28) - token KO.
- Funnel internes 30j : register_started 76, email_submitted 14, otp_verified 5, plan_selected 2, tenant_created 10, with_checkout 0.

Reserves :
- R1 Clarity client absent (KEY-339 PH-20.2).
- R2 CTA home + pages secondaires sans trackMarketingClick (KEY-340 PH-20.3).
- R3 Compte demo absent (KEY-341 PH-20.4).
- R4 ad_spend Google bloque par token KO.
- R5 Pixels client-side absents par decision strategique (server-side only).
- R6 Hardening post-incident hors scope (KEY-323 continue).

Rapport : keybuzz-infra/docs/PH-SAAS-T8.12AS.20.1-ACQUISITION-TRACKING-GO-AUDIT-01.md
```

## E10 NO FAKE METRICS / NO FAKE EVENTS

### Constats client-side

- Website GA4 envoie pageview reel + marketing_cta_click consent-aware avec presence flags only. Pas de Lead/Purchase fake.
- Website Meta/TikTok Pixel : si actives, envoient ViewContent reel pricing (intention). Pas de Lead/Purchase fake.
- Client bundle PROD register : 0 occurrence Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW-. plan_selected emit unique.

### Constats server-side

- StartTrial : 8 deliveries reelles (avril a mai 2026) liees a Stripe checkout completed.
- Purchase : 3 deliveries 2026-05-19. Probablement renouvellement Stripe d un abonne pre-existant (signup_attribution.with_checkout = 0 sur 30j). A confirmer cote billing mais aucun risque "fake" en absence de Stripe session.
- PageView server-side : 4 deliveries en avril, source non identifiee dans code actuel - probable code legacy. Non emergent en mai. Non bloquant mais a verifier en PH-20.x si necessaire.

### Aucun event fabrique

- Pas de tag AW-XXXXXXXXXX cote Client.
- Pas de PII envoyee vers GA4/Meta/TikTok/Ads (presence flags only).
- Pas de Lead/Purchase faux declenche par CE.

## GAPS

1. Source PageView server-side (4 emissions avril) : pas localisee dans code source actuel - probable legacy ou tests. A clarifier si actuellement reproductible.
2. signup_attribution 2 with_gclid dans 30j : nature inconnue (probable trafic organique Google avec gclid). Pas de risque "fake" mais a documenter pour eviter confusion futur.
3. ClarityProvider Website : effectivement injecte au consent OK ? Non confirme via observation directe HTML brut (consent banner pas accepte par le scan). A reverifier en navigation reelle.
4. Page features/about/contact/amazon : 0 callsites trackMarketingClick - PH-20.3.
5. Compte demo isole pour videos UGC/motion : non concu, non integre - PH-20.4.

## ROLLBACK GitOps STRICT

Aucune mutation effectuee dans cette phase. Aucun rollback necessaire.

## CONFIRMATIONS

- AUCUN docker build / push / tag.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN git commit / push.
- AUCUN secret / token affiche.
- AUCUN /opt/keybuzz/credentials/ ou /opt/keybuzz/secrets/ ouvert.
- AUCUN evenement test envoye vers GA4/Meta/TikTok/Google Ads/LinkedIn (les events PROD observes sont reels et historiques).
- AUCUNE conversion publicitaire artificielle creee.
- AUCUNE PII publiee dans ce rapport (les UUIDs destinations dans le tableau Purchase sont des IDs internes, non sensibles).
- AUCUN Linear ticket cree, ferme, ou modifie automatiquement.
- Bastion install-v3 (46.62.171.61) uniquement.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO TRACKING AGENCE AVEC RESERVES PH-SAAS-T8.12AS.20.1 |
| Bastion | install-v3 46.62.171.61 |
| Client PROD | v3.5.199-register-state-persistence-prod (8553bad) |
| API PROD | v3.5.250-ad-spend-sync-all-prod |
| Website PROD | v0.6.18-ga4-cleanup-prod |
| keybuzz-infra HEAD | 8645f1d |
| GA4 ID Website | G-R3QQDYEBFG (via SGTM t.keybuzz.pro) |
| Destinations CAPI PROD | 14 (Meta 7 / TikTok 3 / LinkedIn 1 / webhooks 3) |
| Deliveries server-side 30j | Purchase 3, StartTrial 8 (reel), PageView 4 (legacy/test), ViewContent 4 |
| signup_attribution 30j | 10 leads (0 fbclid, 2 gclid, 6 utm_source, 0 checkout) |
| ad_spend Meta last sync | 2026-05-21 (LIVE) |
| ad_spend Google last sync | 2026-04-28 (token KO, recovery KEY-322) |
| Clarity Client | INACTIF (recommander PH-20.2) |
| Compte demo | ABSENT (recommander PH-20.4) |
| CTA home tracking | 0 callsites (recommander PH-20.3) |
| Linear KEY-338 | Brouillon comment fourni (non poste par CE) |
| Rapport | keybuzz-infra/docs/PH-SAAS-T8.12AS.20.1-ACQUISITION-TRACKING-GO-AUDIT-01.md (non commit) |

### Prochaines phrases GO possibles

- GO CLARITY CLIENT REGISTER DEV PH-SAAS-T8.12AS.20.2
- GO PATCH WEBSITE CTA TRACKING DEV PH-SAAS-T8.12AS.20.3
- GO DEMO ACCOUNT DESIGN PH-SAAS-T8.12AS.20.4
- GO LEAD RECOVERY CRM DESIGN PH-SAAS-T8.12AS.19.8

STOP.
