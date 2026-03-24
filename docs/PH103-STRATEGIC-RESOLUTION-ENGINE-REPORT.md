# PH103 — Strategic Resolution Engine

> Date : 16 mars 2026
> Environnement : DEV
> Image : `v3.6.05-ph103-strategic-resolution-dev`
> Rollback : `v3.6.04-ph102-long-term-memory-dev`

---

## 1. Objectif

PH103 orchestre tous les signaux produits par PH41 → PH102 pour determiner la meilleure strategie SAV globale avant generation de la reponse IA.

PH103 ne remplace aucun moteur existant. Il agit comme chef d'orchestre decisionnel.

---

## 2. Strategies supportees (8)

| Strategie | Description |
|---|---|
| `REQUEST_INFORMATION` | Demander des informations supplementaires au client |
| `CARRIER_INVESTIGATION` | Enqueter aupres du transporteur |
| `SUPPLIER_WARRANTY` | Traiter via la garantie fournisseur |
| `RETURN_PROCESS` | Initier un processus de retour |
| `REPLACEMENT` | Envoyer un produit de remplacement |
| `REFUND` | Traiter un remboursement |
| `ESCALATE_HUMAN` | Escalader vers un agent humain |
| `FRAUD_REVIEW` | Signaler pour revue fraude |

---

## 3. Signaux agreges

| Source | Phase |
|---|---|
| Seller DNA | PH96 |
| Buyer Reputation | PH91 |
| Customer Patience | PH93 |
| Cost Awareness | PH90 |
| Fraud Pattern | PH55 |
| Marketplace Policy | PH92 |
| Knowledge Graph | PH101 |
| Long-Term Memory | PH102 |
| Multi-Order Context | PH97 |
| SAV Scenario | PH41 |

---

## 4. Matrice de scoring

Chaque strategie recoit un score base sur :

```
score = base
      + scenario_match
      + seller_weight (DNA preferences)
      + buyer_adjustment (reputation, risk)
      + cost_efficiency (order value, tier)
      + patience_impact
      + marketplace_weight
      + knowledge_graph_signals
      + long_term_memory_signals
      - fraud_penalty
      - abuse_penalty
```

Le score est normalise entre 0 et 1. Les strategies sont triees par score decroissant.

---

## 5. Position pipeline

```
PH97 Multi-Order Context
PH101 Knowledge Graph
PH102 Long-Term Memory
PH103 Strategic Resolution   ← NOUVEAU
PH100 AI Governance
LLM
PH98 Quality Scoring
PH99 Self-Improvement
```

PH103 s'execute apres PH102 (long-term memory) et avant PH100 (governance).

---

## 6. Integration `decisionContext`

```json
{
  "strategicResolution": {
    "recommendedStrategy": "SUPPLIER_WARRANTY",
    "confidence": 0.81,
    "strategyScores": {
      "SUPPLIER_WARRANTY": 0.82,
      "CARRIER_INVESTIGATION": 0.77,
      "REQUEST_INFORMATION": 0.66,
      "RETURN_PROCESS": 0.45,
      "REPLACEMENT": 0.40,
      "REFUND": 0.22,
      "ESCALATE_HUMAN": 0.15,
      "FRAUD_REVIEW": 0.10
    },
    "consideredSignals": ["seller_dna", "buyer_reputation", "cost_awareness", "sav_scenario"]
  }
}
```

---

## 7. Prompt block exemple

```
=== STRATEGIC RESOLUTION ENGINE (PH103) ===
Recommended strategy: SUPPLIER_WARRANTY
Confidence: 0.81

Alternative strategies:
- CARRIER_INVESTIGATION (0.77)
- REQUEST_INFORMATION (0.66)

Guidance:
Prefer: Process via supplier warranty.
Avoid immediate refund unless supplier rejects case.
Seller prefers investigation over immediate refund.
Alternatives: CARRIER_INVESTIGATION (0.77), REQUEST_INFORMATION (0.66).
=== END STRATEGIC RESOLUTION ENGINE ===
```

---

## 8. Endpoint debug

| Method | Route | Description |
|---|---|---|
| GET | `/ai/strategic-resolution?tenantId=X` | Strategie recommandee avec matrice de scores |

Aucun appel LLM. Aucun cout KBActions.

---

## 9. Tests

- Tests : 20 cas / 60+ assertions
- Resultat : 100% PASS
- Fichier : `src/tests/ph103-tests.ts`

### Cas couverts

| # | Scenario | Strategie attendue | Resultat |
|---|---|---|---|
| 1 | Contexte vide | Stable | PASS |
| 2 | Produit defectueux + warranty seller | WARRANTY | PASS |
| 3 | Fraud risk HIGH | FRAUD_REVIEW | PASS |
| 4 | Delivery issue | CARRIER_INVESTIGATION | PASS |
| 5 | Low value + customer-first seller | REFUND | PASS |
| 6 | General inquiry | REQUEST_INFORMATION | PASS |
| 7 | Return request | RETURN_PROCESS | PASS |
| 8 | Wrong item + low cost | REPLACEMENT/RETURN | PASS |
| 9 | High value + risky buyer | ESCALATE_HUMAN | PASS |
| 10 | All scores 0-1 | Normalized | PASS |
| 11 | Sorted descending | Correct | PASS |
| 12 | KG repeat product → WARRANTY boost | Boosted | PASS |
| 13 | LTM fraud → FRAUD_REVIEW boost | Boosted | PASS |
| 14 | Prompt block structure | Valid | PASS |
| 15 | Prompt block alternatives | Shown | PASS |
| 16 | Idempotence | Stable | PASS |
| 17 | All signals tracked | 9+ signals | PASS |
| 18 | Amazon marketplace | Conciliatory | PASS |
| 19 | Multi-order high risk | Escalation | PASS |
| 20 | Guidance actionable | Relevant | PASS |

---

## 10. Non-regression

| Endpoint | Status |
|---|---|
| `/health` | 200 OK |
| `/ai/strategic-resolution` | 200 OK |
| `/ai/long-term-memory` (PH102) | 200 OK |
| `/ai/knowledge-graph` (PH101) | 200 OK |
| `/ai/governance` (PH100) | 200 OK |
| `/ai/self-improvement` (PH99) | 200 OK |

Pipeline PH41 → PH102 intact.

---

## 11. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.04-ph102-long-term-memory-dev -n keybuzz-api-dev
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
- [x] Aucune modification destructive DB
- [x] Aucune regression PH41 → PH102
