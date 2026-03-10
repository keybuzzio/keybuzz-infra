# PH64 — Resolution Prediction Engine

> Date : 2026-03-01
> Phase : PH64
> Environnement : DEV

---

## Objectif

Estimer la resolution la plus probable pour un cas SAV donne, sans executer d'action ni appeler de LLM.

PH64 est une **couche predictive interne** qui enrichit le contexte decisionnelle de l'IA en calculant des probabilites de resolution a partir des signaux existants (PH41-PH63).

---

## Difference Decision vs Prediction

| Concept | Moteur | Comportement |
|---------|--------|-------------|
| **Decision** | PH45 Decision Tree, PH49 Refund Protection, PH60 Calibration | Bloque, autorise, escalade — **executif** |
| **Prediction** | PH64 Resolution Prediction | Estime la resolution probable — **informatif** |

PH64 ne prend aucune decision. Il nourrit le prompt IA d'une projection probabiliste pour aider a la formulation de la reponse.

---

## Resolutions predites (7)

| Type | Description |
|------|-------------|
| `INVESTIGATION` | Litige livraison, non recu, investigation transport |
| `WARRANTY_PATH` | Voie garantie / fournisseur / SAV technique |
| `REPLACEMENT` | Remplacement produit preferable |
| `REFUND` | Remboursement probable (si autorise) |
| `INFORMATION_REQUEST` | Informations manquantes avant resolution |
| `HUMAN_REVIEW` | Cas trop complexe / risque / sensible |
| `NO_ACTION_NEEDED` | Aucune resolution necessaire |

---

## Logique de scoring

Le moteur utilise un systeme de **scoring heuristique pondere** ou chaque signal contribue au score d'une ou plusieurs resolutions.

### Regles principales

| Regle | Condition | Effet |
|-------|-----------|-------|
| R1 — Livraison | savScenario delivery + window expired | INVESTIGATION +0.60 |
| R2 — Defaut produit | defect + evidence + warranty eligible | WARRANTY_PATH +0.80, REPLACEMENT +0.30 |
| R3 — Faible valeur | orderValue < 30 EUR | REFUND +0.10, REPLACEMENT +0.10 |
| R4 — Fraud/Abuse HIGH | fraudRisk HIGH ou abuseRisk HIGH | HUMAN_REVIEW +0.35, REFUND cap 0.05-0.10 |
| R5 — Manque infos | no evidence + defect/refund | INFORMATION_REQUEST +0.30 |
| R6 — Legal threat | intent contains legal/avocat/tribunal | HUMAN_REVIEW +0.30 |
| R7 — Calibration | decisionLevel = HUMAN_REQUIRED | HUMAN_REVIEW +0.40 |
| R8 — Merchant pref | warranty_first / replacement_preferred | Boost correspondant +0.15 |

### Caps de securite

- Si `refundBlocked` ou `refundProtectionActive` : REFUND plafonne a 0.15
- Si `refundAllowed === false` : REFUND plafonne a 0.10
- Si `abuseRisk HIGH` ou `fraudRisk HIGH` : INFORMATION_REQUEST ne peut depasser HUMAN_REVIEW
- Tous les scores sont clampes a [0, 1]

---

## Donnees utilisees

| Source | Champ utilise |
|--------|---------------|
| PH45 Decision Tree | savScenario |
| PH47 Customer Risk | customerRiskCategory |
| PH48 Product Value | orderValue, orderValueCategory |
| PH49 Refund Protection | refundAllowed |
| PH50 Merchant Behavior | category |
| PH54 Customer Intent | customerIntent |
| PH55 Fraud Pattern | fraudRisk |
| PH56 Delivery Intelligence | deliveryScenario, deliveryWindowExpired |
| PH57 Supplier/Warranty | warrantyEligible, supplierPathAvailable |
| PH58 Conversation Memory | askedForPhotos, investigationOpened, warrantyPathMentioned, customerProvidedAdditionalInfo |
| PH60 Decision Calibration | decisionLevel, refundAllowed, escalationRecommended |
| PH61 Marketplace Intelligence | marketplace, escalationRisk |
| PH62 Evidence Intelligence | evidencePresent, evidenceTypes, possibleDamageEvidence |
| PH63 Abuse Pattern | abuseRisk |

---

## Integration dans le pipeline

Position : **apres PH59 (Context Compression), avant buildSystemPrompt()**

### Prompt block

```
=== RESOLUTION PREDICTION ENGINE ===
Predicted resolution: WARRANTY_PATH
Confidence: 0.78

Candidate resolutions:
- WARRANTY_PATH: 0.78
- INVESTIGATION: 0.52
- REPLACEMENT: 0.31

Based on:
- merchant_behavior_warranty_first
- product_defect_detected
- warranty_eligible

Guidance:
- prefer_warranty_before_refund
=== END RESOLUTION PREDICTION ENGINE ===
```

### decisionContext

```json
{
  "resolutionPrediction": {
    "predictedResolution": "WARRANTY_PATH",
    "confidence": 0.78,
    "candidateResolutions": [...],
    "basedOn": [...],
    "guidance": [...]
  }
}
```

---

## Endpoint debug

`GET /ai/resolution-prediction?tenantId=xxx&savScenario=xxx&customerIntent=xxx`

- Aucun appel LLM
- Aucun debit KBActions
- Retourne le resultat brut du moteur

---

## Tests

15 tests, 29 assertions — tous passes.

| Test | Scenario | Prediction attendue | Resultat |
|------|----------|---------------------|----------|
| T1 | Delivery non recu + window expired | INVESTIGATION | PASS |
| T2 | Defect + evidence + warranty | WARRANTY_PATH | PASS |
| T3 | Low value + defect + refund | REFUND/REPLACEMENT/WARRANTY | PASS |
| T4 | Fraud HIGH + refund | HUMAN_REVIEW | PASS |
| T5 | No evidence + defect | INFORMATION_REQUEST high | PASS |
| T6 | Replacement preference | REPLACEMENT elevated | PASS |
| T7 | Amazon high value dispute | HUMAN_REVIEW | PASS |
| T8 | Abuse HIGH + refund | HUMAN_REVIEW | PASS |
| T9 | Strong evidence + defect | WARRANTY_PATH | PASS |
| T10 | Info already provided | INFO_REQUEST reduced | PASS |
| T11 | English classification | INVESTIGATION | PASS |
| T12 | Legal threat | HUMAN_REVIEW | PASS |
| T13 | Empty context | NO_ACTION_NEEDED | PASS |
| T14 | Refund blocked calibration | REFUND <= 0.10 | PASS |
| T15 | Structure validation | All fields present | PASS |

---

## Non-regression

PH64 n'affecte aucun moteur existant :
- Zero appel LLM supplementaire
- Zero impact KBActions
- Zero action automatique
- Compilation TypeScript : zero erreur
- PH41-PH63 : intacts (PH64 consomme leurs sorties, ne les modifie pas)

---

## Fichiers modifies

| Fichier | Modification |
|---------|-------------|
| `src/services/resolutionPredictionEngine.ts` | **CREE** — moteur de prediction |
| `src/modules/ai/ai-assist-routes.ts` | Import + invocation pipeline + prompt block + decisionContext |
| `src/modules/ai/ai-policy-debug-routes.ts` | Endpoint debug GET /resolution-prediction |

---

## Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.73c-ph63b-softguard-dev -n keybuzz-api-dev
```

---

## Image DEV

- Tag : `v3.5.74-ph64-resolution-prediction-dev`
- Rollback : `v3.5.73c-ph63b-softguard-dev`
