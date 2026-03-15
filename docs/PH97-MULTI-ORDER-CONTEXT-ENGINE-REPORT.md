# PH97 — Multi-Order Context Engine

> Date : 15 mars 2026
> Environnement : DEV (v3.5.98-ph97-multi-order-context-dev)
> Rollback : v3.5.97-ph96-seller-dna-dev

---

## 1. Objectif

Detecter les patterns de fraude et d'abus multi-commande en analysant le comportement d'un client
a travers plusieurs commandes sur une fenetre de 90 jours.

## 2. Service

**Fichier** : `src/services/multiOrderContextEngine.ts`

### Fonctions

| Fonction | Role |
|---|---|
| `computeMultiOrderContext(tenantId, buyerHandle, conversationId?)` | Point d'entree principal |
| `detectCrossOrderPatterns(orders, conversations)` | Detection des 10 signaux |
| `computeOrderClusterRisk(signalCount)` | Scoring et classification |
| `buildMultiOrderContextBlock(result)` | Generation du bloc prompt |

## 3. Sources de donnees

- `orders` : commandes du client (via `customer_email` ou `buyer_name`)
- `conversations` : conversations liees (via `customer_handle` ou `order_ref`)
- `messages` : dernier message inbound pour analyse textuelle

Fenetre : 90 jours, limite 50 commandes + 50 conversations.

## 4. Signaux detectes (10)

| Signal | Condition |
|---|---|
| `multi_order_non_delivery` | >= 2 commandes avec plainte "non recu" |
| `multi_order_refund_pattern` | >= 2 demandes remboursement sur commandes differentes |
| `repeated_defect_claims` | >= 2 commandes avec plainte "defectueux" |
| `cluster_complaint_spike` | >= 3 plaintes en < 14 jours |
| `multi_marketplace_pattern` | plaintes sur >= 2 marketplaces differentes |
| `high_value_cluster` | >= 2 commandes >= 150 EUR avec plainte |
| `fast_repeat_orders` | >= 2 commandes avec plainte dans les 7 jours |
| `mixed_claim_instability` | >= 2 types de plainte differents + >= 3 conversations |
| `delivery_claim_conflict` | >= 2 commandes marquees livrees mais client dit non recu |
| `refund_pressure_multi_order` | >= 2 order refs + >= 3 conversations avec pression remboursement |

## 5. Scoring

| Signaux | Score | Niveau |
|---|---|---|
| 0 | 0.00 | LOW |
| 1 | 0.20 | LOW |
| 2 | 0.40 | MEDIUM |
| 3-4 | 0.60-0.80 | HIGH |
| 5+ | 0.85+ | CRITICAL |

## 6. Structure de sortie

```json
{
  "ordersAnalyzed": 5,
  "conversationsAnalyzed": 3,
  "multiOrderRiskScore": 0.62,
  "riskLevel": "HIGH",
  "signals": ["multi_order_non_delivery", "refund_pressure_multi_order"],
  "ordersInvolved": ["405-4867060-5480332", "402-0451681-3086763"],
  "guidance": [
    "avoid immediate refund — investigate first",
    "cross-reference delivery proof across orders"
  ],
  "promptBlock": "=== MULTI-ORDER CONTEXT ENGINE (PH97) ===\n...",
  "source": "computed"
}
```

## 7. Position pipeline

```
PH92 Marketplace Policy
PH96 Seller DNA
PH90 Cost Awareness
PH91 Buyer Reputation
PH93 Customer Patience
PH94 Resolution Cost Optimizer
PH97 Multi-Order Context   <-- NOUVEAU
LLM
```

## 8. Decision Context

```json
{
  "multiOrderContext": {
    "riskLevel": "HIGH",
    "ordersAnalyzed": 4,
    "signals": ["multi_order_non_delivery"]
  }
}
```

## 9. Prompt Block

```
=== MULTI-ORDER CONTEXT ENGINE (PH97) ===
Orders analyzed: 5
Conversations analyzed: 3
Multi-order risk level: HIGH
Risk score: 0.62

Detected signals:
- multi order non delivery
- refund pressure multi order

Orders involved: 405-4867060-5480332, 402-0451681-3086763

Guidance:
- avoid immediate refund — investigate first
- cross-reference delivery proof across orders
=== END MULTI-ORDER CONTEXT ENGINE ===
```

## 10. Endpoint debug

```
GET /ai/multi-order-context
  ?tenantId=xxx
  &buyerEmail=xxx    (ou customerHandle ou conversationId)
```

Aucun appel LLM. Aucun cout KBActions.

## 11. Tests

```
25 PASS / 0 FAIL / 37 assertions

T1  Health check                       PASS
T2  Endpoint validation                PASS
T3  Unknown buyer fallback             PASS
T4  Missing tenantId                   PASS
T5  Missing auth                       PASS
T6  No orders buyer                    PASS
T7  Response structure                 PASS
T8  Multi-tenant isolation             PASS
T9  customerHandle param               PASS
T10 Idempotence                        PASS
T11 Non-regression cost-awareness      PASS
T12 Non-regression buyer-reputation    PASS
T13 Non-regression marketplace-policy  PASS
T14 Non-regression customer-patience   PASS
T15 Non-regression resolution-cost     PASS
T16 Non-regression seller-dna          PASS
T17 Non-regression global-learning     PASS
T18 Array types                        PASS
T19 Risk level enum                    PASS
T20 Score range                        PASS
T21 promptBlock type                   PASS
T22 Source enum                        PASS
T23 Guidance non-empty                 PASS
T24 Pipeline /ai/assist intact         PASS
T25 conversationId fallback            PASS
```

## 12. Non-regression

Tous les endpoints PH90-PH96 verifies intacts :

- `/health` OK
- `/ai/cost-awareness` OK
- `/ai/buyer-reputation` OK
- `/ai/marketplace-policy` OK
- `/ai/customer-patience` OK
- `/ai/resolution-cost-optimizer` OK
- `/ai/seller-dna` OK
- `/ai/global-learning/tenant` OK
- `/ai/assist` pipeline intact

## 13. Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.97-ph96-seller-dna-dev -n keybuzz-api-dev
```
