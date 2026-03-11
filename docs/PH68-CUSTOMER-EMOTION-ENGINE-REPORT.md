# PH68 — Customer Emotion Engine

> Date : 11 mars 2026
> Environnement : DEV uniquement
> Version : v3.5.78-ph68-customer-emotion-dev

---

## 1. Objectif

Detecter l'etat emotionnel du client pour adapter la reponse IA. Complement PH53 (Tone) et PH54 (Intent) — PH68 ne les remplace pas.

## 2. Emotions detectees

| Emotion | Priorite | Description |
|---|---|---|
| `ANGRY` | 1 (plus haute) | Insultes, menaces juridiques, agressivite |
| `FRUSTRATED` | 2 | Retards repetes, deception, impatience |
| `ANXIOUS` | 3 | Inquietude, besoin de reassurance |
| `CONFUSED` | 4 | Incomprehension, demande de clarification |
| `SATISFIED` | 5 | Remerciement, satisfaction, resolution |
| `NEUTRAL` | fallback | Aucune emotion forte detectee |

## 3. Logique de detection

### Patterns FR/EN

Chaque emotion dispose de 9-12 patterns regex couvrant francais et anglais.

**ANGRY** : `arnaque`, `porter plainte`, `voleur`, `scam`, `sue you`, `unacceptable`, `!!!+`
**FRUSTRATED** : `toujours rien`, `ca fait X jours`, `ras le bol`, `still waiting`, `disappointed`, `??+`
**ANXIOUS** : `je m'inquiete`, `est-ce normal`, `urgent`, `worried`, `when will`
**CONFUSED** : `je ne comprends pas`, `que dois-je faire`, `confused`, `can you explain`
**SATISFIED** : `merci beaucoup`, `parfait`, `c'est regle`, `thank you`, `problem solved`

### Signaux d'intensite

| Signal | Condition | Boost |
|---|---|---|
| `excessive_exclamation` | >= 3 `!` | +0.05 |
| `excessive_questions` | >= 3 `?` | +0.03 |
| `caps_lock_detected` | >50% majuscules, texte >20 chars | +0.07 |
| `word_repetition` | Mot repete consecutivement | +0.03 |

### Signaux contextuels

| Source | Condition | Effet |
|---|---|---|
| PH53 Tone = FIRM/LEGAL_SAFE | Detection tone ferme | Signal `tone_firm_or_legal` |
| PH54 Intent = CUSTOMER_AGGRESSIVE | Detection intention agressive | Hint vers ANGRY |
| PH54 Intent = CUSTOMER_FRUSTRATION | Detection frustration | Hint vers FRUSTRATED |
| Conversation > 5 messages | Conversation longue | Signal `long_conversation` |

### Scoring

```
score = baseConfidence + patternBoost (max 0.15) + intensityBoost + contextHintBoost (0.05)
clamped [0, 0.98]
```

### Priorite de classification

Si plusieurs emotions matchent avec des scores proches (< 0.10 d'ecart), la priorite domine :
`ANGRY > FRUSTRATED > ANXIOUS > CONFUSED > SATISFIED > NEUTRAL`

## 4. Guidance par emotion

| Emotion | Guidance |
|---|---|
| ANGRY | Acknowledger la colere, rester calme, eviter le defensif, proposer une resolution |
| FRUSTRATED | Acknowledger la frustration, s'excuser, fournir un prochain step concret |
| ANXIOUS | Rassurer avec des faits, donner un timeline clair, ton calme |
| CONFUSED | Expliquer etape par etape, eviter le jargon, proposer de clarifier |
| SATISFIED | Acknowledger le feedback positif, confirmer la resolution |
| NEUTRAL | Repondre professionnellement, adresser directement la demande |

## 5. Integration pipeline

### Position

```
PH53 Customer Tone
PH54 Customer Intent
PH68 Customer Emotion   ← nouveau
PH55 Fraud Pattern
...
```

### Fichiers modifies

| Fichier | Modification |
|---|---|
| `src/services/customerEmotionEngine.ts` | **Nouveau** |
| `src/modules/ai/ai-assist-routes.ts` | Import + pipeline block + buildSystemPrompt + decisionContext |
| `src/modules/ai/ai-policy-debug-routes.ts` | Import + endpoint debug |

### Prompt block

```
=== CUSTOMER EMOTION ENGINE ===
Detected emotion: FRUSTRATED
Confidence: 0.82

Guidance:
- acknowledge the customer frustration
- apologize for the inconvenience
- provide a concrete next step with timeline
- avoid generic responses
=== END CUSTOMER EMOTION ENGINE ===
```

### Decision context

```json
{
  "customerEmotion": {
    "emotion": "FRUSTRATED",
    "confidence": 0.82,
    "signals": ["delay_complaint", "negative_intensity"],
    "guidance": ["acknowledge the customer frustration", "apologize for the inconvenience"]
  }
}
```

## 6. Endpoint debug

```
GET /ai/customer-emotion?tenantId=ecomlg-001&message=toujours%20rien%20recu
```

## 7. Tests

```
Tests: 18 | Assertions: 36 | PASS: 36 | FAIL: 0
RESULT: ALL PASS
```

| # | Test | Resultat |
|---|---|---|
| T1 | Message neutre | NEUTRAL — PASS |
| T2 | Retard livraison FR | FRUSTRATED — PASS |
| T3 | Insultes + menaces FR | ANGRY — PASS |
| T4 | Inquietude FR | ANXIOUS — PASS |
| T5 | Confusion FR | CONFUSED — PASS |
| T6 | Satisfaction FR | SATISFIED — PASS |
| T7 | Frustration EN | FRUSTRATED — PASS |
| T8 | Colere EN | ANGRY — PASS |
| T9 | Message ambigu | Stable — PASS |
| T10 | Message vide | NEUTRAL — PASS |
| T11 | Context AGGRESSIVE | ANGRY boost — PASS |
| T12 | Context FRUSTRATION | FRUSTRATED — PASS |
| T13 | CAPS LOCK | Intensity boost — PASS |
| T14 | Exclamation excessive | ANGRY/FRUSTRATED — PASS |
| T15 | Confusion EN | CONFUSED — PASS |
| T16 | Satisfaction EN | SATISFIED — PASS |
| T17 | Priorite ANGRY > FRUSTRATED | ANGRY — PASS |
| T18 | Non-regression KBActions | Aucun impact — PASS |

## 8. Non-regression

Toutes les phases PH41-PH67 restent intactes. TypeScript : 0 erreur.

## 9. Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.77-ph67-knowledge-retrieval-dev -n keybuzz-api-dev
```

---

*Rapport genere le 11 mars 2026 — DEV uniquement.*
