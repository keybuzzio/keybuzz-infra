# PH78 — AI Performance Metrics Engine

> Date : 2026-03-11
> Auteur : Agent Cursor
> Image DEV : `v3.5.89-ph78-ai-performance-metrics-dev`
> Rollback : `v3.5.88-ph77-execution-audit-dev`

---

## 1. Objectif

Fournir une vue agregee des performances du moteur IA SAV.
PH78 ne modifie aucun comportement IA — il agrege les donnees d'audit PH77 pour repondre a des questions de suivi :
volume d'utilisation, qualite, taux d'escalade, adoption autopilot, distribution des workflows.

---

## 2. Service

### Fichier : `src/services/aiPerformanceMetricsEngine.ts`

| Fonction | Description |
|----------|-------------|
| `computeAiPerformanceMetrics(pool, filters)` | Metriques globales agregees |
| `computeTenantAiMetrics(pool, tenantId, filters)` | Metriques par tenant |
| `computeWorkflowMetrics(pool, filters)` | Distribution par workflow avec detail |
| `computeTimelineMetrics(pool, filters)` | Historique par jour (90 jours max) |

### Source de donnees
Table `ai_execution_audit` (PH77) — source de verite.

---

## 3. Metriques calculees (12 familles)

| # | Famille | Champs |
|---|---------|--------|
| 1 | Execution totals | executions, safeAutomatic, assisted, blocked |
| 2 | Execution level distribution | SAFE_AUTOMATIC, NONE (blocked), autres |
| 3 | Action distribution | REQUEST_INFORMATION, OPEN_CARRIER_INVESTIGATION, etc. |
| 4 | Workflow distribution | DELIVERY_INVESTIGATION, WARRANTY_PROCESS, etc. |
| 5 | Escalation distribution | (extensible via decision_context) |
| 6 | Safety block distribution | fraud HIGH, abuse HIGH, critical value, etc. |
| 7 | Top intents | DELIVERY_DELAY, PRODUCT_DEFECT, REFUND_REQUEST, etc. |
| 8 | Top fraud signals | (via safety_block_reason) |
| 9 | Top abuse signals | (via safety_block_reason) |
| 10 | Prediction distribution | WARRANTY_PATH, INVESTIGATION, REFUND, etc. |
| 11 | Autopilot adoption | total, safeAutomatic, blocked, adoptionRate |
| 12 | Timeline | executions/jour, safeAutomatic/jour, blocked/jour |

---

## 4. Filtres supportes

| Filtre | Type | Description |
|--------|------|-------------|
| `tenantId` | string | Filtre par tenant |
| `dateFrom` / `date_from` | string | Date debut (ISO) |
| `dateTo` / `date_to` | string | Date fin (ISO) |
| `workflowStage` | string | Filtre par workflow |
| `actionType` | string | Filtre par action |
| `executionLevel` | string | Filtre par niveau execution |

---

## 5. Endpoints

### GET /ai/performance-metrics
Metriques globales. Parametres : tenantId, date_from, date_to, workflowStage, actionType, executionLevel.

### GET /ai/performance-metrics/tenant
Metriques par tenant. Parametre requis : tenantId.

### GET /ai/performance-metrics/workflows
Distribution workflow detaillee avec safeAutomatic et blocked par workflow.

### GET /ai/performance-metrics/timeline
Historique par jour (90 jours max). Retourne un tableau de `{ date, executions, safeAutomatic, blocked }`.

Tous les endpoints : 0 LLM, 0 KBActions, lecture seule.

---

## 6. Exemples JSON

### Global
```json
{
  "period": { "from": "2026-03-01", "to": "2026-03-11" },
  "totals": { "executions": 124, "safeAutomatic": 28, "assisted": 71, "manual": 0, "blocked": 25 },
  "workflowDistribution": { "DELIVERY_INVESTIGATION": 34, "WARRANTY_PROCESS": 22 },
  "actionDistribution": { "REQUEST_INFORMATION": 35, "OPEN_CARRIER_INVESTIGATION": 18 },
  "safetyBlocks": { "fraud risk is HIGH": 8, "order value is CRITICAL": 5 },
  "topIntents": { "DELIVERY_DELAY": 29, "PRODUCT_DEFECT": 24 },
  "predictionDistribution": { "WARRANTY_PATH": 40, "INVESTIGATION": 30 },
  "autopilotAdoption": { "total": 124, "safeAutomatic": 28, "blocked": 25, "adoptionRate": 0.23 }
}
```

### Tenant
```json
{
  "tenantId": "ecomlg-001",
  "totals": { "executions": 48, "safeAutomatic": 11, "assisted": 28, "manual": 0, "blocked": 9 },
  "topWorkflows": [{ "key": "INFORMATION_REQUIRED", "count": 17 }],
  "topActions": [{ "key": "REQUEST_INFORMATION", "count": 19 }],
  "topSafetyBlocks": [{ "key": "fraud risk is HIGH", "count": 3 }],
  "topIntents": [{ "key": "DELIVERY_DELAY", "count": 12 }]
}
```

---

## 7. Tests

| Test | Description | Resultat |
|------|-------------|----------|
| T1 | Empty metrics stable | PASS |
| T2 | 3 audits totals correct | PASS |
| T3 | Workflow distribution | PASS |
| T4 | Action distribution | PASS |
| T5 | Tenant filter | PASS |
| T6 | Date range filter | PASS |
| T7 | Execution levels | PASS |
| T8 | Safety blocks | PASS |
| T9 | Top intents | PASS |
| T10 | Prediction distribution | PASS |
| T11 | Autopilot adoption | PASS |
| T12 | Tenant metrics | PASS |
| T13 | Workflow metrics | PASS |
| T14 | Timeline metrics | PASS |
| T15 | Non-regression | PASS |

**Total : 15 tests / 48 assertions / 0 echec**

Tests d'integration executes dans le pod API DEV avec DB reelle.

---

## 8. Non-regression

- PH41 a PH77 : aucune modification
- 0 appel LLM
- 0 impact KBActions
- Pipeline IA inchange

---

## 9. Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.88-ph77-execution-audit-dev -n keybuzz-api-dev
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.88-ph77-execution-audit-dev -n keybuzz-api-dev
```
