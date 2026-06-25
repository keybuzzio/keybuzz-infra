# PH-SAAS-T8.12AS.21.115 - PUSH IMAGE API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY PROD

Date UTC: 2026-06-25
Mode: PUSH IMAGE API PROD only
Verdict: DONE_WITH_DEBTS

## Objectif

Pousser vers GHCR, sans rebuild ni deploy, l'image API PROD construite en PH-21.114:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod`

Image locale attendue:

`sha256:1e85e6a19fb2dd6a9db6ec50e600abd2c6e94323e218ddd869752eb918b230f9`

Source attendue:

`547648fd1fcb05d291157a5119cd35d141905cdf`

## Sources relues

| Source | Resultat |
| --- | --- |
| AI_MEMORY CURRENT_STATE | relu, 974 lignes |
| AI_MEMORY RULES_AND_RISKS | relu, 169 lignes |
| AI_MEMORY DOCUMENT_MAP | relu, 165 lignes |
| AI_MEMORY CE_PROMPTING_STANDARD | relu, 233 lignes |
| PH-T8.10J modele canonique local | relu |
| PH-21.107 -> PH-21.114 retours CE locaux | relus |
| PH-21.107 rapport infra | relu |
| PH-21.112 rapport infra | relu |
| PH-21.113 rapport infra | relu |
| PH-21.114 rapport infra | relu |

## Preflight bastion

| Controle | Resultat |
| --- | --- |
| Hostname | install-v3 |
| IP obligatoire | 46.62.171.61 presente |
| IP interdite 51.159.99.247 | absente |
| Date UTC preflight | 2026-06-25T07:58:00Z |

## Repos

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 547648fd | 547648fd | 0/0 | 223, non-dist 0 | ne pas nettoyer, ne pas build |
| keybuzz-infra | main | 44bf2a9 | 44bf2a9 | 0/0 | 0 | rapport docs-only autorise |

Dette conservee: le repo API courant garde des suppressions tracked `dist/`
preexistantes. Elles n'ont pas ete nettoyees ni revert.

## Verification image locale

| Controle image locale | Attendu | Resultat |
| --- | --- | --- |
| tag local | present | present |
| Image ID | `sha256:1e85e6a19fb2dd6a9db6ec50e600abd2c6e94323e218ddd869752eb918b230f9` | match |
| OCI revision | `547648fd1fcb05d291157a5119cd35d141905cdf` | match |
| OCI version | `v3.5.265-meta-capi-error-observability-prod` | match |
| OCI source | `https://github.com/keybuzzio/keybuzz-api` | match |
| OCI title | `keybuzz-api` | match |
| RepoDigest pre-push | absent ou non pertinent | absent |

## Registry safety avant push

| Image/tag | Etat attendu avant push | Resultat |
| --- | --- | --- |
| `v3.5.265-meta-capi-error-observability-prod` | absent | absent |
| `latest` | digest note, intact | `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` |

## Push image

| Champ | Valeur |
| --- | --- |
| Image poussee | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod` |
| Image ID avant push | `sha256:1e85e6a19fb2dd6a9db6ec50e600abd2c6e94323e218ddd869752eb918b230f9` |
| Manifest digest GHCR obtenu | `sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384` |
| Push latest | 0 |
| Autres tags pousses | 0 |
| Rebuild | 0 |

## Pull-back / inspect

| Pull-back / inspect | Attendu | Resultat |
| --- | --- | --- |
| RepoDigest | manifest digest GHCR cible | `ghcr.io/keybuzzio/keybuzz-api@sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384` |
| Image ID/config | `sha256:1e85e6a19fb2dd6a9db6ec50e600abd2c6e94323e218ddd869752eb918b230f9` | match |
| OCI revision | `547648fd1fcb05d291157a5119cd35d141905cdf` | match |
| OCI version | `v3.5.265-meta-capi-error-observability-prod` | match |
| secret/PII exposure | 0 | 0 |

Pull-back result:

- Digest: `sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384`
- Status: image up to date for the target tag

## Registry safety apres push

| Controle registry post-push | Attendu | Resultat |
| --- | --- | --- |
| tag PROD cible distant | present | present |
| manifest digest | documente | `sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384` |
| latest | inchange | `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` |
| autre tag pousse | 0 | 0 |
| rebuild | 0 | 0 |

## Runtime read-only non-regression

| Service | Image | Digest runtime | Ready | Restarts | Mutation |
| --- | --- | --- | --- | --- | --- |
| API PROD | `v3.5.264-onboarding-trial-page-viewed-meta-prod` | `sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad` | 1/1 | 0 | non |
| API DEV | `v3.5.265-meta-capi-error-observability-dev` | `sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb` | 1/1 | 0 | non |
| Client PROD | `v3.5.260-onboarding-register-started-owner-payload-prod` | `sha256:c244570f6000e94559094f2009df8792775ba8739b83d4bb17aa3bd4152f7115` | 1/1 | 0 | non |
| Client DEV | `v3.5.260-onboarding-register-started-owner-payload-dev` | `sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9` | 1/1 | 0 | non |
| Website PROD | `v0.7.2-visual-hero-parity-prod` | `sha256:24ff787f8f550afbb79df1d7979dbe35fc91d0a1c6ad7e4b6ce5914284cf8bb4` | 2/2 | 0 | non |
| Website DEV | `v0.7.1-hero-copy-prod-body-parity-dev` | `sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b` | 1/1 | 0 | non |
| Admin DEV | `v2.12.2-media-buyer-lp-domain-qa-dev` | `sha256:c747ee93d25a81e43f44e04d2c845b51a3eab0ede51f050df1375e6009abaa09` | 1/1 | 0 | non |
| Admin PROD | `v2.12.2-media-buyer-lp-domain-qa-prod` | `sha256:ecc2080ff7fe5031eab812b1c32d330e4f7eea902d2a98e4d7bd7b409e0d5037` | 1/1 | 0 | non |
| Backend DEV | `v1.0.57-amazon-notification-classification-dev` | `sha256:ab583b9c57bb47bddb35be594ffb8938bf7bd57d6f79b6f8906c341083c5d806` | 1/1 | 0 | non |
| Backend PROD | `v1.0.56-amazon-inbound-dedup-prod` | `sha256:9689875ca55677d80ef122a2bbd6209fd5071da2fac51f15cd182f8d7f1dcdd2` | 1/1 | 0 | non |

## AI feature parity / anti-regression

| Surface IA | Attendu | Resultat |
| --- | --- | --- |
| PROVIDER_CREDIT_EXHAUSTED | present selon audit PH-21.114 | present |
| llm-provider-errors | present selon audit PH-21.114 | present |
| dist/tests | absent selon audit PH-21.114 | absent |
| appel LLM | 0 | 0 |
| DB ai_usage/ledger mutation volontaire | 0 | 0 |

## No fake metrics / no fake events

| Controle | Attendu | Resultat |
| --- | --- | --- |
| build/rebuild CE | 0 | 0 |
| POST /funnel/event CE | 0 | 0 |
| retry/replay CAPI | 0 | 0 |
| CAPI test endpoint | 0 | 0 |
| DB mutation volontaire | 0 | 0 |
| StartTrial/Purchase/CompletePayment pollues | 0 | 0 |
| formulaire /register | 0 | 0 |
| checkout Stripe | 0 | 0 |

## Dettes / limites

- Dette preexistante non bloquante: repo API courant dirty `dist/` tracked deletions,
  non touche.
- Le tag PROD est pousse mais pas deployee. API PROD runtime reste en v3.5.264 jusqu'au
  GO GitOps explicite.
- Ne pas rejouer `99541c23fe41` sans GO explicite.

## Verdict

`GO PUSH IMAGE API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY PROD DONE_WITH_DEBTS PH-SAAS-T8.12AS.21.115`

## Prochain GO exact

`GO APPLY API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY PROD GITOPS PH-SAAS-T8.12AS.21.116`
