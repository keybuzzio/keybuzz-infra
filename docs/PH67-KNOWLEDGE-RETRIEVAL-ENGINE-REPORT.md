# PH67 — Knowledge Retrieval Engine (RAG SAV)

> Date : 11 mars 2026
> Auteur : Cursor Agent
> Environnement : DEV uniquement
> Version : v3.5.77-ph67-knowledge-retrieval-dev

---

## 1. Objectif

Creer une couche Knowledge Retrieval Engine permettant a l'IA de recuperer les connaissances documentaires pertinentes avant generation de reponse SAV.

PH67 exploite de facon structuree :
- Politiques SAV globales
- Politiques marketplace (Amazon, Octopia)
- Procedures garantie / fournisseur
- Procedures livraison
- Regles de traitement par type de cas

## 2. Architecture

### Structure documentaire

```
src/data/knowledge/
  global-safeguards.json     (6 documents)
  amazon-policies.json       (5 documents)
  delivery-procedures.json   (4 documents)
  warranty-procedures.json   (4 documents)
  octopia-policies.json      (2 documents)
```

**Total : 21 documents structures.**

### Format document

```json
{
  "id": "amazon-no-refund-before-return-001",
  "category": "MARKETPLACE_POLICY",
  "marketplace": "AMAZON",
  "tags": ["refund", "return", "amazon", "policy"],
  "title": "Amazon: No refund before return",
  "content": "On Amazon marketplace, never promise a refund before the return process is completed.",
  "lang": "en"
}
```

### 5 categories de connaissance

| Categorie | Description | Documents |
|---|---|---|
| `GLOBAL_POLICY` | Politiques SAV universelles | 6 |
| `MARKETPLACE_POLICY` | Regles Amazon, Octopia | 7 |
| `DELIVERY_PROCEDURE` | Procedures livraison | 4 |
| `WARRANTY_PROCEDURE` | Procedures garantie | 4 |
| `TENANT_POLICY` | Regles vendeur (extensible) | 0 (prevu) |

## 3. Logique de scoring

### Collecte des tags pertinents

Le moteur collecte des tags depuis tous les signaux contextuels :

| Source | Exemple | Tags generes |
|---|---|---|
| `customerIntent` | `product_defect` | `defect, warranty, proof, photo, video` |
| `deliveryScenario` | `NOT_RECEIVED` | `not-received, investigation, carrier, tracking` |
| `supplierWarrantyScenario` | `WARRANTY_ELIGIBLE_WITH_PROOF` | `warranty, proof, photo, video, defect` |
| `savScenario` | `delivery_issue` | `delivery, not-received, carrier` |
| `fraudRisk` | `HIGH` | `risk, fraud` |
| `message` (keywords) | `ecran casse remboursement` | `screen, defect, proof, refund, return` |

### Scoring par document

```
score = tag_overlap / max(doc_tags, relevant_tags)
  + marketplace_boost (+0.15 si match, -0.10 si mismatch)
  minimum 0.05 pour GLOBAL_POLICY
  clamped [0, 1]
```

### Selection

- Seuil minimum : `score > 0.10`
- Tri : score decroissant
- **Maximum : 3 documents** (limite stricte pour eviter le gonflement du prompt)

## 4. Integration pipeline

### Position

```
PH64 Resolution Prediction
PH65 Escalation Intelligence
                                    ← PH67 Knowledge Retrieval ici
const messages (buildSystemPrompt)
LLM call
PH66 Self-Protection (post-LLM)
```

### Fichiers modifies

| Fichier | Modification |
|---|---|
| `src/services/knowledgeRetrievalEngine.ts` | **Nouveau** — moteur de retrieval |
| `src/data/knowledge/*.json` | **Nouveau** — 5 fichiers documentaires |
| `src/modules/ai/ai-assist-routes.ts` | Import + pipeline block + buildSystemPrompt + decisionContext |
| `src/modules/ai/ai-policy-debug-routes.ts` | Import + endpoint debug |

### Prompt block injecte

```
=== KNOWLEDGE RETRIEVAL ENGINE ===
Matched knowledge:
1. Standard defect warranty procedure — For any product defect: request photo or video...
2. Amazon: No refund before return — On Amazon marketplace, never promise a refund...
3. Proof required before action — For any product defect, always request photo evidence...

Top themes:
- warranty_procedure
- marketplace_policy

Guidance:
- request_proof_before_warranty
- follow_refund_policy_strictly
=== END KNOWLEDGE RETRIEVAL ENGINE ===
```

### Decision context

```json
{
  "knowledgeRetrieval": {
    "matchedKnowledgeIds": ["warranty-defect-standard-001", "amazon-no-refund-before-return-001"],
    "topThemes": ["warranty_procedure", "marketplace_policy"],
    "guidance": ["request_proof_before_warranty", "follow_refund_policy_strictly"]
  }
}
```

## 5. Endpoint debug

```
GET /ai/knowledge-retrieval?tenantId=xxx&customerIntent=product_defect&marketplace=AMAZON&message=ecran%20casse
```

Retour :
```json
{
  "matchedKnowledge": [...],
  "topThemes": [...],
  "guidance": [...]
}
```

- Aucun appel LLM
- Aucun debit KBActions

## 6. Tests

### Resultats

```
Tests: 18 | Assertions: 44 | PASS: 44 | FAIL: 0
RESULT: ALL PASS
```

### Couverture

| # | Test | Attendu | Resultat |
|---|---|---|---|
| T1 | Product defect + Amazon | warranty + Amazon policy | PASS |
| T2 | Delivery delay + NOT_RECEIVED | delivery procedure + tracking | PASS |
| T3 | Refund request + Amazon | refund restriction docs | PASS |
| T4 | Low value defect | simplified procedure guidance | PASS |
| T5 | High value defect, no evidence | warranty + request evidence | PASS |
| T6 | Octopia delivery issue | Octopia or delivery docs | PASS |
| T7 | Unknown marketplace | graceful fallback | PASS |
| T8 | Fraud HIGH | strict verification guidance | PASS |
| T9 | Warranty claim with proof | warranty docs | PASS |
| T10 | Empty context | minimal fallback | PASS |
| T11 | French message "ecran casse" | screen/defect docs | PASS |
| T12 | English message "not received" | delivery procedure | PASS |
| T13 | A-to-Z threat + Amazon | A-to-Z policy | PASS |
| T14 | Damaged in transit | damaged delivery doc | PASS |
| T15 | Relay point expired | relay doc | PASS |
| T16 | Max 3 results enforced | <= 3 docs | PASS |
| T17 | Score range 0-1 | all scores valid | PASS |
| T18 | Non-regression KBActions | no consumption | PASS |

## 7. Non-regression

| Phase | Statut |
|---|---|
| PH41 SAV Policy | Intact |
| PH45 Decision Tree | Intact |
| PH49 Refund Protection | Intact |
| PH50 Merchant Behavior | Intact |
| PH54 Customer Intent | Intact |
| PH55 Fraud Pattern | Intact |
| PH56 Delivery Intelligence | Intact |
| PH57 Supplier/Warranty | Intact |
| PH58 Conversation Memory | Intact |
| PH59 Context Compression | Intact |
| PH60 Decision Calibration | Intact |
| PH61 Marketplace Intelligence | Intact |
| PH62 Evidence Intelligence | Intact |
| PH63 Abuse Pattern | Intact |
| PH64 Resolution Prediction | Intact |
| PH65 Escalation Intelligence | Intact |
| PH66 Self-Protection | Intact |
| KBActions | Aucun impact |
| TypeScript compilation | 0 erreur |

## 8. Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.76-ph66-self-protection-dev -n keybuzz-api-dev
```

## 9. Extensions futures

- **Tenant-specific knowledge** : documents propres a chaque vendeur (table DB `tenant_knowledge`)
- **RAG vectoriel** : integration Qdrant pour retrieval semantique (quand la base documentaire depasse ~100 docs)
- **Auto-enrichissement** : apprentissage des resolutions reussies pour alimenter la base
- **Multi-langue** : traduction automatique des documents selon la langue du client

---

*Rapport genere le 11 mars 2026 — DEV uniquement.*
