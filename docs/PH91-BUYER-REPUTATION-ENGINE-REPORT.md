# PH91 — Buyer Reputation Engine — Rapport

> Date : 14 mars 2026
> Environnement : DEV uniquement
> Image : `v3.5.92-ph91-buyer-reputation-dev`
> Rollback : `v3.5.61-ph90-cost-awareness-dev`

---

## 1. Objectif

Créer un moteur de réputation acheteur persistant basé sur l'historique réel des interactions SAV (180 derniers jours). Le moteur identifie les acheteurs fiables, normaux, à surveiller, risqués et abusifs.

PH91 est un moteur **analytique pur** :
- Aucun appel LLM
- Aucun coût KBActions
- Aucune modification DB
- Signal de réputation utilisable par PH47, PH55, PH63, PH90

---

## 2. Algorithme de scoring

### Base score
- Score initial (sans historique) : **8** → NORMAL_BUYER

### Signaux et poids

| Signal | Poids |
|--------|-------|
| Commande livrée sans problème | +2 |
| Commande sans réclamation | +1 |
| Demande d'information simple | 0 |
| Retour produit | -1 |
| Remplacement | -1 |
| Remboursement | -2 |
| Litige marketplace | -4 |
| Réclamation non-réception répétée | -3 |
| Abus détecté (PH63) | -5 |

### Classification

| Score | Classification |
|-------|---------------|
| >= 15 | TRUSTED_BUYER |
| 8–14 | NORMAL_BUYER |
| 3–7 | WATCH_BUYER |
| 0–2 | RISKY_BUYER |
| < 0 | ABUSIVE_BUYER |

### Fenêtre d'analyse
- **180 jours** glissants

### Confidence

| Events total | Confidence |
|-------------|-----------|
| 0 | 0.30 |
| 1-2 | 0.50 |
| 3-5 | 0.70 |
| 6-15 | 0.85 |
| > 15 | 0.95 |

---

## 3. Sources de données

| Table | Données extraites |
|-------|------------------|
| `orders` | Commandes par statut (delivered, shipped) |
| `amazon_returns` | Retours, remboursements (montant) |
| `conversations` | Conversations SAV, litiges (sav_status), claims livraison |

### Résolution du buyer handle
1. `customer_handle` sur la conversation (prioritaire)
2. Fallback : `customer_email` via `order_ref` → `orders`
3. Recherche flexible : correspondance exacte + ILIKE pour maximiser la couverture

---

## 4. Risk indicators détectés

| Indicateur | Condition |
|-----------|-----------|
| `repeat_refunds` | >= 3 remboursements |
| `delivery_claim_pattern` | >= 2 réclamations livraison |
| `marketplace_dispute` | >= 1 litige |
| `abuse_detected` | >= 1 flag abus |
| `high_refund_ratio` | refunds/orders > 40% |
| `serial_returner` | >= 3 retours + >= 2 remplacements |
| `negative_reputation` | score < 0 |

---

## 5. Intégration pipeline

### Position

```
PH47 Customer Risk
PH48 Product Value
PH50 Merchant Behavior
PH61 Marketplace Intelligence
PH90 Cost Awareness
PH91 Buyer Reputation    ← nouveau
→ [LLM Call]
```

PH91 s'exécute après PH90 (Cost Awareness) et avant l'appel LLM.

### decisionContext

```json
{
  "buyerReputation": {
    "score": -2,
    "classification": "ABUSIVE_BUYER",
    "confidence": 0.91,
    "riskIndicators": ["repeat_refunds", "delivery_claim_pattern"]
  }
}
```

### Prompt block

```
=== BUYER REPUTATION ENGINE (PH91) ===
Buyer classification: ABUSIVE_BUYER
Reputation score: -2
Risk indicators:
- repeat_refunds
- delivery_claim_pattern

Guidelines:
- do NOT offer refunds without full investigation
- require photos and proof for every claim
- recommend human review for any financial decision
=== END BUYER REPUTATION ENGINE ===
```

Le bloc n'est PAS injecté pour les NORMAL_BUYER sans indicateurs de risque (pas de bruit dans le prompt).

---

## 6. Endpoint debug

```
GET /ai/buyer-reputation?tenantId=X&buyerHandle=Y
GET /ai/buyer-reputation?tenantId=X&conversationId=Z
```

Retourne le profil complet (score, classification, signals, riskIndicators, confidence).
Aucun appel LLM. Aucun coût KBActions.

---

## 7. Cache Redis

| Clé | TTL |
|-----|-----|
| `buyer_reputation:{tenantId}:{buyerHandle}` | 15 minutes |

---

## 8. Tests — 49/49 PASS

| # | Test | Résultat |
|---|------|---------|
| T1 | Buyer sans historique → NORMAL_BUYER (score 8) | PASS |
| T2 | Buyer 100 commandes clean → TRUSTED_BUYER | PASS |
| T3 | Buyer 3 remboursements → WATCH_BUYER | PASS |
| T4 | Buyer 5 remboursements → ABUSIVE_BUYER | PASS |
| T5 | Buyer avec litige → RISKY_BUYER | PASS |
| T6 | Buyer normal + 1 retour → NORMAL/TRUSTED | PASS |
| T7 | Classification boundaries (8 assertions) | PASS |
| T8 | Prompt block ABUSIVE_BUYER | PASS |
| T9 | Prompt block empty pour NORMAL | PASS |
| T10 | Prompt block TRUSTED mentions "excellent" | PASS |
| T11 | Risk indicators détection | PASS |
| T12 | Abuse flags penalty | PASS |
| T13 | Endpoint debug 200 | PASS |
| T14 | Endpoint missing params 400 | PASS |
| T15 | Classification stable (idempotent) | PASS |
| T16 | Non-régression health/assist/cost-awareness | PASS |
| T17 | Non-régression channels/billing | PASS |
| T18 | Delivery claims pattern | PASS |
| T19 | Endpoint conversationId résolution | PASS |
| T20 | Multi-tenant isolation | PASS |

**20 tests, 49 assertions, 100% PASS**

---

## 9. Non-régression

| Endpoint | Statut |
|---------|--------|
| `/health` | 200 OK |
| `/ai/assist/status` | 200 OK |
| `/ai/cost-awareness` | 200 OK |
| `/channels/billing-compute` | 200 OK |
| PH41 → PH90 | Non impactés |

---

## 10. Fichiers modifiés

| Fichier | Action |
|---------|--------|
| `src/services/buyerReputationEngine.ts` | **CRÉÉ** — moteur principal |
| `src/modules/ai/ai-assist-routes.ts` | Import + pipeline + decisionContext + buildSystemPrompt |
| `src/modules/ai/ai-policy-debug-routes.ts` | Import + endpoint `/buyer-reputation` |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | Image tag mise à jour |

---

## 11. Rollback

```bash
kubectl set image deployment/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.61-ph90-cost-awareness-dev \
  -n keybuzz-api-dev
```

---

## 12. Exemples de calcul

### Buyer fiable (100 commandes, 0 problèmes)
- Score : 8 + 95×2 + 90×1 = 288 → TRUSTED_BUYER
- Confidence : 0.95

### Buyer normal sans historique
- Score : 8 (base) → NORMAL_BUYER
- Confidence : 0.30

### Buyer abusif (5 remboursements sur 6 commandes)
- Score : 8 + 1×2 + 0×1 + 2×(-1) + 5×(-2) = -2 → ABUSIVE_BUYER
- Indicators : repeat_refunds, high_refund_ratio
- Confidence : 0.85

### Buyer à risque (1 litige + 2 remboursements)
- Score : 8 + 1×2 + 0×1 + 1×(-1) + 2×(-2) + 1×(-4) = 1 → RISKY_BUYER
- Indicators : marketplace_dispute
- Confidence : 0.70
