# PH-SAAS-T8.12AS.20.33-APPLY-BACKEND-ATOMIC-AMAZON-INBOUND-DEDUP-PROD-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.33 (APPLY GITOPS PROD)
> Environnement : PROD (GitOps strict ; DEV strictement intact ; aucun trigger/replay/fake)

## 1. Verdict

GO APPLY BACKEND AND JOBSWORKER PROD GITOPS READY PH-SAAS-T8.12AS.20.33

API keybuzz-backend PROD ET jobs-worker PROD deployes sur v1.0.56-amazon-inbound-dedup-prod via GitOps strict (commit+push manifest AVANT apply, kubectl apply -f uniquement, rollout OK). Triple correspondance manifest=last-applied=runtime=imageID digest GHCR sha256:9689875ca556...1dcdd2 sur les deux. jobs-worker conserve command jobsWorker.js + JOB_TYPES=OUTBOUND_EMAIL_SEND + SMTP PROD 49.13.35.167:25 secure=false. API boot sans erreur Prisma. No unintended processing (Job/OutboundEmail/MOM before==after, AMAZON_POLL worker-1=0, 0 claim/send spontane). DEV strictement intact (v1.0.56-dev). **Le patch atomique advisory lock (PH-20.26), prouve en concurrence reelle DEV (PH-20.30-BIS : 4 POST -> 1 message + 2 skip), est maintenant ACTIF au runtime PROD.** P0 KEY-323 non touche.

## 2. Preflight (E0)

| Service | Namespace | Image avant | Ready | Restarts | JOB_TYPES | verdict |
|---|---|---|---|---|---|---|
| keybuzz-backend | keybuzz-backend-prod | v1.0.55-amazon-inbound-dedup-prod | 1/1 | 0 | n/a | OK |
| jobs-worker | keybuzz-backend-prod | v1.0.55-amazon-inbound-dedup-prod | 1/1 | 0 | OUTBOUND_EMAIL_SEND + SMTP 49.13.35.167:25 secure=false + cmd jobsWorker.js | OK |
| keybuzz-backend | keybuzz-backend-dev | v1.0.56-amazon-inbound-dedup-dev | - | - | n/a | inchange |
| jobs-worker | keybuzz-backend-dev | v1.0.56-amazon-inbound-dedup-dev | - | - | n/a | inchange |

infra clean cfa1c1f ; GHCR config digest 179af6fb0632 + manifest digest 9689875c (= attendus PH-20.32) verifies. Bastion install-v3 / 46.62.171.61.

## 3. Snapshot BEFORE no unintended processing (E1)

| Signal | Before | Verdict |
|---|---|---|
| Job OUTBOUND_EMAIL_SEND (backend DB PROD keybuzz_backend_prod) | aucun (0 row) | baseline |
| OutboundEmail | aucun (0 row) | baseline |
| MarketplaceOutboundMessage | 0 | baseline |
| AMAZON_POLL lockedBy worker-1 (exact) | 0 | OK |
| jobs-worker logs | heartbeat claimed=0 (no job) | idle |

## 4. Patch manifests (E2) + dry-run (E3)

| Fichier | changement | verdict |
|---|---|---|
| k8s/keybuzz-backend-prod/deployment.yaml | image v1.0.55-prod -> v1.0.56-amazon-inbound-dedup-prod (+ commentaire PH-20.33 + digest 9689875c/config 179af6fb + rollback v1.0.55) | OK |
| k8s/keybuzz-backend-prod/deployment-jobs-worker.yaml | image v1.0.55-prod -> v1.0.56-amazon-inbound-dedup-prod (idem) | OK |

git diff : 2 fichiers, 2 lignes image uniquement (patch via python str.replace). dry-run client+server : keybuzz-backend + jobs-worker "configured". Rendu : v1.0.56-prod active=2 ; v1.0.55-prod n'apparait que dans le commentaire rollback ; JOB_TYPES=OUTBOUND_EMAIL_SEND present ; SMTP PROD present ; latest=0.

## 5. Commit + push AVANT apply (E4)

commit infra **b34d259** "chore(backend): deploy atomic Amazon inbound dedup image to PROD (PH-20.33, v1.0.56-amazon-inbound-dedup-prod, KEY-323)" ; push cfa1c1f..b34d259 ; HEAD=origin=b34d259, ahead=0, clean. Apply effectue APRES le push.

## 6. Runtime equality (E5/E6/E7)

| Service | manifest | last-applied | runtime | imageID digest | ready | restarts | verdict |
|---|---|---|---|---|---|---|---|
| keybuzz-backend PROD (565fc9df9-5rptj) | v1.0.56-prod | v1.0.56-prod | v1.0.56-prod | sha256:9689875c...1dcdd2 | 1/1 | 0 | OK |
| jobs-worker PROD (dcd95d488-b5ql6) | v1.0.56-prod | v1.0.56-prod | v1.0.56-prod | sha256:9689875c...1dcdd2 | 1/1 | 0 | OK |

API boot : "Server listening at http://127.0.0.1:4000" + "KeyBuzz backend listening on port 4000", 0 erreur Prisma (warning vault-ca.pem benin pre-existant). jobs-worker startup : "[JobsWorker] Starting worker worker-1 image=unknown types=OUTBOUND_EMAIL_SEND jobTypesRaw=\"OUTBOUND_EMAIL_SEND\" pollMs=2000". kubectl apply -f uniquement (aucun set/patch/edit/restart). Anciens pods v1.0.55 (cn68k + nsfcp) en terminaison gracieuse.

## 7. Snapshot AFTER no unintended processing (E8)

| Signal | Before | After | Verdict |
|---|---|---|---|
| Job OUTBOUND_EMAIL_SEND | aucun (0) | aucun (0) | inchange |
| OutboundEmail | aucun (0) | aucun (0) | inchange |
| MarketplaceOutboundMessage | 0 | 0 | inchange |
| AMAZON_POLL lockedBy worker-1 (exact) | 0 | 0 | inchange |
| jobs-worker claim/send/SMTP spontane | claimed=0 | startup only, claimed=0 | OK |
| SMTP / email / trigger / replay / fake event | 0 | 0 | OK |

## 8. DEV intact (E9)

API + jobs-worker DEV restent v1.0.56-amazon-inbound-dedup-dev ; aucun manifest backend-dev modifie cette phase (commit b34d259 = uniquement k8s/keybuzz-backend-prod) ; aucun apply DEV ; DEV restarts=0.

## 9. AI feature parity / anti-regression

API boot sain (0 erreur Prisma). jobs-worker reste scope OUTBOUND_EMAIL_SEND (jobTypesRaw confirme), AMAZON_POLL non claim (worker-1=0), aucun outbound/inbound job traite spontanement. IA / escalades / assignment / statuts / historique non touches (bump image uniquement). Pipeline outbound restaure KEY-323 (PH-20.14AE) preserve. Le patch atomique advisory lock (pg_advisory_xact_lock + computeInboundDedupLockScope, PH-20.26) est actif au runtime PROD (API ingestion + jobs-worker).

## 10. Rollback

Revenir a v1.0.55-amazon-inbound-dedup-prod via GitOps : git revert b34d259 (ou re-bump manifest) + kubectl apply -f ; image v1.0.55-prod toujours sur GHCR (digest b21e524a). Jamais kubectl set image.

## 11. Limites restantes

- Preuve runtime concurrence PROD a etablir (PH-20.34, read-only, vrai message ; advisory lock = vraie DB).
- CONTRAINTE UNIQUE DB : durcissement stockage differe (post-cleanup doublons).
- CROSS-TENANT (4xfub8 ecomlg-001 / as0yom ecomlg-motxke32) : non corrige (decision produit).
- Reply-to obsoletes (3jcpvk/cp2hat) : retrait Seller Central separe.
- Cleanup des doublons existants : phase separee.

## 12. Next GO

GO READONLY VERIFY ATOMIC AMAZON INBOUND DEDUP PROD PH-SAAS-T8.12AS.20.34 : preuve read-only que les redeliveries quasi-simultanees du meme amazonIds.messageId (meme tenant) collapsent en 1 message logique au runtime PROD (vrai message, SANS fake event ; logs "Dedup lock acquired" + "Idempotent skip", DB 1 message / 1 conversation par tenant+amazonIds.messageId).

## 13. Phrase cible

GO APPLY BACKEND AND JOBSWORKER PROD GITOPS READY PH-SAAS-T8.12AS.20.33

STOP.
