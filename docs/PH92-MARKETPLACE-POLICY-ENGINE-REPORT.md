# PH92 — Marketplace Policy Engine

**Date** : 14 mars 2026
**Environnement** : DEV uniquement
**Tag** : `v3.5.93-ph92-marketplace-policy-dev`
**Rollback** : `v3.5.92-ph91-buyer-reputation-dev`

---

## Objectif

Créer un moteur de politique marketplace qui applique des règles SAV spécifiques selon la marketplace source de la conversation. Chaque marketplace a ses propres attentes en termes de ton, de politique de remboursement, de gestion des livraisons, de demande de preuves et d'escalade.

## Profils de politique

| Marketplace | Profil | Ton | Risque compliance |
|---|---|---|---|
| AMAZON | AMAZON_BUYER_PROTECTION | CONCILIATORY | HIGH |
| CDISCOUNT | CDISCOUNT_STANDARD | NEUTRAL_PROFESSIONAL | MEDIUM |
| OCTOPIA | OCTOPIA_STANDARD | PROCESS_ORIENTED | MEDIUM |
| FNAC | FNAC_DARTY_STANDARD | INSTITUTIONAL | MEDIUM |
| DARTY | FNAC_DARTY_STANDARD | INSTITUTIONAL | MEDIUM |
| MIRAKL | MIRAKL_STANDARD | PROCESS_ORIENTED | MEDIUM |
| GENERIC | GENERIC_ECOMMERCE | NEUTRAL_PROFESSIONAL | LOW |

## Guidelines par profil

### AMAZON_BUYER_PROTECTION
- Ton conciliant et empathique
- Ne pas rembourser trop vite — investiguer d'abord, sans refus abrupt
- Demander preuve poliment, jamais en ultimatum
- Éviter les promesses non tenables
- Escalader tôt si le cas est complexe
- Ne jamais pousser vers un A-to-Z ou feedback négatif

### CDISCOUNT_STANDARD
- Investigation structurée avant toute résolution
- Documentation obligatoire
- Traçabilité des étapes
- Ton professionnel et neutre

### OCTOPIA_STANDARD
- Orientation process et opérateur
- Documentation systématique
- Respect des SLA opérateur
- Ton professionnel

### FNAC_DARTY_STANDARD
- Approche institutionnelle et formelle
- Service client retail
- Demande d'éléments claire et ordonnée
- Process d'escalade formel

### MIRAKL_STANDARD
- Conformité SLA et process
- Documentation complète pour tout claim
- Escalade basée sur les breach SLA
- Communication traceable et auditable

### GENERIC_ECOMMERCE
- Bonnes pratiques e-commerce standard
- Ton professionnel et utile
- Investigation avant remboursement

## Logique de mapping

### Résolution marketplace

1. **Paramètre `marketplace`** : recherche directe dans les profils (case-insensitive)
2. **Paramètre `channel`** : mapping via table `CHANNEL_TO_MARKETPLACE`
3. **Préfixes** : `amazon-fr`, `amazon-de`, etc. → `AMAZON`
4. **Fallback** : `GENERIC`

### Channels supportés
`amazon`, `amazon-fr`, `amazon-de`, `amazon-it`, `amazon-es`, `amazon-nl`, `amazon-be`, `amazon-uk`, `cdiscount`, `cdiscount-fr`, `octopia`, `fnac`, `fnac-fr`, `darty`, `darty-fr`, `mirakl`

### Confidence
- `0.94` si résolu via channel ou marketplace explicite
- `0.50` si fallback (pas de channel/marketplace)

## Position dans le pipeline

```
PH61 Marketplace Intelligence (existant, non intégré pipeline)
PH92 Marketplace Policy Engine  ← NOUVEAU
PH90 Cost Awareness Engine
PH91 Buyer Reputation Engine
PH55 Fraud Pattern
PH63 Abuse Pattern
PH60 Decision Calibration
PH64 Resolution Prediction
PH69 Prompt Stability
PH70 Workflow
LLM
```

PH92 est positionné **avant** PH90 et PH91 dans le pipeline pour que les politiques marketplace soient disponibles comme contexte pour les moteurs suivants.

## Intégration

### decisionContext
```json
{
  "marketplacePolicy": {
    "marketplace": "AMAZON",
    "policyProfile": "AMAZON_BUYER_PROTECTION",
    "complianceRisk": "HIGH",
    "confidence": 0.94
  }
}
```

### buildSystemPrompt
```
=== MARKETPLACE POLICY ENGINE (PH92) ===
Marketplace: AMAZON
Policy profile: AMAZON_BUYER_PROTECTION
Tone: CONCILIATORY
Refund policy: CAUTIOUS
Delivery policy: INVESTIGATE_WITHOUT_BLAME
Evidence policy: REQUEST_POLITELY
Escalation policy: EARLY_IF_RISK
Compliance risk: HIGH

Guidelines:
- Amazon has strong buyer protection — never appear rigid or confrontational
- use a conciliatory and empathetic tone at all times
- do NOT refund too quickly — investigate first, but never refuse abruptly
- request evidence (photos, descriptions) politely, never as an ultimatum
- avoid promises you cannot guarantee (delivery dates, specific outcomes)
- escalate early if the buyer seems frustrated or the case is complex
- never push the buyer toward an A-to-Z claim or negative feedback
=== END MARKETPLACE POLICY ENGINE ===
```

Pour `GENERIC` avec risque LOW, le bloc est vide (pas de bruit dans le prompt).

## Endpoint debug

```
GET /ai/marketplace-policy?tenantId=xxx&marketplace=AMAZON
GET /ai/marketplace-policy?tenantId=xxx&channel=octopia
GET /ai/marketplace-policy?tenantId=xxx&conversationId=xxx
```

Retourne le profil complet avec guidelines, confidence, et source.

## Fichiers modifiés

| Fichier | Action |
|---|---|
| `src/services/marketplacePolicyEngine.ts` | CRÉÉ — moteur principal |
| `src/modules/ai/ai-assist-routes.ts` | MODIFIÉ — import, pipeline, buildSystemPrompt, decisionContext |
| `src/modules/ai/ai-policy-debug-routes.ts` | MODIFIÉ — endpoint `/ai/marketplace-policy` |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | MODIFIÉ — image v3.5.93 |

## Résultats des tests

```
Tests: 21
Assertions: 51
PASS: 51
FAIL: 0
```

### Couverture

| Test | Scénario |
|---|---|
| T1 | Amazon → AMAZON_BUYER_PROTECTION (8 assertions) |
| T2 | CDiscount → CDISCOUNT_STANDARD |
| T3 | Octopia via channel → OCTOPIA_STANDARD |
| T4 | Fnac → FNAC_DARTY_STANDARD |
| T5 | Darty → FNAC_DARTY_STANDARD |
| T6 | Mirakl → MIRAKL_STANDARD |
| T7 | Unknown → GENERIC fallback |
| T8 | Amazon via channel (confidence 0.94) |
| T9 | amazon-fr → AMAZON |
| T10 | cdiscount channel → CDISCOUNT |
| T11 | Aucun channel/marketplace → GENERIC fallback |
| T12 | Auth 401 sans X-User-Email |
| T13 | tenantId 400 requis |
| T14 | Non-régression PH90 |
| T15 | Non-régression PH91 |
| T16 | Non-régression /health |
| T17 | Multi-tenant isolation |
| T18 | Idempotence (2 appels identiques) |
| T19 | Darty via channel |
| T20 | fnac-fr via channel |
| T21 | GENERIC guidelines completeness |

## Non-régression confirmée

- `/health` → 200 OK
- `/ai/cost-awareness` → opérationnel
- `/ai/buyer-reputation` → opérationnel
- `/ai/marketplace-policy` → nouveau, opérationnel
- `/billing/current` → opérationnel
- Pipeline AI intact

## Contraintes respectées

- Aucun appel LLM
- Aucun coût KBActions
- Aucune modification DB
- Multi-tenant strict
- Aucun hardcodage tenant
- DEV uniquement
- GitOps strict

## Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.92-ph91-buyer-reputation-dev -n keybuzz-api-dev
```
