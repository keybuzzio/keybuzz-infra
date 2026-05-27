# PH-SAAS-T8.12AS.20.46-BIS-READONLY-RCA-AI-ASSIST-INTERMITTENT-FAILURES-DEV-PROD-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.46-BIS (READONLY RCA AI ASSIST INTERMITTENT FAILURES DEV+PROD)
> Environnement : DEV + PROD ; read-only strict (SELECT/logs/get) ; aucun POST/appel AI/fake/mutation

## 1. Verdict

GO READONLY RCA AI ASSIST INTERMITTENT FAILURES DEV PROD PROVIDER_CREDIT PH-SAAS-T8.12AS.20.46-BIS

Cause principale UNIQUE et prouvee, DEV ET PROD : PROVIDER_CREDIT. Le gateway LiteLLM
(llm.keybuzz.io) renvoie 400 "Your credit balance is too low to access the Anthropic API"
(AnthropicException) pour les model groups kbz-premium ET kbz-standard ; le fallback (lui aussi
backe Anthropic) renvoie aussi 400 -> la generation echoue -> le Client affiche "Impossible de
generer une suggestion". C'est intermittent car certaines requetes passent (credit ponctuel /
cas sans LLM) et d'autres tapent le mur de credit Anthropic. Le patch classifier PH-20.42-TER
est VALIDE en DEV (notification skippee message-level 0 KBActions ; conversations buyer/order
NON skippees, generation tentee). Ce n'est NI un overmatch classifier, NI un bug Client, NI un
probleme KBActions/budget. PROD subit le meme manque de credit Anthropic (PROD n'a pas le patch
classifier mais ses echecs AI Assist observes sont aussi PROVIDER_CREDIT).

## 2. Synthese claire pour Ludovic

- Le bouton "Generer une suggestion" echoue quand le modele IA (Anthropic via LiteLLM) refuse
  l'appel : "credit balance too low". Plus de credits Anthropic = pas de generation.
- Ca touche DEV et PROD (meme gateway LiteLLM, meme compte Anthropic).
- Quand il reste un peu de credit, certaines generations passent : d'ou l'aspect aleatoire.
- Le correctif de classification (notifications vs vrais buyer) fonctionne : les notifications
  sont skippees sans consommer de KBActions, les vrais messages buyer (ex SWITAA commande) ne
  sont PAS skippes et tentent bien la generation.
- Action : recharger / corriger le credit Anthropic (Plans & Billing) cote LiteLLM. C'est une
  action de FACTURATION/ENVIRONNEMENT, hors code, hors cette phase.

## 3. Runtime DEV / PROD

| env | service | image | imageID digest | restarts |
|---|---|---|---|---:|
| DEV | keybuzz-api | v3.5.259-ai-assist-notification-scope-dev | sha256:e31ff645deed | 0 |
| DEV | keybuzz-client | v3.5.259-ai-assist-notification-scope-dev | sha256:019dea6325fc | 0 |
| DEV | keybuzz-backend | v1.0.57-amazon-notification-classification-dev | sha256:ab583b9c57bb | 0 |
| PROD | keybuzz-api | v3.5.257-autopilot-no-reply-kbactions-prod | sha256:52ec1bcf01de | 0 |
| PROD | keybuzz-client | v3.5.217-clarity-client-restore-prod | sha256:e75ac3ad37ed | 0 |
| PROD | keybuzz-backend | v1.0.56-amazon-inbound-dedup-prod | sha256:9689875ca556 | 0 |

Aucun rollout en cours (NewReplicaSetAvailable DEV+PROD). PROD non modifie.

## 4. Routes AI Assist cartographiees

| composant | route/contrat | constat |
|---|---|---|
| Client AISuggestionSlideOver | clic -> BFF /api/ai/assist -> keybuzz-api /ai/assist | DEV v3.5.259 gere skipped:true en etat neutre ; les vraies erreurs (LLM 400) -> "Impossible de generer" |
| keybuzz-api ai-assist-routes.ts | logs [AI Assist] reqId : Context loaded / KBActions available / Budget OK / skip NO_REPLY / LiteLLM failed | flux complet trace ; echec survient APRES "Budget OK", au call LiteLLM |
| LiteLLM gateway | llm.keybuzz.io, model groups kbz-premium + kbz-standard (Anthropic) + fallback | 400 credit balance too low ; fallback aussi 400 |

## 5. Conversations / requetes problematiques (logs reels, clics Ludovic)

Fenetre : pod api-dev depuis 20:02:58Z (97 clics [AI Assist] DEV), pod api-prod (24 clics PROD).

| env | reqId / tenant | flux | resultat |
|---|---|---|---|
| DEV | req-mpoj1whhykots7 / switaa-sasu | Context loaded Order TEST-ORD-R5 -> generation | SUCCESS suggestions:1 orderComplete:true |
| DEV | req-mpoj324ce4ia2r / switaa-sasu | Context loaded -> debit KBActions 5.47 (1737.25->1731.78) | SUCCESS suggestions:1 (debit normal) |
| DEV | req-mpoj2hufrn9g7v / switaa-sasu | Context loaded ; KBActions 1737.25 ; Budget OK | FAIL LiteLLM 400 credit -> fallback 400 |
| DEV | req-mpoj3dtrnazjeh / switaa-sasu | Context loaded ; Budget OK | FAIL LiteLLM 400 credit -> fallback 400 |
| DEV | req-mpoj11g0ehr1kb | notification Seller Central conv cmmo63h9... | skip NO_REPLY_PLATFORM_NOTIFICATION message-level (0 KBActions) CORRECT |
| DEV | req-mpoit54r273gy5 / req-mpoiyyky09zojq | Context loaded Order 402-2042655 / 171-8133751 (vrais buyer, NON skippes) | FAIL LiteLLM 400 credit (kbz-standard / kbz-premium) |
| PROD | req-mpoj48gmg3zh00 | Context loaded Order 171-8133751 | FAIL LiteLLM 400 credit kbz-premium -> fallback 400 |
| PROD | req-mpoj4geehdyed1 | Context loaded Order none | FAIL LiteLLM 400 credit -> fallback 400 |

Meme tenant (switaa-sasu), meme session : certains reqId SUCCESS, d'autres FAIL credit -> preuve
directe de l'intermittence = epuisement credit Anthropic, pas le classifier.

## 6. Table causes classees

| categorie | present ? | evidence | bloquant ? |
|---|---|---|---|
| A CLIENT_NO_REQUEST | NON | 97 [AI Assist] DEV / 24 PROD : les appels atteignent l'API | - |
| B CLIENT_BAD_RESPONSE_HANDLING | NON | Client affiche erreur SUR un vrai 400 LLM (correct) ; skip rendu neutre | - |
| C EXPECTED_NOTIFICATION_SKIP | OUI (OK) | req-mpoj11g0ehr1kb skip message-level 0 KBActions | non (correct) |
| D CLASSIFIER_OVERMATCH | NON (corrige) | buyer/order convs (402.., 171.., TEST-ORD) NON skippes, generation tentee | - |
| E PROVIDER_CREDIT | OUI (PRINCIPAL) | DEV 7 + PROD 2 "credit balance too low" Anthropic ; kbz-premium+kbz-standard ; fallback 400 | OUI (AI Assist) |
| F PROVIDER_ERROR | partiel | seules erreurs = 400 credit (pas 429/5xx/timeout distincts) | - |
| G KBACTIONS_BUDGET | NON | "KBActions available: 1737.25", "Budget OK", debit OK sur success | - |
| H CONTEXT_ERROR | NON | "Context loaded" systematique avant l'echec | - |
| I UNKNOWN_API_ERROR | NON | toutes les erreurs sont des 400 LiteLLM credit identifiees | - |

## 7. Auto-suggestion vs regeneration manuelle

| flow | route/service | resultat observe |
|---|---|---|
| AI Assist manuel | keybuzz-api /ai/assist -> LiteLLM | SUCCESS si credit dispo ; FAIL 400 credit sinon |
| Autopilot auto-suggest | autopilot/engine -> LiteLLM (meme gateway) | meme dependance credit (PH-20.46 : Autopilot conv cmmopx7b -> 400 credit) |

Un brouillon auto a pu etre genere quand il restait du credit ; une regeneration manuelle plus
tard echoue car le credit Anthropic est epuise. Meme provider, meme cause. Pas de divergence de
chemin expliquant un bug : c'est la disponibilite du credit qui varie dans le temps.

## 8. Provider / credits

| env | error type | count (pod) | model groups | provider |
|---|---|---:|---|---|
| DEV | credit balance too low (400) | 7 | kbz-premium (5), kbz-standard (2) | Anthropic via LiteLLM llm.keybuzz.io |
| PROD | credit balance too low (400) | 2 | kbz-premium (2) | Anthropic via LiteLLM llm.keybuzz.io |

Fallback model group egalement Anthropic -> "LiteLLM failed, using fallback" suivi d'un 400.
Aucune cle/secret affichee. Recharge credit = action billing hors scope (interdit cette phase).

## 9. KBActions / wallet

tenant switaa-sasu : KBActions available 1737.25, Budget OK source plan_budget, debit normal
5.47 sur generation reussie (remainingAfter 1731.78). Aucun rejet wallet/budget. KBActions NON
en cause. (lecture read-only, aucune mutation ledger.)

## 10. Client runtime endpoints

| env | client image | API base | skipped UX | note |
|---|---|---|---|---|
| DEV | v3.5.259-...scope-dev | api-dev.keybuzz.io | present (PH-20.42-TER) | skip notif rendu neutre |
| PROD | v3.5.217-clarity-...-prod | api.keybuzz.io | absent (pas encore PH-20.42-TER) | mais echecs PROD = provider credit, pas skip |

PROD n'a pas le patch skip message-level ; non pertinent ici car les echecs PROD observes sont
des 400 credit (generation buyer normale qui echoue faute de credit), pas des skips.

## 11. PROD bloque ou non

- Le patch classifier/Client PH-20.42-TER est fonctionnellement VALIDE en DEV (skip notif
  message-level OK ; buyer/order non skippes ; generations reussies quand credit dispo).
- BLOQUEUR RESIDUEL = PROVIDER_CREDIT (Anthropic), commun DEV+PROD, INDEPENDANT du code et
  anterieur/transverse aux patchs PH-20.38/42-TER. Tant que le credit Anthropic est epuise, AI
  Assist echoue par intermittence dans LES DEUX environnements, quel que soit le classifier.
- Decision : la promotion PROD du classifier (PH-20.47) n'est pas bloquee par un bug code ; mais
  elle n'apportera AUCUNE amelioration visible tant que le credit Anthropic n'est pas recharge.
  Recommandation : traiter d'abord le credit provider (P0 billing), puis decider la promotion.

## 12. AI feature parity / non-regression

jobs-worker OUTBOUND_EMAIL_SEND claimed=0 (heartbeat), AMAZON_POLL non sollicite, outbound
KEY-323 intact, aucun deploy/mutation, PROD images inchangees. Phase 100% read-only.

## 13. Recommandations prochaines phases

1. P0 ENV/BILLING (hors CE code) : recharger / corriger le credit Anthropic du compte LiteLLM
   (llm.keybuzz.io, model groups kbz-premium + kbz-standard + fallback). Action infra/billing.
2. Apres recharge : RELANCER PH-20.46 VERIFY DEV (mixte cmmo2np8 + notif cmmpml2o8) pour preuve
   de generation buyer reussie + skip notif neutre.
3. Optionnel hardening : configurer un fallback LiteLLM vers un provider/model group ayant du
   credit (OpenAI ou autre) pour eviter l'echec total quand Anthropic est a sec (phase separee).
4. PROD promotion classifier PH-20.47 : a decider apres P0 credit (le code est pret/teste).

## 14. Phrase cible

GO READONLY RCA AI ASSIST INTERMITTENT FAILURES DEV PROD PROVIDER_CREDIT PH-SAAS-T8.12AS.20.46-BIS

STOP.
