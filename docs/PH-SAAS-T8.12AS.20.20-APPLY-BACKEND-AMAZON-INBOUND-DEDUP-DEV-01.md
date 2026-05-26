# PH-SAAS-T8.12AS.20.20-APPLY-BACKEND-AMAZON-INBOUND-DEDUP-DEV-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.20 (APPLY BACKEND + JOBS-WORKER DEV GITOPS)
> Environnement : DEV (GitOps strict ; PROD strictement intact ; aucun trigger/replay/fake event)

## 1. Verdict

GO APPLY BACKEND AND JOBSWORKER DEV GITOPS READY PH-SAAS-T8.12AS.20.20

API keybuzz-backend DEV et jobs-worker DEV deployes sur v1.0.55-amazon-inbound-dedup-dev via GitOps strict (commit+push manifest AVANT apply, kubectl apply -f uniquement, rollout OK). Triple correspondance manifest=last-applied=runtime=digest GHCR sha256:b314826. jobs-worker conserve JOB_TYPES=OUTBOUND_EMAIL_SEND + SMTP DEV inchange. No unintended processing (Job/OutboundEmail inchanges, AMAZON_POLL worker-1=0, 0 claim/send spontane). API boot sans erreur Prisma. PROD strictement intact (v1.0.54-prod). Le patch dedup PH-20.17 est maintenant ACTIF au runtime DEV. P0 KEY-323 non touche.

## 2. Preflight (E0)

| Service | Namespace | Image avant | Ready | Restarts | JOB_TYPES | verdict |
|---|---|---|---|---|---|---|
| keybuzz-backend | keybuzz-backend-dev | v1.0.54-amazon-validation-pipeline-dev | 1/1 | 0 | n/a | OK |
| jobs-worker | keybuzz-backend-dev | v1.0.54-amazon-validation-pipeline-dev | 1/1 | 0 | OUTBOUND_EMAIL_SEND + SMTP 49.13.35.167:25 secure=false | OK |
| keybuzz-backend | keybuzz-backend-prod | v1.0.54-amazon-validation-pipeline-prod | - | 0 | n/a | inchange |
| jobs-worker | keybuzz-backend-prod | v1.0.54-amazon-validation-pipeline-prod | - | 0 | n/a | inchange |

infra clean fa679b6 ; GHCR config digest 8e2b4d0399be (manifest b314826) verifie.

## 3. Patch manifests (E2) + dry-run (E3)

| Fichier | changement | verdict |
|---|---|---|
| k8s/keybuzz-backend-dev/deployment.yaml | image L32 v1.0.54 -> v1.0.55 (+ commentaire PH-20.20 + digest + rollback v1.0.54) | OK |
| k8s/keybuzz-backend-dev/deployment-jobs-worker.yaml | image L32 v1.0.54 -> v1.0.55 (idem) | OK |

git diff : 2 fichiers, 2 lignes image uniquement. dry-run client+server : keybuzz-backend + jobs-worker "configured". Rendu : tag image reel keybuzz-backend:v1.0.55 = 2 ; keybuzz-backend:v1.0.54 = 0 (le v1.0.54 restant n'apparait que dans le commentaire rollback) ; JOB_TYPES=OUTBOUND_EMAIL_SEND present ; SMTP DEV present ; latest = 0.

## 4. Commit + push AVANT apply (E4)

commit infra **6b7af84** "chore(backend): deploy Amazon inbound dedup image to DEV (PH-20.20, v1.0.55, KEY-323)" ; push fa679b6..6b7af84 ; HEAD=origin=6b7af84, ahead=0, clean. Apply effectue APRES le push.

## 5. Runtime equality (E5/E6/E7)

| Service | manifest | last-applied | runtime | imageID digest | ready | restarts | verdict |
|---|---|---|---|---|---|---|---|
| keybuzz-backend DEV | v1.0.55 | v1.0.55 | v1.0.55 | sha256:b314826...9702 | true | 0 | OK |
| jobs-worker DEV | v1.0.55 | v1.0.55 | v1.0.55 | sha256:b314826...9702 | true | 0 | OK |

API boot : "Server listening at http://127.0.0.1:4000" + "KeyBuzz backend listening on port 4000", 0 erreur Prisma. jobs-worker startup : "[JobsWorker] Starting worker worker-1 image=unknown types=OUTBOUND_EMAIL_SEND jobTypesRaw=\"OUTBOUND_EMAIL_SEND\" pollMs=2000" (image=unknown = env IMAGE_VERSION non injectee best-effort, normal). kubectl apply -f uniquement (aucun set/patch/edit/restart). Ancien pod jobs-worker v1.0.54 en terminaison gracieuse (transitoire).

## 6. No unintended processing (E1 before / E8 after)

| Signal | Before | After | Verdict |
|---|---|---|---|
| Job OUTBOUND_EMAIL_SEND | DONE 13 / FAILED 16 | DONE 13 / FAILED 16 | inchange |
| OutboundEmail | PENDING 1 / SENT 13 / FAILED 14 | PENDING 1 / SENT 13 / FAILED 14 | inchange |
| AMAZON_POLL lockedBy worker-1 (exact) | 0 | 0 | inchange |
| jobs-worker claim/send/SMTP spontane | heartbeat claimed=0 (no job) | 0 marker claim/send/SMTP | OK |
| SMTP / email / trigger / replay / fake event | 0 | 0 | OK |

La PENDING OutboundEmail=1 (cmpma3nsd, historique PH-20.14S jamais envoye) demeure ; aucune action declenchee par cette phase.

## 7. PROD intact (E9)

API + jobs-worker PROD restent v1.0.54-amazon-validation-pipeline-prod, restarts=0 ; aucun manifest backend-prod modifie cette phase (git diff fa679b6..HEAD = aucun fichier backend-prod) ; aucun apply PROD.

## 8. AI feature parity / anti-regression

API boot sain (0 erreur Prisma). jobs-worker reste scope OUTBOUND_EMAIL_SEND (jobTypesRaw confirme), AMAZON_POLL non claim (worker-1=0), aucun outbound/inbound job traite spontanement. IA / escalades / assignment / statuts / historique non touches (bump image uniquement). Pipeline restaure KEY-323 preserve. Doublon cross-tenant (4xfub8/as0yom) inchange = decision produit/cleanup separee.

## 9. Rollback

Revenir a v1.0.54-amazon-validation-pipeline-dev via GitOps : git revert 6b7af84 (ou re-bump manifest) + kubectl apply -f ; image v1.0.54 toujours sur GHCR. Jamais kubectl set image.

## 10. Linear (E11)

Commentaire KEY-323 + KEY-337 (statuts inchanges) : apply DEV v1.0.55 OK, runtime/digest match, no unintended processing, PROD intact.

## 11. Next GO

GO VERIFY AMAZON INBOUND DEDUP DEV PH-SAAS-T8.12AS.20.21 : prouver au runtime DEV que 2 livraisons SES du meme message Amazon (vrai message ou replay controle, SANS fake event) collapsent en 1 conversation + 1 message (idempotent skip via metadata.amazonIds.messageId).

## 12. Phrase cible

GO APPLY BACKEND AND JOBSWORKER DEV GITOPS READY PH-SAAS-T8.12AS.20.20

STOP.
