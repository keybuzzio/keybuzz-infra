# PH82 - Follow-up & Waiting State Engine - Rapport

> Date : 12 mars 2026
> Environnement : DEV
> Image : `v3.5.93-ph82-followup-engine-dev`
> Rollback : `v3.5.92-ph81-human-approval-queue-dev`

---

## Objectif

Creer un moteur de suivi des dossiers SAV dans le temps. PH82 gere les etats d'attente (client, transporteur, fournisseur, retour, remboursement, validation interne) et permet de tracker chaque dossier en cours.

PH82 ne modifie aucun comportement IA. C'est un moteur de workflow et de suivi.

---

## Architecture

### Service
- Fichier : `src/services/followupEngine.ts`
- Fonctions : `computeFollowupState()`, `createFollowupCase()`, `listFollowups()`, `updateFollowupStatus()`, `shouldCreateFollowup()`, `computeFollowupPriority()`, `getFollowupCase()`

### Table DB
```sql
ai_followup_cases (
  id UUID PK,
  tenant_id TEXT NOT NULL,
  conversation_id TEXT NOT NULL,
  order_id TEXT,
  followup_type TEXT NOT NULL,
  followup_reason TEXT,
  status TEXT NOT NULL DEFAULT 'WAITING',
  waiting_for TEXT,
  priority TEXT NOT NULL DEFAULT 'MEDIUM',
  due_at TIMESTAMPTZ,
  metadata JSONB,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
```

### Index
- `idx_afc_tenant` (tenant_id)
- `idx_afc_conv` (conversation_id)
- `idx_afc_status` (status)
- `idx_afc_due` (due_at)

---

## Types de Follow-up (8)

| Type | WaitingFor | DueAt (heures) | Description |
|---|---|---|---|
| WAITING_CUSTOMER | customer | 48h | Client doit fournir info / photo |
| WAITING_CARRIER | carrier | 72h | Enquete transport |
| WAITING_SUPPLIER | supplier | 96h | Dossier fournisseur |
| WAITING_RETURN | customer_return | 168h | Produit en attente de retour |
| WAITING_REFUND_PROCESS | finance | 72h | Remboursement en traitement |
| WAITING_INTERNAL_REVIEW | internal_team | 24h | Validation interne |
| WAITING_ESCALATION | support_team | 24h | Attente equipe support |
| WAITING_EXTERNAL_RESPONSE | marketplace | 96h | Attente marketplace |

---

## Statuts

| Statut | Description |
|---|---|
| OPEN | Cree, pas encore en attente |
| WAITING | En attente active |
| RESOLVED | Resolu |
| CANCELLED | Annule |
| EXPIRED | Expire (due_at depasse) |

---

## Logique de Priorite

| Score | Priorite | Exemples |
|---|---|---|
| >= 35 | CRITICAL | legal_threat (+40), fraud+delivery (+40) |
| >= 20 | HIGH | fraud_high (+30), critical_value (+25), abuse_high (+20) |
| >= 10 | MEDIUM | delivery_investigation (+10), supplier_escalation (+10), high_value (+10) |
| < 10 | LOW | attente client simple, safety_block (+5) |

---

## Creation Automatique

| Situation | Follow-up Type |
|---|---|
| Delivery investigation | WAITING_CARRIER |
| Carrier action active | WAITING_CARRIER |
| Supplier escalation | WAITING_SUPPLIER |
| Warranty process | WAITING_SUPPLIER |
| Return initiated | WAITING_RETURN |
| Refund process | WAITING_REFUND_PROCESS |
| Human review | WAITING_INTERNAL_REVIEW |
| Information required | WAITING_CUSTOMER |
| Marketplace escalation | WAITING_EXTERNAL_RESPONSE |

### Deduplication
Si un followup OPEN/WAITING existe deja pour la meme conversation + type, pas de doublon.

---

## Endpoints

| Method | Route | Description |
|---|---|---|
| GET | `/ai/followups` | Liste avec filtres (tenantId, status, followupType) |
| GET | `/ai/followups/:id` | Detail d'un followup |
| POST | `/ai/followups/simulate` | Simulation DEV |

---

## Integration Pipeline

```
PH77 Execution Audit Trail
PH81 Human Approval Queue
PH82 Follow-up Engine   <-- NOUVEAU
buildSystemPrompt / LLM
PH66 Self Protection
```

PH82 est non-bloquant (fire-and-forget).

---

## Resultats Tests

```
Tests: 18
Assertions: 52
Passed: 52
Failed: 0
ALL PASS
```

### Cas testes
- T1 : Delivery -> WAITING_CARRIER (type, waitingFor, status, dueAt, uuid, created)
- T2 : Supplier escalation -> WAITING_SUPPLIER (type, waitingFor, reason)
- T3 : Information required -> WAITING_CUSTOMER (type, waitingFor, reason)
- T4 : Return action -> WAITING_RETURN (type, waitingFor)
- T5 : Refund process -> WAITING_REFUND_PROCESS (type, waitingFor)
- T6 : Human review -> WAITING_INTERNAL_REVIEW (type, waitingFor)
- T7 : Carrier action -> WAITING_CARRIER
- T8 : Warranty -> WAITING_SUPPLIER (reason)
- T9 : Priority CRITICAL (legal_threat)
- T10 : Priority CRITICAL (fraud + delivery)
- T11 : Priority MEDIUM (delivery only)
- T12 : Priority LOW (information_required)
- T13 : Status WAITING -> RESOLVED
- T14 : Status CANCELLED
- T15 : Status EXPIRED
- T16 : Deduplication (2nd blocked)
- T17 : List filters (count, array, items)
- T18 : No followup + functions existence (7 checks)

---

## Non-regression

| Check | Resultat |
|---|---|
| Health | OK |
| PH82 Followups | count=0 (pret) |
| PH81 Queue | OK |
| PH80 Safety Simulation | PASS 17/17 |
| PH79 Health Monitoring | OK |
| Pipeline IA | Inchange |
| KBActions | Aucun impact |

---

## Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.92-ph81-human-approval-queue-dev -n keybuzz-api-dev
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.92-ph81-human-approval-queue-dev -n keybuzz-api-dev
```
