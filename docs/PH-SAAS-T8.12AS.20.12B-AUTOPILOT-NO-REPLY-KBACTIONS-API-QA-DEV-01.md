# PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-API-QA-DEV-01

> Date : 2026-05-24
> Linear : KEY-337 parent PH-20 ; KEY-231 KBActions trial value/anxiety ; KEY-270 cloture audits IA ; references KEY-312 / KEY-235 / KEY-305 / KEY-263 / KEY-302 / KEY-308 / KEY-309
> Phase : PH-SAAS-T8.12AS.20.12B
> Environnement : QA API DEV read-only (no build, no push, no deploy, no kubectl mutation, no DB mutation)

## VERDICT

GO QA API AUTOPILOT NO-REPLY KBACTIONS DEV READY PH-SAAS-T8.12AS.20.12B

Prochaine phrase GO recommandee : GO BUILD API AUTOPILOT NO-REPLY KBACTIONS PROD PH-SAAS-T8.12AS.20.12B

## Resume executif

QA DEV read-only valide le runtime API PH-20.12B applique. Runner Node.js execute directement dans le pod via kubectl exec, important UNIQUEMENT les modules compiles purs (`/app/dist/services/noReplyClassifier.js` + `/app/dist/config/kbactions.js`), avec 25/25 assertions PASS.

Cas no-reply Amazon plateforme (16 fixtures derivees des patterns reels observes en DB DEV/PROD 30j audit PH-20.12, sender names redacted) tous classifies CORRECTEMENT avec subtype attendu (AMAZON_SELLER_CENTRAL_NOTIFICATION x5, AMAZON_ATOZ_NOREPLY x4, AMAZON_BUSINESS_NOREPLY x2, AMAZON_REGIONAL_NOREPLY x4, GENERIC_PLATFORM_NOREPLY x1).

Controle clients reels (4 fixtures incluant Amazon buyer alias marketplace, mention "noreply" dans body, refund request avec keyword Amazon, marketplace italien) tous NOT classifies no-reply -> flux Autopilot preserve.

Controle PH-20.11C (HIGH risk customer avec menace + remboursement + avis menace public) NOT classifie no-reply -> PRE_LLM_BLOCKED path en aval PRESERVE 100%.

KBActions :
- `getKBActionsForSource('autopilot_skipped_no_reply')` = 0 KBA exact (sentinel compile)
- `KBACTIONS_WEIGHTS['autopilot_skipped_no_reply']` = 0 (table entry compile)
- `getKBActionsForSource('inbox_suggestion')` = 6.16 KBA (dans 6.0 +/-15%, vrais drafts PRESERVE)
- `getKBActionsForSource('inbox_contextualized')` = 9.79 KBA (dans 10.0 +/-15%, vrais drafts PRESERVE)

Logs delta runner : 0 appel /ai/assist + 0 appel /ai/execute + 0 appel /autopilot/draft/consume (avant runner = 0, apres runner = 0). 0 erreur tail 1000. 0 mutation DB. 0 message marketplace. 0 KBActions consommee. 0 LLM call.

Non-regression : API PROD v3.5.255 pod qv4jd 24h 0 restart INCHANGE, Client DEV pod nsh5f 31h 0 restart INCHANGE, Client PROD pod 92c96 22h 0 restart INCHANGE. API DEV pod kpbjg 13m Running 0 restart (uptime stable, aucun crash post-rollout).

## Sources lues

1. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md
2. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md
3. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md
4. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md
5. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12-AI-AUTOPILOT-NO-REPLY-NOTIFICATIONS-KBACTIONS-READONLY-AUDIT-01.md (0f23944) - patterns reels DB
6. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AI-AUTOPILOT-NO-REPLY-NOTIFICATIONS-KBACTIONS-SOURCE-PATCH-DEV-01.md (84fe251) - patch source
7. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-API-BUILD-DEV-01.md (841d0d8) - build
8. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-API-PUSH-IMAGE-DEV-01.md (749a6b1) - push
9. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.12B-AUTOPILOT-NO-REPLY-KBACTIONS-API-APPLY-DEV-01.md (eb7e96d) - apply

## E0 - Preflight

| Item | Attendu | Constate | Verdict |
|---|---|---|---|
| Bastion hostname | install-v3 | install-v3 | OK |
| Bastion IP externe | 46.62.171.61 | 46.62.171.61 | OK |
| Date UTC | 2026-05-24 | 2026-05-24 09:30 UTC | OK |
| API DEV image runtime | v3.5.256-autopilot-no-reply-kbactions-dev | v3.5.256-autopilot-no-reply-kbactions-dev | OK MATCH PH-20.12B applique |
| API DEV pod | Ready 1/1 0 restart | keybuzz-api-595f76dd5c-kpbjg Running 1/1 0 restart 10m+ | OK |
| API DEV imageID | sha256:5f50cc82ce64... | sha256:5f50cc82ce6452bb2de35c129020348c6ea8d2dd47522f1d6061e81188116b92 | OK MATCH GHCR digest |
| API DEV /health | HTTP 200 | http=200 | OK |
| API PROD | v3.5.255-...-prod | v3.5.255-ai-draft-blocked-reason-prod | INCHANGE |
| Client DEV | v3.5.214-...-dev | v3.5.214-ai-draft-blocked-reason-dev | INCHANGE |
| Client PROD | v3.5.215-...-prod | v3.5.215-ai-draft-blocked-reason-prod | INCHANGE |

## E1 - Dist runtime audit (heritage rapport apply eb7e96d)

| Marker | Fichier dist | Count | Verdict |
|---|---|---|---|
| noReplyClassifier.js | /app/dist/services/noReplyClassifier.js | present 5407 bytes | NEW LIVE |
| NO_REPLY_PLATFORM_NOTIFICATION | classifier x3 + engine x1 | 4 markers | OK |
| autopilot_skipped_no_reply | kbactions.js x1 | 1 marker | OK weight compile |
| classifyNoReplyPlatformNotification | classifier x2 + engine x1 | 3 markers | OK wired |
| PRE_LLM_BLOCKED preserve | engine x3 + guardrails x1 + routes x2 | 6 markers | PRESERVE |
| refundProtectionLayer.js | present | preserve | PRESERVE doctrine |
| ai-assist-routes.js / autopilot/routes.js | present | preserve | PRESERVE |

## E2/E3/E5/E6 - Runner QA Node.js dans pod (read-only pure imports)

Methode : `kubectl cp` script JS dans pod, puis `kubectl exec node /tmp/qa-runner.js`. Script importe UNIQUEMENT modules compiles purs sans side effect (`/app/dist/services/noReplyClassifier.js` + `/app/dist/config/kbactions.js`). Aucun import pool/litellm/wallet. Aucun appel HTTP. Aucune mutation DB. Aucun consommation KBActions.

Fixtures no-reply derivees des patterns OBSERVES en DB DEV/PROD 30j (audit PH-20.12 commit 0f23944), sender names redacted (pas de PII brute) :

| # | Fixture authorName (redacted) | Subtype attendu | Resultat | Verdict |
|---|---|---|---|---|
| 1 | Notifications Amazon Seller Central (Ne pas repondre) donotreply | AMAZON_SELLER_CENTRAL_NOTIFICATION | isNoReply=true subtype MATCH | PASS |
| 2 | Communications Amazon Seller Central (ne pas repondre) donotreply | AMAZON_SELLER_CENTRAL_NOTIFICATION | isNoReply=true subtype MATCH | PASS |
| 3 | Comunicaciones de Amazon Seller Central (no responder) donotreply | AMAZON_SELLER_CENTRAL_NOTIFICATION | isNoReply=true subtype MATCH | PASS |
| 4 | Comunicazioni di Amazon Seller Central (non rispondere) donotreply | AMAZON_SELLER_CENTRAL_NOTIFICATION | isNoReply=true subtype MATCH | PASS |
| 5 | Notifiche di Amazon Seller Central (non rispondere) donotreply | AMAZON_SELLER_CENTRAL_NOTIFICATION | isNoReply=true subtype MATCH | PASS |
| 6 | atoz-guarantee-no-reply | AMAZON_ATOZ_NOREPLY | isNoReply=true subtype MATCH | PASS |
| 7 | Garantie A a Z d Amazon atoz-guarantee-no-reply | AMAZON_ATOZ_NOREPLY | isNoReply=true subtype MATCH | PASS |
| 8 | Garantia de la A a la Z de Amazon atoz-guarantee-no-reply | AMAZON_ATOZ_NOREPLY | isNoReply=true subtype MATCH | PASS |
| 9 | Garanzia dalla A alla Z di Amazon atoz-guarantee-no-reply | AMAZON_ATOZ_NOREPLY | isNoReply=true subtype MATCH | PASS |
| 10 | Amazon Business Europe noreply | AMAZON_BUSINESS_NOREPLY | isNoReply=true subtype MATCH | PASS |
| 11 | Amazon Business noreply | AMAZON_BUSINESS_NOREPLY | isNoReply=true subtype MATCH | PASS |
| 12 | Amazon.es donotreply | AMAZON_REGIONAL_NOREPLY | isNoReply=true subtype MATCH | PASS |
| 13 | Amazon.it donotreply | AMAZON_REGIONAL_NOREPLY | isNoReply=true subtype MATCH | PASS |
| 14 | Amazon.com donotreply | AMAZON_REGIONAL_NOREPLY | isNoReply=true subtype MATCH | PASS |
| 15 | Amazon.nl donotreply | AMAZON_REGIONAL_NOREPLY | isNoReply=true subtype MATCH | PASS |
| 16 | Amazon Europe noreply | GENERIC_PLATFORM_NOREPLY | isNoReply=true subtype MATCH | PASS |

Fixtures controle clients reels (NOT classifies) - PASS 4/4 :

| # | Fixture | isNoReply attendu | Resultat | Verdict |
|---|---|---|---|---|
| 17 | Jean Dupont @marketplace.amazon.fr + "remboursement commande" | false | false subtype=null | PASS |
| 18 | Pierre Durand @marketplace.amazon.fr + body mentionne "noreply Amazon" | false | false (sender-driven, body ignore) | PASS |
| 19 | Marie Martin @marketplace.amazon.fr + "remboursement immediat avis Amazon" | false | false (preserve PH-20.11C HIGH risk path) | PASS |
| 20 | Mario Rossi @marketplace.amazon.it + "rimborso" | false | false (Italian customer) | PASS |

Fixture controle PH-20.11C preserve (NOT classifie no-reply, doit aller en PRE_LLM_BLOCKED path en aval) - PASS 1/1 :

| # | Fixture | isNoReply attendu | Resultat | Verdict |
|---|---|---|---|---|
| 21 | Sophie Lambert + "URGENT remboursement avocat avis 1 etoile menace reseaux" | false | false (sender client reel, PRE_LLM_BLOCKED path preserve) | PASS |

KBActions verification (PASS 4/4) :

| # | Test | Attendu | Resultat | Verdict |
|---|---|---|---|---|
| 22 | getKBActionsForSource('autopilot_skipped_no_reply') | 0 exact | 0 | PASS |
| 23 | KBACTIONS_WEIGHTS['autopilot_skipped_no_reply'] | 0 exact | 0 | PASS |
| 24 | getKBActionsForSource('inbox_suggestion') in [5.1, 6.9] | dans fourchette +/-15% | 6.16 | PASS preserve |
| 25 | getKBActionsForSource('inbox_contextualized') in [8.5, 11.5] | dans fourchette +/-15% | 9.79 | PASS preserve |

**TOTAL 25/25 PASS** dans le runtime pod.

## E4 - Verification skip avant LLM/draft/message (logs delta)

| Endpoint | Logs BEFORE runner (tail 1000) | Logs AFTER runner (tail 1000) | Delta | Verdict |
|---|---|---|---|---|
| /ai/assist | 0 | 0 | 0 | OK aucune side effect |
| /ai/execute | 0 | 0 | 0 | OK aucune side effect |
| /autopilot/draft/consume | 0 | 0 | 0 | OK aucune side effect |
| Combine (grep -cE) | 0 | 0 | 0 | OK |

Runner declare via console.log :
- AUCUN appel /ai/assist (classifier import only)
- AUCUN appel /ai/execute
- AUCUN appel /autopilot/draft/consume
- AUCUNE KBActions consommee (computeKBActions pure function, no debit)
- AUCUN appel LLM (no chatCompletion import)
- AUCUNE mutation DB (no pool query)
- AUCUN message marketplace (no send)
- AUCUN fake event/conversation/lead (read-only runner)

## E5 - Controle vrais clients PRESERVE

Voir tableau E2/E3/E5/E6 fixtures 17-20 (4/4 PASS). Tous les clients reels marketplace Amazon (buyer alias `@marketplace.amazon.<tld>` + nom personne) sont CORRECTEMENT NOT classifies no-reply :
- Hard exclusion BUYER_HANDLE_RX (`@marketplace.amazon.<tld>`) - jamais classifie via handle
- Sender authorName personne (Jean, Pierre, Marie, Mario) - aucun match patterns no-reply
- Body content (mentions "Amazon", "noreply", "remboursement", "avis", "rimborso") - body IGNORE par classifier sender-driven

Comportement Autopilot pour ces clients en runtime : flux normal Wallet -> Context -> Step 6.5 SKIP (isNoReply=false) -> Step 6b Order Context -> Step 6d Guardrails -> Step 7 LLM draft.

## E6 - Controle PH-20.11C preserve

Fixture HIGH risk 21 (Sophie Lambert URGENT menace) : NOT classifie no-reply -> en runtime, le flux engine.ts atteint Step 6.5 (NO_REPLY skip = false), continue vers Step 6b/6c/6d (guardrails), et selon evaluateGuardrails declenche PRE_LLM_BLOCKED si combinedRisk HIGH (doctrine PH-20.11C / KEY-312 preserve).

Markers PH-20.11C verifies en dist runtime (heritage apply report) :
- PRE_LLM_BLOCKED : 6 markers (engine x3 + guardrails x1 + routes x2)
- blockedStatus / blockedNotes : preserve dans routes.js (GET /autopilot/draft expose)
- guardrailNotes : preserve
- autopilotGuardrails.ts source hash 3b85a276 INCHANGE
- refundProtectionLayer.js + 15 refund refs PRESERVE

Le classifier no-reply N EST PAS un raccourci pour PRE_LLM_BLOCKED : il se declenche AVANT, sur sender pattern uniquement. Si un vrai client envoie un sender pattern qui match (peu probable mais possible : client nomme "Pierre Donotreply" theoreique), le classifier renverra true et skippera l autopilot. Risk faux positif documente dans PH-20.12B source patch rapport, mitigation possible V2 via combined score + flag UI.

## E7 - Logs + non-regression runtime

| Element | Avant QA | Apres QA | Verdict |
|---|---|---|---|
| API DEV pod kpbjg | Running 1/1 10m 0 restart | Running 1/1 13m 0 restart | OK stable (croissance uptime normale) |
| API DEV erreurs (TypeError/ReferenceError/HTTP 500/HTTP 503/Unhandled/DB error) tail 1000 | 0 | 0 | OK clean |
| API DEV /health probes tail 1000 | normal | 133 probes | OK regulieres |
| API PROD pod qv4jd | Running 1/1 23h 0 restart | Running 1/1 24h 0 restart | PRESERVE |
| Client DEV pod nsh5f | Running 1/1 31h 0 restart | Running 1/1 31h 0 restart | PRESERVE |
| Client PROD pod 92c96 | Running 1/1 22h 0 restart | Running 1/1 22h 0 restart | PRESERVE |
| Manifests GitOps | INCHANGE | INCHANGE | PRESERVE |

## AI feature parity / anti-regression

| Feature | QA result | Verdict |
|---|---|---|
| Vrais messages clients marketplace NOT classifies no-reply | 4/4 controles PASS (Jean, Pierre, Marie, Mario) | PRESERVE |
| Sender pattern no-reply DETECTES correctement | 16/16 fixtures PASS (5 Seller Central + 4 Atoz + 2 Business + 4 Regional + 1 Generic) | NEW LIVE |
| HIGH risk customer PH-20.11C NOT classifie no-reply | 1/1 PASS (Sophie Lambert URGENT menace) | PRESERVE |
| blockedInfo / blockedStatus / blockedNotes preserve | dist markers PRE_LLM_BLOCKED 6 + routes.js | PRESERVE |
| Doctrine seller-first guardrails autopilotGuardrails.ts hash 3b85a276 | INCHANGE | PRESERVE 100% |
| refundProtectionLayer 15 refund refs | dist preserve | PRESERVE |
| KBActions vrais drafts (inbox_suggestion 6.0 +/-15% / inbox_contextualized 10.0 +/-15%) | 6.16 / 9.79 dans fourchette | PRESERVE |
| KBActions skip no-reply | 0 KBA exact | NEW LIVE |
| /ai/assist / /ai/execute / /autopilot/draft/consume | 0 appel pendant QA | OK aucun side effect |
| LLM calls | 0 | OK |
| Drafts generes | 0 | OK |
| Messages marketplace envoyes | 0 | OK |
| Mutation DB | 0 | OK |
| Seuils guardrails modifies | non (autopilotGuardrails hash INCHANGE) | PRESERVE |
| PRE_LLM_BLOCKED rendu eligible draft | non (Step 6.5 ajoute SANS toucher PRE_LLM_BLOCKED) | PRESERVE |
| KEY-305 race UI Client | preserve (Client non touche) | PRESERVE |
| KEY-263 DEV/PROD isolation | preserve | PRESERVE |
| KEY-302 build args sentinel | preserve | PRESERVE |
| KEY-308 OCI 6/6 | preserve | COMPLIANT |
| KEY-309 tag immuable | preserve | COMPLIANT |
| KEY-312 PH-20.11C Done | doctrine preserve | PRESERVE |

## No fake metrics / no fake events / no fake KBActions

| Risque | Verification | Verdict |
|---|---|---|
| Fake event tracking | 0 (runner = JS import + assert local) | OK |
| Fake lead/register/checkout | 0 | OK |
| Fake message marketplace | 0 | OK |
| Fake KBActions debit | 0 (computeKBActions pure function, retourne valeur sans debiter wallet) | OK |
| Fake conversation INSERT | 0 (aucun acces DB) | OK |
| Fake KPI / dashboard | 0 | OK |
| Mutation DB | 0 (runner n importe pas pg/pool) | OK |
| Backfill stats | 0 | OK |
| Fake ai_action_log | 0 (runner n importe pas engine.ts/autopilot path) | OK |
| Runner consomme wallet ou LLM | NON (imports purs uniquement : classifier + config) | OK |
| Fixtures = donnees reelles ? | NON : sender names patterns redacted (pas de PII), customer fixtures = noms generiques (Jean Dupont, etc.) | OK fixtures pures |

## Limites / fixtures

- Le runner utilise des FIXTURES LOCALES (en memoire dans le JS, pas d acces DB). Les patterns no-reply sont DERIVES des observations DB DEV/PROD audit PH-20.12 (commit 0f23944) mais les fixtures elles-memes ne contiennent AUCUNE PII reelle (sender names = patterns publics Amazon, customer fixtures = noms generiques).
- Pas d acces DB live (BEGIN READ ONLY non utilise dans cette phase, car le runner se concentre sur la pure function du classifier). La validation comportement reel sur trafic notif Amazon entrant sera mesuree post-QA via observation runtime logs + ai_action_log entries (phase observation 24-48h ou QA browser Ludovic separee).
- Le runner ne declenche PAS le flux engine.ts complet (qui passerait par checkActionsAvailable + loadFullConversationContext + evaluateGuardrails + chatCompletion) pour eviter tout side effect runtime. La validation du flux integre est garantie par tests source PH119 (15/15 PASS pre-build) + audit dist markers (E1 + apply report).

## Confirmations securite

| Interdit | Respecte | Preuve |
|---|---|---|
| docker build / push | OUI | 0 commande |
| deploy DEV/PROD | OUI | 0 ; runtime DEV stable + PROD INCHANGE |
| kubectl apply / set / patch / edit / rollout restart | OUI | uniquement kubectl get + exec (lecture + run) |
| manifest GitOps modifie | OUI | 0 fichier touche |
| LLM call | OUI | 0 (runner = pure JS import) |
| KBActions consommee | OUI | 0 (computeKBActions pure function) |
| Mutation DB | OUI | 0 (aucun import pool/pg) |
| Message marketplace | OUI | 0 |
| Fake event/metric/conversation/KBActions | OUI | 0 |
| Secret/token/PII brut | OUI | fixtures redacted, aucun secret affiche |
| /opt/keybuzz/credentials ni /opt/keybuzz/secrets | OUI | non touche |
| Dump env de pods | OUI | 0 (kubectl exec uniquement pour cp + run node + curl localhost /health) |
| /ai/assist / /ai/execute / /autopilot/draft/consume | OUI | 0 delta logs (BEFORE=0, AFTER=0) |
| Bastion install-v3 (46.62.171.61) | OUI | hostname + IP verifies E0 |
| git destructive | OUI | 0 |
| Creation ticket Linear | OUI | 0 |
| Changement statut Linear | OUI | 0 transition |

## Rollback

| Scenario | Plan | Verdict |
|---|---|---|
| QA OK (cas actuel) | aucun rollback necessaire | N/A |
| Si regression detectee | STOP RISK + proposer rollback GitOps strict API DEV vers v3.5.254 dans phase separee (manifest revert + commit + push + kubectl apply + rollout) | plan documente |
| Image GHCR pousee | persist sans impact si non referencee | OK |
| Source 38c048c0 | git revert en phase separee si necessaire | plan documente |

Aucun rollback automatique entrepris dans cette phase QA (verdict = READY).

## Linear

Commentaires sur tickets pertinents (statut INCHANGE 100%, 0 ticket cree) :
- KEY-337 (parent PH-20) : QA DEV success, runtime preuve 25/25
- KEY-231 (KBActions trial value/anxiety) : KBActions 0 prouve sur 25 assertions
- KEY-270 (cloture audits IA) : court rattachement etape QA DEV done
- KEY-235 / KEY-305 / KEY-263 / KEY-302 / KEY-308 / KEY-309 / KEY-312 : NON commentes (preserves)

## Gaps restants / V2 ideas (NON engages)

1. QA browser Ludovic : verifier visuellement comportement DEV (Inbox sur conv reelle notif Amazon + verifier qu aucun Brouillon IA n est genere)
2. Observation runtime 24-48h DEV : compter via SQL read-only les ai_action_log nouveaux entries avec reason=NO_REPLY_PLATFORM_NOTIFICATION:<subtype> et confirmer kbaCost=0
3. Build PROD from-git + push GHCR + deploy PROD (phase PH-20.12B-PROD avec GO Ludovic explicite, sequence identique a DEV : build -> push -> apply -> QA)
4. Client UI enrichissement noReplyInfo dans AISuggestionSlideOver (PH-20.12B-CLIENT optionnel)
5. V2 metric dashboard "Notifications skippees ce mois (KBActions economisees)"
6. V2 atoz-guarantee : workflow specifique Litige A-Z (subtype AMAZON_ATOZ_NOREPLY deja prepare et detecte separement)

## Prochaine phrase GO

**GO BUILD API AUTOPILOT NO-REPLY KBACTIONS PROD PH-SAAS-T8.12AS.20.12B**

STOP.
