# PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-CLOSE-01

> Date : 2026-05-24
> Linear : KEY-337 parent PH-20 ; KEY-231 KBActions trial value/anxiety ; KEY-270 cloture audits IA ; references KEY-312 / KEY-235 / KEY-305 / KEY-263 / KEY-302 / KEY-308 / KEY-309
> Phase : PH-SAAS-T8.12AS.20.12B CLOSE
> Environnement : docs + Linear only (no runtime change)

## VERDICT

GO CLOSE PH-20.12B AUTOPILOT NO-REPLY KBACTIONS READY PH-SAAS-T8.12AS.20.12B

Prochaine action recommandee : GO OBSERVE AUTOPILOT NO-REPLY KBACTIONS SAVINGS PROD PH-SAAS-T8.12AS.20.12C (observation read-only 24-48h)

## Recap objectif / probleme initial

L'audit PH-20.12 (commit infra 0f23944) a confirme un gap technique cote API :
- Aucune classification no-reply avant Autopilot
- Environ 30 KBActions / 30j PROD gaspillees sur notifications Amazon plateforme
- Environ 12% du trafic autopilot concerne
- 149/356 messages inbound HUMAN PROD 30j (42%) avec sender clairement notification

Patterns principaux identifies :
- Amazon Seller Central Notifications/Communications donotreply (FR/IT/ES/EN variants)
- Amazon.xx donotreply (.com / .co.uk / .de / .fr / .it / .es / .nl)
- atoz-guarantee-no-reply
- Amazon Business noreply

Doctrine seller-first/refund (PH-20.11C KEY-312) deja en place via guardrails, mais classifier no-reply manquant -> KBActions debites + LLM calls inutiles avant que les guardrails ne puissent agir.

## Recap solution

Source patch PH-20.12B commit API `38c048c0` sur branche `ph147.4/source-of-truth` :
- NEW `src/services/noReplyClassifier.ts` : classifier pur sans I/O (5 subtypes)
- NEW `src/tests/ph119-tests.ts` : 15 tests unitaires standalone
- MOD `src/modules/autopilot/engine.ts` : Step 6.5 entre Step 6 (Context) et Step 6b (Order) + import classifier
- MOD `src/modules/ai/shared-ai-context.ts` : ConversationContextShared.last_message_author_name
- MOD `src/config/kbactions.ts` : entry `'autopilot_skipped_no_reply': 0.0` + fix `||` -> `??` pour honorer 0.0

Comportement :
- Step 6.5 dans `evaluateAndExecute()` skippe les notifications plateforme/no-reply AVANT wallet, AVANT guardrails, AVANT LLM, AVANT draft
- Classifier sender-driven 5 subtypes : `AMAZON_SELLER_CENTRAL_NOTIFICATION`, `AMAZON_ATOZ_NOREPLY`, `AMAZON_BUSINESS_NOREPLY`, `AMAZON_REGIONAL_NOREPLY`, `GENERIC_PLATFORM_NOREPLY`
- ai_action_log entry : `action_type=autopilot_none status=skipped reason=NO_REPLY_PLATFORM_NOTIFICATION:<subtype> blocked=true kbaCost=0`
- KBActions skip = 0 exact

## Services / runtimes DEV+PROD

| Service | DEV | PROD | Pod | Uptime | Restarts | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api | v3.5.256-autopilot-no-reply-kbactions-dev | v3.5.257-autopilot-no-reply-kbactions-prod | kpbjg / tlwgp | 134m / 28m | 0 / 0 | PH-20.12B LIVE |
| keybuzz-client | v3.5.214-ai-draft-blocked-reason-dev | v3.5.215-ai-draft-blocked-reason-prod | preserve | preserve | 0 | INCHANGE PH-20.11C |

## Commits API/Infra

| Repo | Branche | Commit | Description | Phase |
|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 38c048c0 | feat(autopilot): skip no-reply platform notifications before KBActions PH-20.12B | source patch |
| keybuzz-infra | main | 0f23944 | docs(ai): rapport PH-20.12 no-reply notifications KBActions audit | audit |
| keybuzz-infra | main | 84fe251 | docs(ai): rapport PH-20.12B source patch DEV no-reply autopilot | source patch report |
| keybuzz-infra | main | 841d0d8 | docs(ai): rapport PH-20.12B build API DEV from-git | build DEV |
| keybuzz-infra | main | 749a6b1 | docs(ai): rapport PH-20.12B push image API DEV GHCR | push DEV |
| keybuzz-infra | main | 3329513 | chore(api): deploy PH-20.12B no-reply KBActions DEV | manifest DEV bump |
| keybuzz-infra | main | eb7e96d | docs(ai): rapport PH-20.12B apply API DEV runtime live | apply DEV |
| keybuzz-infra | main | baf7254 | docs(ai): rapport PH-20.12B QA API DEV 25/25 PASS | QA DEV |
| keybuzz-infra | main | 014c25b | docs(ai): rapport PH-20.12B build API PROD from-git parite DEV bit-for-bit | build PROD |
| keybuzz-infra | main | 0c90d92 | docs(ai): rapport PH-20.12B push image API PROD GHCR | push PROD |
| keybuzz-infra | main | 9f21711 | chore(api): deploy PH-20.12B no-reply KBActions PROD | manifest PROD bump |
| keybuzz-infra | main | 888c520 | docs(ai): rapport PH-20.12B apply API PROD runtime live v3.5.257 | apply PROD |
| keybuzz-infra | main | 0aaae7d | docs(ai): rapport PH-20.12B QA API PROD 25/25 PASS runtime live | QA PROD |
| keybuzz-infra | main | (current) | docs(ai): close PH-20.12B autopilot no-reply KBActions | close (cette phase) |

## Images / tags / digests

| Image | Tag | Manifest digest GHCR | Config digest | OCI revision |
|---|---|---|---|---|
| API DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.256-autopilot-no-reply-kbactions-dev | sha256:5f50cc82ce6452bb2de35c129020348c6ea8d2dd47522f1d6061e81188116b92 | sha256:14060c7fab3496ab14788234497dc6fba383a28a4edc8b7498b84a744e7620b8 | 38c048c07fb98543437228657564ef4de388bdfb |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.257-autopilot-no-reply-kbactions-prod | sha256:52ec1bcf01de49803d56f17badd25ae558f7777eb59016824706f6f7d72d3ba3 | sha256:6a426a52780a490d0682a8bd7a0ad5d0149cee0ebed381147335e5fed86bc477 | 38c048c07fb98543437228657564ef4de388bdfb |

Size IDENTIQUE 343 519 201 bytes (327 MiB) DEV vs PROD = preuve mathematique parite source.

Parite bit-for-bit DEV vs PROD sur 5 fichiers critiques dist sha256 IDENTIQUES :
- services/noReplyClassifier.js : 92765d7c8c80591f321a502a09b7b79870dccbe188eb8d5665ed73fb8b81191f
- modules/autopilot/engine.js : ffea0ec1ed6f6d91ad61dfa66590144216d75727419c59b24f9d598dbc5b42a3
- config/kbactions.js : 8fa8b5de4a58cd3e68a5a79141ffba811cc096d5bf6e46d83648de78140c904b
- tests/ph119-tests.js : e2b6da3e00fd48dcf682405d5882da8347ed17f7d22877c8a1ebfc282a4c354f
- services/autopilotGuardrails.js : 74e4da5b6d3700f74d5a96bc27cf96c3ae5d58934ef2c586336abc6194305d86

KEY-308 OCI labels 6/6 + KEY-309 tag immuable respectes sur DEV et PROD.

## QA DEV / QA PROD

| Test | Categorie | DEV (commit baf7254) | PROD (commit 0aaae7d) |
|---|---|---|---|
| Fixtures no-reply Amazon (16) | 5 subtypes (Seller Central FR/IT/ES + Atoz + Business + Regional + Generic) | 16/16 PASS | 16/16 PASS |
| Controle clients reels marketplace (4) | Jean/Pierre/Marie/Mario, body IGNORE par classifier sender-driven | 4/4 PASS NOT classifies | 4/4 PASS NOT classifies |
| Controle PH-20.11C HIGH risk (1) | Sophie Lambert URGENT menace -> isNoReply=false, PRE_LLM_BLOCKED path preserve | 1/1 PASS | 1/1 PASS |
| KBActions skip + couts normaux (4) | autopilot_skipped_no_reply=0 + inbox_suggestion/contextualized dans fourchette +/-15% | 4/4 PASS (6.16/9.79) | 4/4 PASS (6.78/9.20) |
| TOTAL | | **25/25 PASS** | **25/25 PASS** |
| Logs delta runner | /ai/assist + /ai/execute + /autopilot/draft/consume | BEFORE=0 AFTER=0 delta=0 | BEFORE=0 AFTER=0 delta=0 |
| Erreurs runtime tail 1000 | TypeError/ReferenceError/HTTP 500/HTTP 503/Unhandled/DB error | 0 | 0 |
| /health probes | tail 1000 | 133 | 142 |

## AI feature parity / anti-regression

| Feature | Resultat | Verdict |
|---|---|---|
| Vrais messages clients marketplace NOT classifies no-reply | 4/4 PASS DEV + 4/4 PASS PROD (Jean, Pierre, Marie, Mario) | PRESERVE |
| Sender pattern no-reply DETECTES correctement | 16/16 PASS DEV + 16/16 PASS PROD (5 subtypes Amazon) | NEW LIVE DEV+PROD |
| HIGH risk customer PH-20.11C NOT classifie no-reply | 1/1 PASS DEV + 1/1 PASS PROD (Sophie Lambert) | PRESERVE PRE_LLM_BLOCKED path |
| blockedInfo / blockedStatus / blockedNotes preserve | dist PRE_LLM_BLOCKED 6 markers + routes.js | PRESERVE |
| Doctrine seller-first guardrails autopilotGuardrails.ts hash 3b85a276 | source INCHANGE + dist sha256 74e4da5b6d37 IDENTIQUE DEV/PROD | PRESERVE 100% |
| refundProtectionLayer.js + 15 refund refs | dist preserve DEV/PROD | PRESERVE |
| KBActions vrais drafts (inbox_suggestion 6.0 / inbox_contextualized 10.0 +/-15%) | 6.16/9.79 DEV + 6.78/9.20 PROD | PRESERVE |
| KBActions skip no-reply | 0 KBA exact DEV/PROD | NEW LIVE |
| /ai/assist / /ai/execute / /autopilot/draft/consume | preserve routes dist + 0 appel pendant QA | PRESERVE |
| LLM calls / Drafts generes / Messages marketplace pendant phase | 0 / 0 / 0 | OK |
| Mutation DB pendant phase | 0 | OK |
| Seuils guardrails modifies | non (autopilotGuardrails hash INCHANGE) | PRESERVE |
| PRE_LLM_BLOCKED rendu eligible draft | non (Step 6.5 ajoute SANS toucher PRE_LLM_BLOCKED) | PRESERVE |
| Client touche | NON (apply API-only DEV+PROD) | PRESERVE |
| KEY-305 race UI Client | preserve | PRESERVE |
| KEY-263 DEV/PROD isolation | preserve (tag DEV/PROD strict) | PRESERVE |
| KEY-302 build args sentinel | preserve (Dockerfile inchange) | PRESERVE |
| KEY-308 OCI labels 6/6 | OK DEV + OK PROD | COMPLIANT |
| KEY-309 tag immuable | OK (v3.5.256-...-dev + v3.5.257-...-prod uniques) | COMPLIANT |
| KEY-312 PH-20.11C Done | doctrine preserve | PRESERVE |

## No fake metrics / no fake events / no fake KBActions

| Risque | Verification | Verdict |
|---|---|---|
| Fake event tracking | aucun ajout dans source / dist / runtime | OK |
| Fake lead/register/checkout | aucun | OK |
| Fake message marketplace | aucun envoi pendant toute la sequence PH-20.12B | OK |
| Fake KBActions debit | Step 6.5 utilise debitAmount=0 ; computeKBActions('autopilot_skipped_no_reply') = 0 exact (preuve QA DEV+PROD) | OK |
| Fake conversation INSERT | aucune (runners QA = pure JS imports sans DB) | OK |
| Fake KPI / dashboard | aucun | OK |
| Mutation DB pendant phase | 0 | OK |
| Backfill stats | aucun | OK |
| Fake ai_action_log | aucune ; les futures entrees seront REELLES quand l engine recoit un message notif (action=autopilot_none status=skipped reason=NO_REPLY_PLATFORM_NOTIFICATION:<subtype>) | OK |
| Fixtures QA | uniquement en memoire dans le runner JS (sender names redacted, no PII) | OK |

## Limitation QA fixtures

QA DEV+PROD via :
- Fixtures locales pure JS (16 no-reply Amazon redacted + 4 controle clients + 1 PH-20.11C HIGH risk + 4 KBActions)
- Imports purs `noReplyClassifier.js` + `kbactions.js` UNIQUEMENT (no pool/litellm/wallet)
- Markers runtime dist verifies via kubectl exec
- Logs delta runner = 0 (BEFORE=0 AFTER=0 sur /ai/assist /ai/execute /autopilot/draft/consume)

QA DEV+PROD NON via :
- Trafic reel notif Amazon entrant (eviter side effects KBActions/LLM/DB)
- Flux engine.ts complet (checkActionsAvailable + loadFullConversationContext + evaluateGuardrails + chatCompletion) sur conv reelle

Validation flux integre garantie par :
- Tests source PH119 pre-build : 15/15 PASS (commit infra source patch 84fe251)
- Audit dist markers runtime DEV+PROD : tous markers presents
- Parite bit-for-bit DEV/PROD dist sha256 sur 5 fichiers critiques : IDENTIQUE
- QA DEV 25/25 PASS s applique mathematiquement au comportement PROD

## Observation 24-48h recommandee

Prochaine phase suggeree : PH-SAAS-T8.12AS.20.12C OBSERVE (read-only).

Mesures attendues :
1. Logs PROD : compter occurrences de `reason=NO_REPLY_PLATFORM_NOTIFICATION:<subtype>` dans logs API PROD (delta vs baseline pre-deploy)
2. SQL PROD read-only `ai_action_log` :
   - `WHERE action_type='autopilot_none' AND blocked_reason LIKE 'NO_REPLY_PLATFORM_NOTIFICATION:%'`
   - Compter par subtype (AMAZON_SELLER_CENTRAL_NOTIFICATION, AMAZON_ATOZ_NOREPLY, etc.)
   - Verifier `kbaCost=0` systematique sur ces entrees
3. KBActions delta : comparer avec baseline audit PH-20.12 (~30 KBA/30j PROD attendus economises)
4. Non-regression : verifier que cas legitimes (PRE_LLM_BLOCKED, draft genere normalement) ne sont pas affectes
5. Logs runtime : 0 erreur attendu

Aucun test destructif. Aucune mutation DB. Aucun appel LLM/marketplace.

## Rollback

| Element | Plan | Verdict |
|---|---|---|
| Rollback runtime PROD | 1) Manifest API PROD remet ghcr.io/keybuzzio/keybuzz-api:v3.5.255-ai-draft-blocked-reason-prod 2) git commit + push origin/main 3) kubectl apply -f manifest API PROD 4) rollout status 5) verifier pod imageID = sha256:8d3b4d093f087b56e9fcf07c3e6595528c50e3dd2aa5483208d323893261d9cf (v3.5.255) | OK plan documente |
| Rollback runtime DEV | 1) Manifest API DEV remet ghcr.io/keybuzzio/keybuzz-api:v3.5.254-ai-draft-blocked-reason-dev 2) git commit + push 3) kubectl apply 4) rollout 5) verifier pod imageID = sha256:e4f32a3ee71fb80dff3047f1891894b84bc4edc101f02bd2f10823b6f6509628 (v3.5.254) | OK plan documente |
| Rollback source | `git revert 38c048c0` sur ph147.4/source-of-truth + push (phase separee + rebuild) | OK plan documente |
| Aucun rollback actuellement | runtime DEV+PROD stable, QA 25/25 PASS, 0 erreur runtime, doctrine preserve | OK |

Interdiction kubectl set image / patch / edit pour rollback - GitOps strict via manifest + apply uniquement.

## Linear comments / statuts

Commentaires postes a chaque etape PH-20.12B sur KEY-337 (parent PH-20), KEY-231 (KBActions trial value/anxiety), KEY-270 (cloture audits IA) :

| Etape | KEY-337 | KEY-231 | KEY-270 |
|---|---|---|---|
| Audit PH-20.12 | 50224a43 | 33f00ad0 | 57573227 |
| Source patch PH-20.12B | ac569657 | d2080f9f | f1ff1e81 |
| Build DEV PH-20.12B | 05e0940d | 3bbf7096 | 9439093f |
| Push DEV PH-20.12B | 5fc75856 | c0d140f3 | 2b7a58de |
| Apply DEV PH-20.12B | 0b467fcc | 16236a7c | 5604f1f4 |
| QA DEV PH-20.12B | fee239f0 | 10f8147d | 084f6ca6 |
| Build PROD PH-20.12B | 1d097019 | 70396dab | 54cdf057 |
| Push PROD PH-20.12B | 7d0883fd | da63a5ca | 501b8084 |
| Apply PROD PH-20.12B | b64cf3ca | 4764dec2 | 6baa9941 |
| QA PROD PH-20.12B | 9c91a1fa | 0d610af7 | 5bf9cfcd |
| Close PH-20.12B | (cette phase) | (cette phase) | (cette phase) |

Statuts INCHANGES 100% :
- KEY-337 (parent PH-20) : Backlog INCHANGE
- KEY-231 (KBActions trial value/anxiety) : Todo INCHANGE
- KEY-270 (cloture audits IA) : Backlog INCHANGE
- KEY-235 / KEY-305 / KEY-263 / KEY-302 / KEY-308 / KEY-309 / KEY-312 : INCHANGES (non commentes)

Aucun ticket Linear cree dans toute la sequence PH-20.12B (10 etapes audit -> close).
Aucun changement statut Linear sauf demande explicite future de Ludovic.

## Confirmations securite (sequence PH-20.12B entiere)

| Interdit | Respecte | Preuve |
|---|---|---|
| docker build/push hors etapes BUILD/PUSH dediees | OUI | 0 commande hors plan |
| deploy DEV/PROD hors etapes APPLY dediees | OUI | runtime preserve sauf apply explicite |
| kubectl set/patch/edit/rollout restart | OUI | uniquement kubectl apply -f manifest + get + exec |
| modifier manifest GitOps hors etapes APPLY dediees | OUI | uniquement deployment.yaml DEV puis PROD |
| modifier Client/Admin/Website/Backend | OUI | aucun touche, uniquement keybuzz-api |
| LLM call durant toute la sequence | OUI | 0 (runners QA pure JS imports) |
| KBActions consommee durant toute la sequence | OUI | 0 (runners QA pure functions) |
| Mutation DB | OUI | 0 (aucun import pool/pg dans runners) |
| Message marketplace | OUI | 0 |
| Fake event/metric/conversation/KBActions | OUI | 0 (fixtures redacted, sans PII) |
| Secret/token/PII brut dans logs/rapports | OUI | aucun (PGPASSWORD note dans rapport PH-20.12 audit comme lecon retenue, non repete) |
| /opt/keybuzz/credentials ni /opt/keybuzz/secrets | OUI | non touche |
| Dump env de pods | OUI | 0 (kubectl exec uniquement pour ls/grep/curl localhost) |
| /ai/assist / /ai/execute / /autopilot/draft/consume | OUI | 0 appel dans toute la sequence |
| Bastion install-v3 (46.62.171.61) | OUI | hostname + IP verifies a chaque etape |
| git destructive (reset --hard / clean / force) | OUI | 0 commande |
| Creation ticket Linear | OUI | 0 ticket cree |
| Changement statut Linear | OUI | 0 transition |
| KEY-302/263/305/308/309/312 preserves | OUI | verifies a chaque etape |
| KEY-235 doctrine seller-first/refund | OUI | autopilotGuardrails source hash 3b85a276 INCHANGE + dist sha256 IDENTIQUE DEV/PROD |
| PH-20.11C blockedInfo path | OUI | PRE_LLM_BLOCKED 6 markers preserves dist DEV+PROD |

## Prochaine action

**GO OBSERVE AUTOPILOT NO-REPLY KBACTIONS SAVINGS PROD PH-SAAS-T8.12AS.20.12C**

Observation read-only 24-48h post-close pour mesurer economie reelle KBActions sur trafic notif Amazon entrant PROD vs baseline audit PH-20.12 (~30 KBA/30j attendus).

Aucune mutation. Aucun appel LLM. Aucun message. Logs + SQL read-only.

STOP.
