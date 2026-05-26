# PH-SAAS-T8.12AS.20.14X2-BUILD-BACKEND-AMAZON-VALIDATION-PIPELINE-DEV-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; reference PH-20.14W (source patch)
> Phase : PH-SAAS-T8.12AS.20.14X2 (BUILD IMAGE ONLY, DEV)
> Environnement : DEV (aucun push GHCR, aucun deploy, aucune mutation runtime/DB)

## 1. Verdict

GO BUILD BACKEND AMAZON VALIDATION PIPELINE DEV READY PH-SAAS-T8.12AS.20.14X2

Image locale v1.0.54-amazon-validation-pipeline-dev construite from-git depuis le commit d27f4a5 (PH-20.14W). Worktree detache propre, OCI revision=d27f4a5 complet, OCI version=v1.0.54-amazon-validation-pipeline-dev. Tests pre-build OK (ph2014w 10/10 + regressions), tsc OK, prisma generate OK, DMMF MAP_OK. Dist verifie : real inbound valide l'adresse, resolution emailAddress insensitive, updateMany bloquant casse absent, self-test preserve. Aucun push GHCR, aucun deploy, aucun manifest, aucun trigger. Worktree retire sans --force. STOP.

## 2. Preflight

| Repo/service | HEAD/runtime | expected | dirty/ready | verdict |
|---|---|---|---|---|
| keybuzz-backend | HEAD=origin=d27f4a5 | d27f4a5 | .bak cruft only | OK |
| keybuzz-infra | HEAD=origin=81b2fdb | clean | clean | OK |
| API/jobs-worker DEV | v1.0.53-amazon-validation-pipeline-dev | v1.0.53 | ready | OK (read-only) |
| API/jobs-worker PROD | v1.0.53-amazon-validation-pipeline-prod | v1.0.53 | ready | OK (read-only) |
| Bastion | install-v3 / 46.62.171.61 | install-v3 | - | OK |

## 3. Collision tag v1.0.54-amazon-validation-pipeline-dev

| Cible | etat | verdict |
|---|---|---|
| Docker local (avant build) | ABSENT | OK |
| GHCR remote | ABSENT | OK |
| manifests infra k8s | aucune reference v1.0.54 | OK |

## 4. Tests pre-build (dans worktree detache)

| Test | attendu | resultat |
|---|---|---|
| prisma generate | client genere | OK |
| DMMF OutboundEmail.toAddress | dbName=to | MAP_OK |
| tsc --noEmit | 0 erreur | EXIT 0 |
| ph2014w-real-inbound-validation | 10/10 | 10/10 |
| ph2014o-validation-address-casing | 9/9 | 9/9 |
| ph2014i-validation-address | 11/11 | 11/11 |
| ph2014u-jobtypes-hardening | 17/17 | 17/17 |
| ph2014c-outboundEmail | 15/15 | 15/15 |
| ph2014cbis-jobscope | 16/16 | 16/16 |

NB : tests executes dans le worktree (node_modules symlinke vers canonical au meme commit ; DATABASE_URL placeholder pour prisma generate, les tests sont des fonctions pures sans DB). Symlink retire avant le docker build.

## 5. Image

| Attribut | valeur |
|---|---|
| tag | ghcr.io/keybuzzio/keybuzz-backend:v1.0.54-amazon-validation-pipeline-dev |
| image ID | sha256:3c826354f164f18d9937de1087910de6086ac97b43c301f2be549fa2174a828f |
| size | 614MB |
| OCI revision | d27f4a51e6052121b03afcc2c302b76bf006ed1b |
| OCI version | v1.0.54-amazon-validation-pipeline-dev |
| OCI created | 2026-05-26T13:31:17Z |
| OCI source | https://github.com/keybuzzio/keybuzz-backend |
| OCI title | keybuzz-backend |
| push GHCR | AUCUN (image locale uniquement) |

## 6. Markers dist

| Marker | attendu | resultat | verdict |
|---|---|---|---|
| real inbound validates address (log marked VALIDATED) | present | 1 | OK |
| buildRealInboundValidationData (validationStatus/marketplaceStatus/pipelineStatus) | present | 3 | OK |
| emailAddress exact insensitive (svc) | present | 4 | OK |
| decideValidationAddress (svc) | present | 6 | OK |
| webhook to: payload.to | present | 4 | OK |
| webhook emailAddress insensitive (lastInboundAt) | present | 2 | OK |
| update count warning si 0 | present | 1 | OK |
| self-test resolved by exact emailAddress | present | 1 | OK |
| jobsWorker observability (heartbeat) | present | 2 | OK |
| JOB_TYPES (jobsWorker) | present | 12 | OK |
| sendOutboundEmailById | present | jobsWorker.js:2 | OK |
| @map("to") via DMMF dans l'image | dbName=to | OK | OK |
| inboundAddress.updateMany bloquant (svc) | absent | 0 | OK |
| marketplace.toUpperCase() executable (svc) | absent | 1 (ligne de COMMENTAIRE seulement) | OK |
| OUTBOUND_EMAIL_SEND not implemented | absent | 0 | OK |

## 7. No side-effect

| Signal | etat |
|---|---|
| docker push GHCR | aucun (v1.0.54 ABSENT remote) |
| deploy / kubectl apply | aucun |
| manifest GitOps modifie | aucun (infra clean) |
| runtime DEV | inchange v1.0.53-amazon-validation-pipeline-dev |
| runtime PROD | inchange v1.0.53-amazon-validation-pipeline-prod |
| DB mutation / trigger / email | aucun |
| worktree | retire sans --force (seul worktree canonical restant) |

## 8. Rollback

| Niveau | action |
|---|---|
| Image locale | docker rmi de v1.0.54-amazon-validation-pipeline-dev (locale uniquement, jamais poussee) |
| Runtime | aucun (rien deploye) ; PROD/DEV restent v1.0.53 |
| Source/infra | inchanges (d27f4a5 / 81b2fdb deja sur origin) |

## 9. Prochaine phase

GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE DEV PH-SAAS-T8.12AS.20.14Y

Push GHCR de v1.0.54-amazon-validation-pipeline-dev + verification pull-back digest, puis apply DEV GitOps (bump API + jobs-worker DEV v1.0.53 -> v1.0.54), re-trigger DEV pour prouver PENDING -> VALIDATED via le chemin real-inbound, avant promotion PROD (image -prod) sur GO.

Phrase cible : GO BUILD BACKEND AMAZON VALIDATION PIPELINE DEV READY PH-SAAS-T8.12AS.20.14X2

STOP.
