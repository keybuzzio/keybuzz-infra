# PH-SAAS-T8.12AS.20.22-BUILD-BACKEND-AMAZON-INBOUND-DEDUP-PROD-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.22 (BUILD BACKEND PROD ONLY)
> Environnement : PROD preparation (BUILD ONLY ; aucun push/deploy/kubectl/DB/trigger)

## 1. Verdict

GO BUILD BACKEND AMAZON INBOUND DEDUP PROD READY PH-SAAS-T8.12AS.20.22

Image PROD v1.0.55-amazon-inbound-dedup-prod construite from-git (worktree detache 78c450c, porcelain=0), Image ID sha256:7e2f123673ed, OCI revision 78c450c complet, OCI version v1.0.55-amazon-inbound-dedup-prod. Tests pre-build OK (prisma generate, DMMF MAP to, tsc EXIT 0, ph2017 13/13, ph2014w 10/10, ph2014o 9/9, ph2014i 11/11). Markers dist verifies (dedup amazonIds.messageId + fallback SES + @map to + OUTBOUND + observability). LOCALE UNIQUEMENT, non poussee GHCR. Aucun deploy/kubectl/DB/trigger. Runtime DEV v1.0.55-dev + PROD v1.0.54-prod inchanges, PROD restarts=0. Limites connues conservees : race (sans contrainte unique DB) + cross-tenant non corriges par ce patch.

## 2. Preflight (E0) + collision (E1)

| Repo | Branche | HEAD | origin/main | dirty | verdict |
|---|---|---|---|---|---|
| keybuzz-backend | main | 78c450c | 78c450c | amazon.routes.ts.bak (cruft historique) | OK |
| keybuzz-infra | main | 1c029b2 | - | clean | OK |

Bastion install-v3 / 46.62.171.61, date 2026-05-27 08:39Z. Collision : image locale PROD v1.0.55 ABSENTE, GHCR PROD v1.0.55 ABSENT, aucun manifest k8s/keybuzz-backend-prod ne reference v1.0.55-prod. Runtime informatif : DEV v1.0.55-amazon-inbound-dedup-dev, PROD v1.0.54-amazon-validation-pipeline-prod.

## 3. Worktree (E2)

git worktree add --detach /opt/keybuzz/build-worktrees/PH-20.22-backend-dedup-prod 78c450c3e23746b42b121e08dc63942922797777 ; HEAD worktree = 78c450c, porcelain=0. node_modules NON symlinke avant docker build (incident PH-20.18 evite ; symlinke uniquement pour les tests E4 puis retire avant E5).

## 4. Source audit (E3)

| Marker | Attendu | Resultat |
|---|---|---|
| extractStableAmazonMessageKey (inboundDedup.ts) | present | 1 |
| import helper (service) | present | 1 |
| idempotence query amazonIds.messageId (service) | present | 1 |
| bloc idempotence AVANT fallback SES | ordre | L283 (stableAmazonMessageKey) < L308 (SES messageId) |
| fallback SES rawPreview conserve | present | 1 |
| @map("to") OutboundEmail (schema) | present | 1 |
| OUTBOUND_EMAIL_SEND (jobsWorker) | present | 5 |
| jobsWorker heartbeat observability | present | 2 |
| NOT IMPLEMENTED OUTBOUND | 0 | 0 |
| hardcode 4xfub8/3jcpvk/cp2hat/as0yom/order reel | 0 | 0 |

NB pre-existant hors patch : amazonFees.routes.ts L101 `const tenantId = tenant_id || "ecomlg-001"` = fallback tech-debt d'une route Amazon Fees SANS lien avec le chemin dedup (PH-20.17 ne touche que inboundDedup.ts + inboxConversation.service.ts + tests) ; present a l'identique dans le DEV v1.0.55 deja deploye ; pas une regression de cette phase ; a traiter en hygiene separee.

## 5. Tests pre-build (E4)

| Test | Attendu | Resultat |
|---|---|---|
| prisma generate | OK | OK |
| DMMF OutboundEmail.toAddress.dbName | to | to |
| tsc --noEmit | EXIT 0 | EXIT 0 |
| ph2017-inbound-dedup | pass | 13 passed, 0 failed |
| ph2014w | pass | 10 passed, 0 failed |
| ph2014o | pass | 9 passed, 0 failed |
| ph2014i | pass | 11 passed, 0 failed |

## 6. Docker build PROD (E5)

Image ghcr.io/keybuzzio/keybuzz-backend:v1.0.55-amazon-inbound-dedup-prod construite depuis le worktree propre. Build-args : IMAGE_REVISION=78c450c3e23746b42b121e08dc63942922797777, IMAGE_VERSION=v1.0.55-amazon-inbound-dedup-prod, IMAGE_CREATED=2026-05-27T08:41:51Z. Aucun latest. Aucun push. BUILD_OK (Successfully built 7e2f123673ed).

## 7. Audit image (E6)

| Item | Valeur / Resultat |
|---|---|
| Image ID | sha256:7e2f123673edd54a91fe2465002463f448bf83d5ab59a687504a13e87006c4b2 |
| OCI image.revision | 78c450c3e23746b42b121e08dc63942922797777 |
| OCI image.version | v1.0.55-amazon-inbound-dedup-prod |
| OCI image.created | 2026-05-27T08:41:51Z |
| extractStableAmazonMessageKey (dist/inboundDedup.js) | 2 |
| idempotence amazonIds.messageId (dist/service.js) | 1 |
| bloc stableAmazonMessageKey (dist/service.js) | 3 |
| fallback SES rawPreview (dist/service.js) | 1 |
| OUTBOUND_EMAIL_SEND (dist/jobsWorker.js) | 5 |
| jobsWorker heartbeat | 2 |
| sendOutboundEmailById (dist) | present |
| NOT IMPLEMENTED OUTBOUND | 0 |
| @map to (client Prisma genere dans l'image) | present |
| hardcode 4xfub8/3jcpvk/cp2hat/as0yom/order dans dist | 0 |

## 8. No side-effect (E7)

| Garantie | etat |
|---|---|
| GHCR PROD v1.0.55-amazon-inbound-dedup-prod | ABSENT (non pousse) |
| runtime DEV API + jobs-worker | v1.0.55-amazon-inbound-dedup-dev (inchange) |
| runtime PROD API + jobs-worker | v1.0.54-amazon-validation-pipeline-prod (inchange) |
| manifest PROD ref v1.0.55-prod | aucun |
| PROD pod restarts | 0 |
| DB / email / trigger / replay / fake | 0 |
| kubectl apply/set/patch/edit/restart | 0 |

## 9. Cleanup (E8)

Worktree retire via git worktree remove (sans --force), absent de git worktree list. Image locale v1.0.55-amazon-inbound-dedup-prod (7e2f123673ed) CONSERVEE pour push ulterieur. Aucun container d'audit residuel (docker run --rm).

## 10. AI feature parity / anti-regression

Le patch ne modifie pas IA / escalades / assignment / statuts / historique (PH-20.17 = idempotence ingestion uniquement, scope tenant). Guard validation + sendOutboundEmailById + OUTBOUND_EMAIL_SEND presents dans le dist (5 + present). jobsWorker observability (heartbeat 2) conservee. Fallback SES conserve (chemin order:/non-Amazon non regresse). Pipeline restaure KEY-323 non touche.

## 11. Limites restantes

- RACE : dedup = SELECT-puis-skip sans contrainte unique DB -> sous redeliveries quasi-simultanees (cas PROD du 06:29, 4 POST en 229 ms) la collapse 3->1 n'est pas garantie. A fermer par contrainte unique DB produit (tenant_id, amazonIds.messageId / thread_key), phase separee.
- CROSS-TENANT : idempotence tenant-scopee ne fusionne pas le doublon ecomlg-001 / ecomlg-motxke32. Decision produit + cleanup data separes.
- Adresses reply-to obsoletes (3jcpvk/cp2hat) cote Amazon Seller Central : hors scope, retrait manuel separe.

## 12. Next GO

GO PUSH IMAGE BACKEND AMAZON INBOUND DEDUP PROD PH-SAAS-T8.12AS.20.23 (push GHCR + pull-back digest match), puis GO APPLY BACKEND AND JOBSWORKER PROD GITOPS PH-SAAS-T8.12AS.20.24 (bump deployment.yaml API PROD + deployment-jobs-worker.yaml PROD v1.0.54-prod -> v1.0.55-prod, commit+push manifest AVANT apply, rollout, verifier manifest=last-applied=runtime=digest + no unintended processing).

## 13. Phrase cible

GO BUILD BACKEND AMAZON INBOUND DEDUP PROD READY PH-SAAS-T8.12AS.20.22

STOP.
