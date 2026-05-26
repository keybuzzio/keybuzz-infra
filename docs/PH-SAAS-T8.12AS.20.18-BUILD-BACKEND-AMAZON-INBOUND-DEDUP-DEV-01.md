# PH-SAAS-T8.12AS.20.18-BUILD-BACKEND-AMAZON-INBOUND-DEDUP-DEV-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.18 (BUILD BACKEND AMAZON INBOUND DEDUP DEV)
> Environnement : DEV preparation, BUILD ONLY (aucun push GHCR / deploy / kubectl / DB / trigger)

## 1. Verdict

GO BUILD BACKEND AMAZON INBOUND DEDUP DEV READY PH-SAAS-T8.12AS.20.18

Image backend DEV v1.0.55-amazon-inbound-dedup-dev construite localement from-git 78c450c (worktree detache propre), embarquant le patch dedup inbound Amazon PH-20.17 (idempotence tenant-scopee par metadata.amazonIds.messageId avant fallback SES). OCI labels conformes, markers dist verifies, tests pre-build OK. Aucun push GHCR, aucun deploy, aucun kubectl, aucune DB/migration/trigger/fake event. Runtime DEV (v1.0.54-dev) et PROD (v1.0.54-prod) inchanges. P0 KEY-323 non touche.

## 2. Source

| Item | Valeur |
|---|---|
| repo | keybuzz-backend |
| branche | main |
| commit from-git | 78c450c3e23746b42b121e08dc63942922797777 |
| HEAD = origin/main | oui |
| dirty | src/modules/marketplaces/amazon/amazon.routes.ts.bak (cruft historique, exclu ; worktree porcelain=0) |

## 3. Image construite

| Item | Valeur |
|---|---|
| tag | ghcr.io/keybuzzio/keybuzz-backend:v1.0.55-amazon-inbound-dedup-dev |
| Image ID | sha256:8e2b4d0399be748a2436160412fa270a03ea36248a13c34f2adbf04efe1e9e8e |
| OCI revision | 78c450c3e23746b42b121e08dc63942922797777 |
| OCI version | v1.0.55-amazon-inbound-dedup-dev |
| OCI created | 2026-05-26T21:55:46Z |
| push GHCR | NON (build only) |
| latest | NON touche |

## 4. Tests pre-build (E4)

| Test | Attendu | Resultat |
|---|---|---|
| prisma generate | OK | OK |
| tsc --noEmit | EXIT 0 | EXIT 0 |
| ph2017-inbound-dedup | 13/13 | 13 passed, 0 failed |
| ph2014w-real-inbound-validation | 10/10 | 10 passed, 0 failed |
| ph2014o-validation-address-casing | 9/9 | 9 passed, 0 failed |
| ph2014i-validation-address | 11/11 | 11 passed, 0 failed |

## 5. Markers dist (E6, image construite)

| Marker | Attendu | Resultat |
|---|---|---|
| dist/.../inboundDedup.js extractStableAmazonMessageKey | present | 2 |
| inboundDedup.js amazonIds | present | 2 |
| inboxConversation.service.js stableAmazonMessageKey (bloc idempotence) | present | 3 |
| service requete SQL metadata->'amazonIds'->>'messageId' | present | present (verifie) |
| service fallback SES "based on messageId" | present | 1 |
| jobsWorker.js OUTBOUND_EMAIL_SEND | present | 5 |
| jobsWorker.js sendOutboundEmailById (handler implemente) | present | 2 |
| jobsWorker.js heartbeat (observabilite) | present | 2 |
| OUTBOUND_EMAIL_SEND not implemented | 0 | 0 (seul INBOUND_EMAIL_PROCESS not implemented, job type distinct pre-existant) |
| @map("to") -> colonne "to" (client Prisma genere) | present | present (1) |
| hardcode ecomlg/4xfub8/as0yom | 0 | 0 |

## 6. No side-effect (E7)

| Garantie | etat |
|---|---|
| GHCR v1.0.55 | ABSENT (non pousse) |
| runtime backend DEV | v1.0.54-amazon-validation-pipeline-dev (inchange) |
| runtime backend PROD | v1.0.54-amazon-validation-pipeline-prod (inchange) |
| manifests referencant v1.0.55 | aucun |
| pods backend DEV restarts | 0 |
| docker push / deploy / kubectl | 0 |
| DB / migration / email / trigger / replay / fake event | 0 |

## 7. Cleanup (E8)

Worktree /opt/keybuzz/build-worktrees/PH-20.18-backend-dedup retire via git worktree remove (sans --force), 0 worktree PH-20.18 restant. Container d'audit ephemere (docker run --rm). Image locale v1.0.55-amazon-inbound-dedup-dev CONSERVEE pour la phase push.

## 8. AI feature parity / anti-regression

Patch limite a l'ingestion inbound (inboxConversation.service.js + inboundDedup.js). Verifie inchanges : OUTBOUND_EMAIL_SEND implemente (sendOutboundEmailById present), jobsWorker observabilite present, @map("to") present, validation guard (chaine PH-20.14W) intacte. Aucune modification IA/escalades/assignment/statuts/historique. Pipeline restaure KEY-323 non regresse (build only, runtime inchange).

## 9. Linear (E10)

Commentaire KEY-323 + KEY-337 (statuts inchanges) : build DEV v1.0.55 from 78c450c, dedup patch present, tests OK, no push/deploy.

## 10. Next GO

GO PUSH IMAGE BACKEND AMAZON INBOUND DEDUP DEV PH-SAAS-T8.12AS.20.19 (docker push GHCR + pull-back digest verify), puis GO APPLY BACKEND AND JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.20 (bump deployment.yaml + deployment-jobs-worker.yaml DEV v1.0.54 -> v1.0.55, commit+push manifest avant apply, rollout, verif runtime=digest), puis verif runtime dedup sur vrai message ou replay controle (sans fake event).

## 11. Phrase cible

GO BUILD BACKEND AMAZON INBOUND DEDUP DEV READY PH-SAAS-T8.12AS.20.18

STOP.
