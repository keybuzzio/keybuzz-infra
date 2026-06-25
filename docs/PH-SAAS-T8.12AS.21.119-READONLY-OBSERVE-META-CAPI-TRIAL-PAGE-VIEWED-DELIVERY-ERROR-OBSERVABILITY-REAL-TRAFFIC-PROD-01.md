# PH-SAAS-T8.12AS.21.119 - Readonly observe Meta CAPI trial_page_viewed real traffic PROD

Date d'observation: 2026-06-25
Mode: READONLY OBSERVE REAL TRAFFIC PROD
Verdict: NO_GO_TRIAL_PAGE_VIEWED_MISSING

## Objectif

Observer en lecture seule le vrai passage annonce par Ludovic depuis la LP Antoine vers
`https://client.keybuzz.io/register`, afin de verifier:

- presence d'un `register_started` reel;
- propagation owner / UTM / click IDs disponibles;
- creation server-side de `trial_page_viewed`;
- tentative de livraison Meta CAPI;
- si echec provider, presence d'un `error_message` safe non vide.

CE n'a genere aucun trafic, aucun POST `/funnel/event`, aucun formulaire, aucun checkout
Stripe, aucun replay/retry CAPI et aucune mutation DB.

## Fenetre observee

| Champ | Valeur |
| --- | --- |
| Centre annonce Paris | 2026-06-25 16:59 Europe/Paris |
| Centre annonce UTC | 2026-06-25T14:59:00Z |
| Fenetre UTC | 2026-06-25T14:49:00Z -> 2026-06-25T15:19:00Z |
| Fenetre Europe/Paris | 2026-06-25T16:49:00+02:00 -> 2026-06-25T17:19:00+02:00 |

## Sources relues

| Source | Resultat |
| --- | --- |
| AI_MEMORY/CURRENT_STATE.md | relu / hash distant documente |
| AI_MEMORY/RULES_AND_RISKS.md | relu / hash distant documente |
| AI_MEMORY/DOCUMENT_MAP.md | relu / hash distant documente |
| AI_MEMORY/CE_PROMPTING_STANDARD.md | relu / hash distant documente |
| PH-21.103 | relu |
| PH-21.104 | relu |
| PH-21.105 | relu |
| PH-21.106 | relu |
| PH-21.107 | relu |
| PH-21.112 | relu |
| PH-21.113 | relu |
| PH-21.114 | relu |
| PH-21.115 | relu |
| PH-21.116 | relu |
| PH-21.117 | relu |
| PH-21.118 | relu |

## Preflight bastion

| Controle | Resultat |
| --- | --- |
| Hostname | install-v3 |
| IP obligatoire | 46.62.171.61 presente |
| IP interdite | 51.159.99.247 absente |
| Date UTC executee | 2026-06-25T15:09:30Z |

## Repos

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 547648fd | 547648fd | 0/0 | 223 dist-only, non-dist 0 | OK, dette preexistante non touchee |
| keybuzz-client | ph148/onboarding-activation-replay | d9631ca | d9631ca | 0/0 | 1 | OK, non modifie |
| keybuzz-infra | main | 455617e | 455617e | 0/0 | 0 avant rapport | OK |

## Runtime precheck

| Service | Attendu | Resultat |
| --- | --- | --- |
| API PROD image | v3.5.265-meta-capi-error-observability-prod | OK |
| API PROD digest | sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384 | OK |
| API PROD equality | manifest=last-applied=spec=pod | OK |
| API PROD ready/restarts | 1/1, 0 | OK |
| API PROD health | /health status ok | OK |
| Client PROD image | v3.5.260-onboarding-register-started-owner-payload-prod | OK |
| Client PROD digest | sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115 | OK |
| Client PROD ready/restarts | 1/1, 0 | OK |
| API latest manifest hash | 71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549 | OK, inchange |

## DB read-only snapshot

Lecture via transaction `BEGIN TRANSACTION READ ONLY`, terminee par `ROLLBACK`.

| Table / controle | Total | Fenetre |
| --- | ---: | ---: |
| funnel_events | 317 | 1 |
| funnel_events register_started | 188 | 1 |
| funnel_events trial_page_viewed | 0 | 0 |
| outbound_conversion_delivery_logs | 21 | 0 |
| outbound trial_page_viewed deliveries | 2 | 0 |
| outbound failed deliveries | 6 | 0 |
| outbound error_message non null | 6 | N/A |
| conversion_events | 3 | 0 |
| StartTrial | 2 | 0 |
| Purchase | 1 | 0 |
| CompletePayment | 0 | 0 |
| ai_usage | 380 | 2 |
| ai_usage PROVIDER_CREDIT_EXHAUSTED | 0 | 0 |
| ai_actions_ledger | 427 | 2 |

## Observation register_started

Un vrai `register_started` a ete trouve dans la fenetre.

| Controle | Attendu | Resultat |
| --- | --- | --- |
| event trouve | oui si trafic reel | FOUND |
| timestamp UTC | documente | 2026-06-25T14:59:44.406Z |
| timestamp Paris | documente | 2026-06-25T16:59:44.406+02:00 |
| source | client | client |
| id safe | tronque | 4bf011...9c3e |
| funnel_id safe | tronque | 5940c5...341b |
| attribution_id safe | tronque | 5940c5...341b |
| tenant_id | pre-tenant attendu possible | null |
| marketing_owner_tenant_id | keybuzz-consulting-mo9zndlk | KO, absent |
| UTM | presents si lien Antoine/Webflow correct | KO, absents |
| click id | present si clic Meta reel | absent |
| referrer/source URL | safe indicator uniquement | absents |
| PII exposee | 0 | 0 |

Conclusion: le passage reel `/register` existe, mais le contrat d'attribution URL n'est
pas conserve sur l'event capture: owner absent, UTM absents, click IDs absents.

## Observation trial_page_viewed server-side

| Controle | Attendu | Resultat |
| --- | --- | --- |
| trial_page_viewed cree | oui apres register_started eligible | NOT_FOUND |
| funnel_events trial_page_viewed fenetre | > 0 attendu si cree | 0 |
| outbound delivery associee | oui si emission tentee | NOT_FOUND |
| duplicate excessif | non | 0 |

Conclusion: rupture observee apres `register_started`. Aucun `trial_page_viewed`
server-side ni delivery associee n'a ete cree dans la fenetre.

## Observation Meta CAPI delivery

| Controle | Attendu | Resultat |
| --- | --- | --- |
| delivery associee | oui si trial_page_viewed emis | NOT_FOUND |
| provider | Meta | N/A |
| status | success/failed/pending | N/A |
| HTTP/status provider | safe | N/A |
| error_message | non vide si failed | N/A |
| error_message sanitized | oui si failed | N/A |
| secret/PII exposure | 0 | 0 |

Conclusion: Meta CAPI n'a pas ete atteint pour ce passage, car `trial_page_viewed` est
absent.

## Logs API PROD safe

Logs filtres sur 2026-06-25T14:49:00Z -> 2026-06-25T15:19:00Z, sans affichage de lignes
brutes.

| Controle | Resultat |
| --- | ---: |
| log lines fenetre | 790 |
| crash/panic/fatal/uncaught/unhandled | 0 |
| strong secret pattern | 0 |
| raw provider body expose | 0 |
| register_started markers | 0 |
| trial_page_viewed markers | 0 |
| Meta CAPI markers | 0 |
| delivery success/failed markers | 0 |
| provider error normalized markers | 1 |
| replay/retry/99541c23fe41 markers | 0 |

## Pollution check / no fake metrics

| Controle | Attendu | Resultat |
| --- | --- | --- |
| POST /funnel/event CE | 0 | 0 |
| retry/replay CAPI | 0 | 0 |
| CAPI test endpoint | 0 | 0 |
| formulaire /register CE | 0 | 0 |
| checkout Stripe CE | 0 | 0 |
| StartTrial delta fenetre | 0 | 0 |
| Purchase delta fenetre | 0 | 0 |
| CompletePayment delta fenetre | 0 | 0 |
| DB mutation volontaire | 0 | 0 |

## AI feature parity / anti-regression

| Surface IA | Attendu | Resultat |
| --- | --- | --- |
| PROVIDER_CREDIT_EXHAUSTED | present runtime / pas d'erreur | present, DB count 0 |
| llm-provider-errors | inchange | inchange selon runtime PH-21.118 |
| appel LLM CE | 0 | 0 |
| DB ai_usage mutation volontaire | 0 | 0 |
| KBActions/ledger mutation volontaire | 0 | 0 |
| regression IA visible | 0 | 0 |

Note: `ai_usage` et `ai_actions_ledger` ont chacun 2 lignes naturelles dans la fenetre
observee; CE n'a declenche aucun appel LLM.

## Non-regression services

| Service | Resultat |
| --- | --- |
| API PROD | v3.5.265 prod, digest attendu, ready 1/1, restarts 0 |
| API DEV | v3.5.265 dev, digest sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb, ready 1/1, restarts 0 |
| Client PROD | v3.5.260 owner payload prod, digest attendu, ready 1/1, restarts 0 |
| Client DEV | v3.5.260 owner payload dev, digest sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9, ready 1/1, restarts 0 |
| Website PROD | v0.7.2 visual hero parity prod, ready 2/2, restarts 0 |
| Website DEV | v0.7.1 hero copy prod body parity dev, ready 1/1, restarts 0 |
| Admin PROD | v2.12.2 media buyer LP domain QA prod, ready 1/1, restarts 0 |
| Admin DEV | v2.12.2 media buyer LP domain QA dev, ready 1/1, restarts 0 |
| Backend PROD | v1.0.56 amazon inbound dedup prod, ready 1/1, restarts 0 |
| Backend DEV | v1.0.57 amazon notification classification dev, ready 1/1, restarts 0 |

## Verdict

`NO_GO_TRIAL_PAGE_VIEWED_MISSING`.

Raison:

- le vrai `register_started` annonce par Ludovic est bien capture a
  `2026-06-25T14:59:44.406Z`;
- l'event ne porte pas `marketing_owner_tenant_id`, pas d'UTM, pas de click ID et pas de
  source URL/referrer safe;
- aucun `trial_page_viewed` server-side n'est cree;
- aucune delivery Meta CAPI n'est tentee.

La rupture est donc avant la livraison Meta CAPI. Cette phase ne conclut pas sur une
erreur provider Meta: le provider n'a pas ete atteint sur ce passage.

## Prochaine action recommandee

GO READONLY RCA ONBOARDING TRIAL_PAGE_VIEWED MISSING AFTER REGISTER_STARTED PROD PH-SAAS-T8.12AS.21.120

Objectif du RCA suivant:

- verifier pourquoi le `register_started` reel a perdu owner/UTM/click IDs;
- comparer le contrat URL LP Antoine/Webflow -> Client `/register` -> API `/funnel/event`;
- verifier si l'emission `trial_page_viewed` est conditionnee a owner/destination ou si
  elle aurait du se produire malgre l'attribution absente;
- rester en lecture seule, sans POST `/funnel/event`, sans formulaire et sans replay CAPI.
