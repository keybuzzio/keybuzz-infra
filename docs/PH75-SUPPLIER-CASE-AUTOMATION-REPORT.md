# PH75 — Supplier Case Automation Engine

> Date : 11 mars 2026
> Environnement : DEV
> Image : `ghcr.io/keybuzzio/keybuzz-api:v3.5.86-ph75-supplier-case-automation-dev`
> Rollback : `v3.5.85-ph74-return-management-dev`

---

## 1. Objectif

Ajouter un moteur **Supplier Case Automation** qui prepare automatiquement la gestion des dossiers fournisseur / garantie dans le pipeline IA SAV.

PH75 ne declenche **aucune action reelle** — il prepare uniquement :
- L'ouverture de dossier fournisseur
- L'identification des donnees manquantes
- Le niveau d'automatisation possible
- Le type de dossier fournisseur recommande

---

## 2. Architecture

### Fichier principal
`src/services/supplierCaseAutomationEngine.ts`

### Fonctions exportees
- `buildSupplierCaseAutomationPlan(context)` — moteur principal
- `buildSupplierCaseAutomationBlock(result)` — bloc prompt

### Position pipeline
```
PH72 Action Execution
PH73 Carrier Integration
PH74 Return Management
PH75 Supplier Case Automation   <-- nouveau
PH67 Knowledge Retrieval
PH59 Context Compression
LLM
PH66 Self Protection
```

---

## 3. Scenarios (8)

| Scenario | Description |
|---|---|
| `SUPPLIER_CASE_NOT_APPLICABLE` | Aucun fournisseur implique |
| `SUPPLIER_CASE_INFORMATION_REQUIRED` | Donnees manquantes |
| `SUPPLIER_CASE_READY` | Dossier fournisseur pret |
| `SUPPLIER_CASE_BLOCKED_MISSING_DATA` | Donnees critiques absentes |
| `LOW_VALUE_NO_SUPPLIER_ESCALATION` | Faible valeur, pas d'escalade |
| `HIGH_VALUE_SUPPLIER_ESCALATION` | Produit cher, fournisseur recommande |
| `DEFECT_WITH_PROOF_SUPPLIER_CASE` | Defaut + preuve, dossier ouvert |
| `SUPPLIER_REVIEW_REQUIRED` | Cas ambigu, validation humaine |

---

## 4. Types de dossier fournisseur

| Type | Usage |
|---|---|
| `WARRANTY_CLAIM` | Garantie constructeur |
| `SUPPLIER_INVESTIGATION` | Investigation fournisseur |
| `REPLACEMENT_REQUEST` | Remplacement produit |
| `NOT_APPLICABLE` | Aucun dossier |

---

## 5. Niveaux d'automatisation

| Niveau | Description |
|---|---|
| `MANUAL` | Validation humaine obligatoire (fraude, haute valeur) |
| `ASSISTED` | Agent valide (cas standard) |
| `AUTOMATIC_READY` | Pret a automatiser (cas non-applicable, faible valeur) |

---

## 6. Niveaux de securite

| Niveau | Condition |
|---|---|
| `SAFE` | Pas de risque fraude/abus |
| `REVIEW_REQUIRED` | Haute valeur ou risque moyen |
| `RESTRICTED` | Fraude/abus HIGH |

---

## 7. Logique de classification

Ordre de priorite :
1. **Fraud/Abuse HIGH** -> `SUPPLIER_REVIEW_REQUIRED`
2. **Non-relevant** (retour, livraison, pas defaut) -> `NOT_APPLICABLE`
3. **Low value sans garantie** -> `LOW_VALUE_NO_SUPPLIER_ESCALATION`
4. **High/Critical value** -> `HIGH_VALUE_SUPPLIER_ESCALATION`
5. **Medium fraud/abuse** -> `SUPPLIER_REVIEW_REQUIRED`
6. **Defaut + preuve + photos** -> `DEFECT_WITH_PROOF_SUPPLIER_CASE`
7. **Warranty eligible** -> `SUPPLIER_CASE_READY` ou `INFORMATION_REQUIRED`
8. **Defaut sans preuve** -> `SUPPLIER_CASE_INFORMATION_REQUIRED`
9. **Donnees critiques manquantes** -> `SUPPLIER_CASE_BLOCKED_MISSING_DATA`

---

## 8. Donnees requises

| Champ | Source |
|---|---|
| `orderId` | orderContext |
| `productSku` | orderContext |
| `defectDescription` | message client |

---

## 9. Endpoint debug

```
GET /ai/supplier-case-automation?tenantId=ecomlg-001&customerIntent=product+broken&evidencePresent=true&photosAttached=true
```

Reponse :
```json
{
  "scenario": "DEFECT_WITH_PROOF_SUPPLIER_CASE",
  "supplierCaseType": "WARRANTY_CLAIM",
  "automationLevel": "ASSISTED",
  "safetyLevel": "SAFE",
  "eligibility": "READY",
  "confidence": 0.78,
  "guidance": ["product defect confirmed with proof", "supplier warranty case can proceed"]
}
```

---

## 10. Tests

| # | Test | Resultat |
|---|---|---|
| T1 | Defaut + preuve | `DEFECT_WITH_PROOF_SUPPLIER_CASE` |
| T2 | Defaut sans preuve | `INFORMATION_REQUIRED` |
| T3 | Faible valeur | `LOW_VALUE_NO_SUPPLIER_ESCALATION` |
| T4 | Haute valeur | `HIGH_VALUE_SUPPLIER_ESCALATION` |
| T5 | Fraud HIGH | `SUPPLIER_REVIEW_REQUIRED` + `RESTRICTED` |
| T6 | Retour standard | `NOT_APPLICABLE` |
| T7 | Warranty + WARRANTY_FIRST | `SUPPLIER_CASE_READY` + `WARRANTY_CLAIM` |
| T8 | Donnees absentes | `BLOCKED_MISSING_DATA` |
| T9 | Livraison investigation | `NOT_APPLICABLE` |
| T10 | Abuse HIGH | `SUPPLIER_REVIEW_REQUIRED` |
| T11 | WARRANTY_PROCESS + data | `SUPPLIER_CASE_READY` |
| T12 | Resolution WARRANTY | supplier relevant |
| T13 | Prediction REPLACEMENT | `REPLACEMENT_REQUEST` |
| T14 | Fraud MEDIUM | `SUPPLIER_REVIEW_REQUIRED` |
| T15 | Pas d'intent fournisseur | `NOT_APPLICABLE` |
| T16 | Format bloc prompt | header/footer valides |
| T17 | Low value + no warranty | `LOW_VALUE` skip |

**Resultats : 17 tests, 39 assertions, 100% PASS**

---

## 11. Non-regression

- PH41-PH74 intacts
- TypeScript `tsc --noEmit` : 0 erreur
- Pipeline complet fonctionnel
- Aucun appel LLM supplementaire
- Aucun impact KBActions

---

## 12. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.85-ph74-return-management-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.85-ph74-return-management-dev -n keybuzz-api-dev
```
