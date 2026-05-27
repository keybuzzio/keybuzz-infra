# PH-SAAS-T8.12AS.20.38-SOURCE-PATCH-AMAZON-NOTIFICATION-CLASSIFICATION-DEV-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.38 (SOURCE PATCH AMAZON NOTIFICATION CLASSIFICATION)
> Environnement : SOURCE DEV first - commits LOCAUX uniquement, aucun push/build/deploy/kubectl/DB

## 1. Verdict

GO SOURCE PATCH AMAZON NOTIFICATION CLASSIFICATION DEV PARTIAL PH-SAAS-T8.12AS.20.38

Patch source minimal applique + teste + commite EN LOCAL sur les deux repos concernes (keybuzz-backend ingestion, keybuzz-api generation de suggestions). Les deux objectifs fonctionnels du prompt sont atteints : (a) les notifications Amazon Seller Central donotreply n'arment plus de SLA et sont taguees en metadata a l'ingestion ; (b) la generation de brouillon IA (ai-assist) est skippee pour ces notifications (0 KBActions, 0 appel LLM), en miroir du skip Autopilot existant (PH-20.12B step 6.5). Verdict PARTIAL (et non READY) sur UN point produit volontairement DEFERE : le passage de message_source a une valeur SYSTEM. La whitelist runtime est ['HUMAN','AI_ASSISTED'] et la table product ne contient aujourd'hui que HUMAN/AI_ASSISTED/SUPPLIER_CONTACT/SUPPLIER_INBOUND (aucun SYSTEM, aucune contrainte CHECK) : introduire un nouvel enum message_source impacte le rendu Client (bulle de message) et les metriques categorisees par source, ce qui exige une phase Client-aware separee. Le marquage est donc fait via metadata (additif, sans risque enum), ce qui suffit au skip IA et a la suppression SLA. Aucun push, aucun build, aucune mutation DB. Repo backend dirty pre-existant compris (1 fichier .bak untracked) ; repo api dirty pre-existant compris (223 suppressions sous dist/, src propre).

## 2. Preflight (E0)

| Repo | Branche | HEAD avant | origin | dirty (avant) | verdict |
|---|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 38c048c0 | github.com/keybuzzio/keybuzz-api | 223 (TOUS dist/, src propre) | OK (artefacts build) |
| keybuzz-backend | main | 78bfb94 | (bastion) | 1 (amazon.routes.ts.bak untracked) | OK (bak pre-existant) |
| keybuzz-infra | main | 56a79db | (bastion) | 0 | OK |

Bastion install-v3 / 46.62.171.61, date 2026-05-27 ~15:13Z. PROD runtime inchange (read-only sur preflight).

## 3. Localisation classifier + usages (E1)

| Fichier | Fonction | Usage actuel | Gap (avant PH-20.38) |
|---|---|---|---|
| keybuzz-api src/services/noReplyClassifier.ts | classifyNoReplyPlatformNotification | classifier sender-driven (PH-20.12B) | gate UNIQUEMENT autopilot |
| keybuzz-api src/modules/autopilot/engine.ts:222 | step 6.5 skip | skip draft/LLM/KBActions autopilot | OK (deja branche) |
| keybuzz-api src/modules/ai/ai-assist-routes.ts:1058 | debitKBActions reason=ai_generation | brouillon IA manuel | PAS de gate no-reply -> KBActions gaspilles |
| keybuzz-backend src/modules/webhooks/inboxConversation.service.ts | createInboxConversation (INSERT conv+msg) | message_source=HUMAN, sla_due_at=now+24h INCONDITIONNEL | PAS de gate no-reply -> SLA arme + HUMAN |
| keybuzz-backend src/modules/webhooks/inboundDedup.ts | advisory lock amzmsg (PH-20.26) | dedup buyer-message | NE PAS TOUCHER (intact) |

Constat : le classifier n'existait que dans keybuzz-api ; l'ingestion reelle (metadata/message_source/SLA, advisory lock) est dans keybuzz-backend.

## 4. Patch ingestion (E2) - keybuzz-backend

Fichiers :
- NOUVEAU src/modules/webhooks/platformNotificationClassifier.ts : export classifyAmazonPlatformNotification (porte fidelement le set de regex sender-driven de keybuzz-api noReplyClassifier.ts PH-20.12B ; meme exclusion BUYER_HANDLE_RX @marketplace.amazon.).
- MODIF src/modules/webhooks/inboxConversation.service.ts :
  - import du classifier.
  - calcul platformNotif : SEULEMENT si !stableAmazonMessageKey (buyer-first : un message buyer porte metadata.amazonIds.messageId et n'est JAMAIS classe).
  - convSlaDueAt = platformNotif.isNotification ? null : slaDueAt -> SLA NON arme pour une NOUVELLE conversation de notification (les conversations existantes threadees ne sont pas touchees : pas d'INSERT conversation -> garde mixte automatique).
  - messageMetadata = { ...metadata, platformNotification:true, platformNotificationSubtype, platformNotificationClassifier } pour le message ; sinon metadata inchangee.
  - message_source : INCHANGE ('HUMAN') -> aucun changement enum (DEFERE).

| Comportement | Avant | Apres |
|---|---|---|
| Notification donotreply (sans amazonIds) -> SLA | sla_due_at = now+24h | null (non arme) si nouvelle conversation |
| Notification -> metadata | source=AMAZON only | + platformNotification/subtype/classifier |
| Message buyer (amazonIds.messageId) | HUMAN, SLA arme | INCHANGE (jamais classe, SLA arme) |
| Conversation mixte (notif threadee dans conv buyer) | SLA conv inchange | SLA conv inchange (pas d'INSERT) |

## 5. Patch generation suggestions (E3) - keybuzz-api

Fichier MODIF src/modules/ai/ai-assist-routes.ts :
- import classifyNoReplyPlatformNotification.
- apres loadConversationContext (contextType==='conversation'), classification sender-driven sur conversation.customer_name / customer_handle / subject / channel ; si isNoReply -> return early structure { status:'success', skipped:true, reason:'NO_REPLY_PLATFORM_NOTIFICATION', subtype, suggestions:[], explanations:[], kbActionsConsumed:0 } AVANT tout budget/LLM/debit.
- 0 appel LLM, 0 debit KBActions (le debit reason=ai_generation est en aval, jamais atteint).
- Miroir exact du skip Autopilot engine.ts step 6.5.
- Buyer-first : BUYER_HANDLE_RX dans le classifier + upgrade customer_handle vers l'alias buyer (PH63B) lorsqu'un buyer repond -> les conversations buyer actives ne sont PAS skippees.

## 6. Tests (E4)

| Test | Cas | Attendu | Resultat |
|---|---|---|---|
| platformNotificationClassifier.test.ts #1 | "Notifications Amazon Seller Central (Ne pas repondre) donotreply" | isNotification=true, AMAZON_SELLER_CENTRAL_NOTIFICATION | PASS |
| #2 | atoz-guarantee-no-reply | isNotification=true, AMAZON_ATOZ_NOREPLY | PASS |
| #3 | donotreply@amazon.fr (handle) | isNotification=true | PASS |
| #4 | author "Service donotreply" | isNotification=true, GENERIC | PASS |
| #5 | buyer alias @marketplace.amazon.fr | isNotification=false (buyer wins) | PASS |
| #6 | buyer handle @marketplace.amazon.de | isNotification=false | PASS |
| #7 | vrai client mentionnant Amazon en subject | isNotification=false (sender-driven) | PASS |
| #8 | input vide | isNotification=false | PASS |
| tsc --noEmit keybuzz-backend | typecheck repo | 0 erreur (0 sur fichiers touches) | PASS |
| tsc --noEmit keybuzz-api | typecheck repo | 0 erreur (0 sur fichiers touches) | PASS |

Test unitaire backend : 8/8 (node_modules/.bin/ts-node src/tests/platformNotificationClassifier.test.ts). Les cas IA buyer-wins / mixte sont couverts par la logique sender-driven + le garde stableAmazonMessageKey (buyer = jamais classe) ; tests d'integration runtime (DB/webhook) hors scope de cette phase source-only et a faire en validation DEV post-build.

## 7. Audit non-regression (E5)

| Verif | Etat |
|---|---|
| Hardcode tenant/token/order | AUCUN (utilise payload from/subject + conv.customer_*) |
| Secret affiche | AUCUN |
| Outbound reply (KEY-323) | INCHANGE |
| Guard validation inbound | INCHANGE |
| Dedup amzmsg / advisory lock (PH-20.26) | INCHANGE (inboundDedup.ts non touche, section verrou non modifiee) |
| Migration / CREATE INDEX / ALTER / DML | AUCUNE (metadata additif uniquement) |
| message_source enum | INCHANGE (HUMAN) -> 0 risque Client |
| Conversation entiere masquee | NON (classification niveau message ; SLA seulement sur NOUVELLE conv notif) |
| Suggestions IA pour vrais buyers | PRESERVE (sender-driven + BUYER_HANDLE_RX + PH63B) |

## 8. Commits locaux (E6) - AUCUN PUSH

| Repo | Commit | Contenu |
|---|---|---|
| keybuzz-backend | c38583a | + platformNotificationClassifier.ts, + tests/platformNotificationClassifier.test.ts, M inboxConversation.service.ts |
| keybuzz-api | 8f050f06 | M ai-assist-routes.ts |
| keybuzz-infra | (ce rapport, commit local docs-only) | docs/PH-SAAS-T8.12AS.20.38-... |

Aucun push. Aucun build image. Aucun docker push. Aucun kubectl. STOP au gate push.

## 9. Limites restantes

- message_source SYSTEM DEFERE : necessite handling Client (rendu bulle + metriques) avant introduction d'un nouvel enum ; metadata.platformNotification suffit aux gates actuels.
- Forward-looking : le tag metadata + SLA-null ne s'applique qu'aux NOUVELLES notifications post-deploy ; les conversations/SLA historiques ne sont pas modifies (pas de cleanup dans cette phase).
- Le skip ai-assist s'appuie sur le sender de la conversation (customer_name/handle) ; sur une conversation mixte dont le dernier message serait une notification mais dont le handle a ete upgrade vers le buyer, le skip ne s'applique pas (choix buyer-first volontaire : ne jamais risquer de bloquer un buyer).
- Validation runtime (build DEV from-git + smoke webhook + QA Inbox) a faire en phase suivante.

## 10. Texte Linear prepare (E8) - NON POSTE avant push

KEY-323 + KEY-337 (statuts inchanges) :
"PH-20.38 SOURCE PATCH classification notifications Amazon = PARTIAL (DEV, commits LOCAUX, pas de push). Branche le classifier existant aux 2 points manquants identifies en PH-20.37 : (1) ingestion keybuzz-backend inboxConversation.service.ts (nouveau platformNotificationClassifier.ts porte de PH-20.12B) -> notifications Seller Central donotreply (sans amazonIds) taguees metadata.platformNotification + SLA non arme pour une nouvelle conversation notif ; (2) keybuzz-api ai-assist-routes.ts -> skip generation brouillon IA (0 KBActions, 0 LLM) en miroir du skip Autopilot. Buyer-first garanti : jamais classe si amazonIds.messageId present + BUYER_HANDLE_RX + PH63B. message_source SYSTEM DEFERE (whitelist ['HUMAN','AI_ASSISTED'], risque enum Client) -> marquage via metadata seulement = PARTIAL. Tests 8/8 + tsc 0 erreur (2 repos). amzmsg/advisory lock + outbound + guard intacts. Commits keybuzz-backend c38583a, keybuzz-api 8f050f06. Aucun push/build/deploy/DB. Prochain : GO PUSH SOURCE PATCH AMAZON NOTIFICATION CLASSIFICATION DEV PH-20.38."

## 11. Phrase cible

GO SOURCE PATCH AMAZON NOTIFICATION CLASSIFICATION DEV PARTIAL PH-SAAS-T8.12AS.20.38

Prochaine phrase GO recommandee : GO PUSH SOURCE PATCH AMAZON NOTIFICATION CLASSIFICATION DEV PH-SAAS-T8.12AS.20.38

STOP.
