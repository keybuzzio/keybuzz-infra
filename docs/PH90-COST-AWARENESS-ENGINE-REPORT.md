# PH90 — Cost Awareness Engine — Rapport

> Date : 14 mars 2026
> Image DEV : `v3.5.61-ph90-cost-awareness-dev`
> Rollback : `v3.5.60-channels-billing-secure-dev`
> PROD : non deploye (attente validation)

---

## 1. Objectif

Creer une couche d'aide a la decision economique permettant a l'IA de comparer les options de resolution SAV selon leur cout reel estime.

PH90 ne :
- n'execute aucune action
- ne modifie pas Stripe
- n'appelle pas de LLM
- ne consomme pas de KBActions
- ne modifie pas la DB

---

## 2. Service cree

### `src/services/costAwarenessEngine.ts`

| Fonction | Role |
|----------|------|
| `computeResolutionCostProfile(input)` | Point d'entree principal — calcule le profil de cout complet |
| `computeEstimatedRefundCost(amount)` | Cout estime du remboursement |
| `computeEstimatedReplacementCost(amount, itemCount)` | Cout estime du remplacement |
| `computeEstimatedReturnCost(amount)` | Cout estime du retour |
| `computeEstimatedSupplierWarrantyCost(available)` | Cout estime de la garantie fournisseur |
| `computeEstimatedCarrierInvestigationCost(possible)` | Cout estime de l'enquete transporteur |
| `computeProfitabilityRisk(amount, cost, category)` | Calcul du risque de rentabilite |
| `buildCostAwarenessBlock(result)` | Generation du bloc prompt |
| `computeCostAwarenessFromConversation(tenantId, convId)` | Resolution depuis une conversation (DB) |
| `computeCostAwarenessFromOrder(tenantId, orderId)` | Resolution depuis une commande (DB) |

---

## 3. Logique de cout

### Hypotheses de calcul

| Option | Formule | Composants |
|--------|---------|------------|
| **Refund** | `montant × 1.0 + montant × 0.03` | Remboursement total + frais traitement 3% |
| **Replacement** | `montant × 0.55 + 8€ × items` | Cout produit estime 55% du PV + expedition 8€/item |
| **Return** | `7€ + 3€ + montant × 0.10` | Transport retour + traitement + decote 10% |
| **Supplier Warranty** | `5€ + 7€` | Frais admin + expedition fournisseur |
| **Carrier Investigation** | `0€` | Cout quasi nul |

### Regles de fallback

- Si `orderAmount` absent → `0`, source = `fallback`, promptBlock vide
- Si `currency` absente → `EUR` par defaut
- Si `itemCount` absent → `1` par defaut
- Si `supplierWarrantyAvailable` absent → `false` (non disponible, cout = -1)
- Si `carrierInvestigationPossible` absent → `false` (non applicable, cout = -1)
- Aucune donnee inventee silencieusement

---

## 4. Profitability Risk

| Niveau | Condition |
|--------|-----------|
| `LOW` | Cout recommande < 30% du montant commande |
| `MEDIUM` | Cout recommande 30-60% du montant |
| `HIGH` | Cout recommande 60-90% du montant |
| `CRITICAL` | Cout recommande > 90% du montant, ou valeur critique + ratio > 50% |

---

## 5. Recommended Economic Path

Le moteur classe les options par cout croissant et selectionne la moins chere parmi celles disponibles.

Priorites a cout egal :
1. `CARRIER_INVESTIGATION` (si tracking disponible)
2. `SUPPLIER_WARRANTY` (si fournisseur identifie)
3. `RETURN`
4. `REPLACEMENT`
5. `REFUND`
6. `HUMAN_REVIEW` (si client RISKY ou aucune option)

---

## 6. Integration pipeline

### Position dans le pipeline IA

```
PH41 SAV Policy
PH43 Historical Resolution
PH44 Tenant Policy
PH45 Decision Tree
PH46 Response Strategy
PH47 Customer Risk
PH48 Product Value Awareness
PH49 Refund Protection
PH50 Merchant Behavior
PH51 Learning Signals
PH52 Adaptive Response
PH90 Cost Awareness Engine     ← NOUVEAU
[LLM Call]
```

PH90 est place apres PH52 (Adaptive Response) et avant l'appel LLM car il consolide les signaux de PH47/PH48/PH49/PH50 pour produire une recommandation economique.

### Entrees utilisees

| Source | Donnee |
|--------|--------|
| `orderContext` | totalAmount, currency, itemCount, tracking |
| `orderValueAwareness` (PH48) | category (LOW/MEDIUM/HIGH/CRITICAL) |
| `customerRiskResult` (PH47) | category (TRUSTED/NORMAL/WATCH/RISKY) |
| `refundProtectionResult` (PH49) | refundAllowed |
| `merchantBehaviorResult` (PH50) | refundRate, replacementRate, warrantyRate |
| `supplierCtx` | presence d'un dossier fournisseur |

### Sorties

1. **`decisionContext.costAwareness`** — Objet structure dans le contexte de decision
2. **`costAwarenessPromptBlock`** — Bloc injecte dans le prompt systeme
3. **Logs** — `[AI Assist] PH90 CostAwareness: path:X risk:Y refund:Z confidence:C src:S`

---

## 7. Endpoint debug

```
GET /ai/cost-awareness?tenantId=xxx&conversationId=yyy
GET /ai/cost-awareness?tenantId=xxx&orderId=zzz
GET /ai/cost-awareness?tenantId=xxx&orderAmount=120
```

Aucun appel LLM. Aucun cout KBActions.

### Exemple de reponse

```json
{
  "tenantId": "ecomlg-001",
  "orderAmount": 120,
  "currency": "EUR",
  "estimatedCosts": {
    "refund": 123.6,
    "replacement": 74,
    "return": 22,
    "supplierWarranty": -1,
    "carrierInvestigation": -1
  },
  "recommendedEconomicPath": "RETURN",
  "profitabilityRisk": "MEDIUM",
  "confidence": 0.77,
  "reasoning": [
    "remboursement est loption la plus couteuse",
    "RETURN est loption la plus economique (22.00 EUR)",
    "economie de 52.00 EUR par rapport a REPLACEMENT"
  ],
  "source": "partial"
}
```

---

## 8. Resultats des tests

### Tests PH90 : 52/52 PASS

| # | Test | Assertions | Resultat |
|---|------|------------|----------|
| T1 | Low value (15 EUR) | 3 | PASS |
| T2 | High value (500 EUR) | 4 | PASS |
| T3 | Supplier warranty dispo | 3 | PASS |
| T4 | Carrier investigation dispo | 3 | PASS |
| T5 | Replacement vs Refund | 3 | PASS |
| T6 | Return breakdown | 3 | PASS |
| T7 | Devise EUR | 2 | PASS |
| T8 | Devise manquante → fallback | 2 | PASS |
| T9 | Montant absent → fallback | 3 | PASS |
| T10 | Client RISKY → HUMAN_REVIEW | 2 | PASS |
| T11 | Profitability risk levels | 3 | PASS |
| T12 | Prompt block generation | 4 | PASS |
| T13 | Non-regression endpoints | 2 | PASS |
| T14 | Non-regression channels/billing | 2 | PASS |
| T15 | Debug endpoint conversationId | 3 | PASS |
| T16 | Multi-tenant isolation | 2 | PASS |
| T17 | Idempotence | 3 | PASS |
| T18 | Fallback (no order) | 3 | PASS |
| T19 | Missing tenantId → 400 | 1 | PASS |
| T20 | Missing params → 400 | 1 | PASS |
| **Total** | **20 tests** | **52 assertions** | **52/52** |

### Audit Stripe DEV : 14/14 PASS

---

## 9. Non-regression

Verifie intact :
- `/health` → 200
- `/ai/assist/status` → 200
- `/channels/billing-compute` → 200
- Audit Stripe 14/14
- Pas de modification DB
- Pas de modification Stripe
- PH41-PH85 non impactes

---

## 10. Rollback

```bash
kubectl set image deployment/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.60-channels-billing-secure-dev \
  -n keybuzz-api-dev
kubectl rollout restart deployment/keybuzz-api -n keybuzz-api-dev
```

Aucune migration DB a reverter (PH90 ne cree pas de table).
