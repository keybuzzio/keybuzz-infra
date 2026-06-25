# PH-SAAS-T8.12AS.21.118 - READONLY CLOSE API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY PROD

Date UTC: 2026-06-25
Mode: READONLY CLOSE API PROD
Verdict: READY_WITH_LIMITS

## Objectif

Cloturer en lecture seule la chaine PROD d'observabilite des erreurs Meta CAPI pour
l'evenement server-side `trial_page_viewed`.

Cette phase consolide PH-21.104 a PH-21.117 et confirme que l'API PROD finale tourne sur:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod`

avec digest runtime:

`sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384`

Aucune mutation runtime n'a ete faite dans cette phase.

## Sources relues

| Source | Resultat |
| --- | --- |
| AI_MEMORY CURRENT_STATE | relu |
| AI_MEMORY RULES_AND_RISKS | relu |
| AI_MEMORY DOCUMENT_MAP | relu |
| AI_MEMORY CE_PROMPTING_STANDARD | relu |
| PH-T8.10J modele canonique local | relu |
| Retours CE PH-21.104 -> PH-21.117 | relus |
| Rapports infra PH-21.107 / PH-21.112 / PH-21.113 / PH-21.114 / PH-21.115 / PH-21.116 / PH-21.117 | relus |

## Preflight bastion

| Controle | Resultat |
| --- | --- |
| Hostname | install-v3 |
| IP obligatoire | 46.62.171.61 presente |
| IP interdite 51.159.99.247 | absente |
| Date UTC preflight | 2026-06-25T09:52:01Z |

## Repos

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 547648fd | 547648fd | 0/0 | 223, non-dist 0 | non touche |
| keybuzz-infra | main | 9214431 | 9214431 | 0/0 | 0 | rapport docs-only autorise |

Dette conservee: le repo API courant garde des suppressions tracked `dist/` preexistantes,
non touchees.

## Consolidation PH-21.104 -> PH-21.117

| Phase | Role | Verdict / resultat consolide |
| --- | --- | --- |
| PH-21.104 | observation trafic reel initial | NO_GO_CAPI_DELIVERY_FAILED |
| PH-21.105 | RCA failed delivery | READY_RCA_EVIDENCE_INSUFFICIENT |
| PH-21.106 | deep RCA persistence | READY_DEEP_RCA_OBSERVABILITY_PATCH_REQUIRED |
| PH-21.107 | source patch DEV | source patch API 547648fd, push source OK |
| PH-21.108 | build DEV | READY |
| PH-21.109 | push image DEV | DONE |
| PH-21.110 | apply DEV | READY_WITH_LIMITS |
| PH-21.111 | verify DEV | READY_WITH_LIMITS |
| PH-21.112 | close DEV | READY_WITH_LIMITS |
| PH-21.113 | design PROD | READY_FOR_BUILD_PROD |
| PH-21.114 | build PROD | READY_WITH_DEBTS |
| PH-21.115 | push image PROD | DONE_WITH_DEBTS |
| PH-21.116 | apply PROD | READY_WITH_DEBTS |
| PH-21.117 | verify PROD | READY_WITH_LIMITS |

Conclusion: la chaine source/build/push/apply/verify PROD est coherente. Aucune
contradiction bloquante n'a ete trouvee.

## Registry final

| Controle | Resultat |
| --- | --- |
| Image target | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod` |
| RepoDigest | `ghcr.io/keybuzzio/keybuzz-api@sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384` |
| Image ID/config | `sha256:1e85e6a19fb2dd6a9db6ec50e600abd2c6e94323e218ddd869752eb918b230f9` |
| OCI revision | `547648fd1fcb05d291157a5119cd35d141905cdf` |
| OCI version | `v3.5.265-meta-capi-error-observability-prod` |
| latest hash | `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` |
| latest intact | oui |

## Runtime final API PROD

| Controle API PROD | Attendu | Resultat |
| --- | --- | --- |
| Manifest Git image | target | target |
| Last-applied image | target | target |
| Deployment spec image | target | target |
| Pod spec image | target | target |
| Pod imageID digest | `sha256:ca11a4e...` | `sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384` |
| Generation/observedGeneration | equal | 425/425 |
| Ready replicas | 1/1 | 1/1 |
| Pod count | 1 | 1 |
| Pod | running | keybuzz-api-5d6945f8cd-26mdl |
| Pod ready | True | True |
| Restarts | 0 | 0 |
| Health | OK | status ok |

Runtime equality finale confirmee:

`manifest Git = last-applied = deployment spec = pod spec = pod imageID`.

## Audit final observabilite

| Audit runtime | Attendu | Resultat |
| --- | --- | --- |
| provider-error-normalizer | present | fichier present |
| meta-capi adapter | present | fichier present |
| emitter/persistence | present | fichier present |
| llm-provider-errors | present | fichier present |
| normalizeMetaCapiProviderError | present | 4 |
| buildSafeMetaCapiDeliveryErrorMessage | present | 3 |
| META_MISSING_USER_DATA | present | 1 |
| UNKNOWN_SAFE_ERROR | present | 3 |
| outbound_conversion_delivery_logs | present | 19 |
| error_message | present | 16 |
| trial_page_viewed | present | 7 |
| StartTrial | present | 9 |
| Purchase | present | 31 |
| PROVIDER_CREDIT_EXHAUSTED | present | 13 |
| llm-provider-errors | present | 4 |
| dist/tests | absent | 0 |
| artefacts tests PH21.107/PH21.79 | absent | 0 |
| secret/PII exposure | 0 | 0 |

## Logs et DB read-only

Fenetre logs API PROD: 2h, tail 5000.

| Controle read-only | Attendu | Resultat |
| --- | --- | --- |
| crash/panic/fatal | 0 | 0 |
| strong secret pattern | 0 | 0 |
| raw provider body expose | 0 | 0 |
| capi/meta logs | documente | 0 |
| trial_page_viewed logs | documente | 0 |
| retry/replay/99541c23fe41 logs | 0 | 0 |
| delivery_logs total | documente | 21 |
| failed total | documente | 6 |
| error_message non null | documente | 6 |
| trial_page_viewed delivery total | documente | 2 |
| trial_page_viewed delivery failed | documente | 2 |
| nouveau failed Meta naturel post-apply | count safe | 0 observe dans la fenetre |
| ai_usage PROVIDER_CREDIT_EXHAUSTED | 0 | 0 |
| DB mutation volontaire | 0 | 0 |

Lecture DB effectuee en transaction `BEGIN TRANSACTION READ ONLY`.

## Non-regression services

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
| PROVIDER_CREDIT_EXHAUSTED | present | present, 13 occurrences |
| llm-provider-errors | present | present, 4 occurrences |
| dist/tests | absent | 0 |
| appel LLM CE | 0 | 0 |
| DB ai_usage/ledger mutation volontaire | 0 | 0 |
| ai_usage PROVIDER_CREDIT_EXHAUSTED | 0 | 0 |
| regression IA visible | 0 | 0 |

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
| StartTrial/Purchase/CompletePayment pollues par CE | 0 | 0 |
| formulaire /register | 0 | 0 |
| checkout Stripe | 0 | 0 |

## Dettes et limites finales

- `TRAFFIC_REQUIRED` / `NO_NATURAL_FAILED_DELIVERY`: aucun nouvel incident provider
  naturel post-apply n'a ete observe.
- La preuve live d'un nouveau `error_message` safe non vide reste a obtenir avec un vrai
  trafic public/Meta, sans replay artificiel.
- Ne pas rejouer `99541c23fe41` sans GO explicite.
- Dette preexistante non bloquante: repo API courant dirty dist-only, non touche.
- La preuve Ads Manager / Events Manager depend d'un vrai parcours public/Meta et reste
  hors scope de cette cloture.
- StartTrial/Purchase restent hors scope de ce patch, definitions intactes.

## Verdict

`GO READONLY CLOSE API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY PROD READY_WITH_LIMITS PH-SAAS-T8.12AS.21.118`

## Prochain GO

`GO READONLY OBSERVE META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY REAL TRAFFIC PROD PH-SAAS-T8.12AS.21.119`

Ce GO est facultatif et seulement pertinent quand Ludovic ou Antoine declenche un vrai
parcours public/Meta. Aucun GO technique n'est requis pour corriger le runtime actuel.
