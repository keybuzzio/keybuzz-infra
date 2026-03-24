# PH117 — Tenant AI Dashboard / Client Exposure Layer

**Date** : 19 mars 2026
**Auteur** : Cursor Executor

---

## Images deployees

| Service | DEV | PROD |
|---|---|---|
| API | `v3.6.19-ph117-ai-dashboard-dev` | `v3.6.19-ph117-ai-dashboard-prod` |
| Client | `v3.5.49-ph117-ai-dashboard-dev` | `v3.5.49-ph117-ai-dashboard-prod` |

**Rollback API** : `v3.6.18-ph116-real-execution-monitoring-{dev|prod}`
**Rollback Client** : `v3.5.48-white-bg-{dev|prod}`

---

## 1. Objectif

PH117 cree la premiere couche SaaS client-facing du moteur IA, permettant a chaque tenant de :

- Voir le niveau d'autonomie IA et l'etat du systeme
- Comprendre ce qui est automatise vs assiste vs manuel
- Visualiser la performance (executions, taux de succes)
- Mesurer l'impact financier (economies, remboursements evites)
- Surveiller les risques et la securite
- Voir l'etat des connecteurs
- Recevoir des recommandations personnalisees

---

## 2. Architecture

### Service API cree

`src/services/aiDashboardEngine.ts`

Fonctions :

| Fonction | Role |
|---|---|
| `computeAIDashboard(tenantId)` | Aggregation complete de toutes les donnees |
| `computeAIDashboardMetrics(tenantId)` | Metriques detaillees (volume, succes, safety) |
| `computeAIDashboardExecution(tenantId)` | Liste des 50 dernieres executions |
| `computeAIDashboardFinancial(tenantId)` | Impact financier (economies, refunds) |
| `computeAIDashboardRecommendations(tenantId)` | Recommandations categorisees |

### Sources de donnees aggregees

| Source | Phase | Donnee |
|---|---|---|
| `ai_execution_attempt_log` | PH110-PH115 | Executions, modes, resultats |
| `ai_execution_incidents` | PH116 | Incidents, sante systeme |
| Environment variables | PH113/114/115 | Niveaux d'autonomie, kill switch |

---

## 3. Endpoints API (5)

| Method | Route | Description |
|---|---|---|
| GET | `/ai/dashboard` | Vue complete aggregee |
| GET | `/ai/dashboard/metrics` | Metriques detaillees |
| GET | `/ai/dashboard/execution` | 50 dernieres executions |
| GET | `/ai/dashboard/financial-impact` | Impact financier |
| GET | `/ai/dashboard/recommendations` | Recommandations |

Parametre : `tenantId` (obligatoire). Header : `x-user-email`.

---

## 4. Route BFF Client

`app/api/ai/dashboard/route.ts`

Proxy vers l'API backend, parametre `view` pour les sous-endpoints.

---

## 5. Page Client UI

`app/ai-dashboard/page.tsx`

### 7 sections

| # | Section | Contenu |
|---|---|---|
| 1 | Hero Status | Niveau d'autonomie, etat, badge securite, KPI principaux |
| 2 | Automatisation | Repartition automatique / assiste / manuel avec barres |
| 3 | Workflows | Top 5 des workflows (trie par volume) |
| 4 | Impact financier | Economies, remboursements evites, garanties |
| 5 | Securite & Risques | Alertes fraude, actions bloquees, score securite |
| 6 | Connecteurs & Systeme | Etat par connecteur, incidents actifs |
| 7 | Recommandations | Suggestions personnalisees |

### Navigation

Ajout dans `ClientLayout.tsx` :
- Icone : `BarChart3`
- Label : "IA Performance"
- Position : apres "Journal IA"

---

## 6. Verification DEV (19 mars 2026)

```
/health                           → 200 OK
/ai/dashboard                     → 200 autonomy=LIMITED_AUTOPILOT executions=40 health=HEALTHY
/ai/dashboard/metrics             → 200 total=40
/ai/dashboard/execution           → 200 executions=40 total=40
/ai/dashboard/financial-impact    → 200 savings=15 refundsAvoided=0
/ai/dashboard/recommendations     → 200 recommendations=1
```

Non-regression :
```
/ai/real-execution-monitoring     → 200
/ai/real-execution-live           → 200
/ai/governance                    → 200
/ai/self-improvement              → 200
```

---

## 7. Verification PROD (19 mars 2026)

```
/health                           → 200 OK
/ai/dashboard                     → 200 autonomy=MANUAL_ONLY health=HEALTHY
```

PROD retourne `MANUAL_ONLY` car aucune variable d'activation n'est definie — comportement correct.

---

## 8. Exemple JSON — Dashboard complet

```json
{
  "tenantId": "ecomlg-001",
  "autonomy": {
    "level": "LIMITED_AUTOPILOT",
    "state": "NOMINAL",
    "eligibleForRealExecution": true
  },
  "execution": {
    "totalExecutions": 40,
    "realExecutions": 20,
    "dryRunExecutions": 20,
    "successRate": 0.95
  },
  "automation": {
    "safeAutomatic": 15,
    "assisted": 20,
    "manual": 5
  },
  "workflows": {
    "top": [
      { "name": "REQUEST_INFORMATION", "count": 25 },
      { "name": "MARK_CONVERSATION_RESOLVED", "count": 10 }
    ]
  },
  "financialImpact": {
    "estimatedSavings": 15,
    "refundsAvoided": 0,
    "warrantyUsed": 0
  },
  "risk": {
    "fraudAlerts": 0,
    "blockedActions": 2,
    "safetyScore": 0.95
  },
  "systemHealth": {
    "status": "HEALTHY",
    "incidents": 0,
    "lastIncident": null
  },
  "connectors": [
    {
      "name": "customer_interaction_connector",
      "status": "HEALTHY",
      "successRate": 0.95
    }
  ],
  "recommendations": [
    "Votre systeme IA fonctionne de maniere optimale"
  ]
}
```

---

## 9. Tests (ph117-tests.ts)

| Metrique | Valeur |
|---|---|
| Tests | 22 |
| Assertions | 70+ |
| PASS | 100% |

Couverture :
- T01-T03 : Structure complete, autonomy, execution
- T04 : Automation breakdown = total
- T05-T06 : Financial impact, risk ranges
- T07-T08 : System health, connector validation
- T09 : Recommandations generees
- T10 : Multi-tenant isolation
- T11-T15 : Endpoints secondaires (metrics, execution, financial, recommendations)
- T16 : Tenant vide = defaults sains
- T17 : Workflows tries desc
- T18 : Action distribution = total
- T19 : Idempotence
- T20 : Pas d'appel LLM ni KBActions
- T21-T22 : Financial logic, non-regression PH116

---

## 10. Mapping des phases

| Donnee UI | Source |
|---|---|
| Niveau d'autonomie | PH113/114/115 (env vars) |
| Execution metrics | PH110 (ai_execution_attempt_log) |
| Safety blocks | PH110/113/114/115 (blocked_reason) |
| Incidents systeme | PH116 (ai_execution_incidents) |
| Connecteurs | PH107/110 (connector_name) |
| Impact financier | PH110 (action_name analysis) |
| Recommandations | Logique interne basee sur metriques |

---

## 11. Rollback

```bash
# API DEV
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.18-ph116-real-execution-monitoring-dev -n keybuzz-api-dev

# API PROD
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.18-ph116-real-execution-monitoring-prod -n keybuzz-api-prod

# Client DEV
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.48-white-bg-dev -n keybuzz-client-dev

# Client PROD
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.48-white-bg-prod -n keybuzz-client-prod
```

---

## 12. Resume

| Element | Statut |
|---|---|
| Service API aggregateur | Cree (aiDashboardEngine.ts) |
| 5 endpoints API | Operationnels |
| Route BFF client | Creee |
| Page UI /ai-dashboard | Creee (7 sections) |
| Navigation sidebar | Ajoutee ("IA Performance") |
| i18n | Mis a jour |
| Tests | 22/22 PASS (70+ assertions) |
| API DEV | v3.6.19-ph117-ai-dashboard-dev |
| API PROD | v3.6.19-ph117-ai-dashboard-prod |
| Client DEV | v3.5.49-ph117-ai-dashboard-dev |
| Client PROD | v3.5.49-ph117-ai-dashboard-prod |
| PROD activation | AUCUNE (MANUAL_ONLY) |
| GitOps | deployment.yaml API mis a jour |
| Non-regression | PH41-PH116 intacts |
| Impact IA | AUCUN |
| Impact KBActions | AUCUN |
