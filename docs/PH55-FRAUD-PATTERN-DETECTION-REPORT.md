# PH55 — Fraud Pattern Detection — Rapport

> Date : 10 mars 2026
> Auteur : Agent Cursor (CE)
> Status : DEV deploye, en attente validation PROD

---

## Objectif

Ajouter une couche interne de detection de patterns de fraude/abus dans les conversations SAV. PH55 ne juge pas, n'accuse pas, ne refuse pas. Il rend l'IA plus prudente en renforcant les demandes de preuves et en evitant les remboursements prematures.

---

## Principes de securite

- JAMAIS d'accusation de fraude vers le client
- JAMAIS de refus automatique de demande
- JAMAIS d'action punitive
- Signal interne uniquement pour guider l'IA
- Ton professionnel et procedural maintenu

---

## Signaux detectes (10)

| # | Signal | Poids | Description |
|---|---|---|---|
| 1 | `risky_customer_profile` | 3 | customerRisk = RISKY (PH47) |
| 2 | `immediate_refund_pressure` | 2 | Demande remboursement des les premiers messages |
| 3 | `high_value_refund_pressure` | 2 | Remboursement + commande HIGH/CRITICAL_VALUE |
| 4 | `missing_evidence_on_defect` | 1 | Produit "casse" sans preuve/photo |
| 5 | `repeat_non_delivery_claims` | 2 | Non-recu + historique refunds eleve |
| 6 | `contradiction_delivery_claim` | 2 | Non-recu mais donnees suggerent livre |
| 7 | `repeated_refund_history` | 3 | Taux de remboursement > 50% sur 5+ cas |
| 8 | `multi_issue_escalation` | 1 | Accusations multiples dans un message |
| 9 | `legal_pressure_fast` | 2 | Menace juridique tot dans l'echange |
| 10 | `inconsistent_story` | 2 | Contradiction (non-recu + defectueux) |

---

## Niveaux de risque

| Niveau | Critere | Action IA |
|---|---|---|
| **LOW** | 0-1 signal faible (weight total < 3) | Proceder normalement |
| **MEDIUM** | 2+ signaux ou weight total >= 3 | Demander preuves, eviter remboursement direct |
| **HIGH** | 4+ signaux ou weight total >= 6 | Procedure stricte, escalade si doute |

---

## Guidance produite

| Guidance | Signification |
|---|---|
| `request_proof` | Demander preuves (photos, captures) |
| `ask_for_photos` | Demander photos specifiquement |
| `avoid_direct_refund` | Eviter remboursement immediat |
| `follow_strict_process` | Suivre la procedure standard |
| `require_return` | Exiger retour produit |
| `escalate_if_doubt` | Escalader en cas de doute |
| `verify_tracking` | Verifier le suivi de livraison |
| `remain_factual` | Rester factuel (pas d'emotion) |
| `request_clarification` | Demander clarification |
| `address_one_issue_at_time` | Traiter un probleme a la fois |

---

## Donnees utilisees

Le moteur exploite les donnees deja disponibles dans le pipeline :

- **PH47** customerRisk (category, score)
- **PH48** orderValueAwareness (category, totalAmount)
- **PH49** refundProtection (refundAllowed, protectionReason)
- **PH50** merchantBehavior (refundRate, totalCases)
- **PH54** customerIntent (intent, confidence)
- **PH53** customerTone (tone)
- **PH41** savClassification (scenario)
- Message texte + nombre de messages conversation

---

## Position pipeline

```
1.  Base prompt
2.  SAV Policy (PH41)
3.  Tenant Policy (PH42)
4.  Historical Engine (PH43)
5.  Decision Tree (PH45)
6.  Response Strategy (PH46)
7.  Refund Protection (PH49)
8.  Merchant Behavior (PH50)
9.  Adaptive Response (PH52)
10. Customer Tone (PH53)
11. Customer Intent (PH54)
12. Fraud Pattern Detection (PH55)  <-- nouveau
13. Order Context
14. Supplier Context
15. Tenant Rules
16. LLM
```

---

## Exemple prompt block

```
=== FRAUD PATTERN DETECTION (PH55) ===
Fraud risk: MEDIUM
Confidence: 67%
Signals:
- immediate_refund_pressure
- missing_evidence_on_defect

Guidance:
- avoid_direct_refund
- request_proof
- follow_strict_process
- ask_for_photos

Signaux de prudence detectes. Demander des preuves supplementaires.
Eviter le remboursement direct. Suivre la procedure standard.
Ne pas accuser le client.
Do not accuse the customer.
Remain professional and procedural.
=== END FRAUD PATTERN DETECTION ===
```

---

## Fichiers modifies/crees

| Fichier | Action |
|---|---|
| `src/services/fraudPatternEngine.ts` | CREE — moteur heuristique 10 signaux |
| `src/modules/ai/ai-assist-routes.ts` | MODIFIE — import, computation, prompt injection, decisionContext |
| `src/modules/ai/ai-policy-debug-routes.ts` | MODIFIE — interface, /policy/effective, GET /fraud-pattern |

---

## Endpoints

### GET /ai/fraud-pattern
- Parametres : `tenantId`, `message`, `conversationId` (opt)
- Retourne : `{ fraudRisk, confidence, signals, guidance }`

### GET /ai/policy/effective (mis a jour)
- Ajoute `fraudPattern` dans la reponse

### POST /ai/assist (mis a jour)
- Ajoute `fraudPattern` dans `decisionContext`
- Inject `fraudPatternPromptBlock` dans le system prompt (position 12)

---

## Resultats des tests (12/12 + non-regression)

| # | Scenario | Attendu | Obtenu | Confiance | Signaux | Status |
|---|---|---|---|---|---|---|
| 1 | Client normal | LOW | LOW | 0.15 | — | PASS |
| 2 | Colis manquant simple | LOW | LOW | 0.15 | — | PASS |
| 3 | Refund + defect sans preuve | MEDIUM | MEDIUM | 0.67 | immediate_refund_pressure, missing_evidence_on_defect | PASS |
| 4 | Defectueux sans photo | LOW | LOW | 0.33 | missing_evidence_on_defect | PASS |
| 5 | Refund pressure + defect | MEDIUM | MEDIUM | 0.67 | immediate_refund_pressure, missing_evidence_on_defect | PASS |
| 6 | Menace juridique + refund | MEDIUM | MEDIUM | 0.67 | immediate_refund_pressure, legal_pressure_fast | PASS |
| 7 | Multi-issue escalation | MEDIUM | MEDIUM | 0.67 | missing_evidence_on_defect, multi_issue_escalation | PASS |
| 8 | Contradiction non-recu + casse | MEDIUM | MEDIUM | 0.67 | missing_evidence_on_defect, inconsistent_story | PASS |
| 9 | Question simple | LOW | LOW | 0.15 | — | PASS |
| 10 | Remerciement | LOW | LOW | 0.15 | — | PASS |
| 11 | Anglais refund + broken | MEDIUM | MEDIUM | 0.67 | immediate_refund_pressure, missing_evidence_on_defect | PASS |
| 12 | Combinaison critique | HIGH/MEDIUM | MEDIUM | 0.73 | immediate_refund_pressure, missing_evidence_on_defect, legal_pressure_fast | PASS |

### Non-regression /ai/assist
- HTTP 200
- `fraudPattern` present dans `decisionContext` : PASS
- `customerIntent` present : PASS
- `customerTone` present : PASS
- Pipeline stable

---

## Impact

- Aucun appel LLM supplementaire
- Aucun impact KBActions
- Aucune modification des decisions SAV
- Aucune action punitive
- Zero impact base de donnees
- Tous les layers precedents intacts

---

## Deploiement

| Env | Image | Status |
|---|---|---|
| DEV | `v3.5.65-ph55-fraud-pattern-dev` | Deploye |
| PROD | — | En attente validation |

### Rollback
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.64-ph54-customer-intent-dev -n keybuzz-api-dev
```
