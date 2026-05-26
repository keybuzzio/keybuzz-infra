# PH-SAAS-T8.12AS.20.14V-BUILD-BACKEND-AMAZON-VALIDATION-PIPELINE-DEV-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14U / PH-20.14S-RCA / PH-20.14R
> Phase : PH-SAAS-T8.12AS.20.14V (BUILD ONLY image backend DEV from-git)
> Environnement : DEV (build local uniquement ; aucun push, aucun deploy)

## 1. Verdict

GO BUILD BACKEND AMAZON VALIDATION PIPELINE DEV READY PH-SAAS-T8.12AS.20.14V

Image backend DEV immuable construite from-git depuis commit 1179c15 (PH-20.14U : observabilite jobsWorker + durcissement JOB_TYPES). Tag v1.0.53-amazon-validation-pipeline-dev, Image ID sha256:377764c8bcb2, OCI revision = 1179c1547de3c06db9c0accd2fd2179a87da7151, OCI version = v1.0.53-amazon-validation-pipeline-dev. Worktree detache propre (HEAD 1179c15, dirty=0). Tests pre-build OK (tsc + DMMF MAP_OK + ph2014u 17/17 + ph2014cbis 16/16 + ph2014c 15/15 + ph2014i 11/11 + ph2014o 9/9). Audit dist : observabilite jobsWorker presente (heartbeat, claim/done/fail jobId, OUTBOUND_EMAIL_SEND start/result, claim DISABLED guard), parseJobTypesEnv durci (raw == null), JOB_TYPES, sendOutboundEmailById, @map("to"), resolution emailAddress case-insensitive, garde isValidationEmail(subject) ; ancien pre-filtre toUpperCase = 0 ; not implemented OUTBOUND = 0. Aucun push GHCR, aucun deploy, aucun manifest, aucune DB mutation, aucun email, aucun trigger. Runtime DEV reste v1.0.52, PROD intact (v1.0.47).

Prochaine phrase GO : GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE DEV PH-SAAS-T8.12AS.20.14W (docker push v1.0.53 + pull-back digest), puis apply API + jobs-worker DEV -> re-trigger PH-20.14S-bis sous observabilite.

## 2. Sources relues

PH-20.14U (source patch observabilite + JOB_TYPES), PH-20.14S-RCA (gap observabilite), PH-20.14R (deploy v1.0.52). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS. Memoire agent : project_amazon_validation_pipeline_gap.

## 3. Preflight (repo / runtime)

| Repo/service | branche | HEAD/runtime | origin/digest | dirty/ready | verdict |
|---|---|---|---|---|---|
| keybuzz-backend | main | 1179c15 | origin/main 1179c15 | non (hors amazon.routes.ts.bak untracked) | OK |
| keybuzz-infra | main | 7ad4f7f | origin/main 7ad4f7f | non | OK |
| API DEV (runtime) | - | v1.0.52 | digest 4e60d0e8 | ready | OK (non touche) |
| jobs-worker DEV (runtime) | - | v1.0.52 | digest 4e60d0e8 | ready | OK (non touche) |
| PROD backend | - | v1.0.47-cross-env-guard-fix-prod | - | - | INTACT |
| Bastion install-v3 / 46.62.171.61 | - | - | - | - | OK |

## 4. Tag collision

| Cible | etat | verdict |
|---|---|---|
| local docker v1.0.53-amazon-validation-pipeline-dev | ABSENT | OK |
| GHCR v1.0.53-amazon-validation-pipeline-dev | ABSENT | OK |
| manifests infra k8s referencant v1.0.53 | 0 | OK |

## 5. Worktree build-from-git

| Worktree | HEAD | dirty | verdict |
|---|---|---|---|
| /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.14V-.../keybuzz-backend | 1179c15 | 0 | OK |

git worktree add --detach @ 1179c15 ; porcelain=0 ; package-lock present. NB : 9 fichiers *.bak/*.backup sont du cruft TRACKE pre-existant (committe historiquement, deja dans v1.0.52) ; tsconfig include src/**/*.ts ne les compile pas ; non bloquant (worktree clean, porcelain=0). L untracked amazon.routes.ts.bak du repo canonique n est PAS copie dans le worktree neuf.

## 6. Tests pre-build (commit 1179c15)

| Test | commande | resultat | verdict |
|---|---|---|---|
| prisma generate | npx prisma generate | EXIT 0 | OK |
| DMMF mapping | OutboundEmail.toAddress.dbName | "to" -> MAP_OK=true | OK |
| typecheck | npx tsc --noEmit -p tsconfig.json | TSC_OK | OK |
| PH-20.14U (durcissement) | tests/ph2014u-jobtypes-hardening.test.ts | 17 passed, 0 failed | OK |
| PH-20.14C-BIS (jobscope) | tests/ph2014cbis-jobscope.test.ts | 16 passed, 0 failed | OK |
| PH-20.14C (outboundEmail) | tests/ph2014c-outboundEmail.test.ts | 15 passed, 0 failed | OK |
| PH-20.14I (resolution) | tests/ph2014i-validation-address.test.ts | 11 passed, 0 failed | OK |
| PH-20.14O (casse) | tests/ph2014o-validation-address-casing.test.ts | 9 passed, 0 failed | OK |

Tests executes dans le repo canonique au commit identique 1179c15 (worktree sans node_modules ; HEAD verifie = 1179c15 = source equivalente bit-pour-bit). Aucune mutation DB, aucun SMTP reel.

## 7. Image

| Item | Valeur | Verdict |
|---|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-backend:v1.0.53-amazon-validation-pipeline-dev | OK |
| Image ID | sha256:377764c8bcb24823a8bf9e059913c626cdc49792e8a0632fb6fc86fc7406d268 | OK |
| Size | 613906705 octets (~586 MiB) | OK |
| OCI revision | 1179c1547de3c06db9c0accd2fd2179a87da7151 | OK (== 1179c15) |
| OCI version | v1.0.53-amazon-validation-pipeline-dev | OK |
| OCI created | 2026-05-26T09:17:06Z | OK |

docker build from worktree (context source 1179c15), build-args IMAGE_REVISION/VERSION/CREATED. Aucun push.

## 8. Markers (dist extrait, read-only)

| Marker | attendu | resultat | verdict |
|---|---|---|---|
| jobsWorker heartbeat | present | "heartbeat worker=" | OK |
| jobsWorker claim/done/fail jobId | present | claim jobId= / done jobId= / fail jobId= | OK |
| OUTBOUND_EMAIL_SEND start/result | present | start + result | OK |
| claim DISABLED guard (JOB_TYPES vide) | present | "claim DISABLED" | OK |
| parseJobTypesEnv durci | raw == null | present | OK |
| JOB_TYPES scoping | present | 2 fichiers | OK |
| sendOutboundEmailById | present | 2 | OK |
| @map("to") (client genere) | present | schema.prisma:538 toAddress @map("to") | OK |
| resolution emailAddress insensitive | present | equals: to.trim() | OK |
| garde isValidationEmail(subject) | present | present | OK |
| ancien pre-filtre marketplace.toUpperCase() dans inbound.service.js | 0 | 0 | OK |
| "OUTBOUND_EMAIL_SEND not implemented" | absent | 0 | OK |

NB : le segment de log "Starting worker ... image=" est compile en concatenations distinctes (TS template) ; le grep sur une ligne ne le matche pas, mais les autres logs (heartbeat/claim/done/fail/OUTBOUND/claim DISABLED) confirment que l observabilite PH-20.14U est bien dans le dist.

## 9. No side-effect

| Check | etat | verdict |
|---|---|---|
| docker push / GHCR v1.0.53 | ABSENT | OK |
| deploy / kubectl apply / manifest modifie | 0 (infra k8s dirty=0) | OK |
| runtime DEV API + jobs-worker | v1.0.52 inchange | OK |
| PROD | v1.0.47 intact | OK |
| DB mutation / email / trigger | 0 | OK |
| container audit / worktree | nettoyes (0 restant ; worktree remove sans --force) | OK |
| image locale v1.0.53 | conservee (377764c8bcb2) | OK |

## 10. Rollback

| Element | Rollback | Runtime impact |
|---|---|---|
| Runtime | N/A (aucune image deployee) | aucun |
| Image locale v1.0.53 | docker rmi v1.0.53-amazon-validation-pipeline-dev | aucun |
| Source | revert 1179c15 seulement si demande separee | aucun |
| Docs | revert commit rapport infra si erreur | aucun |

## 11. Prochaine phase

GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE DEV PH-SAAS-T8.12AS.20.14W (docker push v1.0.53 + pull-back digest match), puis GO APPLY ... (deploy API + jobs-worker DEV sur v1.0.53) -> re-trigger PH-20.14S-bis SOUS observabilite (logs claim/done/heartbeat identifieront le consommateur reel + decision d envoi). Phase config separee : upgrader amazon-orders/items-worker hors v1.0.40 + fixer JOB_TYPES. Ne pas deployer v1.0.48/49/50/51/52 en finalite (v1.0.53 cible). Ne pas promouvoir PROD, ne pas retry outbound, ne pas flip DB.

Phrase cible : GO BUILD BACKEND AMAZON VALIDATION PIPELINE DEV READY PH-SAAS-T8.12AS.20.14V

STOP.
