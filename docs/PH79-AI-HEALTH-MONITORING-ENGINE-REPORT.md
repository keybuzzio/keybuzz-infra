# PH79 — AI Health Monitoring Engine

> Phase : PH79
> Date : 2026-03-11
> Image DEV : `ghcr.io/keybuzzio/keybuzz-api:v3.5.90-ph79-ai-health-monitoring-dev`
> Rollback : `v3.5.89-ph78-ai-performance-metrics-dev`

---

## 1. Objectif

Créer une couche de supervision automatique détectant les dérives du moteur IA SAV.
PH79 ne modifie **aucun** comportement IA — il lit uniquement les données produites par PH77 (Execution Audit Trail) et PH78 (AI Performance Metrics).

PH79 agit comme un **système d'alerte précoce** pour l'IA.

---

## 2. Service

**Fichier** : `src/services/aiHealthMonitoringEngine.ts`

### Fonctions

| Fonction | Description |
|---|---|
| `computeAiHealthStatus(pool, filters)` | Score de santé global + alertes + signaux |
| `computeTenantHealthScore(pool, tenantId, filters)` | Score de santé par tenant |
| `computeHealthAlerts(pool, filters)` | Alertes actives uniquement |
| `detectAnomalies(metrics)` | Détection d'anomalies sur métriques brutes |
| `computeHealthSignals(metrics)` | Calcul des signaux de stabilité |
| `computeSystemHealthScore(signals)` | Score pondéré + classification |

### Filtres supportés

| Filtre | Type | Description |
|---|---|---|
| `tenantId` | string | Filtrer par tenant |
| `dateFrom` | string | Date début (ISO) |
| `dateTo` | string | Date fin (ISO) |

---

## 3. Anomalies détectées (10)

| # | Type | Seuil | Sévérité |
|---|---|---|---|
| 1 | `SAFETY_BLOCK_SPIKE` | >25% MEDIUM, >40% HIGH | MEDIUM/HIGH |
| 2 | `ESCALATION_SPIKE` | blockedRate + fraudRate > 50% | HIGH |
| 3 | `AUTOMATION_DROP` | safeAutomatic < 20% MEDIUM, < 10% HIGH | MEDIUM/HIGH |
| 4 | `FRAUD_SPIKE` | fraudReview > 15% MEDIUM, > 30% HIGH | MEDIUM/HIGH |
| 5 | `ABUSE_SPIKE` | safetyBlocked > 50% | HIGH |
| 6 | `WORKFLOW_DRIFT` | workflow dominant > 70% | MEDIUM |
| 7 | `INTENT_DRIFT` | intent dominant > 70% | MEDIUM |
| 8 | `ESCALATION_SPIKE` (combined) | blockedRate + fraudRate > 50% | HIGH |
| 9 | `CONFIDENCE_COLLAPSE` | via confidenceStability | via score |
| 10 | `TENANT_ANOMALY` | via computeTenantHealthScore | via score |

---

## 4. Health Score

### Signaux de stabilité

| Signal | Poids | Calcul |
|---|---|---|
| `automationStability` | 25% | safeAutoRate / 0.30 + 0.3, cap 1 |
| `safetyStability` | 25% | 1 - blockedRate * 2, min 0 |
| `workflowDistributionStability` | 20% | 1 - (dominance - 0.5) * 2, min 0 |
| `fraudStability` | 20% | 1 - fraudRate * 3, min 0 |
| `confidenceStability` | 10% | 0.85 si total >= 5, sinon 1 |

### Classification

| Score | Statut |
|---|---|
| >= 0.85 | `HEALTHY` |
| >= 0.65 | `WARNING` |
| < 0.65 | `CRITICAL` |

---

## 5. Endpoints

### GET /ai/health-monitoring

Score de santé global.

**Paramètres** : `tenantId`, `date_from`, `date_to`

**Réponse** :
```json
{
  "systemHealthScore": 0.91,
  "status": "HEALTHY",
  "metrics": {
    "executions": 124,
    "safeAutomaticRate": 0.23,
    "blockedRate": 0.05,
    "assistedRate": 0.72
  },
  "alerts": [],
  "topWorkflows": ["INFORMATION_REQUIRED", "DELIVERY_INVESTIGATION"],
  "healthSignals": {
    "automationStability": 0.88,
    "safetyStability": 0.94,
    "workflowDistributionStability": 0.90,
    "fraudStability": 0.97,
    "confidenceStability": 0.85
  }
}
```

### GET /ai/health-monitoring/tenant

Score de santé par tenant.

**Paramètres** : `tenantId` (requis), `date_from`, `date_to`

**Réponse** :
```json
{
  "tenantId": "ecomlg-001",
  "healthScore": 0.88,
  "status": "HEALTHY",
  "metrics": {
    "executions": 48,
    "safeAutomaticRate": 0.23,
    "blockedRate": 0.04
  },
  "alerts": [],
  "topWorkflows": ["DELIVERY_INVESTIGATION"]
}
```

### GET /ai/health-monitoring/alerts

Alertes actives.

**Paramètres** : `tenantId`, `date_from`, `date_to`

**Réponse** :
```json
{
  "alerts": [
    {
      "type": "SAFETY_BLOCK_SPIKE",
      "severity": "MEDIUM",
      "message": "Safety blocks exceed 25% of executions",
      "value": 30,
      "threshold": 25
    }
  ],
  "count": 1
}
```

---

## 6. Source de données

| Table | Usage |
|---|---|
| `ai_execution_audit` | Source de vérité (PH77) |

---

## 7. Pipeline

PH79 est visible dans `/ai/policy/effective` :

```
PH41 → PH44 → PH43 → PH45 → PH46 → PH49 → PH50 → PH52 → PH53 →
PH54 → PH55 → PH60 → PH61 → PH62 → PH63 → PH56 → PH57 → PH58 →
PH59 → PH64 → PH65 → PH67 → PH68 → PH69 → PH70 → PH71 → PH73 →
PH74 → PH75 → PH76 → PH77 → PH78 → PH79 → buildSystemPrompt → LLM → PH66
```

PH79 ne modifie pas le pipeline, il est listé comme couche d'observabilité.

---

## 8. Tests

| # | Test | Assertions | Résultat |
|---|---|---|---|
| T1 | Empty metrics → HEALTHY | 7 | PASS |
| T2 | Automation distribution | 4 | PASS |
| T3 | Safety spike detection | 3 | PASS |
| T4 | Escalation spike | 3 | PASS |
| T5 | Tenant anomaly | 4 | PASS |
| T6 | No data → stability = 1 | 5 | PASS |
| T7 | Workflow drift | 2 | PASS |
| T8 | Fraud spike | 1 | PASS |
| T9 | Abuse spike | 1 | PASS |
| T10 | Health score calculation | 6 | PASS |
| T11 | Alert severity | 3 | PASS |
| T12 | Global health endpoint | 4 | PASS |
| T13 | Tenant health endpoint | 3 | PASS |
| T14 | Alerts endpoint | 3 | PASS |
| T15 | Filter tenant | 1 | PASS |
| T16 | Filter date range | 2 | PASS |
| **Total** | **16 tests** | **52 assertions** | **100% PASS** |

---

## 9. Non-régression

| Endpoint | Statut |
|---|---|
| `/health` | OK |
| `/ai/assist` | Intact |
| `/ai/policy/effective` | OK (PH79 ajouté) |
| `/ai/execution-audit` | OK |
| `/ai/performance-metrics` | OK |
| Pipeline IA PH41→PH78 | Intact |
| Autopilot | Intact |
| Self-protection PH66 | Intact |
| KBActions | Aucun impact |

---

## 10. Rollback

```bash
# Rollback DEV
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.89-ph78-ai-performance-metrics-dev -n keybuzz-api-dev
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.89-ph78-ai-performance-metrics-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```
