# PH45 — SAV Decision Tree + Confidence Gate — Rapport de Validation

> Date : 8 mars 2026
> Environnement : DEV
> Image : `ghcr.io/keybuzzio/keybuzz-api:v3.5.53-ph45-decision-tree-dev`
> Rollback : `v3.5.52-ph447-order-context-dev-b`

---

## 1. Resume

PH45 ajoute une couche de decision structuree a l'IA KeyBuzz :
- **Arbre de decision SAV** avec 12 scenarios
- **Confidence Gate** (high/medium/low) basee sur les signaux disponibles
- **Detection des informations manquantes** (photos, tracking, motif)
- **Actions autorisees/interdites** par scenario
- **Observabilite** complete dans decisionContext et /ai/policy/effective

## 2. Fichiers modifies

| Fichier | Action |
|---|---|
| `src/config/sav-decision-tree.ts` | CREE — Module central (290 lignes) |
| `src/modules/ai/ai-assist-routes.ts` | MODIFIE — Integration decision tree |
| `src/modules/ai/ai-policy-debug-routes.ts` | MODIFIE — Exposition dans /ai/policy/effective |

## 3. Resultats des 12 tests E2E

| # | Scenario | Classification | Confidence | Missing | Next Step | KBA |
|---|---|---|---|---|---|---|
| T1 | Colis non arrive | delivered_not_received | **MEDIUM (0.67)** | Tracking | Enquete transporteur | 10.15 |
| T2 | Produit endommage | damaged_product | **MEDIUM (0.50)** | **Photos** | Demander photos | 8.72 |
| T3 | Client agressif | aggressive_customer | HIGH (1.0) | - | Calme + cadre | 10.52 |
| T4 | Remboursement | refund_request | HIGH (1.0) | - | Procedure retour | 9.34 |
| T5 | Retard livraison | delivery_delay | HIGH (0.79) | Tracking | Verifier tracking | 10.91 |
| T6 | Retour | return_request | HIGH (1.0) | - | Procedure marketplace | 9.39 |
| T7 | Defectueux sans photo | defective_product | **MEDIUM (0.67)** | **Photos** | Demander photos | 8.87 |
| T8 | Mauvais produit | wrong_product | **MEDIUM (0.60)** | **Photos** | Demander photo+etiquette | 10.22 |
| T9 | Garantie | warranty_request | HIGH (1.0) | - | Garantie legale | 10.20 |
| T10 | Annulation | cancellation_request | HIGH (1.0) | - | Deja expediee | 9.75 |
| T11 | Facture | invoice_request | HIGH (1.0) | - | Espace client | 9.83 |
| T12 | Ambigu | unknown | HIGH (1.0) | - | Demander precisions | 10.83 |

**Resultat : 12/12 PASS**

## 4. Comportements cles valides

### Confidence Gate fonctionne correctement
- **Photos manquantes** (T2, T7, T8) → confidence MEDIUM, l'IA demande des preuves
- **Tracking manquant** (T1, T5) → confidence MEDIUM/HIGH, l'IA oriente vers verification
- **Tout present** (T3, T4, T6, T9, T10, T11) → confidence HIGH, resolution claire

### Actions interdites respectees
- T2 (produit endommage) : `proposer un remboursement sans photos` INTERDIT
- T4 (remboursement) : `promettre un remboursement direct` INTERDIT
- T3 (agressif) : `ceder a la pression ou aux menaces` INTERDIT
- T1 (non recu) : `rembourser immediatement` INTERDIT

### Detection informations manquantes
- Produit endommage sans photo → `Photos emballage + produit fournies`
- Produit defectueux sans photo → `Preuves photo/video fournies`
- Mauvais produit sans photo → `Photo du produit recu + etiquette`
- Colis non arrive sans tracking → `Livraison confirmee par tracking`

## 5. Non-regression

| Metrique | Avant PH45 | Apres PH45 | Status |
|---|---|---|---|
| KBActions par requete | 8-11 | 8-11 | OK (identique) |
| Wallet apres 12 tests | 569.39 | 450.66 | OK (debit normal ~118 KBA pour 12 appels) |
| Suggestions generees | oui | oui | OK |
| decisionContext persiste | oui | oui + enrichi | OK |
| /ai/policy/effective | oui | oui + decisionTree | OK |

## 6. Exemple de prompt injecte (T2 - produit endommage)

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

## 7. Deploiement

| Env | Image | Status |
|---|---|---|
| **DEV** | `v3.5.53-ph45-decision-tree-dev` | DEPLOYE ✓ |
| **PROD** | `v3.5.52-ph447-order-context-prod` | INCHANGE (attente validation) |

## 8. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.52-ph447-order-context-dev-b -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

## 9. Stop Point

**PROD non deploye. Attente validation Ludovic.**
