# PH53 — Customer Tone Engine Report

> Date : 9 mars 2026
> Environnement : DEV
> API : `v3.5.63-ph53-customer-tone-dev`
> Rollback : `v3.5.62-ph527-expert-mode-dev`

## Objectif

Adapter automatiquement le ton des reponses IA selon le comportement du client. Le moteur ne modifie jamais les decisions SAV — il agit uniquement sur la forme.

## Tons disponibles

| Ton | Description | Declencheur |
|-----|-------------|-------------|
| POLITE | Reponse standard polie | Client normal/trusted |
| EMPATHETIC | Empathie, reconaissance frustration | Retard livraison, colis manquant, frustration |
| NEUTRAL | Factuel, technique | Investigation, defaut produit, haute valeur |
| FIRM | Ferme mais professionnel | Client agressif, insultes |
| LEGAL_SAFE | Precautions juridiques | Fraude suspectee, client RISKY, menaces legales |

## Logique de decision (priorite descendante)

```
1. Fraude suspectee OU client RISKY      → LEGAL_SAFE (conf: 0.90)
2. Client agressif OU insultes detectees  → FIRM       (conf: 0.88)
3. Retard livraison / colis manquant      → EMPATHETIC (conf: 0.85-0.92)
4. Frustration detectee (non-livraison)   → EMPATHETIC (conf: 0.78)
5. Defaut produit / investigation         → NEUTRAL    (conf: 0.75)
6. Client TRUSTED                         → POLITE     (conf: 0.88)
7. Commande HIGH/CRITICAL_VALUE           → NEUTRAL    (conf: 0.72)
8. Default                                → POLITE     (conf: 0.70)
```

## Signaux utilises

| Signal | Source |
|--------|--------|
| `savScenario` | PH41 SAV Classification |
| `customerRiskCategory` | PH47 Customer Risk Engine |
| `orderValueCategory` | PH48 Product Value Awareness |
| `isAggressive` | Detection patterns (regex FR/EN) |
| `messageFrustration` | Detection patterns (regex FR/EN) |
| `refundAllowed` | PH49 Refund Protection |

## Detection de patterns

Le moteur analyse le dernier message client avec des patterns regex :
- **Agression** : insultes, menaces legales, vocabulaire agressif (FR + EN)
- **Frustration** : deception, impatience, delais, urgence (FR + EN)

## Pipeline IA final

```
 1. Base Prompt
 2. SAV Policy (PH41)
 3. Tenant Policy (PH44)
 4. Historical Resolution (PH43)
 5. Decision Tree (PH45)
 6. Response Strategy (PH46)
 7. Refund Protection (PH49)
 8. Merchant Behavior (PH50)
 9. Adaptive Response (PH52)
10. Customer Tone Engine (PH53) ← NEW
11. Order Context
12. Supplier Context
13. Tenant Rules
14. LLM
```

## Bloc prompt injecte

```
=== CUSTOMER TONE ENGINE (PH53) ===
Tone: EMPATHETIC
Confidence: 92%
Reason: delivery_delay_with_frustration

Instruction:
Adopt an empathetic tone acknowledging the customer's frustration or inconvenience.
Show understanding of their situation.
Remain professional and avoid admitting liability.
=== END CUSTOMER TONE ENGINE ===
```

## Fichiers crees/modifies

| Fichier | Action |
|---------|--------|
| `src/services/customerToneEngine.ts` | **Cree** — service complet |
| `src/modules/ai/ai-assist-routes.ts` | Modifie — pipeline + decisionContext |
| `src/modules/ai/ai-policy-debug-routes.ts` | Modifie — debug endpoint + interface |

## Endpoint debug

```
GET /ai/customer-tone?tenantId=...&scenario=...&message=...&riskCategory=...&valueCategory=...
```

Retour :
```json
{
  "tenantId": "ecomlg-001",
  "tone": "EMPATHETIC",
  "confidence": 0.92,
  "reason": "delivery_delay_with_frustration",
  "signalsUsed": ["message_frustration_detected", "scenario:delivery_delay", "delivery_empathy_trigger"]
}
```

## decisionContext

```json
{
  "customerTone": {
    "tone": "NEUTRAL",
    "confidence": 0.72,
    "reason": "high_value_order_caution",
    "signalsUsed": ["scenario:unknown", "risk:WATCH", "value:CRITICAL_VALUE"]
  }
}
```

## Tests (10/10)

| # | Scenario | Tone attendu | Resultat |
|---|----------|-------------|---------|
| 1 | Client normal, remboursement | POLITE | PASS |
| 2 | Client frustre, retard livraison | EMPATHETIC | PASS |
| 3 | Client agressif, insultes | FIRM | PASS |
| 4 | Client RISKY, menace | LEGAL_SAFE | PASS |
| 5 | Defaut produit, investigation | NEUTRAL | PASS |
| 6 | Client TRUSTED | POLITE (haute conf) | PASS |
| 7 | Colis manquant | EMPATHETIC | PASS |
| 8 | Commande CRITICAL_VALUE | NEUTRAL | PASS |
| 9 | Anglais + frustration | EMPATHETIC | PASS |
| 10 | Non-regression /ai/assist | customerTone present | PASS |

## Non-regression

- PH41 SAV Policy : intact
- PH45 Decision Tree : intact
- PH49 Refund Protection : intact
- PH50 Merchant Behavior : intact
- PH52 Adaptive Response : intact
- KBActions : aucun cout supplementaire
- Aucun appel marketplace

## Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.62-ph527-expert-mode-dev -n keybuzz-api-dev
```

## Infra

- Aucun nouveau service K8s
- Aucun nouveau CronJob
- Aucune migration DB
- Aucun nouveau secret
