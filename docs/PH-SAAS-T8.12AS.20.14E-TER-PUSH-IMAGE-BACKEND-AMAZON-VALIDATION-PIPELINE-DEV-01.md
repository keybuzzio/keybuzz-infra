# PH-SAAS-T8.12AS.20.14E-TER-PUSH-IMAGE-BACKEND-AMAZON-VALIDATION-PIPELINE-DEV-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14C-TER / D-TER
> Phase : PH-SAAS-T8.12AS.20.14E-TER (PUSH IMAGE ONLY)
> Environnement : DEV (push GHCR uniquement ; aucun deploy, aucun manifest, aucune mutation)

## 1. Verdict

GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE DEV DONE PH-SAAS-T8.12AS.20.14E-TER

L image backend DEV immuable v1.0.50-amazon-validation-pipeline-dev (commit 2a14258) est poussee sur GHCR. Pull-back OK, config digest remote == image ID local (7e8a056c), labels OCI rev/ver confirmes. Aucun build, aucun deploy, aucun manifest GitOps, aucun kubectl, aucune mutation DB, aucun email. jobs-worker DEV inchange (v1.0.49).

Prochaine phrase GO : GO APPLY BACKEND AND JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.14F-TER.

## 2. Pre-push (verif image locale)

| Item | Valeur | Verdict |
|---|---|---|
| Image ID | sha256:7e8a056cb53e70147cd4c32aa65ec1d1f11d29549cea8754d7316e1ed8005876 | OK |
| OCI revision | 2a142587533e77546fb10d353a0acc86f8a7a754 | OK |
| OCI version | v1.0.50-amazon-validation-pipeline-dev | OK |
| Prisma mapping toAddress -> to (client genere) | schema.prisma:538 @map("to") | OK |
| JOB_TYPES dans dist/workers/jobsWorker.js | present (8 occurrences) | OK |
| GHCR avant push | ABSENT | OK |

## 3. Push

| Item | Valeur | Verdict |
|---|---|---|
| Tag pousse | ghcr.io/keybuzzio/keybuzz-backend:v1.0.50-amazon-validation-pipeline-dev | OK |
| Digest manifest GHCR | sha256:6e00ad07798247b5c1177cb2e6ddf9db9ec6015c942673b12dbbb1c3a5bd39da | OK |
| Layers | nouvelles couches Pushed + base already exists | OK |

## 4. Pull-back / digest match

| Check | Valeur | Verdict |
|---|---|---|
| GHCR present apres push | oui | OK |
| Config digest remote | sha256:7e8a056c... | == ID local |
| Image ID local | sha256:7e8a056c... | MATCH |
| Pull-back manifest digest | sha256:6e00ad07... (up to date) | OK |
| Labels remote (pull-back) | rev=2a14258 ver=v1.0.50-amazon-validation-pipeline-dev | OK |

## 5. No side-effect

| Side effect | Preuve | Verdict |
|---|---|---|
| build | 0 | OK |
| deploy / kubectl apply | 0 | OK |
| manifest GitOps modifie | 0 | OK |
| pod restart | jobs-worker inchange v1.0.49 | OK |
| DB mutation | 0 | OK |
| email reel | 0 | OK |
| trigger validation | 0 | OK |
| v1.0.48 / v1.0.49 utilises/deployes | non | OK |

## 6. Rollback

Tag immuable pousse : ne pas ecraser. Pour invalider : ne pas referencer v1.0.50 dans les manifests (aucun apply effectue). Suppression GHCR possible via package settings si necessaire (action separee). Runtime inchange (aucune image deployee), donc rollback runtime N/A.

## 7. Prochaine phrase GO

GO APPLY BACKEND AND JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.14F-TER

Redeploy keybuzz-backend API DEV (qui fait le create OutboundEmail) ET jobs-worker DEV sur v1.0.50. Ne PAS proposer de re-trigger validation avant que les deux tournent sur v1.0.50.

STOP.
