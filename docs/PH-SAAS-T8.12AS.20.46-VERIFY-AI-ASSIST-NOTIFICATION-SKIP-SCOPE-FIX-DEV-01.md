# PH-SAAS-T8.12AS.20.46-VERIFY-AI-ASSIST-NOTIFICATION-SKIP-SCOPE-FIX-DEV-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.46 (VERIFY FUNCTIONAL + READONLY RCA DEV)
> Environnement : DEV runtime ; read-only CE (SELECT/logs/get) ; aucun POST/appel AI/fake event

## 1. Verdict

GO VERIFY AI ASSIST NOTIFICATION SKIP SCOPE FIX DEV ACTION_REQUIRED PH-SAAS-T8.12AS.20.46

Le runtime DEV v3.5.259 (correctif message-level) est correctement deploye et les 2
conversations cibles sont pretes a la verification. MAIS aucune action UI AI Assist reelle
n'a ete effectuee sur ce runtime depuis son demarrage (api-dev pod startedAt 2026-05-27T20:02:58Z,
0 marqueur [AI Assist], 0 debit ledger sur les 2 convs cibles). Il est donc IMPOSSIBLE de
prouver au runtime, sur action utilisateur reelle, (a) la non-skip de la conversation mixte et
(b) le skip propre + UX neutre de la notification pure. L'interdit no-POST/no-fake empeche CE de
fabriquer ces clics. ACTION REQUISE : Ludovic clique "Generer une suggestion" sur les 2 convs
ci-dessous en DEV, puis on RELANCE ce verify. Cote environnement : credits LiteLLM/Anthropic DEV
epuises (confirme par une tentative Autopilot, ENV_CREDIT, hors classifier).

## 2. Runtime DEV / PROD

| service | namespace | image | imageID digest | restarts |
|---|---|---|---|---:|
| keybuzz-api | keybuzz-api-dev | v3.5.259-ai-assist-notification-scope-dev | sha256:e31ff645deed... | 0 |
| keybuzz-client | keybuzz-client-dev | v3.5.259-ai-assist-notification-scope-dev | sha256:019dea6325fc... | 0 |
| keybuzz-backend | keybuzz-backend-dev | v1.0.57-amazon-notification-classification-dev | sha256:ab583b9c57bb... | 0 |
| keybuzz-api | keybuzz-api-prod | v3.5.257-autopilot-no-reply-kbactions-prod | sha256:52ec1bcf01de... | 0 |
| keybuzz-client | keybuzz-client-prod | v3.5.217-clarity-client-restore-prod | sha256:e75ac3ad37ed... | 0 |
| keybuzz-backend | keybuzz-backend-prod | v1.0.56-amazon-inbound-dedup-prod | sha256:9689875ca556... | 0 |

runtime DEV = digests PH-20.44/45. PROD inchange.

## 3. Actions UI observees

Aucune action AI Assist utilisateur sur le runtime v3.5.259 : 0 marqueur [AI Assist] dans les
logs api-dev depuis startedAt 20:02:58Z ; 0 debit ledger (1h) sur les 2 conversations cibles.
Seule activite IA observee = generation Autopilot en arriere-plan (conv cmmopx7bdb7d1e19fa73be914,
tenant switaa-sasu, risk MEDIUM) -> [LiteLLM] Error 400 credit balance too low (Anthropic) :
c'est l'ENV_CREDIT, declenche par Autopilot, PAS par un clic AI Assist, PAS sur une conv cible.

## 4. Conversation mixte (cible, PRETE - non encore testee)

| conv | last inbound | amazonIds.messageId | attendu fix | observe |
|---|---|---|---|---|
| cmmo2np8qd96a7d0bcd151c8d | author=Maeva czf5ctf10jfg3sn+... (buyer) 2026-05-27T09:55Z | A00365023D73G5MXSHMM1 (PRESENT) | skip=FALSE (BUYER_AMAZON_IDS_PRESENT) | AUCUN CLIC -> non observe |

conversation customer_name = "Communications Amazon Seller Central (ne pas repondre) donotreply"
(handle notification) MAIS dernier message inbound = buyer reel avec amazonIds. C'est exactement
le cas CLASSIFIER_OVERMATCH de PH-20.42-BIS. Le helper message-level (teste 15/15, CASE2/CASE5)
predit skip=FALSE. Necessite un clic reel pour confirmation runtime.

## 5. Notification pure (cible, PRETE - non encore testee)

| conv | evidence notification | amazonIds | attendu fix | observe |
|---|---|---|---|---|
| cmmpml2o8g7049c9c95a6a4d1 | 3 derniers inbound author="Notifications Amazon Seller Central (Ne pas repondre) donotreply" | NULL (tous) | skip=TRUE NO_REPLY_PLATFORM_NOTIFICATION, 0 KBActions, UI neutre | AUCUN CLIC -> non observe |

Le dernier message inbound est bien la notification no-reply sans amazonIds (pas de buyer
posterieur). Le helper predit skip=TRUE (CASE1/CASE3). Necessite un clic reel.

## 6. KBActions / events

| signal | before | after | verdict |
|---|---:|---:|---|
| ai_suggestion_events | 2668 | 2668 | stable |
| ai_actions_ledger | 539 | 539 | stable sur la fenetre verify |
| ai_actions_ledger reason=ai_generation | 446 | 446 | stable sur la fenetre verify |
| debits ledger (1h) convs cibles cmmo2np8 + cmmpml2o8 | 0 | 0 | 0 (aucun clic) |

Note : le +1 ai_generation vs PH-20.45 (445->446) correspond a la generation Autopilot conv
cmmopx7b (20:22:20Z), pas a un clic AI Assist ni a un skip. Skip notification = 0 debit (non
encore exerce faute de clic). Aucun fake event/KBActions cree par CE.

## 7. LiteLLM credit / env

[LiteLLM] Error 400 "Your credit balance is too low to access the Anthropic API" (Model Group
kbz-premium, request_id req_011CbThN...) observe sur une generation AUTOPILOT en DEV. ENV_CREDIT
confirme et ACTIF en DEV, independant du classifier (corrige). A la verification UI, une
generation buyer reussie peut etre bloquee par ce credit : classer ENV_CREDIT, pas bug classifier.

## 8. No unintended processing

backend DB DEV (PH-20.45 baseline) inchange : Job OUTBOUND_EMAIL_SEND DONE13/FAILED16, OutboundEmail
SENT13/PENDING1/FAILED14, MOM2, AMAZON_POLL lockedBy worker-1=0, jobs-worker claimed=0. Aucun
job/skip declenche par CE. Phase 100% read-only (SELECT + kubectl logs/get).

## 9. PROD intact

api v3.5.257-prod, client v3.5.217-prod, backend v1.0.56-prod, restarts=0, aucun apply PROD,
aucun manifest PROD modifie.

## 10. Limites / decision

- ACTION REQUISE (sans fake/POST/replay) : Ludovic clique "Generer une suggestion" en DEV sur :
  (A) conversation mixte cmmo2np8qd96a7d0bcd151c8d -> attendu : PAS de skip ; si la generation
  echoue avec "credit balance too low" => ENV_CREDIT (classifier OK, le skip ne se declenche pas).
  (B) notification pure cmmpml2o8g7049c9c95a6a4d1 -> attendu : etat neutre "Notification
  systeme..." (pas erreur rouge), API skipped:true NO_REPLY_PLATFORM_NOTIFICATION, 0 KBActions.
  Puis RELANCER ce verify read-only.
- Decision promotion PROD : la phase BUILD/PUSH/APPLY PROD (PH-20.47) ne doit PAS demarrer tant
  que (A)+(B) ne sont pas prouves au runtime. Le classifier est corrige cote source/tests (15/15)
  et deploye DEV, mais la preuve fonctionnelle runtime manque. Les credits LiteLLM DEV sont un
  blocage d'ENVIRONNEMENT distinct : ils n'empechent PAS de prouver le SKIP (notification) ni la
  NON-SKIP (mixte) ; ils empechent seulement d'observer une generation buyer reussie en DEV.
- PROD reste bloque jusqu'a verify DEV concluant.

## 11. Phrase cible

GO VERIFY AI ASSIST NOTIFICATION SKIP SCOPE FIX DEV ACTION_REQUIRED PH-SAAS-T8.12AS.20.46

Prochaine etape : clics UI Ludovic (cmmo2np8 + cmmpml2o8) puis RELANCE verify read-only ; si
concluant -> GO BUILD AI ASSIST NOTIFICATION SKIP SCOPE FIX PROD PH-SAAS-T8.12AS.20.47.

STOP.
