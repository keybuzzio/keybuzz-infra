# PH-SAAS-T8.12AS.21.119 - Readonly observe Meta CAPI trial_page_viewed real traffic PROD

Date d'observation: 2026-06-25
Mode: READONLY OBSERVE REAL TRAFFIC PROD
Verdict: READY_FAILED_WITH_SAFE_ERROR

## Objectif

Observer en lecture seule le vrai passage annonce par Ludovic depuis la LP Antoine vers
`https://client.keybuzz.io/register`, avec lien complet owner/UTM, afin de verifier:

- presence d'un `register_started` reel;
- propagation owner / UTM / click IDs disponibles;
- creation server-side de `trial_page_viewed`;
- tentative de livraison Meta CAPI;
- si la livraison Meta CAPI echoue, presence d'un `error_message` provider safe, non
  vide et sans secret/PII dans `outbound_conversion_delivery_logs.error_message`.

CE n'a genere aucun trafic, aucun POST `/funnel/event`, aucun formulaire, aucun checkout
Stripe, aucun replay/retry CAPI et aucune mutation DB.

## Fenetre observee

| Champ | Valeur |
| --- | --- |
| Centre annonce Paris | 2026-06-25 17:17 Europe/Paris |
| Centre annonce UTC | 2026-06-25T15:17:00Z |
| Fenetre UTC | 2026-06-25T15:07:00Z -> 2026-06-25T15:37:00Z |
| Fenetre Europe/Paris | 2026-06-25T17:07:00+02:00 -> 2026-06-25T17:37:00+02:00 |
| Observation finale UTC | 2026-06-25T15:38:47Z |

## Sources relues

| Source | Resultat |
| --- | --- |
| AI_MEMORY/CURRENT_STATE.md | relu |
| AI_MEMORY/RULES_AND_RISKS.md | relu |
| AI_MEMORY/DOCUMENT_MAP.md | relu |
| AI_MEMORY/CE_PROMPTING_STANDARD.md | relu |
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
| Date UTC execution finale | 2026-06-25T15:38:47Z |

## Repos

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 547648fd | 547648fd | 0/0 | 223 dist-only, non-dist 0 | OK, dette preexistante non touchee |
| keybuzz-client | ph148/onboarding-activation-replay | d9631ca | d9631ca | 0/0 | 1 | OK, non modifie |
| keybuzz-infra | main | 6ecaf2c | 6ecaf2c | 0/0 | 0 avant rapport | OK |

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
| funnel_events | 319 | 2 |
| funnel_events register_started | 190 | 2 |
| funnel_events trial_page_viewed | 0 | 0 |
| outbound_conversion_delivery_logs | 22 | 1 |
| outbound trial_page_viewed deliveries | 3 | 1 |
| outbound failed deliveries | 7 | 1 |
| outbound error_message non null | 7 | N/A |
| outbound trial_page_viewed failed with error_message | N/A | 1 |
| conversion_events | 3 | 0 |
| StartTrial | 2 | 0 |
| Purchase | 1 | 0 |
| CompletePayment | 0 | 0 |
| ai_usage | 380 | 0 |
| ai_usage PROVIDER_CREDIT_EXHAUSTED | 0 | 0 |
| ai_actions_ledger | 427 | 0 |

## Observation register_started

Deux `register_started` ont ete trouves dans la fenetre. Le candidat cible owner/UTM est
celui de `2026-06-25T15:27:14.892Z`, car il porte l'owner et les UTM du lien complet.

| Controle | Attendu | Resultat |
| --- | --- | --- |
| event trouve | oui si trafic reel | FOUND |
| timestamp UTC candidat cible | documente | 2026-06-25T15:27:14.892Z |
| timestamp Paris candidat cible | documente | 2026-06-25T17:27:14.892+02:00 |
| source | client | client |
| id safe | tronque | 35eab2...83bf |
| funnel_id safe | tronque | 2da987...2c3a |
| attribution_id safe | tronque | 2da987...2c3a |
| tenant_id | pre-tenant attendu possible | null |
| marketing_owner_tenant_id | keybuzz-consulting-mo9zndlk | OK |
| UTM | presents si lien Antoine/Webflow correct | OK |
| click id | present si clic Meta reel, sinon direct manual OK | MISSING_DIRECT_MANUAL_OK |
| referrer/source URL | safe indicator uniquement | absents |
| PII exposee | 0 | 0 |

Note: un second `register_started` non owner/UTM existe a `2026-06-25T15:33:48.843Z`.
Il n'est pas retenu comme candidat cible du lien complet.

## Observation trial_page_viewed server-side

| Controle | Attendu | Resultat |
| --- | --- | --- |
| trial_page_viewed cree cote KeyBuzz/API | oui | FOUND via outbound delivery log |
| funnel_events trial_page_viewed fenetre | informatif | 0 |
| outbound delivery associee | oui si emission tentee | FOUND |
| duplicate excessif | non | 1 delivery dans la fenetre |
| delai depuis register_started cible | court/documente | environ 20.7 secondes |

Conclusion: `trial_page_viewed` n'est pas materialise comme ligne `funnel_events`, mais la
chaine API a bien emis un event outbound `trial_page_viewed` associe temporellement au
`register_started` owner/UTM.

## Observation Meta CAPI delivery

| Controle | Attendu | Resultat |
| --- | --- | --- |
| delivery associee | oui | FOUND |
| provider | Meta | Meta CAPI |
| delivery id safe | tronque | 26e674...d3e5 |
| destination id safe | tronque | 87f8dc...1192 |
| event id safe | tronque | tpv_97...6c13 |
| attempt | documente | 3 |
| status | success/failed/pending | failed |
| HTTP status | safe | 400 |
| error_message | non vide si failed | OK |
| error_message sanitized | oui si failed | OK |
| classification safe | documentee sans message brut | META_INVALID_PIXEL_OR_TOKEN |
| provider code | presence seulement | present |
| retryable | safe | false |
| created_at UTC | documente | 2026-06-25T15:27:35.565Z |
| secret/PII exposure | 0 | 0 |

Le message provider brut n'a pas ete affiche. Seuls les champs safe/agreges ont ete
documentes.

## Logs API PROD safe

Logs filtres sur 2026-06-25T15:07:00Z -> 2026-06-25T15:37:00Z, sans affichage de lignes
brutes.

| Controle | Resultat |
| --- | ---: |
| log lines fenetre | 1199 |
| crash/panic/fatal/uncaught/unhandled | 0 |
| strong secret pattern | 0 |
| raw provider body expose | 0 |
| register_started markers | 0 |
| trial_page_viewed markers | 4 |
| Meta CAPI markers | 4 |
| delivery success/failed markers | 0 |
| provider error normalized markers | 0 |
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

`READY_FAILED_WITH_SAFE_ERROR`.

Raison:

- un vrai `register_started` owner/UTM a ete capture dans la fenetre;
- le click id est absent, coherent avec un test direct manuel sans fbclid;
- `trial_page_viewed` a ete emis cote KeyBuzz/API via outbound delivery log;
- la delivery Meta CAPI a echoue naturellement avec HTTP 400;
- `outbound_conversion_delivery_logs.error_message` est present, non vide, safe, et
  classifie `META_INVALID_PIXEL_OR_TOKEN`;
- aucun secret, token, Authorization, cookie, email, phone, user_data ou payload provider
  brut n'a ete affiche.

## Prochaine action recommandee

AUCUN GO TECHNIQUE REQUIS.

La preuve live demandee par PH-21.119 est obtenue: l'observabilite d'erreur provider safe
est confirmee sur un vrai `trial_page_viewed` PROD. Un GO close/read-only peut etre lance
si Ludovic souhaite simplement cloturer administrativement la chaine.
