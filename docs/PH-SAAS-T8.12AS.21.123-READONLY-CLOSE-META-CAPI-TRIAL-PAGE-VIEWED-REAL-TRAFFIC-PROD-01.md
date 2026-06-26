# PH-SAAS-T8.12AS.21.123 - Readonly close Meta CAPI trial_page_viewed real traffic PROD

Date UTC: 2026-06-26
Mode: READONLY CLOSE PROD
Scope: cloture de la chaine server-side Meta CAPI `trial_page_viewed` sur `/register`.

## Resume executif

Verdict: `READY_CLOSED`

La chaine `trial_page_viewed` Meta CAPI demandee par Antoine est cloturee cote KeyBuzz:

- PH-21.119: vrai trafic `/register`, `trial_page_viewed` trouve, delivery Meta failed HTTP 400 `META_INVALID_PIXEL_OR_TOKEN`;
- PH-21.121: RCA, cause probable `META_TOKEN_OR_PIXEL_REJECTED_BY_PROVIDER`, pas de bug source prouve;
- PH-21.122: nouveau token/destination Meta CAPI via Admin PROD, ancienne destination desactivee, vrai trafic `/register`, delivery `trial_page_viewed` delivered HTTP 200.

PH-21.123 confirme en lecture seule:

- API PROD stable sur `v3.5.265-meta-capi-error-observability-prod`;
- Client PROD stable sur `v3.5.260-onboarding-register-started-owner-payload-prod`;
- une seule destination Meta CAPI KBC active;
- ancienne destination `87f8dc...1192` inactive;
- nouvelle destination `b9c038...4761` active, last_test_status `success`;
- `register_started` PH-21.122 trouve avec owner OK et UTM OK;
- `trial_page_viewed` trouve via delivery logs;
- delivery Meta CAPI `87fdf4...d45a` delivered HTTP 200 attempt 1;
- StartTrial/Purchase/CompletePayment deltas `0/0/0`;
- aucun fake event CE;
- aucun token, secret, provider raw body ou PII expose.

Limite explicite: Ads Manager / Events Manager sont `NOT_AVAILABLE` pour CE. La preuve CE est KeyBuzz DB/API + delivery Meta CAPI HTTP 200.

## Scope et interdits respectes

| Interdit / controle | Resultat |
| --- | --- |
| POST `/funnel/event` | 0 |
| retry/replay delivery | 0 |
| CAPI test endpoint CE | 0 |
| ouverture `/register` CE | 0 |
| formulaire `/register` CE | 0 |
| checkout Stripe | 0 |
| build / docker push | 0 |
| deploy / kubectl apply / restart / rollback | 0 |
| mutation DB | 0 |
| Secret.data lu/decode | 0 |
| token brut affiche | 0 |
| provider raw body affiche | 0 |
| Webflow / Linear mutation | 0 |

## Sources relues

| Source | Resultat |
| --- | --- |
| AI_MEMORY/CURRENT_STATE.md | relu |
| AI_MEMORY/RULES_AND_RISKS.md | relu |
| AI_MEMORY/DOCUMENT_MAP.md | relu |
| AI_MEMORY/CE_PROMPTING_STANDARD.md | relu |
| PH-21.78 | relu |
| PH-21.79 | relu |
| PH-21.84 | relu |
| PH-21.97 | relu |
| PH-21.102 | relu |
| PH-21.119 | relu |
| PH-21.121 | relu |
| PH-21.122 | relu |
| PH-21.119/121/122 retours locaux | relus via contexte local disponible |

## Preflight bastion / repos

| Controle | Resultat |
| --- | --- |
| hostname | install-v3 |
| IP obligatoire | 46.62.171.61 presente |
| IP interdite | 51.159.99.247 absente |
| date UTC audit | 2026-06-26T08:16:56Z |

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 547648fd | 547648fd | 0/0 | 223 dist tracked preexistants, non-dist 0 | OK read-only |
| keybuzz-client | ph148/onboarding-activation-replay | d9631ca | d9631ca | 0/0 | 1 dette preexistante | OK read-only |
| keybuzz-infra | main | 44bdf68 | 44bdf68 | 0/0 | 0 avant rapport | OK docs-only |

## Runtime precheck API PROD / Client PROD

| Service | Image | Digest | Equality | Ready | Restarts | Markers | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| API PROD | v3.5.265-meta-capi-error-observability-prod | sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384 | manifest=last-applied=spec=pod OK | 1/1 | 0 | runtime markers OK | OK |
| Client PROD | v3.5.260-onboarding-register-started-owner-payload-prod | sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | last-applied=spec=pod OK | 1/1 | 0 | owner payload OK | OK |

API PROD markers in-pod:

| Marker | Count |
| --- | ---: |
| PROVIDER_CREDIT_EXHAUSTED | 5 |
| trial_page_viewed | 3 |
| StartTrial | 5 |
| Purchase | 8 |
| error_message | 3 |
| Meta CAPI | 5 |

Client PROD bundle markers:

| Marker | Resultat |
| --- | ---: |
| register_started | 1 |
| marketing_owner_tenant_id | 2 |
| UTM | 1 |
| click IDs | 1 |
| https://api.keybuzz.io | 2 |
| https://api-dev.keybuzz.io | 0 |

API `latest` manifest hash: unchanged, expected hash OK.

## Meta destination cutover metadata-only

| Champ | Valeur safe | Verdict |
| --- | --- | --- |
| total Meta CAPI KBC | 3 | info |
| active count | 1 | OK |
| inactive/deleted count | 2 | OK |
| active destination safe | b9c038...4761 | OK |
| active destination created_at | 2026-06-26T07:43:17.587Z | OK |
| active destination updated_at | 2026-06-26T07:43:33.903Z | OK |
| active destination last_test_status | success | OK |
| active destination pixel metadata | 123...748 | OK masked |
| active destination token metadata | present_long | OK metadata-only |
| old destination safe | 87f8dc...1192 | found |
| old destination active | false | OK |
| old destination updated_at | 2026-06-26T07:43:41.354Z | OK |
| old destination last_test_status | failed | historical/config transition |
| third old destination | f768d0...923f inactive/deleted | OK |
| secret exposure | 0 | OK |

Decision destination: cutover conforme. Une seule destination Meta CAPI KBC active.

## Consolidation PH-21.119 failure

| Surface | Resultat |
| --- | --- |
| Fenetre | 2026-06-25T15:07:00Z -> 2026-06-25T15:37:00Z |
| register_started | FOUND |
| owner | OK |
| UTM | OK |
| click id | MISSING_DIRECT_MANUAL_OK |
| trial_page_viewed | FOUND |
| delivery id safe | 26e674...d3e5 |
| event id safe | tpv_97...6c13 |
| status | failed |
| http_status | 400 |
| classification | META_INVALID_PIXEL_OR_TOKEN |
| provider code safe | 190 |
| StartTrial/Purchase/CompletePayment deltas | 0/0/0 |

## Consolidation PH-21.121 RCA

| Point RCA | Resultat |
| --- | --- |
| destination ancienne | FOUND 87f8dc...1192 |
| owner routing | OK |
| pixel metadata | OK masked 123...748 |
| token metadata | OK metadata-only |
| source mapping trial_page_viewed | OK |
| source patch requis | non prouve |
| cause probable | META_TOKEN_OR_PIXEL_REJECTED_BY_PROVIDER |
| confiance | HIGH |
| action | correction Meta config / token-pixel permissions |

## Consolidation PH-21.122 success

| Surface | Resultat |
| --- | --- |
| Fenetre UTC | 2026-06-26T07:34:00Z -> 2026-06-26T08:04:00Z |
| Fenetre Paris | 2026-06-26T09:34:00+02:00 -> 2026-06-26T10:04:00+02:00 |
| Passage annonce | 2026-06-26 09:44 Europe/Paris |
| register_started | FOUND |
| register_started id safe | 6376fe...bd84 |
| funnel_id safe | 2b70b5...1307 |
| attribution_id safe | 2b70b5...1307 |
| source | client |
| tenant_id | null |
| owner | OK |
| UTM | OK |
| click id | MISSING_DIRECT_MANUAL_OK |
| register_started created_at | 2026-06-26T07:44:27.046Z |
| trial_page_viewed KeyBuzz/API | FOUND |
| delivery id safe | 87fdf4...d45a |
| event id safe | tpv_67...7903 |
| destination safe | b9c038...4761 |
| status | delivered |
| http_status | 200 |
| attempt | 1 |
| delivery created_at | 2026-06-26T07:44:27.303Z |
| error_message safe | N/A |
| classification | N/A |

## DB read-only snapshots

Lecture via transaction `BEGIN TRANSACTION READ ONLY`, terminee par `ROLLBACK`.

| Controle | Total | Fenetre | Verdict |
| --- | ---: | ---: | --- |
| funnel_events | 325 | 1 | OK |
| register_started | N/A | 1 | FOUND |
| trial_page_viewed in funnel_events | N/A | 0 | informatif seulement |
| outbound_conversion_delivery_logs | 27 | 5 | OK |
| trial_page_viewed deliveries | N/A | 1 | FOUND |
| delivery success/delivered | N/A | 2 | OK |
| delivery failed | N/A | 3 | contexte config/admin, non cible final |
| delivery pending | N/A | 0 | OK |
| conversion_events | 3 | 0 | no business event |
| StartTrial | N/A | 0 | OK |
| Purchase | N/A | 0 | OK |
| CompletePayment | N/A | 0 | OK |
| ai_usage | 384 | 0 | no AI delta window |
| ai_usage PROVIDER_CREDIT_EXHAUSTED | N/A | 0 | OK |
| ai_actions_ledger | 431 | 0 | no KBActions delta window |

## Logs safe

| Controle | Count | Verdict |
| --- | ---: | --- |
| log lines fenetre | 1260 | info |
| crash/panic/fatal/uncaught/unhandled | 0 | OK |
| strong secret pattern | 0 | OK |
| raw provider body exposure | 0 | OK |
| trial_page_viewed markers | 1 | OK |
| Meta CAPI markers | 6 | OK |
| delivery success markers | 2 | OK |
| delivery failed markers | 3 | contexte config/admin, non cible final |
| provider error normalized markers | 0 | OK |
| replay/retry markers | 0 | OK |

## No fake metrics / no fake events

| Controle | Resultat |
| --- | --- |
| POST `/funnel/event` CE | 0 |
| retry/replay CAPI | 0 |
| CAPI test endpoint CE | 0 |
| ouverture `/register` CE | 0 |
| formulaire `/register` CE | 0 |
| checkout Stripe CE | 0 |
| StartTrial/Purchase/CompletePayment deltas | 0/0/0 |
| DB mutation volontaire | 0 |

## Non-regression services

| Service | Resultat |
| --- | --- |
| API PROD | v3.5.265 prod, digest attendu, ready 1/1, restarts 0 |
| API DEV | v3.5.265 dev, digest attendu, ready 1/1, restarts 0 |
| Client PROD | v3.5.260 prod, digest attendu, ready 1/1, restarts 0 |
| Client DEV | v3.5.260 dev, digest attendu, ready 1/1, restarts 0 |
| Website PROD | v0.7.2 visual hero parity, ready 2/2, unchanged |
| Website DEV | v0.7.1 hero copy prod body parity, ready 1/1, unchanged |
| Admin PROD/DEV | runtimes observes, ready 1/1, unchanged |
| Backend PROD/DEV | runtimes observes, ready 1/1, unchanged |
| latest tags | unchanged |

## Limites restantes

| Limite | Statut |
| --- | --- |
| Ads Manager attribution | NOT_AVAILABLE pour CE |
| Meta Events Manager visuel | NOT_AVAILABLE pour CE |
| fbclid | absent, normal pour test manuel direct |
| Webflow / try.keybuzz.io | doit maintenir query params owner/UTM/click IDs vers client.keybuzz.io/register |
| StartTrial | hors scope, non prouve par cette phase |

## Message reutilisable pour Antoine

`trial_page_viewed` server-side est maintenant en place et livre par Meta CAPI sur vrai trafic `/register`. C'est un event d'arrivee onboarding, distinct de `StartTrial`, qui reste reserve aux vrais trials/subscriptions Stripe.

Pour que l'attribution campagne remonte cote Meta/Ads Manager, les liens et LP doivent continuer a transmettre vers `https://client.keybuzz.io/register`:

- `marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk`;
- UTM Meta;
- le click ID Meta (`fbclid`) quand le trafic vient d'une vraie publicite Meta.

Un test manuel direct peut prouver la livraison CAPI KeyBuzz, mais ne prouve pas l'attribution Ads Manager. Ads Manager / Events Manager sont a verifier cote Meta avec du trafic pub reel.

Message non envoye par CE.

## Decision / verdict

Verdict principal: `READY_CLOSED`

Justification:

- PH-21.122 delivery delivered HTTP 200 consolidee;
- une seule destination Meta CAPI KBC active;
- ancienne destination PH-21.119 inactive;
- runtime API/Client PROD stable;
- no fake events CE;
- StartTrial/Purchase/CompletePayment non pollues;
- token/provider raw body/PII exposure = 0.

## Prochain GO recommande

`AUCUN GO TECHNIQUE REQUIS - demander a Antoine de verifier Events Manager / Ads Manager avec trafic pub reel`

## Table finale

| Brique | Resultat | Preuve | Verdict |
| --- | --- | --- | --- |
| Runtime API PROD | OK | v3.5.265 + digest attendu | OK |
| Runtime Client PROD | OK | v3.5.260 + owner payload | OK |
| Destination Meta KBC | active_count=1 | active b9c038...4761, old 87f8dc...1192 inactive | OK |
| PH-21.119 failure | consolidee | failed HTTP 400 invalid pixel/token | RCA closed |
| PH-21.121 RCA | consolidee | Meta config cause probable | closed |
| PH-21.122 success | delivered | 87fdf4...d45a HTTP 200 | OK |
| Pollution | 0 | StartTrial/Purchase/CompletePayment 0/0/0 | OK |
| Limites | Ads Manager NOT_AVAILABLE | hors CE | documented |
| Final | READY_CLOSED | all KeyBuzz technical proof closed | READY |
