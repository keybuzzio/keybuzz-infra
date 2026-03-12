# PH85 - Ops Action Center / Agent Workbench Engine - Rapport

> Date : 12 mars 2026
> Auteur : Cursor CE
> Image DEV : `v3.5.96-ph85-ops-action-center-dev`
> Rollback : `v3.5.95-ph84-followup-scheduler-dev`

---

## 1. Objectif

Creer un Ops Action Center Engine permettant de piloter les dossiers SAV necessitant une action humaine. PH85 introduit la couche Agent Workbench Backend :

- Consultation des dossiers necessitant intervention
- Regroupement queues + follow-ups + escalations
- Assignation d'agent
- Changement de statut
- Actions manuelles controlees (resolve, snooze)

PH85 ne modifie aucun comportement IA. Couche operationnelle uniquement.

---

## 2. Architecture

### Service

`src/services/opsActionCenterEngine.ts`

### Fonctions

| Fonction | Role |
|---|---|
| `computeOpsPriorityScore(item)` | Score 0-100 → LOW/MEDIUM/HIGH/CRITICAL |
| `getOpsDashboard(pool, filters)` | Dashboard agrege (queues + followups + totals) |
| `getPendingApprovals(pool, filters)` | Liste des approbations en attente (tri par priorite) |
| `getFollowupWorkload(pool, filters)` | Charge follow-up avec urgence + priorite calculee |
| `getEscalationCases(pool, filters)` | Cas avec escalation (depuis ai_execution_audit) |
| `assignCase(pool, caseId, agentId)` | Assigner un dossier a un agent |
| `updateCaseStatus(pool, caseId, status)` | Mettre a jour le statut |
| `resolveCase(pool, caseId)` | Clore un dossier |
| `snoozeCase(pool, caseId, durationHours)` | Reporter un dossier (1-168h) |

---

## 3. Sources de donnees

| Table | Usage |
|---|---|
| `ai_human_approval_queue` | Approbations humaines (PH81) |
| `ai_followup_cases` | Follow-ups en attente (PH82) |
| `ai_execution_audit` | Escalations (PH77) |

---

## 4. Algorithme de priorite

| Facteur | Points |
|---|---|
| Fraud HIGH | +30 |
| Fraud MEDIUM | +15 |
| Order value CRITICAL | +25 |
| Order value HIGH | +12 |
| Urgency CRITICAL | +30 |
| Urgency OVERDUE | +20 |
| Urgency DUE_SOON | +10 |
| Legal escalation | +25 |
| Fraud investigation | +20 |
| Supplier escalation | +10 |
| Human review | +5 |

| Score | Niveau |
|---|---|
| 76-100 | CRITICAL |
| 51-75 | HIGH |
| 26-50 | MEDIUM |
| 0-25 | LOW |

---

## 5. Endpoints

### Lecture

| Method | Route | Description |
|---|---|---|
| GET | `/ai/ops-dashboard` | Dashboard agrege (totals, queues, followups) |
| GET | `/ai/ops/pending-approvals` | Approbations en attente triees par priorite |
| GET | `/ai/ops/followups` | Charge follow-up avec urgence et actions recommandees |
| GET | `/ai/ops/escalations` | Cas avec escalation active |

### Actions

| Method | Route | Description |
|---|---|---|
| POST | `/ai/ops/assign` | Assigner un dossier a un agent |
| POST | `/ai/ops/resolve` | Clore un dossier |
| POST | `/ai/ops/snooze` | Reporter un dossier |

---

## 6. Exemples JSON

### GET /ai/ops-dashboard

```json
{
  "totals": {
    "humanApprovalCases": 3,
    "followupsPending": 2,
    "overdueFollowups": 1,
    "criticalCases": 1
  },
  "queues": {
    "REFUND_REVIEW": 1,
    "FRAUD_REVIEW": 1,
    "LEGAL_REVIEW": 1
  },
  "followups": {
    "WAITING_CUSTOMER": 1,
    "WAITING_CARRIER": 1
  }
}
```

### GET /ai/ops/pending-approvals

```json
{
  "count": 3,
  "items": [
    {
      "caseId": "uuid",
      "conversationId": "conv-...",
      "type": "FRAUD_REVIEW",
      "priority": "CRITICAL",
      "workflowStage": "fraud_high",
      "tenantId": "ecomlg-001",
      "suggestedAction": "ESCALATE_FRAUD_TEAM"
    }
  ]
}
```

### GET /ai/ops/followups

```json
{
  "count": 2,
  "items": [
    {
      "followupId": "uuid",
      "conversationId": "conv-...",
      "type": "WAITING_CUSTOMER",
      "urgency": "CRITICAL",
      "priorityScore": 30,
      "priorityLevel": "MEDIUM",
      "recommendedAction": "RECONTACT_CUSTOMER"
    }
  ]
}
```

### POST /ai/ops/assign

```json
{ "caseId": "uuid", "agentId": "agent_123" }
→ { "updated": true }
```

### POST /ai/ops/resolve

```json
{ "caseId": "uuid" }
→ { "resolved": true }
```

### POST /ai/ops/snooze

```json
{ "caseId": "uuid", "durationHours": 24 }
→ { "snoozed": true }
```

---

## 7. Pipeline

```
PH77 Execution Audit Trail
PH78 Performance Metrics
PH79 Health Monitoring
PH80 Safety Simulation
PH81 Human Approval Queue
PH82 Follow-up Engine
PH83 Control Center
PH84 Follow-up Scheduler
PH85 Ops Action Center ← NOUVEAU
```

Visible dans `pipelineOrder` et `pipelineLayers.opsActionCenter: true`.

---

## 8. Resultats tests

```
24 PASS / 0 FAIL / 50 assertions
```

| Test | Description | Resultat |
|---|---|---|
| T1 | Dashboard endpoint | PASS |
| T2 | Pending approvals endpoint | PASS |
| T3 | Followup workload endpoint | PASS |
| T4 | Escalations endpoint | PASS |
| T5 | Assign - 400 sans params | PASS |
| T6 | Resolve - 400 sans params | PASS |
| T7 | Snooze - 400 sans params | PASS |
| T8 | Dashboard avec donnees | PASS |
| T9 | Approvals avec donnees | PASS |
| T10 | Tri priorite CRITICAL first | PASS |
| T11 | Followup workload avec donnees | PASS |
| T12 | Items urgency + priorityScore | PASS |
| T13 | Queue distribution | PASS |
| T14 | Followup distribution | PASS |
| T15 | Assign case | PASS |
| T16 | Resolve case | PASS |
| T17 | Snooze case | PASS |
| T18 | Non-regression PH84 | PASS |
| T19 | Non-regression PH83 | PASS |
| T20 | Non-regression PH82 | PASS |
| T21 | Non-regression PH81 | PASS |
| T22 | Non-regression PH80 | PASS |
| T23 | PH85 in deployed code | PASS |
| T24 | Non-regression /health | PASS |

---

## 9. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.95-ph84-followup-scheduler-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.95-ph84-followup-scheduler-dev -n keybuzz-api-dev
```

---

## 10. Impact

- Aucun appel LLM
- Aucun cout KBActions
- Aucune modification du pipeline IA PH41-PH84
- Couche operationnelle lecture + actions controlees
