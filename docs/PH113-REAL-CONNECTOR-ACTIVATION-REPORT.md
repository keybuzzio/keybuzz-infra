# PH113 — First Real Safe Connector Activation

**Date** : 18 mars 2026
**Environnement** : DEV uniquement
**Image** : `v3.6.15-ph113-real-connector-dev`
**Rollback** : `v3.6.14-ph112-ai-control-center-dev`

---

## 1. Objectif

Premiere activation reelle d'un connecteur IA, sous controle total :
- Perimetre ultra restreint : **REQUEST_INFORMATION** uniquement
- Connecteur : **customer_interaction_connector** uniquement
- Tenant : **ecomlg-001** uniquement (via policy DB, pas hardcode)
- Mode : **REAL_WITH_HUMAN_REVIEW** + **INTERNAL_TEST**

## 2. Architecture

### Service cree

`src/services/safeRealExecutionEngine.ts`

### Fonctions principales

| Fonction | Role |
|---|---|
| `computeSafeExecution(input)` | Evalue 8 gates de securite pour determiner DRY_RUN vs REAL |
| `getSafeExecutionStatus(tenantId)` | Resume d'execution (quotas, compteurs, etat) |
| `buildSafeExecutionBlock(result)` | Bloc prompt pour le LLM |
| `isPh113SafeModeEnabled()` | Verifie env PH113_SAFE_MODE |

### 8 Gates de securite (ordre d'evaluation)

| Gate | Condition | Resultat si echec |
|---|---|---|
| 1. PH113_SAFE_MODE | env != 'true' | DRY_RUN + fallback |
| 2. Global execution | AI_REAL_EXECUTION_ENABLED != 'true' | DRY_RUN |
| 3. Action allowlist | Action pas dans PH113_ALLOWED_ACTIONS | DRY_RUN |
| 4. Governance | LOCKED ou DEGRADED | DRY_RUN |
| 5. Conversation whitelist | Channel != amazon, buyer abusif, fraud HIGH, tone agressif | DRY_RUN |
| 6. Volume limits | >5/heure ou >20/jour | DRY_RUN |
| 7. PH110 gating | Action BLOCKED par PH110 | DRY_RUN |
| 8. PH111 activation | Action non eligible PH111 | DRY_RUN |

### Actions autorisees (PH113)

| Action | Connecteur | Statut |
|---|---|---|
| REQUEST_INFORMATION | customer_interaction_connector | AUTORISE (sous review) |
| *toutes les autres* | * | INTERDIT |

### Actions explicitement interdites

REFUND, REPLACEMENT, RETURN, SUPPLIER_CASE, ESCALATE_FRAUD, ESCALATE_LEGAL, CARRIER_INVESTIGATION, etc.

## 3. Limites de volume

| Limite | Valeur |
|---|---|
| Max par heure | 5 |
| Max par jour | 20 |

Comptage base sur `ai_execution_attempt_log` (dry_run = false).

## 4. Whitelist conversation

Pour etre eligible a l'execution reelle :
- Channel = **amazon** uniquement
- Buyer classification != ABUSIVE / HIGH
- Fraud risk != HIGH / CRITICAL
- Customer tone != AGGRESSIVE / HOSTILE

## 5. Activation Policy creee

```sql
INSERT INTO ai_activation_policy (tenant_id, connector_name, action_name, activation_mode, is_enabled, rollout_stage, notes)
VALUES ('ecomlg-001', 'customer_interaction_connector', 'REQUEST_INFORMATION',
        'REAL_WITH_HUMAN_REVIEW', true, 'INTERNAL_TEST',
        'PH113: First safe real connector activation');
```

## 6. Variables d'environnement

| Variable | Valeur DEV | Effet |
|---|---|---|
| PH113_SAFE_MODE | `true` (a activer) | Gate 1 — tout reste DRY_RUN si absent |
| AI_REAL_EXECUTION_ENABLED | `true` (a activer) | Gate 2 — kill switch global |

**Etat actuel** : les deux variables ne sont PAS encore activees dans le deployment K8s.
Tout reste donc en DRY_RUN par defaut (fail-safe).

## 7. Endpoints debug

| Endpoint | Description |
|---|---|
| `GET /ai/real-execution-status` | Resume PH113 : enabled, quotas, compteurs |
| `GET /ai/safe-execution` | Calcul safe execution pour un tenant/conversation |

## 8. Integration pipeline

```
PH111 Controlled Activation
PH113 Safe Real Execution    ← NOUVEAU
PH100 AI Governance
LLM
PH98 Quality Scoring
PH99 Self Improvement
```

### decisionContext

```json
{
  "safeExecution": {
    "action": "REQUEST_INFORMATION",
    "executionMode": "DRY_RUN",
    "approved": false,
    "approvalStatus": "NOT_REQUIRED",
    "blockedReason": "ph113_safe_mode_disabled",
    "fallback": true,
    "rollbackPossible": true
  }
}
```

## 9. Verification DEV

| Test | Resultat |
|---|---|
| `/health` | 200 OK |
| `/ai/real-execution-status` | 200 OK — enabled:false, safeMode:false |
| `/ai/safe-execution` | 200 OK — DRY_RUN (safe mode disabled) |
| `/ai/controlled-activation` | 200 OK — INTERNAL_TEST, 1 action enabled |
| `/ai/controlled-execution` | 200 OK — 1 simulated |
| `/ai/governance` | 200 OK — NOMINAL |

**6/6 PASS**

## 10. Tests

`src/tests/ph113-tests.ts` — 22 tests, 65+ assertions

| # | Test | Resultat |
|---|---|---|
| T01 | PH113_SAFE_MODE=false → DRY_RUN | PASS |
| T02 | AI_REAL_EXECUTION_ENABLED=false → DRY_RUN | PASS |
| T03 | REFUND action → DRY_RUN | PASS |
| T04 | REPLACEMENT → DRY_RUN | PASS |
| T05 | ESCALATE_FRAUD → DRY_RUN | PASS |
| T06 | SUPPLIER_WARRANTY → DRY_RUN | PASS |
| T07 | Governance LOCKED → DRY_RUN | PASS |
| T08 | Fraud HIGH → DRY_RUN | PASS |
| T09 | Buyer ABUSIVE → DRY_RUN | PASS |
| T10 | AGGRESSIVE tone → DRY_RUN | PASS |
| T11 | Channel octopia → DRY_RUN | PASS |
| T12 | Channel email → DRY_RUN | PASS |
| T13 | PH110 BLOCKED → DRY_RUN | PASS |
| T14 | PH111 not eligible → DRY_RUN | PASS |
| T15 | All gates pass → REAL eligible | PASS |
| T16 | Approval required → not approved | PASS |
| T17 | isPh113SafeModeEnabled | PASS |
| T18 | buildSafeExecutionBlock REAL | PASS |
| T19 | buildSafeExecutionBlock blocked | PASS |
| T20 | getSafeExecutionStatus structure | PASS |
| T21 | Governance DEGRADED → DRY_RUN | PASS |
| T22 | Payload snapshot content | PASS |

## 11. Non-regression

PH41 → PH112 intacts. Endpoints verifies :
- `/health` 200 OK
- `/ai/controlled-activation` 200 OK
- `/ai/controlled-execution` 200 OK
- `/ai/governance` 200 OK

## 12. Securite

- **Fail-safe** : tout est DRY_RUN par defaut
- **8 gates** de securite empilees
- **Volume limits** : 5/h, 20/j
- **Whitelist** : amazon only, pas d'agressif/fraude/abusif
- **Approval** : REAL_WITH_HUMAN_REVIEW oblige une validation humaine
- **Logging** : chaque tentative enregistree dans `ai_execution_attempt_log`
- **Rollback** : instantane via `kubectl set image`
- **Aucune execution reelle activee** : les env vars ne sont pas encore definies

## 13. Prochaines etapes (apres validation)

1. Activer `PH113_SAFE_MODE=true` dans le deployment DEV
2. Activer `AI_REAL_EXECUTION_ENABLED=true` dans le deployment DEV
3. Tester avec une conversation amazon reelle en DEV
4. Valider le flux REAL_WITH_HUMAN_REVIEW
5. Si OK : deployer en PROD (avec les memes env vars desactivees par defaut)

## 14. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.14-ph112-ai-control-center-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```
