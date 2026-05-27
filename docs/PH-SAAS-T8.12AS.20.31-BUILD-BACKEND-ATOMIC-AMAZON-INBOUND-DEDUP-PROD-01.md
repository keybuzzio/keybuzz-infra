# PH-SAAS-T8.12AS.20.31-BUILD-BACKEND-ATOMIC-AMAZON-INBOUND-DEDUP-PROD-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.31 (BUILD BACKEND PROD ONLY)
> Environnement : PROD preparation (BUILD ONLY ; aucun push/deploy/kubectl/DB/trigger)

## 1. Verdict

GO BUILD BACKEND ATOMIC AMAZON INBOUND DEDUP PROD READY PH-SAAS-T8.12AS.20.31

Image PROD v1.0.56-amazon-inbound-dedup-prod construite from-git (worktree detache 78bfb94, porcelain=0 hors .bak), Image ID sha256:179af6fb0632, OCI revision 78bfb9424675dd01105792ec74635730d597c849, OCI version v1.0.56-amazon-inbound-dedup-prod, created 2026-05-27T13:28:15Z. Embarque le patch atomique PH-20.26 (advisory lock pg_advisory_xact_lock + computeInboundDedupLockScope), prouve au runtime DEV en PH-20.30-BIS (4 POST concurrents -> 1 message + 2 skip). Tests pre-build OK (tsc EXIT 0, ph2026 14/14, ph2017 13/13, ph2014w 10/10, ph2014o 9/9, ph2014i 11/11). Markers dist verifies. LOCALE UNIQUEMENT, non poussee GHCR. Aucun deploy/kubectl/DB/trigger. Runtime DEV v1.0.56-dev + PROD v1.0.55-prod inchanges.

## 2. Preflight (E0) + collision (E1)

| Repo | Branche | HEAD | origin/main | dirty | verdict |
|---|---|---|---|---|---|
| keybuzz-backend | main | 78bfb94 | 78bfb94 | amazon.routes.ts.bak (cruft historique) | OK |
| keybuzz-infra | main | f1f6263 | - | clean | OK |

Bastion install-v3 / 46.62.171.61, date 2026-05-27 13:26Z. Collision : image locale v1.0.56-prod ABSENTE, GHCR v1.0.56-prod ABSENT, aucun manifest k8s ne reference v1.0.56-prod. Runtime informatif : DEV v1.0.56-amazon-inbound-dedup-dev, PROD v1.0.55-amazon-inbound-dedup-prod.

## 3. Worktree (E2)

git worktree add --detach /opt/keybuzz/build-worktrees/PH-20.31-backend-atomic-dedup-prod 78bfb94 ; HEAD worktree = 78bfb942..., porcelain=0. node_modules NON symlinke avant docker build (symlinke uniquement pour les tests E4 puis retire avant E5 ; incident PH-20.18 evite).

## 4. Source audit (E3)

| Marker | Attendu | Resultat |
|---|---|---|
| computeInboundDedupLockScope (def + import + use) | present | 3 |
| pg_advisory_xact_lock (svc) | 1 | 1 |
| amzmsg:<tenant> scope | present | 2 |
| thread:<tenant>:<channel>:<threadKey> scope | present | 2 |
| transaction courte : COMMIT (L477) AVANT storeRawMime (L490) | ordre | OK |
| fallback legacy (txClient null -> productDb pool) | present | runQuery L305-306 |
| hardcode 4xfub8/3jcpvk/cp2hat/as0yom/order reel | 0 | 0 |
| @map("to") (schema) | present | 1 |
| OUTBOUND_EMAIL_SEND (jobsWorker) | present | 5 |
| jobsWorker heartbeat | present | 2 |
| NOT IMPLEMENTED OUTBOUND (jobsWorker) | 0 | 0 (le seul match "SES not implemented, falling back to SMTP" = log fallback SES->SMTP, pas un stub OUTBOUND ; seul INBOUND_EMAIL_PROCESS stub) |

## 5. Tests pre-build (E4)

| Test | Attendu | Resultat |
|---|---|---|
| prisma generate (DATABASE_URL factice, codegen local) | OK | OK (Prisma Client v6.19.1) |
| tsc --noEmit | EXIT 0 | EXIT 0 |
| ph2026-inbound-dedup-lock | pass | 14 passed, 0 failed |
| ph2017-inbound-dedup | pass | 13 passed, 0 failed |
| ph2014w-real-inbound-validation | pass | 10 passed, 0 failed |
| ph2014o-validation-address-casing | pass | 9 passed, 0 failed |
| ph2014i-validation-address | pass | 11 passed, 0 failed |

## 6. Docker build PROD (E5)

Image ghcr.io/keybuzzio/keybuzz-backend:v1.0.56-amazon-inbound-dedup-prod construite depuis le worktree propre (node_modules symlink RETIRE avant build, porcelain=0). Build-args : IMAGE_REVISION=78bfb9424675dd01105792ec74635730d597c849, IMAGE_VERSION=v1.0.56-amazon-inbound-dedup-prod, IMAGE_CREATED=2026-05-27T13:28:15Z. Aucun latest. Aucun push. BUILD_OK (Successfully built 179af6fb0632).

## 7. Audit image (E6)

| Item | Valeur / Resultat |
|---|---|
| Image ID | sha256:179af6fb0632dab8d91ebd362e3a1c20b39908d66448dc9fdd86bbeaa8495c2a |
| OCI image.revision | 78bfb9424675dd01105792ec74635730d597c849 |
| OCI image.version | v1.0.56-amazon-inbound-dedup-prod |
| OCI image.created | 2026-05-27T13:28:15Z |
| computeInboundDedupLockScope (dist/inboundDedup.js) | 2 |
| pg_advisory_xact_lock (dist/service.js) | 1 |
| "Dedup lock acquired" (dist/service.js) | 1 |
| "Idempotent skip" (dist/service.js) | 1 |
| amzmsg scope | 2 |
| thread scope | 2 |
| stableAmazonMessageKey (dist/service.js) | 4 |
| OUTBOUND_EMAIL_SEND (dist/jobsWorker.js) | 5 |
| jobsWorker heartbeat | 2 |
| sendOutboundEmailById (dist/jobsWorker.js) | 2 |
| NOT IMPLEMENTED OUTBOUND (dist/jobsWorker.js) | 0 |
| INBOUND_EMAIL_PROCESS stub (distinct) | 1 |
| @map to (DMMF OutboundEmail.toAddress.dbName) | to |
| hardcode 4xfub8/3jcpvk/cp2hat/as0yom/order dans dist | 0 |

## 8. No side-effect (E7)

| Garantie | etat |
|---|---|
| GHCR v1.0.56-amazon-inbound-dedup-prod | ABSENT (non pousse) |
| runtime DEV API + jobs-worker | v1.0.56-amazon-inbound-dedup-dev (inchange) |
| runtime PROD API + jobs-worker | v1.0.55-amazon-inbound-dedup-prod (inchange) |
| manifest ref v1.0.56-prod | aucun |
| pod restart (PROD) | 0 |
| DB / email / trigger / replay / fake | 0 |
| kubectl apply/set/patch/edit/restart | 0 |
| latest | non touche |

## 9. Cleanup (E8)

Worktree retire via git worktree remove (sans --force), absent de git worktree list. Image locale v1.0.56-amazon-inbound-dedup-prod (179af6fb0632) CONSERVEE pour push ulterieur. Aucun container d'audit residuel (docker run --rm).

## 10. AI feature parity / anti-regression

Le patch ne modifie pas IA / escalades / assignment / statuts / historique (PH-20.26 = serialisation de la section dedup, fallback legacy conserve). Guard validation + OUTBOUND_EMAIL_SEND presents dans le dist (5, sendOutboundEmailById 2). jobsWorker observability (heartbeat 2) conservee. Pipeline restaure KEY-323 non touche. Le travail non-critique (MinIO/attachments/stats/autopilot) reste apres COMMIT (transaction courte). Image PROD = meme code/dist que DEV v1.0.56 (meme commit 78bfb94, prouve runtime en PH-20.30-BIS) ; Image ID distinct car labels OCI version/created PROD differents.

## 11. Limites restantes

- CONTRAINTE UNIQUE DB : durcissement stockage differe (post-cleanup doublons).
- CROSS-TENANT (4xfub8 ecomlg-001 / as0yom ecomlg-motxke32) : non corrige (decision produit).
- Reply-to obsoletes (3jcpvk/cp2hat) : retrait Seller Central separe.
- Cleanup des doublons existants : phase separee (jamais DELETE ad hoc).
- v1.0.55-prod actuel non garanti race-safe (a remplacer par v1.0.56-prod).

## 12. Next GO

GO PUSH IMAGE BACKEND ATOMIC AMAZON INBOUND DEDUP PROD PH-SAAS-T8.12AS.20.32 (push GHCR + pull-back digest match), puis GO APPLY BACKEND AND JOBSWORKER PROD GITOPS PH-SAAS-T8.12AS.20.33 (bump deployment.yaml API PROD + deployment-jobs-worker.yaml PROD v1.0.55-prod -> v1.0.56-prod, commit+push AVANT apply, rollout, verifier digest + no unintended processing).

## 13. Phrase cible

GO BUILD BACKEND ATOMIC AMAZON INBOUND DEDUP PROD READY PH-SAAS-T8.12AS.20.31

STOP.
