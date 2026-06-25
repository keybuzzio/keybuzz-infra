# PH-SAAS-T8.12AS.21.119 - READONLY OBSERVE META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY REAL TRAFFIC PROD

Date UTC: 2026-06-25
Mode: READONLY OBSERVE REAL TRAFFIC PROD
Verdict: ACTION_REQUIRED_REAL_TRAFFIC_WINDOW

## Objectif

Observer en lecture seule un vrai trafic PROD lie a l'arrivee sur:

`https://client.keybuzz.io/register`

La chaine a observer etait:

1. `register_started` reel cote Client/API;
2. propagation owner/UTM/click IDs disponibles;
3. creation server-side `trial_page_viewed`;
4. tentative de livraison Meta CAPI;
5. si failed, persistence d'un `error_message` provider safe, non vide et sans secret/PII.

Cette phase n'a cree aucun trafic, aucun event et aucune mutation.

## Sources relues

| Source | Resultat |
| --- | --- |
| AI_MEMORY CURRENT_STATE | relu |
| AI_MEMORY RULES_AND_RISKS | relu |
| AI_MEMORY DOCUMENT_MAP | relu |
| AI_MEMORY CE_PROMPTING_STANDARD | relu |
| PH-T8.10J modele canonique local | relu |
| Retours CE PH-21.103 / 21.104 / 21.105 / 21.106 / 21.107 / 21.112 / 21.113 / 21.114 / 21.115 / 21.116 / 21.117 / 21.118 | relus |
| Rapport PH-21.103 | relu |
| Rapport PH-21.104 | relu |
| Rapport PH-21.107 | relu |
| Rapport PH-21.118 | relu |

## Preflight bastion

| Controle | Resultat |
| --- | --- |
| Hostname | install-v3 |
| IP obligatoire | 46.62.171.61 presente |
| IP interdite 51.159.99.247 | absente |
| Date UTC preflight | 2026-06-25T11:28:51Z |

## Fenetre d'observation

Aucune heure de test explicite n'a ete fournie avec le GO. La fenetre par defaut de la
mission a donc ete utilisee.

| Fenetre | Start | End |
| --- | --- | --- |
| UTC | 2026-06-25T10:28:51Z | 2026-06-25T11:28:51Z |
| Europe/Paris | 2026-06-25T12:28:51+02:00 | 2026-06-25T13:28:51+02:00 |
| DB UTC precise | 2026-06-25T10:28:54.703Z | 2026-06-25T11:28:54.703Z |

## Repos

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 547648fd | 547648fd | 0/0 | 223, non-dist 0 | non touche |
| keybuzz-client | ph148/onboarding-activation-replay | d9631ca | d9631ca | 0/0 | 1 | non touche |
| keybuzz-infra | main | 483a4f0 | 483a4f0 | 0/0 | 0 | rapport docs-only autorise |

## Runtime precheck

| Service | Attendu | Resultat |
| --- | --- | --- |
| API PROD image | `v3.5.265-meta-capi-error-observability-prod` | OK |
| API PROD digest | `sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384` | OK |
| API PROD equality | manifest=last-applied=spec=pod | OK |
| API PROD ready/restarts | 1/1, 0 | 1/1, 0 |
| API PROD health | OK | status ok |
| Client PROD image | `v3.5.260-onboarding-register-started-owner-payload-prod` | OK |
| Client PROD digest | `sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115` | OK |
| latest API hash | `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` | intact |

API PROD pod:

`keybuzz-api-5d6945f8cd-26mdl`

Client PROD pod:

`keybuzz-client-748446795b-xqmr5`

## Snapshot DB read-only

Lecture effectuee via transaction `BEGIN TRANSACTION READ ONLY`. Aucun payload complet,
email, telephone, IP complete, user agent complet ou secret n'a ete affiche.

| Snapshot | Resultat |
| --- | --- |
| funnel_events total | 316 |
| funnel_events recent 60m | 0 |
| register_started total | 187 |
| register_started recent 60m | 0 |
| trial_page_viewed funnel recent 60m | 0 |
| delivery_logs total | 21 |
| delivery_logs recent 60m | 0 |
| trial_page_viewed delivery total | 2 |
| trial_page_viewed delivery recent 60m | 0 |
| failed total | 6 |
| failed recent 60m | 0 |
| error_message non null | 6 |
| trial_page_viewed failed error_message recent 60m | 0 |
| conversion_events total | 3 |
| StartTrial total / recent 60m | 2 / 0 |
| Purchase total / recent 60m | 1 / 0 |
| CompletePayment total / recent 60m | 0 / 0 |
| ai_usage total / recent 60m | 375 / 5 |
| ai_usage PROVIDER_CREDIT_EXHAUSTED total / recent 60m | 0 / 0 |

## register_started reel

| register_started reel | Attendu | Resultat |
| --- | --- | --- |
| event trouve | oui si trafic reel | NOT_FOUND |
| timestamp UTC/Paris | documente | N/A |
| marketing_owner_tenant_id | keybuzz-consulting-mo9zndlk si URL correcte | N/A |
| UTM | present si lien Antoine/Webflow correct | N/A |
| click id | present si clic Meta reel, sinon MISSING_DIRECT_MANUAL_OK | N/A |
| PII exposee | 0 | 0 |

Decision: aucun vrai passage `/register` n'a ete observe dans la fenetre. La phase ne
conclut donc pas que le tracking est casse.

## trial_page_viewed server-side

| trial_page_viewed server-side | Attendu | Resultat |
| --- | --- | --- |
| event cree | oui si register_started reel | N/A |
| delai depuis register_started | court / documente | N/A |
| owner routing | OK | N/A |
| duplicate excessif | non | N/A |
| delivery log associe | oui si emission tentee | N/A |

Raison: aucun `register_started` recent.

## Meta CAPI delivery

| Meta CAPI delivery | Attendu | Resultat |
| --- | --- | --- |
| delivery associee | oui si trial_page_viewed cree | N/A |
| provider | Meta | N/A |
| status | success/failed/pending | N/A |
| HTTP/status provider | safe | N/A |
| error_message | non vide si failed | N/A |
| error_message sanitized | oui si failed | N/A |
| secret/PII exposure | 0 | 0 |

Raison: aucun `register_started` recent, donc aucun `trial_page_viewed` recent et aucune
delivery Meta CAPI associee a observer.

## Logs API PROD

Fenetre logs: 65 minutes.

| Logs API PROD | Attendu | Resultat |
| --- | --- | --- |
| lignes | documente | 2986 |
| crash/panic/fatal | 0 | 0 |
| strong secret pattern | 0 | 0 |
| raw provider body expose | 0 | 0 |
| register_started markers | count safe | 0 |
| trial_page_viewed markers | count safe | 0 |
| Meta CAPI markers | count safe | 0 |
| delivery success/failed markers | count safe | 0 |
| provider error normalized | count safe | 1 |
| retry/replay/99541c23fe41 | 0 | 0 |

Le compteur provider error normalized n'est pas lie a un nouveau `register_started` ou
`trial_page_viewed` observe dans la DB sur la fenetre.

## Pollution check

| Pollution check | Attendu | Resultat |
| --- | --- | --- |
| POST /funnel/event CE | 0 | 0 |
| retry/replay | 0 | 0 |
| CAPI test | 0 | 0 |
| StartTrial delta CE | 0 | 0 |
| Purchase delta CE | 0 | 0 |
| CompletePayment delta CE | 0 | 0 |
| DB mutation volontaire | 0 | 0 |
| formulaire /register CE | 0 | 0 |
| checkout Stripe CE | 0 | 0 |

## AI feature parity / anti-regression

| Surface IA | Attendu | Resultat |
| --- | --- | --- |
| PROVIDER_CREDIT_EXHAUSTED | present runtime | present selon PH-21.118 |
| llm-provider-errors | present runtime | present selon PH-21.118 |
| dist/tests | absent | absent selon PH-21.118 |
| appel LLM CE | 0 | 0 |
| DB ai_usage/ledger mutation volontaire | 0 | 0 |
| ai_usage PROVIDER_CREDIT_EXHAUSTED | 0 | 0 |
| regression IA visible | 0 | 0 |

## Non-regression services

| Service | Image/digest | Etat |
| --- | --- | --- |
| API DEV | `v3.5.265-meta-capi-error-observability-dev` / `sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb` | ready 1/1, restarts 0 |
| Client PROD | `v3.5.260-onboarding-register-started-owner-payload-prod` / `sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115` | ready 1/1, restarts 0 |
| Client DEV | `v3.5.260-onboarding-register-started-owner-payload-dev` / `sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9` | ready 1/1, restarts 0 |
| Website PROD | `v0.7.2-visual-hero-parity-prod` / `sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4` | ready 2/2, restarts 0 |
| Website DEV | `v0.7.1-hero-copy-prod-body-parity-dev` / `sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b` | ready 1/1, restarts 0 |
| Admin PROD | `v2.12.2-media-buyer-lp-domain-qa-prod` / `sha256:ecc2080ff7fe5031eab812b1c32d330e4f7eea902d2a98e4d7bd7b409e0d5037` | ready 1/1, restarts 0 |
| Admin DEV | `v2.12.2-media-buyer-lp-domain-qa-dev` / `sha256:c747ee93d25a81e43f44e04d2c845b51a3eab0ede51f050df1375e6009abaa09` | ready 1/1, restarts 0 |
| Backend PROD | `v1.0.56-amazon-inbound-dedup-prod` / `sha256:9689875ca55677d80ef122a2bbd6209fd5071da2fac51f15cd182f8d7f1dcdd2` | ready 1/1, restarts 0 |
| Backend DEV | `v1.0.57-amazon-notification-classification-dev` / `sha256:ab583b9c57bb47bddb35be594ffb8938bf7bd57d6f79b6f8906c341083c5d806` | ready 1/1, restarts 0 |

## Verdict

`GO READONLY OBSERVE META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY REAL TRAFFIC PROD ACTION_REQUIRED_REAL_TRAFFIC_WINDOW PH-SAAS-T8.12AS.21.119`

Raison:

- aucun `register_started` reel n'a ete trouve dans la fenetre par defaut;
- aucun `trial_page_viewed` recent n'a donc pu etre observe;
- aucune delivery Meta CAPI recente associee n'a donc pu etre qualifiee;
- la runtime API/Client PROD est saine et inchangee;
- CE n'a genere aucun faux trafic.

## Prochaine action

Demander a Ludovic ou Antoine de declencher un vrai passage public via l'URL/landing Meta,
puis relancer ce GO avec l'heure Paris du test. La mission utilisera alors une fenetre
centree `T-10 minutes` a `T+20 minutes`.
