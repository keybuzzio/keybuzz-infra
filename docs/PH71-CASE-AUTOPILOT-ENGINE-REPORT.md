# PH71 — Case Autopilot Engine

**Date** : 11 mars 2026
**Auteur** : Agent Cursor (CE)
**Environnement** : DEV
**Image** : `v3.5.82-ph71-case-autopilot-dev`

---

## 1. Objectif

Transformer les decisions IA (PH41 - PH70) en actions operationnelles structurees.
PH71 prepare automatiquement les actions metier sans les executer.

---

## 2. Architecture

### Fichier

`src/services/caseAutopilotEngine.ts`

### Fonctions exportees

| Fonction | Role |
|---|---|
| `computeCaseAutopilot(ctx)` | Determine l'action autopilot |
| `buildCaseAutopilotBlock(result)` | Genere le bloc prompt LLM |

---

## 3. Mapping Workflow -> Action

| Workflow Stage | Action Autopilot | Donnees requises |
|---|---|---|
| INFORMATION_REQUIRED | REQUEST_INFORMATION | conversationId, missingFields |
| DELIVERY_INVESTIGATION | OPEN_CARRIER_INVESTIGATION | orderId, trackingNumber, carrier, shippingDate |
| WARRANTY_PROCESS | OPEN_SUPPLIER_CASE | orderId, productSku, supplierId, defectDescription |
| RETURN_PROCESS | INITIATE_RETURN | orderId, returnReason, productCondition |
| REFUND_REVIEW | HUMAN_REVIEW_REFUND | orderId, refundAmount, refundReason, approverRequired |
| FRAUD_REVIEW | ESCALATE_FRAUD_REVIEW | orderId, customerHistory, fraudSignals |
| ESCALATED_CASE | ESCALATE_SUPPORT_TEAM | conversationId, escalationReason, priorityLevel |
| RESOLVED | MARK_RESOLVED | conversationId, resolutionSummary |

---

## 4. Niveaux d'Automatisation

| Niveau | Condition | Exemples |
|---|---|---|
| **MANUAL** | Fraude HIGH, abuse HIGH, valeur CRITICAL, menace legale, REFUND_REVIEW, ESCALATED_CASE, FRAUD_REVIEW | Cas sensibles necessitant validation humaine |
| **ASSISTED** | Livraison, retour, garantie, fraude MEDIUM, valeur HIGH | Cas standards guides par l'IA |
| **AUTOMATIC_READY** | Information simple, cas resolu | Actions executables automatiquement |

### Regles de determination

1. MANUAL si : fraudRisk=HIGH, abuseRisk=HIGH, CRITICAL value, legal threat, FRAUD/ESCALATED/REFUND stages
2. AUTOMATIC_READY si : RESOLVED, INFORMATION_REQUIRED (sans evidence, client non agressif)
3. ASSISTED : tous les autres cas

---

## 5. Position Pipeline

```
PH65 Escalation Intelligence
PH70 Workflow Orchestration Engine
PH71 Case Autopilot Engine  <-- NOUVEAU
PH67 Knowledge Retrieval
PH69 Prompt Stability Guard
PH66 Self-Protection
LLM
```

---

## 6. Bloc Prompt

```
=== CASE AUTOPILOT ENGINE ===
Workflow stage: DELIVERY_INVESTIGATION
Recommended action: OPEN_CARRIER_INVESTIGATION
Automation level: ASSISTED
Required data: orderId, trackingNumber, carrier, shippingDate
Confidence: 0.74

Guidance:
- inform the customer that an investigation is opened
- request confirmation if the parcel was received by neighbor
- do not discuss refund until investigation is complete
=== END CASE AUTOPILOT ENGINE ===
```

---

## 7. Decision Context

```json
{
  "caseAutopilot": {
    "workflowStage": "DELIVERY_INVESTIGATION",
    "action": "OPEN_CARRIER_INVESTIGATION",
    "automationLevel": "ASSISTED",
    "requiredData": ["orderId", "trackingNumber", "carrier", "shippingDate"],
    "confidence": 0.74
  }
}
```

---

## 8. Endpoint Debug

`GET /ai/case-autopilot`

Parametres : `tenantId`, `workflowStage`, `fraudRisk`, `abuseRisk`, `deliveryScenario`, `supplierWarrantyScenario`, `escalationType`, `orderValueCategory`, `customerIntent`, `customerEmotion`, `evidencePresent`, `predictedResolution`

---

## 9. Tests

| Test | Scenario | Resultat | Status |
|---|---|---|---|
| T1 | DELIVERY_INVESTIGATION | OPEN_CARRIER_INVESTIGATION + ASSISTED | PASS |
| T2 | WARRANTY_PROCESS | OPEN_SUPPLIER_CASE + ASSISTED | PASS |
| T3 | FRAUD_REVIEW + fraud HIGH | ESCALATE_FRAUD_REVIEW + MANUAL | PASS |
| T4 | INFORMATION_REQUIRED | REQUEST_INFORMATION + AUTOMATIC_READY | PASS |
| T5 | RESOLVED | MARK_RESOLVED + AUTOMATIC_READY | PASS |
| T6 | fraud HIGH override | MANUAL | PASS |
| T7 | delivery simple | ASSISTED | PASS |
| T8 | information simple | AUTOMATIC_READY | PASS |
| T9 | RETURN_PROCESS | INITIATE_RETURN + ASSISTED | PASS |
| T10 | REFUND_REVIEW | MANUAL | PASS |
| T11 | ESCALATED_CASE | MANUAL | PASS |
| T12 | critical value | MANUAL | PASS |
| T13 | abuse HIGH | MANUAL | PASS |
| T14 | evidence boosts confidence | Verifie | PASS |
| T15 | empty context fallback | INFORMATION_REQUIRED | PASS |
| T16 | block format | Valide | PASS |
| T17 | legal threat intent | MANUAL | PASS |
| T18 | angry + info | ASSISTED | PASS |

**18 tests, 41 assertions, 100% PASS**

---

## 10. Non-Regression

- TypeScript : 0 erreurs
- Pipeline PH41-PH70 : intact
- Aucun appel LLM
- Aucun impact KBActions
- Aucune action externe executee

---

## 11. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.81-ph70-workflow-orchestration-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.81-ph70-workflow-orchestration-dev -n keybuzz-api-dev
```
