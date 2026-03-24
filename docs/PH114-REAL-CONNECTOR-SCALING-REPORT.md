# PH114 — Real Connector Scaling Plan (Controlled Expansion)

> Date : 18 mars 2026
> Phase : PH114
> Environnement deploye : DEV
> Image : `v3.6.16-ph114-real-scaling-dev`
> Rollback : `v3.6.15-ph113-real-connector-dev`

---

## 1. Objectif

Etendre le perimetre d'execution reelle de PH113 (1 seule action) vers un ensemble multi-actions et multi-connecteurs controle, avec securite renforcee.

## 2. Actions activees (PH114)

| Action | Connecteur | Mode |
|---|---|---|
| `REQUEST_INFORMATION` | `customer_interaction_connector` | SAFE_EXPANDED |
| `PREPARE_CARRIER_INVESTIGATION` | `carrier_connector` | SAFE_EXPANDED |
| `PREPARE_RETURN` | `returns_connector` | SAFE_EXPANDED |
| `PREPARE_SUPPLIER_CASE` | `supplier_connector` | SAFE_EXPANDED |
| `MARK_CONVERSATION_RESOLVED` | `conversation_state_connector` | SAFE_EXPANDED |

## 3. Actions permanentement bloquees

- `REFUND` / `PREPARE_REFUND_REVIEW`
- `REPLACEMENT` / `PREPARE_REPLACEMENT`
- `ESCALATE_FRAUD`
- `ESCALATE_LEGAL`

Ces actions ne seront JAMAIS autorisees en execution reelle par ce moteur.

## 4. Nouveau mode d'execution

| Mode | Description | Phase |
|---|---|---|
| `DRY_RUN` | Simulation | Defaut |
| `REAL` | PH113 — 1 action | PH113 |
| `SAFE_EXPANDED` | PH114 — multi-actions | PH114 |

Le mode `SAFE_EXPANDED` est active uniquement si `PH114_EXPANDED_MODE=true`.

## 5. Variables d'environnement

| Variable | Valeur DEV | Valeur PROD | Description |
|---|---|---|---|
| `PH113_SAFE_MODE` | `false` (inactif) | `false` (inactif) | Gate PH113 |
| `AI_REAL_EXECUTION_ENABLED` | `false` (inactif) | `false` (inactif) | Gate globale |
| `PH114_EXPANDED_MODE` | `false` (inactif) | `false` (inactif) | Mode multi-actions PH114 |

Toutes les variables sont desactivees par defaut. Rien ne s'execute en reel.

## 6. Quotas

| Parametre | PH113 | PH114 |
|---|---|---|
| Max/heure | 5 | 10 |
| Max/jour | 20 | 50 |

Les quotas sont DB-backed via `ai_execution_attempt_log`.

## 7. Risk-aware execution (PH114)

PH114 bloque si :
- `fraudRisk >= MEDIUM`
- `abuseRisk >= MEDIUM`
- `buyerReputation` = `ABUSIVE` / `ABUSIVE_BUYER` / `HIGH` / `RISKY_BUYER`
- `customerTone` = `AGGRESSIVE` / `HOSTILE`

Plus restrictif que PH113 (qui ne bloquait qu'a `HIGH`/`CRITICAL`).

## 8. Connector Readiness Scoring

Nouvelle fonction `computeConnectorReadiness(action, connector, ctx)` :

```json
{
  "ready": true,
  "confidence": 0.9,
  "missingFields": [],
  "riskLevel": "LOW",
  "connector": "customer_interaction_connector",
  "action": "REQUEST_INFORMATION"
}
```

Champs requis par connecteur :
- `customer_interaction_connector` : `conversationId`
- `carrier_connector` : `orderId`, `trackingNumber`
- `returns_connector` : `orderId`
- `supplier_connector` : `orderId`
- `conversation_state_connector` : `conversationId`

## 9. Endpoints debug

| Endpoint | Description |
|---|---|
| `GET /ai/real-execution-status` | Statut PH113/PH114 (quotas, mode, actions) |
| `GET /ai/real-execution-plan` | Preview multi-actions (eligible, blocked, quotas) |
| `GET /ai/connector-readiness` | Score de readiness par connecteur |
| `GET /ai/safe-execution` | Execution safe pour une conversation |

## 10. Securite — 10 gates

| Gate | Description |
|---|---|
| 1 | `PH113_SAFE_MODE` env check |
| 2 | `AI_REAL_EXECUTION_ENABLED` env check |
| 3 | Action permanentement bloquee |
| 4 | Action dans la allowlist active |
| 5 | Governance non LOCKED/DEGRADED |
| 6 | Risk-aware check (fraud, abuse, tone) |
| 7 | Volume limits (heure + jour) |
| 8 | PH110 controlled execution check |
| 9 | PH111 activation check |
| 10 | Connector readiness check |

## 11. Verification DEV

```
/health                    → 200 OK
/ai/real-execution-status  → 200 (enabled=false, safeMode=false, expandedMode=false)
/ai/real-execution-plan    → 200 (11 actions evaluees, 0 eligible, 11 blocked)
/ai/connector-readiness    → 200 (readiness score)
/ai/safe-execution         → 200 (DRY_RUN — safe mode desactive)
/ai/governance             → 200 OK
/ai/controlled-execution   → 200 OK
/ai/controlled-activation  → 200 OK
/ai/action-dispatcher      → 200 OK
```

## 12. Tests

Fichier : `src/tests/ph114-tests.ts`

- 25 tests
- 75+ assertions
- Couvre : multi-actions, blocage permanent, risk-aware, quotas, readiness, prompt block

## 13. Integration pipeline

```
PH97 Multi-Order Context
PH101 Knowledge Graph
PH102 Long-Term Memory
PH104 Cross-Tenant Intelligence
PH103 Strategic Resolution
PH105 Autonomous Ops Plan
PH106 Action Dispatcher
PH107 Connector Abstraction
PH108 Case Manager
PH109 Case State Persistence
PH110 Controlled Execution
PH111 Controlled Activation
PH113/PH114 Safe Real Execution  ← etendu
PH100 Governance
LLM
PH98 Quality Scoring
PH99 Self Improvement
```

## 14. Non-regression

| Endpoint | Statut |
|---|---|
| `/health` | 200 PASS |
| `/ai/governance` | 200 PASS |
| `/ai/controlled-execution` | 200 PASS |
| `/ai/controlled-activation` | 200 PASS |
| `/ai/action-dispatcher` | 200 PASS |

## 15. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.15-ph113-real-connector-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```
