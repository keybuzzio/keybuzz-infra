# PH-SAAS-T8.12AS.21.116 - APPLY API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY PROD GITOPS

Date UTC: 2026-06-25
Mode: APPLY API PROD GITOPS
Verdict: READY_WITH_DEBTS

## Objectif

Promouvoir en PROD, via GitOps strict, l'image API deja poussee en PH-21.115:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod`

Digest GHCR attendu:

`sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384`

Image ID/config attendu:

`sha256:1e85e6a19fb2dd6a9db6ec50e600abd2c6e94323e218ddd869752eb918b230f9`

Source API:

`547648fd1fcb05d291157a5119cd35d141905cdf`

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

Note: aucun fichier `C:\DEV\KeyBuzz\tmp\PH-21.116_CE_MISSION.md` n'etait present localement.
Le GO explicite courant a ete execute avec le protocole GitOps PROD KeyBuzz standard.

## Preflight bastion

| Controle | Resultat |
| --- | --- |
| Hostname | install-v3 |
| IP obligatoire | 46.62.171.61 presente |
| IP interdite 51.159.99.247 | absente |
| Date UTC preflight | 2026-06-25T08:06:27Z |

## Repos avant patch

| Repo | Branche | HEAD | Origin | Ahead/behind | Dirty | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 547648fd | 547648fd | 0/0 | 223, non-dist 0 | ne pas nettoyer, ne pas build |
| keybuzz-infra | main | 7ee8ea4 | 7ee8ea4 | 0/0 | 0 | manifest API PROD autorise |

Dette conservee: le repo API courant garde des suppressions tracked `dist/` preexistantes,
non touchees.

## Registry pre-apply

| Controle | Resultat |
| --- | --- |
| Target image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod` |
| Pull digest | `sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384` |
| Digest match | oui |
| Image ID/config | `sha256:1e85e6a19fb2dd6a9db6ec50e600abd2c6e94323e218ddd869752eb918b230f9` |
| OCI revision | `547648fd1fcb05d291157a5119cd35d141905cdf` |
| OCI version | `v3.5.265-meta-capi-error-observability-prod` |
| latest hash | `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` |

## Patch GitOps

Fichier modifie:

`k8s/keybuzz-api-prod/deployment.yaml`

Diff scope:

| Fichier | Changement |
| --- | --- |
| `k8s/keybuzz-api-prod/deployment.yaml` | image API PROD `v3.5.264` -> `v3.5.265`, commentaire trace/rollback |

Ancienne image:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod`

Nouvelle image:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod`

Rollback documente:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod`

avec digest runtime precedent:

`sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad`

## Validations avant commit

| Controle | Resultat |
| --- | --- |
| Changed files | `k8s/keybuzz-api-prod/deployment.yaml` uniquement |
| Diff stat | 1 file changed, 1 insertion, 1 deletion |
| `kubectl apply --dry-run=client -f` | PASS |
| `kubectl apply --dry-run=server -f` | PASS |

## Commit/push manifest

| Controle | Resultat |
| --- | --- |
| Commit manifest | `4b9dec7` |
| Message | `deploy(PH-21.116): promote api meta capi observability prod` |
| Push | normal non-force |
| Post-push | HEAD=origin, ahead/behind 0/0 |

## Apply et rollout

Commande autorisee executee:

`kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`

Resultat:

- `deployment.apps/keybuzz-api configured`
- rollout status: `deployment "keybuzz-api" successfully rolled out`

Aucun `kubectl set image`, `kubectl patch`, `kubectl edit`, `kubectl set env` ou restart
imperatif n'a ete utilise.

## Runtime API PROD apres apply

| Controle | Resultat |
| --- | --- |
| Manifest image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod` |
| Deployment generation | 425 |
| Observed generation | 425 |
| Ready replicas | 1/1 |
| Manifest = target | oui |
| Deployment spec = target | oui |
| Last-applied = target | oui |
| Pod | keybuzz-api-5d6945f8cd-26mdl |
| Pod image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod` |
| Pod imageID | `ghcr.io/keybuzzio/keybuzz-api@sha256:ca11a4e7477f8ee1ddeca2ec64d8cd469402344060fedac5f412be413a5bd384` |
| Digest OK | oui |
| Pod ready | True |
| Restarts | 0 |
| Phase | Running |
| Health | status ok |
| Logs 10m crash/panic/fatal | 0 |
| Logs 10m strong secret pattern | 0 |

## Registry safety apres apply

| Controle | Resultat |
| --- | --- |
| latest hash apres apply | `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` |
| latest inchange | oui |
| Docker build | 0 |
| Docker push | 0 |

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
| PROVIDER_CREDIT_EXHAUSTED | present selon audit PH-21.114 | present |
| llm-provider-errors | present selon audit PH-21.114 | present |
| dist/tests | absent selon audit PH-21.114 | absent |
| appel LLM | 0 | 0 |
| DB ai_usage/ledger mutation volontaire | 0 | 0 |

## No fake metrics / no fake events

| Controle | Attendu | Resultat |
| --- | --- | --- |
| build/rebuild CE | 0 | 0 |
| docker push CE | 0 | 0 |
| POST /funnel/event CE | 0 | 0 |
| retry/replay CAPI | 0 | 0 |
| CAPI test endpoint | 0 | 0 |
| DB mutation volontaire | 0 | 0 |
| formulaire /register | 0 | 0 |
| checkout Stripe | 0 | 0 |

## Dettes / limites

- Dette preexistante non bloquante: repo API courant dirty `dist/` tracked deletions,
  non touche.
- PH-21.116 a active le runtime PROD, mais n'a pas observe de nouvel incident Meta CAPI
  naturel.
- Ne pas rejouer `99541c23fe41` sans GO explicite.

## Verdict

`GO APPLY API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY PROD GITOPS READY_WITH_DEBTS PH-SAAS-T8.12AS.21.116`

## Prochain GO exact

`GO READONLY VERIFY API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY PROD PH-SAAS-T8.12AS.21.117`
