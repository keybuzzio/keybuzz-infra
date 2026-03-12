# PH84 - SLA & Follow-up Scheduler Engine - Rapport

> Date : 12 mars 2026
> Auteur : Cursor CE
> Image DEV : `v3.5.95-ph84-followup-scheduler-dev`
> Rollback : `v3.5.94-ph83-control-center-dev`

---

## 1. Objectif

Creer un moteur de scheduling intelligent qui surveille automatiquement les dossiers follow-up (PH82) pour :

- Detecter les follow-ups arrivant a echeance
- Detecter les follow-ups depasses
- Generer des actions recommandees
- Calculer les priorites dynamiques
- Alimenter le Control Center (PH83)

PH84 ne modifie aucun comportement IA. C'est une couche operationnelle.

---

## 2. Architecture

### Service

`src/services/followupSchedulerEngine.ts`

### Fonctions principales

| Fonction | Role |
|---|---|
| `computeUrgency(dueAt)` | Calcule l'urgence : ON_TRACK / UPCOMING / DUE_SOON / OVERDUE / CRITICAL |
| `computeFollowupSchedulerPriority(item)` | Score 0-100 → priorite LOW/MEDIUM/HIGH/CRITICAL |
| `generateFollowupActions(items)` | Genere les actions recommandees pour les cas en retard |
| `scanUpcomingFollowups(pool, filters)` | Liste les follow-ups a echeance < 24h |
| `scanOverdueFollowups(pool, filters)` | Liste les follow-ups depasses |
| `buildFollowupSchedulerReport(pool, filters)` | Rapport complet (totals, distributions, actions) |
| `computeFollowupTimeline(pool, filters)` | Timeline par jour |
| `computeTenantSchedulerView(pool, tenantId)` | Vue par tenant |

---

## 3. Niveaux d'urgence

| Etat | Condition |
|---|---|
| ON_TRACK | due_at > 24h |
| UPCOMING | due_at dans < 24h |
| DUE_SOON | due_at dans < 6h |
| OVERDUE | due_at depasse |
| CRITICAL | > 24h de retard |

---

## 4. Algorithme de priorite

Score 0-100 base sur :

| Facteur | Points |
|---|---|
| CRITICAL overdue | +40 |
| OVERDUE | +25 |
| DUE_SOON | +15 |
| UPCOMING | +5 |
| Fraud HIGH | +20 |
| Legal escalation | +20 |
| Critical value | +15 |
| High value | +8 |
| Supplier escalation | +10 |
| Internal review | +5 |
| Escalation wait | +5 |

Classification :

| Score | Priorite |
|---|---|
| 81-100 | CRITICAL |
| 51-80 | HIGH |
| 21-50 | MEDIUM |
| 0-20 | LOW |

---

## 5. Actions recommandees

| Type follow-up | Action generee |
|---|---|
| WAITING_CUSTOMER overdue | RECONTACT_CUSTOMER |
| WAITING_CARRIER overdue | OPEN_CARRIER_INVESTIGATION |
| WAITING_SUPPLIER overdue | RECONTACT_SUPPLIER |
| WAITING_RETURN overdue | REMIND_RETURN |
| WAITING_REFUND_PROCESS overdue | EXPEDITE_REFUND |
| WAITING_INTERNAL_REVIEW overdue | ESCALATE_INTERNAL |
| WAITING_ESCALATION overdue | ASSIGN_SENIOR_AGENT |
| WAITING_EXTERNAL_RESPONSE overdue | FOLLOW_UP_MARKETPLACE |

---

## 6. Endpoints

| Method | Route | Description |
|---|---|---|
| GET | `/ai/followup-scheduler` | Rapport global (totals, distributions, actions) |
| GET | `/ai/followup-scheduler/overdue` | Liste des follow-ups en retard |
| GET | `/ai/followup-scheduler/priorities` | Distribution des priorites |
| GET | `/ai/followup-scheduler/timeline` | Timeline par jour |
| GET | `/ai/followup-scheduler/tenant` | Vue par tenant (tenantId requis) |

Tous les endpoints acceptent `?tenantId=xxx` en filtre.

---

## 7. Exemple JSON

### GET /ai/followup-scheduler?tenantId=ecomlg-001

```json
{
  "totals": {
    "openFollowups": 3,
    "upcoming": 1,
    "dueSoon": 0,
    "overdue": 0,
    "critical": 2
  },
  "priorityDistribution": {
    "LOW": 0,
    "MEDIUM": 1,
    "HIGH": 0,
    "CRITICAL": 2
  },
  "urgencyDistribution": {
    "ON_TRACK": 0,
    "UPCOMING": 1,
    "DUE_SOON": 0,
    "OVERDUE": 0,
    "CRITICAL": 2
  },
  "typeDistribution": {
    "WAITING_CUSTOMER": 1,
    "WAITING_CARRIER": 1,
    "WAITING_SUPPLIER": 1
  },
  "actionsRecommended": [
    { "type": "RECONTACT_CUSTOMER", "count": 1 },
    { "type": "OPEN_CARRIER_INVESTIGATION", "count": 1 }
  ]
}
```

---

## 8. Pipeline

```
PH77 Execution Audit Trail
PH78 Performance Metrics
PH79 Health Monitoring
PH80 Safety Simulation
PH81 Human Approval Queue
PH82 Follow-up Engine
PH83 Control Center
PH84 Follow-up Scheduler ← NOUVEAU
```

PH84 est visible dans `pipelineOrder` et `pipelineLayers.followupScheduler: true`.

---

## 9. Resultats tests

```
23 PASS / 0 FAIL / 50 assertions
```

| Test | Description | Resultat |
|---|---|---|
| T1 | Global scheduler report empty | PASS |
| T2 | Overdue endpoint empty | PASS |
| T3 | Priorities endpoint empty | PASS |
| T4 | Timeline endpoint empty | PASS |
| T5 | Tenant scheduler view | PASS |
| T6 | Missing tenantId → 400 | PASS |
| T7 | Overdue detects inserted cases | PASS |
| T8 | Report detects overdue + upcoming | PASS |
| T9 | Actions recommended | PASS |
| T10 | Type WAITING_CUSTOMER present | PASS |
| T11 | Type WAITING_CARRIER present | PASS |
| T12 | Type WAITING_SUPPLIER present | PASS |
| T13 | Priority distribution | PASS |
| T14 | Urgency distribution | PASS |
| T15 | Tenant view with data | PASS |
| T16 | Timeline entries | PASS |
| T17 | Non-regression PH82 | PASS |
| T18 | Non-regression PH83 | PASS |
| T19 | Non-regression PH81 | PASS |
| T20 | PH84 in deployed code | PASS |
| T21 | Non-regression PH80 | PASS |
| T22 | Non-regression PH79 | PASS |
| T23 | Non-regression /health | PASS |

---

## 10. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.94-ph83-control-center-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.94-ph83-control-center-dev -n keybuzz-api-dev
```

---

## 11. Source de donnees

PH84 lit uniquement la table `ai_followup_cases` (creee par PH82).
Aucune nouvelle table n'est necessaire.

---

## 12. Impact

- Aucun appel LLM
- Aucun cout KBActions
- Aucune modification du pipeline IA PH41-PH83
- 100% lecture / agregation
