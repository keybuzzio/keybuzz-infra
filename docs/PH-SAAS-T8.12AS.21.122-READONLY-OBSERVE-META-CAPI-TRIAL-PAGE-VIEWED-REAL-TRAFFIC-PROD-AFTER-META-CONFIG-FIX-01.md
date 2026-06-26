# PH-SAAS-T8.12AS.21.122 - Readonly observe Meta CAPI trial_page_viewed real traffic PROD after Meta config fix

Date UTC: 2026-06-26
Mode: READONLY OBSERVE PROD
Scope: Meta CAPI `trial_page_viewed` real traffic validation after Meta config fix.

## Resume executif

Verdict: `READY_DELIVERY_SUCCESS_AFTER_META_CONFIG_FIX`

Contexte ops Ludovic:

- nouveau token Meta CAPI saisi via Admin PROD;
- nouvelle destination Meta CAPI validee avec succes;
- ancienne destination Meta CAPI desactivee;
- lien `/register` ouvert le 2026-06-26 a 09:44 Europe/Paris, soit 2026-06-26T07:44:00Z;
- fenetre cible: 2026-06-26T07:34:00Z -> 2026-06-26T08:04:00Z.

Resultat observe:

- config Meta KBC confirmee en metadata-only: nouvelle destination active creee/maj apres PH-21.121, ancienne destination desactivee;
- `register_started` reel trouve a 2026-06-26T07:44:27.046Z;
- owner KBC OK, UTM OK, click id absent coherent test direct manuel;
- `trial_page_viewed` KeyBuzz/API trouve via `outbound_conversion_delivery_logs`;
- delivery Meta CAPI trouvee: status `delivered`, HTTP 200, attempt 1;
- error_message absent, classification N/A;
- aucune pollution StartTrial/Purchase/CompletePayment;
- aucun fake event CE;
- API PROD, Client PROD et autres services inchanges.

Preuve importante: CE n'a pas lu, affiche, decode ni exporte de token. Les controles de destination sont metadata-only.

## Scope et interdits respectes

| Interdit / controle | Resultat |
| --- | --- |
| POST `/funnel/event` | 0 |
| retry/replay delivery | 0 |
| CAPI test endpoint CE | 0 |
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
| PH-21.85 | relu |
| PH-21.91 | relu |
| PH-21.92 | relu |
| PH-21.97 | relu |
| PH-21.102 | relu |
| PH-21.103 | relu |
| PH-21.119 | relu |
| PH-21.121 | relu |
| PH-21.122 precedent | relu |

## Preflight bastion / repos

| Controle | Resultat |
| --- | --- |
| hostname | install-v3 |
| IP obligatoire | 46.62.171.61 presente |
| IP interdite | 51.159.99.247 absente |
| date UTC audit | 2026-06-26T08:03:40Z |

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 547648fd | 547648fd | 0/0 | 223 dist tracked preexistants, non-dist 0 | OK read-only |
| keybuzz-client | ph148/onboarding-activation-replay | d9631ca | d9631ca | 0/0 | 1 dette preexistante | OK read-only |
| keybuzz-infra | main | a7c4132 | a7c4132 | 0/0 | 0 avant rapport | OK docs-only |

## Runtime precheck API PROD / Client PROD

| Service | Image | Digest | Equality | Ready | Restarts | Markers | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| API PROD | v3.5.265-meta-capi-error-observability-prod | sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384 | manifest=last-applied=spec=pod OK | 1/1 | 0 | health OK | OK |
| Client PROD | v3.5.260-onboarding-register-started-owner-payload-prod | sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | last-applied=spec=pod OK | 1/1 | 0 | owner payload OK | OK |

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

## Meta config metadata-only precheck

| Champ | Valeur safe | Verdict |
| --- | --- | --- |
| destinations owner KBC | 3 | OK |
| active count | 1 | OK |
| inactive/deleted count | 2 | OK |
| active destination id safe | b9c038...4761 | OK |
| owner routing active | keybuzz-consulting-mo9zndlk | OK |
| type | meta_capi | OK |
| active/deleted | active true, deleted_at absent | OK |
| endpoint Graph | present | OK |
| pixel metadata | 123...748 | OK |
| pixel endpoint coherence | true | OK |
| token metadata | present, long/encrypted-or-long | OK |
| active destination created_at | 2026-06-26T07:43:17.587Z | changed after PH-21.121 |
| active destination updated_at | 2026-06-26T07:43:33.903Z | changed after PH-21.121 |
| active destination last_test_status | success | OK |
| old PH-21.119 destination id safe | 87f8dc...1192 | found disabled |
| old PH-21.119 destination active | false | OK |
| old PH-21.119 destination updated_at | 2026-06-26T07:43:41.354Z | desactivation after PH-21.121 |
| config_fix_confirmed | YES | OK |
| secret_exposure | 0 | OK |

Interpretation:

- la correction Meta config est prouvee en metadata-only;
- la nouvelle destination active KBC est differente de la destination PH-21.119;
- l'ancienne destination PH-21.119 est desactivee;
- le token n'a jamais ete lu ni affiche.

## Fenetre d'observation

| Champ | Valeur |
| --- | --- |
| Source de la fenetre | explicit_time |
| Centre observe UTC | 2026-06-26T07:44:00Z |
| Centre observe Paris | 2026-06-26T09:44:00+02:00 |
| Fenetre UTC | 2026-06-26T07:34:00Z -> 2026-06-26T08:04:00Z |
| Fenetre Europe/Paris | 2026-06-26T09:34:00+02:00 -> 2026-06-26T10:04:00+02:00 |

## DB read-only snapshots

Lecture via transaction `BEGIN TRANSACTION READ ONLY`, terminee par `ROLLBACK`.

| Controle | Total | Fenetre | Verdict |
| --- | ---: | ---: | --- |
| funnel_events | 325 | 1 | OK |
| register_started | 193 | 1 | FOUND |
| trial_page_viewed in funnel_events | 0 | 0 | informatif seulement |
| outbound_conversion_delivery_logs | 27 | 5 | OK |
| trial_page_viewed deliveries | 4 | 1 | FOUND |
| delivery success/delivered window | N/A | 2 | OK |
| delivery failed window | N/A | 3 | non cible, contexte admin/config |
| delivery pending window | N/A | 0 | OK |
| conversion_events | 3 | 0 | no business event |
| StartTrial | N/A | 0 | OK |
| Purchase | N/A | 0 | OK |
| CompletePayment | N/A | 0 | OK |
| ai_usage | 383 | 0 | no AI delta |
| ai_usage PROVIDER_CREDIT_EXHAUSTED | N/A | 0 | OK |
| ai_actions_ledger | 430 | 0 | no KBActions delta |

## register_started observe

| Champ | Resultat safe |
| --- | --- |
| register_started | FOUND |
| timestamp UTC | 2026-06-26T07:44:27.046Z |
| timestamp Paris | 2026-06-26T09:44:27.046+02:00 |
| id safe | 6376fe...bd84 |
| funnel_id safe | 2b70b5...1307 |
| attribution_id safe | 2b70b5...1307 |
| source | client |
| tenant_id | null |
| owner | OK |
| UTM | OK |
| click id | MISSING_DIRECT_MANUAL_OK |
| PII exposure | 0 |

## trial_page_viewed KeyBuzz/API

| Surface | Resultat |
| --- | --- |
| register_started candidat | FOUND |
| trial_page_viewed KeyBuzz/API | FOUND |
| source de preuve | outbound_conversion_delivery_logs |
| event id safe | tpv_67...7903 |
| timestamp UTC | 2026-06-26T07:44:27.303Z |

Note: `trial_page_viewed` reste absent de `funnel_events`, ce qui est attendu/informatif car la preuve vient de la delivery outbound.

## Meta CAPI delivery

| Champ | Resultat safe |
| --- | --- |
| delivery | FOUND |
| delivery id safe | 87fdf4...d45a |
| event id safe | tpv_67...7903 |
| destination id safe | b9c038...4761 |
| status | delivered |
| http_status | 200 |
| attempt | 1 |
| retryable | N/A |
| error_message present | false |
| error_message safe | N/A |
| classification safe | N/A |
| provider code safe | N/A |
| token exposure | 0 |
| provider raw body exposure | 0 |

Decision delivery: KeyBuzz Meta CAPI delivery is OK after Meta config fix.

Ads Manager / Events Manager: `NOT_AVAILABLE` pour CE; la preuve disponible ici est KeyBuzz DB/API + delivery Meta CAPI HTTP 200.

## Logs safe

| Controle | Count | Verdict |
| --- | ---: | --- |
| log lines fenetre | 1255 | info |
| crash/panic/fatal/uncaught/unhandled | 0 | OK |
| strong secret pattern | 0 | OK |
| raw provider body exposure | 0 | OK |
| register_started markers | 0 | coherent DB |
| trial_page_viewed markers | 1 | OK |
| Meta CAPI markers | 6 | OK |
| delivery success markers | 2 | OK |
| delivery failed markers | 3 | contexte config/admin, non cible `trial_page_viewed` delivery delivered |
| provider error normalized markers | 0 | OK |
| replay/retry markers | 0 | OK |

## No fake metrics / no fake events

| Controle | Resultat |
| --- | --- |
| POST `/funnel/event` CE | 0 |
| retry/replay CAPI | 0 |
| CAPI test endpoint CE | 0 |
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

## AI feature parity / anti-regression

| Surface | Resultat |
| --- | --- |
| PROVIDER_CREDIT_EXHAUSTED | pas de delta window |
| ai_usage | 0 window |
| ai_actions_ledger | 0 window |
| StartTrial/Purchase semantics | intactes, deltas 0/0 |
| Backend Amazon | runtime inchange |
| Client/Website/Admin | runtimes inchanges |

## Decision / verdict

Verdict principal: `READY_DELIVERY_SUCCESS_AFTER_META_CONFIG_FIX`

Justification:

- la nouvelle destination Meta CAPI KBC est active et validee en metadata-only;
- l'ancienne destination PH-21.119 est desactivee;
- un vrai `register_started` owner/UTM est observe dans la fenetre explicite;
- une delivery `trial_page_viewed` associee est observee;
- cette delivery est `delivered`, HTTP 200, attempt 1, sans error_message;
- aucune pollution business ni fake event CE.

## Prochain GO recommande

`GO READONLY CLOSE META CAPI TRIAL_PAGE_VIEWED REAL TRAFFIC PROD PH-SAAS-T8.12AS.21.123`

## Table finale

| Brique | Resultat | Preuve | Verdict |
| --- | --- | --- | --- |
| Runtime API PROD | OK | v3.5.265 + digest attendu | OK |
| Runtime Client PROD | OK | v3.5.260 + digest attendu + bundle owner payload | OK |
| Meta config metadata | nouvelle destination active + ancienne desactivee | DB read-only metadata | OK |
| Real traffic | FOUND | register_started 2026-06-26T07:44:27.046Z | OK |
| trial_page_viewed | FOUND | delivery log event `trial_page_viewed` | OK |
| Meta delivery | delivered HTTP 200 | delivery id 87fdf4...d45a | OK |
| Pollution | 0 | DB/logs | OK |
| Final | READY_DELIVERY_SUCCESS_AFTER_META_CONFIG_FIX | delivery success after fix | READY |
