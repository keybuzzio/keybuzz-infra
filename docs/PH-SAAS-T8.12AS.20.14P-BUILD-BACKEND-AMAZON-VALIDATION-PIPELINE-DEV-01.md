# PH-SAAS-T8.12AS.20.14P-BUILD-BACKEND-AMAZON-VALIDATION-PIPELINE-DEV-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14O / PH-20.14M / PH-20.14L
> Phase : PH-SAAS-T8.12AS.20.14P (BUILD ONLY image backend DEV from-git)
> Environnement : DEV (build local uniquement ; aucun push, aucun deploy, aucun GitOps apply)

## 1. Verdict

GO BUILD BACKEND AMAZON VALIDATION PIPELINE DEV READY PH-SAAS-T8.12AS.20.14P

Image backend DEV immuable construite from-git depuis commit 8f7122b (PH-20.14O). Tag v1.0.52-amazon-validation-pipeline-dev, Image ID sha256:645f326612d8, OCI revision = 8f7122bfec4e2ade80b0b98c8a82d3b658f12efb, OCI version = v1.0.52-amazon-validation-pipeline-dev. Worktree detache propre (HEAD 8f7122b, dirty=0). Tests pre-build OK (tsc + ph2014o 9/9 + ph2014i 11/11 + ph2014cbis 16/16 + ph2014c 15/15 + DMMF MAP_OK). Audit dist : tous les markers presents (decideValidationAddress, query emailAddress equals+insensitive, garde isValidationEmail(subject), updateMarketplaceStatusIfAmazon, @map("to"), sendOutboundEmailById, OUTBOUND_EMAIL_SEND, JOB_TYPES, worker:jobs/once) ; ancien pre-filtre toUpperCase dans processValidation = 0 ; not implemented OUTBOUND = 0. Aucun push GHCR, aucun deploy, aucun manifest, aucune DB mutation, aucun email, aucun trigger. Runtime DEV reste v1.0.51.

Prochaine phrase GO : GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE DEV PH-SAAS-T8.12AS.20.14Q (docker push v1.0.52 + pull-back digest), puis GO APPLY BACKEND AND JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.14R.

## 2. Sources relues

PH-20.14O (source patch BIS, fix casse marketplace), PH-20.14M (root cause), PH-20.14L (deploy v1.0.51). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS, KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH, CE_PROMPTING_STANDARD. Memoire agent : project_amazon_validation_pipeline_gap.

## 3. Preflight

| Repo/Service | Branche/Image | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| Bastion install-v3 / 46.62.171.61 | - | - | - | OK |
| keybuzz-backend | main | 8f7122b = origin/main | non (hors amazon.routes.ts.bak tracke) | OK |
| keybuzz-infra | main | cc6a25d (contient rapport PH-20.14O) | non | OK |
| API DEV (keybuzz-backend) | image v1.0.51 | - | - | OK (non touche) |
| jobs-worker DEV | image v1.0.51 | - | - | OK (non touche) |
| v1.0.52 deployee | non | - | - | OK (attendu) |

backend HEAD = origin/main = 8f7122b : OK pour build.

## 4. Tag collision

| Tag | Local | GHCR | Verdict |
|---|---|---|---|
| v1.0.52-amazon-validation-pipeline-dev | ABSENT | ABSENT | OK (aucune collision) |

## 5. Worktree

| Worktree | HEAD | Dirty | Verdict |
|---|---|---|---|
| /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.14P-.../keybuzz-backend | 8f7122b | 0 | OK |

git worktree add --detach @ 8f7122b ; porcelain=0.

## 6. Source audit (worktree, read-only)

| Marker | Count/Result | Verdict |
|---|---|---|
| decideValidationAddress | 4 (src) | OK |
| processValidationEmail | 25 (src) | OK |
| emailAddress equals + mode insensitive | inbound.service.ts:253 | OK |
| isValidationEmail(subject) guard | inbound.service.ts:158 | OK |
| updateMarketplaceStatusIfAmazon | 3 (src) | OK |
| subject passe au webhook | inboundEmailWebhook.routes.ts:76 | OK |
| toAddress String @map("to") | schema.prisma:538 | OK |
| sendOutboundEmailById | 6 (src) | OK |
| OUTBOUND_EMAIL_SEND | 14 (src) | OK |
| JOB_TYPES | 9 (src) | OK |
| ancien pre-filtre marketplace.toUpperCase() as any dans .ts compile | 0 (present seulement dans .bak non compile) | OK |
| prisma migrate / db push dans src | 0 | OK |
| not implemented OUTBOUND_EMAIL_SEND | 0 (seul INBOUND_EMAIL_PROCESS logge not implemented) | OK |

Note : fichiers *.bak / *.backup / *.pre_auth sont du cruft tracke pre-existant (deja dans v1.0.50/51) ; tsconfig include = src/**/*.ts ne matche pas ces extensions, donc jamais compiles. Aucune migration SQL, aucun hardcode tenant/email, aucun secret ajoute.

## 7. Tests pre-build

| Test | Commande | Resultat | Verdict |
|---|---|---|---|
| prisma generate | npx prisma generate | EXIT 0 | OK |
| DMMF mapping | OutboundEmail.toAddress.dbName | "to" -> MAP_OK=true | OK |
| Typecheck | npx tsc --noEmit -p tsconfig.json | TSC_OK | OK |
| PH-20.14O (multi-casse) | tests/ph2014o-validation-address-casing.test.ts | 9 passed, 0 failed | OK |
| PH-20.14I (resolution) | tests/ph2014i-validation-address.test.ts | 11 passed, 0 failed | OK |
| PH-20.14C-BIS (jobscope) | tests/ph2014cbis-jobscope.test.ts | 16 passed, 0 failed | OK |
| PH-20.14C (outboundEmail) | tests/ph2014c-outboundEmail.test.ts | 15 passed, 0 failed | OK |

Tests executes dans le repo principal au commit identique 8f7122b (worktree sans node_modules ; source equivalente bit-pour-bit, HEAD verifie = 8f7122b). Aucune mutation DB, aucun SMTP reel (tests mockes).

## 8. Build

| Item | Valeur | Verdict |
|---|---|---|
| Tag | ghcr.io/keybuzzio/keybuzz-backend:v1.0.52-amazon-validation-pipeline-dev | OK |
| Image ID | sha256:645f326612d8e5b33717c03a7e772044f1a4af7fb961ccc9b0c8f412c56f65ee | OK |
| Size | 613904720 octets (~586 MiB) | OK |
| OCI revision | 8f7122bfec4e2ade80b0b98c8a82d3b658f12efb | OK (== 8f7122b) |
| OCI version | v1.0.52-amazon-validation-pipeline-dev | OK |
| OCI created | 2026-05-26T05:30:52Z | OK |
| OCI source | https://github.com/keybuzzio/keybuzz-backend | OK |

docker build from worktree (context = source 8f7122b), build-args IMAGE_REVISION/VERSION/CREATED. Aucun push.

## 9. Image audit (dist extrait, read-only)

| Check image | Resultat | Verdict |
|---|---|---|
| decideValidationAddress dans dist | present (1 fichier) | OK |
| query emailAddress equals: to.trim() + mode insensitive | present (dist/modules/inbound/inbound.service.js) | OK |
| garde isValidationEmail(subject) | present | OK |
| updateMarketplaceStatusIfAmazon | present (2) | OK |
| ancien pre-filtre marketplace.toUpperCase() dans inbound.service.js | 0 | OK |
| sendOutboundEmailById | present (2) | OK |
| OUTBOUND_EMAIL_SEND | present (3) | OK |
| JOB_TYPES | present (2) | OK |
| dist/workers/jobsWorker.js | present | OK |
| scripts worker:jobs + worker:jobs:once (package.json) | present | OK |
| not implemented pour OUTBOUND | 0 | OK |
| @map("to") dans client Prisma genere (image) | schema.prisma:538 toAddress @map("to") | OK |

## 10. Side effects

| Side effect | Count/Preuve | Verdict |
|---|---|---|
| docker push | 0 (v1.0.52 GHCR ABSENT) | OK |
| kubectl mutation | 0 | OK |
| manifest modifie | 0 (infra git clean) | OK |
| pod restart | 0 (runtime DEV v1.0.51 inchange) | OK |
| DB mutation | 0 | OK |
| email envoye | 0 | OK |
| trigger validation | 0 | OK |
| v1.0.52 deployee | non | OK |

## 11. AI feature parity / anti-regression

| Feature | Contrat | Impact build | Verdict |
|---|---|---|---|
| Amazon outbound From | = adresse inbound tenant | aucun (non touche) | OK |
| Guard validationStatus=VALIDATED | non bypasse | preserve | OK |
| Inbound webhook resolution exacte | par emailAddress (case-insensitive) | renforce (casse marketplace) | OK |
| PH-20.11C guardrails | non touches | preserve | OK |
| PH-20.12B no-reply KBActions | non touche | preserve | OK |
| PH-20.13B Client | suspendu | non repris | OK |
| outbound deliveries marketplace | pas de retry | aucun | OK |
| jobsWorker JOB_TYPES=OUTBOUND_EMAIL_SEND | protege AMAZON_POLL | present dans image | OK |

## 12. No fake metrics / no fake events

| Object | Build/test allowed | Runtime forbidden | Verdict |
|---|---|---|---|
| validation / webhook / OutboundEmail / delivery / KBActions / dashboard | tests mockes uniquement | aucune ecriture runtime | OK |

Build/tests sur mocks. Aucune ecriture DB, aucun fake validation/webhook/OutboundEmail/delivery/KBActions/metrique.

## 13. Cleanup

| Cleanup | Resultat | Verdict |
|---|---|---|
| Container audit (docker create) | supprime (0 restant) | OK |
| /tmp/v152dist | supprime | OK |
| Worktree | git worktree remove (sans --force) OK + prune | OK |
| Image locale v1.0.52 | conservee (645f326612d8) | OK |

## 14. Rollback

| Element | Rollback | Runtime impact |
|---|---|---|
| Runtime | N/A (aucune image deployee) | aucun |
| Image locale | docker rmi v1.0.52-amazon-validation-pipeline-dev | aucun |
| Source | revert 8f7122b seulement si demande separee | aucun |
| Docs | revert commit rapport infra si erreur doc | aucun |

## 15. Prochaine phrase GO

GO PUSH IMAGE BACKEND AMAZON VALIDATION PIPELINE DEV PH-SAAS-T8.12AS.20.14Q (docker push v1.0.52 + pull-back digest match), puis GO APPLY BACKEND AND JOBSWORKER DEV GITOPS PH-SAAS-T8.12AS.20.14R. Ne pas re-trigger la validation tant que API DEV ET jobs-worker DEV ne tournent pas tous les deux sur v1.0.52. Ne pas deployer v1.0.48/49/50/51.

Phrase cible : GO BUILD BACKEND AMAZON VALIDATION PIPELINE DEV READY PH-SAAS-T8.12AS.20.14P

STOP.
