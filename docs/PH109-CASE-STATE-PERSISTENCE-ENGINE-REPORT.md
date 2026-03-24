# PH109 — Case State Persistence Engine

> Date : 2026-03-17
> Environnement : DEV
> Image : `v3.6.11-ph109-case-state-persistence-dev`
> Rollback : `v3.6.10-ph108-case-manager-dev`

---

## 1. Objectif

PH109 persiste l'état des dossiers SAV calculé par PH108 dans la base de données, historise les transitions significatives, et fournit des endpoints pour relire le cycle de vie complet d'un dossier.

## 2. Tables créées

### ai_case_state (snapshot courant)

| Colonne | Type | Description |
|---|---|---|
| id | UUID PK | Identifiant |
| tenant_id | TEXT | Tenant |
| conversation_id | TEXT | Conversation |
| order_id | TEXT | Commande (optionnel) |
| current_state | TEXT | État courant |
| current_stage | TEXT | Stage courant |
| owner | TEXT | Propriétaire (AI/HUMAN/SUPPLIER/CARRIER) |
| mode | TEXT | Mode (AUTOMATED/ASSISTED/MANUAL) |
| next_action | TEXT | Prochaine action |
| priority | TEXT | Priorité |
| confidence | FLOAT | Score de confiance |
| blocking_reason | TEXT | Raison de blocage |
| recommended_followup_delay | TEXT | Délai de suivi |
| last_transition_at | TIMESTAMP | Dernière transition |
| created_at | TIMESTAMP | Création |
| updated_at | TIMESTAMP | Dernière MAJ |

Contrainte UNIQUE : `(tenant_id, conversation_id)`
Index : tenant_id, conversation_id, current_state, owner, priority

### ai_case_state_history (historique transitions)

| Colonne | Type | Description |
|---|---|---|
| id | UUID PK | Identifiant |
| tenant_id | TEXT | Tenant |
| conversation_id | TEXT | Conversation |
| from_state | TEXT | État précédent |
| to_state | TEXT | Nouvel état |
| from_stage / to_stage | TEXT | Stages |
| owner, mode | TEXT | Propriétaire/mode au moment de la transition |
| next_action, priority | TEXT | Action/priorité |
| confidence | FLOAT | Confiance |
| trigger_reason | TEXT | Raison du changement |
| source_engine | TEXT | Toujours PH109_CASE_STATE_PERSISTENCE |
| created_at | TIMESTAMP | Date de la transition |

Index : tenant_id, conversation_id, to_state, created_at

## 3. Logique de persistance

### Changements significatifs (créent une entrée historique)

- Changement d'état (current_state)
- Changement de stage
- Changement d'owner
- Changement de mode
- Changement de nextAction
- Changement de priorité
- Apparition/disparition d'un blockingReason

### Non significatif (pas de doublon historique)

- Seule la confidence change (micro-variation)

### Première persistance

- Crée le snapshot + première entrée historique avec `from_state = null`

## 4. Architecture

### Service

`src/services/caseStatePersistenceEngine.ts`

### Fonctions

| Fonction | Rôle |
|---|---|
| `ensureCaseStateTables()` | Crée les tables si inexistantes |
| `upsertCaseState(input)` | Upsert snapshot + append history si changement significatif |
| `getCurrentCaseState(tenantId, convId)` | Lit le snapshot courant |
| `getCaseStateHistory(tenantId, convId)` | Lit l'historique complet |
| `listCaseStates(tenantId, filters)` | Liste filtrée des snapshots |
| `buildCaseStatePersistenceBlock(result)` | Génère le bloc prompt |

## 5. Position pipeline

```
PH107 Connector Abstraction
PH108 Case Manager
PH109 Case State Persistence   ← NOUVEAU
PH100 AI Governance
LLM
PH98 Quality Scoring
PH99 Self Improvement
```

## 6. Intégration decisionContext

```json
{
  "caseStatePersistence": {
    "persisted": true,
    "snapshotUpdated": true,
    "historyAppended": true
  }
}
```

## 7. Bloc prompt

```
=== CASE STATE PERSISTENCE (PH109) ===
Current persisted case state:
- state: WAITING_CARRIER
- owner: CARRIER
- priority: MEDIUM

Latest recorded transition:
- NEW -> WAITING_CARRIER
=== END CASE STATE PERSISTENCE ===
```

## 8. Endpoints debug

| Endpoint | Params | Retour |
|---|---|---|
| `GET /ai/case-state` | tenantId, conversationId? | Snapshot courant |
| `GET /ai/case-state/history` | tenantId, conversationId | Historique transitions |
| `GET /ai/case-state/list` | tenantId, state?, owner?, priority? | Liste filtrée |

## 9. Tests

22 tests (20 + 2 bonus), 60+ assertions — 100% PASS.

| # | Test | Résultat |
|---|---|---|
| 1 | First persistence → snapshot created | PASS |
| 2 | First persistence → history created | PASS |
| 3 | Same state replayed → no duplicate | PASS |
| 4 | State change → history append | PASS |
| 5 | Stage change → history append | PASS |
| 6 | Owner change → history append | PASS |
| 7 | Mode change → history append | PASS |
| 8 | NextAction change → history append | PASS |
| 9 | Priority change → history append | PASS |
| 10 | BlockingReason change → history append | PASS |
| 11 | Confidence only → no history | PASS |
| 12 | Prompt block with transition | PASS |
| 13 | Prompt block no transition | PASS |
| 14 | Not persisted → empty block | PASS |
| 15 | Snapshot fields correct | PASS |
| 16 | Multi-tenant isolation | PASS |
| 17 | Idempotence prompt block | PASS |
| 18 | dryRun is false | PASS |
| 19 | Timestamp present | PASS |
| 20 | All 9 states representable | PASS |
| B1 | BLOCKED → IN_PROGRESS transition | PASS |
| B2 | RESOLVED state | PASS |

## 10. Vérification DEV

| Check | Résultat |
|---|---|
| `/health` | 200 OK |
| `/ai/case-state` | 200 OK (tables créées auto) |
| `/ai/case-state/list` | 200 OK |
| `/ai/case-state/history` | 200 OK |
| `/ai/case-manager` (PH108) | 200 OK |
| `/ai/connector-abstraction` (PH107) | 200 OK |
| `/ai/action-dispatcher` (PH106) | 200 OK |
| `/ai/autonomous-ops` (PH105) | 200 OK |
| `/ai/governance` (PH100) | 200 OK |
| Pod | Running, 0 restarts |
| Image | `v3.6.11-ph109-case-state-persistence-dev` |

## 11. Rollback

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.10-ph108-case-manager-dev -n keybuzz-api-dev
kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev
```

Les tables créées sont inoffensives si rollback applicatif.

## 12. Fichiers modifiés

| Fichier | Action |
|---|---|
| `src/services/caseStatePersistenceEngine.ts` | NOUVEAU |
| `src/tests/ph109-tests.ts` | NOUVEAU |
| `src/modules/ai/ai-assist-routes.ts` | Import + pipeline + decisionContext |
| `src/modules/ai/ai-policy-debug-routes.ts` | 3 endpoints debug |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | Image tag |
