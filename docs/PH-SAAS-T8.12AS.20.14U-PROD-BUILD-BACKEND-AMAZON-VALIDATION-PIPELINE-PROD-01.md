# PH-SAAS-T8.12AS.20.14U-PROD-BUILD-BACKEND-AMAZON-VALIDATION-PIPELINE-PROD-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14T / PH-20.14S-BIS / PH-20.14X / PH-20.14W / PH-20.14U
> Phase : PH-SAAS-T8.12AS.20.14U-PROD-BUILD (BUILD IMAGE PROD ONLY from-git)
> Environnement : PROD preparation (build local uniquement ; aucun push, aucun deploy)

## 1. Verdict

GO BUILD BACKEND AMAZON VALIDATION PIPELINE PROD READY PH-SAAS-T8.12AS.20.14U-PROD-BUILD

Image backend PROD immuable construite from-git depuis commit 1179c15 (option A : image PROD dediee, decision Ludovic ; pas de reutilisation de l image -dev). Tag v1.0.53-amazon-validation-pipeline-prod, Image ID sha256:8932a4558998..., OCI revision = 1179c1547de3c06db9c0accd2fd2179a87da7151, OCI version = v1.0.53-amazon-validation-pipeline-prod. Meme code que le v1.0.53 DEV valide (meme commit, meme taille 613906705 octets) ; seuls les labels OCI (version/created) different, d ou un Image ID distinct du DEV (377764c8). Worktree detache propre (HEAD 1179c15, porcelain=0). Tests pre-build OK (prisma generate + DMMF MAP_OK + tsc + ph2014u 17/17 + ph2014cbis 16/16 + ph2014c 15/15 + ph2014i 11/11 + ph2014o 9/9). Audit dist : observabilite jobsWorker (heartbeat, claim/done/fail jobId, OUTBOUND start/result, claim DISABLED), parseJobTypesEnv durci (raw == null), JOB_TYPES, sendOutboundEmailById, emailAddress insensitive (to.trim), isValidationEmail(subject), @map("to") (client genere) tous presents ; OUTBOUND_EMAIL_SEND not implemented = 0. Aucun push GHCR, aucun deploy, aucun manifest, aucune DB mutation, aucun email, aucun trigger. Runtime PROD reste v1.0.47, jobs-worker PROD reste absent, runtime DEV reste v1.0.53.

Prochaine phrase GO : GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE PROD PH-SAAS-T8.12AS.20.14U-PROD-PUSH (docker push v1.0.53-prod + pull-back digest), puis apply PROD GitOps (bump API + creer jobs-worker PROD) -> STOP avant trigger.

## 2. Sources relues

PH-20.14T (decision PROD READY), PH-20.14S-BIS (DEV READY), PH-20.14X (apply DEV), PH-20.14W (push DEV), PH-20.14U (source patch). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS. Memoire agent : project_amazon_validation_pipeline_gap.

## 3. Preflight

| Repo/service | HEAD/runtime | expected | dirty/ready | verdict |
|---|---|---|---|---|
| keybuzz-backend | HEAD 1179c15 | origin/main 1179c15 | non (hors amazon.routes.ts.bak untracked) | OK |
| keybuzz-infra | HEAD 3bc3472 | origin/main 3bc3472 | non | OK |
| PROD API (runtime) | v1.0.47-cross-env-guard-fix-prod | inchange | ready | OK (non touche) |
| PROD jobs-worker | ABSENT | absent (a creer phase apply) | - | OK |
| DEV API + jobs-worker (runtime) | v1.0.53-amazon-validation-pipeline-dev | inchange | ready | OK (non touche) |
| Bastion install-v3 / 46.62.171.61 | - | - | - | OK |

## 4. Tag collision

| Cible | etat | verdict |
|---|---|---|
| local docker v1.0.53-amazon-validation-pipeline-prod | ABSENT avant build | OK |
| GHCR v1.0.53-amazon-validation-pipeline-prod | ABSENT | OK |
| manifests infra k8s referencant ce tag | 0 | OK |

## 5. Tests pre-build (commit 1179c15, repo canonique)

| Test | resultat | verdict |
|---|---|---|
| prisma generate | EXIT 0 | OK |
| DMMF OutboundEmail.toAddress.dbName | "to" -> MAP_OK=true | OK |
| tsc --noEmit | TSC_OK | OK |
| ph2014u-jobtypes-hardening | 17 passed, 0 failed | OK |
| ph2014cbis-jobscope | 16 passed, 0 failed | OK |
| ph2014c-outboundEmail | 15 passed, 0 failed | OK |
| ph2014i-validation-address | 11 passed, 0 failed | OK |
| ph2014o-validation-address-casing | 9 passed, 0 failed | OK |

Tests via ts-node (scripts standalone PASS/FAIL, pas jest). Executes au commit identique 1179c15 (worktree sans node_modules ; HEAD = source bit-pour-bit). Aucune mutation DB, aucun SMTP reel.

## 6. Image

| Item | Valeur | Verdict |
|---|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-backend:v1.0.53-amazon-validation-pipeline-prod | OK |
| Image ID | sha256:8932a4558998203fa355e2c10f1c94a6a4defaa2dc137dfca8b5b661d1044407 | OK |
| Size | 613906705 octets (~586 MiB ; == DEV v1.0.53) | OK |
| OCI revision | 1179c1547de3c06db9c0accd2fd2179a87da7151 | OK (== 1179c15) |
| OCI version | v1.0.53-amazon-validation-pipeline-prod | OK |
| OCI created | 2026-05-26T10:28:09Z | OK |

docker build from worktree (context source 1179c15), build-args IMAGE_REVISION/IMAGE_VERSION/IMAGE_CREATED. Aucun push. Image ID distinct du DEV (377764c8) car labels OCI version/created differents ; le dist (code) est identique (meme commit, meme taille).

## 7. Markers (dist extrait, read-only)

| Marker | attendu | resultat | verdict |
|---|---|---|---|
| jobsWorker heartbeat | present | dist/workers/jobsWorker.js | OK |
| claim/done/fail jobId | present | dist/workers/jobsWorker.js | OK |
| OUTBOUND_EMAIL_SEND start/result | present | dist/workers/jobsWorker.js | OK |
| claim DISABLED guard | present | dist/workers/jobsWorker.js | OK |
| parseJobTypesEnv durci | raw == null | dist/modules/jobs/jobs.service.js | OK |
| JOB_TYPES scoping | present | 2 fichiers | OK |
| sendOutboundEmailById | present | 2 | OK |
| emailAddress insensitive (to.trim) | present | dist/modules/inbound/inbound.service.js | OK |
| isValidationEmail(subject) | present | dist/modules/inbound/inbound.service.js | OK |
| @map("to") (client genere) | present | node_modules/.prisma/client/schema.prisma | OK |
| "OUTBOUND_EMAIL_SEND not implemented" | absent | 0 | OK |

## 8. No side-effect

| Check | etat | verdict |
|---|---|---|
| GHCR v1.0.53-prod | ABSENT (non pousse) | OK |
| runtime PROD API | v1.0.47 inchange | OK |
| jobs-worker PROD | absent inchange | OK |
| runtime DEV | v1.0.53 inchange | OK |
| manifests infra modifies | 0 (infra dirty=0) | OK |
| kubectl apply / deploy / DB mutation / email / trigger | 0 | OK |
| worktree | retire proprement (git worktree remove sans --force) | OK |
| image locale PROD | conservee (8932a455) | OK |

## 9. Rollback

| Element | Rollback | Runtime impact |
|---|---|---|
| Runtime | N/A (aucune image deployee) | aucun |
| Image locale v1.0.53-prod | docker rmi v1.0.53-amazon-validation-pipeline-prod | aucun |
| Source | revert 1179c15 seulement si demande separee | aucun |
| Docs | revert commit rapport infra si erreur | aucun |

## 10. Prochaine phase

GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE PROD PH-SAAS-T8.12AS.20.14U-PROD-PUSH : docker push v1.0.53-amazon-validation-pipeline-prod + pull-back digest match (config digest == Image ID local 8932a455). Puis GO APPLY PROD GitOps : bump deployment.yaml API PROD v1.0.47 -> v1.0.53-prod + creer deployment-jobs-worker.yaml PROD (command jobsWorker.js, JOB_TYPES=OUTBOUND_EMAIL_SEND, SMTP inline mail-core-01 49.13.35.167:25 secure=false, envFrom db/secrets/vault-token/amazon-spapi-creds, imagePullSecrets ghcr) -> apply -> rollout -> verifier digest + no unintended processing -> STOP avant trigger. Re-trigger PROD ulterieur = send-validation authentifie reel (KEYBUZZ_DEV_MODE=false PROD), 1 adresse a la fois, apres verification routage webhook mail-core PROD. Hygiene separee : upgrade amazon-orders/items-worker hors v1.0.40. Ne pas promouvoir PROD sans GO explicite.

Phrase cible : GO BUILD BACKEND AMAZON VALIDATION PIPELINE PROD READY PH-SAAS-T8.12AS.20.14U-PROD-BUILD

STOP.
