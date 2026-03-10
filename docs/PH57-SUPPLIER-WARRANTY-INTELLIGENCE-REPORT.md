# PH57 — Supplier / Warranty Intelligence Layer — Rapport

> Date : 10 mars 2026
> Auteur : Agent Cursor (CE)
> Status : DEV deploye, en attente validation PROD

---

## Objectif

Detecter quand la voie garantie / fournisseur / diagnostic / remplacement est pertinente et orienter la strategie SAV en consequence. Ne jamais promettre de garantie sans preuve, ne jamais creer de ticket fournisseur reel, ne jamais contourner PH49 Refund Protection.

---

## Principes de securite

- JAMAIS promettre une garantie sans preuve
- JAMAIS inventer un SAV fournisseur
- JAMAIS contourner PH49 Refund Protection
- JAMAIS creer de ticket fournisseur reel
- JAMAIS faire de promesse contractuelle inventee
- Raisonner uniquement sur les donnees disponibles

---

## Scenarios detectes (8)

| # | Scenario | Confiance | Description |
|---|---|---|---|
| 1 | `WARRANTY_ELIGIBLE_WITH_PROOF` | 0.85 | Defaut detecte + preuves fournies |
| 2 | `WARRANTY_POSSIBLE_BUT_PROOF_MISSING` | 0.82 | Defaut detecte mais preuves manquantes |
| 3 | `SUPPLIER_DIAGNOSTIC_REQUIRED` | 0.79 | Diagnostic technique necessaire |
| 4 | `REPLACEMENT_PREFERRED_OVER_REFUND` | 0.78 | Remplacement preferable au remboursement |
| 5 | `REPAIR_OR_TECHNICAL_REVIEW_PATH` | 0.75 | Reparation / expertise technique |
| 6 | `LOW_VALUE_NO_WARRANTY_PATH` | 0.70 | Faible valeur, garantie pas systematique |
| 7 | `WARRANTY_NOT_APPLICABLE` | 0.65 | Pas de contexte garantie |
| 8 | `SUPPLIER_INVESTIGATION_NEEDED` | 0.83 | Investigation fournisseur necessaire |

---

## Regles cles

### Regle 1 — Defaut / panne
- Orienter vers garantie / diagnostic AVANT remboursement
- Sauf cas faible valeur tres clair

### Regle 2 — Preuves manquantes
- Ne pas proposer de remboursement
- Demander photo / video / description precise

### Regle 3 — Merchant warranty-first
- Renforcer l'orientation garantie
- Reduire la probabilite de remboursement

### Regle 4 — Haute valeur
- Privilegier diagnostic / garantie / investigation fournisseur
- Eviter remboursement direct

### Regle 5 — Faible valeur
- Voie garantie possible mais pas systematique
- Geste commercial simple preferable

### Regle 6 — Remplacement
- Si remplacement mentionne + defaut confirme + preuve : orienter remplacement

### Regle 7 — Fraude / incoherence
- Aucune promesse garantie directe
- Demander preuves / procedure stricte

---

## Donnees utilisees

| Source | Champ | Usage |
|---|---|---|
| PH54 | customerIntent | Intent client (PRODUCT_DEFECT) |
| PH41 | savScenario | Classification SAV |
| PH48 | orderValueCategory | Categorie valeur commande |
| PH55 | fraudRisk | Niveau risque fraude |
| PH49 | refundAllowed | Protection remboursement |
| PH50 | merchantWarrantyFirst | Comportement vendeur |
| PH50 | merchantRefundRate | Taux remboursement vendeur |
| orderContext | status, fulfillmentChannel | Statut commande |
| message | text | Patterns defaut/preuve/garantie/remplacement/reparation |

---

## Position pipeline

```
1.  Base prompt
2.  SAV Policy (PH41)
3.  Tenant Policy (PH42/44)
4.  Historical Engine (PH43)
5.  Decision Tree (PH45)
6.  Response Strategy (PH46)
7.  Refund Protection (PH49)
8.  Merchant Behavior (PH50)
9.  Adaptive Response (PH52)
10. Customer Tone (PH53)
11. Customer Intent (PH54)
12. Fraud Pattern (PH55)
13. Delivery Intelligence (PH56)
14. Supplier / Warranty Intelligence (PH57)  <-- nouveau
15. Order Context
16. Supplier Context
17. Tenant Rules
18. LLM
```

---

## Exemple prompt block

```
=== SUPPLIER / WARRANTY INTELLIGENCE LAYER (PH57) ===
Supplier/Warranty scenario: WARRANTY_POSSIBLE_BUT_PROOF_MISSING
Confidence: 82%

Signals:
- product_defect_detected
- proof_missing
- merchant_behavior_warranty_first

Guidance:
- request_photos
- request_detailed_description
- do_not_promise_refund

Un defaut produit est signale mais les preuves manquent.
Demander au client des photos, videos ou une description
detaillee du probleme. Ne pas promettre de remboursement.
=== END SUPPLIER / WARRANTY INTELLIGENCE LAYER ===
```

---

## Fichiers modifies/crees

| Fichier | Action |
|---|---|
| `src/services/supplierWarrantyEngine.ts` | CREE — moteur 8 scenarios |
| `src/modules/ai/ai-assist-routes.ts` | MODIFIE — import, computation, prompt injection, decisionContext |
| `src/modules/ai/ai-policy-debug-routes.ts` | MODIFIE — interface, /policy/effective, GET /supplier-warranty-intelligence |

---

## Endpoints

### GET /ai/supplier-warranty-intelligence
- Parametres : `tenantId`, `message`, `conversationId`, `orderValueCategory`, `fraudRisk`, `merchantWarrantyFirst`
- Retourne : `{ supplierWarrantyScenario, confidence, signals, guidance }`

### GET /ai/policy/effective (mis a jour)
- Ajoute `supplierWarrantyIntelligence` dans la reponse

### POST /ai/assist (mis a jour)
- Ajoute `supplierWarrantyIntelligence` dans `decisionContext`
- Inject `supplierWarrantyPromptBlock` dans le system prompt (position 14)

---

## Resultats des tests (12/12 + non-regression)

| # | Scenario | Attendu | Obtenu | Confiance | Signaux | Status |
|---|---|---|---|---|---|---|
| 1 | Defaut + preuve fournie | WARRANTY_ELIGIBLE_WITH_PROOF | WARRANTY_ELIGIBLE_WITH_PROOF | 0.85 | product_defect_detected, proof_provided | PASS |
| 2 | Defaut sans preuve | WARRANTY_POSSIBLE_BUT_PROOF_MISSING | WARRANTY_POSSIBLE_BUT_PROOF_MISSING | 0.82 | product_defect_detected, proof_missing | PASS |
| 3 | Panne technique sans preuve | WARRANTY_POSSIBLE_BUT_PROOF_MISSING | WARRANTY_POSSIBLE_BUT_PROOF_MISSING | 0.82 | product_defect_detected, proof_missing | PASS |
| 4 | Remplacement + defaut + preuve | WARRANTY_ELIGIBLE_WITH_PROOF | WARRANTY_ELIGIBLE_WITH_PROOF | 0.85 | product_defect_detected, proof_provided | PASS |
| 5 | Faible valeur + defaut | WARRANTY_POSSIBLE_BUT_PROOF_MISSING | WARRANTY_POSSIBLE_BUT_PROOF_MISSING | 0.82 | product_defect_detected, proof_missing | PASS |
| 6 | Haute valeur + defaut | WARRANTY_POSSIBLE_BUT_PROOF_MISSING | WARRANTY_POSSIBLE_BUT_PROOF_MISSING | 0.82 | product_defect_detected, proof_missing | PASS |
| 7 | Fraude elevee + defaut | WARRANTY_POSSIBLE_BUT_PROOF_MISSING | WARRANTY_POSSIBLE_BUT_PROOF_MISSING | 0.82 | product_defect_detected, proof_missing, fraud_risk_elevated | PASS |
| 8 | Merchant warranty-first | WARRANTY_POSSIBLE_BUT_PROOF_MISSING | WARRANTY_POSSIBLE_BUT_PROOF_MISSING | 0.82 | product_defect_detected, proof_missing, merchant_behavior_warranty_first | PASS |
| 9 | Defaut + mention video | WARRANTY_ELIGIBLE_WITH_PROOF | WARRANTY_ELIGIBLE_WITH_PROOF | 0.85 | product_defect_detected, proof_provided | PASS |
| 10 | Anglais defaut sans preuve | WARRANTY_POSSIBLE_BUT_PROOF_MISSING | WARRANTY_POSSIBLE_BUT_PROOF_MISSING | 0.82 | product_defect_detected, proof_missing | PASS |
| 11 | Pas de signal defaut | WARRANTY_NOT_APPLICABLE | WARRANTY_NOT_APPLICABLE | 0.65 | no_defect_signal, no_warranty_context | PASS |
| 12 | Reparation + defaut | WARRANTY_POSSIBLE_BUT_PROOF_MISSING | WARRANTY_POSSIBLE_BUT_PROOF_MISSING | 0.82 | product_defect_detected, proof_missing | PASS |

### Non-regression /ai/assist
- HTTP 200
- `supplierWarrantyIntelligence` present dans `decisionContext` : PASS
- `deliveryIntelligence` present : PASS
- `fraudPattern` present : PASS
- Pipeline complet stable

---

## Impact

- Aucun appel LLM supplementaire
- Aucun impact KBActions
- Aucun ticket fournisseur reel
- Aucune action externe
- Aucune promesse contractuelle
- PH49 Refund Protection intact
- Zero impact base de donnees
- Tous les layers precedents intacts

---

## Deploiement

| Env | Image | Status |
|---|---|---|
| DEV | `v3.5.67-ph57-supplier-warranty-intelligence-dev` | Deploye |
| PROD | — | En attente validation |

### Rollback
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.66-ph56-delivery-intelligence-dev -n keybuzz-api-dev
```
