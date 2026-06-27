# PH-SAAS-T8.12AS.21.175 - Push image API Client first-run /start onboarding latency PROD

## Verdict

DONE.

Images PROD poussees sur GHCR et verifiees par pull-back:

- API: `ghcr.io/keybuzzio/keybuzz-api:v3.5.273-start-onboarding-latency-prod`
- Client: `ghcr.io/keybuzzio/keybuzz-client:v3.5.267-start-onboarding-latency-prod`

Aucun deploy, aucun `kubectl apply`, aucun manifest modifie, aucun formulaire, aucun checkout, aucun fake event, aucune mutation DB.

## Objectif

Pousser les images PROD locales construites et auditees en PH-21.174 vers GHCR, sans modifier le runtime Kubernetes.

## Sources et images locales

| Service | Image | Image ID local | Source | Version label |
| --- | --- | --- | --- | --- |
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.273-start-onboarding-latency-prod` | `sha256:7b7aefc7eb4dd7e07ebc6e3cc6bbb1edf788244f78fb60aecf76b14643f93784` | `b60f506fe677af82563e77f2a1ad27110bf74593` | `v3.5.273-start-onboarding-latency-prod` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.267-start-onboarding-latency-prod` | `sha256:542292c3e98308da7cd2538bb2f2ab08144b4b71170754b3f21664329499ae8e` | `48147dc572b3b4444f3b85d2277867e15a1c3e5d` | `v3.5.267-start-onboarding-latency-prod` |

## Registry precheck

| Image | Avant push |
| --- | --- |
| API tag cible | ABSENT |
| Client tag cible | ABSENT |

`latest` avant push:

| Repo image | Hash manifest `latest` |
| --- | --- |
| API | `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` |
| Client | `151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341` |

## Push GHCR

| Service | Push | Manifest digest GHCR |
| --- | --- | --- |
| API | OK | `sha256:424612fe036d604f95c0d843b02a0ca3b9035c0c5f07d122615b5bf1ea03a9c7` |
| Client | OK | `sha256:ae5de89ed95da058ece6f93d85ae6a2f925d8aa6d1b437ae6f0dde06a1b5dbc0` |

Note process: le script initial a pousse les deux images correctement, puis a echoue sur une verification `RepoDigests` locale vide. Un post-verify dedie a ete execute ensuite via `docker pull` et `docker manifest inspect`; toutes les validations finales ont passe.

## Pull-back verification

| Service | Digest pull-back | Image ID apres pull | Revision label | Verdict |
| --- | --- | --- | --- | --- |
| API | `sha256:424612fe036d604f95c0d843b02a0ca3b9035c0c5f07d122615b5bf1ea03a9c7` | `sha256:7b7aefc7eb4dd7e07ebc6e3cc6bbb1edf788244f78fb60aecf76b14643f93784` | `b60f506fe677af82563e77f2a1ad27110bf74593` | PASS |
| Client | `sha256:ae5de89ed95da058ece6f93d85ae6a2f925d8aa6d1b437ae6f0dde06a1b5dbc0` | `sha256:542292c3e98308da7cd2538bb2f2ab08144b4b71170754b3f21664329499ae8e` | `48147dc572b3b4444f3b85d2277867e15a1c3e5d` | PASS |

## Latest verification

| Repo image | Hash `latest` avant | Hash `latest` apres | Verdict |
| --- | --- | --- | --- |
| API | `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` | `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` | PASS |
| Client | `151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341` | `151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341` | PASS |

## Runtime PROD inchange

| Service | Runtime actuel | Ready | Generation |
| --- | --- | --- | --- |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.271-dependency-hardening-prod` | 1/1 | 431/431 |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.266-dependency-hardening-prod` | 1/1 | 433/433 |

## No fake metrics / no fake events

- 0 deploy.
- 0 `kubectl apply`.
- 0 manifest modifie.
- 0 `kubectl set image/env/patch/edit`.
- 0 formulaire.
- 0 checkout Stripe.
- 0 POST `/funnel/event`.
- 0 fake StartTrial/Purchase/CompletePayment.
- 0 CAPI test.
- 0 DB mutation volontaire.
- 0 Webflow / Meta Ads / Linear.

## Non-regression

- Tags immuables utilises.
- `latest` intact.
- Images pull-back OK.
- Runtime PROD inchange.
- Rollback GitOps conserve:
  - API `v3.5.271-dependency-hardening-prod`
  - Client `v3.5.266-dependency-hardening-prod`

## Prochaine phase

`GO APPLY API CLIENT FIRST-RUN START ONBOARDING LATENCY PROD GITOPS PH-SAAS-T8.12AS.21.176`

## Verdict final

GO PUSH IMAGE API CLIENT FIRST-RUN START ONBOARDING LATENCY PROD DONE PH-SAAS-T8.12AS.21.175.

STOP.
