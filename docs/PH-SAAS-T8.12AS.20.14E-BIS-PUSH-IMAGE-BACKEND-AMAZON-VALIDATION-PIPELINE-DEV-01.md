# PH-SAAS-T8.12AS.20.14E-BIS-PUSH-IMAGE-BACKEND-AMAZON-VALIDATION-PIPELINE-DEV-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14C-BIS / PH-20.14D-BIS
> Phase : PH-SAAS-T8.12AS.20.14E-BIS-PUSH-IMAGE-BACKEND-AMAZON-VALIDATION-PIPELINE-DEV
> Environnement : DEV image registry (PUSH ONLY ; no build, no deploy, no GitOps, no DB, no email)

## 1. Verdict

GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE DEV READY PH-SAAS-T8.12AS.20.14E-BIS

L image backend DEV scopee v1.0.49-amazon-validation-pipeline-dev (build PH-20.14D-BIS, commit 71e66c9, filtre JOB_TYPES) est poussee sur GHCR. Pull-back OK, OCI revision 71e66c9, version v1.0.49. Aucun build, deploy, GitOps, DB, email. v1.0.48 generique non utilisee.

## 2. Image locale verify (avant push)

| Check | Attendu | Observe | Verdict |
|---|---|---|---|
| Image ID | sha256:684628279a70... | sha256:684628279a70bcdb55964deecb707aab92bccd4b9b50da257a261355b8caf1b2 | OK |
| OCI revision | 71e66c9 | 71e66c9b435a2de6cda4909b8a094b4b592b3192 | OK |
| OCI version | v1.0.49-amazon-validation-pipeline-dev | idem | OK |
| OCI created | n/a | 2026-05-25T19:52:02Z | OK |
| JOB_TYPES dans dist (jobsWorker.js) | present | 8 occurrences | OK |
| GHCR avant push | absent | ABSENT | OK |

## 3. Push

| Push item | Valeur | Verdict |
|---|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-backend:v1.0.49-amazon-validation-pipeline-dev | OK |
| Manifest digest | sha256:16a864a1c31b96d368469bd5459979fbe63af59e56ba84dbd317df9d42cb91df | OK |
| Manifest size | 2626 | OK |
| Push exit | 0 | OK |
| latest pousse | NON | OK |
| autre tag pousse | NON | OK |

## 4. Pull-back / digest audit

| Item | Valeur | Verdict |
|---|---|---|
| docker pull | up to date (digest sha256:16a864a1c31b...) | OK = digest push |
| Image ID local (config) | sha256:684628279a70...52b2 | OK inchange |
| RepoDigest | ghcr.io/keybuzzio/keybuzz-backend@sha256:16a864a1c31b...91df | OK |
| OCI revision (post pull) | 71e66c9b435a2de6cda4909b8a094b4b592b3192 | OK |
| OCI version (post pull) | v1.0.49-amazon-validation-pipeline-dev | OK |

## 5. Side effects

| Side effect | Preuve | Verdict |
|---|---|---|
| build | aucun (docker push uniquement) | AUCUN |
| deploy / kubectl mutation | aucune commande | AUCUN |
| manifest GitOps | aucun | AUCUN |
| jobsWorker / v1.0.48 / v1.0.49 deploye | aucun | AUCUN |
| DB mutation / email / trigger | aucun | AUCUN |

## 6. Anti-regression

Un push GHCR ne modifie aucun runtime : aucun deploy ne reference v1.0.49 (jobsWorker DEV cree en PH-20.14F-BIS). v1.0.48 generique reste obsolete pour le jobsWorker validation. Workers Amazon, guard VALIDATED, webhook, PH-20.11C/12B : inchanges.

## 7. No fake metrics / events

Push image uniquement. Aucun event, aucun KPI, aucun flip statut, aucun email.

## 8. Rollback

| Element | Rollback | Runtime impact |
|---|---|---|
| Image GHCR v1.0.49 | tag immuable persiste, sans effet tant que non reference par un deploy | aucun |
| Image locale | conservee pour apply DEV | aucun |

## 9. Prochaine phrase GO

GO APPLY JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.14F-BIS

Deployment jobs-worker (keybuzz-backend-dev), image v1.0.49-amazon-validation-pipeline-dev, command node dist/workers/jobsWorker.js, env JOB_TYPES=OUTBOUND_EMAIL_SEND (ne claim jamais AMAZON_POLL), SMTP cas 1 (SMTP_HOST=49.13.35.167 / SMTP_PORT=25 / SMTP_SECURE=false), envFrom keybuzz-backend-db + keybuzz-backend-secrets + vault-token + amazon-spapi-creds. Ne PAS deployer v1.0.48. Ne PAS re-trigger validation avant jobsWorker DEV scope deploye et healthy.

STOP.
