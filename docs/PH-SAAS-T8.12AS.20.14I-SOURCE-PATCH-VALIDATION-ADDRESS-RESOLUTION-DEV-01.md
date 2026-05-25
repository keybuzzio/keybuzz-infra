# PH-SAAS-T8.12AS.20.14I-SOURCE-PATCH-VALIDATION-ADDRESS-RESOLUTION-DEV-01

> Date : 2026-05-25
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14G-TER / C-TER / F-TER
> Phase : PH-SAAS-T8.12AS.20.14I (SOURCE PATCH ONLY)
> Environnement : DEV source patch ; aucun build, aucun deploy, aucune mutation DB

## 1. Verdict

GO SOURCE PATCH VALIDATION ADDRESS RESOLUTION DEV READY PH-SAAS-T8.12AS.20.14I

processValidationEmail resout desormais l adresse inbound EXACTE par emailAddress du destinataire (via la fonction pure decideValidationAddress), au lieu de findUnique({ tenantId_marketplace_country }) qui etait ambigu en multi-connection. Si plusieurs candidates partagent le meme emailAddress : aucune validation (pas de fallback arbitraire). tsc OK, tests 11/11 (nouveau) + 16/16 + 15/15. Commit backend LOCAL cbbc99e (NON pousse). Aucun build, aucun deploy, aucune mutation DB, aucun email, aucun trigger. API/jobs-worker DEV inchanges (v1.0.50).

Prochaine phrase GO : GO PUSH SOURCE PATCH VALIDATION ADDRESS RESOLUTION DEV PH-SAAS-T8.12AS.20.14I (push backend cbbc99e + rapport infra + Linear), puis GO BUILD BACKEND ... PH-20.14J (tag v1.0.51).

## 2. Sources relues

PH-20.14G-TER (root cause), PH-20.14C-TER (schema map), PH-20.14F-TER (deploy v1.0.50). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS, OPERATIONAL_SOURCE_OF_TRUTH.

## 3. Preflight

| Repo/Service | Branche/Image | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-backend | main | 2a14258 = origin (avant commit) | non (sauf amazon.routes.ts.bak untracked historique) | OK |
| keybuzz-infra | main | 6111f62 | non | OK |
| API DEV | v1.0.50-amazon-validation-pipeline-dev | n/a | inchange | OK |
| jobs-worker DEV | v1.0.50-amazon-validation-pipeline-dev | n/a | inchange | OK |

## 4. Root cause PH-20.14G-TER

Trigger DEV reel : pipeline mecanique OK de bout en bout, mais l adresse PENDING ciblee (cmk5caxx7, token 812g37) n est pas passee VALIDATED. processValidationEmail (inbound.service.ts) resolvait l adresse via findUnique({ tenantId_marketplace_country }). tenant_test_dev ayant 2 adresses FR amazon (2 connections ; @@unique([tenantId,marketplace,country]) non applique en DB = drift), le findUnique a retourne l autre adresse (deja VALIDATED) et l a re-validee. validationStatus global inchange.

## 5. Code audit

| Fonction | Fichier | Critere actuel | Donnees disponibles | Risque |
|---|---|---|---|---|
| processValidationEmail | src/modules/inbound/inbound.service.ts | findUnique(tenantId_marketplace_country) | to (emailAddress exact), parsed.token, candidates par tenant/mk/country | valide la mauvaise adresse en multi-connection |
| parseInboundAddress | meme fichier | regex canonical -> tenant/marketplace/country/token | token disponible | OK |
| sendValidationEmail | inboundEmailValidation.service.ts | filtre addresses par country sur la connection | emailAddress par adresse | OK (envoi cible la bonne adresse) |

emailAddress exact du destinataire est disponible dans le webhook (params.to) -> resolution exacte possible.

## 6. Design patch

| Decision | Choix | Justification | Risque |
|---|---|---|---|
| Resolution | match emailAddress exact (insensitive) parmi candidates (tenant,mk,country) | l email recu identifie l adresse unique | nul |
| Multi-candidates exact | si >1 meme emailAddress : aucune validation, log error | pas de fallback arbitraire | nul |
| Token | defense : address.token doit == parsed.token sinon refus | coherence | nul |
| Fonction pure | decideValidationAddress(to, parsedToken, candidates) | testable sans DB (pattern PH-20.14C) | nul |
| Idempotent | si deja VALIDATED exact match : revalide (no-op effectif) + flag alreadyValidated | non destructif | nul |

## 7. Patch

| Fichier | Changement | Risque | Test |
|---|---|---|---|
| src/modules/inbound/inbound.service.ts | + decideValidationAddress (pure) ; processValidationEmail : findUnique -> findMany(tenant,mk,country) + decideValidationAddress(emailAddress exact) + update by id ; log redacted | faible | ph2014i |
| tests/ph2014i-validation-address.test.ts | nouveau test multi-adresses meme tenant/country | n/a | 11/11 |

git diff : 2 files changed, +132 / -14. Aucun changement schema, aucune migration.

## 8. Tests / typecheck

| Test | Commande | Resultat | Verdict |
|---|---|---|---|
| typecheck | npx tsc --noEmit -p tsconfig.json | TSC_OK | OK |
| PH-20.14I (nouveau) | tests/ph2014i-validation-address.test.ts | 11 passed, 0 failed | OK |
| PH-20.14C-BIS | tests/ph2014cbis-jobscope.test.ts | 16 passed, 0 failed | OK |
| PH-20.14C | tests/ph2014c-outboundEmail.test.ts | 15 passed, 0 failed | OK |

Cas couverts : exact PENDING valide ; autre adresse VALIDATED non touchee ; case-insensitive ; recipient inconnu -> not found ; doublon emailAddress -> ambiguous (pas de validation) ; token mismatch -> refus ; destinataire vide -> guard.

## 9. Side effects

| Side effect | Count/Preuve | Verdict |
|---|---|---|
| build / docker push | 0 | OK |
| deploy / kubectl | 0 | OK |
| DB mutation runtime | 0 | OK |
| email reel / trigger | 0 | OK |
| jobs-worker / API DEV | inchanges v1.0.50 | OK |
| git push | 0 (origin/main = 2a14258) | OK |

## 10. Anti-regression / AI feature parity

| Feature | Contrat | Impact patch | Verdict |
|---|---|---|---|
| Amazon outbound From | tenant inbound address | inchange | OK |
| Guard validationStatus=VALIDATED | non bypasse, renforce (adresse exacte) | ameliore | OK |
| Inbound webhook | resolution exacte par emailAddress | corrige | OK |
| PH-20.11C / PH-20.12B / PH-20.13B | preserve / suspendu | non touche | OK |
| jobsWorker JOB_TYPES / AMAZON_POLL | non regresse | non touche | OK |

## 11. No fake metrics / events

| Objet | Change | Verdict |
|---|---|---|
| validation / webhook / OutboundEmail / KBActions | aucun fake, aucun flip DB ; tests mocks uniquement | OK |

## 12. Commits

| Repo | Commit | Files | Push | Verdict |
|---|---|---|---|---|
| keybuzz-backend | cbbc99e fix(amazon): validate exact inbound address | inbound.service.ts + ph2014i test | LOCAL (en attente GO) | OK |
| keybuzz-infra | (rapport, commit local) | ce fichier | LOCAL (en attente GO) | OK |

## 13. Rollback

| Element | Rollback | Runtime impact |
|---|---|---|
| Backend | git revert cbbc99e (non pousse : reset local a 2a14258) | aucun (non deploye) |
| Docs infra | git revert commit rapport | aucun |
| DB | N/A (aucune mutation) | aucun |

## 14. Prochaine phrase GO

GO PUSH SOURCE PATCH VALIDATION ADDRESS RESOLUTION DEV PH-SAAS-T8.12AS.20.14I (push backend cbbc99e + rapport infra + Linear KEY-323/KEY-337).

Puis GO BUILD BACKEND AMAZON VALIDATION PIPELINE DEV PH-SAAS-T8.12AS.20.14J (tag v1.0.51-amazon-validation-pipeline-dev) -> push -> redeploy API + jobs-worker DEV -> re-trigger sur l adresse PENDING. Ne pas re-trigger avant rebuild+push+redeploy.

STOP.
