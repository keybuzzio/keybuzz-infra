# PH-SAAS-T8.12AS.20.46-QUATER-READONLY-VERIFY-AI-ASSIST-REAL-CLICKS-DEV-PROD-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.46-QUATER (READONLY VERIFY POST-CLICS REELS DEV+PROD)
> Environnement : DEV + PROD ; read-only strict (SELECT/logs/get) ; aucun POST/appel AI/fake/mutation

## 1. Verdict

GO READONLY VERIFY AI ASSIST REAL CLICKS DEV PROD READY PH-SAAS-T8.12AS.20.46-QUATER

DEV et PROD sont confirmes OK apres recharge du credit Anthropic. Des generations reelles
declenchees par les clics de Ludovic ont reussi dans les DEUX environnements, avec debit KBActions
normal et 0 nouvelle erreur "credit balance too low". La conversation PROD de la capture (SWITAA
SASU, commande 35212521252558-PROD) est confirmee en base avec un debit ai_generation a 23:21:58Z.
Aucun bug code, aucune regression. La cause bloquante provider credit est definitivement levee.

## 2. Synthese claire pour Ludovic

- DEV : le bouton "Generer une suggestion" remarche. 4 generations reelles reussies post-recharge
  (22:22:58Z puis 23:21-23:23), dont une sur une conversation buyer commande Amazon
  171-8133751 (contextualisee, NON skippee). 0 erreur credit sur les 2 dernieres heures.
- PROD : confirme aussi. 2 generations SWITAA reussies a 23:21:57Z et 23:22:50Z (+ une ecomlg a
  21:57Z), 0 erreur credit sur les 2 dernieres heures. La conversation de ta capture
  (cmmp5gdys..., commande 35212521252558-PROD) a bien debite 5.82 KBActions a 23:21:58Z.
- Le manque de credit Anthropic est resolu pour DEV ET PROD (compte partage, meme gateway
  llm.keybuzz.io).
- Aucun risque : phase 100% read-only, 0 mutation, PROD intacte (images inchangees, restarts=0).
- Prochain : decision produit sur la promotion PROD du patch classifier message-level (PH-20.47).

## 3. Runtime DEV / PROD

| env | service | namespace | image | imageID digest | ready | restarts |
|---|---|---|---|---|---:|---:|
| DEV | keybuzz-api | keybuzz-api-dev | v3.5.259-ai-assist-notification-scope-dev | sha256:e31ff645deed | true | 0 |
| DEV | keybuzz-client | keybuzz-client-dev | v3.5.259-ai-assist-notification-scope-dev | sha256:019dea6325fc | true | 0 |
| DEV | keybuzz-backend | keybuzz-backend-dev | v1.0.57-amazon-notification-classification-dev | sha256:ab583b9c57bb | true | 0 |
| PROD | keybuzz-api | keybuzz-api-prod | v3.5.257-autopilot-no-reply-kbactions-prod | sha256:52ec1bcf01de | true | 0 |
| PROD | keybuzz-client | keybuzz-client-prod | v3.5.217-clarity-client-restore-prod | sha256:e75ac3ad37ed | true | 0 |
| PROD | keybuzz-backend | keybuzz-backend-prod | v1.0.56-amazon-inbound-dedup-prod | sha256:9689875ca556 | true | 0 |

Aucun rollout/apply en cours (updated=available=desired sur tous les deployments cibles). PROD non
modifie. Infra repo keybuzz-infra HEAD=3c0876c, branch=main, ahead/behind=0/0, dirty=0 avant ce
rapport.

## 4. Fenetre post-clics

| fenetre | start UTC | end UTC | justification |
|---|---|---|---|
| BEFORE (echecs credit) | 2026-05-27T20:22:20Z | 2026-05-27T20:41:19Z | vague d'erreurs credit DEV+PROD (RCA PH-20.46-BIS) |
| AFTER (post-recharge) | 2026-05-27T20:41:19Z | 2026-05-27T23:27Z (now) | apres derniere erreur credit ; recharge + clics Ludovic DEV/PROD dans cette fenetre |

Derniere erreur credit DEV 20:40:29Z, PROD 20:41:19Z. Tous les clics observes ensuite sont des
succes. Fenetre d'observation = last 6h (couvre BEFORE et AFTER).

## 5. Generations reelles observees (post-recharge)

| env | timestamp | reqId | tenant | conv/order | result | provider error | KBActions |
|---|---|---|---|---|---|---|---:|
| DEV | 2026-05-27T22:22:58Z | req-mpomr2w9x9kkjz | switaa-sasu-mnc1x4eq | cmmp35jrjw... | suggestions:1 | none | debit 5.72 |
| DEV | 2026-05-27T23:21:14Z | req-mpoou2864trnie | switaa-sasu-mnc1x4eq | cmmphi008... | suggestions:1 | none | debit 6.54 |
| DEV | 2026-05-27T23:21:31Z | req-mpoouecos9rx57 | switaa-sasu-mnc1x4eq | cmmp2qrnaa... | suggestions:1 | none | debit 6.51 |
| DEV | 2026-05-27T23:23:07Z | req-mpoowianczours | switaa-sasu-mnc1x4eq | order 171-8133751 (buyer) | suggestions:1 | none | debit 8.81 |
| PROD | 2026-05-27T21:57:10Z | req-mpoltynaoywp4u | ecomlg-motxke32 | (suggestion) | success | none | debit 5.93 |
| PROD | 2026-05-27T23:21:57Z | req-mpoouzhpjxvlp8 | switaa-sasu-mnc1ouqu | cmmp5gdys... (capture) | suggestions:1 | none | debit 5.82 |
| PROD | 2026-05-27T23:22:50Z | req-mpoovzbvfngubl | switaa-sasu-mnc1ouqu | cmmp4bamgn... | suggestions:1 | none | debit 5.96 |

DEV credit errors AFTER = 0 (total 6h = 7, toutes <= 20:40:29Z). PROD credit errors AFTER = 0
(total 6h = 2, toutes <= 20:41:19Z ; last 2h = 0). La generation DEV sur order Amazon 171-8133751
prouve que le chemin buyer (contextualise) n'est PAS skippe et aboutit.

## 6. Conversation PROD capture

| env | conv | tenant | latest inbound | amazonIds | platformNotification | AI result | KBActions |
|---|---|---|---|---|---|---|---:|
| PROD | cmmp5gdys0903099c71d008ba | switaa-sasu-mnc1ouqu | "Ludovic | eComLG ludovic" (email PR0P264MB...) | null | non (email channel) | suggestions:1 @ 23:21:57Z | debit 5.82 @ 23:21:58Z |

Message buyer de la capture present en base : "Pourquoi je n'ai pas recu ma commande
35212521252558-PROD. Ou est-elle ?" (inbound). Le dernier inbound n'a pas de
metadata.amazonIds.messageId (canal email) -> le classifier classe author_name -> ce n'est pas un
handle de notification -> NON skippe -> generation effectuee. ai_actions_ledger confirme
reason=ai_generation kb_actions=5.820 created_at=2026-05-27T23:21:58.131Z pour cette conversation.

## 7. Provider / credits

| env | last credit error | credit errors after | success after | verdict |
|---|---|---:|---:|---|
| DEV | 2026-05-27T20:40:29Z | 0 | 4 | RESTAURE, prouve |
| PROD | 2026-05-27T20:41:19Z | 0 | 3 | RESTAURE, prouve |

Erreurs BEFORE = HTTP 400 Anthropic "Your credit balance is too low" via LiteLLM (model groups
kbz-premium + kbz-standard, fallback Anthropic None). Apres recharge : LiteLLM repond avec cost
normal (kbz-premium), 0 erreur credit. Aucun secret affiche. Aucune action provider/credit par CE.

## 8. KBActions / wallet

| env | tenant | conv | ai_generation debit | suggestion | verdict |
|---|---|---|---:|---|---|
| DEV | switaa-sasu-mnc1x4eq | order 171-8133751 | 8.81 | suggestions:1 | debit normal sur succes contextualise |
| PROD | switaa-sasu-mnc1ouqu | cmmp5gdys... | 5.82 | suggestions:1 | debit normal sur succes (capture) |
| DEV/PROD | - | echec credit BEFORE | 0 | - | aucun debit sur erreur provider |

Debit uniquement sur generation reussie ; 0 debit sur erreur credit ; 0 debit sur skip notification
(conforme PH-20.46-BIS). Aucune anomalie ledger. Lecture read-only stricte.

## 9. Classifier / skip notification

Le succes DEV sur order Amazon 171-8133751 (contextualise, late=true) et le succes PROD sur la
conversation capture (dernier inbound = message buyer, pas un handle notification) confirment que
le chemin buyer n'est PAS degrade. Aucun trafic de pure notification systeme observe dans la
fenetre AFTER a re-prouver le skip (comportement deja valide PH-20.46-BIS : notification skippee
message-level, 0 KBActions). Pas de regression classifier.

## 10. PROD bloque ou non

- DEV : service IA restaure et patch classifier PH-20.42-TER fonctionnellement valide (skip
  notification message-level ; buyer/order non skippes ; generations reussies). Rien ne bloque.
- PROD : runtime API/Client inchange (PROD n'a pas encore le patch classifier PH-20.42-TER) MAIS
  la capacite AI Assist PROD est confirmee OK post-recharge (2 succes SWITAA + ledger DB). La cause
  provider credit est levee pour les deux environnements.
- Promotion PROD du classifier message-level (PH-20.47) : plus AUCUN blocage technique residuel.
  Le code est pret et teste (15/15). La promotion releve d'une decision produit (build/push/apply
  PROD avec GO explicite de Ludovic).

## 11. Non-regression runtime

jobs-worker OUTBOUND_EMAIL_SEND DEV+PROD heartbeat claimed=0 (no job this poll), 0 erreur,
restarts=0. AMAZON_POLL worker-1 non sollicite. Outbound KEY-323 intact. Aucun deploy/mutation/
apply. PROD images inchangees. Tous pods ready, restarts=0. Phase 100% read-only.

## 12. Recommandations prochaines phases

1. PH-20.47 : decision produit + promotion PROD du classifier message-level PH-20.42-TER
   (build/push/apply API + Client PROD, GO explicite requis). Code pret/teste 15/15.
2. Hardening (phase separee) : alerting sur "credit balance too low" + fallback LiteLLM vers un
   provider disposant de credit, pour eviter un blocage total futur.
3. Optionnel : surveillance passive du solde credit du compte Anthropic / LiteLLM.

## 13. Phrase cible

GO READONLY VERIFY AI ASSIST REAL CLICKS DEV PROD READY PH-SAAS-T8.12AS.20.46-QUATER

STOP.
