# PH56 — Delivery Intelligence Layer — Rapport

> Date : 10 mars 2026
> Auteur : Agent Cursor (CE)
> Status : DEV deploye, en attente validation PROD

---

## Objectif

Ameliorer le raisonnement de l'IA sur les situations de livraison en utilisant uniquement les donnees disponibles. Ne jamais inventer de tracking, ne jamais promettre de remboursement, ne jamais conclure qu'un colis est perdu sans preuve.

---

## Principes de securite

- JAMAIS inventer un numero de tracking absent
- JAMAIS dire "en preparation" quand le statut est "shipped"
- JAMAIS promettre de remboursement
- JAMAIS conclure a une perte sans preuve
- Toujours raisonner a partir des donnees reelles disponibles

---

## Scenarios detectes (8)

| # | Scenario | Confiance | Description |
|---|---|---|---|
| 1 | `DELIVERED_CUSTOMER_CLAIMS_NOT_RECEIVED` | 0.87 | Marque livre mais client dit non recu |
| 2 | `POSSIBLE_THIRD_PARTY_RECEIPT` | 0.78 | Mention voisin/point relais/foyer |
| 3 | `DELIVERY_INVESTIGATION_NEEDED` | 0.82-0.88 | Investigation necessaire (non recu + fenetre expiree ou haute valeur) |
| 4 | `DELIVERY_WINDOW_EXPIRED` | 0.84 | Fenetre de livraison depassee |
| 5 | `SHIPPED_NO_TRACKING` | 0.76 | Expedie mais pas de tracking |
| 6 | `DELIVERY_WINDOW_ACTIVE` | 0.81 | Fenetre encore active |
| 7 | `PREPARING_OR_PROCESSING_UNCERTAIN` | 0.60 | Statut incertain |
| 8 | `DELIVERY_INFORMATION_ONLY` | 0.72 | Question simple sur la livraison |

---

## Regles cles

### Regle 1 — Tracking absent
- Ne JAMAIS dire "la commande est en preparation"
- Dire "en cours d'acheminement" ou "nous verifions l'etat"
- Mentionner la fenetre estimee si disponible

### Regle 2 — Fenetre active
- Rassurer le client
- Rappeler la date estimee
- Ne pas ouvrir d'investigation prematuree

### Regle 3 — Fenetre depassee
- Reconnaitre le retard
- Proposer de verifier l'etat
- Ne pas promettre de remboursement

### Regle 4 — Livre mais client dit non recu
- Ne pas contredire le client
- Suggerer : boite aux lettres, voisins, foyer, point relais

### Regle 5 — Haute valeur
- Plus de prudence, plus d'investigation
- Pas de remboursement direct

---

## Donnees utilisees

| Source | Champ | Usage |
|---|---|---|
| orderContext | status | Statut commande (shipped, delivered...) |
| orderContext | fulfillmentChannel | Canal d'expedition |
| orderContext | purchaseDate | Date d'achat |
| orderContext | tracking | Numero de suivi |
| orderContext | deliveryWindow | Fenetre estimee (earliest/latest) |
| PH54 | customerIntent | Intent client detecte |
| PH48 | orderValueCategory | Categorie valeur commande |
| PH55 | fraudRisk | Niveau risque fraude |
| message | text | Contenu du message client |

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
12. Fraud Pattern (PH55)
13. Delivery Intelligence (PH56)  <-- nouveau
14. Order Context
15. Supplier Context
16. Tenant Rules
17. LLM
```

---

## Exemple prompt block

```
=== DELIVERY INTELLIGENCE LAYER (PH56) ===
Delivery scenario: DELIVERY_WINDOW_EXPIRED
Confidence: 84%

Signals:
- delivery_window_expired
- tracking_absent

Guidance:
- acknowledge_delay
- offer_to_investigate
- do_not_claim_not_shipped

La fenetre de livraison est depassee. Reconnaitre le retard
et proposer de verifier l'etat de l'expedition.
Ne pas promettre de remboursement.
=== END DELIVERY INTELLIGENCE LAYER ===
```

---

## Fichiers modifies/crees

| Fichier | Action |
|---|---|
| `src/services/deliveryIntelligenceEngine.ts` | CREE — moteur 8 scenarios |
| `src/modules/ai/ai-assist-routes.ts` | MODIFIE — import, computation, prompt injection, decisionContext |
| `src/modules/ai/ai-policy-debug-routes.ts` | MODIFIE — interface, /policy/effective, GET /delivery-intelligence |

---

## Endpoints

### GET /ai/delivery-intelligence
- Parametres : `tenantId`, `message`, `conversationId`, `orderStatus`, `deliveryWindowLatest`, `markedAsDelivered`, `trackingAvailable`
- Retourne : `{ deliveryScenario, confidence, signals, guidance }`

### GET /ai/policy/effective (mis a jour)
- Ajoute `deliveryIntelligence` dans la reponse

### POST /ai/assist (mis a jour)
- Ajoute `deliveryIntelligence` dans `decisionContext`
- Inject `deliveryIntelligencePromptBlock` dans le system prompt (position 13)

---

## Resultats des tests (12/12 + non-regression)

| # | Scenario | Attendu | Obtenu | Confiance | Signaux | Status |
|---|---|---|---|---|---|---|
| 1 | Shipped no tracking + fenetre active | SHIPPED_NO_TRACKING | SHIPPED_NO_TRACKING | 0.76 | status_shipped, tracking_absent | PASS |
| 2 | Fenetre expiree + non recu | DELIVERY_INVESTIGATION_NEEDED | DELIVERY_INVESTIGATION_NEEDED | 0.82 | customer_claims_not_received, delivery_window_expired, tracking_absent | PASS |
| 3 | Fenetre expiree sans reclamation | DELIVERY_WINDOW_EXPIRED | DELIVERY_WINDOW_EXPIRED | 0.84 | delivery_window_expired, tracking_absent | PASS |
| 4 | Delivered + client dit non recu | DELIVERED_CUSTOMER_CLAIMS_NOT_RECEIVED | DELIVERED_CUSTOMER_CLAIMS_NOT_RECEIVED | 0.87 | marked_delivered, customer_claims_not_received | PASS |
| 5 | Delivered + mention voisin | POSSIBLE_THIRD_PARTY_RECEIPT | POSSIBLE_THIRD_PARTY_RECEIPT | 0.78 | third_party_mention_detected, marked_delivered | PASS |
| 6 | Non delivered + tiers mention | POSSIBLE_THIRD_PARTY_RECEIPT | POSSIBLE_THIRD_PARTY_RECEIPT | 0.78 | third_party_mention_detected, claims_not_received | PASS |
| 7 | Non recu + fenetre expiree | DELIVERY_INVESTIGATION_NEEDED | DELIVERY_INVESTIGATION_NEEDED | 0.82 | customer_claims_not_received, delivery_window_expired, tracking_absent | PASS |
| 8 | Shipped no tracking | SHIPPED_NO_TRACKING | SHIPPED_NO_TRACKING | 0.76 | status_shipped, tracking_absent | PASS |
| 9 | Anglais non recu + expired | DELIVERY_INVESTIGATION_NEEDED | DELIVERY_INVESTIGATION_NEEDED | 0.82 | customer_claims_not_received, delivery_window_expired, tracking_absent | PASS |
| 10 | Aucun contexte livraison | PREPARING_OR_PROCESSING_UNCERTAIN | PREPARING_OR_PROCESSING_UNCERTAIN | 0.60 | status_uncertain, no_delivery_window | PASS |
| 11 | Statut pending | PREPARING_OR_PROCESSING_UNCERTAIN | PREPARING_OR_PROCESSING_UNCERTAIN | 0.60 | status_uncertain, no_delivery_window | PASS |
| 12 | Delivered + point relais | POSSIBLE_THIRD_PARTY_RECEIPT | POSSIBLE_THIRD_PARTY_RECEIPT | 0.78 | third_party_mention_detected, marked_delivered | PASS |

### Non-regression /ai/assist
- HTTP 200
- `deliveryIntelligence` present dans `decisionContext` : PASS (`DELIVERY_WINDOW_EXPIRED`)
- `fraudPattern` present : PASS
- `customerIntent` present : PASS
- Pipeline stable

---

## Impact

- Aucun appel LLM supplementaire
- Aucun impact KBActions
- Aucune action transport reelle
- Aucune promesse de remboursement
- Aucun envoi marketplace
- Zero impact base de donnees
- Tous les layers precedents intacts

---

## Deploiement

| Env | Image | Status |
|---|---|---|
| DEV | `v3.5.66-ph56-delivery-intelligence-dev` | Deploye |
| PROD | — | En attente validation |

### Rollback
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.65-ph55-fraud-pattern-dev -n keybuzz-api-dev
```
