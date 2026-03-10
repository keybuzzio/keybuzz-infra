# PH60 — AI Decision Calibration Engine

> Date : 2026-03-01
> Auteur : Cursor CE
> Environnement : DEV
> Image : `v3.5.70-ph60-decision-calibration-dev`
> Rollback : `v3.5.69-ph59-context-compression-dev`

---

## Objectif

Calibrer le niveau de decision autorise pour l'IA selon le risque economique, le profil client, les signaux de fraude et la complexite du dossier.

PH60 determine si l'IA peut :
- **AUTO** : gerer le cas de maniere autonome
- **GUIDED** : proposer des actions mais laisser l'agent valider
- **HUMAN_REQUIRED** : escalader obligatoirement vers un agent humain

PH60 est une couche d'**arbitrage**, pas de decision SAV. Il ne remplace ni Refund Protection (PH49), ni Decision Tree (PH45), ni aucune couche existante.

---

## Niveaux de decision

### AUTO
Autorise quand toutes les conditions sont remplies :
- `orderValue` = LOW (< 30 EUR)
- `fraudRisk` = LOW
- `customerRisk` != RISKY / HIGH_RISK / BLACKLISTED
- Pas de menace legale
- Pas de delivery delay actif
- Pas de dossier fournisseur en cours

### GUIDED
Declenche si :
- Valeur commande MEDIUM (50-200 EUR)
- Delivery delay detecte
- Fraud risk = MEDIUM (sans high value)
- Ton agressif du client
- Information manquante du client
- Dossier fournisseur actif
- Scenario SAV impliquant un retard livraison

### HUMAN_REQUIRED
Declenche si (un seul suffit) :
- Fraud risk = HIGH
- Menace legale (LEGAL_THREAT, LEGAL_ACTION, COMPLAINT_AUTHORITY...)
- Valeur critique (>= 200 EUR) + demande remboursement
- Client flagge RISKY / HIGH_RISK / BLACKLISTED
- Fraud MEDIUM + valeur >= 100 EUR

---

## Entrees

| Parametre | Source | Usage |
|---|---|---|
| `customerRiskCategory` | PH47 | Profil risque client |
| `orderValueCategory` | PH48 | Categorie valeur commande |
| `orderValue` | PH48 | Montant commande |
| `fraudRisk` | PH55 | Niveau fraude detecte |
| `customerIntent` | PH54 | Intention client |
| `customerTone` | PH53 | Ton client |
| `merchantBehaviorCategory` | PH50 | Profil vendeur |
| `savScenario` | PH41 | Scenario SAV |
| `refundAllowed` | PH49 | Decision remboursement amont |
| `conversationMemoryFlags` | PH58 | Drapeaux memoire |
| `hasDeliveryDelay` | Contexte | Retard livraison |
| `hasSupplierCase` | Contexte | Dossier fournisseur |

---

## Position dans le pipeline

```
PH53 Customer Tone
PH54 Customer Intent
PH55 Fraud Pattern
PH60 Decision Calibration ← NOUVEAU
PH56 Delivery Intelligence
PH57 Supplier/Warranty
PH58 Conversation Memory
PH59 Context Compression
```

PH60 a besoin des resultats de PH47-PH55 pour calibrer.
PH56+ beneficient du niveau de decision pour affiner leurs guidances.

---

## Bloc prompt

```
=== DECISION CALIBRATION ENGINE (PH60) ===
Decision level: GUIDED
Refund allowed: no
Replacement allowed: yes
Escalation recommended: false
Confidence: 78%
Reason: Medium value order requires guided decision

This case requires careful handling. Suggest actions but do not commit.
Propose next steps and let the agent decide on financial commitments.
=== END DECISION CALIBRATION ENGINE ===
```

---

## Decision Context

```json
{
  "decisionCalibration": {
    "level": "GUIDED",
    "refundAllowed": false,
    "replacementAllowed": true,
    "escalationRecommended": false,
    "reason": "Medium value order requires guided decision",
    "confidence": 0.78,
    "signalsUsed": ["medium_value"]
  }
}
```

---

## Endpoint debug

```
GET /ai/decision-calibration?tenantId=xxx&orderValue=150&fraudRisk=MEDIUM&customerIntent=REFUND_DEMAND
```

Parametres query : `customerRiskCategory`, `orderValueCategory`, `orderValue`, `fraudRisk`, `customerIntent`, `customerTone`, `savScenario`, `refundAllowed`, `hasDeliveryDelay`, `hasSupplierCase`.

Aucun appel LLM. Aucun debit KBActions.

---

## Tests

15 tests, 42 assertions — **42/42 PASS**

| Test | Scenario | Niveau attendu | Resultat |
|---|---|---|---|
| T1 | Low value + low risk | AUTO | PASS |
| T2 | High value + refund request | HUMAN_REQUIRED | PASS |
| T3 | Delivery delay | GUIDED | PASS |
| T4 | Fraud HIGH | HUMAN_REQUIRED | PASS |
| T5 | Legal threat | HUMAN_REQUIRED | PASS |
| T6 | Trusted customer + defect | AUTO | PASS |
| T7 | Medium value | GUIDED | PASS |
| T8 | Medium fraud + high value | HUMAN_REQUIRED | PASS |
| T9 | Risky customer | HUMAN_REQUIRED | PASS |
| T10 | Aggressive tone | GUIDED | PASS |
| T11 | Supplier case active | GUIDED | PASS |
| T12 | Refund blocked upstream | refundAllowed=false | PASS |
| T13 | Empty context | AUTO (stable) | PASS |
| T14 | Prompt block structure | Headers/footer/content | PASS |
| T15 | Medium fraud alone | GUIDED (not HUMAN) | PASS |

---

## Non-regression

| Couche | Impact | Status |
|---|---|---|
| PH41-PH55 | Aucun — executees avant PH60 | OK |
| PH49 Refund Protection | Aucun — PH60 lit mais ne modifie pas | OK |
| PH45 Decision Tree | Aucun — PH60 lit mais ne modifie pas | OK |
| PH56-PH59 | Aucun — executees apres PH60 | OK |
| KBActions | 0 impact | OK |
| decisionContext | Enrichi avec champ decisionCalibration | OK |

---

## Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.69-ph59-context-compression-dev -n keybuzz-api-dev
```

---

## Cout

| Metrique | Valeur |
|---|---|
| Appels LLM supplementaires | 0 |
| Impact KBActions | 0 |
| Complexite ajoutee | 1 service (277 lignes), 6 points integration |
