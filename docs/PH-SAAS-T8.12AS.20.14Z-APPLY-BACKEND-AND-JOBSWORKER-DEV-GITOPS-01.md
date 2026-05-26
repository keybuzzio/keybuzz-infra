# PH-SAAS-T8.12AS.20.14Z-APPLY-BACKEND-AND-JOBSWORKER-DEV-GITOPS-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; reference PH-20.14Y (push) / PH-20.14X2 (build) / PH-20.14W (source patch)
> Phase : PH-SAAS-T8.12AS.20.14Z (APPLY GITOPS DEV)
> Environnement : DEV uniquement (PROD intact)

## 1. Verdict

GO APPLY BACKEND AND JOBSWORKER DEV GITOPS READY PH-SAAS-T8.12AS.20.14Z

API keybuzz-backend DEV + jobs-worker DEV deployes via GitOps strict sur v1.0.54-amazon-validation-pipeline-dev (revision d27f4a5, digest GHCR f1a6e19d). manifest=last-applied=runtime=digest verifie sur les deux. jobs-worker conserve JOB_TYPES=OUTBOUND_EMAIL_SEND + SMTP DEV 49.13.35.167:25 secure=false + command jobsWorker.js. No unintended processing : counts Job/OutboundEmail inchanges, AMAZON_POLL worker-1=0, aucun trigger/email/SMTP. PROD intact v1.0.53-prod. STOP avant test real-inbound DEV.

## 2. Preflight

| Repo/service | branche/runtime | HEAD/digest | dirty/ready | verdict |
|---|---|---|---|---|
| keybuzz-infra | main | bbe8a90=origin (avant) | clean | OK |
| keybuzz-backend | main | d27f4a5=origin | clean | OK |
| GHCR v1.0.54-dev | - | config 3c826354 / manifest f1a6e19d | present | OK |
| API DEV | v1.0.53 (avant) | @5b893934 | ready, restarts=0 | OK |
| jobs-worker DEV | v1.0.53 (avant) | @5b893934 | ready, restarts=0 | OK |
| PROD | v1.0.53-prod | - | intact | OK |

## 3. Runtime before / after

| Service | before image | after image | after imageID digest | ready | restarts |
|---|---|---|---|---|---|
| API keybuzz-backend DEV | v1.0.53-dev (@5b893934) | v1.0.54-dev | @sha256:f1a6e19d5433...cc9 | true | 0 |
| jobs-worker DEV | v1.0.53-dev (@5b893934) | v1.0.54-dev | @sha256:f1a6e19d5433...cc9 | true | 0 |

Anciens pods v1.0.53 termines ; seuls les pods v1.0.54 tournent. jobs-worker startup : "[JobsWorker] Starting worker worker-1 image=unknown types=OUTBOUND_EMAIL_SEND jobTypesRaw=OUTBOUND_EMAIL_SEND pollMs=2000" (image=unknown = env IMAGE_VERSION non injectee, benin). API boot : "Server listening at :4000", 0 erreur Prisma.

## 4. Manifests

| Fichier | avant | apres | autres champs |
|---|---|---|---|
| k8s/keybuzz-backend-dev/deployment.yaml L32 | v1.0.53-dev | v1.0.54-dev (# PH-20.14Z, rollback v1.0.53) | command API/ports/envFrom/probes inchanges |
| k8s/keybuzz-backend-dev/deployment-jobs-worker.yaml L32 | v1.0.53-dev | v1.0.54-dev (# PH-20.14Z, rollback v1.0.53) | command jobsWorker.js + JOB_TYPES=OUTBOUND_EMAIL_SEND + SMTP 49.13.35.167:25 secure=false + envFrom/imagePullSecrets/probes/resources inchanges |

Seules les 2 lignes image: modifiees. Aucune modif PROD, keybuzz-api, secrets, SMTP, command, JOB_TYPES.

## 5. Dry-run

| Commande | resultat |
|---|---|
| apply --dry-run=client API | deployment.apps/keybuzz-backend configured (dry run) |
| apply --dry-run=server API | deployment.apps/keybuzz-backend configured (server dry run) |
| apply --dry-run=client jobs-worker | deployment.apps/jobs-worker configured (dry run) |
| apply --dry-run=server jobs-worker | deployment.apps/jobs-worker configured (server dry run) |
| lignes image actives | 2 = v1.0.54 uniquement (matches v1.0.5x restants = commentaires rollback/doc) |
| JOB_TYPES / SMTP dans jobs-worker | present |

## 6. Rollout

| Service | apply | rollout |
|---|---|---|
| API keybuzz-backend | deployment configured | successfully rolled out |
| jobs-worker | deployment configured | successfully rolled out |

GitOps strict : commit infra ba19ff3 (manifests) pousse AVANT apply ; kubectl apply -f uniquement (aucun set image/patch/edit/rollout restart).

## 7. Digest

| Item | valeur |
|---|---|
| GHCR manifest digest | sha256:f1a6e19d5433cde7e5ac416fcd6ddc2cd6c8bf017311e31075ed4f604cc20cc9 |
| runtime imageID (API + jobs-worker) | sha256:f1a6e19d5433cde7e5ac416fcd6ddc2cd6c8bf017311e31075ed4f604cc20cc9 |
| manifest = last-applied = runtime | v1.0.54-amazon-validation-pipeline-dev (les trois) |
| match | OK (runtime digest == GHCR manifest digest) |

## 8. No unintended processing

| Signal | before | after | verdict |
|---|---|---|---|
| Job OUTBOUND_EMAIL_SEND | DONE 13 / FAILED 16 | DONE 13 / FAILED 16 | INCHANGE |
| OutboundEmail | PENDING 1 / FAILED 14 / SENT 13 | PENDING 1 / FAILED 14 / SENT 13 | INCHANGE |
| AMAZON_POLL lockedBy worker-1 | 0 | 0 | OK |
| jobs-worker (nouveau pod) | - | heartbeat polls=30 claimed=0, 0 claim/done/result/SMTP/send | startup only |
| SMTP send / email self-test / trigger validation | - | 0 | OK |
| job inattendu | - | 0 | OK |

## 9. AI feature parity / anti-regression

| Garantie | etat |
|---|---|
| guard outbound validationStatus | intact (lit validationStatus='VALIDATED' marketplace='amazon' minuscule) |
| From Amazon contract (isAmazonForwardedEmail) | intact |
| real inbound validation logic (PH-20.14W) | present au runtime (image v1.0.54) |
| jobs-worker scope OUTBOUND_EMAIL_SEND | intact (startup confirme) |
| AMAZON_POLL claime par worker-1 | 0 (aucune interference pollers Amazon) |
| retry outbound | aucun |
| fake webhook / email / job | aucun |
| PH-20.11C / PH-20.12B / PH-20.13B | preserves (aucun fichier touche) |
| PH-20.13B Client push | reste suspendu (hors scope) |

## 10. Rollback

| Niveau | action |
|---|---|
| Manifest | git revert ba19ff3 (image v1.0.53) + kubectl apply -f (rollback documente dans le commentaire image) |
| Image v1.0.53 | toujours sur GHCR (digest 5b893934), redeployable |
| PROD | intact (aucune action) |

## 11. Prochaine phase

GO VERIFY REAL INBOUND VALIDATES AMAZON ADDRESS DEV PH-SAAS-T8.12AS.20.14Z2

Test real-inbound DEV (read-only puis trigger controle) : prouver qu'un message Amazon (self-test ou vrai message via mail-core) passe une adresse inbound DEV PENDING a VALIDATED via le chemin real-inbound (updateMarketplaceStatusIfAmazon -> resolution emailAddress exact -> validationStatus VALIDATED). Puis, sur GO, promotion PROD : build image v1.0.54-amazon-validation-pipeline-prod from-git d27f4a5, push GHCR, apply PROD GitOps (API + jobs-worker), re-trigger PROD.

Phrase cible : GO APPLY BACKEND AND JOBSWORKER DEV GITOPS READY PH-SAAS-T8.12AS.20.14Z

STOP.
