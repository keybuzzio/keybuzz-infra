# PH-SAAS-T8.12AS.20.12-AI-AUTOPILOT-NO-REPLY-NOTIFICATIONS-KBACTIONS-READONLY-AUDIT-01

> Date : 2026-05-23
> Linear : KEY-337 (parent PH-20), KEY-231 (KBActions trial value/anxiety), KEY-235 (doctrine seller-first), KEY-270 (cloture AI audits), KEY-312 (ref guardrail guidance Done)
> Phase : PH-SAAS-T8.12AS.20.12
> Environnement : PROD + DEV read-only strict applicatif

## VERDICT

GO READONLY AUDIT AI AUTOPILOT NO-REPLY NOTIFICATIONS KBACTIONS READY PH-SAAS-T8.12AS.20.12

Prochaine phrase GO recommandee : GO PRODUCT DECISION AI AUTOPILOT NO-REPLY NOTIFICATIONS KBACTIONS PH-SAAS-T8.12AS.20.12A

## Resume executif

Audit read-only applicatif strict : 0 mutation runtime, 0 LLM, 0 KBActions consommees, 0 mutation DB applicative, 0 changement Linear statut, 0 secret/PII brut affiche.

Gap technique confirme : le pipeline inbound API declenche Autopilot pour TOUS les messages, y compris les notifications plateforme no-reply (Amazon Seller Central donotreply, atoz-guarantee-no-reply, Amazon Business noreply, etc.). Cote Client une logique de classification existe deja (src/features/inbox/utils/messageClassifier.ts -> CLIENT / AMAZON_AUTO / SYSTEM) avec 16 patterns content + 4 patterns sender, mais elle n est PAS portee cote API et n influence PAS la decision de declencher evaluateAndExecute, computeKBActions ou debitKBActions.

Impact PROD 30 jours :
- 356 messages inbound HUMAN total
- 149 messages (~42%) ont un sender clairement notification no-reply (somme des patterns)
- 5 entrees ai_action_log autopilot sur conversations notification = ~30 KBActions debitees pour rien
- A comparer aux 38 entrees ai_action_log autopilot sur conversations clients reelles = ~230 KBActions debitees (cas legitimes incluant PRE_LLM_BLOCKED, ESCALATION_DRAFT, DRAFT_DISMISSED)

Impact actuel modere (~30 KBA / 30j PROD) mais croissance attendue avec :
- Plus de tenants en plan AUTOPILOT (Trial Wow Stack PH148)
- Plus de connecteurs Amazon actifs (KEY-244 + AS.13.3A live)
- Plus de notifications systeme Amazon par tenant

Risque structurel : a chaque nouveau tenant connecte Amazon, l Autopilot peut debiter des KBActions sur des notifications no-reply, generer du trafic LLM inutile (lorsque guardrails ne bloquent pas), produire des Brouillons IA bizarres sur des messages systeme, et generer de fausses metriques d activite SAV.

Recommandation produit : ajouter une etape pre-LLM no-reply classifier dans Autopilot engine, avant checkActionsAvailable et avant evaluateGuardrails, pour skipper proprement les NO_REPLY_PLATFORM_NOTIFICATION avec status=skipped reason=NO_REPLY_PLATFORM_NOTIFICATION blocked=false KBActions=0. Source de verite logique : porter src/features/inbox/utils/messageClassifier.ts cote API et le partager (parite UI/API).

## Sources lues

1. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md (entree PH-20.11C COMPLETE Done)
2. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md
3. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md
4. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md
5. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/API_AUTOPILOT_CONTEXT.md
6. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/AI_MESSAGING_FEATURE_PARITY_BASELINE.md
7. /opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/SELLER_FIRST_REFUND_PROTECTION_DOCTRINE.md
8. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-CLIENT-QA-PROD-01.md
9. /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.20.11C-GUARDRAIL-GUIDANCE-LINEAR-DONE-01.md
10. keybuzz-api : src/modules/autopilot/engine.ts (973 LOC), src/modules/autopilot/routes.ts (457 LOC), src/services/autopilotGuardrails.ts (476 LOC), src/services/ai-actions.service.ts (511 LOC), src/services/ai-credits.service.ts (369 LOC), src/modules/inbound/routes.ts (609 LOC), src/modules/inbound/amazonForward.ts (317 LOC), src/config/kbactions.ts
11. keybuzz-client : app/inbox/InboxTripane.tsx, src/features/inbox/utils/messageClassifier.ts, src/features/inbox/components/MessageFilterToggle.tsx, src/features/inbox/components/ConversationSummaryBar.tsx, src/features/ai-ui/*
12. Linear GraphQL API : ref tickets + keyword search (10 keywords, 18+ unique tickets identifies)

## Runtime snapshot

| Service | Namespace | Image | Pod | Ready | Restarts | Verdict |
|---|---|---|---|---|---|---|
| keybuzz-api DEV | keybuzz-api-dev | v3.5.254-ai-draft-blocked-reason-dev | keybuzz-api-9d69675d4-mh5d5 | 1/1 | 0 | LIVE INCHANGE |
| keybuzz-client DEV | keybuzz-client-dev | v3.5.214-ai-draft-blocked-reason-dev | keybuzz-client-7c65567649-nsh5f | 1/1 | 0 | LIVE INCHANGE |
| keybuzz-api PROD | keybuzz-api-prod | v3.5.255-ai-draft-blocked-reason-prod | keybuzz-api-56bff5c9c5-qv4jd | 1/1 | 0 | LIVE INCHANGE |
| keybuzz-client PROD | keybuzz-client-prod | v3.5.215-ai-draft-blocked-reason-prod | keybuzz-client-696bcd98c6-92c96 | 1/1 | 0 | LIVE INCHANGE |

Bastion : install-v3 / 46.62.171.61 / kubernetes-admin@kubernetes / date UTC 2026-05-23.

Branches API : ph147.4/source-of-truth HEAD 5070e6a6 (PH-20.11C baseline). Branche Client : ph148/onboarding-activation-replay (HEAD aligne PH-20.11C). Repos infra : main HEAD courant.

## Tickets Linear identifies

Aucun ticket dedie PH-20.12 n existe encore. Tickets pertinents trouves :

| Ticket | Statut | Type | Pertinence PH-20.12 | Action recommandee |
|---|---|---|---|---|
| KEY-231 | Todo | unstarted | KBActions trial : montrer la valeur sans creer d anxiete | Commenter audit + lier PH-20.12 |
| KEY-235 | Backlog | backlog | Aligner messages demo et IA sur doctrine seller-first / refund protection | Commenter (doctrine impactee si no-reply mal classe) |
| KEY-255 | Backlog | backlog | AP.2 Auditer et completer escalade Agent client / Agent KeyBuzz | Note de lien (escalations sur notif) |
| KEY-270 | Backlog | backlog | AP.3 Cloture finale memoire apres audits IA/messaging/connecteurs | Lier PH-20.12 comme nouveau lot avant cloture |
| KEY-271 | Todo | unstarted | AP.4 Audit regression connecteurs et features critiques avant Ads | Lier |
| KEY-291 | Done | completed | AR.7 Enrich message_source for AI assisted / autopilot replies | Reference reutilisable pour propagate flag noReply |
| KEY-305 | Done | completed | Inbox auto-suggestion IA ne se genere plus automatiquement | Ne pas casser : la suppression du brouillon auto est preserve, PH-20.12 ne reactive RIEN |
| KEY-312 | Done | completed | Guardrail guidance PH-20.11C | Reference doctrine |
| KEY-337 | Backlog | backlog | PH-20 parent | Commenter (sous-phase identifiee) |

Recommandation : creer ticket dedie PH-20.12 (titre suggestion : "AP.X - Skip Autopilot + KBActions on no-reply platform notifications") apres GO Ludovic. Ne pas creer dans cette phase.

## Cartographie source API (autopilot + inbound + services)

| Fichier | Bloc | Role actuel | Gap PH-20.12 | Verdict |
|---|---|---|---|---|
| src/modules/inbound/routes.ts:296 | autopilot trigger email inbound | evaluateAndExecute(conversationId, tenantId, 'inbound') fire-and-forget pour TOUT message email entrant | Aucune classification no-reply avant trigger | Gap source confirme |
| src/modules/inbound/routes.ts:588 | autopilot trigger amazon forward inbound | idem pour Amazon forward inbound | Aucune classification no-reply avant trigger | Gap source confirme |
| src/modules/inbound/amazonForward.ts:117-141 | cleanCustomerName() | Renomme "Notifications Amazon Seller Central (Ne pas repondre) donotreply" -> "Amazon" pour affichage ; idem atoz-guarantee, Amazon Business noreply, donotreply suffix | Logique uniquement display ; ne renvoie pas de flag isNotification ni de classification routable downstream | Gap structurel : connaissance presente mais non propagee |
| src/modules/autopilot/engine.ts:155 | evaluateAndExecute() entree | Sequence : loadSettings -> resolveIAMode -> checkActionsAvailable -> loadFullConversationContext -> evaluateGuardrails | Aucun step entre context et guardrails pour skipper notification | Gap design |
| src/modules/autopilot/engine.ts:248-257 | PRE_LLM_BLOCKED branch | const blockKba = computeKBActions('autopilot_draft'); await debitKBActions(tenantId, requestId, blockKba, conversationId); -> logAction status=skipped blocked=true reason=PRE_LLM_BLOCKED | Debite KBA meme si message est une notification systeme. Ce n est pas mal en soi pour les VRAIS clients risque haut (PH-20.11C), mais sur notif no-reply c est un faux positif | Gap couts cache derriere PRE_LLM_BLOCKED |
| src/services/ai-actions.service.ts:79 | computeKBActions() | Recoit source string, retourne cost via KBACTIONS_WEIGHTS table | autopilot_draft N EST PAS dans la table -> fallback 'default' = 6.0 KBA par draft tente, avec variance +/-15% | Source 'autopilot_draft' devrait avoir entree explicite ; et 'autopilot_no_reply_skip' devrait avoir 0.0 |
| src/config/kbactions.ts:36-58 | KBACTIONS_WEIGHTS table | inbox_suggestion=6.0 ; inbox_contextualized=10.0 ; inbox_regenerate=3.0 ; playbook_auto=8.0 ; playbook_simulation=4.0 ; attachment_analysis=14.0 ; sentiment_analysis=6.0 ; heavy_decision=20.0 ; default=6.0 | Pas d entree no_reply ni de cost 0.0 ; pas de difference autopilot vs inbox manual | Ajouter entree 'autopilot_skipped_no_reply' a 0.0 |
| src/services/autopilotGuardrails.ts | evaluateGuardrails | Risque buyer + product + combined, basee sur context message ; pas de fast-path notification | N a pas vocation a classer messages systemes - c est en amont qu il faut filtrer | Reste tel quel (preserve doctrine seller-first) |

## Cartographie source Client (Inbox)

| Fichier | Bloc | Role UI actuel | Gap PH-20.12 | Verdict |
|---|---|---|---|---|
| src/features/inbox/utils/messageClassifier.ts | classifyInboundMessage() | Retourne CLIENT \| AMAZON_AUTO \| SYSTEM via 16 content signals + 4 sender signals + messageSource/conversationType | Logique uniquement Client side, jamais executee API side | Sourcer ici pour porter cote API |
| src/features/inbox/components/MessageFilterToggle.tsx:18 | toggle UI | "Afficher/Masquer les notifications Amazon" | Permet de masquer visuellement, ne change pas le comportement Autopilot/KBActions | UI bonus mais ne resout pas le probleme |
| src/features/inbox/components/ConversationSummaryBar.tsx:30 | badge | conversationType === 'SYSTEM_NOTIFICATION' -> badge "Notification Amazon" + icone Bell | Necessite que la conversation soit deja taggee SYSTEM_NOTIFICATION cote DB - mais l API ne le fait pas systematiquement | Source de verite manquante en amont |
| src/features/ai-ui/AISuggestionSlideOver.tsx | Brouillon IA drawer | Affiche le brouillon recu via GET /autopilot/draft + (PH-20.11C) blockedInfo carte amber + trame | Aucune branche pour info-only / NO_REPLY_PLATFORM_NOTIFICATION | A enrichir lorsque API expose noReplyInfo (PH-20.12B) |
| src/features/ai-ui/MessageSourceBadge.tsx | badge source message | Affiche source agent/IA/auto | Ne distingue pas notification systeme du flux normal | Acceptable, pas urgent |

## Audit DB DEV read-only (30 jours)

Transaction strictement BEGIN READ ONLY ; ROLLBACK confirme transaction_read_only=on cote pool API DEV.

| Indicateur DEV | Valeur 30j | Note |
|---|---|---|
| messages.direction='inbound' total | 342 | base ref |
| message_source distinct | HUMAN | seule valeur observee sur inbound 30j |
| author_name matchant pattern no-reply | 147 (somme des distincts) | ~43% du flux inbound DEV |
| body matchant 'amazon_corp_legal' (footer legal Amazon) | 42 | indicateur secondaire |
| body matchant 'do_not_reply_body' (regex strict) | 0 | regex trop stricte, donc remontes via author_name uniquement |

Top author_name notification DEV 30j (extrait, ids et adresses non affichees) :

| author_redacted | count |
|---|---|
| Communications Amazon Seller Central (ne pas repondre) donot | 27+17 = 44 (deux variantes accents) |
| Amazon.es donotreply | 19 |
| Notifications Amazon Seller Central (Ne pas repondre) donotr | 14 |
| atoz-guarantee-no-reply | 14 |
| Amazon.it donotreply | 13 |
| Comunicaciones de Amazon Seller Central (no responder) donot | 10 |
| Comunicazioni di Amazon Seller Central (non rispondere) dono | 6 |
| Amazon Europe noreply | 6 |
| Comunicaciones de Seller Central de Amazon (no responder) do | 4 |
| Amazon Business Europe noreply | 4 |
| Garantie A a Z d Amazon atoz-guarantee-no-reply | 4 |
| Garantia de la A a la Z de Amazon atoz-guarantee-no-reply | 3 |
| Amazon.com donotreply | 2 |
| Garanzia dalla A alla Z di Amazon atoz-guarantee-no-reply | 1 |
| Notifiche di Amazon Seller Central (non rispondere) donotrep | 1 |
| Amazon.nl donotreply | 1 |
| Amazon Business noreply | 1 |

ai_action_log autopilot* sur conversations DEV notification 30j :

| action_type | status | blocked | reason | n | total_kba |
|---|---|---|---|---|---|
| autopilot_escalate | skipped | true | ESCALATION_DRAFT:0.85 | 3 | 18.08 |
| autopilot_escalate | skipped | true | ESCALATION_DRAFT:0.75 | 1 | 6.02 |

DEV total KBA debitees sur notif conv : ~24.10 KBA / 30j. Volume DEV faible (auto-test scenarios principalement).

## Audit DB PROD read-only (30 jours)

Transaction strictement BEGIN READ ONLY ; ROLLBACK confirme transaction_read_only=on cote pool API PROD.

| Indicateur PROD | Valeur 30j | Note |
|---|---|---|
| messages.direction='inbound' total | 356 | base ref |
| author_name matchant pattern no-reply | ~149 (somme distincts) | ~42% du flux inbound PROD |

Top author_name notification PROD 30j (extrait, distribution similaire DEV) :

| author_redacted | count |
|---|---|
| Communications Amazon Seller Central (ne pas repondre) (2 variantes accents) | 28 + 17 = 45 |
| Amazon.es donotreply | 19 |
| Notifications Amazon Seller Central (Ne pas repondre) | 15 |
| atoz-guarantee-no-reply | 14 |
| Amazon.it donotreply | 13 |
| Comunicaciones de Amazon Seller Central (no responder) | 10 |
| Comunicazioni di Amazon Seller Central (non rispondere) | 6 |
| Amazon Europe noreply | 6 |
| Garantie A a Z d Amazon atoz-guarantee-no-reply | 4 |
| Comunicaciones de Seller Central de Amazon (no responder) | 4 |
| Amazon Business Europe noreply | 4 |
| Garantia de la A a la Z de Amazon | 3 |
| Amazon.com donotreply | 2 |
| Amazon Business noreply | 1 |
| Amazon.nl donotreply | 1 |
| Garanzia dalla A alla Z di Amazon | 1 |
| Notifiche di Amazon Seller Central (non rispondere) | 1 |

ai_action_log autopilot* sur conversations PROD notification 30j :

| action_type | status | blocked | reason_short | n | total_kba |
|---|---|---|---|---|---|
| autopilot_escalate | skipped | true | ESCALATION_DRAFT | 2 | 11.94 |
| autopilot_escalate | skipped | true | DRAFT_GENERATED | 1 | 5.75 |
| autopilot_escalate | skipped | true | DRAFT_MODIFIED | 1 | 5.49 |
| autopilot_reply | skipped | true | DRAFT_DISMISSED | 1 | 6.90 |

PROD total KBA debitees sur notif conv 30j : ~30.08 KBA.

Comparaison conversations clients reelles (non-notification) 30j PROD :

| action_type | status | blocked | reason_short | n | total_kba |
|---|---|---|---|---|---|
| autopilot_reply | skipped | true | PRE_LLM_BLOCKED | 11 | 63.76 |
| autopilot_escalate | skipped | true | DRAFT_APPLIED | 9 | 57.03 |
| autopilot_escalate | skipped | true | ESCALATION_DRAFT | 8 | 49.09 |
| autopilot_reply | skipped | true | DRAFT_GENERATED | 4 | 24.37 |
| autopilot_escalate | skipped | true | DRAFT_MODIFIED | 3 | 17.60 |
| autopilot_reply | skipped | true | DRAFT_MODIFIED | 2 | 12.88 |
| autopilot_escalate | skipped | true | DRAFT_DISMISSED | 1 | 5.79 |

Total cas legitimes 30j : ~230 KBA.

Ratio waste / total = 30 / (30+230) = 11.5% du KBA autopilot PROD debite sur des notifications no-reply (modere mais non-nul).

## Pattern no-reply consolide

| Pattern no-reply | Occurrences DEV 30j | Occurrences PROD 30j | KBActions risk | Verdict |
|---|---|---|---|---|
| Sender Communications/Notifications Amazon Seller Central donotreply | ~58 | ~60 | 6-12 KBA par cas si guardrails laissent passer | A bloquer en amont |
| Sender Amazon.xx donotreply (.es .it .com .nl) | ~35 | ~35 | idem | A bloquer en amont |
| Sender atoz-guarantee-no-reply | ~22 | ~22 | idem | A bloquer en amont MAIS contenu peut etre litige A-Z (juridique) - cas border : trame statique guidance plutot que skip total ? |
| Sender Amazon Business (Europe) noreply | ~5 | ~5 | idem | A bloquer en amont |
| Body Amazon corp/legal footer | 42 | non mesure | indicateur secondaire | Pattern secondaire confirmation |

## Correlation KBActions / wallet

| Cas | LLM appele | KBActions actuelles | KBActions recommandees | Recommandation |
|---|---|---|---|---|
| Notification no-reply systeme, conversation neuve | non (autopilot s arrete sur WALLET_EMPTY ou MODE_NOT_AUTOPILOT) | 0 | 0 | Skip propre status=skipped reason=NO_REPLY_PLATFORM_NOTIFICATION (au lieu de NO_SETTINGS / WALLET_EMPTY confus) |
| Notification no-reply systeme, autopilot enable + plan AUTOPILOT + wallet OK | non si guardrails bloquent ; OUI si guardrails OK | 6 KBA (PRE_LLM_BLOCKED) ou 6-10 KBA (draft genere) | 0 KBA | Skip avant checkActionsAvailable + avant evaluateGuardrails |
| Atoz guarantee no-reply (litige A-Z) | non actuellement | 0-6 KBA | 0 KBA + flag UI "Litige A-Z notification - reponse possible via Seller Central" | Cas border : preserver visibilite mais ne pas auto-draft |
| Client reel via marketplace | OUI | 6-10 KBA selon contexte | 6-10 KBA inchange | Aucun changement |
| Client reel haute risque (PRE_LLM_BLOCKED PH-20.11C) | non (block) | 6 KBA | 6 KBA inchange (doctrine seller-first preserve) | Aucun changement |
| Ambigu (faible score classifier) | non / OUI selon guardrails | 0-10 KBA | 0 KBA + flag UI "Verification humaine recommandee" | Conservative : pas d auto-draft |

## Classification produit proposee

A. **NO_REPLY_PLATFORM_NOTIFICATION**
- Signal : sender match >=1 pattern (donotreply, noreply, no-reply, Notifications Amazon, atoz-guarantee, Amazon Business noreply) OU messageSource='SYSTEM' OU conversationType='SYSTEM_NOTIFICATION'
- Action IA : status=skipped reason=NO_REPLY_PLATFORM_NOTIFICATION blocked=false debit=0
- UI : badge "Notification - aucune reponse requise" + section repliable "Generer brouillon si besoin" (bouton manuel, debit normal si utilise)
- Risque : faible si patterns bien calibres

B. **CUSTOMER_REQUEST_VIA_MARKETPLACE**
- Signal : sender ne match aucun pattern notif + direction=inbound + messageSource pas SYSTEM
- Action IA : flux Autopilot inchange (eligible draft selon guardrails)
- UI : flux Brouillon IA actuel

C. **SENSITIVE_CUSTOMER_REQUEST**
- Signal : passe classification client + atteint PRE_LLM_BLOCKED via autopilotGuardrails (combinedRisk HIGH)
- Action IA : doctrine PH-20.11C preserve (carte amber + trame statique)
- UI : guidance guardrail (deja live PROD)

D. **AMBIGUOUS_NOTIFICATION**
- Signal : score classification entre seuil "client clair" et "notification clair" (ex : 1 sender signal mais 0 content signal)
- Action IA : status=skipped reason=AMBIGUOUS_NOTIFICATION blocked=false debit=0 + flag UI
- UI : badge "Classification incertaine" + bouton "Forcer brouillon IA"

| Classe | Signal | Action IA | KBActions | UI | Risque |
|---|---|---|---|---|---|
| A | sender pattern OR messageSource=SYSTEM OR conversationType=SYSTEM_NOTIFICATION | skip status=skipped | 0 | "Aucune reponse requise" | Faible |
| B | none of A,C,D | flux normal | 6-10 | Brouillon IA normal | Aucun changement |
| C | guardrails HIGH (PH-20.11C) | trame statique | 6 (debit conserve) | Carte amber + Copier trame | Doctrine preserve |
| D | score borderline | skip status=skipped | 0 | "Verification humaine" + bouton manuel | Modere (faux positifs Client B) |

## Decision technique proposee (NON appliquee)

Option recommandee : **Pre-LLM no-reply classifier en API**

Patch design (NON applique, NON commit, NON build) :

| Option | Fichiers | Benefice | Risque | Recommandation |
|---|---|---|---|---|
| Option 1 : Skip a la source dans engine | src/modules/autopilot/engine.ts (entre Step 5 Wallet et Step 6 Context) + src/services/noReplyClassifier.ts (NEW, portage de messageClassifier.ts client) | Source unique cote API, decision avant tout cost | Faux positifs si patterns mal calibres ; doctrine seller-first non impactee si on garde guardrails apres | RECOMMANDE |
| Option 2 : Skip dans inbound routes | src/modules/inbound/routes.ts (avant fire-and-forget evaluateAndExecute) + classifier service | Skip avant meme appel engine | Couplage logique IA dans inbound (mauvais decoupage de responsabilites) | Non recommande |
| Option 3 : Flag dans message_source + filtre engine | src/modules/inbound/amazonForward.ts (set messageSource='SYSTEM' systematique sur notif) + engine check | Source-of-truth DB queryable | Mutation DB invasive (re-tagging historique optionnel) | Possible mais necessite migration DB |
| Option 4 : Combiner Option 1 + Option 3 | classifier en engine + tag messages.message_source='SYSTEM' au write inbound | Defense en profondeur | Plus de code mais plus robuste | Possible en V2 si MVP Option 1 valide |

Patch propose (Option 1 detaille) :

Nouveau fichier `src/services/noReplyClassifier.ts` :
- Export `classifyNoReply(senderName: string, body: string, conversationType: string | null, messageSource: string | null): 'CUSTOMER' | 'NO_REPLY_NOTIFICATION' | 'AMBIGUOUS'`
- Patterns sender : meme set que client (noreply, no-reply, donotreply, notifications, seller central, atoz-guarantee, amazon business)
- Patterns content : meme set que client (16 patterns)
- Pre-check messageSource === 'SYSTEM' OR conversationType === 'SYSTEM_NOTIFICATION' -> NO_REPLY_NOTIFICATION immediat
- Si score combine >= 2 -> NO_REPLY_NOTIFICATION ; score = 1 -> AMBIGUOUS ; score = 0 -> CUSTOMER

Modification `src/modules/autopilot/engine.ts` :
- Apres Step 5 (Wallet) et avant Step 6 (Context full), ajouter Step 5b :
  - Load context light (juste senderName + body + conversationType + messageSource) via requete dediee
  - classifyNoReply() ;
  - Si NO_REPLY_NOTIFICATION : logAction(action='none', status='skipped', reason='NO_REPLY_PLATFORM_NOTIFICATION', blocked=false, kbaCost=0, payload={ classifier: 'sender_pattern_match' }) ; return noopResult('NO_REPLY_PLATFORM_NOTIFICATION')
  - Si AMBIGUOUS : logAction reason='AMBIGUOUS_NOTIFICATION_REQUIRES_HUMAN' status=skipped blocked=false kbaCost=0 ; return noopResult
  - Sinon : continuer flux normal

Modification `src/config/kbactions.ts` :
- Ajouter `'autopilot_skipped_no_reply': 0.0` dans KBACTIONS_WEIGHTS pour stricte audit (cout explicite zero plutot que fallback)

Modification `src/modules/autopilot/routes.ts` (GET /autopilot/draft) :
- Etendre payload reponse pour exposer `noReplyInfo: { type: 'NO_REPLY_NOTIFICATION' | 'AMBIGUOUS_NOTIFICATION' | null, detectedPattern: string }` (analogue a blockedInfo PH-20.11C)
- Aucune mutation DB necessaire

Modification client `src/features/ai-ui/AISuggestionSlideOver.tsx` (PH-20.12B-CLIENT) :
- Si noReplyInfo.type === 'NO_REPLY_NOTIFICATION' : carte info bleue "Aucune reponse requise - notification systeme" + bouton "Generer brouillon si necessaire" (qui declenche action manuelle Brouillon IA avec debit normal)
- Si noReplyInfo.type === 'AMBIGUOUS_NOTIFICATION' : carte ambigu "Classification incertaine - verification humaine recommandee" + bouton "Generer brouillon IA"
- Preservation totale doctrine PH-20.11C (PRE_LLM_BLOCKED reste prioritaire)

Risques applicatifs identifies (pour PH-20.12B-IMPL future) :

| Risque | Mitigation |
|---|---|
| Faux positif (vrai client classe NO_REPLY) | Score >= 2 obligatoire ; UI offre bouton manuel "Generer brouillon" | 
| Faux negatif (notif classee CUSTOMER) | Pas pire qu actuel, comportement identique flux actuel |
| Doctrine seller-first cassee (PRE_LLM_BLOCKED detourne) | Step pre-LLM no-reply AVANT evaluateGuardrails ; si message est NO_REPLY mais aussi sensible (rare), on prefere skip - aucun risque pour le client car aucune reponse ne sera envoyee de toute facon |
| Atoz guarantee A-Z classifie NO_REPLY trop agressif | Cas border : laisser passer en CUSTOMER pour permettre validation humaine - patterns peuvent l exempter avec exception explicite |
| Variance KBActions facturee aux clients | Cout 0 sur skip est correct (aucun LLM) ; sentinel KBACTIONS_WEIGHTS['autopilot_skipped_no_reply'] = 0.0 explicite |
| Multi-tenant : seuils differents par tenant | V2 : table tenant_no_reply_overrides ; V1 : patterns hard-coded suffisent |
| Regression metrics dashboard SAV | KEY-286/289/291/292 inchanges (skip n est pas un draft, pas un reply, donc aucune metric SAV impactee) |

## Logs read-only post-audit

| Env | Pattern | Count | Verdict |
|---|---|---|---|
| API PROD tail 2000 | TypeError / ReferenceError / HTTP 500 / HTTP 403 / Unhandled / database error / /ai/assist / /ai/execute / /autopilot/draft/consume | 0 | clean |
| API PROD tail 500 | Autopilot trigger + notification grep | 0 erreur, requetes normales GET /autopilot/draft | clean |

Aucun appel LLM declenche par l audit. Aucune KBActions consommee par l audit.

## AI feature parity / anti-regression

| Surface | Statut | Verifie pendant audit |
|---|---|---|
| Brouillon IA normal | LIVE PROD | NON modifie (audit read-only) |
| Brouillon IA blockedInfo (PH-20.11C) | LIVE PROD | NON modifie |
| Trame de reponse securisee (PH-20.11C) | LIVE PROD | NON modifie |
| Suggestion IA | LIVE PROD | NON modifie |
| Aide IA manuelle | LIVE PROD | NON modifie |
| Autopilot | LIVE PROD | NON modifie |
| Escalation | LIVE PROD | NON modifie |
| Guardrails seller-first (autopilotGuardrails.ts) | LIVE PROD | NON modifie - hash preserve |
| KBActions billing | LIVE PROD | NON modifie |
| Connecteurs marketplace | LIVE PROD | NON modifie |
| Inbox conversation classification UI | LIVE PROD (CLIENT/AMAZON_AUTO/SYSTEM) | NON modifie |
| Commande / suivi / historique IA | LIVE PROD | NON modifie |
| KEY-305 race UI | preserve | NON modifie |
| KEY-263 DEV/PROD isolation | preserve | NON modifie |
| KEY-302 build args | preserve | NON modifie |

## No fake metrics / no fake events / no fake KBActions

| Confirmation | Statut |
|---|---|
| Aucun event marketing | OK |
| Aucun fake lead/register/checkout | OK |
| Aucun fake message marketplace | OK |
| Aucun appel LLM | OK |
| Aucune KBActions consommee | OK |
| Aucune mutation DB applicative | OK (toutes les requetes en BEGIN READ ONLY + ROLLBACK) |
| Aucun usage de donnees artificielles | OK |
| Aucun fake KPI / dashboard / billing | OK |

## Confirmations securite

| Interdit | Respecte | Preuve |
|---|---|---|
| docker build / push | OUI | aucune commande |
| kubectl apply / set / patch / edit / delete | OUI | uniquement kubectl get / kubectl exec pour env grep |
| restart pod | OUI | pods Running INCHANGES (uptime preserves) |
| modifier source applicative | OUI | aucun edit/commit dans keybuzz-api ou keybuzz-client |
| modifier manifest GitOps | OUI | aucun edit/commit dans keybuzz-infra |
| appel /ai/assist /ai/execute /autopilot/draft/consume | OUI | 0 dans logs tail 2000 |
| LLM call | OUI | 0 |
| KBActions consommee | OUI | 0 |
| mutation DB | OUI | toutes transactions BEGIN READ ONLY + ROLLBACK |
| message marketplace | OUI | aucun envoi |
| fake event / metric | OUI | aucun |
| secret/token/PII brut | OUI | emails non affiches dans le rapport ; mots de passe DB inadvertamment visibles dans une commande mais NON repris dans rapport (a rotater hors PH-20.12 si necessaire) |
| changement Linear statut | OUI | aucun ticket transitionne, commentaires post-rapport seulement |
| bastion install-v3 / 46.62.171.61 | OUI | hostname + IP verifies preflight E0 |
| /opt/keybuzz/credentials ni /opt/keybuzz/secrets | OUI | non touche |
| KEY-305 / KEY-235 / KEY-231 / KEY-337 statut | OUI | inchanges |

Note securite : pendant E4, un grep kubectl exec env a affiche brievement le PGPASSWORD DEV dans la sortie commande (PowerShell terminal). Le mot de passe DEV n est PAS reproduit dans ce rapport. Recommandation hors PH-20.12 : verifier si rotation PGPASSWORD keybuzz_api_dev necessaire (Q-1B-2A rotation track existante).

## Tableaux finaux

### 1. Services

| Service | DEV | PROD | Verdict |
|---|---|---|---|
| keybuzz-api | v3.5.254-ai-draft-blocked-reason-dev | v3.5.255-ai-draft-blocked-reason-prod | LIVE INCHANGE |
| keybuzz-client | v3.5.214-ai-draft-blocked-reason-dev | v3.5.215-ai-draft-blocked-reason-prod | LIVE INCHANGE |

### 2. Tickets Linear

| Ticket | Statut | Pertinence | Action recommandee |
|---|---|---|---|
| KEY-231 | Todo | KBActions value/anxiety | Commenter audit |
| KEY-235 | Backlog | doctrine seller-first | Commenter doctrine impact |
| KEY-270 | Backlog | AP.3 cloture AI audits | Lier comme nouveau lot |
| KEY-337 | Backlog | parent PH-20 | Commenter sous-phase |

### 3. Pattern no-reply

| Pattern | DEV 30j | PROD 30j | KBActions risk | Verdict |
|---|---|---|---|---|
| Sender Notifications/Communications Amazon Seller Central donotreply | ~58 | ~60 | 6-12 KBA / cas | A bloquer pre-LLM |
| Sender Amazon.xx donotreply | ~35 | ~35 | idem | A bloquer pre-LLM |
| Sender atoz-guarantee-no-reply | ~22 | ~22 | idem | A bloquer pre-LLM (border : litige A-Z) |
| Sender Amazon Business (Europe) noreply | ~5 | ~5 | idem | A bloquer pre-LLM |
| Body amazon corp/legal footer | 42 | non mesure | secondaire | Pattern confirmation |

### 4. Source file gap

| Source file | Decision actuelle | Gap | Patch futur (NON applique) |
|---|---|---|---|
| src/modules/inbound/routes.ts:296,588 | trigger evaluateAndExecute pour tout inbound | aucune classification no-reply | (en Option 1) ne pas modifier ce fichier ; gerer dans engine |
| src/modules/inbound/amazonForward.ts:117-141 | cleanCustomerName display-only | flag isNotification non propage | Optionnel : exposer un helper isNoReplySender(name) reutilisable |
| src/modules/autopilot/engine.ts:155+ | Wallet -> Context -> Guardrails | aucun pre-LLM no-reply skip step | Ajouter Step 5b : classifyNoReply + early skip |
| src/services/ai-actions.service.ts | computeKBActions(source) | autopilot_draft -> default 6.0 ; pas d entree no_reply | Ajouter 'autopilot_skipped_no_reply': 0.0 |
| src/services/noReplyClassifier.ts | (n existe pas) | source unique partagee API/Client | Nouveau fichier, porter messageClassifier.ts logique |
| src/features/inbox/utils/messageClassifier.ts (Client) | classifyInboundMessage CLIENT/AMAZON_AUTO/SYSTEM | logique uniquement UI | Garder + utiliser comme source design pour API |
| src/features/ai-ui/AISuggestionSlideOver.tsx | drawer brouillon IA + blockedInfo PH-20.11C | pas de branche noReplyInfo | Ajouter cards info / ambigu (PH-20.12B-CLIENT) |

### 5. Cas

| Cas | LLM | KBActions actuel | KBActions cible | Action recommandee |
|---|---|---|---|---|
| Notif Amazon donotreply, autopilot off | NON | 0 | 0 (status confus -> propre) | skip propre reason=NO_REPLY_PLATFORM_NOTIFICATION |
| Notif Amazon, autopilot on, wallet OK, guardrails passe | OUI possible | 6-10 KBA | 0 | skip avant wallet + guardrails |
| Notif Amazon, autopilot on, PRE_LLM_BLOCKED | NON | 6 KBA | 0 | skip avant guardrails |
| Atoz no-reply (litige) | NON | 0 | 0 + UI flag | skip + flag "Litige A-Z" UI |
| Client reel marketplace | OUI | 6-10 KBA | 6-10 KBA | aucun changement |
| Client reel HIGH risk (PH-20.11C) | NON | 6 KBA | 6 KBA | doctrine preserve |

### 6. Interdits

| Interdit | Respecte | Preuve |
|---|---|---|
| docker build/push | OUI | aucune commande |
| deploy DEV/PROD | OUI | runtime INCHANGE pods uptime preserves |
| kubectl mutation | OUI | seulement kubectl get + kubectl exec env |
| restart pod | OUI | 0 restart cycle pendant audit |
| modifier manifest GitOps | OUI | keybuzz-infra non touche |
| modifier source applicative | OUI | keybuzz-api et keybuzz-client non touche |
| /ai/assist /ai/execute /autopilot/draft/consume | OUI | 0 dans logs |
| LLM | OUI | 0 |
| KBActions | OUI | 0 |
| mutation DB | OUI | BEGIN READ ONLY + ROLLBACK |
| message marketplace | OUI | 0 envoi |
| fake event/metric | OUI | 0 |
| secret/token/PII brut affiche dans rapport | OUI | emails non listes, mots de passe non repris |
| changement Linear statut | OUI | aucun ticket transitionne |

## Gaps restants / V2 ideas (NON engages)

1. V2 classifier multi-niveau : tenant-specific overrides (table tenant_no_reply_overrides) si certains tenants veulent reagir aux notifications Amazon (rare).
2. V2 ML-based classifier : si patterns regex deviennent insuffisants, considerer un mini-classifier ML (mais sur-engineering pour MVP).
3. V2 batch retro-tag : marquer historiquement messages.message_source='SYSTEM' pour notifications passees (migration optionnelle).
4. V2 Dashboard insight : "Notifications skippees ce mois : N (X KBActions economisees)" - metric positive pour valoriser fonctionnalite.
5. V2 atoz-guarantee exception : workflow specifique Litige A-Z avec template valide juridiquement plutot que skip total.

## Prochaine phrase GO attendue

Si decision produit necessaire avant patch (validation classifier seuils + UI design wording) :
**GO PRODUCT DECISION AI AUTOPILOT NO-REPLY NOTIFICATIONS KBACTIONS PH-SAAS-T8.12AS.20.12A**

Si decision produit deja prise et patch direct :
**GO SOURCE PATCH AI AUTOPILOT NO-REPLY NOTIFICATIONS KBACTIONS DEV PH-SAAS-T8.12AS.20.12B**

Si STOP necessaire :
- GO STOP READONLY AUDIT NO-REPLY DATA INSUFFICIENT (NON applicable : data PROD/DEV exploitable, 149 cas PROD 30j)
- GO STOP READONLY AUDIT NO-REPLY SCHEMA BLOCKER (NON applicable : schema messages + ai_action_log accessible read-only)
- GO STOP READONLY AUDIT NO-REPLY SAFETY BREACH (NON applicable : 0 mutation, 0 LLM, 0 KBA)

STOP.
