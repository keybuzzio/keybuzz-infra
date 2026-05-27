# PH-SAAS-T8.12AS.20.42-BIS-READONLY-RCA-AI-ASSIST-FAILURE-DEV-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.42-BIS (READONLY RCA AI ASSIST FAILURE DEV)
> Environnement : DEV runtime, RCA read-only ; aucun fake event/mutation/appel IA

## 1. Verdict

GO READONLY RCA AI ASSIST FAILURE DEV CLASSIFIER_OVERMATCH PH-SAAS-T8.12AS.20.42-BIS

Cause principale BLOQUANTE pour PROD : le skip AI Assist PH-20.38 (api ai-assist-routes.ts) est SENDER-driven au niveau CONVERSATION (classifyNoReplyPlatformNotification sur conversation.customer_name / customer_handle). Sur une conversation MIXTE dont le handle conversation est une notification Amazon Seller Central donotreply MAIS qui contient de vrais messages buyer porteurs d'amazonIds.messageId, le skip se declenche pour TOUTE la conversation et bloque a tort la generation AI Assist du vrai message buyer. Prouve en DEV sur conv cmmo2np8qd96a7d0bcd151c8d (handle=Communications Amazon Seller Central donotreply, + 4 messages buyer Maeva avec amazonIds A09978741.../A0539779.../A00365023...) : 6 POST /ai/assist -> skip NO_REPLY_PLATFORM_NOTIFICATION (0 KBActions). Mon hypothese PH-20.38 (PH63B upgrade customer_handle vers le buyer => conv mixte non skippee) NE TIENT PAS pour cette conversation (handle reste la notification). Deux constats additionnels distincts : (B) UX_GAP : meme reponse skip (status success, skipped:true, suggestions:[]) -> le Client affiche "Impossible de generer une suggestion" (erreur generique). (C) DEV LiteLLM credit exhaustion : la capture exacte de Ludovic (MUNKHSUU, order 408-5000914-4493909, conv cmmpnwaw7ifff57e98bf3f4fd) est un VRAI buyer correctement NON skippe, mais l'appel LiteLLM renvoie 400 "Your credit balance is too low to access the Anthropic API" -> fallback -> "Impossible de generer". (C) est un probleme d'environnement DEV (credits Anthropic), PAS le patch, et explique pourquoi PROD (avec credits) fonctionne sur ce buyer. Cout protege (0 KBActions sur le skip). Correction = API-side (skip au niveau MESSAGE et non conversation) + Client UX + recharge credits DEV. Aucune correction dans cette phase.

## 2. Runtime DEV / PROD (E0)

| service | namespace | image | imageID digest | ready | restarts |
|---|---|---|---|---:|---:|
| keybuzz-backend | keybuzz-backend-dev | v1.0.57-amazon-notification-classification-dev | sha256:ab583b9c57bb... | true | 0 |
| jobs-worker | keybuzz-backend-dev | v1.0.57-amazon-notification-classification-dev | sha256:ab583b9c57bb... | true | 0 |
| keybuzz-api | keybuzz-api-dev | v3.5.258-amazon-notification-classification-dev | sha256:732e307befa7... | true | 0 |
| keybuzz-backend | keybuzz-backend-prod | v1.0.56-amazon-inbound-dedup-prod | (inchange) | - | 0 |
| keybuzz-api | keybuzz-api-prod | v3.5.257-autopilot-no-reply-kbactions-prod | (inchange) | - | - |

Bastion install-v3 / 46.62.171.61, 2026-05-27 ~17:49Z. runtime DEV = manifest = last-applied (PH-20.41).

## 3. Logs API du clic (E1) - POST /ai/assist

| timestamp (approx) | conv | signal | resultat |
|---|---|---|---|
| ~16:24Z | cmmo2np8qd96a7d0bcd151c8d | POST /ai/assist x6 | skip NO_REPLY_PLATFORM_NOTIFICATION subtype=AMAZON_SELLER_CENTRAL_NOTIFICATION (0 KBActions) |
| ~16:24Z | cmmpnwaw7ifff57e98bf3f4fd (order 408-5000914-4493909) | POST /ai/assist (NON skip) | Context loaded -> Budget OK -> [LiteLLM] Error 400 "credit balance too low" -> fallback |

13 marqueurs [AI Assist] sur la fenetre ; 6 occurrences NO_REPLY_PLATFORM_NOTIFICATION (toutes sur cmmo2np8).

## 4. Metadata DB (E2) - conv cmmo2np8 = MIXTE

| element | valeur |
|---|---|
| conversation customer_name | Communications Amazon Seller Central (ne pas repondre) donotreply |
| conversation order_ref / created_at | 403-8526031-1289110 / 2026-04-17 (PRE-deploy) |
| msg 1 (2026-04-17) | source=AMAZON, amazonIds=NULL, platformNotification=null (ingere par v1.0.56 pre-patch), notification Seller Central |
| msg 2-5 (2026-05-21 / 05-27) | author Maeva ...@marketplace, source=AMAZON, amazonIds PRESENT (A09978741.../A0539779.../A00365023...) = VRAIS BUYER |
| message_source | HUMAN (tous) |

Conversation MIXTE : 1 notification + 4 buyer reels avec amazonIds. Le skip conv-level la bloque entierement -> OVERMATCH. (msg notif non tagge platformNotification car ingere avant le deploy ; sans incidence sur le skip qui est sender-driven, pas metadata-driven.)

Conv de la capture Ludovic : cmmpnwaw7ifff57e98bf3f4fd, customer_name=MUNKHSUU ny6ml7hv9vwx6b5+...@... (vrai buyer), order 408-5000914-4493909 -> NON skippe (correct) -> echec LiteLLM 400 (cause C).

## 5. KBActions / ai_suggestion_events (E4)

| signal (conv cmmo2np8) | valeur | verdict |
|---|---|---|
| ai_actions_ledger (debit) | 0 ligne | cout protege (skip = 0 KBActions) |
| ai_suggestion_events | 1 reply + 1 status (action=none) | track frontend du skip (pas de generation) |

Aucun debit KBActions sur le skip. Aucune generation IA spontanee.

## 6. Analyse Client / API contract (E6)

| composant | fichier | constat |
|---|---|---|
| API | keybuzz-api src/modules/ai/ai-assist-routes.ts (8f050f06, l.642-672) | skip classifie conversation.customer_name/customer_handle (CONV-LEVEL, SELECT l.182) ; renvoie status='success' 200 + skipped:true + suggestions:[] |
| Client | keybuzz-client src/features/ai-ui/AISuggestionSlideOver.tsx (HEAD dda6b45) | affiche "Impossible de generer une suggestion" sur suggestions vides ; ne gere pas skipped:true -> erreur generique (UX_GAP) |

Fix scope identifie : (1) API-only pour OVERMATCH = classifier au niveau MESSAGE (dernier message inbound / presence amazonIds) plutot que conversation.customer_name ; ne pas skip si la conversation/le message porte amazonIds buyer. (2) Client pour UX_GAP = rendre skipped:true proprement. (3) Env DEV pour cause C = recharger credits Anthropic/LiteLLM DEV.

## 7. AI Assist sur vrais messages (E5)

| conv | type | resultat | verdict |
|---|---|---|---|
| cmmpnwaw7 (MUNKHSUU, order 408) | vrai buyer (amazonIds) | NON skippe (classifier correct) ; LiteLLM 400 credit -> fallback | AI Assist buyer NON casse par le classifier, mais impraticable en DEV (credits) |
| cmmo2np8 buyer messages (Maeva) | vrai buyer dans conv mixte | skippe a tort (OVERMATCH) | BUG |

Pas d'echantillon DEV de generation AI Assist reussie (LiteLLM credits epuises) -> "AI Assist global non casse" NON prouvable en DEV ; mais le classifier n'est PAS la cause sur le buyer pur (cmmpnwaw7 non skippe). PROD fonctionne (credits OK).

## 8. Non-regression runtime (E7)

jobs-worker DEV : heartbeat claimed=0 types=OUTBOUND_EMAIL_SEND (no job this poll), scope intact. PROD intact (backend v1.0.56-prod, api v3.5.257-prod). amzmsg + outbound non touches. Aucun fake event/metric ; phase 100% read-only.

## 9. Cause (synthese)

- PRINCIPAL (bloquant PROD) : CLASSIFIER_OVERMATCH - skip AI Assist conv-level bloque les conversations mixtes contenant de vrais buyer messages (amazonIds). Bug PH-20.38 (api), a corriger avant promotion PROD.
- SECONDAIRE : UX_GAP - reponse skip rendue en erreur generique cote Client.
- TERTIAIRE (env, hors patch) : LiteLLM 400 credit Anthropic epuise en DEV -> AI Assist buyer impraticable en DEV ; explique la capture MUNKHSUU et le "PROD ok / DEV ko" sur buyer.

## 10. Rapport + recommandation phase suivante

Prochaine phase recommandee : GO SOURCE PATCH AI ASSIST NOTIFICATION SKIP SCOPE FIX DEV PH-SAAS-T8.12AS.20.42-TER :
- API : restreindre le skip au MESSAGE cible (skip seulement si le dernier message inbound est une notification no-reply SANS amazonIds ; ne jamais skip si amazonIds present ou si conversation contient un buyer message recent). Reutiliser stableAmazonMessageKey / metadata.amazonIds au niveau message.
- Client : gerer skipped:true (afficher "Notification systeme - pas de brouillon" au lieu d'une erreur).
- DEV env : recharger credits LiteLLM/Anthropic DEV (hors KEY-323, action infra) pour permettre une vraie validation AI Assist buyer en DEV.
- Puis re-build/push/apply/verify DEV avant toute promotion PROD.

## 11. Phrase cible

GO READONLY RCA AI ASSIST FAILURE DEV CLASSIFIER_OVERMATCH PH-SAAS-T8.12AS.20.42-BIS

STOP.
