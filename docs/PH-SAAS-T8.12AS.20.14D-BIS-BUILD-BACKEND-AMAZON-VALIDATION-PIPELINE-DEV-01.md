# PH-SAAS-T8.12AS.20.14D-BIS-BUILD-BACKEND-AMAZON-VALIDATION-PIPELINE-DEV-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14C / PH-20.14C-BIS / PH-20.14D / PH-20.14E / PH-20.14F (suspendu) / PH-20.14F-SMTP
> Phase : PH-SAAS-T8.12AS.20.14D-BIS-BUILD-BACKEND-AMAZON-VALIDATION-PIPELINE-DEV
> Environnement : DEV (BUILD ONLY ; no push, no deploy, no GitOps apply, no DB, no email)

## 1. Verdict

GO BUILD BACKEND AMAZON VALIDATION PIPELINE DEV READY PH-SAAS-T8.12AS.20.14D-BIS

Image backend DEV v1.0.49-amazon-validation-pipeline-dev construite from-git depuis le commit 71e66c9 (patch PH-20.14C-BIS scope JOB_TYPES). Worktree propre, tsc OK, 16/16 + 15/15 tests OK, build Docker reussi, audit image confirme : claimNextJob(jobTypes?), buildClaimJobQuery, parseJobTypesEnv, JOB_TYPES lu, OUTBOUND_EMAIL_SEND implemente, sendOutboundEmailById present. Aucun push, deploy, GitOps, DB, email. v1.0.48 (generique) ni v1.0.49 deploye.

## 2. Sources relues

| Source | Usage |
|---|---|
| PH-20.14C-BIS (commit 2414471) | patch scope JOB_TYPES |
| PH-20.14D (e35e2d2) | build precedent v1.0.48 (generique, obsolete pour jobsWorker) |
| PH-20.14E (138f065) | push v1.0.48 |
| PH-20.14F-SMTP (4a73620) | config SMTP DEV reutilisable |
| keybuzz-backend @ 71e66c9 | source build |

## 3. Preflight

| Repo/Service | Branche/Image | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| Bastion install-v3 | 46.62.171.61 | n/a | n/a | OK |
| keybuzz-backend | main | 71e66c9 = origin/main | 1 untracked .bak | OK (HEAD=origin attendu) |
| keybuzz-infra | main | 2414471 | clean | OK |
| jobsWorker DEV | deploy | absent | n/a | confirme absent |
| v1.0.48 / v1.0.49 deploye | n/a | aucun | n/a | confirme |

backend HEAD = origin/main = 71e66c9 : gate respecte.

## 4. Tag collision

| Tag | Local | GHCR | Manifests | Verdict |
|---|---|---|---|---|
| v1.0.49-amazon-validation-pipeline-dev | ABSENT | ABSENT | seulement doc PH-20.14C-BIS (reference, pas un manifest) | LIBRE, utilise |

## 5. Worktree

| Worktree | HEAD | Dirty | Verdict |
|---|---|---|---|
| /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.14D-BIS-.../keybuzz-backend | 71e66c9 | porcelain=0 | PROPRE |

## 6. Source audit (worktree)

| Marker | Resultat | Verdict |
|---|---|---|
| claimNextJob(workerId, jobTypes?) | present (jobs.service.ts) | OK |
| buildClaimJobQuery | present | OK |
| parseJobTypesEnv | present | OK |
| jobsWorker lit process.env.JOB_TYPES | const JOB_TYPES = parseJobTypesEnv(process.env.JOB_TYPES) | OK |
| claimNextJob(WORKER_ID, JOB_TYPES) | present | OK |
| sendOutboundEmailById | present (3 occurrences) | OK |
| OUTBOUND_EMAIL_SEND not implemented | 0 | OK |
| worker:jobs / worker:jobs:once | present | OK |
| secret / hardcode dans le patch | 0 | OK |

## 7. Tests (canonical @ 71e66c9, node_modules presents)

| Test | Commande | Resultat | Verdict |
|---|---|---|---|
| Typecheck | npx tsc --noEmit -p tsconfig.json | TSC_OK | OK |
| Scope JOB_TYPES | npx ts-node tests/ph2014cbis-jobscope.test.ts | 16 passed, 0 failed | OK |
| Validation send (14C) | npx ts-node tests/ph2014c-outboundEmail.test.ts | 15 passed, 0 failed | OK |

Tests mockes (store + sender), sans DB ni SMTP reels. Le build Docker re-execute tsc dans le builder : compilation propre en env clean.

## 8. Build

| Item | Valeur | Verdict |
|---|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-backend:v1.0.49-amazon-validation-pipeline-dev | OK |
| Image ID | sha256:684628279a70bcdb55964deecb707aab92bccd4b9b50da257a261355b8caf1b2 | OK |
| Size | 692432074 bytes (~660 MiB) | OK |
| OCI revision | 71e66c9b435a2de6cda4909b8a094b4b592b3192 | OK = 71e66c9 |
| OCI version | v1.0.49-amazon-validation-pipeline-dev | OK |
| OCI created | 2026-05-25T19:52:02Z | OK |
| Build exit | 0 (28/28 steps) | OK |
| docker push | NON | OK |

## 9. Image audit (dist extrait)

| Check image | Resultat | Verdict |
|---|---|---|
| jobs.service: buildClaimJobQuery + parseJobTypesEnv | present (5 occ.) | OK |
| jobs.service: type::text IN / AND false | present (4 occ.) | OK |
| jobsWorker: JOB_TYPES / parseJobTypesEnv | present (8 occ.) | OK |
| jobsWorker: sendOutboundEmailById | present (2 occ.) | OK |
| OUTBOUND_EMAIL_SEND not implemented | 0 | OK |
| worker:jobs / worker:jobs:once dans package.json image | present | OK |

Le filtre JOB_TYPES est present dans le dist : l image v1.0.49 permet un jobsWorker scope (JOB_TYPES=OUTBOUND_EMAIL_SEND) qui ne claimera jamais AMAZON_POLL.

## 10. Side effects

| Side effect | Preuve | Verdict |
|---|---|---|
| docker push | image GHCR_ABSENT | AUCUN |
| deploy / kubectl mutation | aucune commande | AUCUN |
| v1.0.48 / v1.0.49 deploye | aucun deploy ne les reference | AUCUN |
| jobsWorker DEV | absent | AUCUN |
| commit backend | HEAD 71e66c9 inchange | AUCUN |
| manifest infra | HEAD 2414471, clean | AUCUN |
| DB mutation / email reel / trigger | aucun | AUCUN |
| worktree | retire sans --force | PROPRE |

## 11. Anti-regression / AI feature parity

| Feature | Contrat | Impact build | Verdict |
|---|---|---|---|
| Workers Amazon dedies (orders/items) | partagent claimNextJob (defaut sans jobTypes = tous types) | non touche ; le futur jobsWorker validation utilisera JOB_TYPES=OUTBOUND_EMAIL_SEND et ne claimera pas AMAZON_POLL | PROTEGE |
| Amazon outbound From / guard VALIDATED | inchange | aucun rapport | PRESERVE |
| inbound webhook / PH-20.11C / PH-20.12B | inchange | aucun rapport | PRESERVE |
| OUTBOUND_EMAIL_SEND -> sendOutboundEmailById | inchange (PH-20.14C) | preserve | PRESERVE |
| PH-20.13B Client | suspendu | non repris | SUSPENDU |
| v1.0.48 generique | obsolete pour jobsWorker validation | non utilise | DOCUMENTE OBSOLETE |

## 12. No fake metrics / events

| Objet | Build/test allowed | Runtime forbidden | Verdict |
|---|---|---|---|
| OutboundEmail / validation / webhook / delivery | mocks test uniquement | aucune ecriture runtime | OK |
| email SMTP | sender mocke | aucun email reel | OK |

## 13. Cleanup

| Cleanup | Resultat | Verdict |
|---|---|---|
| git worktree remove (sans --force) | REMOVED_OK | OK |
| worktree list | seul keybuzz-backend main 71e66c9 | OK |
| dist tmp extrait | rm -rf /tmp/ph2014dbis | OK |
| image locale v1.0.49 | conservee (684628279a70) | OK |

## 14. Rollback

| Element | Rollback | Runtime impact |
|---|---|---|
| Image locale v1.0.49 | docker rmi | aucun (non deployee, non poussee) |
| Source 71e66c9 | revert PH-20.14C-BIS si demande separee | aucun |
| Rapport infra | git revert commit docs | aucun |

## 15. Prochaine phrase GO

GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE DEV PH-SAAS-T8.12AS.20.14E-BIS

(push GHCR du tag v1.0.49-amazon-validation-pipeline-dev + verif digest pull-back).

Puis, apres push :
GO APPLY JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.14F-BIS

(Deployment jobs-worker keybuzz-backend-dev, image v1.0.49, command node dist/workers/jobsWorker.js, JOB_TYPES=OUTBOUND_EMAIL_SEND, SMTP cas 1 : SMTP_HOST=49.13.35.167 / SMTP_PORT=25 / SMTP_SECURE=false). Ne PAS deployer v1.0.48 (generique). Ne PAS re-trigger validation avant jobsWorker DEV scope deploye et healthy.

STOP.
