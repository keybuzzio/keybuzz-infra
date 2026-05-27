# PH-SAAS-T8.12AS.20.24-APPLY-BACKEND-AMAZON-INBOUND-DEDUP-PROD-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.24 (APPLY GITOPS PROD)
> Environnement : PROD (GitOps strict ; DEV strictement intact ; aucun trigger/replay/fake)

## 1. Verdict

GO APPLY BACKEND AND JOBSWORKER PROD GITOPS READY PH-SAAS-T8.12AS.20.24

API keybuzz-backend PROD ET jobs-worker PROD deployes sur v1.0.55-amazon-inbound-dedup-prod via GitOps strict (commit+push manifest AVANT apply, kubectl apply -f uniquement, rollout OK). Triple correspondance manifest=last-applied=runtime=imageID digest GHCR sha256:b21e524a9d98...52e2 sur les deux. jobs-worker conserve command jobsWorker.js + JOB_TYPES=OUTBOUND_EMAIL_SEND + SMTP PROD 49.13.35.167:25 secure=false. API boot sans erreur Prisma. No unintended processing (Job/OutboundEmail/MOM vides before==after, AMAZON_POLL worker-1=0, 0 claim/send/SMTP spontane). DEV strictement intact (v1.0.55-dev, restarts=0). Le patch dedup PH-20.17 (idempotence amazonIds.messageId) est maintenant ACTIF au runtime PROD. P0 KEY-323 outbound non touche.

## 2. Preflight (E0)

| Service | Namespace | Image avant | Ready | Restarts | JOB_TYPES | verdict |
|---|---|---|---|---|---|---|
| keybuzz-backend | keybuzz-backend-prod | v1.0.54-amazon-validation-pipeline-prod | 1/1 | 0 | n/a | OK |
| jobs-worker | keybuzz-backend-prod | v1.0.54-amazon-validation-pipeline-prod | 1/1 | 0 | OUTBOUND_EMAIL_SEND + SMTP 49.13.35.167:25 secure=false + cmd jobsWorker.js | OK |
| keybuzz-backend | keybuzz-backend-dev | v1.0.55-amazon-inbound-dedup-dev | - | - | n/a | informatif (intact) |
| jobs-worker | keybuzz-backend-dev | v1.0.55-amazon-inbound-dedup-dev | - | - | n/a | informatif (intact) |

infra clean f83020e ; GHCR config digest sha256:7e2f123673ed (== Image ID PH-20.22), manifest digest sha256:b21e524a (PH-20.23). Bastion install-v3 / 46.62.171.61.

## 3. Snapshot BEFORE no unintended processing (E1)

| Signal | Before | Verdict |
|---|---|---|
| Job OUTBOUND_EMAIL_SEND | [] (vide) | baseline |
| OutboundEmail | [] (vide) | baseline |
| MarketplaceOutboundMessage | [] (vide) | baseline |
| AMAZON_POLL lockedBy worker-1 (exact) | 0 | OK |
| jobs-worker logs | heartbeat claimed=0 (no job) | idle |

DB keybuzz_backend PROD via pod backend (DATABASE_URL), SELECT only.

## 4. Patch manifests (E2) + dry-run (E3)

| Fichier | changement | verdict |
|---|---|---|
| k8s/keybuzz-backend-prod/deployment.yaml | image v1.0.54 -> v1.0.55-amazon-inbound-dedup-prod (+ commentaire PH-20.24 + digest + rollback v1.0.54) | OK |
| k8s/keybuzz-backend-prod/deployment-jobs-worker.yaml | image v1.0.54 -> v1.0.55-amazon-inbound-dedup-prod (idem) | OK |

git diff : 2 fichiers, 2 lignes image uniquement (patch via python str.replace, le `|` du commentaire casse sed). dry-run client+server : keybuzz-backend + jobs-worker "configured". Rendu : v1.0.55-prod active=2 ; v1.0.54-prod ACTIVE (ligne image)=0 (n'apparait que dans le commentaire rollback) ; JOB_TYPES=OUTBOUND_EMAIL_SEND present ; SMTP PROD present ; latest=0.

## 5. Commit + push AVANT apply (E4)

commit infra **7f23635** "chore(backend): deploy Amazon inbound dedup image to PROD (PH-20.24, v1.0.55-amazon-inbound-dedup-prod, KEY-323)" ; push f83020e..7f23635 ; HEAD=origin=7f23635, ahead=0, clean. Apply effectue APRES le push.

## 6. Runtime equality (E5/E6/E7)

| Service | manifest | last-applied | runtime | imageID digest | ready | restarts | verdict |
|---|---|---|---|---|---|---|---|
| keybuzz-backend PROD (797978c57d-cn68k) | v1.0.55-prod | v1.0.55-prod | v1.0.55-prod | sha256:b21e524a...52e2 | true | 0 | OK |
| jobs-worker PROD (75c884ffdc-nsfcp) | v1.0.55-prod | v1.0.55-prod | v1.0.55-prod | sha256:b21e524a...52e2 | true | 0 | OK |

API boot : "Server listening at http://127.0.0.1:4000" + "KeyBuzz backend listening on port 4000", 0 erreur Prisma (warning vault-ca.pem benin pre-existant). jobs-worker startup : "[JobsWorker] Starting worker worker-1 image=unknown types=OUTBOUND_EMAIL_SEND jobTypesRaw=\"OUTBOUND_EMAIL_SEND\" pollMs=2000" (image=unknown = env IMAGE_VERSION non injectee best-effort, normal). kubectl apply -f uniquement (aucun set/patch/edit/restart). Anciens pods v1.0.54 en terminaison gracieuse (transitoire).

## 7. Snapshot AFTER no unintended processing (E8)

| Signal | Before | After | Verdict |
|---|---|---|---|
| Job OUTBOUND_EMAIL_SEND | [] | [] | inchange |
| OutboundEmail | [] | [] | inchange |
| MarketplaceOutboundMessage | [] | [] | inchange |
| AMAZON_POLL lockedBy worker-1 (exact) | 0 | 0 | inchange |
| jobs-worker claim/send/SMTP spontane | 0 | 0 (startup only) | OK |
| SMTP / email / trigger / replay / fake event | 0 | 0 | OK |

## 8. DEV intact (E9)

API + jobs-worker DEV restent v1.0.55-amazon-inbound-dedup-dev, restarts=0 ; aucun manifest DEV modifie cette phase ; aucun apply DEV.

## 9. AI feature parity / anti-regression

API boot sain (0 erreur Prisma). jobs-worker reste scope OUTBOUND_EMAIL_SEND (jobTypesRaw confirme), AMAZON_POLL non claim (worker-1=0), aucun outbound/inbound job traite spontanement. IA / escalades / assignment / statuts / historique non touches (bump image uniquement). Pipeline outbound restaure KEY-323 (PH-20.14AE) preserve. Doublon cross-tenant (4xfub8/as0yom) + race + reply-to obsoletes = NON corriges par ce patch (phases separees).

## 10. Rollback

Revenir a v1.0.54-amazon-validation-pipeline-prod via GitOps : git revert 7f23635 (ou re-bump manifest) + kubectl apply -f ; image v1.0.54 toujours sur GHCR (digest 060abd98). Jamais kubectl set image.

## 11. Limites restantes

- RACE : dedup SELECT-puis-skip sans contrainte unique DB -> collapse non garantie sous redeliveries quasi-simultanees. Contrainte unique DB produit (tenant_id, amazonIds.messageId / thread_key), phase separee.
- CROSS-TENANT : non corrige (decision produit + cleanup data separes).
- Adresses reply-to obsoletes 3jcpvk/cp2hat cote Amazon Seller Central : retrait manuel separe.
- Doublons existants en DB : non nettoyes (phase cleanup dediee).

## 12. Next GO

GO READONLY VERIFY AMAZON INBOUND DEDUP PROD PH-SAAS-T8.12AS.20.25 : prouver au runtime PROD que les redeliveries d'un meme message Amazon (meme amazonIds.messageId, meme tenant) collapsent en 1 message (vrai message OU observation read-only d'une prochaine reception reelle, SANS fake event), idealement sur ecomlg-001 ; quantifier la reduction du triple.

## 13. Phrase cible

GO APPLY BACKEND AND JOBSWORKER PROD GITOPS READY PH-SAAS-T8.12AS.20.24

STOP.
