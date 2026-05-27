# PH-SAAS-T8.12AS.20.27-BUILD-BACKEND-ATOMIC-AMAZON-INBOUND-DEDUP-DEV-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.27 (BUILD BACKEND DEV ONLY)
> Environnement : DEV preparation (BUILD ONLY ; aucun push/deploy/kubectl/DB/trigger)

## 1. Verdict

GO BUILD BACKEND ATOMIC AMAZON INBOUND DEDUP DEV READY PH-SAAS-T8.12AS.20.27

Image DEV v1.0.56-amazon-inbound-dedup-dev construite from-git (worktree detache 78bfb94, porcelain=0), Image ID sha256:e3b5d2b30542, OCI revision 78bfb9424675dd01105792ec74635730d597c849, OCI version v1.0.56-amazon-inbound-dedup-dev. Embarque le patch atomique PH-20.26 (advisory lock transactionnel pg_advisory_xact_lock + computeInboundDedupLockScope). Tests pre-build OK (prisma generate, DMMF MAP to, tsc EXIT 0, ph2026 14/14, ph2017 13/13, ph2014w 10/10, ph2014o 9/9, ph2014i 11/11). Markers dist verifies. LOCALE UNIQUEMENT, non poussee GHCR. Aucun deploy/kubectl/DB/trigger. Runtime DEV v1.0.55-dev + PROD v1.0.55-prod inchanges.

## 2. Preflight (E0) + collision (E1)

| Repo | Branche | HEAD | origin/main | dirty | verdict |
|---|---|---|---|---|---|
| keybuzz-backend | main | 78bfb94 | 78bfb94 | amazon.routes.ts.bak (cruft historique) | OK |
| keybuzz-infra | main | b225e91 | - | clean | OK |

Bastion install-v3 / 46.62.171.61, date 2026-05-27 11:57Z. Collision : image locale v1.0.56-dev ABSENTE, GHCR v1.0.56-dev ABSENT, aucun manifest k8s ne reference v1.0.56. Runtime informatif : DEV v1.0.55-amazon-inbound-dedup-dev, PROD v1.0.55-amazon-inbound-dedup-prod.

## 3. Worktree (E2)

git worktree add --detach /opt/keybuzz/build-worktrees/PH-20.27-backend-atomic-dedup-dev 78bfb94 ; HEAD worktree = 78bfb942..., porcelain=0. node_modules NON symlinke avant docker build (symlinke uniquement pour les tests E4 puis retire avant E5 ; incident PH-20.18 evite).

## 4. Source audit (E3)

| Marker | Attendu | Resultat |
|---|---|---|
| computeInboundDedupLockScope (def dedup.ts + import + use svc) | present | def L69 + import L10 + use L295 |
| amzmsg:<tenant> scope | present | OK |
| thread:<tenant>:<channel>:<threadKey> scope | present | OK |
| pg_advisory_xact_lock (svc) | present | 1 |
| transaction courte : COMMIT AVANT MinIO/attachments/stats/autopilot | ordre | COMMIT inline L477 < storeRawMime L490 < stats L549 < autopilot L585 |
| fallback legacy (txClient null -> productDb pool) | present | runQuery = txClient ? client : productDb |
| @map("to") OutboundEmail (schema) | present | 1 |
| OUTBOUND_EMAIL_SEND (jobsWorker) | present | 5 |
| jobsWorker heartbeat observability | present | 2 |
| NOT IMPLEMENTED OUTBOUND | 0 | 0 |
| hardcode 4xfub8/3jcpvk/cp2hat/as0yom/order reel | 0 | 0 |

## 5. Tests pre-build (E4)

| Test | Attendu | Resultat |
|---|---|---|
| prisma generate | OK | OK |
| DMMF OutboundEmail.toAddress.dbName | to | to |
| tsc --noEmit | EXIT 0 | EXIT 0 |
| ph2026-inbound-dedup-lock | pass | 14 passed, 0 failed |
| ph2017-inbound-dedup | pass | 13 passed, 0 failed |
| ph2014w | pass | 10 passed, 0 failed |
| ph2014o | pass | 9 passed, 0 failed |
| ph2014i | pass | 11 passed, 0 failed |

## 6. Docker build DEV (E5)

Image ghcr.io/keybuzzio/keybuzz-backend:v1.0.56-amazon-inbound-dedup-dev construite depuis le worktree propre. Build-args : IMAGE_REVISION=78bfb9424675dd01105792ec74635730d597c849, IMAGE_VERSION=v1.0.56-amazon-inbound-dedup-dev, IMAGE_CREATED=2026-05-27T11:59:44Z. Aucun latest. Aucun push. BUILD_OK (Successfully built e3b5d2b30542).

## 7. Audit image (E6)

| Item | Valeur / Resultat |
|---|---|
| Image ID | sha256:e3b5d2b30542d21516137f5a53a842ee0b696fbcc17710df644594c2e4459e4c |
| OCI image.revision | 78bfb9424675dd01105792ec74635730d597c849 |
| OCI image.version | v1.0.56-amazon-inbound-dedup-dev |
| OCI image.created | 2026-05-27T11:59:44Z |
| computeInboundDedupLockScope (dist/inboundDedup.js) | 2 |
| pg_advisory_xact_lock (dist/service.js) | 1 |
| amzmsg scope | 2 |
| thread scope | 2 |
| stableAmazonMessageKey (dist/service.js) | 4 |
| idempotence amazonIds.messageId | 1 |
| OUTBOUND_EMAIL_SEND (dist/jobsWorker.js) | 5 |
| jobsWorker heartbeat | 2 |
| NOT IMPLEMENTED OUTBOUND | 0 |
| @map to (client Prisma genere dans l'image) | present |
| hardcode 4xfub8/3jcpvk/cp2hat/as0yom/order dans dist | 0 |

## 8. No side-effect (E7)

| Garantie | etat |
|---|---|
| GHCR v1.0.56-amazon-inbound-dedup-dev | ABSENT (non pousse) |
| runtime DEV API + jobs-worker | v1.0.55-amazon-inbound-dedup-dev (inchange) |
| runtime PROD API + jobs-worker | v1.0.55-amazon-inbound-dedup-prod (inchange) |
| manifest ref v1.0.56 | aucun |
| pod restart | 0 |
| DB / email / trigger / replay / fake | 0 |
| kubectl apply/set/patch/edit/restart | 0 |

## 9. Cleanup (E8)

Worktree retire via git worktree remove (sans --force), absent de git worktree list. Image locale v1.0.56-amazon-inbound-dedup-dev (e3b5d2b30542) CONSERVEE pour push ulterieur. Aucun container d'audit residuel (docker run --rm).

## 10. AI feature parity / anti-regression

Le patch ne modifie pas IA / escalades / assignment / statuts / historique (PH-20.26 = serialisation de la section dedup, fallback legacy conserve). Guard validation + OUTBOUND_EMAIL_SEND presents dans le dist (5). jobsWorker observability (heartbeat 2) conservee. Pipeline restaure KEY-323 non touche. Le travail non-critique (MinIO/attachments/stats/autopilot) reste apres COMMIT (transaction courte).

## 11. Limites restantes

- Preuve runtime concurrence necessaire (vrai message, post-apply DEV) : l'advisory lock requiert une vraie DB Postgres -> non unit-testable, a prouver au runtime.
- CONTRAINTE UNIQUE DB : durcissement stockage differe (post-cleanup doublons).
- CROSS-TENANT (4xfub8/as0yom) : non fusionne (decision produit).
- Reply-to obsoletes 3jcpvk/cp2hat cote Amazon : retrait manuel separe.
- Cleanup doublons existants : phase separee.

## 12. Next GO

GO PUSH IMAGE BACKEND ATOMIC AMAZON INBOUND DEDUP DEV PH-SAAS-T8.12AS.20.28 (push GHCR + pull-back digest match), puis GO APPLY BACKEND AND JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.29 (bump API + jobs-worker DEV v1.0.55-dev -> v1.0.56-dev, commit+push AVANT apply, rollout, verifier digest + no unintended processing), puis verify concurrence runtime sur vrai message.

## 13. Phrase cible

GO BUILD BACKEND ATOMIC AMAZON INBOUND DEDUP DEV READY PH-SAAS-T8.12AS.20.27

STOP.
