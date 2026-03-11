# PH70 — Workflow / Case Orchestration Engine

**Date** : 11 mars 2026
**Auteur** : Agent Cursor (CE)
**Environnement** : DEV
**Image** : `v3.5.81-ph70-workflow-orchestration-dev`

---

## 1. Objectif

Transformer KeyBuzz d'un moteur de reponse IA en moteur de gestion de dossier SAV intelligent.
PH70 analyse tous les signaux du pipeline (PH41-PH69) et determine :

- L'etape actuelle du dossier SAV (workflowStage)
- L'action recommandee suivante (recommendedNextAction)
- Le proprietaire recommande (recommendedOwner)
- Le delai recommande (recommendedDelay)
- Le score de confiance (confidence)

PH70 ne declenche **aucune action externe reelle**.

---

## 2. Architecture

### Fichier cree

`src/services/workflowOrchestrationEngine.ts`

### Fonctions exportees

| Fonction | Role |
|---|---|
| `computeWorkflowState(ctx)` | Calcule l'etat du workflow SAV |
| `buildWorkflowOrchestrationBlock(result)` | Genere le bloc prompt pour le LLM |

### Types exportes

| Type | Description |
|---|---|
| `WorkflowStage` | 8 etats possibles du dossier |
| `RecommendedAction` | 8 actions recommandees |
| `RecommendedOwner` | 5 types de proprietaires |
| `RecommendedDelay` | 4 niveaux de delai |
| `WorkflowOrchestrationContext` | Inputs du moteur |
| `WorkflowOrchestrationResult` | Output complet |

---

## 3. Etats du Workflow SAV

| Etape | Action | Proprietaire | Delai |
|---|---|---|---|
| `INFORMATION_REQUIRED` | `REQUEST_INFORMATION` | `ai_copilot` | immediate |
| `DELIVERY_INVESTIGATION` | `INVESTIGATE_DELIVERY` | `support_agent` | immediate |
| `WARRANTY_PROCESS` | `OPEN_SUPPLIER_CASE` | `supplier_team` | within_24h |
| `RETURN_PROCESS` | `INITIATE_RETURN` | `support_agent` | within_1h |
| `REFUND_REVIEW` | `HUMAN_REVIEW_REFUND` | `senior_agent` | within_1h |
| `FRAUD_REVIEW` | `ESCALATE_FRAUD_REVIEW` | `fraud_team` | immediate |
| `ESCALATED_CASE` | `ESCALATE_SUPPORT_TEAM` | `senior_agent` | immediate |
| `RESOLVED` | `MARK_RESOLVED` | `ai_copilot` | next_business_day |

---

## 4. Logique de Scoring

### Signaux et poids

| Signal | Poids | Source |
|---|---|---|
| DecisionTree | 0.25 | PH45 |
| ResolutionPrediction | 0.20 | PH64 |
| DeliveryIntelligence | 0.15 | PH56 |
| WarrantyIntelligence | 0.15 | PH57 |
| FraudPattern | 0.15 | PH55 |
| ConversationMemory | 0.10 | PH58 |

### Signaux additionnels (boosters)

- Escalation type/severity (PH65)
- Customer intent (PH54)
- Customer emotion (PH68)
- Evidence presence/level (PH62)
- Order value category
- Abuse pattern (PH63)

### Mecanisme

1. Chaque signal contribue au score de un ou plusieurs etats
2. Les scores sont ponderes selon la confiance et la disponibilite du signal
3. L'etat avec le score le plus eleve est selectionne
4. Si aucun score > 0.10 : fallback vers `INFORMATION_REQUIRED`
5. La confiance est normalisee entre 0.20 et 0.98

---

## 5. Position Pipeline

```
PH41 SAV Policy
PH44 Tenant Policy
PH43 Historical Engine
PH45 Decision Tree
PH46 Response Strategy
PH49 Refund Protection
PH50 Merchant Behavior
PH52 Adaptive Response
PH53 Customer Tone
PH54 Customer Intent
PH68 Customer Emotion
PH55 Fraud Pattern
PH60 Decision Calibration
PH61 Marketplace Intelligence
PH62 Evidence Intelligence
PH63 Abuse Pattern
PH64 Resolution Prediction
PH65 Escalation Intelligence
PH70 Workflow Orchestration Engine  <-- NOUVEAU
PH67 Knowledge Retrieval
PH69 Prompt Stability Guard
PH66 Self-Protection
```

---

## 6. Bloc Prompt

```
=== WORKFLOW ORCHESTRATION ENGINE ===
Current case stage: DELIVERY_INVESTIGATION
Recommended next action: INVESTIGATE_DELIVERY
Confidence: 0.74
Recommended owner: support_agent
Recommended delay: immediate

Guidance:
- focus on resolving the delivery issue
- request confirmation from the customer if the parcel might have been delivered to a neighbour
- avoid refund discussion before investigation is completed
=== END WORKFLOW ORCHESTRATION ENGINE ===
```

---

## 7. Decision Context

```json
{
  "workflow": {
    "stage": "DELIVERY_INVESTIGATION",
    "nextAction": "INVESTIGATE_DELIVERY",
    "recommendedOwner": "support_agent",
    "recommendedDelay": "immediate",
    "confidence": 0.74
  }
}
```

---

## 8. Endpoint Debug

`GET /ai/workflow-state`

Parametres : `tenantId`, `conversationId`, `decisionTreeScenario`, `predictedResolution`, `deliveryScenario`, `supplierWarrantyScenario`, `fraudRisk`, `abuseRisk`, `escalationType`, `customerIntent`, `customerEmotion`, `evidencePresent`

Aucun appel LLM. Aucun debit KBActions.

---

## 9. Tests

| Test | Scenario | Resultat attendu | Status |
|---|---|---|---|
| T1 | Colis non recu | DELIVERY_INVESTIGATION | PASS |
| T2 | Produit casse avec preuve | WARRANTY_PROCESS | PASS |
| T3 | Remboursement demande | REFUND_REVIEW | PASS |
| T4 | Menace juridique + agressif | ESCALATED_CASE | PASS |
| T5 | Fraud HIGH + abuse HIGH | FRAUD_REVIEW | PASS |
| T6 | Retour simple | RETURN_PROCESS | PASS |
| T7 | Information manquante | INFORMATION_REQUIRED | PASS |
| T8 | Confirmation client | RESOLVED | PASS |
| T9 | Delivered customer claims | DELIVERY_INVESTIGATION | PASS |
| T10 | Garantie fournisseur | WARRANTY_PROCESS | PASS |
| T11 | Haute valeur + refund | REFUND_REVIEW | PASS |
| T12 | Contexte vide | INFORMATION_REQUIRED (fallback) | PASS |
| T13 | Fraud MEDIUM + abuse HIGH | FRAUD_REVIEW | PASS |
| T14 | Defect sans evidence | INFORMATION_REQUIRED | PASS |
| T15 | Format bloc prompt | Valide | PASS |
| T16 | Signals toujours remplis | Non vide | PASS |

**16 tests, 45 assertions, 100% PASS**

---

## 10. Non-Regression

- TypeScript : `npx tsc --noEmit` = 0 erreurs
- Pipeline PH41-PH69 : intact
- Aucun appel LLM supplementaire
- Aucun impact KBActions
- Aucune modification DB
- Aucune action externe

---

## 11. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.80-ph69-prompt-stability-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.80-ph69-prompt-stability-dev -n keybuzz-api-dev
```
