# PH95 — Global Learning Engine — Rapport

> Date : 14 mars 2026
> Auteur : Agent Cursor
> Environnement : DEV
> Image : `v3.5.96-ph95-global-learning-dev`
> Rollback : `v3.5.95-ph94-resolution-cost-optimizer-dev`

---

## 1. Objectif

Créer un moteur analytique qui synthétise les apprentissages issus de l'activité IA et humaine pour produire des insights, mesurer l'efficacité des résolutions, détecter les patterns d'escalade et générer des recommandations d'amélioration.

## 2. Sources de données

| Table | Données utilisées |
|---|---|
| `conversation_learning_events` | AI acceptance/modified/rejected rates, learning types |
| `ai_execution_audit` | Workflow stages, execution levels, resolution effectiveness |
| `ai_followup_cases` | Follow-up burden, pending/overdue counts, top types |
| `ai_human_approval_queue` | Escalation patterns by queue_type |
| `conversations` | Marketplace behavior (channel distribution) |

Toutes les requêtes sont en **lecture seule** (SELECT uniquement).

## 3. Insights calculés (10 familles)

| # | Famille | Métriques |
|---|---|---|
| 1 | AI Acceptance | acceptedRate, modifiedRate, rejectedRate, humanOnlyRate |
| 2 | Resolution Effectiveness | carrier_investigation, supplier_warranty, return, replacement, refund, human_review |
| 3 | Escalation Patterns | humanReview, fraudReview, legalReview, supplierReview, total |
| 4 | Follow-up Burden | pending, overdue, topTypes |
| 5 | Marketplace Behavior | channel distribution counts |
| 6 | Buyer Risk Outcomes | via escalation correlation |
| 7 | Refund Effectiveness | effectiveness score (0-1) |
| 8 | Warranty Effectiveness | effectiveness score (0-1) |
| 9 | Delivery Investigation | effectiveness score (0-1) |
| 10 | Learning Recommendations | generated from all metrics |

## 4. Recommandations générées

| Type | Condition |
|---|---|
| INCREASE_SUPPLIER_WARRANTY | warranty > refund effectiveness |
| REDUCE_REFUND_FIRST | refund effectiveness < 50% |
| ESCALATE_HIGH_RISK_BUYERS_EARLIER | fraud reviews > 5 |
| IMPROVE_DELIVERY_INVESTIGATION_USAGE | carrier investigation > 70% |
| REVIEW_RETURN_PATH_FOR_LOW_VALUE_ITEMS | return effectiveness < 40% |
| IMPROVE_AI_SUGGESTION_QUALITY | rejection rate > 25% |
| ANALYZE_MODIFICATION_PATTERNS | modification rate > 30% |
| REDUCE_FOLLOWUP_BACKLOG | overdue follow-ups > 3 |
| REVIEW_ESCALATION_VOLUME | total escalations > 20 |
| AI_PERFORMING_WELL | acceptance rate > 70% |
| INSUFFICIENT_DATA | fallback when no data |

Chaque recommandation contient : `type`, `confidence`, `evidenceCount`, `explanation`.

## 5. Endpoints

| Méthode | Route | Description |
|---|---|---|
| GET | `/ai/global-learning` | Insights globaux (tous tenants) |
| GET | `/ai/global-learning/tenant` | Insights par tenant (tenantId requis) |
| GET | `/ai/global-learning/recommendations` | Recommandations |
| GET | `/ai/global-learning/resolution-effectiveness` | Efficacité des résolutions |

Paramètres communs : `tenantId`, `date_from`, `date_to`

Aucun appel LLM. Aucun coût KBActions.

## 6. Exemple de sortie (données réelles DEV)

```json
{
  "tenantId": "ecomlg-001",
  "period": "all-time",
  "learningSummary": {
    "total": 9,
    "acceptedRate": 0.33,
    "modifiedRate": 0.33,
    "rejectedRate": 0.11,
    "humanOnlyRate": 0.22
  },
  "escalationPatterns": {
    "humanReview": 0,
    "fraudReview": 0,
    "legalReview": 1,
    "supplierReview": 0,
    "total": 1
  },
  "recommendations": [
    {
      "type": "REDUCE_REFUND_FIRST",
      "confidence": 0.78,
      "evidenceCount": 9,
      "explanation": "refund effectiveness is below 50%"
    },
    {
      "type": "ANALYZE_MODIFICATION_PATTERNS",
      "confidence": 0.75,
      "evidenceCount": 3,
      "explanation": "AI modification rate is 33%"
    }
  ]
}
```

## 7. Résultats tests

```
25 PASS / 0 FAIL / 25 TESTS / 54 ASSERTIONS
```

| Test | Description | Résultat |
|---|---|---|
| T1-T2 | Structure globale (sections, source, period) | PASS |
| T3-T4 | Tenant insights (tenantId, sections) | PASS |
| T5 | Rates sum to ~1.0 | PASS |
| T6 | Resolution effectiveness keys | PASS |
| T7 | Escalation patterns structure | PASS |
| T8 | Follow-up burden structure | PASS |
| T9-T10 | Recommendations (array, fields) | PASS |
| T11 | Resolution effectiveness endpoint | PASS |
| T12 | Date filters | PASS |
| T13 | Empty dataset → fallback | PASS |
| T14 | Multi-tenant isolation | PASS |
| T15 | tenantId required validation | PASS |
| T16 | Auth required | PASS |
| T17 | Idempotence | PASS |
| T18 | Global tenantCount | PASS |
| T19-T24 | Non-régression PH90-PH94 + health | PASS |
| T25 | Scores in [0,1] | PASS |

## 8. Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.95-ph94-resolution-cost-optimizer-dev -n keybuzz-api-dev
```

## 9. Fichiers

| Fichier | Action |
|---|---|
| `src/services/globalLearningEngine.ts` | CRÉÉ |
| `src/modules/ai/ai-policy-debug-routes.ts` | MODIFIÉ (4 endpoints PH95) |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | MODIFIÉ |
| `keybuzz-infra/docs/PH95-GLOBAL-LEARNING-ENGINE-REPORT.md` | CRÉÉ |
| `scripts/ph95-tests.sh` | CRÉÉ |
