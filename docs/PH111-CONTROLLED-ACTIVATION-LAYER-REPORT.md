# PH111 — Controlled Activation Layer

> Date : 2026-03-17
> Environnement : DEV deployé, PROD en attente
> Image : `v3.6.13-ph111-controlled-activation-dev`
> Rollback : `v3.6.12-ph110-controlled-execution-dev`

---

## 1. Objectif

PH111 introduit la couche de pilotage des activations IA. Elle permet de gérer de façon fine quels tenants, connecteurs et actions peuvent sortir du dry-run, avec quel mode d'activation et à quel stade de rollout.

---

## 2. Architecture

### Service
- `src/services/controlledActivationEngine.ts`

### Table créée (auto CREATE IF NOT EXISTS)

#### `ai_activation_policy`

| Colonne | Type | Description |
|---|---|---|
| id | UUID PK | Identifiant |
| tenant_id | TEXT | Tenant |
| connector_name | TEXT | Connecteur |
| action_name | TEXT | Action |
| activation_mode | TEXT | DISABLED / DRY_RUN_ONLY / SIMULATED_READY / REAL_ALLOWED / REAL_WITH_HUMAN_REVIEW |
| is_enabled | BOOLEAN | Policy active |
| rollout_stage | TEXT | NONE / INTERNAL_TEST / LIMITED_TENANT / LIMITED_ACTIONS / CONTROLLED_REAL / FULLY_ENABLED |
| notes | TEXT | Notes libres |

UNIQUE (tenant_id, connector_name, action_name)

---

## 3. Modes d'activation

| Mode | Description |
|---|---|
| DISABLED | Désactivé |
| DRY_RUN_ONLY | Simulation uniquement |
| SIMULATED_READY | Prêt pour activation future |
| REAL_ALLOWED | Exécution réelle autorisée |
| REAL_WITH_HUMAN_REVIEW | Requiert review humaine |

---

## 4. Stades de rollout

| Stade | Description |
|---|---|
| NONE | Pas de rollout |
| INTERNAL_TEST | Test interne |
| LIMITED_TENANT | Tenant limité |
| LIMITED_ACTIONS | Actions limitées |
| CONTROLLED_REAL | Exécution contrôlée |
| FULLY_ENABLED | Pleinement activé |

---

## 5. Logique d'éligibilité

Cascade de vérification :

1. Action exclue en permanence (ESCALATE_LEGAL, ESCALATE_FRAUD, PREPARE_REFUND_REVIEW) → DISABLED
2. Pas de policy → DRY_RUN_ONLY
3. Policy désactivée → DISABLED
4. Policy mode = DISABLED → DISABLED
5. PH110 BLOCKED → DRY_RUN_ONLY (ne peut pas promouvoir)
6. Governance LOCKED/DEGRADED → DRY_RUN_ONLY
7. Governance RESTRICTED + REAL_ALLOWED → downgrade REAL_WITH_HUMAN_REVIEW
8. DRY_RUN_ONLY / SIMULATED_READY → mode tel quel
9. REAL_WITH_HUMAN_REVIEW / REAL_ALLOWED → activation effective

---

## 6. Phases d'activation prévues

| Phase | Actions |
|---|---|
| Phase 1 | REQUEST_INFORMATION, NOTIFY_CUSTOMER, MARK_CASE_RESOLVED |
| Phase 2 | OPEN_CARRIER_INVESTIGATION, OPEN_SUPPLIER_CASE, PREPARE_RETURN |
| Phase 3 | PREPARE_REPLACEMENT |
| Toujours exclu | ESCALATE_LEGAL, ESCALATE_FRAUD, PREPARE_REFUND_REVIEW |

---

## 7. Position pipeline

```
PH109 Case State Persistence
PH110 Controlled Real Execution
PH111 Controlled Activation Layer  ← NOUVEAU
PH100 Governance
LLM
PH98 Quality Scoring
PH99 Self Improvement
```

---

## 8. Endpoints debug

| Route | Description |
|---|---|
| `GET /ai/controlled-activation` | État d'activation tenant |
| `GET /ai/controlled-activation/policies` | Policies complètes |
| `GET /ai/controlled-activation/matrix` | Matrice action × connecteur × mode × éligibilité |

---

## 9. decisionContext

```json
{
  "controlledActivation": {
    "tenantId": "ecomlg-001",
    "rolloutStage": "NONE",
    "enabledActions": 0,
    "eligibleActions": []
  }
}
```

---

## 10. Tests

22 tests, 70+ assertions, 100% PASS.

Cas couverts :
- No policy → DRY_RUN_ONLY
- Policy disabled → DISABLED
- REAL_ALLOWED + PH110 eligible → REAL_ALLOWED
- REAL_ALLOWED + PH110 blocked → DRY_RUN_ONLY
- Connector disabled → fallback
- Rollout stages (NONE, INTERNAL_TEST, LIMITED_TENANT, LIMITED_ACTIONS)
- ESCALATE_LEGAL/FRAUD/REFUND → always excluded
- REQUEST_INFORMATION / NOTIFY_CUSTOMER activables
- Governance LOCKED/DEGRADED → DRY_RUN_ONLY
- Governance RESTRICTED → downgrade HUMAN_REVIEW
- Prompt block structure
- Multi-tenant isolation
- Idempotence
- No real execution triggered

---

## 11. Vérification DEV

```
14 PASS / 0 FAIL
PASS Health, PH111 (activation, policies, matrix),
PH110, PH109, PH108, PH107, PH106, PH105, PH103, PH100, PH99
```

---

## 12. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.12-ph110-controlled-execution-dev -n keybuzz-api-dev
```

---

## 13. Non-régression

PH41 → PH110 : tous intacts, 14/14 endpoints vérifiés 200 OK.
