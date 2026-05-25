# PH-SAAS-T8.12AS.20.14J-BUILD-BACKEND-AMAZON-VALIDATION-PIPELINE-DEV-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14I / G-TER / F-TER / D-TER
> Phase : PH-SAAS-T8.12AS.20.14J (BUILD ONLY backend DEV from-git)
> Environnement : DEV (build local ; aucun push, aucun deploy, aucune mutation)

## 1. Verdict

GO BUILD BACKEND AMAZON VALIDATION PIPELINE DEV READY PH-SAAS-T8.12AS.20.14J

Image backend DEV immuable construite from-git depuis le commit cbbc99e (worktree detache propre), tag v1.0.51-amazon-validation-pipeline-dev, OCI revision cbbc99e. L image embarque le correctif PH-20.14I (resolution exacte d adresse par emailAddress via decideValidationAddress) en plus du mapping @map("to"), OUTBOUND_EMAIL_SEND, JOB_TYPES. prisma generate OK, DMMF MAP_OK, tsc OK, tests 11/11 + 16/16 + 15/15. Audit dist OK (decideValidationAddress + guards presents ; ancienne resolution tenantId_marketplace_country absente). Aucun push, aucun deploy, aucune mutation. API/jobs-worker DEV inchanges (v1.0.50). Worktree nettoye sans --force.

Prochaine phrase GO : GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE DEV PH-SAAS-T8.12AS.20.14K.

## 2. Sources relues

PH-20.14I (source patch resolution), PH-20.14G-TER (root cause), PH-20.14F-TER (deploy v1.0.50), PH-20.14D-TER (build precedent). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS, OPERATIONAL_SOURCE_OF_TRUTH.

## 3. Preflight

| Repo/Service | Branche/Image | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-backend | main | cbbc99e = origin/main | non (sauf amazon.routes.ts.bak untracked historique) | OK |
| keybuzz-infra | main | a893b22 | non | OK |
| API DEV | v1.0.50-amazon-validation-pipeline-dev | n/a | inchange | OK |
| jobs-worker DEV | v1.0.50-amazon-validation-pipeline-dev | n/a | inchange | OK |
| v1.0.51 deploye | non | n/a | n/a | OK (attendu non deploye) |

## 4. Tag collision

| Tag | Local | GHCR | Verdict |
|---|---|---|---|
| ghcr.io/keybuzzio/keybuzz-backend:v1.0.51-amazon-validation-pipeline-dev | ABSENT (avant build) | ABSENT | OK |

## 5. Worktree

| Worktree | HEAD | Dirty | Verdict |
|---|---|---|---|
| /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.14J-.../keybuzz-backend | cbbc99e | 0 | OK |

## 6. Source audit (pre-build)

| Marker | Count/Result | Verdict |
|---|---|---|
| decideValidationAddress | export L189 (1 fichier) | OK |
| processValidationEmail | present | OK |
| resolution emailAddress exact + findMany | findMany present ; tenantId_marketplace_country = 0 (ancien findUnique supprime) | OK |
| guards (Ambiguous address / Address token mismatch / Empty recipient) | L195/L200/L203 | OK |
| toAddress String @map("to") | schema.prisma:538 | OK |
| sendOutboundEmailById | 2 fichiers | OK |
| OUTBOUND_EMAIL_SEND | 6 fichiers | OK |
| process.env.JOB_TYPES | jobsWorker.ts:26 | OK |
| worker:jobs / worker:jobs:once | package.json:17-18 | OK |
| log redacted (pas de to brut) | L264 "resolved by exact emailAddress" | OK |
| "not implemented" | INBOUND_EMAIL_PROCESS uniquement | OK |
| migrate / db push / hardcode tenant-email | ABSENT | OK |

## 7. Tests (pre-build, worktree, npm ci isole)

| Test | Commande | Resultat | Verdict |
|---|---|---|---|
| prisma generate | npx prisma generate | GEN_OK | OK |
| DMMF mapping | OutboundEmail.toAddress.dbName | "to" -> MAP_OK=true | OK |
| typecheck | npx tsc --noEmit -p tsconfig.json | TSC_OK | OK |
| PH-20.14I | tests/ph2014i-validation-address.test.ts | 11 passed, 0 failed | OK |
| PH-20.14C-BIS | tests/ph2014cbis-jobscope.test.ts | 16 passed, 0 failed | OK |
| PH-20.14C | tests/ph2014c-outboundEmail.test.ts | 15 passed, 0 failed | OK |

Aucun SMTP reel, aucune DB reelle, aucun OutboundEmail cree.

## 8. Build

| Item | Valeur | Verdict |
|---|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-backend:v1.0.51-amazon-validation-pipeline-dev | OK |
| Image ID | sha256:fca5a28ab5c6a13e3ce34fac7b927a9b0b0beb1f985585966ffdc059007b039b | OK |
| Size | 613903863 octets (~614 MB) | OK |
| OCI revision | cbbc99e1fc484b52e8b2602e47eb38d04765a0f8 | OK |
| OCI version | v1.0.51-amazon-validation-pipeline-dev | OK |
| Push | aucun (build local only) | OK |

## 9. Image audit (sans run serveur)

| Check image | Resultat | Verdict |
|---|---|---|
| dist extrait (docker create + cp) | OK | OK |
| decideValidationAddress (dist) | 1 fichier | OK |
| Ambiguous address (dist) | present | OK |
| Address token mismatch (dist) | present | OK |
| log "resolved by exact emailAddress" (dist) | present | OK |
| tenantId_marketplace_country dans inbound.service.js | 0 (ancienne resolution absente) | OK |
| sendOutboundEmailById / OUTBOUND_EMAIL_SEND / JOB_TYPES (dist) | 2 / 3 / 2 | OK |
| "not implemented" dist jobsWorker | INBOUND_EMAIL_PROCESS uniquement | OK |
| Prisma generated client schema | toAddress String @map("to") L538 | OK |

## 10. Side effects

| Side effect | Count/Preuve | Verdict |
|---|---|---|
| docker push | 0 (v1.0.51 ABSENT GHCR) | OK |
| kubectl mutation / manifest | 0 | OK |
| pod restart | jobs-worker restarts=0, inchange | OK |
| DB mutation / email / trigger | 0 | OK |
| v1.0.51 deploye | non | OK |

## 11. Anti-regression / AI feature parity

| Feature | Contrat | Impact build | Verdict |
|---|---|---|---|
| Amazon outbound From | tenant inbound address | inchange | OK |
| Guard validationStatus=VALIDATED | non bypasse, renforce (adresse exacte) | ameliore | OK |
| Inbound webhook | resolution exacte par emailAddress | corrige (PH-20.14I) | OK |
| PH-20.11C / PH-20.12B / PH-20.13B | preserve / suspendu | non touche | OK |
| outbound deliveries marketplace | pas de retry | non touche | OK |
| jobsWorker JOB_TYPES=OUTBOUND_EMAIL_SEND | protege AMAZON_POLL | code present | OK |

L image embarque exactement le commit cbbc99e. Aucune route, aucun guard regresse.

## 12. No fake metrics / events

| Object | Build/test allowed | Runtime forbidden | Verdict |
|---|---|---|---|
| OutboundEmail / webhook / validation / KBActions | mock en tests | aucun runtime | OK |

Tests mocks uniquement. Runtime DB/email non touche.

## 13. Cleanup

| Cleanup | Resultat | Verdict |
|---|---|---|
| /tmp audit (dist + logs) | supprime | OK |
| git worktree remove (sans --force) | WT_REMOVED | OK |
| git worktree list | uniquement main cbbc99e | OK |
| image locale v1.0.51 | conservee (PRESENT_OK) | OK |

## 14. Rollback

| Element | Rollback | Runtime impact |
|---|---|---|
| Runtime | N/A (aucune image deployee) | aucun |
| Image locale | docker rmi v1.0.51-... si besoin | aucun |
| Source | revert cbbc99e (demande separee) | aucun |
| Docs | revert commit rapport infra si erreur doc | aucun |

## 15. Prochaine phrase GO

GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE DEV PH-SAAS-T8.12AS.20.14K

Puis seulement apres push : GO APPLY BACKEND AND JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.14L.

Ne PAS proposer de re-trigger validation avant que API DEV ET jobs-worker DEV tournent tous les deux sur v1.0.51.

STOP.
