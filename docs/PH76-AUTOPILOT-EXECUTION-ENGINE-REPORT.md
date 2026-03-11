# PH76 — Autopilot Safe Execution Layer

> Date : 11 mars 2026
> Environnement : DEV
> Image : `ghcr.io/keybuzzio/keybuzz-api:v3.5.87-ph76-autopilot-execution-dev`
> Rollback : `v3.5.86-ph75-supplier-case-automation-dev`

---

## 1. Objectif

Ajouter un **Autopilot Safe Execution Layer** qui transforme les plans d'action calcules par PH70-PH75 en execution controlee et securisee avec des garde-fous stricts.

PH76 n'autorise l'execution automatique que pour les actions **SAFE_AUTOMATIC**. Toutes les actions sensibles restent en ASSISTED ou MANUAL.

---

## 2. Architecture

### Fichier principal
`src/services/autopilotExecutionEngine.ts`

### Fonctions exportees
- `computeAutopilotExecution(context)` — moteur principal
- `buildAutopilotExecutionBlock(result)` — bloc prompt

### Position pipeline
```
PH75 Supplier Case Automation
PH76 Autopilot Safe Execution Layer   <-- nouveau
PH67 Knowledge Retrieval
PH59 Context Compression
LLM
PH66 Self Protection
```

---

## 3. Niveaux d'execution

| Niveau | Comportement |
|---|---|
| `NONE` | Aucune action automatique (bloque ou non applicable) |
| `SAFE_AUTOMATIC` | IA peut executer seule (action sure) |

---

## 4. Actions SAFE_AUTOMATIC autorisees (5)

| Action | Service cible | Description |
|---|---|---|
| `REQUEST_INFORMATION` | customer_interaction | Demander info/preuve au client |
| `PREPARE_CARRIER_INVESTIGATION` | carrier_service | Preparer investigation transport |
| `PREPARE_RETURN` | return_service | Preparer instructions retour |
| `PREPARE_SUPPLIER_CASE` | supplier_service | Preparer brouillon dossier fournisseur |
| `MARK_CONVERSATION_RESOLVED` | conversation_service | Marquer conversation resolue |

---

## 5. Actions strictement INTERDITES

| Action | Raison |
|---|---|
| `REFUND` | Impact financier |
| `REPLACEMENT` | Cout produit |
| `FRAUD_ESCALATION` | Decision humaine obligatoire |
| `LEGAL_RESPONSE` | Risque juridique |
| `CARRIER_INVESTIGATION_REAL` | Action externe |
| `SUPPLIER_CASE_REAL` | Action externe |
| `RETURN_LABEL_REAL` | Cout logistique |

---

## 6. Regles de securite (6 checks)

| Check | Condition de blocage |
|---|---|
| `fraud_risk_not_high` | fraudRisk === HIGH |
| `abuse_risk_not_high` | abuseRisk === HIGH |
| `order_value_not_critical` | orderValueCategory === critical |
| `no_legal_threat` | customerIntent contient menace juridique |
| `no_fraud_intent` | customerIntent === FRAUD |
| `calibration_not_human_required` | decisionCalibration === HUMAN_REQUIRED |

Si **une seule** condition echoue : `executable = false`.

---

## 7. Endpoint debug

```
GET /ai/autopilot-execution?tenantId=ecomlg-001&workflowStage=INFORMATION_REQUIRED&orderId=ORD-001
```

Reponse :
```json
{
  "executable": true,
  "executionLevel": "SAFE_AUTOMATIC",
  "actionType": "REQUEST_INFORMATION",
  "targetService": "customer_interaction",
  "confidence": 0.80,
  "safetyChecks": [
    {"check": "fraud_risk_not_high", "passed": true},
    {"check": "abuse_risk_not_high", "passed": true},
    {"check": "order_value_not_critical", "passed": true},
    {"check": "no_legal_threat", "passed": true},
    {"check": "no_fraud_intent", "passed": true},
    {"check": "calibration_not_human_required", "passed": true}
  ],
  "executionPlan": {
    "steps": ["identify missing information", "compose request message", "send to customer"],
    "estimatedDuration": "immediate",
    "reversible": true
  }
}
```

---

## 8. Tests

| # | Test | Resultat |
|---|---|---|
| T1 | Information simple | `SAFE_AUTOMATIC` + `REQUEST_INFORMATION` |
| T2 | Colis non recu | `PREPARE_CARRIER_INVESTIGATION` |
| T3 | Produit casse + preuve | `PREPARE_SUPPLIER_CASE` |
| T4 | Retour simple | `PREPARE_RETURN` |
| T5 | Conversation resolue | `MARK_CONVERSATION_RESOLVED` |
| T6 | Fraud HIGH | `executable=false` |
| T7 | Abuse HIGH | `executable=false` |
| T8 | Valeur CRITICAL | `executable=false` |
| T9 | Legal threat | `executable=false` |
| T10 | HUMAN_REQUIRED | `executable=false` |
| T11 | Action REFUND | `forbidden` |
| T12 | Action FRAUD_ESCALATION | `forbidden` |
| T13 | Automation MANUAL | `executable=false` |
| T14 | Pas de workflow | `NONE` |
| T15 | Format bloc prompt | header/footer valides |
| T16 | Structure safety checks | 6 checks, structure correcte |
| T17 | REQUEST_PROOF -> REQUEST_INFO | mapping correct |

**Resultats : 17 tests, 45 assertions, 100% PASS**

---

## 9. Non-regression

- PH41-PH75 intacts
- TypeScript `tsc --noEmit` : 0 erreur
- Pipeline complet PH41-PH76 fonctionnel
- Aucun appel LLM supplementaire
- Aucun impact KBActions
- 100% non destructif

---

## 10. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.86-ph75-supplier-case-automation-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.86-ph75-supplier-case-automation-dev -n keybuzz-api-dev
```
