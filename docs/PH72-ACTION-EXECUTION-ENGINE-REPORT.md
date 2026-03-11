# PH72 — Action Execution Engine

> Date : 1er mars 2026
> Auteur : Agent Cursor (CE)
> Environnement : DEV uniquement (PROD sur validation Ludovic)

---

## 1. Objectif

PH72 transforme les recommandations du Case Autopilot Engine (PH71) en **plans d'action opérationnels structurés**. Il produit un `actionExecutionPlan` contenant :

- L'action concrète à exécuter
- Le service cible
- Les données requises et manquantes
- Le niveau d'automatisation
- Le niveau de sécurité
- La prochaine étape

PH72 ne déclenche **aucune action réelle** — il prépare uniquement le plan.

---

## 2. Architecture

### Fichier créé
- `src/services/actionExecutionEngine.ts` (~320 lignes)

### Fonctions exportées
- `computeActionExecutionPlan(context)` — calcul du plan d'action
- `buildActionExecutionBlock(result)` — formatage pour injection dans le prompt LLM

---

## 3. Catalogue d'actions (12 actions standardisées)

| Action | Service cible | Prochaine étape |
|---|---|---|
| `OPEN_CARRIER_INVESTIGATION` | carrier_service | WAIT_CARRIER_RESPONSE |
| `REQUEST_CUSTOMER_INFORMATION` | customer_interaction | WAIT_CUSTOMER_RESPONSE |
| `INITIATE_RETURN` | return_service | WAIT_CUSTOMER_RESPONSE |
| `OPEN_SUPPLIER_CASE` | supplier_service | WAIT_SUPPLIER_RESPONSE |
| `ESCALATE_SUPPORT_TEAM` | internal_support | WAIT_HUMAN_REVIEW |
| `ESCALATE_FRAUD_REVIEW` | fraud_team | WAIT_HUMAN_REVIEW |
| `PREPARE_REFUND_REVIEW` | billing_service | WAIT_HUMAN_REVIEW |
| `SEND_TRACKING_INFORMATION` | customer_interaction | MONITOR |
| `REQUEST_PROOF_PHOTOS` | customer_interaction | WAIT_PROOF_UPLOAD |
| `CONFIRM_DELIVERY` | customer_interaction | CLOSE_CASE |
| `MARK_CASE_RESOLVED` | conversation_service | CLOSE_CASE |
| `CREATE_INTERNAL_TASK` | internal_workflow | MONITOR |

---

## 4. Niveaux de sécurité

| Niveau | Description | Déclencheurs |
|---|---|---|
| `SAFE` | Action sans risque | Livraison, info, tracking |
| `REVIEW_REQUIRED` | Validation humaine requise | Remboursement, valeur critique, escalation |
| `RESTRICTED` | Action bloquée | Fraude HIGH, abus HIGH, cas critique |

---

## 5. Niveaux d'automatisation

| Niveau | Description | Cas |
|---|---|---|
| `MANUAL` | Intervention humaine obligatoire | RESTRICTED, REVIEW_REQUIRED |
| `ASSISTED` | Assistance IA avec validation agent | Livraison, retour, garantie |
| `AUTOMATIC_READY` | Prêt pour automatisation complète | Résolu, info simple |

---

## 6. Détection des données manquantes

Le moteur vérifie automatiquement la disponibilité de :
- `orderId`, `trackingNumber`, `carrier`
- `supplierId`, `photosAttached`
- `refundAmount`

Les données absentes sont listées dans `missingData[]`.

---

## 7. Position dans le pipeline IA

```
PH41 SAV Policy → ... → PH65 Escalation Intelligence
PH70 Workflow Orchestration
PH71 Case Autopilot
PH72 Action Execution Engine  ← NOUVEAU
PH67 Knowledge Retrieval → ... → PH59 Context Compression → LLM
PH66 Self Protection
```

---

## 8. Intégration

### ai-assist-routes.ts
- Import de `computeActionExecutionPlan`, `buildActionExecutionBlock`
- Exécution après PH71, avant PH67
- Injection dans `buildSystemPrompt()` via `actionExecutionBlock`
- Ajout dans `decisionContext.actionExecutionPlan`

### ai-policy-debug-routes.ts
- Endpoint `GET /ai/action-execution`
- `pipelineOrder` mis à jour (inclut PH72)
- `pipelineLayers.actionExecution: true`
- `finalPromptSections` inclut `ACTION_EXECUTION_ENGINE`

---

## 9. Endpoint debug

```
GET /ai/action-execution?tenantId=ecomlg-001&workflowStage=DELIVERY_INVESTIGATION
```

Réponse :
```json
{
  "actionType": "OPEN_CARRIER_INVESTIGATION",
  "automationLevel": "ASSISTED",
  "requiredData": ["orderId", "trackingNumber", "carrier", "shippingDate"],
  "missingData": ["trackingNumber"],
  "targetService": "carrier_service",
  "safetyLevel": "SAFE",
  "nextStep": "WAIT_CARRIER_RESPONSE",
  "confidence": 0.50,
  "guidance": [...]
}
```

---

## 10. Résultats des tests

| Métrique | Résultat |
|---|---|
| Tests | **18** |
| Assertions | **38** |
| Passed | **38** |
| Failed | **0** |
| TypeScript | **0 erreur** |

### Détail des tests
| # | Scénario | Résultat attendu | Status |
|---|---|---|---|
| T1 | Delivery investigation | OPEN_CARRIER_INVESTIGATION | PASS |
| T2 | Information manquante | REQUEST_CUSTOMER_INFORMATION | PASS |
| T3 | Warranty sans preuve | REQUEST_PROOF_PHOTOS | PASS |
| T4 | Warranty avec preuve | OPEN_SUPPLIER_CASE | PASS |
| T5 | Fraude HIGH | ESCALATE_FRAUD_REVIEW + RESTRICTED + MANUAL | PASS |
| T6 | Abus HIGH | ESCALATE_FRAUD_REVIEW + RESTRICTED | PASS |
| T7 | Refund review | PREPARE_REFUND_REVIEW + REVIEW_REQUIRED | PASS |
| T8 | Résolu | MARK_CASE_RESOLVED + AUTOMATIC_READY | PASS |
| T9 | Retour | INITIATE_RETURN | PASS |
| T10 | Cas escaladé | ESCALATE_SUPPORT_TEAM | PASS |
| T11 | Menace juridique | ESCALATE_SUPPORT_TEAM | PASS |
| T12 | Livraison confirmée | CONFIRM_DELIVERY | PASS |
| T13 | Données manquantes | missingData détecté | PASS |
| T14 | Fraude medium | REVIEW_REQUIRED | PASS |
| T15 | Info + défaut intent | REQUEST_PROOF_PHOTOS | PASS |
| T16 | Confiance + evidence | confidence > 0.80 | PASS |
| T17 | Format bloc prompt | Header/footer présents | PASS |
| T18 | Info simple → AUTOMATIC_READY | automationLevel correct | PASS |

---

## 11. Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.82-ph71-case-autopilot-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

---

## 12. Tags images

| Env | Tag |
|---|---|
| DEV | `v3.5.83-ph72-action-execution-dev` |
| Rollback | `v3.5.82-ph71-case-autopilot-dev` |
