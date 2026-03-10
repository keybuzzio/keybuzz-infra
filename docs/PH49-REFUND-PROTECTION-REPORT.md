# PH49 — Refund Protection Layer — Rapport

> Date : 9 mars 2026
> Scope : DEV uniquement
> Image : `v3.5.57-ph49-refund-protection-dev`
> Rollback : `v3.5.56-ph48-value-awareness-dev`
> Mode : Tests en SIMULATION — aucun appel marketplace

---

## 1. Objectif

Empecher les remboursements prematures en ajoutant un Refund Protection Layer dans le pipeline IA. Ce layer evalue 10 regles metier et bloque les remboursements si des preconditions ne sont pas remplies.

## 2. Regles de protection (10 regles)

| # | Regle | Poids | Description |
|---|-------|-------|-------------|
| 1 | `delivery_not_clarified` | 3 | Livraison non clarifiee (pas de tracking ni statut) |
| 2 | `delivery_window_active` | 4 | Fenetre de livraison non depassee |
| 3 | `missing_photos` | 3 | Photos manquantes pour produit defectueux/endommage |
| 4 | `high_value_order` | 2 | Commande HIGH_VALUE ou CRITICAL_VALUE |
| 5 | `risky_customer` | 4 | Client categorie RISKY (PH47) |
| 6 | `anti_pattern_refund_first` | 5 | Anti-pattern remboursement premature (PH43) |
| 7 | `tenant_supplier_first` | 3 | Policy tenant : fournisseur d'abord |
| 8 | `tenant_requires_photos` | 3 | Policy tenant : photos obligatoires |
| 9 | `tenant_diagnostic_required` | 3 | Policy tenant : diagnostic requis |
| 10 | `no_order_context` | 2 | Commande non identifiee |

### Logique de decision

- Si aucune regle declenchee → `refundAllowed: true` (avec validation agent)
- Si regle(s) declenchee(s) → `refundAllowed: false` + preconditions
- Confidence de protection : `high` si poids max >= 4, `medium` si poids total >= 5

## 3. Position dans le pipeline IA

```
1. Base prompt
2. PH41 SAV Policy
3. PH44 Tenant Policy
4. PH43 Historical Engine
5. PH45 Decision Tree
6. PH46 Response Strategy
7. PH49 Refund Protection ← NOUVEAU
8. Order Context
9. Supplier Context
10. Tenant Rules
```

## 4. Fichiers crees/modifies

### Nouveau fichier

- `src/services/refundProtectionLayer.ts`
  - `evaluateRefundProtection(scenario, signals, customerRiskCategory, orderValueCategory)`
  - 10 regles de protection avec poids
  - Generation du prompt block `=== REFUND PROTECTION LAYER ===`

### Fichiers modifies

- `src/modules/ai/ai-assist-routes.ts`
  - Import `evaluateRefundProtection`, `RefundProtectionResult`
  - Evaluation systematique (fallback `refund_request` si scenario inconnu)
  - Injection prompt block si regles declenchees
  - `decisionContext.refundProtection` avec 6 champs

- `src/modules/ai/ai-policy-debug-routes.ts`
  - Import `evaluateRefundProtection`, `computeOrderValueCategory`
  - `refundProtection` dans `PolicyEffectiveResponse`
  - `REFUND_PROTECTION` dans `finalPromptSections`
  - `refundProtection: true` dans `policyLayers`

### Document d'audit

- `keybuzz-infra/docs/PH49.1-REFUND-PROTECTION-AUDIT.md`

## 5. Exemple de prompt injecte

```
=== REFUND PROTECTION LAYER ===
Refund allowed: NO
Protection confidence: low
Reason: high_value_order
Required preconditions:
- Investigation approfondie obligatoire pour les commandes haute valeur
Recommended alternative: Orienter vers investigation detaillee et verification fournisseur

IMPORTANT: Ne propose PAS de remboursement. Suis les preconditions ci-dessus.
Si le client insiste, explique que la procedure standard doit etre suivie.
=== END REFUND PROTECTION ===
```

## 6. Tests E2E (SIMULATION) — 12/12 PASS

| # | Test | Protection | Resultat |
|---|------|------------|----------|
| 1 | Colis non recu sans tracking | refundAllowed=false, high_value_order | PASS |
| 2 | Livraison retardee | refundAllowed=false, high_value_order | PASS |
| 3 | Produit casse sans photo | refundAllowed=false, high_value_order | PASS |
| 4 | Produit defectueux haute valeur | refundAllowed=false, high_value_order | PASS |
| 5 | Client abusif | refundAllowed=false, high_value_order | PASS |
| 6 | Question simple | refundProtection present | PASS |
| 7 | Policy tenant | 1 precondition | PASS |
| 8 | Anti-pattern | refundAllowed=false | PASS |
| 9 | CRITICAL_VALUE order | high_value_order triggered | PASS |
| 10 | Scenario inconnu | Protection evaluee | PASS |
| 11 | Multi-langue (anglais) | refundAllowed=false | PASS |
| 12 | Non-regression KBActions | 104 KBA / 12 appels (normal) | PASS |

### Mode de test

- **SIMULATION** : messages simules via `POST /ai/assist` avec `messages` dans le body
- **Aucun appel marketplace** (Amazon, Octopia)
- **Aucun message envoye** aux clients
- **Aucun remboursement declenche**
- **Aucune modification Stripe**

## 7. Non-regression

| Module | Statut |
|--------|--------|
| Health API | OK |
| KBActions | ~9.5 KBA/appel (normal pour kbz-standard) |
| PH41-PH48 | Tous intacts |
| Inbox | Aucun message envoye |
| Outbound worker | Non appele |

## 8. Observabilite

### decisionContext

```json
{
  "refundProtection": {
    "refundAllowed": false,
    "refundConfidence": "low",
    "protectionReason": "high_value_order",
    "requiredPreconditions": ["Investigation approfondie obligatoire..."],
    "recommendedAlternative": "Orienter vers investigation detaillee...",
    "triggeredRules": ["high_value_order"]
  }
}
```

### /ai/policy/effective

```json
{
  "refundProtection": { ... },
  "finalPromptSections": ["GLOBAL_POLICY", "SAV_POLICY", "DECISION_TREE", "RESPONSE_STRATEGY", "REFUND_PROTECTION", "ORDER_CONTEXT"],
  "policyLayers": { "refundProtection": true }
}
```

## 9. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.56-ph48-value-awareness-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

## 10. Deploiement

| Env | Image | Statut |
|-----|-------|--------|
| DEV | `v3.5.57-ph49-refund-protection-dev` | DEPLOYE |
| PROD | - | EN ATTENTE validation Ludovic |

---

**STOP POINT** — Aucun deploiement PROD avant validation Ludovic.
