# PH52 — Adaptive Response Tuning Report

> Date : 9 mars 2026
> Environnement : DEV
> Image : `v3.5.60-ph52-adaptive-response-dev`
> Rollback : `v3.5.59-ph51-conversation-learning-dev`

---

## 1. Objectif

PH52 utilise les données d'apprentissage de PH51 (Conversation Learning Loop) pour ajuster
la priorité des stratégies de réponse de l'IA, sans modifier les règles SAV ni les décisions.

PH52 est un **modulateur de stratégie** uniquement :
- Ne change aucune règle SAV (PH41, PH45)
- Ne contourne jamais Refund Protection (PH49)
- N'autorise aucune nouvelle action
- Ne modifie pas le coût KBActions
- Influence uniquement le wording et la priorité des suggestions

## 2. Position dans le Pipeline IA

```
1  Base Prompt
2  SAV Policy (PH41)
3  Tenant Policy (PH44)
4  Historical Engine (PH43)
5  Decision Tree (PH45)
6  Response Strategy (PH46)
7  Refund Protection (PH49)
8  Merchant Behavior (PH50)
9  Adaptive Response Tuning (PH52) ← NOUVEAU
10 Order Context
11 Supplier Context
12 Tenant Rules
```

## 3. Architecture

### Service
- **Fichier** : `src/services/adaptiveResponseEngine.ts`
- **Fonctions** :
  - `computeAdaptiveSignals(tenantId)` : agrège les actions humaines depuis `conversation_learning_events`
  - `getAdaptiveStrategy(signals, scenario, allowed, forbidden)` : trie les stratégies par poids, exclut les interdites

### Données Utilisées
- Table : `conversation_learning_events` (PH51)
- Champs : `tenant_id`, `human_final_action`, `created_at`
- Agrégation par catégorie d'action : investigation, information, warranty, refund, replacement, apology

### Cache Redis
- Clé : `adaptive_response:{tenantId}`
- TTL : 15 minutes

### Seuil d'Activation
- Minimum 5 événements d'apprentissage pour activer (sinon `enabled: false`)

## 4. Logique d'Adaptation

Les actions humaines historiques sont comptées et pondérées en pourcentage.
L'IA reçoit un bloc prompt ordonnant les stratégies par fréquence d'usage réel du vendeur.

Exemple observé sur `ecomlg-001` (9 événements) :
```
investigation: 44%  ← dominant
information:   22%
refund:        11%
warranty:      11%
replacement:   11%
apology:        0%
```

### Respect des Contraintes
- Les actions interdites par PH45 (Decision Tree) sont exclues de la liste
- Les actions bloquées par PH49 (Refund Protection) ne sont jamais favorisées
- Le bloc prompt indique explicitement : "This does NOT override SAV policy, refund protection, or decision tree rules."

## 5. Bloc Prompt Injecté

```
=== ADAPTIVE RESPONSE TUNING ===
Learned from 9 past interactions.
Dominant merchant strategy: investigation

Preferred response order (based on merchant history):
1. investigation (44%)
2. information (22%)
3. refund (11%)
4. warranty (11%)
5. replacement (11%)

Guideline:
Follow this priority order when multiple valid strategies exist.
This does NOT override SAV policy, refund protection, or decision tree rules.
=== END ADAPTIVE RESPONSE TUNING ===
```

## 6. Decision Context

```json
{
  "adaptiveResponse": {
    "enabled": true,
    "strategyWeights": {
      "investigation": 0.4444,
      "information": 0.2222,
      "warranty": 0.1111,
      "refund": 0.1111,
      "replacement": 0.1111,
      "apology": 0
    },
    "dominantStrategy": "investigation",
    "sampleSize": 9
  }
}
```

## 7. Endpoints

### Debug
- `GET /ai/adaptive-response?tenantId=...`
- Retourne : `tenantId`, `enabled`, `sampleSize`, `strategies`, `dominantStrategy`, `lastUpdated`, `source`

### Observabilité
- `GET /ai/policy/effective?tenantId=...&conversationId=...`
- Section `adaptiveResponse` ajoutée dans la réponse
- `policyLayers.adaptiveResponse: true/false`
- `finalPromptSections` inclut `ADAPTIVE_RESPONSE` si activé

## 8. Fichiers Modifiés

| Fichier | Modification |
|---|---|
| `src/services/adaptiveResponseEngine.ts` | **Nouveau** — moteur adaptatif |
| `src/modules/ai/ai-assist-routes.ts` | Import + appel + prompt + decisionContext |
| `src/modules/ai/ai-policy-debug-routes.ts` | Endpoint debug + observabilité |

## 9. Tests E2E (8/8 PASS)

| # | Test | Résultat |
|---|---|---|
| 1 | Endpoint debug HTTP 200, tous champs | PASS |
| 2 | Threshold enabled/disabled (sampleSize >= 5) | PASS |
| 3 | Dominant strategy = highest weight | PASS |
| 4 | Decision tree intact | PASS |
| 5 | Refund protection prioritaire | PASS |
| 6 | KBActions inchangés (balance=6.43) | PASS |
| 7 | policy/effective contient adaptiveResponse | PASS |
| 8 | Non-régression suggestion IA | PASS |

## 10. Non-Régression

| Module | Statut |
|---|---|
| PH41 SAV Policy | OK |
| PH43 Historical Engine | OK |
| PH45 Decision Tree | OK |
| PH46 Response Strategy | OK |
| PH47 Customer Risk | OK |
| PH48 Product Value | OK |
| PH49 Refund Protection | OK |
| PH50 Merchant Behavior | OK |
| PH51 Learning Loop | OK |
| KBActions | Aucun débit |
| API Health | OK |

## 11. Infra

- Image DEV : `ghcr.io/keybuzzio/keybuzz-api:v3.5.60-ph52-adaptive-response-dev`
- Rollback : `v3.5.59-ph51-conversation-learning-dev`
- Namespace : `keybuzz-api-dev`
- Aucune nouvelle table
- Aucun CronJob
- Cache Redis : 1 clé par tenant (TTL 15 min)

## 12. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.59-ph51-conversation-learning-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

## 13. STOP POINT

**Aucun déploiement PROD.** Attente validation Ludovic.
