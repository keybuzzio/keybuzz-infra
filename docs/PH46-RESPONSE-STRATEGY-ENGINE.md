# PH46 — Response Strategy Engine + Delivery Safety Policy

> Date : 9 mars 2026
> Environnement : DEV
> Image : `ghcr.io/keybuzzio/keybuzz-api:v3.5.54-ph46-response-strategy-dev`
> Rollback : `v3.5.53-ph45-decision-tree-dev`

---

## 1. Objectif

Ameliorer la strategie de reponse IA en ajoutant une couche qui controle
COMMENT l'IA repond (ton, formulation, actions) et non pas QUOI repondre.

Corrige un probleme critique : quand le tracking est absent, l'IA disait
"la commande est en preparation" — un statut non confirme et potentiellement faux.

## 2. Pipeline IA complet apres PH46

```
1. SAV Policy (PH41)        — regles scenario
2. Tenant Policy (PH44)     — overrides tenant
3. Historical Engine (PH43) — cas passes
4. Decision Tree (PH45)     — arbre de decision + confidence gate
5. Response Strategy (PH46) — strategie de reponse + delivery safety  ← NOUVEAU
6. Order Context (PH44.7)   — donnees commande
7. Tenant Rules              — regles vendeur
8. Supplier Context           — contexte fournisseur
```

## 3. Fichiers

| Fichier | Action |
|---|---|
| `src/services/responseStrategyEngine.ts` | CREE — Module central (290 lignes) |
| `src/modules/ai/ai-assist-routes.ts` | MODIFIE — Integration strategie |
| `src/modules/ai/ai-policy-debug-routes.ts` | MODIFIE — Exposition /ai/policy/effective |

## 4. Delivery Safety Policy

### Probleme corrige
Quand `tracking_code` est absent/null, l'IA NE DOIT JAMAIS affirmer :
- "la commande est en preparation"
- "la commande n'est pas expediee"
- "votre colis n'a pas ete envoye"

### Logique
```
if tracking_code == null:
    if today < deliveryWindow.latest:
        → "Votre commande est en cours de traitement"
    else:
        → "La livraison semble depasser le delai prevu. Nous allons investiguer."
```

### Formulations autorisees
- "La commande est en cours de traitement"
- "La livraison est estimee dans le delai prevu"
- "Nous verifions actuellement l'etat de l'expedition"

### Formulations INTERDITES
- "La commande est en preparation"
- "La commande n'est pas encore expediee"
- "Votre colis n'a pas ete envoye"
- "Le colis est en cours de preparation"

## 5. Strategies implementees

| # | Strategy | Condition | Tone |
|---|---|---|---|
| 1 | WAIT_FOR_DELIVERY | Tracking absent + delai normal | polite |
| 2 | DELIVERY_DELAY_INVESTIGATION | Fenetre depassee | empathetic |
| 3 | REQUEST_INFORMATION | Infos manquantes (photos, motif) | variable |
| 4 | WARRANTY_PROCESS | Produit defectueux + garantie | empathetic |
| 5 | RETURN_PROCESS | Demande retour | neutral |
| 6 | FRAUD_SUSPECTED | Signaux fraude | neutral |
| 7 | CUSTOMER_AGGRESSIVE | Client agressif/menacant | **firm** |
| 8 | INFORMATIVE_RESPONSE | Question simple | polite |

## 6. Adaptation du ton

| Contexte client | Ton applique |
|---|---|
| Agressif/menacant | `firm` — ne cede pas |
| Frustre (retard, defaut) | `empathetic` — reconnait la frustration |
| Neutre | `neutral` — professionnel |
| Question simple | `polite` — rassurant |

## 7. Resultats des tests E2E

| Test | Scenario | Strategy | Tone | Delivery Safety | KBA |
|---|---|---|---|---|---|
| T0 policy/effective | delivered_not_received | DELIVERY_DELAY_INVESTIGATION | empathetic | tracking=false, passed=true | - |
| T1 ou est mon colis | delivery_delay | DELIVERY_DELAY_INVESTIGATION | empathetic | tracking=false, passed=true | 11.1 |
| T2 colis non arrive | delivered_not_received | DELIVERY_DELAY_INVESTIGATION | empathetic | tracking=false, passed=true | 10.6 |
| T3 produit casse | damaged_product | REQUEST_INFORMATION | empathetic | null | 9.5 |
| T4 client agressif | aggressive_customer | CUSTOMER_AGGRESSIVE | firm | null | 10.3 |
| T5 non-regression | - | - | - | All layers OK | - |

**5/5 tests PASS**

## 8. Non-regression

| Couche | Status |
|---|---|
| PH41 SAV Policy | Active (GLOBAL_POLICY + SAV_POLICY) |
| PH43 Historical | Active (HISTORICAL_CONTEXT) |
| PH44 Tenant Policy | Active (si configuree) |
| PH44.7 Order Context | Active (ORDER_CONTEXT) |
| PH45 Decision Tree | Active (DECISION_TREE) |
| PH46 Response Strategy | Active (RESPONSE_STRATEGY) |
| KBActions | Cout identique (9-11 KBA/requete) |

## 9. Observabilite

### decisionContext enrichi
```json
{
  "responseStrategy": {
    "type": "DELIVERY_DELAY_INVESTIGATION",
    "tone": "empathetic",
    "reason": "Fenetre de livraison depassee...",
    "deliverySafety": {
      "trackingAvailable": false,
      "deliveryWindowPassed": true
    }
  }
}
```

### /ai/policy/effective
Nouveau champ `responseStrategy` avec :
- strategyType, tone, reason, responseHints
- deliverySafety (trackingAvailable, deliveryWindowPassed, recommendedPhrasing)

## 10. Exemple de prompt injecte

```
=== RESPONSE STRATEGY (PH46) ===
Strategy: DELIVERY_DELAY_INVESTIGATION
Tone: Empathique — reconnait la frustration du client

⚠ DELIVERY SAFETY — Tracking absent :
Formulation recommandee : "La livraison semble depasser le delai prevu.
Nous allons verifier l'etat de votre expedition."
NE JAMAIS affirmer un statut d'expedition non confirme.

Conseils de reponse :
→ Reconnaitre le depassement du delai prevu
→ Proposer une investigation aupres du transporteur
→ Ne JAMAIS promettre un remboursement immediat
→ Donner un delai d'investigation (48-72h)

Formulations autorisees :
✓ "La livraison semble depasser le delai prevu"
✓ "Nous allons ouvrir une investigation aupres du transporteur"
✓ "Nous reviendrons vers vous sous 48 a 72 heures"

Formulations INTERDITES :
✗ "La commande est en preparation"
✗ "Nous allons vous rembourser immediatement"
✗ "Le colis est perdu"
✗ "la commande n'est pas encore expediee"
✗ "votre colis n'a pas ete envoye"
✗ "le colis est en cours de preparation"
=== FIN RESPONSE STRATEGY ===
```

## 11. Deploiement

| Env | Image | Status |
|---|---|---|
| **DEV** | `v3.5.54-ph46-response-strategy-dev` | DEPLOYE |
| **PROD** | `v3.5.53-ph45-decision-tree-prod` | INCHANGE |

## 12. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.53-ph45-decision-tree-dev -n keybuzz-api-dev
```

## 13. Stop Point

**PROD non deploye. Attente validation Ludovic.**
