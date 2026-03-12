# PH81 - Human Approval Queue Engine - Rapport

> Date : 12 mars 2026
> Environnement : DEV
> Image : `v3.5.92-ph81-human-approval-queue-dev`
> Rollback : `v3.5.91-ph80-safety-simulation-v4-dev`

---

## Objectif

Creer une file de validation humaine structuree pour tous les cas que l'IA ne doit pas traiter seule. PH81 transforme les sorties de PH65 (Escalation), PH70 (Workflow), PH71 (Autopilot), PH72 (Action Execution) et PH76 (Safety) en entrees de queue priorisees.

PH81 ne modifie aucun comportement IA. C'est une couche d'orchestration humaine.

---

## Architecture

### Service
- Fichier : `src/services/humanApprovalQueueEngine.ts`
- Fonctions : `buildHumanApprovalEntry()`, `enqueueHumanApproval()`, `listHumanApprovalQueue()`, `computeApprovalPriority()`, `shouldCreateApprovalEntry()`, `getApprovalEntry()`, `updateApprovalStatus()`

### Table DB
```sql
ai_human_approval_queue (
  id UUID PK,
  tenant_id TEXT NOT NULL,
  conversation_id TEXT NOT NULL,
  order_ref TEXT,
  queue_type TEXT NOT NULL,
  queue_status TEXT NOT NULL DEFAULT 'OPEN',
  priority TEXT NOT NULL DEFAULT 'MEDIUM',
  recommended_action TEXT,
  recommended_owner TEXT,
  reason TEXT,
  risk_summary JSONB,
  decision_context JSONB,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
```

### Index
- `idx_ahaq_tenant` (tenant_id)
- `idx_ahaq_conv` (conversation_id)
- `idx_ahaq_order` (order_ref)
- `idx_ahaq_status` (queue_status)
- `idx_ahaq_priority` (priority)
- `idx_ahaq_created` (created_at)

---

## Types de Queue (8)

| Type | Description |
|---|---|
| REFUND_REVIEW | Remboursement necessitant validation |
| FRAUD_REVIEW | Cas fraude / abus eleve |
| LEGAL_REVIEW | Menace juridique / risque legal |
| HIGH_VALUE_REVIEW | Produit haute / critique valeur |
| SUPPLIER_REVIEW | Dossier fournisseur sensible |
| DELIVERY_REVIEW | Litige livraison sensible |
| MARKETPLACE_REVIEW | Cas marketplace risque |
| GENERAL_HUMAN_REVIEW | Revue humaine standard |

---

## Statuts

| Statut | Description |
|---|---|
| OPEN | Entree creee, en attente |
| IN_REVIEW | En cours d'examen |
| APPROVED | Approuvee |
| REJECTED | Rejetee |
| CLOSED | Fermee |

---

## Logique de Priorite

| Score | Priorite | Exemples |
|---|---|---|
| >= 35 | CRITICAL | LEGAL_THREAT, LEGAL_ESCALATION, fraud_high + critical_value |
| >= 20 | HIGH | HUMAN_REVIEW, SUPPLIER_ESCALATION, high_value |
| >= 10 | MEDIUM | refund_review, safety_blocked |
| < 10 | LOW | manual_execution simple |

### Signaux pris en compte
- `customerIntent = LEGAL_THREAT` : +40
- `escalationType = LEGAL_ESCALATION` : +35
- `fraudRisk = HIGH` : +30
- `abuseRisk = HIGH` : +25
- `orderValueCategory = CRITICAL` : +25
- `escalationType = FRAUD_INVESTIGATION` : +20
- `escalationType = SUPPLIER_ESCALATION` : +15
- `escalationType = HUMAN_REVIEW` : +10
- `safetyBlockReason` present : +10
- `decisionPrediction = REFUND` : +10
- `orderValueCategory = HIGH` : +10
- `executionLevel = MANUAL` : +5

---

## Regles de Creation d'Entree

Une entree est creee si au moins une condition :
1. `executionLevel = MANUAL`
2. `escalationType != NONE`
3. `safetyLevel = REVIEW_REQUIRED`
4. `fraudRisk = HIGH`
5. `abuseRisk = HIGH`
6. `orderValueCategory = CRITICAL_VALUE` ou `CRITICAL`
7. `customerIntent = LEGAL_THREAT`

### Deduplication
Si une entree OPEN existe deja pour la meme `conversation_id` + `queue_type`, pas de doublon.

---

## Endpoints

| Method | Route | Description |
|---|---|---|
| GET | `/ai/human-approval-queue` | Liste avec filtres (tenantId, status, priority, type) |
| GET | `/ai/human-approval-queue/:id` | Detail d'une entree |
| POST | `/ai/human-approval-queue/simulate` | Simulation DEV |
| POST | `/ai/human-approval-queue/:id/status` | Mise a jour statut |

---

## Integration Pipeline

```
PH76 Autopilot Safety
PH77 Execution Audit Trail
PH81 Human Approval Queue   <-- NOUVEAU
PH67 Knowledge Retrieval
buildSystemPrompt
LLM
PH66 Self Protection
```

PH81 est non-bloquant (fire-and-forget) et ne modifie pas le prompt LLM.

---

## Resultats Tests

```
Tests: 18
Assertions: 51
Passed: 51
Failed: 0
ALL PASS
```

### Cas testes
- T1 : Refund review (REFUND_REVIEW, OPEN, enqueue)
- T2 : Fraud high (FRAUD_REVIEW, HIGH+, REVIEW_FRAUD_EVIDENCE)
- T3 : Legal threat (LEGAL_REVIEW, CRITICAL, team_lead)
- T4 : Critical value (HIGH_VALUE_REVIEW, SENIOR_AGENT_REVIEW)
- T5 : Supplier review (SUPPLIER_REVIEW, supplier_team)
- T6 : Delivery review (DELIVERY_REVIEW, INVESTIGATE_DELIVERY)
- T7 : Marketplace review (MARKETPLACE_REVIEW, REVIEW_MARKETPLACE_CASE)
- T8 : General human review (GENERAL_HUMAN_REVIEW, HUMAN_REVIEW)
- T9 : Deduplication (2nd entry blocked)
- T10 : List filter tenant (count, items, array)
- T11 : List filter CRITICAL priority
- T12 : Status OPEN -> IN_REVIEW
- T13 : Status IN_REVIEW -> APPROVED
- T14 : Status -> CLOSED
- T15 : decisionContext + riskSummary JSONB
- T16 : No approval for safe context
- T17 : Functions existence (6 functions)
- T18 : Simulate flow end-to-end

---

## Non-regression

| Check | Resultat |
|---|---|
| Health | OK |
| PH80 Safety Simulation | PASS 17/17 |
| PH79 Health Monitoring | OK |
| PH81 Queue endpoint | OK |
| Pipeline IA | Inchange |
| KBActions | Aucun impact |

---

## Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.91-ph80-safety-simulation-v4-dev -n keybuzz-api-dev
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.91-ph80-safety-simulation-v4-dev -n keybuzz-api-dev
```
