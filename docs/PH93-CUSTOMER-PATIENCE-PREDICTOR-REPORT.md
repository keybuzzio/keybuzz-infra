# PH93 — Customer Patience Predictor Engine

**Date** : 14 mars 2026
**Environnement** : DEV uniquement
**Tag** : `v3.5.94-ph93-customer-patience-dev`
**Rollback** : `v3.5.93-ph92-marketplace-policy-dev`

---

## Objectif

Estimer la tolérance temporelle du client, le niveau de pression, et la probabilité d'escalade rapide. PH93 enrichit le contexte IA sans modifier aucune décision existante.

## Logique du moteur

### Score de patience

- **Score initial** : `0.60`
- Ajusté par les signaux détectés dans le message et le contexte conversation

### Signaux analysés (12)

| Signal | Poids | Description |
|---|---|---|
| delay_complaint | -0.15 | Plainte sur un délai |
| negative_intensity | -0.10 | Ton négatif |
| aggressive_language | -0.20 | Insultes/accusations |
| legal_threat | -0.35 | Menace juridique |
| multi_messages_short_interval | -0.10 | 3+ messages en < 1h |
| repeat_claims | -0.10 | 4+ messages inbound |
| refund_pressure | -0.10 | Pression remboursement |
| high_value_order | -0.05 | Commande >= 200€ |
| delivery_overdue | -0.15 | Livraison en retard |
| buyer_reputation_low | -0.10 | Client risqué/abusif |
| positive_tone | +0.15 | Ton positif |
| first_contact | +0.05 | Premier contact |

### Classification

| Score | Niveau | Tolérance |
|---|---|---|
| >= 0.75 | HIGH | 48h |
| 0.50 – 0.74 | MEDIUM | 24h |
| 0.30 – 0.49 | LOW | 12h |
| < 0.30 | CRITICAL | 4h |

### Risque d'escalade

Calculé comme `1 - score`, ajusté par :
- `legal_threat` : +0.15
- `aggressive_language` : +0.10
- `multi_messages_short_interval` : +0.05

### Enrichissement DB

Quand un `conversationId` est fourni, le moteur enrichit les signaux via :
- Comptage messages inbound < 1h (multi_messages)
- Comptage total inbound (repeat_claims)
- Premier contact (first_contact)
- Montant commande via order_ref (high_value_order)
- Statut livraison (delivery_overdue)

## Exemples

| Message | Patience | Score | Tolérance |
|---|---|---|---|
| "merci pour votre réponse" | HIGH | 0.75 | 48h |
| "toujours rien reçu" | LOW | 0.45 | 12h |
| "ça fait 10 jours" | LOW | 0.45 | 12h |
| "je porte plainte" | CRITICAL | 0.25 | 4h |
| "thank you for your help" | HIGH | 0.75 | 48h |
| "vous êtes des escrocs" | LOW | 0.40 | 12h |
| Multiple menaces combinées | CRITICAL | 0.00 | 4h |

## Position pipeline

```
PH92 Marketplace Policy
PH90 Cost Awareness
PH91 Buyer Reputation
PH93 Customer Patience Predictor  ← NOUVEAU
→ buildSystemPrompt
→ LLM
```

PH93 est positionné après PH91 pour pouvoir utiliser `buyerReputation.classification` comme signal d'entrée.

## Intégration

### decisionContext
```json
{
  "customerPatience": {
    "level": "LOW",
    "estimatedToleranceHours": 12,
    "escalationRisk": 0.67,
    "signals": ["delay_complaint", "negative_intensity"]
  }
}
```

### buildSystemPrompt
```
=== CUSTOMER PATIENCE PREDICTOR (PH93) ===
Customer patience level: LOW
Estimated tolerance window: 12 hours
Escalation risk: MEDIUM

Detected signals:
- delay_complaint
- negative_intensity

Guidance:
- respond quickly
- acknowledge frustration
- provide clear next step
- avoid procedural delays
=== END CUSTOMER PATIENCE PREDICTOR ===
```

Pour les clients HIGH sans signaux, le bloc est vide.

## Endpoint debug

```
GET /ai/customer-patience?tenantId=xxx&message=...
GET /ai/customer-patience?tenantId=xxx&conversationId=xxx
```

## Fichiers modifiés

| Fichier | Action |
|---|---|
| `src/services/customerPatienceEngine.ts` | CRÉÉ |
| `src/modules/ai/ai-assist-routes.ts` | MODIFIÉ (import, pipeline, prompt, decisionContext) |
| `src/modules/ai/ai-policy-debug-routes.ts` | MODIFIÉ (endpoint `/ai/customer-patience`) |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | MODIFIÉ |

## Résultats des tests

```
Tests: 23
Assertions: 51
PASS: 51
FAIL: 0
```

### Couverture

| Test | Scénario |
|---|---|
| T1 | Message poli → HIGH (4 assertions) |
| T2 | Plainte délai → score < 0.60 |
| T3 | "ça fait 10 jours" → LOW |
| T4 | Menace juridique → CRITICAL (4 assertions) |
| T5 | "où est mon colis" → delay_complaint |
| T6 | Langage agressif → score < 0.50 |
| T7 | Pression remboursement |
| T8 | Anglais poli → HIGH |
| T9 | Anglais angry + delay |
| T10 | Menaces multiples → CRITICAL (4 signaux) |
| T11 | Question neutre → MEDIUM |
| T12 | Auth 401 |
| T13 | tenantId 400 |
| T14 | message/conversationId 400 |
| T15 | Non-régression PH90 |
| T16 | Non-régression PH91 |
| T17 | Non-régression PH92 |
| T18 | Non-régression /health |
| T19 | Multi-tenant isolation |
| T20 | Idempotence |
| T21 | Message déçu → negative_intensity |
| T22 | Signal mixte positif + delay |
| T23 | Bornes score et risque (5 assertions) |

## Non-régression confirmée

- `/health` → OK
- `/ai/cost-awareness` (PH90) → OK
- `/ai/buyer-reputation` (PH91) → OK
- `/ai/marketplace-policy` (PH92) → OK
- `/ai/customer-patience` (PH93) → OK
- Pipeline PH41 → PH92 intact

## Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.93-ph92-marketplace-policy-dev -n keybuzz-api-dev
```
