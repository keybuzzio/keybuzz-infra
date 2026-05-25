# PH-SAAS-T8.12AS.20.14K-PUSH-IMAGE-BACKEND-AMAZON-VALIDATION-PIPELINE-DEV-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14J / 14I
> Phase : PH-SAAS-T8.12AS.20.14K (PUSH IMAGE ONLY)
> Environnement : DEV (push GHCR uniquement ; aucun deploy, aucune mutation)

## 1. Verdict

GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE DEV DONE PH-SAAS-T8.12AS.20.14K

L image backend DEV immuable v1.0.51-amazon-validation-pipeline-dev (commit cbbc99e, fix resolution exacte adresse PH-20.14I) est poussee sur GHCR. Pull-back OK, config digest remote == image ID local (fca5a28a), labels OCI confirmes. Aucun build, aucun deploy, aucun manifest, aucun kubectl, aucune mutation DB, aucun email. API/jobs-worker DEV inchanges (v1.0.50).

Prochaine phrase GO : GO APPLY BACKEND AND JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.14L.

## 2. Pre-push (image locale)

| Item | Valeur | Verdict |
|---|---|---|
| Image ID | sha256:fca5a28ab5c6a13e3ce34fac7b927a9b0b0beb1f985585966ffdc059007b039b | OK |
| OCI revision | cbbc99e1fc484b52e8b2602e47eb38d04765a0f8 | OK |
| OCI version | v1.0.51-amazon-validation-pipeline-dev | OK |
| decideValidationAddress (dist inbound.service.js) | present (4 occurrences) | OK |
| toAddress @map("to") (client genere) | schema.prisma:538 | OK |
| JOB_TYPES (dist jobsWorker.js) | present (8 occurrences) | OK |
| GHCR avant push | ABSENT | OK |

## 3. Push

| Item | Valeur | Verdict |
|---|---|---|
| Tag pousse | ghcr.io/keybuzzio/keybuzz-backend:v1.0.51-amazon-validation-pipeline-dev | OK |
| Digest manifest GHCR | sha256:92f164d2d5cc355603d4e7ce5600eb27312ac4a638854afe3f1f11a0c14f7801 | OK |
| Layers | 1 nouvelle couche Pushed + base already exists | OK |

## 4. Pull-back / digest match

| Check | Valeur | Verdict |
|---|---|---|
| GHCR present apres push | oui | OK |
| Config digest remote | sha256:fca5a28a... | == ID local |
| Image ID local | sha256:fca5a28a... | MATCH |
| Pull-back manifest digest | sha256:92f164d2... (up to date) | OK |
| Labels remote (pull-back) | rev=cbbc99e ver=v1.0.51-amazon-validation-pipeline-dev | OK |

## 5. No side-effect

| Side effect | Preuve | Verdict |
|---|---|---|
| build | 0 | OK |
| deploy / kubectl apply | 0 | OK |
| manifest GitOps modifie | 0 | OK |
| pod restart | API/jobs-worker inchanges v1.0.50 | OK |
| DB mutation / email / trigger | 0 | OK |
| v1.0.48 / 49 / 50 utilises/deployes | non | OK |

## 6. Rollback

Tag immuable pousse : ne pas ecraser. Runtime inchange (aucune image deployee) -> rollback runtime N/A. Suppression GHCR possible via package settings si necessaire (action separee).

## 7. Prochaine phrase GO

GO APPLY BACKEND AND JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.14L

Redeploy keybuzz-backend API DEV ET jobs-worker DEV sur v1.0.51. Ne PAS proposer de re-trigger validation avant que les deux tournent sur v1.0.51.

STOP.
