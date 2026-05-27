# PH-SAAS-T8.12AS.20.46-TER-READONLY-VERIFY-AI-ASSIST-AFTER-LITELLM-CREDIT-RECHARGE-DEV-PROD-01

> Date : 2026-05-27
> Linear : KEY-323 primary ; KEY-337 parent PH-20
> Phase : PH-SAAS-T8.12AS.20.46-TER (READONLY VERIFY POST-RECHARGE LiteLLM/Anthropic)
> Environnement : DEV + PROD ; read-only strict (SELECT/logs/get) ; aucun POST/appel AI/fake/mutation

## 1. Verdict

GO READONLY VERIFY AI ASSIST AFTER LITELLM CREDIT RECHARGE DEV PROD PARTIAL PH-SAAS-T8.12AS.20.46-TER

DEV : credit Anthropic RESTAURE, prouve par une generation reelle reussie APRES la vague d'echecs
credit, avec debit KBActions normal et 0 nouvelle erreur credit. PROD : restauration NON
directement observable car aucun trafic AI Assist apres la derniere erreur credit ; le compte
Anthropic etant partage (meme gateway llm.keybuzz.io), la restauration est tres probable mais
demande UN clic PROD reel pour confirmation READY. Aucun bug code, aucune regression.

## 2. Synthese claire pour Ludovic

- DEV : le bouton "Generer une suggestion" REMARCHE. Derniere erreur credit a 20:40:29Z ; ensuite
  une vraie generation a 22:22:58Z a reussi (suggestion produite, KBActions debitees 5.72) sans
  aucune erreur credit. Le manque de credit Anthropic est donc resolu cote DEV.
- PROD : plus aucune erreur credit non plus, MAIS personne n'a reclique sur AI Assist en PROD
  depuis 20:41 : impossible de prouver formellement la reussite PROD sans une action reelle.
- Comme c'est le meme compte Anthropic pour DEV et PROD, la recharge profite aux deux ; il reste
  juste a faire UN essai PROD pour valider READY.
- Risque : nul (read-only, 0 mutation, PROD intacte).

## 3. Runtime DEV / PROD

| env | service | image | imageID digest | ready | restarts |
|---|---|---|---|---:|---:|
| DEV | keybuzz-api | v3.5.259-ai-assist-notification-scope-dev | sha256:e31ff645deed | 1 | 0 |
| DEV | keybuzz-client | v3.5.259-ai-assist-notification-scope-dev | (PH-20.45) | 1 | 0 |
| DEV | keybuzz-backend | v1.0.57-amazon-notification-classification-dev | sha256:ab583b9c57bb | 1 | 0 |
| PROD | keybuzz-api | v3.5.257-autopilot-no-reply-kbactions-prod | sha256:52ec1bcf01de | 1 | 0 |
| PROD | keybuzz-client | v3.5.217-clarity-client-restore-prod | (inchange) | 1 | 0 |
| PROD | keybuzz-backend | v1.0.56-amazon-inbound-dedup-prod | (inchange) | 1 | 0 |

api-dev pod startedAt 2026-05-27T20:02:58Z ; api-prod pod startedAt 2026-05-24T11:05:56Z. Aucun
apply/deploy en cours. PROD non modifie.

## 4. Fenetre post-recharge

| fenetre | start UTC | end UTC | justification |
|---|---|---|---|
| BEFORE (echecs credit) | 2026-05-27T20:29:57Z | 2026-05-27T20:41:19Z | vague d'erreurs credit DEV+PROD (RCA PH-20.46-BIS) |
| AFTER (post-recharge) | 2026-05-27T20:41:19Z | 2026-05-27T22:44Z (now) | apres derniere erreur credit ; recharge Ludovic dans cette fenetre |

Heure exacte de recharge non visible dans les logs ; bornee par "derniere erreur credit 20:41:19Z"
et "now 22:44Z". Le dernier evenement AI Assist DEV (22:22:58Z) est dans la fenetre AFTER.

## 5. Provider / credits

| env | type | count fenetre AFTER | dernier credit-error | evidence |
|---|---|---:|---|---|
| DEV | credit balance too low | 0 (last 2h) | 2026-05-27T20:40:29Z | aucune erreur credit apres 20:40:29 ; success 22:22:58 sans erreur |
| DEV | LiteLLM failed (fallback) | 0 (last 2h) | 20:40:29Z | - |
| PROD | credit balance too low | 0 (last 2h) | 2026-05-27T20:41:19Z | aucune erreur credit apres 20:41:19 ; mais 0 trafic AI Assist apres |
| PROD | LiteLLM failed (fallback) | 0 (last 2h) | 20:41:19Z | - |

DEV : transition claire echec->succes. PROD : plus d'erreur mais plus de trafic non plus.

## 6. Generations reelles observees (post-recharge)

| env | reqId / ledger | tenant | conv | model/result | KBActions | verdict |
|---|---|---|---|---|---:|---|
| DEV | req-mpomr2w9x9kkjz @ 22:22:58Z | switaa-sasu | cmmp35jrjw... | suggestions:1 (LLM OK) | debit ai_generation 5.72 | SUCCESS post-recharge |
| PROD | (aucun apres 20:41:19Z) | - | - | - | - | NO_TRAFFIC apres recharge |

DEV ai_suggestion_events total 2708 (last 22:23:01Z) ; le succes 22:22:58 a bien cree un event +
debite KBActions normalement. Aucune generation PROD post-recharge a observer.

## 7. KBActions / wallet

| env | signal | valeur | verdict |
|---|---|---|---|
| DEV | ai_generation debit 22:22:58 | kb=5.72 conv cmmp35jrjw | debit normal sur succes |
| DEV | debit sur echec credit | 0 | aucun debit quand LiteLLM 400 |
| DEV | debit sur skip notification | 0 | conforme (PH-20.46-BIS) |

Debit uniquement sur generation reussie. Aucune anomalie wallet/ledger. Lecture read-only.

## 8. Classifier / skip notification

Aucun nouveau trafic notification post-recharge a observer dans la fenetre AFTER -> SKIP_NOT_OBSERVED
pour cette phase. Le comportement classifier reste celui valide en PH-20.46-BIS (notification
skippee message-level 0 KBActions ; buyer/order non skippes). Le succes DEV 22:22:58 (tenant
switaa, generation aboutie) confirme que le chemin buyer n'est pas degrade par le patch.

## 9. DEV vs PROD

| env | AI Assist success AFTER | credit errors AFTER | conclusion |
|---|---:|---:|---|
| DEV | 1 (22:22:58Z, debit 5.72) | 0 | credit RESTAURE, prouve |
| PROD | 0 (pas de trafic) | 0 | restauration probable (compte Anthropic partage) mais NON observee |

## 10. PROD bloque ou non

- DEV : service IA restaure, patch classifier PH-20.42-TER valide (PH-20.46-BIS) + generation
  reelle reussie ici. Cote DEV, rien ne bloque.
- PROD : runtime inchange (pas encore le patch classifier PH-20.42-TER). La cause provider credit
  est resolue au niveau du compte Anthropic partage, mais aucune generation PROD post-recharge
  n'a ete observee pour le confirmer formellement.
- Decision promotion PROD du classifier (PH-20.47) : la cause bloquante provider credit est levee ;
  il reste a (a) confirmer une generation PROD reelle reussie (1 clic), puis (b) decider la
  promotion du classifier message-level. Le code classifier est pret et teste (15/15) ; la
  promotion releve d'une decision produit, pas d'un blocage technique residuel.

## 11. Non-regression runtime

jobs-worker OUTBOUND_EMAIL_SEND claimed=0 (heartbeat), AMAZON_POLL worker-1 non sollicite,
outbound KEY-323 intact, aucun deploy/mutation, PROD images inchangees, restarts=0. infra clean
(HEAD=origin b141949 avant ce rapport). Phase 100% read-only.

## 12. Recommandations prochaines phases

1. PROD : un (1) clic AI Assist reel sur une conversation buyer PROD pour confirmer la generation
   reussie post-recharge -> upgrade PARTIAL vers READY.
2. Decision produit : promotion PROD du classifier message-level PH-20.42-TER (PH-20.47) - code
   pret/teste ; a planifier (build/push/apply PROD avec GO explicite).
3. Hardening (phase separee) : alerting sur "credit balance too low" + fallback LiteLLM vers un
   provider disposant de credit, pour eviter un blocage total futur.

## 13. Phrase cible

GO READONLY VERIFY AI ASSIST AFTER LITELLM CREDIT RECHARGE DEV PROD PARTIAL PH-SAAS-T8.12AS.20.46-TER

STOP.
