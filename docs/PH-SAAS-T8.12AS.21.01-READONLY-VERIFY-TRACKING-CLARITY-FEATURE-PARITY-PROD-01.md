# PH-SAAS-T8.12AS.21.01-READONLY-VERIFY-TRACKING-CLARITY-FEATURE-PARITY-PROD-01

> Date : 2026-05-29
> Linear : KEY-337 parent PH-20/21 (read-only, aucun statut change, aucun commentaire poste ; voir LINEAR_PREPARED_TEXT)
> Phase : PH-SAAS-T8.12AS.21.01 (audit read-only tracking / Clarity / feature parity PROD)
> Environnement : PROD, LECTURE SEULE stricte (aucun build, deploy, docker, kubectl apply, SQL mutation, fake event, trigger CAPI)

## 1. Verdict

GO READONLY VERIFY TRACKING CLARITY AND FEATURE PARITY PROD CRITICAL_FINDING PH-SAAS-T8.12AS.21.01

Le coeur tracking/feature est sain, MAIS un constat de securite declenche le verdict CRITICAL_FINDING
selon la regle de la mission (secret present en DB) :

CONSTAT CRITIQUE (CF-1) : la table `outbound_conversion_destinations.platform_token_ref` stocke des
access tokens publicitaires EN CLAIR au repos pour les destinations CAPI actives (Meta token `EAA...`,
LinkedIn token ~350 car., TikTok token ~40 car.). 0 ligne chiffree (aucun prefixe `aes256gcm:`),
contrairement a `ad_platform_accounts.token_ref` qui est correctement chiffre (`aes256gcm`, 1/1).
Le masquage EN TRANSIT (logs, reponses API, error sanitization PH-T8.7B.3) est en place, donc pas de
fuite observee via les surfaces applicatives auditees ; mais le chiffrement AU REPOS est absent sur
cette table. Severite P0 securite (hardening). Aucun secret n'a ete affiche durant l'audit (seule une
classification de format a ete faite : counts par motif).

Hors ce constat, l'etat serait READY_WITH_DEBTS : runtime conforme, Clarity Client/Website corrects,
Website porte la stack tracking complete avec les IDs courants et zero faux event, pages protegees
no-ad-tracking prouvees en source, parite IA prouvee runtime. Les conversions server-side n'ont aucun
trafic recent (7j) -> sous-brique TRAFFIC_REQUIRED.

## 2. Preflight (E0)

Bastion install-v3 / IPv4 46.62.171.61, kube context kubernetes-admin@kubernetes. Lectures via node+pg
in-pod (variables PG*/DATABASE_URL, aucune valeur secret affichee) et greps bundle in-pod ; runners /tmp
supprimes.

| service | namespace | image runtime | ready | restarts | verdict |
|---|---|---|---|---|---|
| api | keybuzz-api-prod | v3.5.260-amazon-inbound-address-sync-prod | 1/1 | 0 | OK |
| outbound-worker | keybuzz-api-prod | v3.5.165-escalation-flow-prod | 1/1 | 2 (pre-existant) | OK |
| client | keybuzz-client-prod | v3.5.259-ai-assist-notification-scope-prod | 1/1 | 0 | OK |
| admin | keybuzz-admin-v2-prod | v2.12.2-media-buyer-lp-domain-qa-prod | 1/1 | 0 | OK (decouvert, non suppose) |
| website | keybuzz-website-prod | v0.6.22-clarity-restore-prod | 1/1 x2 | 0 | OK (decouvert) |
| backend | keybuzz-backend-prod | v1.0.56-amazon-inbound-dedup-prod | 1/1 | 0 | OK |
| jobs-worker | keybuzz-backend-prod | v1.0.56-amazon-inbound-dedup-prod | 1/1 | 0 | OK |
| amazon-items-worker | keybuzz-backend-prod | v1.0.40-amz-tracking-visibility-backfill-prod | 1/1 | 0 | OK (ancien, worker) |
| amazon-orders-worker | keybuzz-backend-prod | v1.0.40-amz-tracking-visibility-backfill-prod | 1/1 | 4 (pre-existant) | OK |
| backfill-scheduler | keybuzz-backend-prod | v1.0.42-td02-worker-resilience-prod | 0/1 | 0 | DETTE infra (ErrImagePull, 13j, pre-existant, non lie tracking) |

Repos (sur bastion) :

| repo | branche | HEAD | dirty | verdict |
|---|---|---|---|---|
| keybuzz-infra | main | 151fcaf | 0 | OK (cible commit docs-only) |
| keybuzz-api | ph147.4/source-of-truth | 798db37c | 223 | dirty non-bloquant (working copy ops ; lecture seule ; commit cible = infra uniquement) |
| keybuzz-client | ph148/onboarding-activation-replay | ad4e862 | 1 | idem |
| keybuzz-admin-v2 | main | 3707c83 | 0 | OK |
| keybuzz-website | main | eba00d8 | 0 | OK |
| keybuzz-backend | main | c38583a | 1 | dirty non-bloquant |

## 3. Contrat tracking reconcilie (E1)

Sources : SERVER_SIDE_TRACKING_CONTEXT.md (2026-05-01), MEDIA_BUYER_LP_TRACKING_CONTRACT.md (2026-05-09),
memoire projet (Clarity restore PH-20.15). Valeurs courantes retenues (anciennes signalees) :

| surface | valeur courante | ancienne (obsolete) | porteur attendu | observe |
|---|---|---|---|---|
| Client Clarity | wuk12h9i33 | - | Client funnel | PRESENT bundle Client (2) |
| Website Clarity | wrff07upjx | - | Website | PRESENT bundle Website (2) |
| GA4 | G-R3QQDYEBFG | - | Website (+Client funnel selon doc) | Website 18 ; Client 0 (voir CF/dette D-2) |
| sGTM | t.keybuzz.pro | sgtm.keybuzz.io | Website funnel | Website 18 ; ancien 0 |
| Meta Pixel | 1234164602194748 | - | Website (+Client funnel selon doc) | Website 2 ; Client 0 |
| TikTok Pixel | D7PT12JC77U44OJIPC10 | D0SC1MRC77U0R97160K0 | Website | Website 2 ; ancien 0 ; Client 0 |
| LinkedIn Insight | 9969977 | 6438074 | Website + Client funnel | Website 18 ; Client 2 ; ancien 0 |
| Meta CAPI server-side | 1234164602194748 | - | API destinations | destination active presente |
| TikTok Events API server-side | D7PT12JC77U44OJIPC10 | - | API destinations | destination active presente |
| LinkedIn CAPI server-side | - | - | API destinations | destination active presente |
| Google Ads natif | ABSENT par design (via sGTM/Addingwell) | - | - | 0 destination google (conforme) |

Contradictions signalees (non resolues arbitrairement) :
- Le contrat SERVER_SIDE place GA4/Meta/TikTok/sGTM sur le funnel Client (/register,/login), mais la
  baseline de build Client PROD (PH-20.47) OMET ces build-args -> ces pixels NE chargent PAS cote Client
  (voir dette D-2). Le stack browser complet vit sur le Website (keybuzz.pro).
- Anciennes valeurs (sgtm.keybuzz.io, D0SC1MRC77U0R97160K0, 6438074) = 0 occurrence partout : OK,
  proprement remplacees.

## 4. Client PROD bundle (E2)

| marker | attendu | observe (occurrences /app/.next) | verdict |
|---|---|---|---|
| https://api.keybuzz.io | present | 87 | OK |
| https://api-dev.keybuzz.io | absent | 0 | OK (KEY-302 respecte) |
| Clarity wuk12h9i33 + clarity.ms | present | 2 + 2 | OK |
| LinkedIn 9969977 + snap.licdn | present (funnel) | 2 + 5 | OK |
| GA4 G-R3QQDYEBFG / googletagmanager | (selon doc) | 0 / 0 | ECART -> dette D-2 |
| Meta 1234164602194748 / connect.facebook | (selon doc) | 0 / 0 | ECART -> dette D-2 |
| TikTok D7PT12JC77U44OJIPC10 / analytics.tiktok | (selon doc) | 0 / 0 | ECART -> dette D-2 |
| sGTM t.keybuzz.pro | (selon doc) | 0 | ECART -> dette D-2 |
| fbq Purchase / ttq CompletePayment / StartTrial browser | absent | 0 / 0 / 0 | OK (aucune fausse conversion browser) |
| ancien TikTok/LinkedIn (D0SC.../6438074) | absent | 0 / 0 | OK |
| localhost | ne doit pas etre l'API base publique | 9 | A confirmer (probablement fallback NextAuth/vendor ; api base publique = api.keybuzz.io prouve) -> dette D-7 |

Gating route prouve en source (`src/components/tracking/SaaSAnalytics.tsx`) :
FUNNEL_PREFIXES=['/register','/login'] ; BLOCKED_PREFIXES=['/inbox','/dashboard','/orders','/settings',...] ;
`shouldLoad = !isBlockedPage && isFunnelPage && (GA4_ID||META_PIXEL_ID||TIKTOK_PIXEL_ID||LINKEDIN_PARTNER_ID||CLARITY_PROJECT_ID)`.
Comme GA4/Meta/TikTok n'ont pas d'ID au build Client PROD, seuls Clarity + LinkedIn chargent, et
uniquement sur le funnel.

## 5. Website PROD / funnel public (E3)

| tracker | attendu | observe bundle | verdict |
|---|---|---|---|
| Clarity wrff07upjx | present | 2 | OK |
| GA4 G-R3QQDYEBFG | present | 18 | OK |
| Meta Pixel 1234164602194748 + connect.facebook | present | 2 + 2 | OK |
| TikTok D7PT12JC77U44OJIPC10 + analytics.tiktok | present (ID courant) | 2 + 2 | OK |
| LinkedIn 9969977 + snap.licdn | present | 18 + 2 | OK |
| sGTM t.keybuzz.pro | present | 18 | OK |
| api.keybuzz.io (register forwarding) | present | 2 | OK |
| api-dev | absent | 0 | OK |
| fbq Purchase / ttq CompletePayment | absent browser | 0 / 0 | OK |
| track Lead / InitiateCheckout / SubmitForm / CompleteRegistration / Subscribe | absent (dette PH-WEBSITE-18*) | 0 / 0 / 0 / 0 / 0 | OK (dette fake-events CTA = RESOLUE en runtime) |

Note : token brut "Lead" apparait 3x mais AUCUN `fbq('track','Lead')` (track.*Lead=0) -> pas de fausse
conversion ; occurrences benignes (libelle/standard event non declenche). Validation navigateur publique
non faite (pas de clic CTA pour ne pas declencher d'event) : la preuve est source/bundle.

## 6. Server-side tracking API PROD (E4)

Destinations (`outbound_conversion_destinations`, non soft-deleted) :

| destination_type | active | nb | tokens masques en transit | verdict |
|---|---|---|---|---|
| meta_capi | true | 1 | oui (logs/reponses) | PRESENT ; token AU REPOS en clair -> CF-1 |
| linkedin_capi | true | 1 | oui | PRESENT ; token AU REPOS en clair -> CF-1 |
| tiktok_events | true | 1 | oui | PRESENT ; token AU REPOS en clair -> CF-1 |
| tiktok_events | false | 1 | - | inactif |
| google_ads | - | 0 | - | ABSENT par design (conforme) |

Delivery logs (`outbound_conversion_delivery_logs`) : 0 ligne sur 7 jours, 19 lignes all-time ->
server-side conversions = TRAFFIC_REQUIRED (aucun event recent pour prouver la livraison ce mois).

Business events reels (`conversion_events`, 30j) : Purchase 1 (2026-05-19), StartTrial 1 (2026-05-05) ->
events REELS mais tres rares ; pas de fake. `funnel_events` sains (register_started 103, email_submitted
14, dernier 2026-05-28). Aucun event cree par CE.

Classification token AU REPOS (counts seuls, AUCUNE valeur affichee) :
- `outbound_conversion_destinations.platform_token_ref` (actives) : 3 non-null, 0 aes256gcm, 1 = `EAA...`
  (Meta clair), 2 = autres tokens bruts (LinkedIn len 350, TikTok len 40).
- (toutes lignes) : 11 non-null, 7 `EAA...`, 0 aes256gcm.
- `ad_platform_accounts.token_ref` : 1/1 chiffre `aes256gcm` (len 328) -> reference correcte a repliquer.
- `secret` (webhook) : 1 valeur non-null (len 7) sur une destination non-active ; actives = secret null.

## 7. Admin PROD marketing surfaces (E5)

| surface Admin | present source | dependance API | risque secret | verdict |
|---|---|---|---|---|
| /marketing/destinations | oui (page.tsx + proxy + [id]/test + regenerate-secret) | /destinations | input type=password + redact | PRESENTE_SOURCE |
| /marketing/delivery-logs | oui | /delivery-logs | redact present | PRESENTE_SOURCE |
| /marketing/integration-guide | oui | - | - | PRESENTE_SOURCE |
| /marketing/ad-accounts | oui | /ad-accounts (+sync) | input type=password + redact | PRESENTE_SOURCE |
| /marketing/google-tracking | oui | google-observability | - | PRESENTE_SOURCE |
| /marketing/acquisition-playbook | oui | - | - | PRESENTE_SOURCE |
| /marketing/paid-channels | oui | - | - | PRESENTE_SOURCE |
| /marketing/campaign-qa | oui | - | - | PRESENTE_SOURCE |
| /marketing/funnel | oui | funnel/metrics+events | - | PRESENTE_SOURCE |
| /metrics | oui | metrics/overview (redact) | - | PRESENTE_SOURCE |

Validation navigateur authentifiee non faite (pas de cookie/session) -> AUTH_REQUIRED pour la preuve UI
runtime. Masquage UI (password input) + redact helper presents en source.

## 8. Pages protegees / no-ad-tracking (E6)

| page protegee | tracking pub attendu | preuve | verdict |
|---|---|---|---|
| /dashboard /inbox /orders /settings /billing /messages | aucun | SaaSAnalytics BLOCKED_PREFIXES + isFunnelPage gate | PROUVEE_SOURCE |

Les trackers (y compris Clarity) ne chargent que sur /register et /login. Aucun ad-tracker ne peut
charger sur les pages protegees (double protection : route bloquee + ID absents au build pour
GA4/Meta/TikTok).

## 9. AI feature parity / anti-regression (E7)

| feature | preuve | statut |
|---|---|---|
| AI Assist skip notification message-level | api dist v3.5.260 : determineAiAssistNotificationSkip=3, NO_REPLY_PLATFORM_NOTIFICATION=8, BUYER_AMAZON_IDS_PRESENT=1 | PROUVEE_RUNTIME |
| Client skip UX neutre | bundle Client : skipped=6, "Notification syst"=2 | PROUVEE_BUNDLE |
| Amazon inbound/outbound (KEY-323/PH-20.63) | api dist : determineAmazonProvider=8, normalizeInboundValidationStatus=4 ; outbound prouve PH-20.62 | PROUVEE_RUNTIME |
| Promise/escalation guard | api dist : promise-detection=6 | PROUVEE_RUNTIME |
| Seller-first / platform-aware | api dist : policyPosture=20, marketplace_strict=7 | PROUVEE_RUNTIME |
| Trial effectivePlan / FeatureGate | bundle Client : effectivePlan=14 (FeatureGate string minifie) | PRESENTE_BUNDLE |
| Sample demo gating hasRealChannel | bundle Client : hasRealChannel=6 | PRESENTE_BUNDLE |
| Generation IA reelle / KBActions | non declenche (read-only) | TRAFFIC_REQUIRED (deja prouve PH-20.46-QUATER) |
| Alerting credit LiteLLM/Anthropic + fallback | absent | GAP (dette D-5) |

## 10. No fake metrics / no fake events (E8)

| KPI / metrique | source | periode | fiabilite | limite |
|---|---|---|---|---|
| funnel_events | conversion funnel | 30j | fiable | volume faible (signups manuels) |
| conversion_events Purchase/StartTrial | business events | 30j | fiable mais rare (1+1) | TRAFFIC_REQUIRED pour prouver delivery CAPI |
| outbound_conversion_delivery_logs | server-side delivery | 7j | absent (0) / 19 all-time | TRAFFIC_REQUIRED |
| destinations actives | config CAPI | now | fiable | 3 actives (meta/linkedin/tiktok) |

Aucun event cree, aucun test endpoint envoye a Meta/TikTok/LinkedIn/Google, aucun fake signup/checkout/
KBActions, aucune mutation de compteur durant l'audit.

## 11. Dettes priorisees (E9)

| id | severite | domaine | preuve | risque | action recommandee | phase proposee |
|---|---|---|---|---|---|---|
| D-1 (CF-1) | P0 securite | Server-side tracking | platform_token_ref Meta/LinkedIn/TikTok en clair (0 aes256gcm) vs ad_platform_accounts chiffre | token OAuth exfiltrable si acces DB ; rotation requise si compromis | chiffrer platform_token_ref au repos (reutiliser ads-crypto aes256gcm) + migration + envisager rotation tokens | PH-21.02 (DEV avant PROD) |
| D-2 | P1 | Tracking Client funnel | bundle Client : GA4/Meta/TikTok/sGTM absents (build-args omis PH-20.47) | couverture pixel browser /register incomplete vs contrat ; conversions Meta/TikTok reposent sur CAPI | DECISION produit : funnel Client doit-il porter le stack browser ou rester leger (CAPI + Website) ? si oui, rebuild Client avec build-args | PH-21.03 (decision + eventuel rebuild) |
| D-3 | P1 | API / credits | aucun alerting LiteLLM/Anthropic ni fallback multi-provider | panne credit = AI Assist KO silencieux (vu PH-20.46-BIS) | alerting seuil credit + fallback provider | PH-21.04 |
| D-4 | P1 | Server-side validation | delivery logs 0/7j, business events rares | impossible de prouver la livraison CAPI reelle recente | test controle StartTrial/Purchase reel (GO Ludovic) ou attendre trafic | PH-21.05 (ACTION_REQUIRED_TRAFFIC) |
| D-5 | P2 | Amazon backlog | 8 deliveries failed terminales (5 acheteurs reels) | re-contact tardif si rejoue | revue humaine cible par cible (decision business) | PH-20.64 (optionnel) |
| D-6 | P2 | Tracking TikTok server-side | Business API credentials manquants (KEY-196) | spend TikTok non remontee | livraison credentials puis activation Events API spend | dette externe |
| D-7 | P2 | Client bundle | localhost=9 dans bundle | a confirmer que ce n'est pas l'API base publique | audit source des occurrences localhost (probable fallback NextAuth/vendor) | hygiene |
| D-8 | P2 | LinkedIn server-side | CAPI present mais spend/Ads Reporting approval partielle (KEY-205) | attribution spend LinkedIn incomplete | approval LinkedIn Ads Reporting | dette externe |
| D-9 | P2 | Google Ads | import GA4 -> Google Ads (KEY-215) via Addingwell/sGTM, pas natif | attribution Google partielle | finaliser config import | watch |
| D-10 | P2 | Infra backend | backfill-scheduler ErrImagePull 13j (v1.0.42) | scheduler backfill non operationnel | corriger image/manifest backfill-scheduler | hygiene infra |
| D-11 | P2 | Data hygiene DEV | 20+ tenants test DEV | bruit metrics DEV | cleanup controle | PH dediee DEV |
| D-12 | P3 | Trial lifecycle | emails nudge + usage-value dashboard incomplets | conversion trial sous-optimale | phase lifecycle dediee | later |

## 12. Gaps / action required

- CRITICAL : D-1 chiffrement token au repos (P0 securite).
- ACTION_REQUIRED_TRAFFIC : server-side delivery CAPI (D-4) non prouvable sans event reel recent.
- ACTION_REQUIRED_AUTH : preuve UI Admin marketing runtime (E5) necessite session Ludovic.
- DECISION produit : couverture pixel funnel Client (D-2).

## 13. Non-regression / runtime stability (E10)

| service | restarts | logs critiques 30m | tracking errors 2h | verdict |
|---|---|---|---|---|
| api | 0 | 3 lignes error/exception (aucune tracking/clarity/capi) | 0 | OK (surveiller les 3 lignes, non bloquant) |
| client | 0 | 0 | 0 | OK |
| website (x2) | 0 | 0 | 0 | OK |
| admin | 0 | - | - | OK |
| backend + jobs-worker | 0 | - | - | OK |
| backfill-scheduler | 0 | ErrImagePull (pre-existant) | - | DETTE D-10 |

latest non touche ; manifests api/client = v3.5.260 / v3.5.259 (image-pinned, pas de :latest) ; aucun
build/deploy/mutation durant l'audit. infra commit cible = docs-only.

## 14. Propositions de phases suivantes

- PH-21.02 : chiffrement at-rest de outbound_conversion_destinations.platform_token_ref (DEV avant PROD), P0.
- PH-21.03 : decision + eventuel rebuild Client funnel pixel coverage (D-2).
- PH-21.04 : alerting credit LiteLLM/Anthropic + fallback multi-provider (D-3).
- PH-21.05 : validation server-side CAPI par event reel controle (D-4, ACTION_REQUIRED_TRAFFIC, GO Ludovic).
- PH-20.64 (optionnel) : revue humaine des 8 failed Amazon historiques.

## 15. Fichiers / commandes temporaires crees et supprimes

- Scripts node read-only in-pod (introspection, server-side, classification token) : ecrits dans /tmp du
  pod puis rm. Aucune valeur secret affichee (classification de format uniquement).
- Script shell de comptage bundle : in-pod /tmp puis rm.
- Copies locales C:\DEV\KeyBuzz\tmp\ph2101_*.js / .sh : runners locaux (sans secret).
- Aucune mutation DB/runtime/manifest.

## 16. LINEAR_PREPARED_TEXT (non poste - read-only)

Cible proposee : NOUVEAU ticket securite (a creer par Ludovic) ou commentaire KEY-337.
Texte prepare :
"PH-21.01 audit read-only tracking/Clarity/feature parity PROD = CRITICAL_FINDING. Coeur sain (runtime
v3.5.260/v3.5.259/v0.6.22 conforme ; Clarity Client wuk12h9i33 + Website wrff07upjx OK ; Website porte la
stack tracking complete avec IDs courants et 0 faux event ; pages protegees no-ad-tracking prouvees ;
parite IA prouvee runtime). CONSTAT CRITIQUE : outbound_conversion_destinations.platform_token_ref stocke
les access tokens CAPI (Meta/LinkedIn/TikTok) en clair au repos (0 chiffrement, vs ad_platform_accounts
chiffre aes256gcm) ; masquage en transit OK mais chiffrement au repos absent -> P0 securite, chiffrer +
migration + rotation. Dettes : couverture pixel funnel Client (build-args omis), alerting credit LLM +
fallback, server-side delivery sans trafic recent (TRAFFIC_REQUIRED), backfill-scheduler ErrImagePull.
Aucun statut change, aucun event cree."

## 17. Fichier retour CE

C:\DEV\KeyBuzz\tmp\PH-21.01_CE_RETURN.md

## 18. Phrase cible

GO READONLY VERIFY TRACKING CLARITY AND FEATURE PARITY PROD CRITICAL_FINDING PH-SAAS-T8.12AS.21.01

STOP.
