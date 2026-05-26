# PH-SAAS-T8.12AS.20.14U-SOURCE-PATCH-AMAZON-OUTBOUND-JOB-OBSERVABILITY-DEV-01

> Date : 2026-05-26
> Linear : KEY-323 primary ; KEY-337 parent PH-20 ; references PH-20.14S-RCA / PH-20.14S / PH-20.14C-BIS
> Phase : PH-SAAS-T8.12AS.20.14U (SOURCE PATCH ONLY : observabilite worker + durcissement JOB_TYPES)
> Environnement : DEV (source patch ; aucun build, aucun deploy, aucune mutation DB, aucun trigger)

## 1. Verdict

GO SOURCE PATCH AMAZON OUTBOUND JOB OBSERVABILITY DEV READY PH-SAAS-T8.12AS.20.14U

Patch source minimal applique en reponse a PH-20.14S-RCA (gap d observabilite + hazard JOB_TYPES vide). Deux axes : (1) instrumentation du jobsWorker (startup enrichi, heartbeat de poll, logs structures claim/done/fail + OUTBOUND_EMAIL_SEND start/result) pour qu un job ne puisse plus passer DONE sans trace exploitable ; (2) durcissement de parseJobTypesEnv pour que JOB_TYPES present-mais-vide ("" / whitespace / virgules / unknown-only) signifie claim NOTHING (fail-safe), et non plus claim-all. Comportement par defaut preserve : JOB_TYPES absent (undefined) => aucune restriction (claim all). tsc OK. Tests : ph2014u 17/17 (nouveau), ph2014cbis 16/16 (2 assertions mises a jour au nouveau contrat), ph2014c 15/15, ph2014i 11/11, ph2014o 9/9. Commit backend LOCAL 1179c15, NON pousse (STOP au gate push). Aucun build, aucun deploy, aucun trigger, aucune mutation DB. jobs-worker / API DEV inchanges (v1.0.52).

Prochaine phrase GO : GO PUSH SOURCE PATCH AMAZON OUTBOUND JOB OBSERVABILITY DEV PH-SAAS-T8.12AS.20.14U (push backend 1179c15 + rapport infra + Linear), puis build v1.0.53 -> push -> apply API+jobs-worker DEV -> re-trigger PH-20.14S-bis SOUS observabilite.

## 2. Sources relues

PH-20.14S-RCA (gap observabilite + hazard config), PH-20.14S (retrigger PARTIAL), PH-20.14C-BIS (scope JOB_TYPES origine). Source backend 8f7122b : jobsWorker.ts, jobs.service.ts (parseJobTypesEnv, buildClaimJobQuery, claimNextJob, markJobDone/Failed, enqueueJob), outboundEmail.service.ts (sendOutboundEmailById). AI_MEMORY : CURRENT_STATE, RULES_AND_RISKS. Memoire agent : project_amazon_validation_pipeline_gap.

## 3. Preflight (repos)

| Repo | branche | HEAD local | origin/main | dirty | verdict |
|---|---|---|---|---|---|
| keybuzz-backend | main | 1179c15 (apres commit) | 8f7122b | non (hors amazon.routes.ts.bak) | OK |
| keybuzz-infra | main | eac518c -> +rapport (local) | eac518c | non | OK |
| Bastion install-v3 / 46.62.171.61 | - | - | - | - | OK |
| Runtime DEV API + jobs-worker | v1.0.52 | - | - | - | OK (non touche) |
| PROD backend | v1.0.47-cross-env-guard-fix-prod | - | - | - | INTACT |

## 4. RCA resume (PH-20.14S-RCA)

Job OUTBOUND_EMAIL_SEND cmpma3o1x DONE en 320ms sans envoi (OutboundEmail PENDING, provider null, 0 SMTP), jobs-worker v1.0.52 sans log de claim/done. Etat DB incompatible avec les chemins du code deploye ; consommateur non tracable. Classification : gap d observabilite dominant + hazard config (parseJobTypesEnv("") => claim-all ; amazon workers stale v1.0.40). Ce patch traite l observabilite + le durcissement parsing (le volet config amazon workers est hors scope, phase separee).

## 5. Fichiers modifies

| Fichier | changement | risque | verdict |
|---|---|---|---|
| src/modules/jobs/jobs.service.ts | parseJobTypesEnv : garde `if (!raw || raw.trim().length===0) return undefined` -> `if (raw == null) return undefined`. Env present-mais-vide tombe desormais dans le parse normal -> accepted=[] -> claim nothing. | Faible ; durcissement voulu. Defaut (undefined) inchange. | OK |
| src/workers/jobsWorker.ts | +IMAGE_VERSION (env best-effort) +HEARTBEAT_EVERY_POLLS=30 ; startup log enrichi (image, scope, jobTypesRaw, pollMs) ; warning explicite si JOB_TYPES present-mais-vide (claim disabled) ; logs structures claim/done(durationMs)/fail ; OUTBOUND_EMAIL_SEND start + result(SENT/SKIPPED). Aucune logique d envoi/claim changee. | Faible (logs + compteurs locaux). | OK |
| tests/ph2014cbis-jobscope.test.ts | 2 assertions mises a jour : ""/"   " attendaient undefined -> attendent maintenant [] (nouveau contrat). | N/A (test) | OK |
| tests/ph2014u-jobtypes-hardening.test.ts | nouveau test DB-free (17 assertions) parseJobTypesEnv + buildClaimJobQuery + end-to-end empty-env => AND false. | N/A (test) | OK |

git diff : 4 fichiers, +110/-9. Aucun changement schema DB, SMTP, route API, manifest, package-lock.

## 6. Comportement JOB_TYPES avant / apres

| Entree JOB_TYPES | parseJobTypesEnv avant | parseJobTypesEnv apres | buildClaimJobQuery apres | claim |
|---|---|---|---|---|
| absent (undefined) | undefined | undefined | pas de filtre | TOUS (defaut preserve) |
| "" (vide) | undefined (=> claim all, HAZARD) | [] | AND false | RIEN (fail-safe) |
| "   " whitespace | undefined (HAZARD) | [] | AND false | RIEN |
| "," / " , " | undefined (HAZARD) | [] | AND false | RIEN |
| "BOGUS" unknown-only | [] | [] | AND false | RIEN |
| "OUTBOUND_EMAIL_SEND" | ["OUTBOUND_EMAIL_SEND"] | ["OUTBOUND_EMAIL_SEND"] | type::text IN | OUTBOUND_EMAIL_SEND seul |
| "OUTBOUND_EMAIL_SEND,BOGUS" | ["OUTBOUND_EMAIL_SEND"] + warn | idem + warn | type::text IN | OUTBOUND_EMAIL_SEND seul |

Le jobs-worker validation (JOB_TYPES=OUTBOUND_EMAIL_SEND) reste scope : il ne peut jamais claimer AMAZON_POLL.

## 7. Logs ajoutes (jobsWorker)

| Evenement | log (sans PII brute) |
|---|---|
| startup | worker, image, scope, jobTypesRaw (la valeur d env, non-secret), pollMs |
| JOB_TYPES vide | warning explicite "claim DISABLED ... claiming NOTHING" |
| heartbeat | every 30 polls : worker, polls, claimed, scope, "no job this poll" |
| claim | jobId, type, tenant, worker |
| OUTBOUND start | jobId, outboundEmailId, worker |
| OUTBOUND result | jobId, outboundEmailId, outcome SENT/SKIPPED, status |
| done | jobId, type, outcome=DONE, durationMs |
| fail | jobId, type, durationMs, error message (redige) |

Aucun email complet, aucun token mailbox, aucun secret. jobId/workerId/type/outboundEmailId/outcome uniquement.

## 8. Tests

| Test | commande | resultat | verdict |
|---|---|---|---|
| prisma generate | npx prisma generate | OK | OK |
| typecheck | npx tsc --noEmit -p tsconfig.json | TSC_OK | OK |
| PH-20.14U (nouveau) | tests/ph2014u-jobtypes-hardening.test.ts | 17 passed, 0 failed | OK |
| PH-20.14C-BIS (maj) | tests/ph2014cbis-jobscope.test.ts | 16 passed, 0 failed | OK |
| PH-20.14C | tests/ph2014c-outboundEmail.test.ts | 15 passed, 0 failed | OK |
| PH-20.14I | tests/ph2014i-validation-address.test.ts | 11 passed, 0 failed | OK |
| PH-20.14O | tests/ph2014o-validation-address-casing.test.ts | 9 passed, 0 failed | OK |

## 9. No side-effect

| Check | etat | verdict |
|---|---|---|
| build / docker push / deploy / kubectl apply / restart | 0 | OK |
| manifest GitOps modifie | 0 | OK |
| mutation DB / migration | 0 (prisma generate ecrit node_modules, non versionne) | OK |
| trigger send-validation / email | 0 | OK |
| runtime DEV (API + jobs-worker) | v1.0.52 inchange | OK |
| PROD | non touche | OK |

## 10. AI feature parity / anti-regression (E8)

| Feature | Etat | Verdict |
|---|---|---|
| Guard outbound validationStatus=VALIDATED | non touche | OK |
| From Amazon amazon.<tenant>.<country>.<token>@inbound.keybuzz.io | non touche | OK |
| jobs-worker scope OUTBOUND_EMAIL_SEND | renforce (claim-nothing si JOB_TYPES vide ; AMAZON_POLL jamais claimable sous ce scope) | OK |
| logique d envoi sendOutboundEmailById | inchangee (logs seulement) | OK |
| decideValidationAddress / resolution casse (14O/14I) | non touche | OK |
| PH-20.11C / PH-20.12B / PH-20.13B | preserve / suspendu | OK |

## 11. No fake metrics / no fake events (E9)

| Objet | Etat | Verdict |
|---|---|---|
| fake metric / event / webhook / OutboundEmail / Job | 0 | OK |
| DB mutation / validationStatus flip manuel | 0 | OK |

Patch source + tests mockes/DB-free uniquement. Aucune ecriture runtime.

## 12. Rollback

Commit 1179c15 touche 2 fichiers source (parseJobTypesEnv garde + logs worker) + 2 tests. Revert = reset local HEAD a 8f7122b avant push (non pousse). Aucun effet DB/runtime (rien deploye). Le durcissement parseJobTypesEnv est retro-compatible pour le defaut (undefined) et pour un scope explicite valide ; seul le cas present-mais-vide change (par design).

## 13. Prochaine phase

GO PUSH SOURCE PATCH AMAZON OUTBOUND JOB OBSERVABILITY DEV PH-SAAS-T8.12AS.20.14U (push backend 1179c15 + rapport infra + Linear KEY-323/337). Puis : GO BUILD ... PH-20.14V (tag v1.0.53-amazon-validation-pipeline-dev from 1179c15) -> push image -> apply API + jobs-worker DEV -> re-trigger PH-20.14S-bis SOUS observabilite (les nouveaux logs claim/done/heartbeat permettront d identifier le consommateur reel et la decision d envoi). En phase config separee : upgrader amazon-orders/items-worker hors v1.0.40 + fixer leur JOB_TYPES. Ne pas promouvoir PROD, ne pas retry outbound, ne pas flip DB.

Phrase cible : GO SOURCE PATCH AMAZON OUTBOUND JOB OBSERVABILITY DEV READY PH-SAAS-T8.12AS.20.14U

STOP.
