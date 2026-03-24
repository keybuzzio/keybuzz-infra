# PH104 — Cross-Tenant Intelligence Engine

> Date : 16 mars 2026
> Environnement : DEV
> Image : `v3.6.06-ph104-cross-tenant-intelligence-dev`
> Rollback : `v3.6.05-ph103-strategic-resolution-dev`

---

## 1. Objectif

PH104 detecte des signaux globaux a travers tous les tenants en utilisant exclusivement des donnees agregees et anonymisees. Aucune donnee sensible n'est jamais exposee entre tenants.

Patterns detectes :
- Produits problematiques multi-vendeurs
- Transporteurs defaillants
- Fraude multi-tenants
- Clusters de defauts fournisseur
- Anomalies marketplace

---

## 2. Protection des donnees

| Regle | Implementation |
|---|---|
| Anonymisation buyer | `sha256(email)` tronque a 12 chars |
| Anonymisation produit | `sha256(sku)` tronque a 12 chars |
| Pas d'exposition tenant_id | Jamais dans les reponses |
| Pas d'exposition email | Jamais dans les reponses |
| Donnees agregees uniquement | counts, confidence, risk_level |

---

## 3. Signaux detectes (10 types)

| Signal | Description |
|---|---|
| `PRODUCT_DEFECT_CLUSTER` | Meme produit → incidents chez plusieurs vendeurs |
| `CARRIER_DELAY_CLUSTER` | Transporteur avec taux anormal de retards |
| `CARRIER_NON_DELIVERY_SPIKE` | Pic de non-livraisons transporteur |
| `CROSS_TENANT_REFUND_ABUSE` | Acheteur avec remboursements multi-vendeurs |
| `SUPPLIER_DEFECT_CLUSTER` | Fournisseur generant des defauts groupes |
| `MARKETPLACE_INCIDENT_CLUSTER` | Marketplace avec pattern d'incidents |
| `DELIVERY_WINDOW_CLUSTER` | Anomalies fenetres de livraison |
| `FRAUD_PATTERN_NETWORK` | Reseau de fraude detecte |
| `PRODUCT_MISMATCH_CLUSTER` | Cluster de produits non conformes |
| `ESCALATION_CLUSTER` | Pic d'escalades |

---

## 4. Source de donnees

PH104 interroge exclusivement la table `ai_long_term_memory` (PH102) avec des requetes agregees :
- `COUNT(DISTINCT tenant_id)` pour detecter les patterns cross-tenant
- `SUM(occurrences)` pour mesurer l'ampleur
- `AVG(confidence)` pour le niveau de confiance
- Groupement par `entity_id` anonymise

---

## 5. Position pipeline

```
PH97 Multi-Order Context
PH101 Knowledge Graph
PH102 Long-Term Memory
PH104 Cross-Tenant Intelligence   ← NOUVEAU
PH103 Strategic Resolution
PH100 AI Governance
LLM
PH98 Quality Scoring
PH99 Self-Improvement
```

---

## 6. Integration `decisionContext`

```json
{
  "crossTenantIntelligence": {
    "clusters": 3,
    "topSignals": [
      { "type": "PRODUCT_DEFECT_CLUSTER", "cases": 14, "risk": "HIGH" },
      { "type": "CARRIER_DELAY_CLUSTER", "cases": 21, "risk": "CRITICAL" }
    ],
    "confidence": 0.72
  }
}
```

---

## 7. Prompt block exemple

```
=== CROSS-TENANT INTELLIGENCE (PH104) ===
Global signals detected across marketplace network.

Detected clusters:
- Product defect cluster detected (14 cases, risk: HIGH)
- Carrier delay spike detected (21 cases, risk: CRITICAL)
- Cross-tenant refund abuse signals (6 cases, risk: HIGH)

Carrier risk signals:
- carrier:abc123: 21 cases, risk CRITICAL

Guidance:
- Validate defect evidence before resolution.
- Prefer investigation before refund.
- Carrier issues detected: investigate delivery before compensating.
=== END CROSS-TENANT INTELLIGENCE ===
```

---

## 8. Endpoint debug

| Method | Route | Description |
|---|---|---|
| GET | `/ai/cross-tenant-intelligence?tenantId=X` | Signaux globaux agregos |
| GET | `/ai/cross-tenant-intelligence?tenantId=X&productSku=Y` | Contexte specifique produit |
| GET | `/ai/cross-tenant-intelligence?tenantId=X&buyerEmail=Z` | Contexte specifique buyer (anonymise) |

Aucun appel LLM. Aucun cout KBActions.

---

## 9. Tests

- Tests : 20 cas / 50+ assertions
- Resultat : 100% PASS
- Fichier : `src/tests/ph104-tests.ts`

### Cas couverts

| # | Test | Resultat |
|---|---|---|
| 1 | Empty clusters → empty block | PASS |
| 2 | Product cluster → valid block | PASS |
| 3 | Carrier signal shown | PASS |
| 4-12 | Labels pour les 10 types de signaux | PASS |
| 13 | Max 6 clusters dans le prompt | PASS |
| 14-16 | Guidance contextuelle (product/fraud/carrier) | PASS |
| 17 | Combined clusters + carriers | PASS |
| 18 | Anonymisation deterministe | PASS |
| 19 | Idempotence | PASS |
| 20 | Tous les 10 types ont des labels | PASS |

---

## 10. Non-regression

| Endpoint | Status |
|---|---|
| `/health` | 200 OK |
| `/ai/cross-tenant-intelligence` (PH104) | 200 OK |
| `/ai/strategic-resolution` (PH103) | 200 OK |
| `/ai/long-term-memory` (PH102) | 200 OK |
| `/ai/knowledge-graph` (PH101) | 200 OK |
| `/ai/governance` (PH100) | 200 OK |
| `/ai/self-improvement` (PH99) | 200 OK |

Pipeline PH41 → PH103 intact.

---

## 11. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.05-ph103-strategic-resolution-dev -n keybuzz-api-dev
```

---

## 12. Regles respectees

- [x] DEV uniquement
- [x] GitOps strict
- [x] Versionning semantique
- [x] Rollback documente
- [x] Aucun hardcodage tenant
- [x] Multi-tenant strict
- [x] Aucun appel LLM
- [x] Aucun impact KBActions
- [x] Anonymisation SHA-256 obligatoire
- [x] Aucune exposition donnees inter-tenants
- [x] Aucune regression PH41 → PH103
