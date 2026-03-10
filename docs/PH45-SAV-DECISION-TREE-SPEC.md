# PH45 — SAV Decision Tree + Confidence Gate — Specification

> Date : 8 mars 2026
> Phase : PH45
> Scope : DEV uniquement (PROD apres validation)

---

## 1. Objectif

Transformer l'IA KeyBuzz d'un moteur de suggestion guide par politique (PH41) en un moteur de decision SAV structure, capable de :
- Raisonner par arbre de decision
- Detecter les informations manquantes
- Eviter les conclusions prematurees
- Demander les preuves ou verifications necessaires
- N'autoriser une recommandation "forte" que si le niveau de confiance est suffisant

## 2. Architecture

```
classifySavScenario(text)
    → scenario + classificationConfidence
        ↓
evaluateDecisionTree(scenario, availableSignals)
    → {
        scenario,
        decisionConfidence: high | medium | low,
        confidenceScore: 0.0-1.0,
        missingSignals: [...],
        allowedActions: [...],
        forbiddenActions: [...],
        nextBestStep: string,
        promptBlock: string
      }
        ↓
buildSystemPrompt(..., decisionTreeBlock)
    → Prompt LLM avec arbre de decision injecte
```

## 3. Fichiers

| Fichier | Role |
|---|---|
| `src/config/sav-decision-tree.ts` | Module central : arbre de decision, signaux, confidence gate |
| `src/modules/ai/ai-assist-routes.ts` | Integration dans le handler /ai/assist |
| `src/modules/ai/ai-policy-debug-routes.ts` | Exposition dans /ai/policy/effective |

## 4. Scenarios

| Scenario | Signaux requis | Poids total |
|---|---|---|
| delivery_delay | commande, fenetre livraison, statut, tracking, date achat | 14 |
| delivered_not_received | commande, livraison confirmee, delai, verification client | 12 |
| refund_request | commande, motif, statut, montant | 11 |
| return_request | commande, date achat (retractation), motif | 9 |
| defective_product | commande, description defaut, photos, garantie | 12 |
| damaged_product | commande, photos emballage+produit, description | 10 |
| wrong_product | commande, photo recu+etiquette, difference decrite | 10 |
| warranty_request | commande, date achat, nature probleme | 10 |
| aggressive_customer | contexte compris | 4 |
| cancellation_request | commande, statut commande | 8 |
| invoice_request | commande | 3 |
| unknown | contexte | 5 |

## 5. Confidence Gate

| Niveau | Seuil | Comportement |
|---|---|---|
| **HIGH** | score >= 0.70 | L'IA peut proposer une resolution claire |
| **MEDIUM** | 0.40 <= score < 0.70 | L'IA oriente prudemment, ne conclut pas |
| **LOW** | score < 0.40 | L'IA demande des informations, ne propose RIEN de definitif |

Le score est calcule par :
```
score = somme(poids des signaux presents) / somme(poids de tous les signaux requis)
```

## 6. Signaux disponibles

| Signal | Source | Impact |
|---|---|---|
| hasOrderContext | DB: orders | Commande identifiee |
| orderStatus | DB: orders.status | Shipped/Unshipped/Cancelled |
| hasDeliveryWindow | DB: orders.raw_data | Fenetre livraison estimee |
| deliveryWindowPassed | Calcul runtime | Delai depasse |
| hasTracking | DB: orders.tracking_code | Suivi disponible |
| hasDeliveryStatus | DB: orders.delivery_status | Statut livraison |
| hasPhotos | DB: message_attachments count | Preuves visuelles |
| hasMultipleMessages | Conversation messages | Historique echanges |
| orderValue | DB: orders.total_amount | Montant commande |
| daysSincePurchase | Calcul runtime | Jours depuis achat |
| tenantRequiresPhotos | DB: tenant_ai_policies | Politique photos tenant |
| tenantSupplierFirst | DB: tenant_ai_policies | Fournisseur d'abord |
| tenantRefundThreshold | DB: tenant_ai_policies | Seuil remboursement |
| historicalCasesFound | PH43 engine | Cas historiques |
| antiPatternsTriggered | PH43 engine | Anti-patterns actifs |
| hasSupplierCase | DB: supplier_cases | Dossier fournisseur |

## 7. Bloc Prompt Injecte

```
=== SAV DECISION TREE (PH45) ===
Scenario: damaged_product
Confidence: MEDIUM

⚠ CONFIANCE MOYENNE — Tu peux orienter prudemment mais ne pas conclure definitivement.

Informations manquantes :
- Photos emballage + produit fournies

Prochaine meilleure etape :
→ Demander des photos de l'emballage ET du produit endommage

Actions autorisees :
✓ demander des photos de l'emballage ET du produit
✓ verifier si le dommage est lie au transport
✓ proposer une reclamation transporteur si dommage visible

Actions INTERDITES :
✗ proposer un remboursement sans photos
✗ admettre la responsabilite sans verification
=== FIN SAV DECISION TREE ===
```

## 8. Ordre d'injection Prompt

```
1. Base prompt (regles generales)
2. SAV Policy block (PH41)
3. Tenant Policy block (PH44)
4. Historical patterns block (PH43)
5. SAV Decision Tree (PH45) ← NOUVEAU
6. Order Context block (PH44.7)
7. Tenant Rules
8. Supplier Context
```

## 9. Observabilite

### decisionContext enrichi
```json
{
  "policyLayers": { "decisionTree": true },
  "decisionTreeScenario": "damaged_product",
  "decisionConfidence": "medium",
  "decisionConfidenceScore": 0.50,
  "missingSignals": ["Photos emballage + produit fournies"],
  "allowedActions": ["..."],
  "forbiddenActions": ["..."],
  "nextBestStep": "Demander des photos..."
}
```

### /ai/policy/effective
Nouveau champ `decisionTree` dans la reponse, avec :
- scenario, confidence, confidenceScore
- missingSignals, allowedActions, forbiddenActions
- nextBestStep, reasoning

## 10. Regles

- Aucun changement KBActions (cout identique)
- Aucun changement billing
- Aucun changement SP-API
- Aucune decision automatique executee
- Compatible PH41/PH43/PH44/PH44.5/PH44.7
- Rollback : `v3.5.52-ph447-order-context-dev-b`
