# PH-SAAS-T8.12AS.20.29-APPLY-BACKEND-ATOMIC-AMAZON-INBOUND-DEDUP-DEV-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.29 (APPLY GITOPS DEV)
> Environnement : DEV (GitOps strict ; PROD strictement intact ; aucun trigger/replay/fake)

## 1. Verdict

GO APPLY BACKEND AND JOBSWORKER DEV GITOPS READY PH-SAAS-T8.12AS.20.29

API keybuzz-backend DEV ET jobs-worker DEV deployes sur v1.0.56-amazon-inbound-dedup-dev via GitOps strict (commit+push manifest AVANT apply, kubectl apply -f uniquement, rollout OK). Triple correspondance manifest=last-applied=runtime=imageID digest GHCR sha256:ed3d6c1a7f32...f81b sur les deux. jobs-worker conserve command jobsWorker.js + JOB_TYPES=OUTBOUND_EMAIL_SEND + SMTP DEV 49.13.35.167:25 secure=false. API boot sans erreur Prisma. No unintended processing (Job/OutboundEmail/MOM before==after, AMAZON_POLL worker-1=0, 0 claim/send spontane). PROD strictement intact (v1.0.55-prod). Le patch atomique (advisory lock PH-20.26) est maintenant ACTIF au runtime DEV. P0 KEY-323 non touche.

## 2. Preflight (E0)

| Service | Namespace | Image avant | Ready | Restarts | JOB_TYPES | verdict |
|---|---|---|---|---|---|---|
| keybuzz-backend | keybuzz-backend-dev | v1.0.55-amazon-inbound-dedup-dev | 1/1 | 0 | n/a | OK |
| jobs-worker | keybuzz-backend-dev | v1.0.55-amazon-inbound-dedup-dev | 1/1 | 0 | OUTBOUND_EMAIL_SEND + SMTP 49.13.35.167:25 secure=false + cmd jobsWorker.js | OK |
| keybuzz-backend | keybuzz-backend-prod | v1.0.55-amazon-inbound-dedup-prod | - | - | n/a | inchange |
| jobs-worker | keybuzz-backend-prod | v1.0.55-amazon-inbound-dedup-prod | - | - | n/a | inchange |

infra clean 7f6640b ; GHCR config digest e3b5d2b30542 (manifest ed3d6c1a) verifie. Bastion install-v3 / 46.62.171.61.

## 3. Snapshot BEFORE no unintended processing (E1)

| Signal | Before | Verdict |
|---|---|---|
| Job OUTBOUND_EMAIL_SEND | DONE 13 / FAILED 16 | baseline |
| OutboundEmail | PENDING 1 / SENT 13 / FAILED 14 | baseline |
| MarketplaceOutboundMessage | 2 | baseline |
| AMAZON_POLL lockedBy worker-1 (exact) | 0 | OK |
| jobs-worker logs | heartbeat claimed=0 (no job) | idle |

DB keybuzz_backend DEV via pod backend (DATABASE_URL), SELECT only.

## 4. Patch manifests (E2) + dry-run (E3)

| Fichier | changement | verdict |
|---|---|---|
| k8s/keybuzz-backend-dev/deployment.yaml | image v1.0.55-dev -> v1.0.56-amazon-inbound-dedup-dev (+ commentaire PH-20.29 + digest + rollback v1.0.55) | OK |
| k8s/keybuzz-backend-dev/deployment-jobs-worker.yaml | image v1.0.55-dev -> v1.0.56-amazon-inbound-dedup-dev (idem) | OK |

git diff : 2 fichiers, 2 lignes image uniquement (patch via python str.replace). dry-run client+server : keybuzz-backend + jobs-worker "configured". Rendu : v1.0.56-dev active=2 ; v1.0.55-dev ACTIVE (ligne image)=0 (n'apparait que dans le commentaire rollback) ; JOB_TYPES=OUTBOUND_EMAIL_SEND present ; SMTP DEV present ; latest=0.

## 5. Commit + push AVANT apply (E4)

commit infra **518a072** "chore(backend): deploy atomic Amazon inbound dedup image to DEV (PH-20.29, v1.0.56-amazon-inbound-dedup-dev, KEY-323)" ; push 7f6640b..518a072 ; HEAD=origin=518a072, ahead=0, clean. Apply effectue APRES le push.

## 6. Runtime equality (E5/E6/E7)

| Service | manifest | last-applied | runtime | imageID digest | ready | restarts | verdict |
|---|---|---|---|---|---|---|---|
| keybuzz-backend DEV (7c98d5c544-q56f5) | v1.0.56-dev | v1.0.56-dev | v1.0.56-dev | sha256:ed3d6c1a...f81b | true | 0 | OK |
| jobs-worker DEV (5c78d57586-dm884) | v1.0.56-dev | v1.0.56-dev | v1.0.56-dev | sha256:ed3d6c1a...f81b | true | 0 | OK |

API boot : "Server listening at http://127.0.0.1:4000" + "KeyBuzz backend listening on port 4000", 0 erreur Prisma. jobs-worker startup : "[JobsWorker] Starting worker worker-1 image=unknown types=OUTBOUND_EMAIL_SEND jobTypesRaw=\"OUTBOUND_EMAIL_SEND\" pollMs=2000" (image=unknown = env IMAGE_VERSION non injectee best-effort, normal). kubectl apply -f uniquement (aucun set/patch/edit/restart). Anciens pods v1.0.55 en terminaison gracieuse (transitoire).

## 7. Snapshot AFTER no unintended processing (E8)

| Signal | Before | After | Verdict |
|---|---|---|---|
| Job OUTBOUND_EMAIL_SEND | DONE 13 / FAILED 16 | DONE 13 / FAILED 16 | inchange |
| OutboundEmail | PENDING 1 / SENT 13 / FAILED 14 | PENDING 1 / SENT 13 / FAILED 14 | inchange |
| MarketplaceOutboundMessage | 2 | 2 | inchange |
| AMAZON_POLL lockedBy worker-1 (exact) | 0 | 0 | inchange |
| jobs-worker claim/send/SMTP spontane | heartbeat claimed=0 | startup only, claimed=0 | OK |
| SMTP / email / trigger / replay / fake event | 0 | 0 | OK |

## 8. PROD intact (E9)

API + jobs-worker PROD restent v1.0.55-amazon-inbound-dedup-prod ; aucun manifest backend-prod modifie cette phase (commit 518a072 = uniquement k8s/keybuzz-backend-dev) ; aucun apply PROD ; jobs-worker PROD restarts=0.

## 9. AI feature parity / anti-regression

API boot sain (0 erreur Prisma). jobs-worker reste scope OUTBOUND_EMAIL_SEND (jobTypesRaw confirme), AMAZON_POLL non claim (worker-1=0), aucun outbound/inbound job traite spontanement. IA / escalades / assignment / statuts / historique non touches (bump image uniquement). Pipeline restaure KEY-323 preserve. Le patch atomique advisory lock (PH-20.26) est actif au runtime DEV (API ingestion + jobs-worker).

## 10. Rollback

Revenir a v1.0.55-amazon-inbound-dedup-dev via GitOps : git revert 518a072 (ou re-bump manifest) + kubectl apply -f ; image v1.0.55 toujours sur GHCR. Jamais kubectl set image.

## 11. Limites restantes

- Preuve runtime concurrence a etablir (PH-20.30, vrai message, redeliveries quasi-simultanees -> 1 message logique).
- CONTRAINTE UNIQUE DB : durcissement stockage differe (post-cleanup doublons).
- CROSS-TENANT (4xfub8/as0yom) : non fusionne (decision produit).
- Reply-to obsoletes 3jcpvk/cp2hat cote Amazon : retrait manuel separe.
- Cleanup doublons existants : phase separee.

## 12. Next GO

GO VERIFY ATOMIC AMAZON INBOUND DEDUP DEV PH-SAAS-T8.12AS.20.30 : prouver au runtime DEV que des redeliveries quasi-simultanees du meme amazonIds.messageId (meme tenant) collapsent en 1 message (vrai message OU replay controle d'un vrai payload, SANS fake event), logs "Dedup lock acquired" + "Idempotent skip".

## 13. Phrase cible

GO APPLY BACKEND AND JOBSWORKER DEV GITOPS READY PH-SAAS-T8.12AS.20.29

STOP.
