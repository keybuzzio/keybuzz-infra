# PH-SAAS-T8.12AS.20.12B-HARDEN-AI-MEMORY-PH147-SOURCE-OF-TRUTH-BUILD-GUARDRAIL-01

> Date : 2026-05-24
> Linear : KEY-337 parent PH-20 ; KEY-231 KBActions trial value/anxiety ; KEY-348 observation differee PH-20.12C ; KEY-349 rotation PGPASSWORD DEV ; references KEY-263 / KEY-302 / KEY-308 / KEY-309 / KEY-312
> Phase : PH-SAAS-T8.12AS.20.12B-HARDEN-AI-MEMORY-PH147-SOURCE-OF-TRUTH-BUILD-GUARDRAIL
> Environnement : DOCS ONLY (no runtime change, no source change, no rollback, no cleanup repo API)

## VERDICT

GO HARDEN AI_MEMORY PH147 SOURCE OF TRUTH BUILD GUARDRAIL READY PH-SAAS-T8.12AS.20.12B

## Resume executif

KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md durci pour empecher tout build futur depuis un worktree canonical dirty. Le reviewer Codex a detecte que `/opt/keybuzz/keybuzz-api` montre 223 `D dist/*.js` dirty artifacts alors que les sources applicatives sont CLEAN au commit `38c048c0` sur branche `ph147.4/source-of-truth`. La formulation precedente du doc tolerait cette dette comme acceptable pour build : c etait permissif et dangereux pendant la phase PMF + campagnes Ads actives.

Patch docs-only : 47 lignes touchees (+45 / -2) sur operational source of truth. 0 non-ASCII. Sections 6 (rule 4 porcelain) et 8 (working tree clean) durcies. Nouvelle section 8b ajoutee : "PH147 API source-of-truth hard guardrail (2026-05-24)".

Aucun runtime change, aucun cleanup repo API, aucun build/push/deploy, aucun manifest k8s touche, aucun secret affiche.

## Raison du hardening

Le reviewer Codex a detecte apres la phase precedente (PH-20.12B-AI-MEMORY-OPERATIONAL-SOURCE-OF-TRUTH-UPDATE-01 commit f2cda5f) que la canonical repo `/opt/keybuzz/keybuzz-api` est dans un etat :
- branche : ph147.4/source-of-truth (OK)
- HEAD : 38c048c07fb98543437228657564ef4de388bdfb (OK MATCH origin)
- origin HEAD : 38c048c07fb98543437228657564ef4de388bdfb (OK)
- dirty source applicative : 0 (src/, package.json, package-lock.json, tsconfig.json, Dockerfile tous clean)
- dirty total : 223 (uniquement `D dist/*.js` artefacts de build supprimes du tracking)

Cette dette est observable depuis plusieurs phases PH-20.12B (build DEV, push DEV, apply DEV, build PROD, push PROD, apply PROD, QA DEV, QA PROD, close, update AI_MEMORY) - elle a ete contournee a chaque fois en creant un `git worktree add --detach` propre pour le build, MAIS le doc operational ne l interdisait pas explicitement.

Risque concret pendant phase PMF / campagnes Ads :
1. Un agent futur (CE / Codex) lit le doc operational et voit "must be clean OR only contain documented artifact dirty (e.g. keybuzz-api D dist/*.js)" - interpretation : OK de builder depuis ce repo dirty.
2. L agent declenche `docker build` depuis `/opt/keybuzz/keybuzz-api` directement.
3. Le build inclurait l etat dirty (potentiellement node_modules stale, des cleanup partiels, ou pire un fichier source accidentellement modifie qui passe pour artefact).
4. Image construite avec etat inconnu deployee en PROD pendant phase critique acquisition payante.

Le guardrail force l alternative safe deja utilisee implicitement pendant toute la sequence PH-20.12B : creer un fresh `git worktree add --detach` depuis `origin/ph147.4/source-of-truth` ou le commit cible explicite, verifier `git status --porcelain` = 0, builder depuis ce worktree propre uniquement.

## Sources lues

1. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md
2. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md (avant patch)
3. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md
4. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md
5. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md
6. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AI-MEMORY-OPERATIONAL-SOURCE-OF-TRUTH-UPDATE-01.md (commit f2cda5f)
7. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-CLOSE-01.md (commit 525b6cb)

## E0 - Preflight

| Item | Attendu | Constate | Verdict |
|---|---|---|---|
| Bastion hostname | install-v3 | install-v3 | OK |
| Bastion IP externe | 46.62.171.61 | 46.62.171.61 | OK |
| Date UTC | 2026-05-24 | 2026-05-24 18:27 UTC | OK |
| keybuzz-infra branche | main | main | OK |
| keybuzz-infra HEAD initial | f2cda5f (PH-20.12B AI_MEMORY update) | f2cda5f43eda0739dfbef2455bb52b4925228522 | OK |
| keybuzz-infra dirty | clean | clean | OK |

## E1 - Audit API PH147 (read-only, NO cleanup)

| Element | Attendu | Constate | Verdict |
|---|---|---|---|
| Repo path | /opt/keybuzz/keybuzz-api | OK | OK |
| Branche | ph147.4/source-of-truth | ph147.4/source-of-truth | OK |
| HEAD | 38c048c07fb98543437228657564ef4de388bdfb | 38c048c07fb98543437228657564ef4de388bdfb | OK MATCH |
| origin/ph147.4/source-of-truth | 38c048c07fb98543437228657564ef4de388bdfb | 38c048c07fb98543437228657564ef4de388bdfb | OK MATCH |
| HEAD == origin (no drift) | OUI | OUI | OK |
| Dirty total | peut etre non-zero (D dist/*.js) | 223 | DETTE DOCUMENTEE |
| Dirty source applicative (src/ package.json package-lock.json tsconfig.json Dockerfile) | 0 | 0 | CLEAN |
| Dirty dist/ | <= 223 | 223 | DETTE DOCUMENTEE |
| Sample dirty | `D dist/app.js`, `D dist/config/*.js` | OUI (10 premiers : app.js, ai-budgets.js, database.js, db-conventions.js, env.js, historical-anti-patterns.js, kbactions.js, redis.js, sav-decision-tree.js, sav-policy.js) | DETTE DOCUMENTEE |

**Conclusion reviewer** : source applicative impeccable. La dette est exclusivement sur des artefacts de build (`dist/*.js`) supprimes du tracking Git - resultat normal d un `tsc` qui produit des `.js` non versionnees. Cette dette ne corrompt PAS le code source. Mais elle ne doit pas servir de base de build, parce qu un agent futur ne peut pas determiner trivialement si "tout ce qui est dirty est uniquement dist/*.js" sans audit explicit.

Aucun nettoyage effectue. Aucun `git reset --hard`. Aucun `git clean`. Aucun `git checkout -- dist`. La dette reste en place comme observation read-only.

## E2 - Audit doc avant patch

Phrases permissives identifiees dans KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md :

| Ligne | Phrase actuelle | Risque |
|---|---|---|
| 89 (section 6 rule 4) | `git status --porcelain : must be clean OR only contain documented artifact dirty (e.g. keybuzz-client tsconfig.tsbuildinfo, keybuzz-api D dist/*.js). If anything else is dirty : STOP and investigate.` | Permet implicite de builder depuis canonical repo dirty |
| 112 (section 8 build rules) | `Working tree clean (or only documented artifact dirty).` | Idem, plus directement applique au contexte build |

## E3 - Patch applique

| Fichier | Modification | Lignes |
|---|---|---|
| docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md | Section 6 rule 4 (porcelain split audit vs build) + section 8 "working tree" (worktree clean obligatoire) + NEW section 8b PH147 hard guardrail | 47 lignes touchees (+45 / -2) |

### Section 6 rule 4 - ancien -> nouveau

**Ancien** :
> 4. `git status --porcelain` : must be clean OR only contain documented artifact dirty (e.g. keybuzz-client `tsconfig.tsbuildinfo`, keybuzz-api `D dist/*.js`). If anything else is dirty : STOP and investigate.

**Nouveau** (3 sous-bullets) :
> 4. `git status --porcelain` :
>    - For audit / read-only phases : canonical repo may show documented artifact dirty (e.g. keybuzz-client `tsconfig.tsbuildinfo`, keybuzz-api `D dist/*.js`). Document it, do not clean.
>    - For ANY build phase (docker build, npm build, source patch + commit) : the build worktree must be FULLY clean (`git status --porcelain` returns 0 lines). Documented artifact dirty is NEVER acceptable as a build base. Build from a fresh `git worktree add --detach` checked out from `origin/<branch>` or from the explicit target commit, NOT from the canonical repo if it shows any dirty file. See section 8b for the PH147 hard guardrail.
>    - If anything else is dirty : STOP and investigate.

### Section 8 build rules - ancien -> nouveau

**Ancien** :
> - Working tree clean (or only documented artifact dirty).

**Nouveau** :
> - Build worktree FULLY clean (`git status --porcelain` empty). Documented artifact dirty in the canonical repo is NOT acceptable for build : create a fresh `git worktree add --detach` from `origin/<branch>` or from the target commit. See section 8b for PH147 specifics.

### Section 8b NEW - PH147 API source-of-truth hard guardrail (2026-05-24)

Section entiere ajoutee entre section 8 (Build rules) et section 9 (Smoke harness rules), structuree :
1. Contexte : detection reviewer post-PH-20.12B closeout (223 D dist/*.js)
2. Canonical repo dirty observation (read-only debt) : 4 sous-points (debt observable, read-only only, NE PAS nettoyer implicitement, removal requires dedicated GO Ludovic)
3. Build rule (HARD) : 4 sous-points (no build from dirty, fresh worktree obligatoire avec commande explicit `git worktree add --detach`, verifications pre-build, verifications post-build OCI labels)
4. STOP conditions : 5 cas explicites
5. Cleanup post-build : 2 sous-points (worktree remove + ne pas laisser stale)

### Pourquoi c est plus strict

| Aspect | Avant | Apres |
|---|---|---|
| Build depuis canonical repo dirty | Tolere si "documented artifact dirty" | INTERDIT - STOP obligatoire |
| Fresh worktree | Optionnel/implicite | OBLIGATOIRE - commande explicit |
| Pre-build verification | `git status` mention generic | Verification 3 points (HEAD match, porcelain 0, commit pushed origin) |
| Post-build verification | KEY-308 OCI labels generic | OCI revision label = source commit SHA obligatoire |
| STOP conditions | 1 ligne generic "STOP if dirty" | 5 conditions explicites listees |
| Audit vs build | Confondus | Distincts : audit accepte dirty, build refuse dirty |
| Implicit cleanup | Pas mentionne | INTERDIT (no `git reset`, no `git clean`, no `git checkout --`) sauf GO Ludovic dedie |

## E4 - Verification doc

| Check | Resultat | Verdict |
|---|---|---|
| ASCII strict | 0 non-ASCII (verifie via `grep -cP "[\x80-\xFF]"`) | OK |
| Diff scope | uniquement docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md modifie | OK |
| Diff stat | +45 / -2 | OK |
| Aucun source applicatif modifie | OUI | PRESERVE |
| Aucun manifest k8s modifie | OUI | PRESERVE |
| Aucun secret affiche | OUI | OK |
| Markers presents dans doc | "PH147 API source-of-truth hard guardrail", "hard guardrail", "fresh detached", "build worktree must be FULLY clean", "D dist", "read-only debt", "STOP conditions" tous presents | OK |
| Sections preservees | 1, 2, 3, 5, 7, 9, 10, 11, 12, 13, 14, 15 INCHANGES (regles absolues + protocole + recent PH milestones + tickets) | PRESERVE |

## E5 - Build guardrail final

| Cas | Autorise | Action |
|---|---|---|
| Audit read-only sur canonical repo dirty | OUI | Documenter l etat dirty, ne pas nettoyer |
| Build depuis canonical repo `/opt/keybuzz/keybuzz-api` dirty (meme si dirty = D dist/*.js uniquement) | **NON** | **STOP**, creer fresh worktree |
| Build depuis fresh `git worktree add --detach <target-commit>` propre (porcelain=0) | OUI | Verifier HEAD match + commit pushed origin + OCI labels post-build |
| `git reset --hard` / `git clean` / `git checkout -- <file>` sur canonical repo comme side-effect d une phase build/deploy/patch | **NON** | **STOP**, requires dedicated GO Ludovic phase |
| Branch / HEAD / origin / requested commit mismatch dans build worktree | **NON** | **STOP** |
| OCI revision label = "unknown" au lieu du source commit SHA | **NON** | **STOP**, rebuild avec `--label org.opencontainers.image.revision=<commit>` |
| Stale build worktree non nettoye apres push+apply | NON recommande | `git worktree remove --force <path>` |

## AI feature parity / anti-regression

| Aspect | Resultat | Verdict |
|---|---|---|
| keybuzz-api/src/modules/autopilot/engine.ts | NON touche | PRESERVE PH-20.12B Step 6.5 |
| keybuzz-api/src/services/noReplyClassifier.ts | NON touche | PRESERVE PH-20.12B classifier |
| keybuzz-api/src/config/kbactions.ts | NON touche | PRESERVE PH-20.12B sentinel |
| keybuzz-api/src/services/autopilotGuardrails.ts | NON touche | PRESERVE seller-first hash 3b85a276 |
| keybuzz-api/src/modules/ai/shared-ai-context.ts | NON touche | PRESERVE |
| keybuzz-api/src/tests/ph119-tests.ts | NON touche | PRESERVE |
| keybuzz-client source | NON touche | PRESERVE PH-20.11C |
| keybuzz-api runtime DEV (v3.5.256) | INCHANGE | PRESERVE |
| keybuzz-api runtime PROD (v3.5.257) | INCHANGE | PRESERVE |
| keybuzz-client runtime DEV (v3.5.214) | INCHANGE | PRESERVE |
| keybuzz-client runtime PROD (v3.5.215) | INCHANGE | PRESERVE |
| Manifests k8s | INCHANGE | PRESERVE |
| PH-20.11C blockedInfo path | PRESERVE | OK |
| PH-20.12B no-reply skip path | PRESERVE | OK |
| KBActions vrais drafts | PRESERVE | OK |
| KBActions skip no-reply = 0 | PRESERVE | OK |
| Doctrine seller-first / refundProtection | PRESERVE | OK |

## No fake metrics / no fake events / no fake KBActions

| Risque | Verification | Verdict |
|---|---|---|
| Backfill stats | aucun | OK |
| Fake ai_action_log entry | aucun | OK |
| Faux compteur KBActions | aucun | OK |
| Dashboard modifie | aucun | OK |
| Event marketing | aucun | OK |
| Event tracking | aucun | OK |
| Fake lead/register/checkout | aucun | OK |
| Mutation DB | 0 | OK |
| LLM call | 0 | OK |
| KBActions consommee | 0 | OK |
| Message marketplace | 0 | OK |

## Confirmations securite

| Interdit | Respecte | Preuve |
|---|---|---|
| docker build | OUI | 0 commande |
| docker push | OUI | 0 commande |
| kubectl apply / set image / set env / patch / edit / rollout restart | OUI | uniquement kubectl get pour preflight (pas execute, runtime status documente via etats connus) |
| deploy DEV/PROD | OUI | runtime preserve |
| modifier manifest k8s/ | OUI | aucun fichier k8s touche |
| modifier source applicative (api/client/backend/admin-v2/website) | OUI | aucun source touche |
| nettoyage repo API (git reset --hard / git clean / git checkout -- dist) | OUI | 0 commande destructive |
| mutation DB | OUI | 0 |
| LLM call | OUI | 0 |
| KBActions consommee | OUI | 0 |
| message marketplace | OUI | 0 |
| fake event/metric/conversation/KBActions | OUI | 0 |
| secret/token/PII brut | OUI | aucun |
| /opt/keybuzz/credentials ni /opt/keybuzz/secrets | OUI | non touche |
| dump env de pods | OUI | 0 |
| /ai/assist / /ai/execute / /autopilot/draft/consume | OUI | 0 appel |
| Bastion install-v3 (46.62.171.61) | OUI | hostname + IP verifies E0 |
| Creation ticket Linear | OUI | 0 |
| Changement statut Linear | OUI | 0 transition |
| Regles absolues operational doc sections 1-3, 5, 7, 9-15 | PRESERVES | sections non modifiees |

## Rollback

| Element | Plan | Verdict |
|---|---|---|
| Docs only | `git revert <commit>` sur main si erreur ; aucun runtime impact | OK plan simple |
| Runtime | N/A (aucun touche) | PRESERVE |
| Manifest | N/A (aucun touche) | PRESERVE |
| Source applicatif | N/A (aucun touche) | PRESERVE |
| Canonical repo API dirty state | N/A (dette preservee intentionnellement, ne pas nettoyer) | PRESERVE comme prevu |

## Linear

Commentaires postes (statuts INCHANGES 100%, 0 ticket cree) :
- KEY-337 (parent PH-20) : commentaire principal hardening AI_MEMORY PH147
- KEY-348 (observation differee PH-20.12C) : commentaire court car observation future heritera du guardrail
- KEY-349 (rotation PGPASSWORD DEV) : commentaire court pour signaler que cette dette security reste separee

KEY-231 NON commentee (cette phase est build guardrail, pas product/UX KBActions).
KEY-235 / KEY-263 / KEY-302 / KEY-305 / KEY-308 / KEY-309 / KEY-312 NON commentes (preserves).

## Prochaine action recommandee

Reprendre l angle UX :
**GO READONLY PRODUCT AUDIT KBACTIONS VALUE ANXIETY UX PH-SAAS-T8.12AS.20.13**

Ou observation differee :
**GO OBSERVE AUTOPILOT NO-REPLY KBACTIONS SAVINGS PROD PH-SAAS-T8.12AS.20.12C** (quand trafic reel client suffisant - KEY-348)

Ou cleanup dette dist/*.js (dedicated phase avec GO Ludovic) :
**GO CLEANUP API DIST DEBT PH147 SOURCE-OF-TRUTH** (read-only first to confirm safe, then `git checkout -- dist` ou re-build dist via tsc local, never as side effect)

STOP.
