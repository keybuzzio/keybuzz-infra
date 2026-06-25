# PH-SAAS-T8.12AS.21.122 - Readonly observe Meta CAPI trial_page_viewed real traffic PROD after Meta config fix

Date UTC: 2026-06-25
Mode: READONLY OBSERVE PROD
Scope: Meta CAPI `trial_page_viewed` real traffic validation after supposed Meta config fix.

## Resume executif

Verdict: `ACTION_REQUIRED_META_CONFIG_NOT_CONFIRMED`

La phase a observe les 60 dernieres minutes faute d'heure de test explicite fournie.

Resultat:

- API PROD et Client PROD sont sur les runtimes attendus;
- le bundle Client PROD porte bien `register_started`, `marketing_owner_tenant_id`, UTM/click IDs, API PROD presente et API DEV absente;
- la destination Meta CAPI KBC existe toujours, owner routing OK, pixel metadata OK, token ref metadata OK;
- la destination n'a pas de preuve metadata-only de changement apres PH-21.121: `updated_at=2026-04-23T15:13:03.677Z`, PH-21.121 report commit time `2026-06-25T20:16:58Z`;
- aucun `register_started` recent n'est visible dans la fenetre last-60m;
- aucune nouvelle delivery `trial_page_viewed` n'est visible dans la fenetre;
- aucun success/delivered post-PH-21.121 ne prouve indirectement une correction Meta;
- aucune pollution StartTrial/Purchase/CompletePayment, DB/LLM/KBActions ou fake event CE.

Conclusion: ne pas conclure que la correction Meta est faite ni que la livraison est reparee. Il faut confirmer/remplacer la config Meta KBC, puis faire un vrai passage `/register` avec l'URL complete et relancer PH-21.122 avec l'heure Paris.

## Scope et interdits respectes

| Interdit / controle | Resultat |
| --- | --- |
| POST `/funnel/event` | 0 |
| retry/replay delivery | 0 |
| CAPI test endpoint | 0 |
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

## Preflight bastion / repos

| Controle | Resultat |
| --- | --- |
| hostname | install-v3 |
| IP obligatoire | 46.62.171.61 presente |
| IP interdite | 51.159.99.247 absente |
| date UTC audit | 2026-06-25T20:43:07Z |

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 547648fd | 547648fd | 0/0 | 223 dist tracked preexistants, non-dist 0 | OK read-only |
| keybuzz-client | ph148/onboarding-activation-replay | d9631ca | d9631ca | 0/0 | 1 dette preexistante | OK read-only |
| keybuzz-infra | main | 6ecaa66 | 6ecaa66 | 0/0 | 0 avant rapport | OK docs-only |

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
| destination found | yes | OK |
| destination id safe | 87f8dc...1192 | OK |
| owner | keybuzz-consulting-mo9zndlk | OK |
| type | meta_capi | OK |
| active/deleted | active true, deleted_at absent | OK |
| endpoint Graph | present | OK |
| pixel metadata | 123...748 | OK |
| pixel endpoint coherence | true | OK |
| token metadata | present, long/encrypted-or-long | OK |
| created_at | 2026-04-23T15:12:33.728Z | info |
| updated_at | 2026-04-23T15:13:03.677Z | unchanged |
| PH-21.121 report commit time | 2026-06-25T20:16:58Z | reference |
| changed after PH-21.121 | false | no metadata proof |
| config_fix_confirmed | NO | action required |
| secret_exposure | 0 | OK |

Interpretation: aucune preuve metadata-only ne montre que la destination Meta KBC a ete modifiee apres PH-21.121. Aucun success/delivered post-PH-21.121 n'est visible pour prouver indirectement la correction.

## Fenetre d'observation

| Champ | Valeur |
| --- | --- |
| Source de la fenetre | last_60m |
| Centre observe Paris | N/A, aucune heure explicite fournie |
| Centre observe UTC | N/A, aucune heure explicite fournie |
| Fenetre UTC | 2026-06-25T19:43:07Z -> 2026-06-25T20:43:07Z |
| Fenetre Europe/Paris | 2026-06-25T21:43:07+02:00 -> 2026-06-25T22:43:07+02:00 |

## DB read-only snapshots

Lecture via transaction `BEGIN TRANSACTION READ ONLY`, terminee par `ROLLBACK`.

| Controle | Total | Fenetre | Verdict |
| --- | ---: | ---: | --- |
| funnel_events | 321 | 0 | no recent traffic |
| register_started | 191 | 0 | NOT_FOUND window |
| trial_page_viewed in funnel_events | 0 | 0 | expected/non-source |
| outbound_conversion_delivery_logs | 22 | 0 | no recent delivery |
| trial_page_viewed deliveries | 3 | 0 | no recent delivery |
| delivery failed | N/A | 0 | OK |
| delivery success/delivered | N/A | 0 | no proof |
| delivery pending | N/A | 0 | none |
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
| register_started | NOT_FOUND |
| timestamp UTC | N/A |
| timestamp Paris | N/A |
| id safe | N/A |
| funnel_id safe | N/A |
| attribution_id safe | N/A |
| tenant_id | N/A |
| owner | N/A |
| UTM | N/A |
| click id | N/A |
| PII exposure | 0 |

Decision: aucun vrai passage `/register` observable dans la fenetre last-60m. Le prompt impose de ne pas inventer de succes.

## trial_page_viewed KeyBuzz/API

| Surface | Resultat |
| --- | --- |
| register_started candidat | NOT_FOUND |
| trial_page_viewed KeyBuzz/API | NOT_FOUND |
| source de preuve | delivery_logs, window last-60m |
| event id safe | N/A |
| timestamp UTC | N/A |

## Meta CAPI delivery

| Champ | Resultat safe |
| --- | --- |
| delivery | NOT_FOUND |
| delivery id safe | N/A |
| event id safe | N/A |
| status | N/A |
| http_status | N/A |
| attempt | N/A |
| retryable | N/A |
| error_message present | N/A |
| error_message safe | N/A |
| classification safe | N/A |
| provider code safe | N/A |
| destination id safe | N/A |
| token exposure | 0 |
| provider raw body exposure | 0 |

Note: la derniere failure connue reste celle de PH-21.119. Aucune nouvelle delivery post-PH-21.121 n'a ete observee dans ce run.

## Logs safe

| Controle | Count | Verdict |
| --- | ---: | --- |
| log lines fenetre | 2369 | info |
| crash/panic/fatal/uncaught/unhandled | 0 | OK |
| strong secret pattern | 0 | OK |
| raw provider body exposure | 0 | OK |
| register_started markers | 0 | coherent DB |
| trial_page_viewed markers | 0 | coherent DB |
| Meta CAPI markers | 0 | coherent DB |
| delivery success markers | 0 | no proof |
| delivery failed markers | 0 | no new failure |
| provider error normalized markers | 0 | no new provider error |
| retry/replay markers | 0 | OK |

## No fake metrics / no fake events

| Controle | Resultat |
| --- | --- |
| POST `/funnel/event` CE | 0 |
| retry/replay CAPI | 0 |
| CAPI test endpoint | 0 |
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

## Decision / verdict

Verdict principal: `ACTION_REQUIRED_META_CONFIG_NOT_CONFIRMED`

Justification:

- la destination Meta CAPI KBC existe et reste coherent en metadata-only;
- aucune metadata ne montre une correction post-PH-21.121;
- aucun nouveau `register_started` n'est observe sur la fenetre last-60m;
- aucune nouvelle delivery `trial_page_viewed` success/delivered n'est observee;
- aucun failed nouveau ne permet de dire si l'erreur provider persiste;
- le prompt interdit d'inventer un succes sans trafic reel.

## Prochain GO recommande

Action requise:

`ACTION_REQUIRED_META_CONFIG_NOT_CONFIRMED - confirmer/remplacer token/pixel permissions dans Meta Business puis ouvrir l'URL complete /register et relancer PH-21.122 avec l'heure Paris du test.`

URL complete a ouvrir par Ludovic apres confirmation config:

`https://client.keybuzz.io/register?marketing_owner_tenant_id=keybuzz-consulting-mo9zndlk&utm_source=meta&utm_medium=paid_social&utm_campaign=ph21122_meta_config_fix_test&utm_content=ludovic_real_traffic&utm_term=onboarding_register`

## Table finale

| Brique | Resultat | Preuve | Verdict |
| --- | --- | --- | --- |
| Runtime API PROD | OK | v3.5.265 + digest attendu | OK |
| Runtime Client PROD | OK | v3.5.260 + digest attendu + bundle owner payload | OK |
| Meta config metadata | destination found, token/pixel metadata OK | DB read-only metadata | no fix proof |
| Real traffic | absent | register_started_window=0 | action required |
| trial_page_viewed | absent | delivery_window=0 | N/A |
| Meta delivery | absent | delivery_window=0 | N/A |
| Pollution | 0 | DB/logs | OK |
| Final | ACTION_REQUIRED_META_CONFIG_NOT_CONFIRMED | no config proof + no traffic | action required |
