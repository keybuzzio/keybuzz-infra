# PH47 — Customer Risk Engine — Rapport

> Date : 9 mars 2026
> Scope : DEV uniquement
> Image : `v3.5.55b-ph47-risk-engine-dev`
> Rollback : `v3.5.54-ph46-response-strategy-dev`

---

## 1. Objectif

Creer un Customer Risk Engine evaluant automatiquement le niveau de risque d'un client a partir de son historique SAV. Le score est injecte dans le `decisionContext` de l'IA sans modifier son comportement (preparation uniquement).

## 2. Algorithme de scoring

### Poids

| Facteur | Poids |
|---------|-------|
| Commande livree/expediee | +1 |
| Retour Amazon | -1 |
| Remboursement (refunded_amount > 0) | -2 |
| Litige (conversation avec sav_status) | -3 |

### Classification

| Score | Categorie |
|-------|-----------|
| >= 10 | TRUSTED |
| >= 5 | NORMAL |
| >= 0 | WATCH |
| < 0 | RISKY |

### Cas particulier

Un client sans historique (0 commandes, 0 retours, 0 conversations) recoit un score de base de **5** → categorie **NORMAL**. Un client inconnu est presume normal.

## 3. Donnees utilisees

| Source | Champ | Usage |
|--------|-------|-------|
| `orders` | `customer_email`, `status` | Comptage commandes livrees |
| `amazon_returns` | JOIN via `order_ref` | Comptage retours |
| `amazon_returns` | `refunded_amount > 0` | Comptage remboursements |
| `conversations` | JOIN via `order_ref` + `sav_status` | Comptage litiges |

Note : pas de table `refunds` dans le schema actuel. Les remboursements sont detectes via `amazon_returns.refunded_amount`.

## 4. Fichiers crees/modifies

### Nouveau fichier

- `src/services/customerRiskEngine.ts`
  - `computeCustomerRisk(tenantId, buyerEmail)` → calcul live + cache Redis
  - `resolveBuyerEmail(tenantId, conversationId)` → resolution email acheteur via order_ref
  - Cache Redis : cle `customer_risk:<tenantId>:<buyerEmail>`, TTL 10 minutes

### Fichiers modifies

- `src/modules/ai/ai-assist-routes.ts`
  - Import `computeCustomerRisk`, `resolveBuyerEmail`, `CustomerRiskResult`
  - Appel `resolveBuyerEmail()` puis `computeCustomerRisk()` dans le handler
  - Ajout `customerRisk: { score, category }` dans `decisionContext`
  - Aucune modification du prompt IA

- `src/modules/ai/ai-policy-debug-routes.ts`
  - Import `computeCustomerRisk`, `resolveBuyerEmail`
  - Nouveau endpoint `GET /ai/customer-risk`
  - Parametres : `tenantId`, `buyerEmail` (ou `conversationId` pour resolution auto)
  - Retour JSON : `{ buyerEmail, score, category, metrics, source }`

## 5. Endpoint debug

```
GET /ai/customer-risk?tenantId=ecomlg-001&buyerEmail=xxx@marketplace.amazon.fr
```

Reponse :
```json
{
  "buyerEmail": "xxx@marketplace.amazon.fr",
  "score": 464,
  "category": "TRUSTED",
  "metrics": {
    "deliveredOrders": 467,
    "totalOrders": 467,
    "returns": 0,
    "refunds": 0,
    "refundedTotal": 0,
    "disputes": 1,
    "conversations": 4
  },
  "source": "live"
}
```

Aucun appel LLM. Aucun debit KBActions.

## 6. Tests E2E — 6/6 PASS

| # | Test | Resultat | Detail |
|---|------|----------|--------|
| 1 | Client sans historique | PASS | score=5, category=NORMAL |
| 2 | Client 467 commandes | PASS | score=464, category=TRUSTED |
| 3 | Client avec retours | PASS | returns=1, category=RISKY |
| 4 | Client avec remboursements | PASS | refunds=1, refundedTotal=306.30 |
| 5 | Cache Redis actif | PASS | 2eme appel source=cache |
| 6 | Format endpoint valide | PASS | HTTP 200, tous champs presents |

## 7. Non-regression

| Module | Statut |
|--------|--------|
| Health API | OK |
| KBActions wallet | Inchange |
| IA suggestions | Inchangees (customerRisk dans decisionContext uniquement) |
| PH41 SAV Policy | Intact |
| PH43 Historical | Intact |
| PH45 Decision Tree | Intact |
| PH46 Response Strategy | Intact |

## 8. Impact infrastructure

- Redis : ajout de cles `customer_risk:*` avec TTL 10 min (auto-expiration)
- DB : 4 requetes SQL legeres par calcul live (orders, returns, refunds, conversations)
- CPU/Memoire : negligeable (calcul arithmetique simple)
- Pas de nouvelle table

## 9. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.54-ph46-response-strategy-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

## 10. Deploiement

| Env | Image | Statut |
|-----|-------|--------|
| DEV | `v3.5.55b-ph47-risk-engine-dev` | DEPLOYE |
| PROD | - | EN ATTENTE validation Ludovic |

---

**STOP POINT** — Aucun deploiement PROD avant validation Ludovic.
