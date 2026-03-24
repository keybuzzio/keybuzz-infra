# PH115 — First Controlled Real Execution Enablement

## Resume

PH115 active pour la premiere fois l'execution reelle du systeme IA, de maniere ultra controlee, reversible instantanement, limitee a 1 tenant et 1 action SAFE.

## Variables d'environnement

| Variable | DEV | PROD | Description |
|---|---|---|---|
| `PH113_SAFE_MODE` | `true` | non definie | Gate principale safe mode |
| `AI_REAL_EXECUTION_ENABLED` | `true` | non definie | Kill switch global |
| `PH114_EXPANDED_MODE` | `true` | non definie | Mode multi-action |
| `AI_REAL_EXECUTION_TENANTS` | `ecomlg-001` | non definie | Tenant allowlist |

**PROD reste en DRY_RUN total** — aucune de ces variables n'est definie.

## Allowlist

### Tenants autorises
- `ecomlg-001` (DEV uniquement)

### Actions autorisees pour execution reelle (PH115)
- `REQUEST_INFORMATION` → `customer_interaction_connector`

### Actions autorisees pour simulation expandee (PH114)
- `PREPARE_CARRIER_INVESTIGATION` → `carrier_connector`
- `PREPARE_RETURN` → `returns_connector`
- `PREPARE_SUPPLIER_CASE` → `supplier_connector`
- `MARK_CONVERSATION_RESOLVED` → `conversation_state_connector`

### Actions permanentement bloquees
- `REFUND`, `PREPARE_REFUND_REVIEW`, `REPLACEMENT`, `PREPARE_REPLACEMENT`
- `ESCALATE_FRAUD`, `ESCALATE_LEGAL`
- `SUPPLIER_REAL_CASE`, `RETURN_REAL_EXECUTION`

## Double validation securite

### Gate 1 — Safety
- fraud risk LOW uniquement
- abuse risk LOW uniquement
- buyer NON abusive
- customer tone NON agressif
- governance NON locked/degraded
- value NON critical/very_high

### Gate 2 — Payload readiness
- `conversationId` present et valide
- Tous les champs requis par le connecteur presents

## Mode d'execution

PH115 impose `REAL_WITH_HUMAN_REVIEW` pour les actions reelles :
- Le message IA est genere
- Il est valide par les gates de securite
- Il est journalise comme "real execution eligible"
- L'envoi effectif depend de la validation humaine ou du pipeline outbound

## Kill switch instantane

```bash
# Desactiver IMMEDIATEMENT toute execution reelle :
kubectl set env deploy/keybuzz-api -n keybuzz-api-dev AI_REAL_EXECUTION_ENABLED=false
```

Le pod redemarrera et toutes les executions passeront en DRY_RUN.

## Quotas

| Parametre | Valeur |
|---|---|
| Max executions/heure | 10 (PH114 expanded) |
| Max executions/jour | 50 (PH114 expanded) |

## Endpoints debug

| Endpoint | Description |
|---|---|
| `GET /ai/real-execution-live?tenantId=` | Statut live : enabled, liveMode, allowedTenants, quotas |
| `GET /ai/safe-execution?tenantId=&conversationId=` | Resultat execution : mode, gates, readiness |
| `GET /ai/real-execution-plan?tenantId=` | Plan multi-actions : eligible, blocked, preview |
| `GET /ai/real-execution-status?tenantId=` | Statut global : compteurs, fallbacks |

## Resultats de verification DEV

```
/health                    → 200 OK
/ai/safe-execution         → 200 executionMode=REAL_WITH_HUMAN_REVIEW isRealExecution=true
/ai/real-execution-live    → 200 liveMode=true allowedTenants=[ecomlg-001]
/ai/real-execution-plan    → 200 5 eligible, 8 blocked, mode=SAFE_EXPANDED
/ai/real-execution-status  → 200 enabled=true safeMode=true
/ai/governance             → 200 OK
/ai/controlled-execution   → 200 OK
/ai/controlled-activation  → 200 OK
```

## Audit logging

Chaque tentative d'execution est journalisee dans `ai_execution_attempt_log` avec :
- `isRealExecution` (boolean)
- `safetyChecksPassed` (boolean)
- `approvalRequired` / `approvalStatus`
- `fallback` / `fallbackReason`
- `connectorReadiness` complet

## Tests

Fichier : `src/tests/ph115-tests.ts`
- 22 tests
- 75+ assertions
- Couvre : tenant allowlist, kill switch, fraud/abuse/tone blocking, governance, payload readiness, execution modes, prompt block

## Image

| Env | Image | SHA256 |
|---|---|---|
| DEV | `v3.6.17-ph115-real-execution-dev` | `14b8a8fc7a9f...` |
| PROD | non deploye | — |

## Rollback

```bash
# Rollback image
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.16-ph114-real-scaling-dev -n keybuzz-api-dev

# Supprimer env vars d'activation
kubectl set env deploy/keybuzz-api -n keybuzz-api-dev PH113_SAFE_MODE- AI_REAL_EXECUTION_ENABLED- PH114_EXPANDED_MODE- AI_REAL_EXECUTION_TENANTS-
```

## Non-regression

| Endpoint | DEV |
|---|---|
| `/health` | 200 PASS |
| `/ai/governance` | 200 PASS |
| `/ai/controlled-execution` | 200 PASS |
| `/ai/controlled-activation` | 200 PASS |

## Securite

1. **PROD = DRY_RUN** : aucune env var d'activation en PROD
2. **Tenant allowlist** : seul `ecomlg-001` peut executer en reel
3. **Action allowlist** : seul `REQUEST_INFORMATION` est eligible pour execution reelle
4. **11 gates de securite** : PH113 safe mode → kill switch → tenant → blocked actions → allowlist → safety → payload → volume → PH110 → PH111 → connector readiness
5. **Double validation** : safety gate + payload readiness
6. **Kill switch** : `AI_REAL_EXECUTION_ENABLED=false` stoppe tout instantanement

---

## TEST E2E — Resultats (19 mars 2026)

### Conversation testee

| Champ | Valeur |
|---|---|
| ID | `cmmmxgixed103a49965e8964b` |
| Tenant | `ecomlg-001` |
| Canal | `amazon` |
| Sujet | "Remboursement initie pour la commande 171-2601298-2066704" |
| Status | `open` |
| Messages | 1 inbound, 0 outbound |

### Chaine AI complete (6 endpoints)

| Endpoint | Status | Resultat |
|---|---|---|
| `/ai/strategic-resolution` | 200 | `strategy: REQUEST_INFORMATION` |
| `/ai/autonomous-ops` | 200 | `executionMode: AUTOMATIC_READY` |
| `/ai/action-dispatcher` | 200 | OK |
| `/ai/connector-abstraction` | 200 | OK |
| `/ai/case-manager` | 200 | `caseState: NEW, stage: INITIAL_ASSESSMENT` |
| `/ai/safe-execution` | 200 | `REAL_WITH_HUMAN_REVIEW, isRealExecution: true, safetyChecksPassed: true` |

### Activation PH115 confirmee

```
PH113_SAFE_MODE=true          ✅
AI_REAL_EXECUTION_ENABLED=true ✅
PH114_EXPANDED_MODE=true       ✅
AI_REAL_EXECUTION_TENANTS=ecomlg-001 ✅
liveMode=true                  ✅
```

### Audit trail (ai_execution_attempt_log)

```
17:48:06 | REQUEST_INFORMATION | REAL_WITH_HUMAN_REVIEW | REAL_EXECUTION_ELIGIBLE | dry=false
17:47:42 | REQUEST_INFORMATION | SIMULATED              | BLOCKED                 | dry=true  (kill switch)
17:47:09 | REQUEST_INFORMATION | REAL_WITH_HUMAN_REVIEW | REAL_EXECUTION_ELIGIBLE | dry=false
17:45:41 | REQUEST_INFORMATION | REAL_WITH_HUMAN_REVIEW | REAL_EXECUTION_ELIGIBLE | dry=false
14:23:05 | REQUEST_INFORMATION | REAL_WITH_HUMAN_REVIEW | REAL_EXECUTION_ELIGIBLE | dry=false
14:23:05 | NOTIFY_CUSTOMER     | SIMULATED              | CONNECTOR_DISABLED      | dry=true  (PH110)
14:23:05 | REQUEST_INFORMATION | SIMULATED              | CONNECTOR_DISABLED      | dry=true  (PH110)
```

- 4 executions reelles eligibles (dry_run=false)
- 3 blocages legitimes (kill switch + PH110 connector disabled)
- 0 anomalies

### Test kill switch

| Phase | enabled | liveMode | executionMode | isRealExecution | blockedReason |
|---|---|---|---|---|---|
| AVANT (ON) | true | true | REAL_WITH_HUMAN_REVIEW | true | null |
| KILL SWITCH (OFF) | false | false | DRY_RUN | false | global_execution_disabled |
| RESTAURE (ON) | true | true | REAL_WITH_HUMAN_REVIEW | true | null |

Le kill switch coupe IMMEDIATEMENT toute execution reelle et restaure le fonctionnement normal apres reactivation.

### Execution reelle de message

PH115 est un moteur de gating/eligibilite. Il determine si une action PEUT etre executee en reel. L'envoi effectif de message passe par le pipeline outbound existant (POST /conversations/:id/reply → outbound worker → Amazon SP-API).

Sur la conversation testee :
- PH115 confirme l'eligibilite : `REAL_WITH_HUMAN_REVIEW`, `isRealExecution: true`
- Le pipeline complet (PH103 → PH105 → PH106 → PH107 → PH108 → PH115) valide la strategie `REQUEST_INFORMATION`
- L'audit log enregistre `REAL_EXECUTION_ELIGIBLE` avec `dry_run: false`
- La prochaine utilisation de `/ai/assist` sur cette conversation inclura le contexte PH115 dans le prompt LLM

L'integration avec l'envoi effectif (outbound worker) necessite que l'agent utilise le produit normalement via l'UI KeyBuzz : la suggestion IA generee inclura le contexte PH115 et pourra etre envoyee par l'agent.

---

## VERDICT FINAL : GO

PH115 est fonctionnel, securise et reversible :

| Critere | Statut |
|---|---|
| Tenant allowlist | ✅ PASS |
| Action allowlist | ✅ PASS |
| Double validation securite | ✅ PASS |
| Mode REAL_WITH_HUMAN_REVIEW | ✅ PASS |
| Kill switch instantane | ✅ PASS |
| Audit trail complet | ✅ PASS |
| Chaine AI complete (6 moteurs) | ✅ PASS |
| PROD en DRY_RUN total | ✅ PASS |
| Rollback < 30s | ✅ PASS |
| Non-regression | ✅ PASS |
