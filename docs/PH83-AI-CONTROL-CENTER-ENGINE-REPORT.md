# PH83 - AI Control Center Engine - Rapport

> Date : 12 mars 2026
> Environnement : DEV
> Image : `v3.5.94-ph83-control-center-dev`
> Rollback : `v3.5.93-ph82-followup-engine-dev`

---

## Objectif

Centraliser tous les signaux IA et operationnels en une vue consolidee. PH83 agregue les donnees de PH77 (audit), PH78 (metrics), PH79 (health), PH81 (human queue) et PH82 (followups) pour constituer la base du futur Admin Dashboard.

PH83 est 100% lecture / agregation. Aucune modification du comportement IA.

---

## Architecture

### Service
- Fichier : `src/services/aiControlCenterEngine.ts`
- 12 fonctions exportees

### Sources de donnees
| Table | Usage |
|---|---|
| `ai_execution_audit` | Executions, workflows, actions, escalations, safety |
| `ai_followup_cases` | Follow-ups en attente |
| `ai_human_approval_queue` | Files de validation humaine |

---

## Metriques (10 groupes)

| # | Groupe | Description |
|---|---|---|
| 1 | Execution totals | total, safeAutomatic, assisted, manual |
| 2 | Workflow distribution | repartition par workflowStage |
| 3 | Action distribution | top actions IA |
| 4 | Escalation distribution | repartition par type d'escalade |
| 5 | Safety block distribution | raisons de blocage securite |
| 6 | Follow-up states | breakdown par followup_type |
| 7 | Human approval queues | breakdown par queue_type |
| 8 | Autopilot adoption | taux d'automatisation |
| 9 | Tenant distribution | metriques par tenant |
| 10 | System health score | score global + status + alertes |

---

## Endpoints (5)

| Method | Route | Description |
|---|---|---|
| GET | `/ai/control-center` | Vue globale consolidee |
| GET | `/ai/control-center/tenant` | Vue par tenant (tenantId requis) |
| GET | `/ai/control-center/queues` | Files operationnelles (HA + followups) |
| GET | `/ai/control-center/workflows` | Workflows + actions + escalations |
| GET | `/ai/control-center/timeline` | Executions par jour (30 derniers jours) |

### Filtres supportes
- `tenantId` : filtre par tenant
- `date_from` / `date_to` : plage de dates

---

## Exemple de reponse `/ai/control-center`

```json
{
  "systemHealth": { "status": "HEALTHY", "score": 1.0, "activeAlerts": 0 },
  "executions": { "total": 2, "safeAutomatic": 0, "assisted": 0, "manual": 0 },
  "queues": { "humanApproval": 1, "followups": 0 },
  "workflowDistribution": {},
  "followupBreakdown": {},
  "humanApprovalBreakdown": { "LEGAL_REVIEW": 1 },
  "topActions": {},
  "escalationDistribution": {},
  "safetyBlockDistribution": {},
  "autopilotAdoption": { "total": 2, "safeAutomatic": 0, "rate": 0 },
  "tenants": [{ "tenantId": "ecomlg-001", "executions": 2, "followups": 0, "humanQueue": 1 }]
}
```

---

## Health Score

| Condition | Impact |
|---|---|
| manual rate > 50% | -0.2 |
| manual rate > 30% | -0.1 |
| human queue > 10 | -0.1 |
| followups > 20 | -0.1 |

| Score | Status |
|---|---|
| >= 0.85 | HEALTHY |
| >= 0.65 | WARNING |
| < 0.65 | CRITICAL |

---

## Resultats Tests

```
Tests: 18
Assertions: 64
Passed: 64
Failed: 0
ALL PASS
```

### Cas testes
- T1 : Dataset vide - overview stable (7 assertions)
- T2 : System health (5 assertions)
- T3 : Execution totals (4 assertions)
- T4 : Workflow distribution
- T5 : Action distribution
- T6 : Escalation distribution
- T7 : Safety block distribution
- T8 : Followup summary (2 assertions)
- T9 : Human queue summary (2 assertions)
- T10 : Autopilot adoption (4 assertions)
- T11 : Tenant distribution (5 assertions)
- T12 : Tenant control center (4 assertions)
- T13 : Operational queues (4 assertions)
- T14 : Workflow summary (3 assertions)
- T15 : Timeline (2 assertions)
- T16 : Tenant filter
- T17 : Functions existence (8 assertions)
- T18 : Non-regression structure (9 assertions)

---

## Non-regression

| Check | Resultat |
|---|---|
| Health | OK |
| PH83 Control Center | health=HEALTHY exec=2 |
| PH83 Tenant | ecomlg-001 exec=2 |
| PH83 Queues | ha=1 fu=0 |
| PH82 Followups | OK |
| PH80 Safety | PASS 17/17 |
| Pipeline IA | Inchange |
| KBActions | Aucun impact |

---

## Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.93-ph82-followup-engine-dev -n keybuzz-api-dev
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.93-ph82-followup-engine-dev -n keybuzz-api-dev
```
