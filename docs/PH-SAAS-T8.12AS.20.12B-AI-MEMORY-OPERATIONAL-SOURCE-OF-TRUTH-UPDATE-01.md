# PH-SAAS-T8.12AS.20.12B-AI-MEMORY-OPERATIONAL-SOURCE-OF-TRUTH-UPDATE-01

> Date : 2026-05-24
> Linear : KEY-337 parent PH-20 ; KEY-231 KBActions trial value/anxiety ; KEY-270 cloture audits IA ; KEY-348 observation differee PH-20.12C ; KEY-349 rotation PGPASSWORD DEV ; references KEY-312 / KEY-263 / KEY-302 / KEY-308 / KEY-309
> Phase : PH-SAAS-T8.12AS.20.12B-AI-MEMORY-OPERATIONAL-SOURCE-OF-TRUTH-UPDATE
> Environnement : DOCS ONLY (no runtime change, no manifest, no code)

## VERDICT

GO UPDATE AI_MEMORY OPERATIONAL SOURCE OF TRUTH READY PH-SAAS-T8.12AS.20.12B

Prochaine action recommandee : GO READONLY PRODUCT AUDIT KBACTIONS VALUE ANXIETY UX PH-SAAS-T8.12AS.20.13

## Resume executif

`KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md` mis a jour pour refleter l etat reel post-PH-20.12B closeout. Le doc etait obsolete depuis 2026-05-11 (AS.6.2 KEY-311) : runtime baseline section 4, source anchors section 5, et tickets section 13 contenaient des informations perimees.

Diff : 71 lignes touchees (+43 / -28), 0 non-ASCII. Sections modifiees : header (Last updated), section 4 (runtime baseline), nouvelle section 4b (recent PH milestones live), section 5 (source anchors), section 13 (tickets). Sections 1-3, 6-12, 14-15 INCHANGES (regles absolues + protocole preserves).

Aucun runtime change, aucun manifest k8s touche, aucun code applicatif modifie, aucun secret affiche, aucun build/push/deploy/kubectl mutation.

## Raison de la mise a jour

L operational source of truth est le PREMIER fichier que les agents (CE / Codex / human) doivent lire avant toute phase. Il etait desynchronise par rapport a la realite :

- Section 4 (runtime baseline) indiquait API DEV v3.5.168 / API PROD v3.5.151 / Client DEV v3.5.179 / Client PROD v3.5.174 - tous obsoletes depuis PH-20.11C et PH-20.12B
- Section 5 (source anchors) pointait vers API 070707a1 / Client f244a58 - sources pre-PH-20.11C
- Section 13 (tickets) indiquait KEY-263/301/304/305/308/309/311 comme Open/In Review - en realite tous Done depuis sequence AS.12.x + AS.6 + PH-20.11C + PH-20.12B
- KEY-312 (PH-20.11C blockedInfo guidance) Done depuis 2026-05-23 - non documente
- KEY-337/231/270 actifs/parents - non documentes
- KEY-348 (observation PH-20.12C differee) cree post-close PH-20.12B - non documente
- KEY-349 (rotation PGPASSWORD DEV exposition terminal audit) cree post-PH-20.12 - non documente

Risque : un nouvel agent qui se basait sur cette section pour comprendre l etat aurait fait des decisions erronees (e.g. tenter une promotion KEY-263 deja Done, ou rebuilder sur ancien anchor source). La mise a jour resynchronise canoniquement.

## Sources lues

1. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md (avant modification, 222 lignes)
2. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md (section PH-20.11C + PH-20.12B ajoutees post-close)
3. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md
4. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md
5. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md
6. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-LINEAR-DONE-01.md (KEY-312 Done baseline)
7. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-CLOSE-01.md (commit 525b6cb, 11 etapes PH-20.12B recap)

## E0 - Preflight

| Item | Attendu | Constate | Verdict |
|---|---|---|---|
| Bastion hostname | install-v3 | install-v3 | OK |
| Bastion IP externe | 46.62.171.61 | 46.62.171.61 | OK |
| Date UTC | 2026-05-24 | 2026-05-24 16:39 UTC | OK |
| keybuzz-infra branche | main | main | OK |
| keybuzz-infra HEAD initial | 525b6cb (PH-20.12B CLOSE) | 525b6cbe594c1401cedd537dd3a41e94b2d9bf9e | OK |
| keybuzz-infra dirty | clean | clean | OK |
| API DEV runtime | v3.5.256-autopilot-no-reply-kbactions-dev | MATCH | OK PH-20.12B live |
| API PROD runtime | v3.5.257-autopilot-no-reply-kbactions-prod | MATCH | OK PH-20.12B live |
| Client DEV runtime | v3.5.214-ai-draft-blocked-reason-dev | MATCH | INCHANGE PH-20.11C |
| Client PROD runtime | v3.5.215-ai-draft-blocked-reason-prod | MATCH | INCHANGE PH-20.11C |
| Pod API DEV uptime/restart | Ready 0 restart | kpbjg Running 7h20m 0 restart | OK |
| Pod API PROD uptime/restart | Ready 0 restart | tlwgp Running 5h33m 0 restart | OK |

## E1 - Audit source documentaire (sections obsoletes identifiees)

| Section | Etat avant | Correction necessaire | Verdict |
|---|---|---|---|
| Header `Last updated` | 2026-05-11 (AS.6.2 KEY-311) | -> 2026-05-24 (PH-20.12B autopilot no-reply KBActions closeout) | A patcher |
| Section 4 - runtime baseline | 12 lignes obsoletes (API DEV v3.5.168, API PROD v3.5.151, Client DEV v3.5.179, Client PROD v3.5.174, etc.) | Update API DEV/PROD + Client DEV/PROD avec runtimes PH-20.12B/PH-20.11C verifies. Marquer autres services "(not revalidated in this docs-only phase)". | A patcher |
| Section 4b (nouvelle) | absent | Ajouter section "Recent PH milestones live" : PH-20.11C COMPLETE 2026-05-23 + PH-20.12B COMPLETE 2026-05-24 avec resume comportement + KBActions impact | A creer |
| Section 5 - source anchors | API 070707a1 (PH-AS.1 escalation notifications) + Client f244a58 (AS.1.1 build args fix) | -> API 38c048c0 (PH-20.12B no-reply skip, herite 5070e6a6 PH-20.11C) + Client 1a30ad9 (PH-20.11C guidance chain beabcd81+d132cc4f+1a30ad9) | A patcher |
| Section 12 - do-not-redeploy | 8 images listees (AS.1, AS.4.1, AS.5.x rollback artifacts) | INCHANGE (toujours valides, aucune image PH-20.12B ajoutee a la liste car saine) | PRESERVE |
| Section 13 - tickets | 11 entrees statuts 2026-05-11 (KEY-263 In Review, KEY-301 Open, KEY-304 Open, KEY-305 In Review, KEY-308 Open, KEY-309 Open, etc.) | Update statuts post-AS.12.x + PH-20.11C + PH-20.12B (la plupart Done). Ajouter KEY-312 / KEY-337 / KEY-231 / KEY-270 / KEY-348 / KEY-349 | A patcher |
| Sections 1, 2, 3, 6, 7, 8, 9, 10, 11, 14, 15 | regles absolues + protocole + GitOps + build + Linear + update protocol | INCHANGES | PRESERVE |

## E2 - Patch applique

| Fichier | Modification | Lignes |
|---|---|---|
| docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md | Header Last updated + section 4 (runtime baseline) + section 4b (NEW recent PH milestones) + section 5 (source anchors) + section 13 (tickets) | 71 lignes touchees (+43 / -28) |

Sections preservees INCHANGEES :
- Section 1 - Purpose
- Section 2 - Canonical repos and paths
- Section 3 - Bastion and SSH (install-v3 / 46.62.171.61)
- Section 6 - Mandatory preflight
- Section 7 - GitOps rules (no kubectl set/patch/edit/env, manifest -> commit -> push -> apply -> rollout)
- Section 8 - Build rules (clean tree, commit+push, immutable tag, KEY-302 client build args, KEY-308 OCI labels, KEY-309 tag discipline)
- Section 9 - Smoke harness rules V1 AS.6
- Section 10 - Reports rules ASCII strict + docs-only direct commit AS.6.1
- Section 11 - Linear / disclosure rules
- Section 12 - Do-not-redeploy images (8 images preservees)
- Section 14 - Prompting standard (long-form mandatory)
- Section 15 - Update protocol

Contenu mis a jour - resume :

**Section 4 (runtime baseline)** :
- API DEV : v3.5.256-autopilot-no-reply-kbactions-dev
- API PROD : v3.5.257-autopilot-no-reply-kbactions-prod
- Client DEV : v3.5.214-ai-draft-blocked-reason-dev
- Client PROD : v3.5.215-ai-draft-blocked-reason-prod
- Autres services (backend, outbound-worker, website, admin-v2) : marques "(not revalidated in this docs-only phase)" - inherited from 2026-05-11 baseline

**Section 4b (NEW recent PH milestones)** :
- PH-20.11C : COMPLETE end-to-end (technical + visual Ludovic) 2026-05-23 - API expose blockedInfo + Client auto-open drawer + carte amber + guidance statique + Copier la trame (no LLM, no KBActions) - KEY-312 Done
- PH-20.12B : COMPLETE end-to-end (DEV+PROD live, observation real traffic deferred) 2026-05-24 - Step 6.5 dans engine.ts skippe notifications plateforme/no-reply AVANT wallet/guardrails/LLM/draft + classifier 5 subtypes + KBActions skip = 0 + ai_action_log entry + QA DEV+PROD 25/25 PASS + parite bit-for-bit DEV/PROD + cible ~30 KBA/30j economisees - observation differee KEY-348

**Section 5 (source anchors)** :
- keybuzz-api 38c048c0 = PH-20.12B no-reply skip (herite 5070e6a6 PH-20.11C blockedInfo)
- keybuzz-client 1a30ad9 = PH-20.11C guidance chain (beabcd81 + d132cc4f + 1a30ad9)
- Parite bit-for-bit DEV/PROD confirmee
- autopilotGuardrails.ts source hash 3b85a276 INCHANGE - doctrine seller-first/refund preserve 100%

**Section 13 (tickets)** :
- KEY-263 : Done (DEV/PROD isolation preserve a chaque phase)
- KEY-301 : Done (resolved AS.12 sub-phases)
- KEY-302 : Done preserve (sentinel `__MUST_BE_SET_BY_BUILD_ARG__` on Client rebuild)
- KEY-304 : Done (AS.12.2C-x)
- KEY-305 : Done (PRE_LLM_BLOCKED path PH-20.11C preserve fix race UI)
- KEY-306 : Todo (JWT_SESSION_ERROR PROD non addresse PH-20.11C/PH-20.12B)
- KEY-307 : Todo (Admin-v2 build args non addresse)
- KEY-308 : Done (6/6 labels verifies API DEV v3.5.256 + PROD v3.5.257)
- KEY-309 : Done (tag discipline respectee PH-20.12B)
- KEY-310 : V1 In Review / Done pending
- KEY-311 : Done (ce doc canonical, updated 2026-05-24)
- KEY-312 : Done 2026-05-23 (PH-20.11C end-to-end post visual validation Ludovic PROD)
- KEY-337 : Backlog parent PH-20 (PH-20.11C + PH-20.12B closed underneath, autres PH-20.x pending)
- KEY-231 : Todo (PH-20.12B addresses no-reply side, broader UX value/anxiety angle open)
- KEY-270 : Backlog (PH-20.12B commented as nouveau lot, cloture finale pending GO Ludovic)
- KEY-348 : Backlog NEW 2026-05-24 (PH-20.12C observation 24-48h read-only trafic reel post-close PH-20.12B)
- KEY-349 : Backlog NEW 2026-05-24 (rotation PGPASSWORD DEV apres exposition terminal audit PH-20.12, PROD non impacte)

## E3 - Verification diff

| Fichier | Changement | Risque | Verdict |
|---|---|---|---|
| docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md | +43 / -28 lignes (sections 4/4b/5/13 + header) | Aucun (docs only) | OK |
| docs/PH-SAAS-T8.12AS.20.12B-AI-MEMORY-OPERATIONAL-SOURCE-OF-TRUTH-UPDATE-01.md | NEW rapport docs-only | Aucun | OK |
| Manifest k8s | INCHANGE | N/A | PRESERVE |
| keybuzz-api source | INCHANGE | N/A | PRESERVE |
| keybuzz-client source | INCHANGE | N/A | PRESERVE |
| Autres services source | INCHANGE | N/A | PRESERVE |
| Secrets / credentials | INCHANGE (non touche) | N/A | PRESERVE |
| Runtime DEV/PROD | INCHANGE | N/A | PRESERVE |

ASCII strict : 0 non-ASCII verifie sur operational doc apres patch. Rapport docs-only verifie ASCII apres ecriture.

## AI feature parity / anti-regression (docs-only)

| Feature | Resultat | Verdict |
|---|---|---|
| PH-20.11C blockedInfo / drawer / guidance / Copier la trame | INCHANGE (Client + API runtime non touches) | PRESERVE |
| PH-20.12B no-reply skip + classifier 5 subtypes | INCHANGE (API runtime non touche) | PRESERVE |
| PRE_LLM_BLOCKED path non eligible au draft | INCHANGE | PRESERVE |
| autopilotGuardrails.ts hash 3b85a276 source + dist sha256 IDENTIQUE DEV/PROD | INCHANGE (autopilotGuardrails non touche) | PRESERVE doctrine seller-first 100% |
| refundProtectionLayer + 15 refund refs | INCHANGE | PRESERVE |
| KBActions vrais drafts (inbox_suggestion / inbox_contextualized) | INCHANGE | PRESERVE |
| KBActions skip no-reply = 0 | INCHANGE (sentinel kbactions.js non touche) | PRESERVE |
| Client / Admin-v2 / Website / Backend source | INCHANGE | PRESERVE |
| API source | INCHANGE | PRESERVE |
| K8s manifests | INCHANGE | PRESERVE |

## No fake metrics / no fake events / no fake KBActions

| Risque | Verification | Verdict |
|---|---|---|
| Fake event tracking | aucun ajout (docs only) | OK |
| Fake lead/register/checkout | aucun | OK |
| Fake message marketplace | aucun envoi | OK |
| Fake KBActions debit | 0 (aucun runtime touche) | OK |
| Fake conversation INSERT | 0 (aucun acces DB) | OK |
| Fake KPI / dashboard | aucun | OK |
| Mutation DB | 0 | OK |
| Backfill stats | 0 | OK |
| Observation KEY-348 differee | OUI - pas encore de trafic client reel suffisant pour mesurer economie KBActions vs baseline ~30 KBA/30j. Sera activee quand Ludovic donnera GO observation PH-20.12C. | DOCUMENTE |

## Confirmations securite

| Interdit | Respecte | Preuve |
|---|---|---|
| docker build / push | OUI | 0 commande |
| deploy DEV/PROD | OUI | runtime preserve, pods uptime stable (kpbjg 7h20m / tlwgp 5h33m) |
| kubectl apply / set / patch / edit / rollout restart | OUI | uniquement kubectl get pour preflight runtime |
| modifier manifest GitOps k8s/ | OUI | aucun touche |
| modifier source applicatif (api/client/backend/admin-v2/website) | OUI | aucun touche |
| LLM call | OUI | 0 |
| KBActions consommee | OUI | 0 |
| mutation DB | OUI | 0 |
| message marketplace | OUI | 0 |
| fake event/metric/conversation/KBActions | OUI | 0 |
| secret/token/PII brut | OUI | aucun |
| /opt/keybuzz/credentials ni /opt/keybuzz/secrets | OUI | non touche |
| dump env de pods | OUI | 0 |
| /ai/assist / /ai/execute / /autopilot/draft/consume | OUI | 0 appel |
| Bastion install-v3 (46.62.171.61) | OUI | hostname + IP verifies E0 |
| git destructive (reset --hard / clean / force) | OUI | 0 commande |
| Creation ticket Linear | OUI | 0 |
| Changement statut Linear | OUI | 0 transition (commentaires uniquement) |
| Regles absolues sections 1-3 + 6-12 + 14-15 du doc | PRESERVES | sections non modifiees |

## Rollback

| Element | Plan | Verdict |
|---|---|---|
| Docs only | `git revert <commit>` sur main si erreur ; aucun runtime impact | OK plan simple |
| Runtime | N/A (aucun runtime touche) | PRESERVE |
| Manifest GitOps | N/A (aucun manifest touche) | PRESERVE |
| Source applicatif | N/A (aucune source touchee) | PRESERVE |

## Linear

Commentaires postes (statuts INCHANGES 100%, 0 ticket cree) :
- KEY-337 (parent PH-20) : source operationnelle mise a jour apres PH-20.12B
- KEY-231 (KBActions trial value/anxiety) : baseline KBActions/no-reply documentee dans operational source
- KEY-348 (observation differee PH-20.12C) : maintenant dans source operationnelle, defer until trafic reel
- KEY-349 (rotation PGPASSWORD DEV) : maintenant dans source operationnelle

Pas de commentaire sur KEY-270 / KEY-235 / KEY-305 / KEY-312 / KEY-263 / KEY-302 / KEY-308 / KEY-309 (preserves, deja commentes a chaque phase PH-20.12B).

## Prochaine action recommandee

**GO READONLY PRODUCT AUDIT KBACTIONS VALUE ANXIETY UX PH-SAAS-T8.12AS.20.13**

Reprendre KEY-231 sur l angle UX value/anxiety plus large (au-dela du no-reply skip deja addresse en PH-20.12B). Audit read-only des points de friction Trial Wow Stack autour du compteur KBActions, perception client, narrative valeur.

Alternative differee : GO OBSERVE AUTOPILOT NO-REPLY KBACTIONS SAVINGS PROD PH-SAAS-T8.12AS.20.12C (quand trafic reel client suffisant pour mesurer economie KBActions vs baseline ~30 KBA/30j PROD attendus - KEY-348).

STOP.
