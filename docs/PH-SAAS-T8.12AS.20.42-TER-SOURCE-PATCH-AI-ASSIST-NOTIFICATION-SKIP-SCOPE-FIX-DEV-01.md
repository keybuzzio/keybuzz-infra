# PH-SAAS-T8.12AS.20.42-TER-SOURCE-PATCH-AI-ASSIST-NOTIFICATION-SKIP-SCOPE-FIX-DEV-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.42-TER (SOURCE PATCH AI ASSIST NOTIFICATION SKIP SCOPE FIX DEV)
> Environnement : SOURCE DEV-first ; commits locaux uniquement ; aucun build/push/deploy/kubectl/DB

## 1. Verdict

GO SOURCE PATCH AI ASSIST NOTIFICATION SKIP SCOPE FIX DEV READY PH-SAAS-T8.12AS.20.42-TER

Le bug PH-20.42-BIS (CLASSIFIER_OVERMATCH) est corrige a la source. Le skip AI Assist
ne se base plus sur le sender de conversation (conversation.customer_name /
customer_handle) mais sur le DERNIER message inbound de la conversation, et un message
buyer porteur d'amazonIds.messageId n'est JAMAIS skippe. Patch API + Client, tests verts,
3 commits locaux (api, client, infra). Aucun build, aucun push, aucun deploy, aucun
kubectl, aucune mutation DB. PROD intacte. PH-20.43 (promotion PROD) reste bloque tant que
ce patch n'est pas build/push/apply/verify en DEV.

## 2. Bug RCA (rappel PH-20.42-BIS)

- CLASSIFIER_OVERMATCH : ai-assist-routes.ts (commit 8f050f06, PH-20.38) appelait
  classifyNoReplyPlatformNotification avec authorName=conversation.customer_name (niveau
  CONVERSATION). Sur une conversation MIXTE dont le customer_name/handle est une
  notification Amazon Seller Central donotreply mais qui contient de vrais messages buyer
  porteurs d'amazonIds.messageId, le skip se declenchait pour TOUTE la conversation.
- Preuve DEV : conv cmmo2np8qd96a7d0bcd151c8d (handle notif + 4 messages buyer Maeva avec
  amazonIds) -> 6 POST /ai/assist -> skip NO_REPLY_PLATFORM_NOTIFICATION (0 KBActions),
  comportement fonctionnel faux.
- UX_GAP : la reponse skip (status:success, skipped:true, suggestions:[]) n'etait pas
  geree par le Client (AISuggestionSlideOver.tsx) ; status success + suggestions vides
  retombait silencieusement sur le CTA "Generer une suggestion".

## 3. Fichiers modifies

| repo | fichier | changement | risque |
|---|---|---|---|
| keybuzz-api | src/services/noReplyClassifier.ts | +helper pur determineAiAssistNotificationSkip (+types). classifier existant INCHANGE | faible (ajout pur, type-checke) |
| keybuzz-api | src/modules/ai/ai-assist-routes.ts | skip MESSAGE-LEVEL : charge le dernier message inbound (author_name + metadata.amazonIds.messageId) et appelle le helper ; import swap | faible (meme reponse skip, SELECT read-only borne LIMIT 1) |
| keybuzz-api | __tests__/determineAiAssistNotificationSkip.test.ts | nouveau test pur (hors build, rootDir=src) | nul (test) |
| keybuzz-client | src/services/ai.service.ts | AIAssistResponse : +skipped/reason/subtype | nul (champs optionnels) |
| keybuzz-client | src/features/ai-ui/AISuggestionSlideOver.tsx | gere skipped:true en etat neutre, exclut skipped du CTA pre-generation | faible (UI) |

Backend (keybuzz-backend) NON touche (HEAD c38583a inchange). Autopilot engine.ts
NON touche. tenantGuard / outbound NON touches.

## 4. Design API (message-level)

Helper pur determineAiAssistNotificationSkip(input) :
- input.lastInbound = null -> skip=false, reason=NO_INBOUND_MESSAGE (pas de message a traiter).
- lastInbound.amazonMessageId non vide -> skip=false, reason=BUYER_AMAZON_IDS_PRESENT
  (garde dure buyer : un vrai message Amazon buyer porte amazonIds.messageId).
- sinon classifyNoReplyPlatformNotification sur l'AUTHOR du dernier message inbound
  (authorName=lastInbound.authorName), handle/subject de conversation en signal d'appoint :
  - isNoReply -> skip=true, reason=NO_REPLY_PLATFORM_NOTIFICATION, subtype conserve.
  - sinon -> skip=false, reason=CUSTOMER_OR_AMBIGUOUS.

Route ai-assist-routes.ts : avant le skip, SELECT author_name, metadata FROM messages WHERE
conversation_id=$1 AND direction='inbound' ORDER BY created_at DESC LIMIT 1 ; parse metadata
(string|jsonb) -> amazonIds.messageId ; passe le tout au helper. Si skip -> meme reponse
qu'avant (status:success, skipped:true, suggestions:[], kbActionsConsumed:0, disclaimer).
Aucun appel debitKBActions / LLM sur le chemin skip (0 KBActions preserve). Mirror exact de
la doctrine Autopilot step 6.5 (qui se base deja sur last_message_author_name) + garde
amazonIds que l'Autopilot n'avait pas. Lookup DB encapsule en try/catch non-bloquant.

## 5. Design Client (skipped neutre)

- ai.service.ts : AIAssistResponse expose skipped/reason/subtype (optionnels).
- AISuggestionSlideOver.tsx :
  - nouvel etat skipped (string|null), reset en debut de generateSuggestion.
  - handler : if (status==='success' && skipped) -> setSkipped(disclaimer ou
    "Notification systeme : aucun brouillon IA necessaire.") AVANT de traiter le succes
    normal. Les autres branches (success normal, actions_exhausted, erreur) inchangees.
  - rendu : bloc neutre (bleu, icone ShieldCheck) quand skipped ; le CTA pre-generation est
    exclu si skipped. Aucune erreur affichee, pas de retry agressif.
  - les vraies erreurs API/LLM conservent le bloc erreur rouge + bouton Reessayer.

## 6. Tests

| test | outil | resultat |
|---|---|---|
| API helper determineAiAssistNotificationSkip | tsc standalone (5.9.3) + node, 8 cas / 15 assertions | 15 passed, 0 failed |
| API projet complet | ./node_modules/.bin/tsc --noEmit | EXIT=0 |
| Client (mes fichiers) | tsc --noEmit (.next stale exclu) | EXIT=0 |

Cas couverts (obligatoires) : (1) pure notification no-reply sans amazonIds -> skip true ;
(2) mixte dernier inbound buyer avec amazonIds -> skip false ; (3) mixte dernier inbound
notification sans amazonIds -> skip true ; (4) buyer mentionnant Amazon, sender non
no-reply -> skip false ; (5) amazonIds present -> skip false ; (6) pas de message inbound
-> skip false ; (7) idempotence/purete (0 effet de bord, 0 KBActions cote helper) ; edge
amazonMessageId blanc -> traite comme absent. Toolchain : keybuzz-api n'a pas de framework
de test (jest/ts-node/tsx absents) ; test execute par compilation standalone tsc + node.

## 7. No side-effect / non-regression source

- Aucun build, aucun docker push, aucun deploy, aucun kubectl, aucune mutation DB.
- Aucun fake event / KBActions / ai_suggestion_events / ledger / webhook / replay.
- Aucun hardcode tenant/user/email/seller/order/tracking ; aucun secret.
- Aucun message_source=SYSTEM introduit (le texte UI "Notification systeme" est une chaine
  d'affichage francaise, pas l'enum DB).
- classifyNoReplyPlatformNotification (patterns existants) INCHANGE, non elargi.
- Backend ingestion metadata.platformNotification + advisory lock amzmsg : NON touches.
- Outbound KEY-323 / jobs-worker OUTBOUND_EMAIL_SEND : NON touches.
- tenantGuard validation : NON touche.
- AI feature parity : AI Assist reste possible pour les vrais buyer (amazonIds ou author
  non-notification) ; pure notification no-reply skippee (0 LLM / 0 KBActions) ; parite avec
  l'Autopilot step 6.5 preservee.

## 8. Commits locaux (aucun push)

| repo | branche | HEAD avant | HEAD apres (local) | fichiers |
|---|---|---|---|---|
| keybuzz-api | ph147.4/source-of-truth | 8f050f06 | 15f0e5e5 | ai-assist-routes.ts, noReplyClassifier.ts, __tests__/...test.ts |
| keybuzz-client | ph148/onboarding-activation-replay | dda6b45 | ad4e862 | ai.service.ts, AISuggestionSlideOver.tsx |
| keybuzz-infra | main | f55f389 | (ce rapport) | docs/PH-...-20.42-TER-...md |

Messages : api = "fix(ai): scope no-reply assist skip to target inbound message
(PH-20.42-TER, KEY-323)" ; client = "fix(ai): render notification skip without suggestion
error (PH-20.42-TER, KEY-323)". Dirty residuel attendu : api dist/ (pre-existant, non
stage) ; client tsconfig.tsbuildinfo (cache build, non stage).

## 9. Limites

- LiteLLM/Anthropic credit DEV (cause C de PH-20.42-BIS) NON traite ici (hors scope, action
  infra) : la validation AI Assist buyer reelle en DEV reste impraticable tant que les
  credits ne sont pas recharges.
- Build / push / apply DEV a faire APRES push (phase suivante). Validation runtime a refaire
  (tag + SLA-null + skip message-level sur trafic reel, parite buyer).
- Patch non encore actif au runtime : runtime DEV reste api v3.5.258 / backend v1.0.57.

## 10. Linear (prepare, NON poste avant push)

Texte prevu KEY-323 + KEY-337 (apres push, statut inchange) :
"PH-20.42-TER SOURCE PATCH AI Assist no-reply skip scope fix = READY (commits locaux,
aucun build/push/deploy). Fix CLASSIFIER_OVERMATCH : le skip se base desormais sur le
DERNIER message inbound (author + amazonIds.messageId) et non sur conversation.customer_name ;
un message porteur d'amazonIds.messageId n'est jamais skippe (conversations mixtes
eligibles). Client : reponse skip rendue en etat neutre, plus en erreur. Helper pur
determineAiAssistNotificationSkip + test 15/15 ; tsc api+client clean. Commits : api 15f0e5e5
(ph147.4/source-of-truth), client ad4e862 (ph148/onboarding-activation-replay). Aucune
mutation DB / fake event / KBActions. Backend/outbound/guard/autopilot intacts. PROD intacte.
Prochain : GO PUSH ... PH-20.42-TER puis build/push/apply/verify DEV. PH-20.43 PROD reste
bloque. Statut inchange."

## 11. Phrase cible

GO SOURCE PATCH AI ASSIST NOTIFICATION SKIP SCOPE FIX DEV READY PH-SAAS-T8.12AS.20.42-TER

Prochain GO recommande : GO PUSH SOURCE PATCH AI ASSIST NOTIFICATION SKIP SCOPE FIX DEV
PH-SAAS-T8.12AS.20.42-TER (push api 15f0e5e5 + client ad4e862 + ce rapport infra), puis
build API DEV v3.5.259 + build Client DEV, push images, apply DEV, verify runtime.
PROD PH-20.43 reste bloque jusqu'a validation DEV complete.

STOP.
