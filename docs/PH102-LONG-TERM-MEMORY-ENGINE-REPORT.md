# PH102 — Long-Term Memory Engine

> Date : 16 mars 2026
> Environnement : DEV
> Image : `v3.6.04-ph102-long-term-memory-dev`
> Rollback : `v3.6.03-ph101-knowledge-graph-dev`

---

## 1. Objectif

PH102 ajoute une couche de memoire persistante a long terme permettant au systeme IA de :

- Memoriser les incidents dans le temps
- Detecter les patterns historiques (produits, buyers, fournisseurs, carriers)
- Alimenter les moteurs existants (PH90-PH101) avec un contexte durable
- Conserver les signaux importants meme apres resolution

PH102 est 100% observabilite + memoire, aucune logique decisionnelle.

---

## 2. Table `ai_long_term_memory`

```sql
CREATE TABLE ai_long_term_memory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  signal_type TEXT NOT NULL,
  signal_value JSONB DEFAULT '{}',
  confidence FLOAT DEFAULT 0.5,
  source_engine TEXT DEFAULT 'unknown',
  first_seen TIMESTAMP DEFAULT NOW(),
  last_seen TIMESTAMP DEFAULT NOW(),
  occurrences INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Index

| Index | Colonnes |
|---|---|
| `idx_ltm_tenant` | tenant_id |
| `idx_ltm_entity_type` | entity_type |
| `idx_ltm_entity_id` | entity_id |
| `idx_ltm_signal_type` | signal_type |
| `idx_ltm_last_seen` | last_seen |
| `idx_ltm_unique` | (tenant_id, entity_type, entity_id, signal_type) UNIQUE |

---

## 3. Entites memorisees (6 types)

| Entity Type | Description |
|---|---|
| `BUYER` | Client/acheteur |
| `PRODUCT` | Produit (SKU/ASIN) |
| `SUPPLIER` | Fournisseur |
| `MARKETPLACE` | Place de marche |
| `ORDER` | Commande |
| `CARRIER` | Transporteur |

---

## 4. Signaux memorises (12 types)

| Signal | Description | Source |
|---|---|---|
| `REPEAT_DEFECT_PRODUCT` | Produit avec defauts recurrents | PH101 |
| `REPEAT_REFUND_BUYER` | Buyer demandant des remboursements repetitifs | PH102 |
| `HIGH_RETURN_PRODUCT` | Produit avec taux de retour eleve | PH101 |
| `SUPPLIER_DEFECT_CLUSTER` | Fournisseur generant des defauts groupes | PH101 |
| `CARRIER_DELAY_CLUSTER` | Transporteur avec retards groupes | PH102 |
| `MULTI_ORDER_BUYER_ISSUE` | Buyer avec problemes sur plusieurs commandes | PH97 |
| `MARKETPLACE_POLICY_CONFLICT` | Conflit politique marketplace | PH92 |
| `REPEAT_DELIVERY_CLAIM` | Reclamations livraison repetees | PH102 |
| `FRAUD_PATTERN_BUYER` | Pattern de fraude buyer | PH91 |
| `HIGH_ESCALATION_PRODUCT` | Produit generant beaucoup d'escalades | PH102 |
| `LOW_CONFIDENCE_CASE` | Cas avec confidence faible | PH98 |
| `UNUSUAL_CASE_PATTERN` | Pattern de cas inhabituel | PH102 |

---

## 5. Service `longTermMemoryEngine.ts`

### Fonctions

| Fonction | Role |
|---|---|
| `upsertMemorySignal(input)` | Insert ou met a jour un signal (UPSERT) |
| `updateLongTermMemory(tenantId, decisionContext)` | Extraction et persistance des signaux depuis le pipeline |
| `computeLongTermSignals(tenantId, buyerHandle?, productSku?)` | Recupere les signaux historiques pour le pipeline |
| `getEntityMemory(tenantId, entityType?, entityId?)` | Recupere la memoire d'une entite |
| `getTopSignals(tenantId, limit?)` | Top signaux par occurrences |
| `getMemoryGraph(tenantId)` | Graphe resume (types d'entites et signaux) |
| `buildLongTermMemoryBlock(topSignals)` | Genere le prompt block LLM |

---

## 6. Position pipeline

```
PH97 Multi-Order Context
PH101 Knowledge Graph
PH102 Long-Term Memory   ← NOUVEAU
PH100 AI Governance
LLM
PH98 Quality Scoring
PH99 Self-Improvement
```

PH102 est positionne apres PH101 (knowledge graph) et avant PH100 (governance).

---

## 7. Integration `decisionContext`

```json
{
  "longTermMemory": {
    "entities": 3,
    "signals": [
      { "type": "REPEAT_DEFECT_PRODUCT", "entityId": "SKU-9982", "occurrences": 7, "confidence": 0.8 },
      { "type": "REPEAT_REFUND_BUYER", "entityId": "buyer@test.com", "occurrences": 4, "confidence": 0.6 }
    ],
    "confidence": 0.72
  }
}
```

---

## 8. Prompt block exemple

```
=== LONG TERM MEMORY ENGINE (PH102) ===
Historical signals detected across time.

Key historical signals:
- Repeat product defect patterns (entity: SKU-9982, seen 7x, confidence: 0.80)
- Buyer historical refund behavior (entity: buyer@test.com, seen 4x, confidence: 0.60)
- Supplier defect clusters (entity: SupplierA, seen 3x, confidence: 0.70)

Use this historical context to avoid repeating ineffective resolutions.
=== END LONG TERM MEMORY ENGINE ===
```

---

## 9. Endpoints debug

| Method | Route | Description |
|---|---|---|
| GET | `/ai/long-term-memory?tenantId=X` | Signaux historiques (optionnel: buyerHandle, productSku) |
| GET | `/ai/long-term-memory/entity?tenantId=X&entityType=Y&entityId=Z` | Memoire d'une entite specifique |
| GET | `/ai/long-term-memory/signals?tenantId=X` | Top signaux + graphe resume |

Aucun appel LLM. Aucun cout KBActions.

---

## 10. Tests

- Tests : 20 cas / 40+ assertions
- Resultat : 100% PASS
- Fichier : `src/tests/ph102-tests.ts`

### Cas couverts

| # | Test | Resultat |
|---|---|---|
| 1 | Empty signals → empty block | PASS |
| 2 | Single signal → valid block | PASS |
| 3 | REPEAT_DEFECT_PRODUCT label | PASS |
| 4 | REPEAT_REFUND_BUYER label | PASS |
| 5 | HIGH_RETURN_PRODUCT label | PASS |
| 6 | SUPPLIER_DEFECT_CLUSTER label | PASS |
| 7 | CARRIER_DELAY_CLUSTER label | PASS |
| 8 | FRAUD_PATTERN_BUYER confidence | PASS |
| 9 | Multiple signals combined | PASS |
| 10 | Max 8 signals in prompt | PASS |
| 11 | Occurrences shown | PASS |
| 12 | Guidance text present | PASS |
| 13 | MULTI_ORDER_BUYER_ISSUE | PASS |
| 14 | MARKETPLACE_POLICY_CONFLICT | PASS |
| 15 | LOW_CONFIDENCE_CASE | PASS |
| 16 | HIGH_ESCALATION_PRODUCT | PASS |
| 17 | UNUSUAL_CASE_PATTERN | PASS |
| 18 | REPEAT_DELIVERY_CLAIM | PASS |
| 19 | Idempotence | PASS |
| 20 | All 12 signal types | PASS |

---

## 11. Non-regression

| Endpoint | Status |
|---|---|
| `/health` | 200 OK |
| `/ai/long-term-memory` | 200 OK |
| `/ai/long-term-memory/entity` | 200 OK |
| `/ai/long-term-memory/signals` | 200 OK |
| `/ai/self-improvement` (PH99) | 200 OK |
| `/ai/governance` (PH100) | 200 OK |
| `/ai/knowledge-graph` (PH101) | 200 OK |

Pipeline PH41 → PH101 intact.

---

## 12. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.03-ph101-knowledge-graph-dev -n keybuzz-api-dev
```

La table `ai_long_term_memory` restera en place (inoffensive, aucun impact sans le service).

---

## 13. Regles respectees

- [x] DEV uniquement
- [x] GitOps strict
- [x] Versionning semantique
- [x] Rollback documente
- [x] Aucun hardcodage tenant
- [x] Multi-tenant strict
- [x] Aucun appel LLM
- [x] Aucun impact KBActions
- [x] Aucune modification destructive DB
- [x] Aucune regression PH41 → PH101
