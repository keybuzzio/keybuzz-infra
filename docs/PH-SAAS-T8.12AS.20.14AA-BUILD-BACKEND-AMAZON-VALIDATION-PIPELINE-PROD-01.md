# PH-SAAS-T8.12AS.20.14AA-BUILD-BACKEND-AMAZON-VALIDATION-PIPELINE-PROD-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; reference PH-20.14Z2 (verify DEV) / PH-20.14W (source patch)
> Phase : PH-SAAS-T8.12AS.20.14AA (BUILD IMAGE PROD ONLY)
> Environnement : PROD preparation (aucun push GHCR, aucun deploy, aucune mutation)

## 1. Verdict

GO BUILD BACKEND AMAZON VALIDATION PIPELINE PROD READY PH-SAAS-T8.12AS.20.14AA

Image PROD dediee v1.0.54-amazon-validation-pipeline-prod construite from-git depuis le commit d27f4a5 (meme code que DEV prouve en PH-20.14Z2). Worktree detache propre, OCI revision=d27f4a5 complet, OCI version=v1.0.54-amazon-validation-pipeline-prod. Tests pre-build OK (ph2014w 10/10 + regressions), tsc OK, prisma generate OK, DMMF MAP_OK. Dist verifie : real-inbound valide l adresse, resolution emailAddress insensitive, updateMany bloquant casse absent, self-test preserve, @map(to). Aucun push GHCR, aucun deploy, aucun manifest, aucun trigger. Worktree retire sans --force. STOP.

## 2. Preflight

| Repo/service | HEAD/runtime | expected | dirty/ready | verdict |
|---|---|---|---|---|
| keybuzz-backend | HEAD=origin=d27f4a5 | d27f4a5 | .bak cruft only | OK |
| keybuzz-infra | HEAD=origin=8caf9a7 | clean | clean | OK |
| API/jobs-worker DEV | v1.0.54-amazon-validation-pipeline-dev | v1.0.54 | ready | OK (read-only) |
| API/jobs-worker PROD | v1.0.53-amazon-validation-pipeline-prod | v1.0.53-prod | ready | OK (read-only) |
| Bastion | install-v3 / 46.62.171.61 | install-v3 | - | OK |

## 3. Collision tag v1.0.54-amazon-validation-pipeline-prod

| Cible | etat | verdict |
|---|---|---|
| Docker local (avant build) | ABSENT | OK |
| GHCR remote | ABSENT | OK |
| manifests infra k8s | aucune reference v1.0.54-prod | OK |

## 4. Tests pre-build (worktree detache d27f4a5)

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

NB : tests dans le worktree (node_modules symlinke canonical au meme commit ; DATABASE_URL placeholder pour prisma generate ; tests = fonctions pures sans DB). Symlink retire avant docker build.

## 5. Image

| Attribut | valeur |
|---|---|
| tag | ghcr.io/keybuzzio/keybuzz-backend:v1.0.54-amazon-validation-pipeline-prod |
| image ID | sha256:831cc88204b4a80d4389a6386472b1eb7d2d1322e78de369a736bfeed181a897 |
| size | 614MB |
| OCI revision | d27f4a51e6052121b03afcc2c302b76bf006ed1b |
| OCI version | v1.0.54-amazon-validation-pipeline-prod |
| OCI created | 2026-05-26T14:58:48Z |
| OCI source | https://github.com/keybuzzio/keybuzz-backend |
| OCI title | keybuzz-backend |
| push GHCR | AUCUN (image locale uniquement) |

NB : meme code/dist que l image DEV v1.0.54 (Image ID 3c826354) ; Image ID distinct (831cc882) car labels OCI version/created differents -- meme pattern que v1.0.53-dev/-prod.

## 6. Markers dist

| Marker | attendu | resultat | verdict |
|---|---|---|---|
| real inbound validates address (marked VALIDATED) | present | 1 | OK |
| buildRealInboundValidationData (validationStatus/marketplaceStatus/pipelineStatus) | present | 3 | OK |
| emailAddress exact insensitive (svc) | present | 4 | OK |
| self-test resolved by exact emailAddress | present | 1 | OK |
| webhook to: payload.to | present | 4 | OK |
| webhook lastInboundAt warn si 0 | present | 1 | OK |
| jobsWorker observability (heartbeat) | present | 2 | OK |
| JOB_TYPES (jobsWorker) | present | 12 | OK |
| sendOutboundEmailById | present | jobsWorker.js:2 | OK |
| @map("to") via DMMF dans l image | dbName=to | OK | OK |
| inboundAddress.updateMany bloquant (svc) | absent | 0 | OK |
| OUTBOUND_EMAIL_SEND not implemented | absent | 0 | OK |

## 7. No side-effect

| Signal | etat |
|---|---|
| docker push GHCR | aucun (v1.0.54-prod ABSENT remote) |
| deploy / kubectl | aucun |
| manifest GitOps modifie | aucun (infra clean) |
| runtime DEV | inchange v1.0.54-amazon-validation-pipeline-dev |
| runtime PROD | inchange v1.0.53-amazon-validation-pipeline-prod |
| DB mutation / trigger / email | aucun |
| worktree | retire sans --force (seul worktree canonical restant) |

## 8. Rollback

| Niveau | action |
|---|---|
| Image locale | docker rmi v1.0.54-amazon-validation-pipeline-prod (locale uniquement, jamais poussee) |
| Runtime | aucun (rien deploye) ; PROD reste v1.0.53-prod, DEV v1.0.54-dev |
| Source/infra | inchanges (d27f4a5 / 8caf9a7 sur origin) |

## 9. Prochaine phase

GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE PROD PH-SAAS-T8.12AS.20.14AB

Push GHCR de v1.0.54-amazon-validation-pipeline-prod + pull-back digest match, puis apply PROD GitOps (deployment.yaml API + deployment-jobs-worker.yaml PROD v1.0.53-prod -> v1.0.54-prod), rollout, verifier digest + no unintended processing. Apres promotion, un vrai message Amazon (ou self-test) validera l adresse PROD ecomlg-001 FR (cmmsdn4if / 4xfub8) via le chemin real-inbound, debloquant le guard outbound (objectif P0 KEY-323).

Phrase cible : GO BUILD BACKEND AMAZON VALIDATION PIPELINE PROD READY PH-SAAS-T8.12AS.20.14AA

STOP.
