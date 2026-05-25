# PH-SAAS-T8.12AS.20.14C-BIS-SOURCE-PATCH-JOBSWORKER-SCOPE-DEV-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14C / PH-20.14D / PH-20.14E / PH-20.14F (suspendu) / PH-20.14F-SMTP
> Phase : PH-SAAS-T8.12AS.20.14C-BIS-SOURCE-PATCH-JOBSWORKER-SCOPE-DEV
> Environnement : DEV source patch only (no build, no deploy, no DB mutation, no email)

## 1. Verdict

GO SOURCE PATCH JOBSWORKER OUTBOUND_EMAIL_SEND SCOPE DEV READY PH-SAAS-T8.12AS.20.14C-BIS

Le jobsWorker peut maintenant etre scope par type de job via un filtre OPTIONNEL JOB_TYPES, pour qu un worker validation dedie (JOB_TYPES=OUTBOUND_EMAIL_SEND) ne claim JAMAIS AMAZON_POLL et n interfere pas avec les workers Amazon dedies. Defaut (sans JOB_TYPES) = comportement existant strictement inchange. tsc OK, 16/16 tests OK (sans DB ni SMTP reels). Commit source local cree, non pousse (gate GO push). L apply jobsWorker (PH-20.14F) reste SUSPENDU jusqu au build de cette image scopee.

## 2. Contexte (decision PH-20.14F)

A la reprise de PH-20.14F, le snapshot BEFORE de la Job queue DEV a montre une queue VIVANTE : AMAZON_POLL 1 PENDING + 3 RUNNING (dont 1 frais, worker actif) + 19 PENDING en cours d enqueue, drainee par les workers Amazon existants qui partagent claimNextJob. Le jobsWorker v1.0.48 etant GENERIQUE (claimNextJob sans filtre), le deployer aurait consomme spontanement des AMAZON_POLL (polls Amazon reels) en chevauchement -> condition STOP du prompt. Decision Ludovic : scoper le worker par type avant deploiement.

## 3. Root cause de la decision

- claimNextJob (jobs.service.ts) selectionne le prochain job PENDING/RETRY sans filtre de type.
- jobsWorker.ts est le SEUL caller de claimNextJob (verifie).
- jobsWorker.processJob gere 4 types : AMAZON_POLL, AMAZON_SEND_REPLY, INBOUND_EMAIL_PROCESS, OUTBOUND_EMAIL_SEND.
- En DEV, AMAZON_POLL est deja traite par les workers dedies (amazon-orders/items-worker) via la meme Job queue. Un jobsWorker validation generique ferait double emploi + polls reels.

## 4. Design patch

| Decision | Choix | Justification | Risque |
|---|---|---|---|
| Filtre type OPTIONNEL | claimNextJob(workerId, jobTypes?) | ne change pas le defaut ; seuls les workers dedies passent jobTypes | nul (defaut inchange) |
| Defaut inchange | jobTypes undefined -> aucune clause type | preserve comportement existant (workers Amazon, etc.) | nul |
| Allowlist non vide | type::text IN (...) | scope strict au(x) type(s) demande(s) | faible |
| Allowlist vide explicite | AND false (claim rien) | fail-safe : JOB_TYPES mal configure ne retombe JAMAIS sur AMAZON_POLL | nul |
| jobsWorker lit JOB_TYPES | parseJobTypesEnv(process.env.JOB_TYPES) | env-driven ; unset -> tous types ; inconnus droppes | faible |
| Parser dans jobs.service | parseJobTypesEnv co-localise avec buildClaimJobQuery | import-light + testable sans tirer amazon.poller | nul |
| type::text IN | cast enum->text | evite les soucis de cast enum vs param texte | nul |

Le futur Deployment jobs-worker validation devra avoir JOB_TYPES=OUTBOUND_EMAIL_SEND.

## 5. Fichiers modifies

| Fichier | Changement | Risque | Test |
|---|---|---|---|
| src/modules/jobs/jobs.service.ts | + parseJobTypesEnv, + buildClaimJobQuery (pur), claimNextJob(workerId, jobTypes?) delegue a buildClaimJobQuery | faible | tsc + ts-node |
| src/workers/jobsWorker.ts | import parseJobTypesEnv ; const JOB_TYPES = parseJobTypesEnv(process.env.JOB_TYPES) ; claimNextJob(WORKER_ID, JOB_TYPES) ; log scope | faible | tsc |
| tests/ph2014cbis-jobscope.test.ts | nouveau test standalone ts-node (hors src) | nul | execute |

Diff : 3 files changed, 153 insertions, 16 deletions. Le .bak untracked n est PAS commit. La signature OUTBOUND_EMAIL_SEND -> sendOutboundEmailById (PH-20.14C) est inchangee.

## 6. Tests (repo canonical @ HEAD, node_modules presents)

| Test | Commande | Resultat | Verdict |
|---|---|---|---|
| Typecheck complet | npx tsc --noEmit -p tsconfig.json | TSC_OK | OK |
| no-filter = comportement existant (pas de clause type) | ts-node | PASS | OK |
| filter OUTBOUND_EMAIL_SEND = type::text IN, exclut AMAZON_POLL | ts-node | PASS | OK |
| empty allowlist = AND false (claim rien) | ts-node | PASS | OK |
| parse undefined/empty/whitespace -> undefined (tous types) | ts-node | PASS | OK |
| parse OUTBOUND_EMAIL_SEND -> [that], exclut AMAZON_POLL | ts-node | PASS | OK |
| parse multi / trim / drop inconnu / all-unknown -> [] | ts-node | PASS | OK |
| OUTBOUND_EMAIL_SEND continue d appeler sendOutboundEmailById | ts-node | PASS | OK |
| Total 14C-BIS | ts-node | 16 passed, 0 failed | OK |
| Non-regression 14C (sendOutboundEmailById) | ts-node tests/ph2014c-outboundEmail.test.ts | 15 passed, 0 failed | OK |

Couvre les 4 tests imposes par le reviewer (no-filter preserve, filter OUTBOUND only, jobsWorker ignore AMAZON_POLL via parse+filter, OUTBOUND_EMAIL_SEND -> sendOutboundEmailById). buildClaimJobQuery teste via Prisma.Sql (.sql + .values) sans DB. ts-node typecheck les tests (hors tsconfig.include) en plus de tsc src.

## 7. Side effects

| Side effect | Preuve | Verdict |
|---|---|---|
| build image | aucun | AUCUN |
| deploy / kubectl mutation | aucun | AUCUN |
| jobsWorker deploye | toujours absent DEV | AUCUN |
| mutation DB | test = store mocke + DATABASE_URL factice non joignable | AUCUN |
| email reel | aucun | AUCUN |
| trigger validation | aucun | AUCUN |
| comportement workers Amazon existants | inchange (defaut claimNextJob sans jobTypes) | PRESERVE |

## 8. Anti-regression / AI feature parity

| Feature | Contrat | Impact | Verdict |
|---|---|---|---|
| Workers Amazon dedies (orders/items) | claimNextJob sans jobTypes = tous types | non touche (defaut inchange) | PRESERVE |
| Amazon outbound From / guard VALIDATED | inchange | aucun rapport | PRESERVE |
| webhook inbound / PH-20.11C / PH-20.12B | inchange | aucun rapport | PRESERVE |
| OUTBOUND_EMAIL_SEND -> sendOutboundEmailById | inchange (PH-20.14C) | signature preservee | PRESERVE |
| PH-20.13B Client | suspendu | non repris | SUSPENDU |

## 9. No fake metrics / events

Aucun fake ; tests mocks uniquement (store + sender). Aucune ecriture DB runtime, aucun email.

## 10. Interdits respectes

| Interdit | Respecte |
|---|---|
| build / docker push / deploy / kubectl apply | OUI |
| modifier workers Amazon existants | OUI (defaut claimNextJob inchange) |
| changer le defaut de claimNextJob | OUI (filtre optionnel) |
| DB mutation runtime / email reel | OUI |
| .bak commit | OUI (exclu) |

## 11. Commits source

| Repo | Branche | Commit local | Pousse | Gate |
|---|---|---|---|---|
| keybuzz-backend | main | 71e66c9 | NON | GO push requis |
| keybuzz-infra | main | (ce rapport, local) | NON | GO push requis |

## 12. Gaps restants

- Build de l image scopee : il faut une nouvelle image backend incluant 71e66c9 (PH-20.14D-bis build + 14E-bis push) avant de redeployer le jobsWorker. L image v1.0.48 (PH-20.14E) ne contient PAS encore le filtre JOB_TYPES.
- Reprise PH-20.14F : Deployment jobs-worker avec JOB_TYPES=OUTBOUND_EMAIL_SEND + SMTP cas 1 (PH-20.14F-SMTP : 49.13.35.167:25).
- 2 jobs AMAZON_POLL RUNNING stale (lockedAt 2026-04-10) en DEV : residus de workers morts, hors scope (a nettoyer separement si besoin).

## 13. Rollback

| Element | Rollback | Runtime impact |
|---|---|---|
| Commit backend 71e66c9 | git revert (apres push) ou reset local si non pousse | aucun (pas deploye) |
| Rapport infra | git revert du commit docs | aucun |

## 14. Prochaine phrase GO

GO BUILD BACKEND AMAZON VALIDATION PIPELINE DEV PH-SAAS-T8.12AS.20.14D-BIS

Rebuild image backend DEV depuis le commit scope (71e66c9), tag immuable suivant (ex v1.0.49-amazon-validation-pipeline-dev, schema backend v1.0.x), puis push (14E-bis), puis reprise PH-20.14F avec JOB_TYPES=OUTBOUND_EMAIL_SEND + SMTP cas 1. Ne PAS deployer l image v1.0.48 (generique). Ne PAS re-trigger validation avant jobsWorker DEV scope deploye et healthy.

STOP.
