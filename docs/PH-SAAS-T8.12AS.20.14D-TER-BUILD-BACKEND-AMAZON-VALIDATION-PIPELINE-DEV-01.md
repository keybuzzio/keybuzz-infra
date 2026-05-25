# PH-SAAS-T8.12AS.20.14D-TER-BUILD-BACKEND-AMAZON-VALIDATION-PIPELINE-DEV-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14C / C-BIS / C-TER / D-BIS / F-BIS / G
> Phase : PH-SAAS-T8.12AS.20.14D-TER (BUILD ONLY backend DEV from-git)
> Environnement : DEV (build local uniquement ; aucun push, aucun deploy, aucune mutation)

## 1. Verdict

GO BUILD BACKEND AMAZON VALIDATION PIPELINE DEV READY PH-SAAS-T8.12AS.20.14D-TER

Image backend DEV immuable construite from-git depuis le commit 2a14258 (worktree detache propre), tag v1.0.50-amazon-validation-pipeline-dev. OCI revision = 2a14258. L image embarque les 3 briques : OUTBOUND_EMAIL_SEND implemente, filtrage JOB_TYPES, et mapping Prisma OutboundEmail.toAddress @map("to"). prisma generate OK, typecheck OK, tests 16/16 + 15/15, DMMF mapping prouve (dbName="to"). Audit dist OK. Aucun push GHCR, aucun deploy, aucun manifest, aucune mutation DB, aucun email. jobs-worker DEV inchange (v1.0.49). Worktree nettoye sans --force.

Prochaine phrase GO : GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE DEV PH-SAAS-T8.12AS.20.14E-TER.

## 2. Sources relues

- PH-SAAS-T8.12AS.20.14C-TER-SOURCE-PATCH-OUTBOUNDEMAIL-SCHEMA-MAP-DEV-01.md (cause + correctif @map)
- PH-SAAS-T8.12AS.20.14D-BIS (build precedent v1.0.49)
- PH-SAAS-T8.12AS.20.14F-BIS (deploy jobs-worker DEV)
- PH-SAAS-T8.12AS.20.14G (retrigger PARTIAL, HTTP 500 column toAddress)
- AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS, KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH, CE_PROMPTING_STANDARD

## 3. Preflight

| Repo/Service | Branche/Image | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-backend | main | 2a14258 = origin/main | non (sauf amazon.routes.ts.bak untracked historique) | OK |
| keybuzz-infra | main | 0f1670c | non | OK |
| jobs-worker DEV | v1.0.49-amazon-validation-pipeline-dev | n/a | Running, restarts=0 | OK |
| v1.0.50 deploye | non | n/a | n/a | OK (attendu non deploye) |

Bastion install-v3 / 46.62.171.61 confirme. backend HEAD == origin == 2a14258.

## 4. Tag collision

| Tag | Local | GHCR | Verdict |
|---|---|---|---|
| ghcr.io/keybuzzio/keybuzz-backend:v1.0.50-amazon-validation-pipeline-dev | ABSENT (avant build) | ABSENT | OK, pas d ecrasement |

## 5. Worktree

| Worktree | HEAD | Dirty | Verdict |
|---|---|---|---|
| /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.14D-TER-.../keybuzz-backend | 2a14258 | 0 (porcelain vide) | OK |

git worktree add --detach 2a14258. Le fichier .bak du working tree principal n est PAS present dans le worktree detache.

## 6. Source audit (pre-build)

| Marker | Count/Result | Verdict |
|---|---|---|
| sendOutboundEmailById | 2 fichiers src | OK |
| OUTBOUND_EMAIL_SEND | 6 fichiers src | OK |
| claimNextJob(workerId, jobTypes?) | jobs.service.ts:98 | OK |
| buildClaimJobQuery | 1 fichier | OK |
| parseJobTypesEnv | 2 fichiers | OK |
| process.env.JOB_TYPES | jobsWorker.ts:26 | OK |
| toAddress String @map("to") | schema.prisma:538 | OK |
| worker:jobs / worker:jobs:once | package.json:17-18 | OK |
| "not implemented" | uniquement INBOUND_EMAIL_PROCESS (hors scope) | OK |
| prisma migrate / db push dans src | ABSENT | OK |
| hardcode tenant/email | aucun (noreply@keybuzz.io = defaut SMTP_FROM surchargeable) | OK |

## 7. Tests (pre-build, worktree, npm ci isole)

| Test | Commande | Resultat | Verdict |
|---|---|---|---|
| prisma generate | npx prisma generate | EXIT 0 (pas de migrate/db push) | OK |
| DMMF mapping | OutboundEmail.toAddress.dbName | "to" -> MAP_OK=true | OK |
| typecheck | npx tsc --noEmit -p tsconfig.json | TSC_OK | OK |
| PH-20.14C-BIS | tests/ph2014cbis-jobscope.test.ts | 16 passed, 0 failed | OK |
| PH-20.14C | tests/ph2014c-outboundEmail.test.ts | 15 passed, 0 failed | OK |

Aucun SMTP reel, aucune DB reelle (DATABASE_URL dummy non connectable). Aucun OutboundEmail cree.

## 8. Build

| Item | Valeur | Verdict |
|---|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-backend:v1.0.50-amazon-validation-pipeline-dev | OK |
| Image ID | sha256:7e8a056cb53e70147cd4c32aa65ec1d1f11d29549cea8754d7316e1ed8005876 | OK |
| Size | 613902412 octets (~614 MB) | OK |
| OCI revision | 2a142587533e77546fb10d353a0acc86f8a7a754 | OK |
| OCI version | v1.0.50-amazon-validation-pipeline-dev | OK |
| Push | aucun (build local only) | OK |

Labels OCI : revision, version, source, created, title, description. Build depuis worktree propre 2a14258.

## 9. Image audit (sans run serveur)

| Check image | Resultat | Verdict |
|---|---|---|
| dist extrait (docker create + cp) | OK | OK |
| sendOutboundEmailById (dist) | 2 fichiers | OK |
| OUTBOUND_EMAIL_SEND (dist) | 3 fichiers | OK |
| parseJobTypesEnv (dist) | 2 fichiers | OK |
| buildClaimJobQuery (dist) | 1 fichier | OK |
| JOB_TYPES (dist) | 2 fichiers | OK |
| "not implemented" dans dist/workers/jobsWorker.js | uniquement INBOUND_EMAIL_PROCESS | OK |
| Prisma generated client schema | toAddress String @map("to") L538 | OK |

Le mapping @map("to") est bien embarque dans le client Prisma genere de l image runtime.

## 10. Side effects

| Side effect | Count/Preuve | Verdict |
|---|---|---|
| docker push | 0 (v1.0.50 ABSENT de GHCR) | OK |
| kubectl mutation | 0 | OK |
| manifest modifie | 0 | OK |
| pod restart | jobs-worker restarts=0, inchange | OK |
| DB mutation | 0 | OK |
| email envoye | 0 | OK |
| trigger validation | 0 | OK |
| v1.0.50 deploye | non | OK |

## 11. Anti-regression / AI feature parity

| Feature | Contract | Impact build | Verdict |
|---|---|---|---|
| Amazon outbound From | = tenant inbound address | inchange (image embarque le code stable) | OK |
| Guard outbound | validationStatus=VALIDATED requis | inchange | OK |
| Inbound webhook | preserve | inchange | OK |
| PH-20.11C guardrails | preserve | inchange | OK |
| PH-20.12B no-reply KBActions | preserve | inchange | OK |
| PH-20.13B Client | suspendu | non touche | OK |
| outbound deliveries marketplace | pas de retry | non touche | OK |
| jobsWorker JOB_TYPES=OUTBOUND_EMAIL_SEND | protege AMAZON_POLL (futur deploy) | code present dans image | OK |

Le build n introduit aucune regression : il embarque exactement le commit 2a14258 (worker scope + handler + mapping). Aucune route, aucun guard modifie.

## 12. No fake metrics / events

| Object | Build/test allowed | Runtime forbidden | Verdict |
|---|---|---|---|
| OutboundEmail | mock en tests | aucun create runtime | OK |
| webhook validation | n/a | aucun fake | OK |
| delivery | n/a | aucun fake | OK |
| KBActions / dashboard metric | n/a | aucun fake | OK |

Tests mocks uniquement. Runtime DB/email non touche.

## 13. Cleanup

| Cleanup | Resultat | Verdict |
|---|---|---|
| /tmp audit (dist + logs) | supprime | OK |
| git worktree remove (sans --force) | WT_REMOVED | OK |
| git worktree list | uniquement main 2a14258 | OK |
| image locale v1.0.50 | conservee (PRESENT_OK) | OK |

## 14. Rollback

| Element | Rollback | Runtime impact |
|---|---|---|
| Runtime | N/A (aucune image deployee) | aucun |
| Image locale | docker rmi v1.0.50-... si besoin | aucun |
| Source | revert 2a14258 (demande separee uniquement) | aucun |
| Docs | revert commit rapport infra si erreur doc | aucun |

## 15. Prochaine phrase GO

GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE DEV PH-SAAS-T8.12AS.20.14E-TER

Puis seulement apres push : GO APPLY BACKEND AND JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.14F-TER.

Ne PAS proposer de re-trigger validation avant que API DEV ET jobs-worker DEV tournent tous les deux sur v1.0.50.

STOP.
