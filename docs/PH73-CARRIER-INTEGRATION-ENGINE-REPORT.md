# PH73 — Carrier Integration Engine

> Date : 1er mars 2026
> Auteur : Agent Cursor (CE)
> Environnement : DEV uniquement (PROD sur validation Ludovic)

---

## 1. Objectif

PH73 prépare l'intégration transporteur pour les cas de livraison litigieuse. Il structure les demandes d'investigation, normalise les données transport, et produit un plan d'intégration exploitable par l'IA et les agents.

PH73 ne contacte **aucun transporteur réel** — il prépare uniquement le plan.

---

## 2. Architecture

### Fichier créé
- `src/services/carrierIntegrationEngine.ts` (~300 lignes)

### Fonctions exportées
- `buildCarrierIntegrationPlan(context)` — calcul du plan transporteur
- `buildCarrierIntegrationBlock(result)` — formatage pour injection prompt LLM
- `normalizeCarrier(raw)` — normalisation du nom transporteur

---

## 3. Catalogue des transporteurs (12 + UNKNOWN)

| Transporteur | Aliases | Investigation | Relais |
|---|---|---|---|
| COLISSIMO | colissimo, la poste colissimo | oui | oui |
| LA_POSTE | la poste, laposte | oui | oui |
| CHRONOPOST | chronopost, chrono | oui | oui |
| UPS | ups, united parcel service | oui | non |
| DHL | dhl, dhl express, dhl parcel | oui | non |
| DPD | dpd, dpd france | oui | oui |
| GLS | gls, gls france | oui | oui |
| DB_SCHENKER | db schenker, schenker | oui | non |
| FEDEX | fedex, fed ex, federal express | oui | non |
| TNT | tnt, tnt express | oui | non |
| MONDIAL_RELAY | mondial relay, mondialrelay | non | oui |
| RELAIS_COLIS | relais colis, relaiscolis | non | oui |
| UNKNOWN | (tout le reste) | non | non |

---

## 4. Scénarios détectés (8)

| Scénario | Description | Éligibilité |
|---|---|---|
| `NO_CARRIER_DATA` | Aucun transporteur ni tracking | BLOCKED |
| `TRACKING_PRESENT` | Tracking disponible, données partielles | PARTIAL |
| `TRACKING_MISSING` | Transporteur connu, tracking absent | BLOCKED |
| `INVESTIGATION_READY` | Toutes données présentes | READY |
| `INVESTIGATION_BLOCKED_MISSING_DATA` | Données insuffisantes | BLOCKED |
| `DELIVERED_BUT_DISPUTED` | Livré mais client conteste | READY/PARTIAL |
| `POSSIBLE_RELAY_OR_THIRD_PARTY` | Voisin/relais/tiers mentionné | PARTIAL |
| `CARRIER_ESCALATION_RECOMMENDED` | Risque/valeur élevée | ESCALATION_NEEDED |

---

## 5. Données requises / manquantes

Données obligatoires pour investigation :
- `orderId`
- `trackingNumber`
- `carrier`
- `shippingDate`

Le moteur détecte automatiquement les données manquantes et les liste dans `missingData[]`.

---

## 6. Position dans le pipeline IA

```
PH70 Workflow Orchestration
PH71 Case Autopilot
PH72 Action Execution
PH73 Carrier Integration Engine  ← NOUVEAU
PH67 Knowledge Retrieval → ... → PH59 Context Compression → LLM
PH66 Self Protection
```

---

## 7. Intégration

### ai-assist-routes.ts
- Import de `buildCarrierIntegrationPlan`, `buildCarrierIntegrationBlock`
- Exécution après PH72, avant PH67
- Injection dans `buildSystemPrompt()` via `carrierIntegrationBlock`
- Ajout dans `decisionContext.carrierIntegration`

### ai-policy-debug-routes.ts
- Endpoint `GET /ai/carrier-integration`
- `pipelineOrder` mis à jour (inclut PH73)
- `pipelineLayers.carrierIntegration: true`
- `finalPromptSections` inclut `CARRIER_INTEGRATION_ENGINE`

---

## 8. Endpoint debug

```
GET /ai/carrier-integration?tenantId=ecomlg-001&carrier=Colissimo&trackingNumber=CL123&orderId=ORD-001&shippingDate=2026-02-15
```

Réponse :
```json
{
  "carrierPlanType": "INVESTIGATION_READY",
  "carrierName": "COLISSIMO",
  "carrierRaw": "Colissimo",
  "trackingNumber": "CL123",
  "carrierStatus": "TRACKING_PRESENT",
  "requiredData": ["orderId","trackingNumber","carrier","shippingDate"],
  "missingData": [],
  "investigationEligibility": "READY",
  "confidence": 0.95,
  "supportsInvestigation": true,
  "supportsRelay": true,
  "guidance": [...]
}
```

---

## 9. Résultats des tests

| Métrique | Résultat |
|---|---|
| Tests | **17** |
| Assertions | **45** |
| Passed | **45** |
| Failed | **0** |
| TypeScript | **0 erreur** |

### Détail des tests
| # | Scénario | Résultat | Status |
|---|---|---|---|
| T1 | Tracking absent | TRACKING_MISSING + BLOCKED | PASS |
| T2 | Tracking + UPS | TRACKING_PRESENT | PASS |
| T3 | Toutes données | INVESTIGATION_READY + READY | PASS |
| T4 | Données manquantes | BLOCKED | PASS |
| T5 | Livré contesté | DELIVERED_BUT_DISPUTED | PASS |
| T6 | Voisin/relais | POSSIBLE_RELAY_OR_THIRD_PARTY | PASS |
| T7 | Valeur critique | CARRIER_ESCALATION_RECOMMENDED | PASS |
| T8 | Fraud HIGH | ESCALATION + prudence | PASS |
| T9 | Abuse HIGH | Caution guidance | PASS |
| T10 | Carrier inconnu | UNKNOWN | PASS |
| T11 | Normalisation (5 sub) | 5/5 correct | PASS |
| T12 | Workflow DELIVERY | INVESTIGATION_READY | PASS |
| T13 | PH72 action | Cohérent | PASS |
| T14 | No data | NO_CARRIER_DATA | PASS |
| T15 | Format bloc | Header/footer OK | PASS |
| T16 | Mondial Relay | supportsRelay + !investigation | PASS |
| T17 | Livré disputé + data | READY | PASS |

---

## 10. Rollback

```bash
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.83-ph72-action-execution-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

---

## 11. Tags images

| Env | Tag |
|---|---|
| DEV | `v3.5.84-ph73-carrier-integration-dev` |
| Rollback | `v3.5.83-ph72-action-execution-dev` |
