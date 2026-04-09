# PH142-D — AI Auto-Escalation on Action

> Date : 2026-04-03
> Statut : DEV + PROD deployes

---

## Objectif

Transformer la detection `needsHumanAction` (PH142-C) en action reelle : escalade automatique de la conversation vers un agent humain quand l'IA genere une fausse promesse.

## Architecture

```
LLM genere suggestion
    |
detectFalsePromises() → needsHumanAction = true  (PH142-C)
    |
UPDATE conversations SET escalation_status = 'escalated'  (PH142-D)
    |
INSERT ai_action_log AI_AUTO_ESCALATED  (PH142-D)
    |
InboxTripane → EscalationBadge visible  (existant PH123)
```

## Changements

### API (`keybuzz-api`)

**`src/modules/ai/ai-assist-routes.ts`** :
- Bloc post-detection (apres PH142-C, avant PH31 debit) :
  - Si `needsHumanAction && effectiveConversationId` :
    - UPDATE `conversations` :
      - `escalation_status = 'escalated'`
      - `escalation_reason` = patterns detectes
      - `escalated_by_type = 'ai_auto'`
      - `escalation_target = 'human_agent'`
    - Garde d'idempotence : `WHERE escalation_status IS NULL OR escalation_status != 'escalated'`
    - INSERT `ai_action_log` avec `action_type = 'AI_AUTO_ESCALATED'`
  - Fire-and-forget (non-bloquant)

### Client

**Aucune modification client necessaire.** L'infrastructure existante (PH123) gere deja :
- `EscalationBadge` dans la liste de conversations
- Tri prioritaire (conversations escaladees en haut)
- `EscalationPanel` dans le detail conversation
- Filtre "pickup" pour conversations escaladees non assignees

## Tests DEV

```
Escalation sur conversation reelle:     ESCALATED (escalation_status=escalated, escalated_by_type=ai_auto)
Verification post-escalade:             escalation_target=human_agent, reason=promesse action
Idempotence (re-escalade):              PASS (sautee)
Log AI_AUTO_ESCALATED:                  OK (enregistre correctement)
Build verification:                     PH142-D code PRESENT, human_agent PRESENT, idempotency guard PRESENT
Non-regression health:                  OK
Non-regression journal:                 OK (1298 events)
Non-regression clusters (PH142-B):      OK (1 categorie, 1 flag)
```

## Images deployees

| Service | DEV | PROD |
|---------|-----|------|
| API     | `v3.5.186-ai-auto-escalation-dev` | `v3.5.186-ai-auto-escalation-prod` |
| Client  | `v3.5.185-ai-action-consistency-dev` (inchange) | `v3.5.185-ai-action-consistency-prod` (inchange) |

Note : seule l'API est modifiee dans cette phase. Le client utilise l'infrastructure PH123 existante.

## Non-regression

- PH142-A (quality loop) : intact
- PH142-B (error clustering) : intact
- PH142-C (action consistency) : intact
- Journal IA : fonctionnel
- Billing : non touche
- Autopilot : non touche

## Health checks PROD

```
API  : https://api.keybuzz.io/health  -> 200 OK
Pod  : keybuzz-api 1/1 Running
```

## Rollback DEV

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.185-ai-action-consistency-dev -n keybuzz-api-dev
```

## Rollback PROD

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.185-ai-action-consistency-prod -n keybuzz-api-prod
```
