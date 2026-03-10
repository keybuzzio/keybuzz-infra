# PH48 — Product Value Awareness — Rapport

> Date : 9 mars 2026
> Scope : DEV uniquement
> Image : `v3.5.56-ph48-value-awareness-dev`
> Rollback : `v3.5.55b-ph47-risk-engine-dev`

---

## 1. Objectif

Creer un Product Value Awareness layer evaluant la criticite economique d'une commande. Le resultat est injecte dans le `decisionContext` de l'IA sans modifier son comportement (preparation de donnees uniquement).

## 2. Logique de categorisation

### Seuils (EUR)

| Montant | Categorie |
|---------|-----------|
| < 20 EUR | LOW_VALUE |
| 20 - 149.99 EUR | MEDIUM_VALUE |
| 150 - 499.99 EUR | HIGH_VALUE |
| >= 500 EUR | CRITICAL_VALUE |

### Donnees utilisees

| Champ | Source |
|-------|--------|
| `total_amount` | `orders.total_amount` |
| `currency` | `orders.currency` |
| `itemCount` | `orders.products` (JSONB array length) |

Aucune marge simulee. Aucune donnee externe.

## 3. Fichiers crees/modifies

### Nouveau fichier

- `src/services/productValueAwareness.ts`
  - `classifyOrderValue(totalAmount)` → classification pure
  - `computeOrderValueCategory(order)` → classification depuis un objet commande
  - `getOrderValue(tenantId, orderId)` → lookup DB + classification
  - `getOrderValueFromConversation(tenantId, conversationId)` → resolution via `order_ref`

### Fichiers modifies

- `src/modules/ai/ai-assist-routes.ts`
  - Import `computeOrderValueCategory`
  - Calcul `orderValueAwareness` depuis `orderContext.totalAmount` + `orderContext.currency`
  - Ajout `orderValueAwareness: { totalAmount, currency, category }` dans `decisionContext`
  - Aucune modification du prompt IA

- `src/modules/ai/ai-policy-debug-routes.ts`
  - Import `getOrderValue`
  - Nouveau endpoint `GET /ai/order-value`
  - Parametres : `tenantId`, `orderId`
  - Retour : `{ orderId, totalAmount, currency, category, itemCount, thresholds, source }`

## 4. Endpoint debug

```
GET /ai/order-value?tenantId=ecomlg-001&orderId=408-3928545-2393923
```

Reponse :
```json
{
  "orderId": "ord-mlhfelhx-xqj5kg",
  "totalAmount": 500.3,
  "currency": "EUR",
  "category": "CRITICAL_VALUE",
  "itemCount": 1,
  "thresholds": { "low": 20, "medium": 150, "high": 500 },
  "source": "db"
}
```

Aucun appel LLM. Aucun debit KBActions.

## 5. Tests E2E — 6/6 PASS

| # | Test | Commande | Montant | Resultat |
|---|------|----------|---------|----------|
| 1 | LOW_VALUE | 408-9877295-8699531 | 0.00 EUR | PASS |
| 2 | MEDIUM_VALUE | 403-0819640-8299505 | 20.05 EUR | PASS |
| 3 | HIGH_VALUE | 402-5433831-9896355 | 150.17 EUR | PASS |
| 4 | CRITICAL_VALUE | 408-3928545-2393923 | 500.30 EUR | PASS |
| 5 | Endpoint format | - | - | PASS (HTTP 200, tous champs) |
| 6 | decisionContext | conv cmmlc3r3a... | - | PASS (orderValueAwareness present, CRITICAL_VALUE) |

## 6. Non-regression

| Module | Statut |
|--------|--------|
| Health API | OK |
| KBActions wallet | Inchange |
| IA suggestions | Inchangees (orderValueAwareness dans decisionContext uniquement) |
| PH41-PH47 | Tous intacts |

## 7. Impact infrastructure

- DB : 1 requete SQL legere par appel (SELECT sur `orders`)
- Pas de cache (donnee statique, pas de TTL necessaire)
- CPU/Memoire : negligeable (comparaisons numeriques)
- Pas de nouvelle table

## 8. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.55b-ph47-risk-engine-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

## 9. Deploiement

| Env | Image | Statut |
|-----|-------|--------|
| DEV | `v3.5.56-ph48-value-awareness-dev` | DEPLOYE |
| PROD | - | EN ATTENTE validation Ludovic |

---

**STOP POINT** — Aucun deploiement PROD avant validation Ludovic.
