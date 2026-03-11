# PH77 — Execution Audit Trail Engine

> Date : 2026-03-11
> Auteur : Agent Cursor
> Image DEV : `v3.5.88-ph77-execution-audit-dev`
> Rollback : `v3.5.87-ph76-autopilot-execution-dev`

---

## 1. Objectif

Ajouter un journal complet d'execution des decisions IA et des actions Autopilot.
PH77 ne modifie aucun comportement IA — il ajoute uniquement la tracabilite.

### Cas d'usage
- Audit interne des decisions IA
- Debugging avance du pipeline
- Supervision future dans l'admin panel
- Conformite (Amazon / support client)

---

## 2. Architecture

### Table DB : `ai_execution_audit`

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID | PK auto-generee |
| `tenant_id` | TEXT | Identifiant tenant |
| `conversation_id` | TEXT | Identifiant conversation |
| `order_ref` | TEXT | Reference commande |
| `action_type` | TEXT | Type d'action IA (REQUEST_INFORMATION, PREPARE_RETURN, etc.) |
| `action_execution_level` | TEXT | NONE / SAFE_AUTOMATIC |
| `action_executable` | BOOLEAN | Action autorisee ou bloquee |
| `fraud_risk` | TEXT | LOW / MEDIUM / HIGH |
| `abuse_risk` | TEXT | LOW / MEDIUM / HIGH |
| `order_value_category` | TEXT | LOW / MEDIUM / HIGH / CRITICAL |
| `customer_intent` | TEXT | Intent PH54 |
| `decision_prediction` | TEXT | Resolution predite PH64 |
| `workflow_stage` | TEXT | Etape workflow PH70 |
| `autopilot_action` | TEXT | Action autopilot PH71 |
| `carrier_action` | TEXT | Action transporteur PH73 |
| `return_action` | TEXT | Scenario retour PH74 |
| `supplier_action` | TEXT | Scenario fournisseur PH75 |
| `safety_block_reason` | TEXT | Raison blocage PH76 |
| `decision_context` | JSONB | Snapshot complet decisionContext |
| `created_at` | TIMESTAMPTZ | Timestamp |

### Index
- `idx_ai_exec_audit_tenant` — tenant_id
- `idx_ai_exec_audit_conv` — conversation_id
- `idx_ai_exec_audit_order` — order_ref
- `idx_ai_exec_audit_created` — created_at

---

## 3. Service

### Fichier : `src/services/executionAuditTrailEngine.ts`

#### Fonctions
| Fonction | Description |
|----------|-------------|
| `computeExecutionAuditTrail(ctx)` | Construit le record d'audit a partir du contexte pipeline |
| `saveExecutionAudit(pool, record)` | INSERT asynchrone (fire-and-forget, non bloquant) |
| `queryExecutionAudit(pool, tenantId, conversationId?, limit?)` | Lecture des enregistrements d'audit |

#### Capture des donnees
Le moteur capture automatiquement :
- **PH54** : customerIntent
- **PH55** : fraudRisk
- **PH63** : abuseRisk
- **PH64** : resolutionPrediction
- **PH70** : workflowStage
- **PH71** : autopilotAction
- **PH73** : carrierPlanType
- **PH74** : returnScenario
- **PH75** : supplierCaseScenario
- **PH76** : executable, executionLevel, reason (safety block)
- **orderContext** : orderRef, totalAmount -> valueCategory

---

## 4. Position dans le pipeline

```
PH41 SAV Policy
...
PH75 Supplier Case Automation
PH76 Autopilot Safe Execution
PH77 Execution Audit Trail    <-- NOUVEAU (fire-and-forget INSERT)
PH67 Knowledge Retrieval
...
buildSystemPrompt
LLM
PH66 Self Protection
```

PH77 est execute apres PH76 et avant PH67.
L'INSERT est asynchrone (`saveExecutionAudit(...).catch(...)`) pour ne pas ralentir la reponse IA.

---

## 5. Endpoint debug

### GET /ai/execution-audit
| Parametre | Requis | Description |
|-----------|--------|-------------|
| `tenantId` | Oui | Identifiant tenant |
| `conversationId` | Non | Filtre par conversation |
| `limit` | Non | Nombre de resultats (defaut: 20) |

Retour :
```json
{
  "executions": [...],
  "count": 42
}
```

### /ai/policy/effective
PH77 est present dans :
- `pipelineOrder` : `"PH77"` apres `"PH76"`
- `pipelineLayers` : `"executionAuditTrail": true`
- `finalPromptSections` : `"EXECUTION_AUDIT_TRAIL"`

---

## 6. Tests

| Test | Description | Resultat |
|------|-------------|----------|
| T1 | Basic audit record | PASS |
| T2 | Autopilot action captured | PASS |
| T3 | Fraud HIGH with safety block | PASS |
| T4 | Return flow audit | PASS |
| T5 | Supplier flow audit | PASS |
| T6 | Carrier flow audit | PASS |
| T7 | Manual escalation | PASS |
| T8 | Safe automatic | PASS |
| T9 | Multi-layer decisionContext | PASS |
| T10 | Missing data defaults | PASS |
| T11 | Abuse HIGH block | PASS |
| T12 | Critical value block | PASS |
| T13 | Resolution prediction captured | PASS |
| T14 | Order ref captured | PASS |
| T15 | Forbidden action block | PASS |
| T16 | DecisionContext JSON snapshot | PASS |
| T17 | Executable = no block reason | PASS |

**Total : 17 tests / 54 assertions / 0 echec**

---

## 7. Non-regression

- PH41 a PH76 : aucune modification
- 0 appel LLM supplementaire
- 0 impact KBActions
- Pipeline IA inchange (PH77 est uniquement un observateur)
- INSERT asynchrone non bloquant

---

## 8. Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.87-ph76-autopilot-execution-dev -n keybuzz-api-dev
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.87-ph76-autopilot-execution-dev -n keybuzz-api-dev
```

La table `ai_execution_audit` peut etre conservee meme apres rollback (pas de schema breaking change).
