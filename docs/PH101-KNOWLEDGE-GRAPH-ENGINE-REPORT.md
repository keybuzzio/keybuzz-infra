# PH101 — Knowledge Graph Engine — Rapport

> **Date** : 2026-03-16
> **Environnement** : DEV uniquement
> **Image** : `ghcr.io/keybuzzio/keybuzz-api:v3.6.03-ph101-knowledge-graph-dev`
> **Rollback** : `v3.6.02-ph100-ai-governance-dev`

---

## 1. Objectif

Créer une couche Knowledge Graph Engine permettant à l'IA de construire une vue relationnelle des entités SAV (buyer, order, product, conversation, incident, resolution, marketplace, supplier) pour :
- Détecter les incidents récurrents
- Identifier les produits problématiques
- Repérer les comportements clients répétés
- Tracer les chaînes d'événements SAV
- Identifier les clusters de problèmes

---

## 2. Entités modélisées

| Entité | Colonnes clés | Source DB |
|--------|--------------|-----------|
| **Buyer** | email, ordersCount, conversationsCount, incidentsCount, returnsCount | conversations.customer_handle, orders.customer_email |
| **Order** | id, marketplace, value, status, productsCount, hasReturn | orders |
| **Product** | sku, title, incidentCount, refundCount, returnCount | orders.products (JSONB) |
| **Conversation** | id, channel, status, orderRef, incidentType | conversations |
| **Supplier** | id, name, casesCount | suppliers + supplier_cases |

---

## 3. Relations construites

| Relation | Description |
|----------|-------------|
| `buyer_has_orders` | Un buyer a N commandes |
| `buyer_has_conversations` | Un buyer a N conversations |
| `conversation_linked_to_order` | Une conversation est liée à une commande |
| `product_has_recurrent_incidents` | Un produit a >= 2 incidents |
| `supplier_has_multiple_cases` | Un fournisseur a >= 2 cas SAV |

---

## 4. Graph Signals (10)

| # | Signal | Condition |
|---|--------|-----------|
| 1 | `repeat_product_issue` | Même produit → incidentCount >= 2 |
| 2 | `repeat_buyer_incident` | Buyer → incidentsCount >= 3 |
| 3 | `cross_order_same_issue` | Même type d'incident sur 2+ commandes |
| 4 | `supplier_issue_cluster` | Même fournisseur → casesCount >= 2 |
| 5 | `marketplace_issue_cluster` | Même marketplace → 3+ conversations |
| 6 | `refund_heavy_product` | Produit souvent remboursé |
| 7 | `warranty_candidate_pattern` | 2+ conversations defect/warranty |
| 8 | `delivery_claim_cluster` | 2+ plaintes livraison |
| 9 | `escalation_prone_case` | High incidents + returns |
| 10 | `low_confidence_graph_gap` | Graphe trop pauvre (< 2 entités) |

---

## 5. Position dans le pipeline

```
PH96 Seller DNA
PH90 Cost Awareness
PH91 Buyer Reputation
PH93 Customer Patience
PH94 Resolution Cost Optimizer
PH97 Multi-Order Context
PH101 Knowledge Graph     ← NOUVEAU (pre-LLM + decisionContext)
PH100 AI Governance        (pre-LLM + decisionContext)
PH98 AI Quality Scoring    (post-LLM)
LLM Call
Persist decisionContext
```

PH101 s'exécute avant PH100 car la gouvernance peut bénéficier des signaux du graphe.

---

## 6. Intégration decisionContext

```json
{
  "knowledgeGraph": {
    "graphSignals": ["repeat_product_issue", "delivery_claim_cluster"],
    "relatedEntitiesCount": 7,
    "confidence": 0.84
  }
}
```

---

## 7. Prompt block injecté

```
=== KNOWLEDGE GRAPH ENGINE ===
Related entities detected:
- buyer has 4 orders, 3 conversations
- buyer has 2 returns
- product(s) with recurrent issues: SKU-123

Graph signals:
- repeat_product_issue
- cross_order_same_issue

Guidance:
- Product(s) with recurrent issues: SKU-123
- Same issue type across multiple orders: delivery_issue
=== END KNOWLEDGE GRAPH ENGINE ===
```

---

## 8. Endpoints debug

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/ai/knowledge-graph?tenantId=X&conversationId=Y` | Graphe complet |
| GET | `/ai/knowledge-graph/related?tenantId=X&conversationId=Y` | Entités liées |
| GET | `/ai/knowledge-graph/signals?tenantId=X&conversationId=Y` | Signaux uniquement |

Aucun appel LLM. Aucun coût KBActions.

---

## 9. Tests

| # | Test | Résultat |
|---|------|----------|
| 1 | Single order buyer → simple graph | PASS |
| 2 | 3 orders + 3 incidents → repeat_buyer_incident | PASS |
| 3 | Product incidentCount >= 2 → repeat_product_issue | PASS |
| 4 | Supplier casesCount >= 2 → supplier_issue_cluster | PASS |
| 5 | Same issue 2+ orders → cross_order_same_issue | PASS |
| 6 | No buyer → low_confidence_graph_gap | PASS |
| 7 | Product refundCount >= 2 → refund_heavy_product | PASS |
| 8 | Multiple defect convs → warranty_candidate_pattern | PASS |
| 9 | Multiple delivery claims → delivery_claim_cluster | PASS |
| 10 | High incidents + returns → escalation_prone_case | PASS |
| 11 | 3+ same marketplace → marketplace_issue_cluster | PASS |
| 12 | Prompt block builder | PASS |
| 13 | Empty signals → empty prompt | PASS |
| 14 | Multi-tenant isolation | PASS |
| 15 | Idempotence | PASS |
| 16 | Empty context stable | PASS |
| 17 | Confidence calculation | PASS |
| 18 | Multiple signals combine | PASS |
| 19 | Returns in prompt block | PASS |
| 20 | Export stability | PASS |

**20 tests, 34 assertions, 100% PASS**

---

## 10. Non-régression

| Endpoint | Status |
|----------|--------|
| `/health` | 200 OK |
| `/ai/quality-score` (PH98) | 200 OK |
| `/ai/self-improvement` (PH99) | 200 OK |
| `/ai/governance` (PH100) | 200 OK |
| `/ai/knowledge-graph` (PH101) | 200 OK |
| `/ai/knowledge-graph/signals` | 200 OK |
| `/ai/knowledge-graph/related` | 200 OK |

---

## 11. Rollback

```bash
kubectl set image deployment/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.02-ph100-ai-governance-dev \
  -n keybuzz-api-dev
```

---

## 12. Fichiers modifiés

| Fichier | Action |
|---------|--------|
| `src/services/knowledgeGraphEngine.ts` | **NOUVEAU** — moteur Knowledge Graph |
| `src/modules/ai/ai-policy-debug-routes.ts` | Ajout 3 endpoints `/ai/knowledge-graph*` |
| `src/modules/ai/ai-assist-routes.ts` | Import, pipeline pre-LLM, buildSystemPrompt, decisionContext |
| `src/tests/ph101-tests.ts` | **NOUVEAU** — 20 tests |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | Image mise à jour |

---

## 13. Résumé

PH101 ajoute une couche de structuration relationnelle qui :
- Connecte 5 types d'entités SAV (buyer, orders, products, conversations, suppliers)
- Construit des relations inter-entités
- Détecte 10 types de signaux graphe
- Fournit des guidances contextuelles dans le prompt LLM
- Persiste les signaux dans le decisionContext

**STOP POINT** — Aucun déploiement PROD. Attente validation.
