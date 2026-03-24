# PH110 — Controlled Real Execution Layer

> Date : 2026-03-17
> Environnement : DEV deployé, PROD en attente
> Image : `v3.6.12-ph110-controlled-execution-dev`
> Rollback : `v3.6.11-ph109-case-state-persistence-dev`

---

## 1. Objectif

PH110 introduit la couche de gating d'exécution réelle. Pour la première fois, le système peut calculer si une action **pourrait** passer de SIMULATED à REAL_EXECUTION_ALLOWED — mais tout reste en dry-run par défaut.

Principe fondamental : **fail-safe par défaut, en cas de doute → BLOCK.**

---

## 2. Architecture

### Service
- `src/services/controlledExecutionEngine.ts`

### Tables créées (auto CREATE IF NOT EXISTS)

#### `ai_execution_control`
Table d'allowlist par tenant/connector/action.

| Colonne | Type | Description |
|---|---|---|
| id | UUID PK | Identifiant |
| tenant_id | TEXT | Tenant |
| connector_name | TEXT | Connecteur cible |
| action_name | TEXT | Action |
| execution_policy | TEXT | DRY_RUN_ONLY / REAL_ALLOWED / REAL_WITH_HUMAN_REVIEW / DISABLED |
| is_enabled | BOOLEAN | Allowlist active |
| require_human_review | BOOLEAN | Review humaine requise |

UNIQUE (tenant_id, connector_name, action_name)

#### `ai_execution_attempt_log`
Journal de toutes les tentatives d'exécution.

| Colonne | Type | Description |
|---|---|---|
| id | UUID PK | Identifiant |
| tenant_id | TEXT | Tenant |
| conversation_id | TEXT | Conversation |
| action_name | TEXT | Action tentée |
| connector_name | TEXT | Connecteur |
| requested_mode | TEXT | Mode demandé |
| effective_mode | TEXT | Mode effectif |
| execution_result | TEXT | Résultat |
| blocked_reason | TEXT | Raison du blocage |
| payload | JSONB | Payload |
| dry_run | BOOLEAN | True si dry-run |

---

## 3. Kill Switches

| Type | Variable | Default |
|---|---|---|
| Global | `AI_REAL_EXECUTION_ENABLED` | `false` |
| Par connecteur | `AI_CONNECTOR_{NAME}_ENABLED` | `false` |
| Par tenant | Table `ai_execution_control` | Pas de policy = simulé |

---

## 4. Cascade de sécurité

Chaque action passe par 12 gates dans l'ordre :

1. Action toujours bloquée (ESCALATE_LEGAL, ESCALATE_FRAUD)
2. Action refund toujours bloquée (PREPARE_REFUND_REVIEW)
3. Kill switch global
4. Governance LOCKED/DEGRADED
5. Fraud risk HIGH/CRITICAL
6. Kill switch connecteur
7. Tenant pas allowlisté
8. Policy désactivée
9. Policy = DISABLED
10. Policy = DRY_RUN_ONLY
11. Policy = REAL_WITH_HUMAN_REVIEW
12. Policy = REAL_ALLOWED (toutes les gates passées)

Si une seule gate échoue → fallback SIMULATED ou BLOCKED.

---

## 5. Modes effectifs

| Mode | Description |
|---|---|
| BLOCKED | Action interdite |
| SIMULATED | Dry-run (aucun effet réel) |
| REAL_EXECUTION_ALLOWED | Techniquement autorisable |
| REAL_EXECUTION_REQUIRES_HUMAN | Requiert review humaine |

---

## 6. Position pipeline

```
PH105 Autonomous Ops Plan
PH106 Action Dispatcher
PH107 Connector Abstraction
PH108 Autonomous Case Manager
PH109 Case State Persistence
PH110 Controlled Real Execution  ← NOUVEAU
PH100 Governance
LLM
PH98 Quality Scoring
PH99 Self Improvement
```

---

## 7. Endpoints debug

| Route | Description |
|---|---|
| `GET /ai/controlled-execution` | Résumé exécution gating |
| `GET /ai/controlled-execution/policies` | Policies actives du tenant |
| `GET /ai/controlled-execution/logs` | Journal des tentatives |

---

## 8. decisionContext

```json
{
  "controlledExecution": {
    "summary": { "totalActions": 1, "blocked": 0, "simulated": 1, "realAllowed": 0 },
    "globalExecutionEnabled": false,
    "killSwitchActive": true
  }
}
```

---

## 9. Prompt block

```
=== CONTROLLED REAL EXECUTION LAYER (PH110) ===
Execution gating summary:
- 1 actions evaluated
- 0 real execution allowed
- 1 simulated
- 0 blocked

Execution policy:
- safe by default
- real execution only if explicitly enabled
- do not claim any action was actually executed unless confirmed
=== END CONTROLLED REAL EXECUTION LAYER ===
```

---

## 10. Tests

22 tests, 72 assertions, 100% PASS.

Cas couverts :
- Global kill switch → simulated
- Tenant not allowlisted → simulated
- Action not allowlisted → simulated
- Connector disabled → simulated
- Governance LOCKED/DEGRADED → blocked
- Fraud HIGH/CRITICAL → blocked
- ESCALATE_LEGAL → always blocked
- ESCALATE_FRAUD → always blocked
- PREPARE_REFUND_REVIEW → always blocked
- REAL_ALLOWED full allowlist → REAL_EXECUTION_ALLOWED
- REAL_WITH_HUMAN_REVIEW → REQUIRES_HUMAN
- DRY_RUN_ONLY policy → simulated
- DISABLED policy → blocked
- Prompt block structure
- Multi-tenant isolation
- Idempotence
- No real call by default

---

## 11. Vérification DEV

```
PASS Health: 200
PASS PH110-execution: 200 (totalActions:1, simulated:1, realAllowed:0)
PASS PH110-policies: 200 (0 policies)
PASS PH110-logs: 200 (log enregistré)
PASS PH109-state: 200
PASS PH108-case-mgr: 200
PASS PH107-connectors: 200
PASS PH106-dispatcher: 200
PASS PH105-ops: 200
PASS PH103-strategic: 200
PASS PH100-governance: 200
PASS PH99-self-improve: 200
12 PASS / 0 FAIL
```

---

## 12. Ce qui est activé / désactivé

| Élément | Statut |
|---|---|
| Kill switch global | **OFF** (pas d'env var) |
| Connecteurs | **Tous OFF** |
| Allowlist tenants | **Vide** |
| Exécution réelle | **Aucune** |
| Logging | **Actif** |

---

## 13. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.11-ph109-case-state-persistence-dev -n keybuzz-api-dev
```

Les tables créées sont inoffensives si rollback applicatif.

---

## 14. Non-régression

PH41 → PH109 : tous intacts, 12/12 endpoints vérifiés 200 OK.
