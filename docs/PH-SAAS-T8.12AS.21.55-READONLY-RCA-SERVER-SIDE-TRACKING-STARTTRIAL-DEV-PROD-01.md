# PH-SAAS-T8.12AS.21.55 - READONLY RCA SERVER-SIDE TRACKING STARTTRIAL DEV PROD

Date UTC: 2026-06-12
Role: Codex Executor
Projet: KeyBuzz SaaS / Tracking server-side / StartTrial
Mode: READONLY RCA tracking server-side StartTrial
Linear: KEY-337 reference, aucun changement Linear

## 1. Verdict

GO READONLY RCA SERVER SIDE TRACKING STARTTRIAL DEV PROD TRAFFIC_REQUIRED PH-SAAS-T8.12AS.21.55

Conclusion courte:

- StartTrial CAPI server-side n'est pas prouve casse.
- PROD contient une preuve historique valide: 1 `StartTrial` `sent` le 2026-05-05, livre sur Meta CAPI HTTP 200, TikTok Events HTTP 200 et LinkedIn CAPI HTTP 201.
- Aucun `StartTrial` recent sur 30j / 7j / 48h, mais aucun vrai checkout/trial recent n'est observe dans les events billing correspondants.
- Des micro-events funnel recents existent en PROD, jusqu'a `tenant_created`, mais ils ne sont pas des trials/billing et ne doivent pas etre transformes en `StartTrial`.
- Google/GA4 est un chemin separe: `signup_complete` n'est pas `StartTrial` CAPI. Le Client runtime courant contient `signup_complete`, mais pas le marker GA4 `G-R3QQDYEBFG`; c'est une dette de parite runtime Google/GA4 a traiter separement, pas une casse server-side CAPI.
- Aucun event de test, aucun POST, aucune mutation DB/runtime/source applicative, aucun token brut affiche.

## 2. Objectif

Verifier en lecture seule si le tracking server-side KeyBuzz fonctionne encore, avec focus `StartTrial`, en distinguant:

- trial/billing produit;
- `conversion_events` et delivery logs internes;
- Meta/TikTok/LinkedIn CAPI;
- Google/GA4 `signup_complete` importe/lisible comme StartTrial cote Google Ads;
- Clarity et browser public tracking;
- absence de trafic reel vs bug.

## 3. Sources relues

| Source | Statut |
| --- | --- |
| `C:\DEV\KeyBuzz\tmp\PH-21.55_CE_MISSION.md` | Lu |
| `AI_MEMORY/CURRENT_STATE.md` | Lu |
| `AI_MEMORY/RULES_AND_RISKS.md` | Lu |
| `AI_MEMORY/DOCUMENT_MAP.md` | Lu |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | Lu |
| Modele `PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01` | Lu cible |
| `PH-21.01_CE_RETURN.md` | Lu |
| `PH-21.15_CE_RETURN.md` | Lu |
| `PH-21.54_CE_RETURN.md` | Lu |
| `PH-T8.7B-META-CAPI-NATIVE-PER-TENANT-01.md` | Lu cible |
| `PH-T8.7B.1-META-CAPI-REAL-VALIDATION-01.md` | Lu cible |
| `PH-T8.7B.2-META-CAPI-PROD-PROMOTION-01.md` | Lu cible |
| `PH-T8.7B.3-META-CAPI-ERROR-SANITIZATION-PROD-PROMOTION-01.md` | Lu cible |
| `PH-ADMIN-T8.8H-KBC-META-CAPI-OUTBOUND-REAL-CONFIG-VALIDATION-01.md` | Presence verifiee |
| `PH-T8.10M-TIKTOK-NATIVE-OWNER-AWARE-FOUNDATION-01.md` | Lu cible |
| `PH-T8.10M.1-TIKTOK-NATIVE-RUNTIME-TRUTH-VALIDATION-01.md` | Lu cible |
| `PH-T8.11W-GOOGLE-ADS-CONVERSIONS-POST-GA4-ACTIVATION-01.md` | Lu cible |
| `PH-T8.11X-GA4-TO-GOOGLE-ADS-CONVERSION-IMPORT-CONFIG-01.md` | Lu cible |
| `PH-T8.11Z-ANALYTICS-BASELINE-CLEAN-READINESS-01.md` | Lu cible |
| `PH-T8.12R-CLIENT-GA4-SGTM-PARITY-AND-TRACKING-DOC-RECONCILIATION-01.md` | Lu cible |

Baseline analytics retenue: `2026-04-29 00:00:00 Europe/Paris`, soit `2026-04-28T22:00:00Z`.

## 4. Preflight runtime/repos

| Controle | Resultat |
| --- | --- |
| Bastion | `install-v3` |
| IPv4 obligatoire | `46.62.171.61` presente |
| IP interdite `51.159.99.247` | Non utilisee |
| Date UTC audit | `2026-06-12T11:03:10Z` |
| Kube context | `kubernetes-admin@kubernetes` |

| Repo/service | Branche/image attendue | Observe | Dirty/ready | Verdict |
| --- | --- | --- | --- | --- |
| keybuzz-infra | `main` | HEAD/origin `c81506a3`, ahead/behind `0/0` | dirty `0` | OK |
| keybuzz-api | `ph147.4/source-of-truth` | HEAD/origin `76483e3a`, ahead/behind `0/0` | dirty `223` preexistant | WARN source dirty, non bloqueur read-only |
| keybuzz-client | `ph148/onboarding-activation-replay` | HEAD/origin `ad4e862a`, ahead/behind `0/0` | dirty `1` preexistant | WARN source dirty, non bloqueur read-only |
| keybuzz-website | `main` attendu | branche observee `redesign/light-business`, HEAD/origin `020794b8` | dirty `0` | WARN branche source locale non conforme, runtime prod audite |
| keybuzz-admin-v2 | `main` | HEAD/origin `3707c834` | dirty `0` | OK |
| keybuzz-backend | `main` | HEAD/origin `c38583a8` | dirty `1` preexistant | WARN source dirty, non bloqueur read-only |
| API DEV | image API DEV | `v3.5.263-llm-provider-credit-watcher-dev`, ready `1/1`, restarts `0` | digest `sha256:93914a...d996` | OK |
| API PROD | image API PROD | `v3.5.262-llm-provider-credit-alerting-prod`, ready `1/1`, restarts `0` | digest `sha256:668bcf...abe6` | OK |
| Client DEV | image Client DEV | `v3.5.259-ai-assist-notification-scope-dev`, ready `1/1`, restarts `0` | digest `sha256:019dea...04e` | OK |
| Client PROD | image Client PROD | `v3.5.259-ai-assist-notification-scope-prod`, ready `1/1`, restarts `0` | digest `sha256:e63494...f791` | OK |
| Website DEV | image Website DEV | `v0.7.0-redesign-light-dev`, ready `1/1`, restarts `0` | digest `sha256:71be73...ffff` | OK |
| Website PROD | image Website PROD | `v0.6.22-clarity-restore-prod`, ready `2/2`, restarts `0` | digest `sha256:974350...7ac` | OK |
| Admin PROD | image Admin PROD | `v2.12.2-media-buyer-lp-domain-qa-prod`, ready `1/1`, restarts `0` | digest `sha256:ecc208...037` | OK |
| Backend PROD | image Backend PROD | `v1.0.56-amazon-inbound-dedup-prod`, ready `1/1`, restarts `0` | digest `sha256:968987...dd2` | OK |
| amazon-orders-worker PROD | worker PROD | `v1.0.40-amz-tracking-visibility-backfill-prod`, ready `1/1` | restarts `10` preexistant | Dette SRE deja ouverte |
| backfill-scheduler PROD | scheduler PROD | `Pending`, ready absent | restarts `0` | Dette infra preexistante |

## 5. Source StartTrial / signup_complete

| Signal | Source code | Event interne | Event platform | Destination | Commentaire |
| --- | --- | --- | --- | --- | --- |
| Trial produit | `src/modules/billing/routes.ts` autour `checkout.session.completed` | `emitOutboundConversion('StartTrial', tenantId, ...)` | Canonical `StartTrial` | Outbound destinations actives | Non bloquant, catch/warn si erreur |
| Purchase produit | `src/modules/billing/routes.ts` transition `trialing -> active` | `emitOutboundConversion('Purchase', tenantId, ...)` | Canonical `Purchase` | Outbound destinations actives | Distinct de StartTrial |
| Emission interne | `src/modules/outbound-conversions/emitter.ts` | `conversion_events` avec `event_id=conv_<tenant>_<event>_<subscription>` | `StartTrial` / `Purchase` | delivery logs par destination | Idempotence via `event_id` et statut `sent` |
| Owner-aware routing | `src/modules/outbound-conversions/emitter.ts` | `marketing_owner_tenant_id` lu depuis `tenants` | Routage vers owner si present | destinations owner | Multi-tenant/owner aware |
| Meta CAPI | `src/modules/outbound-conversions/adapters/meta-capi.ts` | Canonical `StartTrial` | Meta `StartTrial` | `meta_capi` | Mapping direct standard Meta |
| TikTok CAPI | `src/modules/outbound-conversions/adapters/tiktok-events.ts` | Canonical `StartTrial` | TikTok `Subscribe` | `tiktok_events` | Mapping documente PH-T8.10M |
| LinkedIn CAPI | `src/modules/outbound-conversions/adapters/linkedin-capi.ts` | Canonical `StartTrial` | LinkedIn `StartTrial` | `linkedin_capi` | Mapping direct |
| Google/GA4 | `src/lib/tracking.ts` Client | `signup_complete` browser | GA4 key event, Google Ads import possible | GA4 / Google Ads | Chemin separe de CAPI, pas un event server-side `StartTrial` |
| Website engagement | `src/lib/tracking.ts` Website | engagement GA4 only | pas de business StartTrial browser | Website pixels | Docs indiquent business conversions reservees server-side |

Marqueurs runtime API confirmes dans `/app/dist` DEV et PROD:

| Env | StartTrial | Purchase | emitOutboundConversion | conversion_events | delivery logs | meta_capi | tiktok_events | linkedin_capi |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| DEV | 11 | 40 | 5 | 4 | 19 | 18 | 15 | 16 |
| PROD | 11 | 40 | 5 | 4 | 19 | 18 | 15 | 16 |

## 6. DB read-only trafic reel

Transactions DB executees avec `BEGIN TRANSACTION READ ONLY` puis `ROLLBACK`. Aucune valeur de payload, email, token ou Secret n'a ete affichee.

| Env | Table | Total |
| --- | --- | ---: |
| DEV | tenants | 32 |
| DEV | billing_events | 374 |
| DEV | conversion_events | 0 |
| DEV | outbound_conversion_delivery_logs | 7 |
| DEV | outbound_conversion_destinations | 9 |
| DEV | funnel_events | 113 |
| PROD | tenants | 20 |
| PROD | billing_events | 189 |
| PROD | conversion_events | 3 |
| PROD | outbound_conversion_delivery_logs | 19 |
| PROD | outbound_conversion_destinations | 14 |
| PROD | funnel_events | 243 |

| Fenetre PROD | Signups/trials reels | conversion_events StartTrial/signup_complete | deliveries | Verdict |
| --- | --- | --- | --- | --- |
| Baseline depuis 2026-04-28T22:00Z | tenants crees 10, billing events 47 | StartTrial 1 `sent`, Purchase 1 `sent`, signup_complete absent de `conversion_events` | StartTrial 3 delivered, Purchase 3 delivered | OK historique |
| 30 derniers jours | tenants crees 6, billing events 16 | StartTrial 0, Purchase 1 | Purchase 3 delivered, StartTrial 0 | TRAFFIC_REQUIRED pour StartTrial recent |
| 7 derniers jours | tenants crees 2, status observe `pending_payment`; billing: `customer.subscription.updated` 2, `invoice.paid` 2 | StartTrial 0, Purchase 0 | 0 | TRAFFIC_REQUIRED, pas de checkout/trial recent |
| 48 dernieres heures | tenants crees 1; funnel `tenant_created` 1 | StartTrial 0, Purchase 0 | 0 | TRAFFIC_REQUIRED |

Details PROD:

| Signal | Count | Premiere date | Derniere date | Statut |
| --- | ---: | --- | --- | --- |
| `conversion_events.StartTrial` | 1 | 2026-05-05T09:23:11Z | 2026-05-05T09:23:11Z | `sent` |
| `conversion_events.Purchase` | 1 | 2026-05-19T09:23:46Z | 2026-05-19T09:23:46Z | `sent` |
| `funnel_events.register_started` 7j | 28 | 2026-06-05T15:15:13Z | 2026-06-12T10:24:15Z | Micro-funnel, pas trial |
| `funnel_events.tenant_created` 7j | 2 | 2026-06-08T00:27:02Z | 2026-06-11T19:29:32Z | Creation tenant, pas billing trial |
| `billing_events.checkout.session.completed` 7j | 0 | n/a | n/a | Aucun vrai StartTrial attendu |
| `billing_events.customer.subscription.created` 7j | 0 | n/a | n/a | Aucun nouveau trial attendu |

DEV:

| Fenetre DEV | Signups/trials reels | conversion_events StartTrial/signup_complete | deliveries | Verdict |
| --- | --- | --- | --- | --- |
| Baseline | tenants crees 7, billing events 126 | 0 | 0 depuis baseline | DEV sans trafic CAPI exploitable |
| 30 derniers jours | tenants crees 4 | 0 | 0 | TRAFFIC_REQUIRED |
| 7 derniers jours | tenants crees 0 | 0 | 0 | TRAFFIC_REQUIRED |
| 48 dernieres heures | tenants crees 0 | 0 | 0 | TRAFFIC_REQUIRED |

## 7. Destinations actives et routing server-side

Token metadata uniquement: `encrypted`, `missing`, ou `legacy_non_empty`. Aucune valeur de token affichee.

| Tenant/owner | Destination | Platform | Active | Deleted | Token metadata | Derniere delivery | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| keybuzz-consulting-mo9zndlk | Meta CAPI | `meta_capi` | true | false | encrypted | 2026-05-19T09:23:47Z | OK |
| keybuzz-consulting-mo9zndlk | TikTok Events | `tiktok_events` | true | false | encrypted | 2026-05-19T09:23:47Z | OK |
| keybuzz-consulting-mo9zndlk | LinkedIn CAPI | `linkedin_capi` | true | false | encrypted | 2026-05-19T09:23:46Z | OK |
| keybuzz-consulting-mo9zndlk | Webhook | `webhook` | false | true | missing | aucune | Inactif attendu |
| ecomlg-001 | Meta/Webhook historiques | divers | false | true | encrypted/missing | historique uniquement | Soft-deleted |
| keybuzz-consulting-mo9y479d DEV | LinkedIn CAPI | `linkedin_capi` | true | false | encrypted | 2026-04-27T15:38:25Z | DEV sans delivery recente |

Routing owner-aware present en source et valide par la destination owner KBC active en PROD. Aucune destination active orpheline inattendue n'a ete observee dans les agregats lus.

## 8. Delivery logs

| Event | Platform | Count 30j | Count 7j | Dernier statut | Derniere erreur safe | Verdict |
| --- | --- | ---: | ---: | --- | --- | --- |
| StartTrial | Meta CAPI | 0 | 0 | Dernier historique HTTP 200 le 2026-05-05 | vide | OK historique, TRAFFIC_REQUIRED recent |
| StartTrial | TikTok Events | 0 | 0 | Dernier historique HTTP 200 le 2026-05-05 | vide | OK historique, TRAFFIC_REQUIRED recent |
| StartTrial | LinkedIn CAPI | 0 | 0 | Dernier historique HTTP 201 le 2026-05-05 | vide | OK historique, TRAFFIC_REQUIRED recent |
| Purchase | Meta CAPI | 1 | 0 | HTTP 200 le 2026-05-19 | vide | OK |
| Purchase | TikTok Events | 1 | 0 | HTTP 200 le 2026-05-19 | vide | OK |
| Purchase | LinkedIn CAPI | 1 | 0 | HTTP 201 le 2026-05-19 | vide | OK |
| signup_complete | GA4/Google | n/a dans delivery logs CAPI | n/a | n/a | n/a | Chemin browser/GA4 distinct |
| Webhook | webhook | 0 | 0 | inactif | n/a | Non attendu |

## 9. Logs runtime

Fenetre logs: 24h, `kubectl logs` read-only, samples masques.

| Service | Fenetre | Marker | Count | Exemple safe | Verdict |
| --- | --- | --- | ---: | --- | --- |
| API DEV | 24h | StartTrial / signup_complete / Purchase / OutboundConv / CAPI / decrypt / token / routing / destination | 0 chacun | Aucun sample tracking | Aucun echec tracking visible |
| API PROD | 24h | StartTrial / signup_complete / Purchase / OutboundConv / CAPI / decrypt / token / routing / destination | 0 chacun | Aucun sample tracking | Aucun echec tracking visible |
| Client DEV | 24h | tracking/conversion | 0 | aucun | OK |
| Client PROD | 24h | tracking/conversion | 0 | un `tenant-context/me` backend 500 hors tracking | Hors scope tracking |
| Website DEV | 24h | tracking/conversion | 0 | aucun | OK |
| Website PROD | 24h | tracking/conversion | 0 | une erreur Server Action ancienne/nouvelle deploy hors tracking | Hors scope tracking |

Les compteurs HTTP 4xx/5xx API observes dans les logs sont lies a d'autres routes/bruits applicatifs; aucun sample tracking/CAPI/decrypt/routing n'a ete trouve.

## 10. Browser/public bundle tracking

| Surface | Marker attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Client DEV | API DEV | `api-dev.keybuzz.io` 87, `api.keybuzz.io` 0 | OK |
| Client PROD | API PROD | `api.keybuzz.io` 87, `api-dev.keybuzz.io` 0 | OK |
| Client PROD | Clarity Client `wuk12h9i33` | 2 | OK |
| Client PROD | LinkedIn `9969977` | 2 + `snap.licdn` 5 | OK |
| Client PROD | sGTM `t.keybuzz.pro` | 2 | Present |
| Client PROD | GA4 `G-R3QQDYEBFG` | 0 | LIMIT / possible runtime drift vs docs PH-GA4/PH-T8.12R |
| Client PROD | Meta/TikTok browser IDs | 0 / 0 | Meta absent peut etre voulu dedup risk; TikTok absent vs docs a verifier |
| Client PROD | Google Ads direct `AW-` | 0 | OK, pas de tag AW direct |
| Client PROD | `signup_complete` code/bundle marker | 2 | Present mais GA4 ID runtime absent |
| Website PROD | GA4 `G-R3QQDYEBFG` | 18 | OK |
| Website PROD | Clarity Website `wrff07upjx` | 2 | OK |
| Website PROD | Meta/TikTok/LinkedIn/sGTM | Meta 2, TikTok 2, LinkedIn 18, sGTM 39 | OK |
| Website PROD | Google Ads direct `AW-` | 0 | OK |
| Website DEV | Preview redesign tracking | `t.keybuzz.pro` 24, API DEV 2, autres public IDs 0 | DEV preview distinct, pas bloquant StartTrial PROD |

## 11. Google/GA4 path

| Point | Preuve interne | Preuve externe requise | Verdict |
| --- | --- | --- | --- |
| Contrat Google | Docs PH-T8.11W/PH-T8.11X: `signup_complete` doit etre importe GA4 comme StartTrial Google Ads | Google Ads / GA4 dashboard pour statut key event/import | ACTION_REQUIRED_EXTERNAL_DASHBOARD |
| Pas de tag direct AW | Bundle Client/Website: `AW-` = 0 | Non | OK |
| Client source | `trackSignupComplete()` appelle `trackGA4('signup_complete', ...)` | Non | PRESENT_SOURCE |
| Client runtime actuel | `signup_complete` present, mais `G-R3QQDYEBFG` absent dans bundle v3.5.259 | GA4 Realtime pour confirmer absence/presence effective | ACTION_REQUIRED_CONFIG / drift possible |
| Website runtime | GA4 + sGTM presents sur website PROD | GA4 dashboard pour hits externes | OK interne |

Conclusion Google/GA4: ne pas conclure "Google Ads casse" sans dashboard externe. En revanche, la preuve interne montre un ecart concret entre les docs GA4 client et le Client runtime courant: `G-R3QQDYEBFG` absent du bundle Client PROD. Cette dette est separee du server-side CAPI StartTrial.

## 12. Clarity

| Surface | Clarity attendu | Observe | Verdict |
| --- | --- | --- | --- |
| Client PROD | `wuk12h9i33` | 2 occurrences + `clarity.ms` 2 | OK |
| Client DEV | `wuk12h9i33` | 2 occurrences + `clarity.ms` 2 | OK |
| Website PROD | `wrff07upjx` | 2 occurrences + `clarity.ms` 2 | OK |
| Website DEV | non confirme / preview redesign | 0 | LIMIT DEV, non bloquant PROD StartTrial |

## 13. Conclusion RCA par plateforme

| Plateforme | StartTrial attendu | Evidence interne | Evidence externe | Verdict | Prochaine action |
| --- | --- | --- | --- | --- | --- |
| Meta CAPI | `StartTrial` standard Meta | PROD historique 2026-05-05 HTTP 200 delivered; destination active encrypted; runtime markers OK | Dashboard Meta non consulte | TRAFFIC_REQUIRED pour preuve recente | Attendre vrai trial ou verifier dashboard |
| TikTok CAPI | `Subscribe` depuis canonical `StartTrial` | PROD historique 2026-05-05 HTTP 200 delivered; destination active encrypted; runtime markers OK | Dashboard TikTok non consulte | TRAFFIC_REQUIRED pour preuve recente | Attendre vrai trial ou verifier dashboard |
| LinkedIn CAPI | `StartTrial` | PROD historique 2026-05-05 HTTP 201 delivered; destination active encrypted; runtime markers OK | Dashboard LinkedIn non consulte | TRAFFIC_REQUIRED pour preuve recente | Attendre vrai trial ou verifier dashboard |
| Google/GA4 import | `signup_complete` lu/importe comme StartTrial | Source/bundle `signup_complete` present; Client runtime GA4 marker absent; Website GA4 OK; AW absent | GA4/Google Ads dashboard requis | ACTION_REQUIRED_CONFIG + EXTERNAL_DASHBOARD_REQUIRED | Phase dediee Client GA4 runtime parity |
| Webhook | Pas de webhook actif attendu | Webhook destinations inactives/soft-deleted | Non | OK inactive | Aucune |
| Clarity | UX analytics, pas StartTrial | Client PROD + Website PROD OK | Dashboard Clarity optionnel | OK interne | Aucune |
| Browser public tracking | Website full stack; Client funnel gate | Website PROD OK; Client PROD Clarity/LinkedIn/sGTM, GA4 absent | Browser/dashboard si besoin | PARTIAL | Ne pas lier a CAPI sans phase dediee |

## 14. No fake metrics / no fake events

| Signal | Classification | Justification |
| --- | --- | --- |
| PROD StartTrial 2026-05-05 | REAL_TRAFFIC/REAL_BILLING interne selon DB | `conversion_events` sent + 3 delivery logs provider |
| PROD Purchase 2026-05-19 | REAL_TRAFFIC/REAL_BILLING interne selon DB | `conversion_events` sent + 3 delivery logs provider |
| PROD funnel 7j | REAL_TRAFFIC funnel/micro-events | `register_started`, `email_submitted`, `tenant_created` presents |
| PROD StartTrial 7j/48h | TRAFFIC_REQUIRED | Aucun `checkout.session.completed` ni `customer.subscription.created` recent |
| DEV StartTrial | TRAFFIC_REQUIRED | 0 conversion_events depuis baseline |
| Google Ads conversion visible | EXTERNAL_DASHBOARD_REQUIRED | Dashboard non accessible, pas de faux KPI |
| Client GA4 runtime | ACTION_REQUIRED_CONFIG | Marker GA4 absent dans bundle actuel malgre docs d'activation |

Aucun KPI n'a ete invente. Les micro-events funnel ne sont pas des trials et ne sont pas convertis en `StartTrial`.

## 15. Non-regression / side-effect

| Interdit | Resultat |
| --- | --- |
| POST | Non execute |
| Event de test | Non cree |
| Fake signup / fake trial / fake checkout / fake purchase | Non execute |
| Endpoint test CAPI | Non appele |
| Secret/token affiche | Non |
| Secret.data K8s lu/decode | Non |
| DB mutation | Non |
| Transaction DB | `BEGIN TRANSACTION READ ONLY` puis `ROLLBACK` |
| Build / docker push | Non |
| Deploy / kubectl apply | Non |
| Linear mutation | Non |
| Runtime PROD mutation | Non |
| Source applicative mutation | Non |

Compteurs before/after dans la meme transaction read-only:

| Env | Table | Before | After | Delta |
| --- | --- | ---: | ---: | ---: |
| DEV | tenants | 32 | 32 | 0 |
| DEV | billing_events | 374 | 374 | 0 |
| DEV | conversion_events | 0 | 0 | 0 |
| DEV | outbound_conversion_delivery_logs | 7 | 7 | 0 |
| DEV | outbound_conversion_destinations | 9 | 9 | 0 |
| DEV | funnel_events | 113 | 113 | 0 |
| DEV | tracking_events | 32434 | 32434 | 0 |
| PROD | tenants | 20 | 20 | 0 |
| PROD | billing_events | 189 | 189 | 0 |
| PROD | conversion_events | 3 | 3 | 0 |
| PROD | outbound_conversion_delivery_logs | 19 | 19 | 0 |
| PROD | outbound_conversion_destinations | 14 | 14 | 0 |
| PROD | funnel_events | 243 | 243 | 0 |
| PROD | tracking_events | 32263 | 32263 | 0 |

## 16. Dettes

| Dette | Severite | Statut | Prochaine action |
| --- | --- | --- | --- |
| Preuve recente StartTrial CAPI | P1 | TRAFFIC_REQUIRED: aucun vrai checkout/trial recent | Attendre vrai trial ou validation dashboard sans fake event |
| Client GA4 runtime parity | P1 | `signup_complete` present mais `G-R3QQDYEBFG` absent du Client runtime courant | Phase dediee design/config/build client, sans faux event |
| Verification dashboards externes | P1 | Meta/TikTok/LinkedIn/GA4/Google Ads dashboards non consultes | `ACTION_REQUIRED_EXTERNAL_DASHBOARD` si Ludovic veut preuve plateforme |
| TikTok/Meta browser Client | P2 | Meta absent peut etre voulu dedup risk; TikTok absent vs docs a clarifier | Design dedup/browser parity |
| Source repos dirty preexistants | P2 process | API/client/backend dirty locaux sur bastion, non utilises pour build | Nettoyage/audit separe si build futur |
| Website source branch locale | P2 process | `redesign/light-business` observee au lieu de `main`; runtime PROD audite OK | Clarifier source-of-truth Website avant build |
| amazon-orders-worker restarts | P2 SRE | Restarts preexistants, hors tracking | Dette SRE worker-restart |
| backfill-scheduler Pending | P2 infra | Preexistant, hors tracking | Dette infra separee |

## 17. LINEAR_PREPARED_TEXT

Aucun changement Linear effectue.

Texte pret a poster si GO Ludovic:

```text
PH-21.55 RCA read-only StartTrial tracking:
- StartTrial CAPI server-side non prouve casse.
- PROD historique OK: StartTrial sent le 2026-05-05 et livre Meta 200 / TikTok 200 / LinkedIn 201.
- Aucun StartTrial recent sur 30j/7j/48h, mais aucun vrai checkout.session.completed ni customer.subscription.created recent; verdict traffic required pour preuve recente.
- Destinations PROD KBC Meta/TikTok/LinkedIn actives, tokens metadata encrypted uniquement.
- Google/GA4 est separe: signup_complete existe mais Client runtime courant ne contient pas G-R3QQDYEBFG; dette Client GA4 runtime parity.
- Aucun POST, fake event, DB mutation, build, deploy, kubectl apply ou secret affiche.
```

## 18. Prochain GO recommande

Prochain GO principal selon la mission et le verdict StartTrial server-side:

GO READONLY CLOSE SERVER SIDE TRACKING STARTTRIAL RCA PH-SAAS-T8.12AS.21.56

Dette separee a planifier si Ludovic veut traiter l'ecart Google/GA4 Client runtime:

GO READONLY DESIGN CLIENT GA4 SIGNUP_COMPLETE RUNTIME PARITY DEV PROD PH-SAAS-T8.12AS.21.56B

## 19. STOP

STOP
