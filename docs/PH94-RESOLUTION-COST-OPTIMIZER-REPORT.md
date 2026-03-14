# PH94 — Resolution Cost Optimizer — Rapport

> Date : 14 mars 2026
> Auteur : Agent Cursor
> Environnement : DEV
> Image : `v3.5.95-ph94-resolution-cost-optimizer-dev`
> Rollback : `v3.5.94-ph93-customer-patience-dev`

---

## 1. Objectif

Créer un moteur d'optimisation de résolution SAV qui compare plusieurs options et recommande la solution la moins coûteuse compatible avec la policy marketplace, le risque, la réputation client et la logique économique PH90.

## 2. Options évaluées

| Option | Description | Coût type |
|---|---|---|
| REFUND | Remboursement complet | 100% orderAmount |
| REPLACEMENT | Remplacement produit | ~60% orderAmount |
| RETURN | Retour produit | ~15 EUR (frais port) |
| SUPPLIER_WARRANTY | Garantie fournisseur | ~10 EUR |
| CARRIER_INVESTIGATION | Enquête transporteur | ~5 EUR |
| HUMAN_REVIEW | Révision humaine (fallback) | 0 EUR |

## 3. Logique d'arbitrage

Chaque option reçoit :
- `estimatedCost` : coût estimé en EUR
- `allowed` : true/false (blocage si fraude, abus, policy)
- `riskLevel` : LOW / MEDIUM / HIGH / CRITICAL
- `complianceFit` : HIGH / MEDIUM / LOW / BLOCKED
- `economicScore` : 0-1 (basé sur ratio coût/200 EUR)
- `reasoning[]` : explications textuelles

### Règles de blocage

| Condition | Options bloquées |
|---|---|
| Fraude détectée (PH55) | REFUND, REPLACEMENT, RETURN |
| Abus détecté (PH63) | REFUND, REPLACEMENT, RETURN |
| Buyer ABUSIVE_BUYER (PH91) | REFUND, REPLACEMENT, RETURN |
| refundAllowed=false (PH49) | REFUND |
| supplierWarrantyAvailable=false | SUPPLIER_WARRANTY |
| Pas de tracking | CARRIER_INVESTIGATION |
| Scénario non_delivery/delivery_issue | RETURN |

### Sélection optimale

1. Filtrer les options autorisées (hors HUMAN_REVIEW)
2. Trier par economicScore décroissant, puis coût croissant
3. Si aucune option valide → HUMAN_REVIEW

## 4. Entrées utilisées (engines existants)

| Engine | Donnée | Usage |
|---|---|---|
| PH90 Cost Awareness | estimatedCosts, profitabilityRisk | Coûts de base |
| PH91 Buyer Reputation | classification | Blocage si ABUSIVE_BUYER |
| PH92 Marketplace Policy | policyProfile, complianceRisk | Contexte marketplace |
| PH49 Refund Protection | refundAllowed, protectionReason | Blocage refund |
| PH55 Fraud Pattern | fraudDetected | Blocage fraude |
| PH63 Abuse Pattern | abuseDetected | Blocage abus |
| PH50 Merchant Behavior | refundRate, replacementRate | Scoring merchant |

## 5. Position pipeline

```
PH90 Cost Awareness
PH91 Buyer Reputation
PH92 Marketplace Policy
PH93 Customer Patience Predictor
PH94 Resolution Cost Optimizer  ← nouveau
PH64 Resolution Prediction
PH69 Prompt Stability
PH70 Workflow
LLM
```

## 6. Injection prompt

```
=== RESOLUTION COST OPTIMIZER (PH94) ===
Optimal resolution: SUPPLIER_WARRANTY

Evaluated options:
- REFUND: allowed, estimated cost 150.00 EUR
- REPLACEMENT: allowed, estimated cost 90.00 EUR
- RETURN: allowed, estimated cost 15.00 EUR
- SUPPLIER_WARRANTY: allowed, estimated cost 10.00 EUR
- CARRIER_INVESTIGATION: blocked, estimated cost 5.00 EUR
- HUMAN_REVIEW: allowed, estimated cost 0.00 EUR

Guidance:
- supplier warranty is the most cost-effective valid option
- estimated cost: 10.00 EUR
- 1 option(s) blocked: CARRIER_INVESTIGATION
=== END RESOLUTION COST OPTIMIZER ===
```

## 7. Decision context

```json
{
  "resolutionCostOptimizer": {
    "optimalResolution": "SUPPLIER_WARRANTY",
    "confidence": 0.95,
    "optionsEvaluated": 6
  }
}
```

## 8. Endpoint debug

`GET /ai/resolution-cost-optimizer`

Paramètres : `tenantId`, `orderAmount`, `refundAllowed`, `supplierWarrantyAvailable`, `carrierInvestigationPossible`, `savScenario`, `fraudDetected`, `abuseDetected`, `buyerClassification`, `marketplacePolicy`

Aucun appel LLM. Aucun coût KBActions.

## 9. Résultats tests

```
25 PASS / 0 FAIL / 25 TESTS / 36 ASSERTIONS
```

| Test | Description | Résultat |
|---|---|---|
| T1 | Basic — 6 options évaluées | PASS |
| T2 | Warranty disponible → optimal | PASS |
| T3 | Refund bloqué → non sélectionné | PASS |
| T4 | Carrier investigation → optimal | PASS |
| T5 | Fraude → HUMAN_REVIEW | PASS |
| T6 | Abus → HUMAN_REVIEW | PASS |
| T7 | Buyer abusif + high value → HUMAN_REVIEW | PASS |
| T8 | Return < Replacement en score | PASS |
| T9 | Replacement < Refund en coût | PASS |
| T10 | Low value refund autorisé | PASS |
| T11 | Aucune option sûre → HUMAN_REVIEW | PASS |
| T12 | Amazon + warranty → pas REFUND | PASS |
| T13 | Warranty non dispo → non sélectionné | PASS |
| T14 | Return bloqué pour non_delivery | PASS |
| T15 | Confidence variable selon contexte | PASS |
| T16 | Idempotence | PASS |
| T17 | Multi-tenant isolation | PASS |
| T18 | Non-régression /health | PASS |
| T19 | Non-régression /ai/cost-awareness | PASS |
| T20 | Non-régression /ai/buyer-reputation | PASS |
| T21 | Non-régression /ai/marketplace-policy | PASS |
| T22 | Non-régression /ai/customer-patience | PASS |
| T23 | Summary populated | PASS |
| T24 | HUMAN_REVIEW toujours autorisé | PASS |
| T25 | High value + warranty → warranty gagne | PASS |

## 10. Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.94-ph93-customer-patience-dev -n keybuzz-api-dev
```

## 11. Fichiers modifiés

| Fichier | Action |
|---|---|
| `src/services/resolutionCostOptimizer.ts` | CRÉÉ |
| `src/modules/ai/ai-assist-routes.ts` | MODIFIÉ (import, pipeline, prompt, context) |
| `src/modules/ai/ai-policy-debug-routes.ts` | MODIFIÉ (endpoint debug PH94) |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | MODIFIÉ (image tag) |
| `keybuzz-infra/docs/PH94-RESOLUTION-COST-OPTIMIZER-REPORT.md` | CRÉÉ |
| `scripts/ph94-build-deploy.sh` | CRÉÉ |
| `scripts/ph94-tests.sh` | CRÉÉ |
