# PH108 — Autonomous Case Manager Engine

> Date : 2026-03-17
> Environnement : DEV
> Image : `v3.6.10-ph108-case-manager-dev`
> Rollback : `v3.6.09-ph107-connector-abstraction-dev`

---

## 1. Objectif

PH108 crée le chef d'orchestre central du cycle de vie d'un dossier SAV. Il détermine l'état du dossier, le propriétaire, la prochaine action, les transitions et les délais de suivi.

## 2. Architecture

### Service

`src/services/autonomousCaseManagerEngine.ts`

### Fonctions

| Fonction | Rôle |
|---|---|
| `computeCaseState(ctx)` | Détermine l'état et le stage du dossier |
| `computeNextAction(ctx)` | Identifie la prochaine action et son propriétaire |
| `computeCaseOwnership(ctx)` | Détermine qui pilote le dossier (AI/HUMAN/SUPPLIER/CARRIER) |
| `computeCaseTransitions(ctx)` | Détecte les transitions d'état |
| `computeCaseManager(input)` | Point d'entrée principal — résultat complet |
| `buildCaseManagerBlock(result)` | Génère le bloc prompt LLM |

## 3. États gérés (9)

| État | Description |
|---|---|
| `NEW` | Dossier créé, évaluation initiale |
| `IN_PROGRESS` | Traitement en cours |
| `WAITING_CUSTOMER` | Attente réponse client |
| `WAITING_CARRIER` | Enquête transporteur |
| `WAITING_SUPPLIER` | Dossier fournisseur ouvert |
| `WAITING_INTERNAL` | Attente action interne |
| `ESCALATED` | Escalade humaine / fraude |
| `RESOLVED` | Dossier résolu |
| `BLOCKED` | Bloqué par gouvernance |

## 4. Logique de décision

### Propriétaires

| Condition | Owner | Mode |
|---|---|---|
| Fraude HIGH/CRITICAL | HUMAN | MANUAL |
| Gouvernance LOCKED/DEGRADED | HUMAN | MANUAL |
| Escalade humaine / fraude | HUMAN | MANUAL |
| Refund > 100€ | HUMAN | ASSISTED |
| Enquête transporteur | CARRIER | ASSISTED |
| Garantie fournisseur | SUPPLIER | ASSISTED |
| Autopilot FULL + risque LOW | AI | AUTOMATED |
| Défaut (autre) | AI | ASSISTED |

### Priorités

| Condition | Priorité |
|---|---|
| Fraude détectée | CRITICAL |
| Gouvernance locked / all blocked | HIGH |
| Patient LOW + données manquantes | HIGH |
| Refund | HIGH |
| Transporteur / fournisseur | MEDIUM |
| Par défaut | LOW |

### Délais de suivi

| Situation | Follow-up |
|---|---|
| Résolu | none |
| Critique | 2h |
| Escaladé | 4h |
| Patient impatient | 12h |
| Attente carrier/supplier | 72h |
| Attente client | 48h |
| Par défaut | 48h |

## 5. Position pipeline

```
PH97 Multi-Order Context
PH101 Knowledge Graph
PH102 Long-Term Memory
PH104 Cross-Tenant Intelligence
PH103 Strategic Resolution
PH105 Autonomous Ops Plan
PH106 Action Dispatcher
PH107 Connector Abstraction
PH108 Case Manager     ← NOUVEAU
PH100 AI Governance
LLM
PH98 Quality Scoring
PH99 Self Improvement
```

## 6. Intégration decisionContext

```json
{
  "caseManager": {
    "caseState": "WAITING_CARRIER",
    "stage": "DELIVERY_INVESTIGATION",
    "owner": "CARRIER",
    "mode": "ASSISTED",
    "nextAction": "OPEN_CARRIER_INVESTIGATION",
    "priority": "MEDIUM",
    "confidence": 0.82,
    "blockingReason": null
  }
}
```

## 7. Bloc prompt

```
=== AUTONOMOUS CASE MANAGER (PH108) ===
Case state: WAITING_CARRIER
Stage: DELIVERY_INVESTIGATION
Owner: CARRIER (ASSISTED)
Next action: OPEN_CARRIER_INVESTIGATION
Priority: MEDIUM
Follow-up: 72h

Guidelines:
- follow structured workflow
- do not skip investigation steps
- escalate when required
=== END AUTONOMOUS CASE MANAGER ===
```

## 8. Endpoint debug

`GET /ai/case-manager?tenantId=xxx&conversationId=yyy`

Réponse : état, stage, owner, mode, nextAction, priority, confidence, blockingReason, followup, transition.

## 9. Tests

22 tests (20 + 2 bonus), 60+ assertions — 100% PASS.

| # | Test | Résultat |
|---|---|---|
| 1 | Empty context → NEW | PASS |
| 2 | Missing data → REQUEST_INFORMATION | PASS |
| 3 | Fraud HIGH → ESCALATED + HUMAN | PASS |
| 4 | Delivery → WAITING_CARRIER | PASS |
| 5 | Defect → WAITING_SUPPLIER | PASS |
| 6 | Resolved → RESOLVED | PASS |
| 7 | Escalation human → ESCALATED | PASS |
| 8 | Governance LOCKED → BLOCKED | PASS |
| 9 | Simple case → AI ASSISTED | PASS |
| 10 | CRITICAL priority for fraud | PASS |
| 11 | Transition NEW → WAITING_CARRIER | PASS |
| 12 | No transition when same state | PASS |
| 13 | Follow-up 72h carrier/supplier | PASS |
| 14 | Follow-up 48h waiting customer | PASS |
| 15 | Follow-up 2h critical | PASS |
| 16 | High value refund → HUMAN ASSISTED | PASS |
| 17 | Return process → AI | PASS |
| 18 | Prompt block structure | PASS |
| 19 | Idempotence | PASS |
| 20 | All blocked → HUMAN escalation | PASS |
| B1 | Governance DEGRADED → BLOCKED | PASS |
| B2 | Low patience → shorter followup | PASS |

## 10. Vérification DEV

| Check | Résultat |
|---|---|
| `/health` | 200 OK |
| `/ai/case-manager` | 200 OK |
| `/ai/connector-abstraction` (PH107) | 200 OK |
| `/ai/action-dispatcher` (PH106) | 200 OK |
| `/ai/autonomous-ops` (PH105) | 200 OK |
| `/ai/governance` (PH100) | 200 OK |
| `/ai/self-improvement` (PH99) | 200 OK |
| Pod status | Running, 0 restarts |
| Image | `v3.6.10-ph108-case-manager-dev` |

## 11. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.09-ph107-connector-abstraction-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

## 12. Fichiers modifiés

| Fichier | Action |
|---|---|
| `src/services/autonomousCaseManagerEngine.ts` | NOUVEAU |
| `src/tests/ph108-tests.ts` | NOUVEAU |
| `src/modules/ai/ai-assist-routes.ts` | Import + pipeline + decisionContext |
| `src/modules/ai/ai-policy-debug-routes.ts` | Endpoint debug |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | Image tag |
