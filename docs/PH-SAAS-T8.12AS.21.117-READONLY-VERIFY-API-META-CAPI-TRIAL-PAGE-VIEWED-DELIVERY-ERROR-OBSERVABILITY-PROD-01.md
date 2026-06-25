# PH-SAAS-T8.12AS.21.117 - READONLY VERIFY API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY PROD

Date UTC: 2026-06-25
Mode: READONLY VERIFY PROD
Verdict: READY_WITH_LIMITS

## Objectif

Verifier en lecture seule que l'API PROD promue en PH-21.116 tourne correctement avec:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod`

Digest runtime attendu:

`sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384`

Cette phase ne fait aucun build, aucun docker push, aucun deploy, aucun `kubectl apply`,
aucun POST `/funnel/event`, aucun retry/replay CAPI, aucun CAPI test, aucune DB mutation
et aucune mutation Linear.

## Sources relues

| Source | Resultat |
| --- | --- |
| AI_MEMORY CURRENT_STATE | relu |
| AI_MEMORY RULES_AND_RISKS | relu |
| AI_MEMORY DOCUMENT_MAP | relu |
| AI_MEMORY CE_PROMPTING_STANDARD | relu |
| PH-21.113 rapport infra | relu |
| PH-21.114 rapport infra | relu |
| PH-21.115 rapport infra | relu |
| PH-21.116 rapport infra | relu |

Note: aucun fichier `C:\DEV\KeyBuzz\tmp\PH-21.117_CE_MISSION.md` n'etait present localement.
Le GO explicite courant a ete execute avec le protocole KeyBuzz READONLY VERIFY PROD.

## Preflight bastion

| Controle | Resultat |
| --- | --- |
| Hostname | install-v3 |
| IP obligatoire | 46.62.171.61 presente |
| IP interdite 51.159.99.247 | absente |
| Date UTC preflight | 2026-06-25T08:54:22Z |

## Repos

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 547648fd | 547648fd | 0/0 | 223, non-dist 0 | non touche |
| keybuzz-infra | main | 5b6ac23 | 5b6ac23 | 0/0 | 0 | rapport docs-only autorise |

Dette conservee: le repo API courant garde des suppressions tracked `dist/` preexistantes,
non touchees.

## Registry

| Controle | Resultat |
| --- | --- |
| Target image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod` |
| Pull digest | `sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384` |
| Digest match | oui |
| Image ID/config | `sha256:1e85e6a19fb2dd6a9db6ec50e600abd2c6e94323e218ddd869752eb918b230f9` |
| OCI revision | `547648fd1fcb05d291157a5119cd35d141905cdf` |
| OCI version | `v3.5.265-meta-capi-error-observability-prod` |
| RepoDigest | `ghcr.io/keybuzzio/keybuzz-api@sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384` |
| latest hash | `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` |
| latest intact | oui |

## Runtime API PROD

| Controle | Resultat |
| --- | --- |
| Manifest image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod` |
| Deployment generation | 425 |
| Observed generation | 425 |
| Ready replicas | 1/1 |
| Manifest = target | oui |
| Deployment spec = target | oui |
| Last-applied = target | oui |
| Pod count | 1 |
| Pod | keybuzz-api-5d6945f8cd-26mdl |
| Pod image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod` |
| Pod imageID | `ghcr.io/keybuzzio/keybuzz-api@sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384` |
| Digest OK | oui |
| Pod ready | True |
| Restarts | 0 |
| Phase | Running |
| Health | status ok |

## Runtime markers

| Marker / fichier | Resultat |
| --- | --- |
| provider-error-normalizer.js | present |
| meta-capi.js | present |
| emitter.js | present |
| llm-provider-errors.js | present |
| normalizeMetaCapiProviderError | 4 |
| buildSafeMetaCapiDeliveryErrorMessage | 3 |
| META_MISSING_USER_DATA | 1 |
| UNKNOWN_SAFE_ERROR | 3 |
| outbound_conversion_delivery_logs | 19 |
| error_message | 16 |
| trial_page_viewed | 7 |
| StartTrial | 9 |
| Purchase | 31 |
| PROVIDER_CREDIT_EXHAUSTED | 13 |
| llm-provider-errors | 4 |
| dist/tests | 0 |
| artefacts tests PH21.107/PH21.79 | 0 |

## Logs API PROD

Fenetre: 1h, tail 3000.

| Controle logs | Resultat |
| --- | --- |
| Lignes | 1524 |
| crash/panic/fatal/uncaught/unhandled | 0 |
| strong secret pattern | 0 |
| capi/meta | 0 |
| trial_page_viewed | 0 |
| StartTrial/Purchase/CompletePayment | 0 |
| LLM/provider credit related | 3 |
| retry/replay/99541c23fe41 | 0 |

Les 3 occurrences LLM restent hors scope Meta CAPI et ne correspondent pas a
`PROVIDER_CREDIT_EXHAUSTED` en DB.

## DB PROD read-only

Lecture effectuee via transaction `BEGIN TRANSACTION READ ONLY`, sans afficher de secret.

| Table | Resultat |
| --- | --- |
| outbound_conversion_delivery_logs | existe, total 21 |
| outbound_conversion_delivery_logs.error_message | colonne presente |
| failed total | 6 |
| error_message non null | 6 |
| trial_page_viewed delivery total | 2 |
| trial_page_viewed delivery failed | 2 |
| delivery 99541c23fe41 | 0 ligne |
| funnel_events | existe, total 316 |
| funnel_events trial_page_viewed | 0 |
| funnel_events register_started | 187 |
| conversion_events | existe, total 3 |
| conversion_events trial_page_viewed | 0 |
| conversion_events StartTrial | 2 |
| conversion_events Purchase | 1 |
| ai_usage | existe, total 370 |
| ai_usage PROVIDER_CREDIT_EXHAUSTED | 0 |

Interpretation:

- la table de delivery conserve bien `error_message` et les erreurs existantes restent
  persistantes;
- aucun nouveau `trial_page_viewed` naturel n'a ete observe dans les logs de la fenetre;
- aucune mutation DB volontaire n'a ete faite par CE;
- la preuve live d'un nouvel incident provider Meta CAPI post-apply reste a obtenir par
  trafic naturel ou GO explicite, pas par replay.

## Non-regression runtime

| Service | Image | Digest runtime | Ready | Restarts |
| --- | --- | --- | --- | --- |
| API DEV | `v3.5.265-meta-capi-error-observability-dev` | `sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb` | 1/1 | 0 |
| Client PROD | `v3.5.260-onboarding-register-started-owner-payload-prod` | `sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115` | 1/1 | 0 |
| Client DEV | `v3.5.260-onboarding-register-started-owner-payload-dev` | `sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9` | 1/1 | 0 |
| Website PROD | `v0.7.2-visual-hero-parity-prod` | `sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4` | 2/2 | 0 |
| Website DEV | `v0.7.1-hero-copy-prod-body-parity-dev` | `sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b` | 1/1 | 0 |
| Admin PROD | `v2.12.2-media-buyer-lp-domain-qa-prod` | `sha256:ecc2080ff7fe5031eab812b1c32d330e4f7eea902d2a98e4d7bd7b409e0d5037` | 1/1 | 0 |
| Admin DEV | `v2.12.2-media-buyer-lp-domain-qa-dev` | `sha256:c747ee93d25a81e43f44e04d2c845b51a3eab0ede51f050df1375e6009abaa09` | 1/1 | 0 |
| Backend PROD | `v1.0.56-amazon-inbound-dedup-prod` | `sha256:9689875ca55677d80ef122a2bbd6209fd5071da2fac51f15cd182f8d7f1dcdd2` | 1/1 | 0 |
| Backend DEV | `v1.0.57-amazon-notification-classification-dev` | `sha256:ab583b9c57bb47bddb35be594ffb8938bf7bd57d6f79b6f8906c341083c5d806` | 1/1 | 0 |

## AI feature parity / anti-regression

| Surface IA | Attendu | Resultat |
| --- | --- | --- |
| PROVIDER_CREDIT_EXHAUSTED | present dans runtime | present, 13 occurrences |
| llm-provider-errors | present dans runtime | present, 4 occurrences |
| dist/tests | absent | 0 |
| appel LLM CE | 0 | 0 |
| DB ai_usage/ledger mutation volontaire | 0 | 0 |
| ai_usage PROVIDER_CREDIT_EXHAUSTED | 0 | 0 |

## No fake metrics / no fake events

| Controle | Attendu | Resultat |
| --- | --- | --- |
| build/rebuild CE | 0 | 0 |
| docker push CE | 0 | 0 |
| deploy/apply CE | 0 | 0 |
| POST /funnel/event CE | 0 | 0 |
| retry/replay CAPI | 0 | 0 |
| CAPI test endpoint | 0 | 0 |
| DB mutation volontaire | 0 | 0 |
| formulaire /register | 0 | 0 |
| checkout Stripe | 0 | 0 |

## Limites

- Aucun nouvel incident Meta CAPI naturel `trial_page_viewed` n'a ete observe dans la
  fenetre de verification.
- La persistence live d'un nouveau provider error safe post-apply reste donc non prouvee
  par trafic naturel.
- Ne pas rejouer `99541c23fe41` sans GO explicite.

## Verdict

`GO READONLY VERIFY API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY PROD READY_WITH_LIMITS PH-SAAS-T8.12AS.21.117`

## Prochain GO exact

`GO READONLY CLOSE API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY PROD PH-SAAS-T8.12AS.21.118`
