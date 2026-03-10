# PH65 — Escalation Intelligence Engine

> Date : 2026-03-01
> Phase : PH65
> Environnement : DEV

---

## Objectif

Determiner quand une conversation SAV doit etre escaladee vers un humain, un fournisseur ou un processus specifique. Le moteur guide la decision finale sans modifier la reponse IA.

---

## Types d'escalade (8)

| Type | Description | Severite typique |
|------|-------------|-----------------|
| `NONE` | L'IA peut repondre seule | LOW |
| `HUMAN_REVIEW` | Validation humaine recommandee | MEDIUM-HIGH |
| `SUPPLIER_ESCALATION` | Transfert au fournisseur | LOW |
| `MARKETPLACE_ESCALATION` | Cas sensible marketplace | MEDIUM-HIGH |
| `REFUND_REVIEW` | Remboursement necessitant validation | MEDIUM-HIGH |
| `FRAUD_INVESTIGATION` | Risque fraude eleve | HIGH-CRITICAL |
| `LEGAL_ESCALATION` | Menace juridique | CRITICAL |
| `CRITICAL_CASE` | Cas critique haute valeur | CRITICAL |

---

## Regles d'escalade

| # | Condition | Escalation | Severite |
|---|-----------|-----------|----------|
| R1 | `fraudRisk = HIGH/CRITICAL` | FRAUD_INVESTIGATION | HIGH/CRITICAL |
| R2 | Intent contient legal/avocat/tribunal | LEGAL_ESCALATION | CRITICAL |
| R3 | `orderValue > 300 + predicted REFUND` | REFUND_REVIEW | HIGH |
| R4 | Delivery conflict (livre mais client dit non recu) | MARKETPLACE_ESCALATION | MEDIUM/HIGH |
| R5 | Warranty eligible avec preuve | SUPPLIER_ESCALATION | LOW |
| R6 | `abuseRisk = HIGH` | HUMAN_REVIEW | HIGH |
| R7 | `orderValue > 300 + fraudRisk MEDIUM` | CRITICAL_CASE | CRITICAL |
| R8 | `decisionLevel = HUMAN_REQUIRED` | HUMAN_REVIEW | MEDIUM |
| R9 | `fraudRisk MEDIUM + abuseRisk MEDIUM` | HUMAN_REVIEW | MEDIUM |

### Priorite

Quand plusieurs regles s'appliquent, la severite la plus haute gagne. A severite egale, la confidence la plus elevee prevaut.

Ordre : CRITICAL > HIGH > MEDIUM > LOW

---

## Donnees utilisees

| Source | Champ |
|--------|-------|
| PH64 Resolution Prediction | predictedResolution, confidence |
| PH55 Fraud Pattern | fraudRisk |
| PH54 Customer Intent | intent |
| PH48 Product Value | orderValue, orderValueCategory |
| PH47 Customer Risk | customerRiskCategory |
| PH56 Delivery Intelligence | deliveryScenario |
| PH57 Supplier/Warranty | supplierWarrantyScenario |
| PH63 Abuse Pattern | abuseRisk |
| PH50 Merchant Behavior | category |
| PH60 Decision Calibration | level, refundAllowed, escalationRecommended |
| PH61 Marketplace Intelligence | marketplace, escalationRisk |
| PH62 Evidence Intelligence | evidencePresent |
| PH49 Refund Protection | refundAllowed |

---

## Position dans le pipeline

```
PH64 Resolution Prediction
PH65 Escalation Intelligence  <-- nouveau
const messages (buildSystemPrompt)
```

### Prompt block

```
=== ESCALATION INTELLIGENCE ===
Escalation: HUMAN_REVIEW
Severity: HIGH

Reasons:
- abuse_pattern_high
- customer_risk_elevated

Recommended action:
Review case manually due to abuse pattern.
=== END ESCALATION INTELLIGENCE ===
```

### decisionContext

```json
{
  "escalationIntelligence": {
    "escalationType": "HUMAN_REVIEW",
    "severity": "HIGH",
    "confidence": 0.85,
    "reasons": ["abuse_pattern_high", "customer_risk_elevated"]
  }
}
```

---

## Endpoint debug

`GET /ai/escalation-intelligence?tenantId=xxx&fraudRisk=HIGH&orderValue=500`

- Aucun appel LLM
- Aucun debit KBActions

---

## Tests

15 tests, 31 assertions — tous passes.

| Test | Scenario | Attendu | Resultat |
|------|----------|---------|----------|
| T1 | Fraud HIGH | FRAUD_INVESTIGATION HIGH | PASS |
| T2 | Fraud CRITICAL + high value | FRAUD_INVESTIGATION CRITICAL | PASS |
| T3 | Legal threat | LEGAL_ESCALATION CRITICAL | PASS |
| T4 | Critical value + refund | REFUND_REVIEW HIGH | PASS |
| T5 | Delivery conflict Amazon | MARKETPLACE_ESCALATION HIGH | PASS |
| T6 | Warranty eligible + proof | SUPPLIER_ESCALATION LOW | PASS |
| T7 | Abuse HIGH | HUMAN_REVIEW HIGH | PASS |
| T8 | Normal case | NONE | PASS |
| T9 | Critical value + fraud MEDIUM | CRITICAL_CASE CRITICAL | PASS |
| T10 | Calibration HUMAN_REQUIRED | HUMAN_REVIEW | PASS |
| T11 | Fraud MEDIUM + abuse MEDIUM | HUMAN_REVIEW | PASS |
| T12 | High value + refund blocked | REFUND_REVIEW | PASS |
| T13 | Empty context | NONE | PASS |
| T14 | Priority fraud CRITICAL > abuse | FRAUD_INVESTIGATION | PASS |
| T15 | Structure validation | All fields | PASS |

---

## Non-regression

- Zero appel LLM supplementaire
- Zero impact KBActions
- Zero action automatique
- Compilation TypeScript : zero erreur
- PH41-PH64 : intacts

---

## Fichiers modifies

| Fichier | Modification |
|---------|-------------|
| `src/services/escalationIntelligenceEngine.ts` | **CREE** — moteur d'escalade |
| `src/modules/ai/ai-assist-routes.ts` | Import + invocation + prompt + decisionContext |
| `src/modules/ai/ai-policy-debug-routes.ts` | Endpoint debug |

---

## Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.74-ph64-resolution-prediction-dev -n keybuzz-api-dev
```

---

## Image DEV

- Tag : `v3.5.75-ph65-escalation-intelligence-dev`
- Rollback : `v3.5.74-ph64-resolution-prediction-dev`
