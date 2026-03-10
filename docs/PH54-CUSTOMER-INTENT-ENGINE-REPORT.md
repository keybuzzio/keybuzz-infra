# PH54 — Customer Intent Engine — Rapport

> Date : 9 mars 2026
> Auteur : Agent Cursor (CE)
> Status : DEV deploye, en attente validation PROD

---

## Objectif

Ajouter un moteur heuristique (regex + keywords) qui detecte l'intention reelle du client dans son message, sans appel LLM supplementaire. Permet d'eviter les remboursements prematures, mieux comprendre les demandes ambigues, anticiper les escalades, et orienter la strategie de reponse.

---

## Intents detectes (12)

| Intent | Description | Priorite |
|---|---|---|
| LEGAL_THREAT | Menace juridique (tribunal, avocat) | 1 |
| CUSTOMER_AGGRESSIVE | Ton agressif (arnaque, voleur) | 2 |
| FRAUD_SIGNAL | Incoherences (jamais commande, carte volee) | 3 |
| REFUND_REQUEST | Demande explicite de remboursement | 4 |
| RETURN_REQUEST | Souhait de retour produit | 5 |
| PRODUCT_DEFECT | Produit defectueux/casse | 6 |
| MISSING_ITEM | Article manquant | 7 |
| DELIVERY_DELAY | Livraison en retard | 8 |
| ORDER_STATUS | Suivi/statut commande | 9 |
| CUSTOMER_FRUSTRATION | Client frustre | 10 |
| INFORMATION_REQUEST | Question simple | 11 |
| GENERAL_CONTACT | Message generique | 12 |

---

## Algorithme

- Detection par regex patterns bilingues (FR + EN)
- 11 regles ordonnees par priorite
- Si aucun pattern ne match : `GENERAL_CONTACT` (confidence 0.5)
- Si plusieurs patterns matchent : le plus prioritaire gagne
- Boost de confiance si plusieurs patterns d'une meme categorie matchent (+0.03/pattern, max +0.10)
- Confiance de base : 0.65 a 0.92 selon l'intent

---

## Patterns par intent (exemples)

### ORDER_STATUS (priority 9, base 0.75)
- `ou est mon colis`, `suivi colis`, `tracking`, `statut commande`
- `where is my order`, `order status`, `track my`

### DELIVERY_DELAY (priority 8, base 0.78)
- `toujours rien recu`, `retard livraison`, `en retard`
- `still not received`, `delivery delay`, `hasn't arrived`

### REFUND_REQUEST (priority 4, base 0.85)
- `je veux un remboursement`, `remboursez moi`
- `refund me`, `money back`, `full refund`

### PRODUCT_DEFECT (priority 6, base 0.80)
- `defectueux`, `casse`, `ne fonctionne pas`
- `broken`, `damaged`, `defective`

### LEGAL_THREAT (priority 1, base 0.92)
- `tribunal`, `avocat`, `plainte`, `mise en demeure`
- `legal action`, `lawyer`, `court`, `lawsuit`

### CUSTOMER_AGGRESSIVE (priority 2, base 0.88)
- `arnaque`, `escroc`, `voleur`, `inadmissible`
- `scam`, `fraud`, `thief`, `pathetic`

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
11. Customer Intent (PH54)  <-- nouveau
12. Order Context
13. Supplier Context
14. Tenant Rules
15. LLM
```

---

## Fichiers modifies/crees

| Fichier | Action |
|---|---|
| `src/services/customerIntentEngine.ts` | CREE — moteur heuristique |
| `src/modules/ai/ai-assist-routes.ts` | MODIFIE — import, computation, prompt injection, decisionContext |
| `src/modules/ai/ai-policy-debug-routes.ts` | MODIFIE — interface, /policy/effective, GET /customer-intent |

---

## Endpoints

### GET /ai/customer-intent
- Parametres : `tenantId`, `message`
- Retourne : `{ intent, confidence, signals, matchedPatterns }`

### GET /ai/policy/effective (mis a jour)
- Ajoute `customerIntent` dans la reponse

### POST /ai/assist (mis a jour)
- Ajoute `customerIntent` dans `decisionContext`
- Inject `customerIntentPromptBlock` dans le system prompt

---

## Observabilite

### decisionContext
```json
{
  "customerIntent": {
    "intent": "DELIVERY_DELAY",
    "confidence": 0.78,
    "signals": ["late_delivery", "where_package"],
    "matchedPatterns": ["retard livraison"]
  }
}
```

### Logs console
```
[AI Assist] <requestId> PH54 Intent: DELIVERY_DELAY confidence:0.78 signals:late_delivery,where_package
```

---

## Resultats des tests (10/10 + non-regression)

| # | Message | Attendu | Obtenu | Confiance | Status |
|---|---|---|---|---|---|
| 1 | Ou est mon colis | ORDER_STATUS | ORDER_STATUS | 0.75 | PASS |
| 2 | Je n ai toujours rien recu | DELIVERY_DELAY | DELIVERY_DELAY | 0.78 | PASS |
| 3 | Je veux un remboursement | REFUND_REQUEST | REFUND_REQUEST | 0.88 | PASS |
| 4 | Produit casse ne fonctionne pas | PRODUCT_DEFECT | PRODUCT_DEFECT | 0.83 | PASS |
| 5 | Article manquant dans ma commande | MISSING_ITEM | MISSING_ITEM | 0.80 | PASS |
| 6 | Vous etes des voleurs arnaque | CUSTOMER_AGGRESSIVE | CUSTOMER_AGGRESSIVE | 0.91 | PASS |
| 7 | Je vais porter plainte au tribunal | LEGAL_THREAT | LEGAL_THREAT | 0.98 | PASS |
| 8 | Bonjour question sur la livraison | INFORMATION_REQUEST | INFORMATION_REQUEST | 0.71 | PASS |
| 9 | Mon colis est en retard | DELIVERY_DELAY | DELIVERY_DELAY | 0.81 | PASS |
| 10 | Merci beaucoup | GENERAL_CONTACT | GENERAL_CONTACT | 0.50 | PASS |

### Non-regression /ai/assist
- HTTP 200
- `customerIntent` present dans `decisionContext` : PASS
- `customerTone` present dans `decisionContext` : PASS
- Pipeline stable, pas d'erreur

---

## Impact

- Aucun appel LLM supplementaire
- Aucun impact KBActions
- Aucune modification des decisions SAV
- Zero impact base de donnees
- Refund protection et decision tree intacts

---

## Deploiement

| Env | Image | Status |
|---|---|---|
| DEV | `v3.5.64-ph54-customer-intent-dev` | Deploye |
| PROD | — | En attente validation |

### Rollback
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.63-ph53-customer-tone-dev -n keybuzz-api-dev
```
