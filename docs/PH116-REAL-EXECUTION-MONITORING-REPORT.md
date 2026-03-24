# PH116 — Real Execution Monitoring & Incident Guardrail

**Date** : 19 mars 2026
**Auteur** : Cursor Executor
**Image DEV** : `v3.6.18-ph116-real-execution-monitoring-dev`
**Image PROD** : `v3.6.18-ph116-real-execution-monitoring-prod`
**Rollback** : `v3.6.17-ph115-real-execution-{dev|prod}`

---

## 1. Objectif

PH116 ajoute une couche de monitoring et de protection automatique pour les executions reelles et simulees du systeme IA. Il detecte les anomalies, calcule la sante des connecteurs, et recommande des actions de fallback en cas d'incident.

PH116 ne cree aucune nouvelle action reelle. Il securise l'execution deja activable.

---

## 2. Architecture

### Service cree

`src/services/realExecutionMonitoringEngine.ts`

### Fonctions principales

| Fonction | Role |
|---|---|
| `computeRealExecutionMetrics(filters)` | Metriques completes (volume, succes, latence, safety, connectors) |
| `detectExecutionIncidents(filters)` | Detection d'anomalies (failures, spikes, degradation) |
| `computeConnectorHealth(filters)` | Sante par connecteur |
| `computeFallbackRecommendation(filters)` | Recommandation de fallback globale/tenant/connecteur |
| `getActiveIncidents(filters)` | Incidents actifs non resolus |
| `buildRealExecutionMonitoringBlock(metrics, fallback)` | Bloc prompt LLM |

### Table creee

```sql
CREATE TABLE ai_execution_incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id TEXT,
  connector_name TEXT,
  action_name TEXT,
  incident_type TEXT NOT NULL,
  severity TEXT NOT NULL,          -- LOW | MEDIUM | HIGH | CRITICAL
  incident_payload JSONB DEFAULT '{}',
  fallback_recommendation TEXT,    -- NONE | SWITCH_TO_DRY_RUN | DISABLE_CONNECTOR | ...
  resolved BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  resolved_at TIMESTAMP
);
```

---

## 3. Familles de metriques (10)

| # | Famille | Contenu |
|---|---|---|
| 1 | Execution volume | total, real, dryRun |
| 2 | Success rate | sent, blocked, failed, fallbacked |
| 3 | Latency | avg, p95, max |
| 4 | Safety blocks | governance, fraud, abuse, missingData, killSwitch, tenant |
| 5 | Kill switch | currentlyEnabled |
| 6 | Action distribution | count par action |
| 7 | Connector health | status, failures, successRate par connecteur |
| 8 | Fallback rate | count, ratio |
| 9 | Incident signals | repeated_failures, latency_spike, fallback_spike, block_spike, anomaly |
| 10 | Tenant risk | riskScore, anomalyState (NORMAL/ELEVATED/CRITICAL) |

---

## 4. Detection d'incidents (7 types)

| Type | Seuil | Recommandation |
|---|---|---|
| `repeated_connector_failures` | >=3 failures / 30 min | DISABLE_CONNECTOR |
| `latency_spike` | p95 > 5000ms | REQUIRE_HUMAN_REVIEW |
| `fallback_spike` | >=5 fallbacks / 30 min | SWITCH_TO_DRY_RUN |
| `block_spike` | >=10 blocks / 30 min | REQUIRE_HUMAN_REVIEW |
| `execution_anomaly` | volume > 150 / 30 min | SWITCH_TO_DRY_RUN |
| `connector_degraded` | success rate < 70% | DISABLE_CONNECTOR |
| `tenant_risk_escalation` | risk score > 0.6 | DISABLE_TENANT |

---

## 5. Recommandations de fallback

| Mode | Description |
|---|---|
| `NONE` | Tout nominal |
| `SWITCH_TO_DRY_RUN` | Incidents critiques — basculer en dry-run |
| `DISABLE_CONNECTOR` | Connecteur instable — desactiver |
| `DISABLE_TENANT` | Tenant genere trop d'anomalies |
| `REQUIRE_HUMAN_REVIEW` | Incidents non critiques — validation humaine |

Mode actuel : **advisory only** (recommandation, pas d'action automatique).

---

## 6. Endpoints

| Method | Route | Description |
|---|---|---|
| GET | `/ai/real-execution-monitoring` | Metriques globales |
| GET | `/ai/real-execution-incidents` | Incidents detectes + actifs |
| GET | `/ai/real-execution-connectors` | Sante des connecteurs |
| GET | `/ai/real-execution-fallback` | Recommandation de fallback |

Parametres : `tenantId`, `date_from`, `date_to` (optionnels).

---

## 7. Verification DEV (19 mars 2026)

```
/health                           → 200 OK
/ai/real-execution-monitoring     → 200 total=10 real=5 risk=0.13
/ai/real-execution-incidents      → 200 detected=0 active=0
/ai/real-execution-connectors     → 200 connectors=1
/ai/real-execution-fallback       → 200 risk=LOW rec=NONE
```

Non-regression :
```
/ai/real-execution-live           → 200
/ai/safe-execution                → 200
/ai/governance                    → 200
/ai/controlled-execution          → 200
```

---

## 8. Verification PROD (19 mars 2026)

```
/health                           → 200 OK
/ai/real-execution-monitoring     → 200 total=8 killSwitch=false
Env check                         → [OK] No activation env vars in PROD
```

**CONFIRMATION : PROD reste en DRY_RUN total.**

Aucune variable `PH113_SAFE_MODE`, `AI_REAL_EXECUTION_ENABLED`, `PH114_EXPANDED_MODE` n'est definie en PROD.

---

## 9. Tests (ph116-tests.ts)

| Metrique | Valeur |
|---|---|
| Tests | 22 |
| Assertions | 75+ |
| PASS | 100% |

Couverture :
- T01-T04 : Metriques vides et structurees
- T05 : Sante connecteurs
- T06-T07 : Incidents (detection + actifs)
- T08-T09 : Fallback recommendation structure
- T10-T12 : Prompt block (vide, avec data, avec incidents)
- T13 : Logique health DEGRADED/UNHEALTHY
- T14-T15 : Fallback critical vs clean
- T16 : Multi-tenant isolation
- T17 : Filtrage par date
- T18 : Categorisation safety blocks
- T19 : Distribution actions
- T20 : PH116 ne declenche aucune execution reelle
- T21 : Non-regression types PH115
- T22 : Structure incident valide

---

## 10. Position pipeline

```
PH110 Controlled Real Execution
PH111 Controlled Activation
PH113/114/115 Real Safe Execution
PH116 Monitoring & Incident Guardrail   ← NOUVEAU
```

PH116 lit `ai_execution_attempt_log` et `ai_execution_control` sans les modifier. Il ecrit uniquement dans `ai_execution_incidents` pour persister les incidents detectes.

---

## 11. Rollback

```bash
# DEV
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.17-ph115-real-execution-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev

# PROD
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.17-ph115-real-execution-prod -n keybuzz-api-prod
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-prod
```

La table `ai_execution_incidents` est inoffensive si rollback applicatif.

---

## 12. Resume

| Element | Statut |
|---|---|
| Service monitoring | Cree |
| Table incidents | Creee (auto-migration) |
| 4 endpoints | Operationnels |
| 10 familles metriques | Implementees |
| 7 types incidents | Detectables |
| 5 recommandations fallback | Calculees |
| Tests | 22/22 PASS (75+ assertions) |
| DEV deploye | v3.6.18-ph116-real-execution-monitoring-dev |
| PROD deploye | v3.6.18-ph116-real-execution-monitoring-prod |
| PROD activation | AUCUNE (DRY_RUN total) |
| GitOps | deployment.yaml mis a jour |
| Non-regression | PH41-PH115 intacts |
