# PH-SAAS-T8.12AS.20.12B-HARDEN-AI-MEMORY-BUILD-WORKTREE-CLEANUP-NO-FORCE-01

> Date : 2026-05-24
> Linear : KEY-337 parent PH-20 ; KEY-348 observation differee PH-20.12C ; references KEY-231 / KEY-349 / KEY-263 / KEY-302 / KEY-308 / KEY-309 / KEY-312
> Phase : PH-SAAS-T8.12AS.20.12B-HARDEN-AI-MEMORY-BUILD-WORKTREE-CLEANUP-NO-FORCE
> Environnement : DOCS ONLY (no runtime change, no cleanup effectif, no worktree mutation)

## VERDICT

GO HARDEN AI_MEMORY BUILD WORKTREE CLEANUP NO FORCE READY PH-SAAS-T8.12AS.20.12B

## Resume executif

KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md durci une fois de plus : la regle `git worktree remove --force <path>` qui apparaissait comme cleanup post-build par defaut dans la section 8b (introduite par le commit ca47eda PH147 hardening) est remplacee par une regle stricte sans force par defaut.

Le reviewer a detecte ce point residuel : `--force` comme commande de cleanup par defaut est dangereux pendant phase PMF + campagnes Ads, parce qu un agent futur pourrait l appliquer reflexivement sans verifier le chemin resolu, et potentiellement detruire un worktree contenant du travail non commit ou pire (via path mismatch).

Patch docs-only : 7 lignes touchees (+6 / -1) sur operational source of truth. 0 non-ASCII. Section 8b sous-section "Cleanup of the build worktree (post-build)" remplacee par 7 sous-bullets stricts.

Aucun runtime change, aucun cleanup effectif de worktree, aucun build/push/deploy, aucun manifest k8s touche, aucun secret affiche.

## Raison du hardening additionnel

Le commit ca47eda (PH147 source-of-truth hardening) a introduit la section 8b avec une sous-section "Cleanup of the build worktree (post-build)" contenant :
```
- `git worktree remove --force <path>` after successful push + apply.
- Never leave stale build worktrees that could be reused with a different HEAD.
```

Problemes detectes par reviewer :
1. `--force` est utilise comme valeur par defaut au lieu d etre une exception encadree.
2. Aucune verification de chemin obligatoire avant `--force`.
3. Aucune indication que `--force` necessite GO Ludovic explicite.
4. Pas de regle "si normal remove echoue, STOP and report" -> un agent forcerait reflexivement.
5. Risque concret pendant phase PMF / campagnes Ads :
   - Agent execute `git worktree remove --force /opt/keybuzz/build-worktrees/<phase>/keybuzz-api` sans verifier le path resolu.
   - Si le path est mal echappe ou mal construit (par exemple symlink ou path qui resolve ailleurs), `--force` ignore les protections de Git.
   - Travail non commit dans un autre worktree pourrait etre detruit.
   - Pire : si le chemin pointe accidentellement vers le canonical repo `/opt/keybuzz/keybuzz-api`, `--force` y forcerait la suppression.

La nouvelle regle force :
- Cleanup normal sans `--force`.
- Verification chemin sous `/opt/keybuzz/build-worktrees/<phase>/` AVANT cleanup.
- Si normal remove echoue : STOP + rapport.
- `--force` uniquement via phase dediee avec GO Ludovic.
- Jamais cleanup canonical repo en side-effect.

## Sources lues

1. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md
2. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md (avant patch ligne 182 contenait --force)
3. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md
4. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md
5. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md
6. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-HARDEN-AI-MEMORY-PH147-SOURCE-OF-TRUTH-BUILD-GUARDRAIL-01.md (commit ca47eda, premier hardening)
7. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AI-MEMORY-OPERATIONAL-SOURCE-OF-TRUTH-UPDATE-01.md (commit f2cda5f, update initial)

## E0 - Preflight

| Item | Attendu | Constate | Verdict |
|---|---|---|---|
| Bastion hostname | install-v3 | install-v3 | OK |
| Bastion IP externe | 46.62.171.61 | 46.62.171.61 | OK |
| Date UTC | 2026-05-24 | 2026-05-24 20:46 UTC | OK |
| keybuzz-infra branche | main | main | OK |
| keybuzz-infra HEAD initial | ca47eda (PH147 hardening) | ca47edabe28caab8434ada5858f40562c4c113c2 | OK |
| keybuzz-infra dirty | 0 | 0 | OK |

## E1 - Verification API PH147 (read-only)

| Element | Attendu | Constate | Verdict |
|---|---|---|---|
| Repo | /opt/keybuzz/keybuzz-api | OK | OK |
| Branche | ph147.4/source-of-truth | ph147.4/source-of-truth | OK |
| HEAD | 38c048c07fb98543437228657564ef4de388bdfb | 38c048c07fb98543437228657564ef4de388bdfb | OK |
| origin/ph147.4/source-of-truth | 38c048c07fb98543437228657564ef4de388bdfb | 38c048c07fb98543437228657564ef4de388bdfb | OK MATCH |
| Dirty total | <= 223 (D dist/*.js dette documentee) | 223 | DETTE DOCUMENTEE preserve |
| Dirty source applicative | 0 | 0 | CLEAN |
| Dirty dist | <= 223 | 223 | DETTE preserve |

Conclusion : etat API PH147 inchange depuis hardening precedent. NE PAS NETTOYER. Dette read-only documentee.

## E2 - Audit doc avant patch

Grep `--force` dans KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md (avant patch) :

| Ligne | Contenu |
|---|---|
| 182 | `- ` + backtick + `git worktree remove --force <path>` + backtick + ` after successful push + apply.` |

Une seule occurrence permissive identifiee, dans la sous-section "Cleanup of the build worktree (post-build)" de la section 8b introduite par le commit ca47eda.

## E3 - Patch applique

| Fichier | Modification | Lignes |
|---|---|---|
| docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md | Section 8b sous-section "Cleanup of the build worktree (post-build)" : remplace 2 bullets permissifs par 7 bullets stricts | +6 / -1 |

### Ancien bloc (avant patch)

```
Cleanup of the build worktree (post-build) :

- `git worktree remove --force <path>` after successful push + apply.
- Never leave stale build worktrees that could be reused with a different HEAD.
```

### Nouveau bloc (apres patch)

```
Cleanup of the build worktree (post-build) :

- Default cleanup command : `git worktree remove <path>` only.
- Before cleanup, verify the resolved absolute path is under `/opt/keybuzz/build-worktrees/<phase>/`.
- If `git worktree remove <path>` fails : STOP and report the reason.
- Do NOT use `git worktree remove --force` as a default build/deploy cleanup.
- `--force` is allowed only in a dedicated cleanup phase with explicit Ludovic GO, path verification, and a report explaining why normal removal failed.
- Never clean the canonical repo `/opt/keybuzz/keybuzz-api` as a side effect of a build/deploy/patch phase.
- Never leave stale build worktrees that could be reused with a different HEAD.
```

### Pourquoi c est plus strict

| Aspect | Avant (commit ca47eda) | Apres (cette phase) |
|---|---|---|
| Commande cleanup par defaut | `git worktree remove --force <path>` | `git worktree remove <path>` (no --force) |
| Verification chemin pre-cleanup | Aucune | Path absolu doit etre sous `/opt/keybuzz/build-worktrees/<phase>/` |
| Cas d echec cleanup normal | Aucun guidance (force automatique) | STOP + rapport |
| Usage `--force` | Default | INTERDIT par defaut |
| Exception `--force` autorisee | Implicite | EXPLICITE : phase dediee + GO Ludovic + path verification + rapport |
| Side-effect canonical repo | Reference dans STOP conditions section 8b | Repete explicitement dans cleanup rules |
| Stale worktree | Mentionne | Preserve (1 bullet) |

## E4 - Verification patch

| Check | Resultat | Verdict |
|---|---|---|
| Diff scope | uniquement docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md modifie | OK |
| Diff stat | +6 / -1 | OK |
| ASCII strict | 0 non-ASCII verifie via grep -cP | OK |
| Aucun source applicatif modifie | OUI | PRESERVE |
| Aucun manifest k8s modifie | OUI | PRESERVE |
| Aucun secret affiche | OUI | OK |
| `git worktree remove` lignes apres patch | 3 occurrences (default + STOP report + --force interdiction) | OK |
| `--force` lignes apres patch | 2 occurrences (Do NOT use as default + allowed exception phrasing) | OK toutes deux dans phrases d interdiction/exception |
| Markers nouvelle regle | "Default cleanup command", "dedicated cleanup phase", "explicit Ludovic GO", "canonical repo" tous presents | OK |
| Sections preservees | toutes hors section 8b "Cleanup of the build worktree" sous-section | PRESERVE |

## E5 - Guardrail cleanup final

| Cas | Autorise | Action |
|---|---|---|
| Cleanup normal build worktree apres phase (push + apply OK) | **OUI** | `git worktree remove <path>` + verifier path sous `/opt/keybuzz/build-worktrees/<phase>/` |
| Cleanup avec `--force` par defaut comme side-effect d une phase build/deploy/patch | **NON** | **STOP** |
| Cleanup avec `--force` en phase dediee GO Ludovic | OUI sous conditions strictes | Phase dediee + GO Ludovic explicite + path verification + rapport expliquant pourquoi normal removal a echoue |
| Cleanup canonical repo `/opt/keybuzz/keybuzz-api` en side-effect d une phase | **NON** | **STOP** (regle preservee depuis ca47eda + repete explicitement dans nouveau bloc cleanup) |
| Echec `git worktree remove <path>` normal | NON force automatique | **STOP** + rapport raison echec |
| Stale build worktree non nettoye apres push + apply | Pas recommande | Cleanup normal au prochain GO ou phase suivante |

## AI feature parity / anti-regression

| Aspect | Resultat | Verdict |
|---|---|---|
| keybuzz-api/src/modules/autopilot/engine.ts | NON touche | PRESERVE PH-20.12B Step 6.5 |
| keybuzz-api/src/services/noReplyClassifier.ts | NON touche | PRESERVE |
| keybuzz-api/src/config/kbactions.ts | NON touche | PRESERVE sentinel |
| keybuzz-api/src/services/autopilotGuardrails.ts | NON touche | PRESERVE seller-first hash 3b85a276 |
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
| Section 8b PH147 hardening core | PRESERVE (seule sous-section "Cleanup" modifiee, autres sous-sections intactes) | OK |

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
| kubectl apply / set image / set env / patch / edit / rollout restart | OUI | uniquement kubectl get pour preflight serait possible (non execute ici, runtime preserve via dette connue) |
| deploy DEV/PROD | OUI | runtime preserve |
| modifier manifest k8s/ | OUI | aucun fichier touche |
| modifier source applicative (api/client/backend/admin-v2/website) | OUI | aucun source touche |
| cleanup effectif worktree | OUI | 0 commande `git worktree remove` executee |
| `git worktree remove --force` | OUI | 0 execution |
| `git reset --hard` / `git clean` / `git checkout --` | OUI | 0 commande destructive |
| nettoyage canonical repo API | OUI | dette dist/*.js preservee intentionnellement |
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
| Regles absolues operational doc sections 1-3, 5-8, 8b reste de section, 9-15 | PRESERVES | sections non modifiees, uniquement sous-section "Cleanup of the build worktree" remplacee |

## Rollback

| Element | Plan | Verdict |
|---|---|---|
| Docs only | `git revert <commit>` sur main si erreur ; aucun runtime impact | OK plan simple |
| Runtime | N/A (aucun touche) | PRESERVE |
| Manifest | N/A (aucun touche) | PRESERVE |
| Source applicatif | N/A (aucun touche) | PRESERVE |
| Canonical repo API dirty state | N/A (dette preservee intentionnellement) | PRESERVE |
| Build worktrees existants | N/A (aucun cleanup execute) | PRESERVE |

## Linear

Commentaires postes (statuts INCHANGES 100%, 0 ticket cree) :
- KEY-337 (parent PH-20) : commentaire principal hardening cleanup no-force
- KEY-348 (observation differee PH-20.12C) : commentaire court car observation future heritera du guardrail cleanup
- KEY-349 (rotation PGPASSWORD DEV) : commentaire court pour signaler que cette dette security reste separee de la regle cleanup

KEY-231 NON commentee (cette phase est build cleanup guardrail, pas product/UX KBActions).
KEY-235 / KEY-263 / KEY-270 / KEY-302 / KEY-305 / KEY-308 / KEY-309 / KEY-312 NON commentes (preserves).

## Prochaine action recommandee

- **GO READONLY PRODUCT AUDIT KBACTIONS VALUE ANXIETY UX PH-SAAS-T8.12AS.20.13** (reprendre KEY-231 UX angle)
- Ou GO OBSERVE PH-20.12C quand trafic reel client suffisant (KEY-348)
- Ou GO CLEANUP API DIST DEBT PH147 SOURCE-OF-TRUTH (dedicated phase avec GO Ludovic, JAMAIS side-effect, JAMAIS avec --force par defaut)
- Ou GO CLEANUP STALE BUILD WORKTREES (dedicated phase avec GO Ludovic si stale worktrees identifies sous `/opt/keybuzz/build-worktrees/<phase>/`, cleanup normal sans --force, --force exception documentee si necessaire)

STOP.
