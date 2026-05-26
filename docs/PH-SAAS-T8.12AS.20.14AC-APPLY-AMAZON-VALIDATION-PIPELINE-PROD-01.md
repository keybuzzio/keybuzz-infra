# PH-SAAS-T8.12AS.20.14AC-APPLY-AMAZON-VALIDATION-PIPELINE-PROD-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; reference PH-20.14AB (push PROD) / PH-20.14Z2 (verify DEV) / PH-20.14W (source patch)
> Phase : PH-SAAS-T8.12AS.20.14AC (APPLY GITOPS PROD)
> Environnement : PROD (mutation runtime API + jobs-worker ; DEV intact)

## 1. Verdict

GO APPLY AMAZON VALIDATION PIPELINE PROD READY PH-SAAS-T8.12AS.20.14AC

API keybuzz-backend PROD + jobs-worker PROD deployes via GitOps strict sur v1.0.54-amazon-validation-pipeline-prod (revision d27f4a5, digest GHCR 060abd98). manifest=last-applied=runtime=digest verifie sur les deux. jobs-worker conserve JOB_TYPES=OUTBOUND_EMAIL_SEND + SMTP 49.13.35.167:25 secure=false + command jobsWorker.js. No unintended processing : Job/OutboundEmail/MarketplaceOutboundMessage VIDES before==after, 11 adresses PENDING inchangees, aucun trigger/email/SMTP. Le patch real-inbound PH-20.14W est maintenant ACTIF en PROD. STOP avant test/validation.

## 2. Preflight

| Repo/service | branche/runtime | HEAD/digest | dirty/ready | verdict |
|---|---|---|---|---|
| keybuzz-infra | main | ce48885=origin (avant) | clean | OK |
| keybuzz-backend | main | d27f4a5=origin | clean | OK |
| GHCR v1.0.54-prod | - | digest 060abd98 (verifie) | present | OK |
| API PROD (avant) | v1.0.53-amazon-validation-pipeline-prod | @18f54575 | ready, restarts=0 | OK |
| jobs-worker PROD (avant) | v1.0.53-amazon-validation-pipeline-prod | @18f54575 | ready, restarts=0 | OK |
| DEV | v1.0.54-amazon-validation-pipeline-dev | - | intact | OK |

## 3. Snapshot PROD before

| Signal | before |
|---|---|
| Job OUTBOUND_EMAIL_SEND | VIDE |
| OutboundEmail | VIDE |
| MarketplaceOutboundMessage | VIDE |
| inbound addresses validationStatus | PENDING 11 / VALIDATED 0 |
| ecomlg-001 FR 4xfub8 (cmmsdn4if) | PENDING / PENDING / PENDING, lastInboundAt null |

## 4. Manifests

| Fichier | avant | apres | autres champs |
|---|---|---|---|
| k8s/keybuzz-backend-prod/deployment.yaml L27 | v1.0.53-prod | v1.0.54-prod (# PH-20.14AC, rollback v1.0.53) | command API/ports/envFrom inchanges |
| k8s/keybuzz-backend-prod/deployment-jobs-worker.yaml L33 | v1.0.53-prod | v1.0.54-prod (# PH-20.14AC, rollback v1.0.53) | command jobsWorker.js + JOB_TYPES=OUTBOUND_EMAIL_SEND + SMTP 49.13.35.167:25 secure=false + envFrom/imagePullSecrets/probes/namespace inchanges |

Seules les 2 lignes image: modifiees. Aucune modif DEV, keybuzz-api, secrets, amazon workers, backfill-scheduler.

## 5. Dry-run

| Commande | resultat |
|---|---|
| apply --dry-run=client API | deployment.apps/keybuzz-backend configured (dry run) |
| apply --dry-run=server API | configured (server dry run) |
| apply --dry-run=client jobs-worker | deployment.apps/jobs-worker configured (dry run) |
| apply --dry-run=server jobs-worker | configured (server dry run) |
| image lines v1.0.54-prod | 2 ; 0 image active v1.0.54-dev/v1.0.47-53 ; 0 latest ; JOB_TYPES + SMTP + namespace PROD present |

## 6. Rollout API PROD

| Etape | resultat |
|---|---|
| kubectl apply -f deployment.yaml | deployment.apps/keybuzz-backend configured |
| rollout status | successfully rolled out |
| nouveau pod | keybuzz-backend-5985bc8597-hqvnn ready, restarts=0 |
| API boot | Server listening :4000, 0 erreur Prisma (warning vault-ca.pem benin pre-existant) |

## 7. Rollout jobs-worker PROD

| Etape | resultat |
|---|---|
| kubectl apply -f deployment-jobs-worker.yaml | deployment.apps/jobs-worker configured |
| rollout status | successfully rolled out |
| nouveau pod | jobs-worker-58d5647cb6-2vj8x ready, restarts=0 |
| startup | "[JobsWorker] Starting worker worker-1 image=unknown types=OUTBOUND_EMAIL_SEND jobTypesRaw=OUTBOUND_EMAIL_SEND pollMs=2000" (image=unknown benin, env IMAGE_VERSION non injectee) |

GitOps strict : commit infra bafc540 (manifests) pousse AVANT apply ; kubectl apply -f uniquement (aucun set image/patch/edit/rollout restart).

## 8. Snapshot AFTER (no unintended processing)

| Signal | before | after | verdict |
|---|---|---|---|
| Job OUTBOUND_EMAIL_SEND | VIDE | VIDE | INCHANGE |
| OutboundEmail | VIDE | VIDE | INCHANGE |
| MarketplaceOutboundMessage | VIDE | VIDE | INCHANGE |
| inbound addresses validationStatus | PENDING 11 / VALIDATED 0 | PENDING 11 / VALIDATED 0 | INCHANGE |
| ecomlg-001 FR 4xfub8 | PENDING | PENDING | INCHANGE (a valider via real-inbound) |
| jobs-worker (nouveau pod) | - | 0 claim / 0 done / 0 SMTP / 0 send | startup only |
| SMTP send / email / trigger / message marketplace | - | 0 | OK |

## 9. Runtime digest

| Service | manifest | last-applied | runtime | imageID digest | ready | verdict |
|---|---|---|---|---|---|---|
| API keybuzz-backend PROD | v1.0.54-prod | v1.0.54-prod | v1.0.54-prod | sha256:060abd98...bda3 | true | OK |
| jobs-worker PROD | v1.0.54-prod | v1.0.54-prod | v1.0.54-prod | sha256:060abd98...bda3 | true | OK |

runtime imageID == GHCR manifest digest 060abd98 sur les deux.

## 10. AI feature parity / anti-regression

| Garantie | etat |
|---|---|
| guard outbound validationStatus | intact (lit validationStatus='VALIDATED', marketplace='amazon' minuscule) |
| From Amazon contract (isAmazonForwardedEmail) | intact |
| real inbound validation logic (PH-20.14W) | ACTIF en PROD (image v1.0.54-prod) |
| SP-API messaging | non active (hors scope cette phase) |
| jobs-worker scope OUTBOUND_EMAIL_SEND | intact (startup confirme) |
| amazon-orders/items-worker | non modifies (v1.0.40, hors scope) |
| backfill-scheduler | hors scope (non touche) |
| retry outbound | aucun |
| fake webhook / email / job | aucun |
| PH-20.11C / PH-20.12B / PH-20.13B | preserves |

## 11. No fake metrics / no fake events

| Signal | etat |
|---|---|
| fake metric / event / webhook | 0 |
| fake OutboundEmail / Job | 0 |
| DB mutation manuelle | 0 |
| validationStatus flip manuel | 0 |

## 12. Rollback

| Niveau | action |
|---|---|
| Manifest | git revert bafc540 (image v1.0.53-prod) + kubectl apply -f (rollback documente dans le commentaire image) |
| Image v1.0.53-prod | toujours sur GHCR (digest 18f54575), redeployable |
| DEV | intact v1.0.54-dev |
| Jamais kubectl set image |

## 13. Prochaine phase

GO VERIFY REAL INBOUND VALIDATES AMAZON ADDRESS PROD PH-SAAS-T8.12AS.20.14AD

Verifier en PROD qu'un vrai message Amazon (ou self-test "Renvoyer la validation") fait passer l'adresse PROD ecomlg-001 FR (cmmsdn4if / 4xfub8) de PENDING a VALIDATED via le chemin real-inbound desormais actif (updateMarketplaceStatusIfAmazon -> resolution emailAddress exact -> validationStatus VALIDATED), debloquant le guard outbound -- objectif P0 KEY-323. Hygiene separee : upgrade amazon-orders/items-worker hors v1.0.40 ; reconcilier doublon token 4xfub8/3jcpvk.

Phrase cible : GO APPLY AMAZON VALIDATION PIPELINE PROD READY PH-SAAS-T8.12AS.20.14AC

STOP.
