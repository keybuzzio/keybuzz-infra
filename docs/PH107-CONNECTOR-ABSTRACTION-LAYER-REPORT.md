# PH107 — Real Connector Abstraction Layer

> Date : 2026-03-16
> Environnement : DEV
> Image : `v3.6.09-ph107-connector-abstraction-dev`
> Rollback : `v3.6.08-ph106-action-dispatcher-dev`

---

## 1. Objectif

PH107 crée une couche d'abstraction de connecteurs qui standardise les dispatches produits par PH106 en payloads normalisés par connecteur, valide les prérequis, et simule les résultats sans jamais appeler de service externe.

## 2. Architecture

### Service

`src/services/connectorAbstractionEngine.ts`

### Fonctions

| Fonction | Rôle |
|---|---|
| `buildConnectorDispatches(input)` | Point d'entrée principal |
| `validateConnectorPayload(connector, payload)` | Valide les champs requis par connecteur |
| `simulateConnectorDispatch(action, connector, valid, mode)` | Simule le résultat du dispatch |
| `normalizeConnectorResult(result)` | Normalise la sortie |
| `buildConnectorAbstractionBlock(result)` | Génère le bloc prompt LLM |

## 3. Connecteurs supportés (10)

| Connector | Usage |
|---|---|
| `customer_interaction_connector` | Messages client |
| `carrier_connector` | Enquêtes transporteur |
| `supplier_connector` | Dossier fournisseur |
| `returns_connector` | Préparation retour |
| `fulfillment_connector` | Remplacement |
| `finance_connector` | Revue remboursement |
| `human_queue_connector` | Support humain |
| `fraud_queue_connector` | Revue fraude |
| `legal_queue_connector` | Queue légale |
| `conversation_state_connector` | État conversation |

## 4. Champs requis par connecteur

| Connector | Champs requis |
|---|---|
| carrier | orderId, trackingNumber, carrier |
| supplier | orderId, supplierId |
| returns | orderId, returnReason |
| customer_interaction | conversationId |
| fulfillment | orderId, productSku |
| finance | orderId, refundAmount |
| human_queue | conversationId |
| fraud_queue | conversationId |
| legal_queue | conversationId |
| conversation_state | conversationId |

## 5. Statuts normalisés

| Statut | Description |
|---|---|
| `SIMULATED_ACCEPTED` | Payload valide, simulation OK |
| `SIMULATED_REJECTED` | Fallback erreur |
| `SIMULATED_BLOCKED` | Bloqué par policy |
| `SIMULATED_REQUIRES_DATA` | Champs manquants |
| `SIMULATED_REQUIRES_HUMAN` | Review humain requis |

## 6. Politique simulation

- **100% dry-run** — aucun appel réel à aucun service externe
- Chaque dispatch porte `dryRun: true`
- Le résultat global porte `simulationOnly: true`
- Les références simulées ont le préfixe `sim-`

## 7. Position pipeline

```
PH97 Multi-Order Context
PH101 Knowledge Graph
PH102 Long-Term Memory
PH104 Cross-Tenant Intelligence
PH103 Strategic Resolution
PH105 Autonomous Ops Plan
PH106 Action Dispatcher
PH107 Connector Abstraction   ← NOUVEAU
PH100 AI Governance
LLM
PH98 Quality Scoring
PH99 Self Improvement
```

## 8. Intégration decisionContext

```json
{
  "connectorAbstraction": {
    "summary": {
      "totalDispatches": 2,
      "accepted": 1,
      "requiresData": 1
    },
    "dispatches": [
      {
        "action": "OPEN_CARRIER_INVESTIGATION",
        "connector": "carrier_connector",
        "status": "SIMULATED_ACCEPTED"
      }
    ],
    "simulationOnly": true
  }
}
```

## 9. Bloc prompt

```
=== CONNECTOR ABSTRACTION LAYER (PH107) ===
Connector simulation summary:
- 2 dispatches prepared
- 1 simulated accepted
- 1 requires data

Connector dispatches:
- OPEN_CARRIER_INVESTIGATION -> carrier_connector (SIMULATED_ACCEPTED)
- NOTIFY_CUSTOMER -> customer_interaction_connector (SIMULATED_REQUIRES_DATA)

Connector policy:
- simulation only
- do not claim any real external execution
=== END CONNECTOR ABSTRACTION LAYER ===
```

## 10. Endpoint debug

`GET /ai/connector-abstraction?tenantId=xxx&conversationId=yyy`

Réponse : summary + dispatches + payloads + statuts simulés.

## 11. Tests

22 tests (20 + 2 bonus), 60+ assertions — 100% PASS.

| # | Test | Résultat |
|---|---|---|
| 1 | Empty context stable | PASS |
| 2 | Carrier dispatch valid → ACCEPTED | PASS |
| 3 | Carrier missing tracking → REQUIRES_DATA | PASS |
| 4 | Supplier dispatch valid | PASS |
| 5 | Supplier missing supplierId | PASS |
| 6 | Returns dispatch valid | PASS |
| 7 | Returns missing reason | PASS |
| 8 | Customer connector valid | PASS |
| 9 | Customer missing conversationId | PASS |
| 10 | Fraud queue → REQUIRES_HUMAN | PASS |
| 11 | Human queue dispatch | PASS |
| 12 | Finance dispatch | PASS |
| 13 | Blocked action stays blocked | PASS |
| 14 | Dry-run enforced globally | PASS |
| 15 | No real connector call | PASS |
| 16 | Payload validator standalone | PASS |
| 17 | Summary counts correct | PASS |
| 18 | Prompt block structure | PASS |
| 19 | Idempotence | PASS |
| 20 | Normalize result edge cases | PASS |
| B1 | Legal queue connector | PASS |
| B2 | Conversation state connector | PASS |

## 12. Vérification DEV

| Check | Résultat |
|---|---|
| `/health` | 200 OK |
| `/ai/connector-abstraction` | 200 OK |
| `/ai/autonomous-ops` (PH105) | 200 OK |
| `/ai/action-dispatcher` (PH106) | 200 OK |
| `/ai/governance` (PH100) | 200 OK |
| Pod status | Running, 0 restarts |
| Image | `v3.6.09-ph107-connector-abstraction-dev` |

## 13. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.08-ph106-action-dispatcher-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

## 14. Fichiers modifiés

| Fichier | Action |
|---|---|
| `src/services/connectorAbstractionEngine.ts` | NOUVEAU |
| `src/tests/ph107-tests.ts` | NOUVEAU |
| `src/modules/ai/ai-assist-routes.ts` | Import + pipeline + decisionContext |
| `src/modules/ai/ai-policy-debug-routes.ts` | Endpoint debug |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | Image tag |
