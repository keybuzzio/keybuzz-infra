# PH137-D-IA-MODE-ORCHESTRATION-01 — Rapport

> Date : 1 mars 2026
> Auteur : Agent Cursor (CE)
> Version DEV : `v3.5.150-ai-mode-engine-dev`
> Version PROD : `v3.5.150-ai-mode-engine-prod`
> Environnement : DEV + PROD deploye

---

## 1. Objectif

Centraliser et structurer le comportement IA selon le mode et le plan, avec un seul module d'orchestration.

---

## 2. Module cree : `ai-mode-engine.ts`

### Fichier : `src/modules/ai/ai-mode-engine.ts`

### Fonction principale : `resolveIAMode(tenantId)`

Retourne un objet `IAModeResolution` contenant :

| Champ | Type | Description |
|---|---|---|
| `mode` | `disabled / suggestion / supervised / autonomous` | Mode IA resolu |
| `plan` | string | Plan du tenant |
| `canSuggest` | boolean | Peut utiliser les suggestions IA |
| `canAutoReply` | boolean | Peut auto-repondre |
| `canAutoAssign` | boolean | Peut auto-assigner |
| `canEscalate` | boolean | Peut escalader |
| `canEscalateToKeybuzz` | boolean | Peut escalader vers l'equipe KeyBuzz |
| `escalationTarget` | `client_team / keybuzz_team / both` | Cible d'escalade |
| `safeMode` | boolean | Mode securise (drafts uniquement) |
| `blocked` | boolean | Acces bloque |
| `blockReason` | string | Raison du blocage |
| `entitlement` | TenantEntitlement | Entitlement complet |

### Matrice des plans

| Plan | Mode max | Suggest | Auto Reply | Auto Assign | Escalate | KeyBuzz Escalation |
|---|---|---|---|---|---|---|
| **STARTER** | disabled | non | non | non | non | non |
| **PRO** | suggestion | oui | non | non | non | non |
| **AUTOPILOT** | autonomous | oui | oui | oui | oui | non |
| **ENTERPRISE** | autonomous | oui | oui | oui | oui | oui |

### Resolution du mode

```
1. Verifier entitlement (billing locked ?)
2. Verifier plan capabilities (PLAN_CAPABILITIES matrix)
3. Charger autopilot_settings du tenant
4. Resoudre mode effectif :
   - PRO -> suggestion (toujours)
   - AUTOPILOT disabled/off -> suggestion (fallback)
   - AUTOPILOT safe_mode -> supervised (drafts)
   - AUTOPILOT autonomous -> autonomous
   - ENTERPRISE -> idem AUTOPILOT + keybuzz escalation
```

---

## 3. Integration

### 3.1 engine.ts (Autopilot)

Avant :
```
Step 2: getTenantEntitlement() -> check plan !== AUTOPILOT/ENTERPRISE
Step 3: check settings.mode !== 'autonomous'
```

Apres :
```
Step 2+3: resolveIAMode() -> check blocked + canUseAutopilot()
```

### 3.2 ai-assist-routes.ts (AI Assist)

Avant :
```
PH130: SELECT plan FROM tenants + SELECT exempt FROM tenant_billing_exempt
       -> block STARTER
```

Apres :
```
PH137-D: resolveIAMode() -> canUseSuggestions()
         -> block si disabled + retourne plan + mode dans la reponse
```

---

## 4. Fichiers modifies

| Fichier | Action |
|---|---|
| `src/modules/ai/ai-mode-engine.ts` | **NOUVEAU** — module d'orchestration |
| `src/modules/autopilot/engine.ts` | Import + remplacement plan/mode check |
| `src/modules/ai/ai-assist-routes.ts` | Import + remplacement plan guard |
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | Image `v3.5.150-ai-mode-engine-dev` |
| `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` | Image `v3.5.150-ai-mode-engine-prod` |
| `keybuzz-infra/k8s/keybuzz-api-prod/outbound-worker-deployment.yaml` | Image `v3.5.150-ai-mode-engine-prod` |

---

## 5. Gating escalade KeyBuzz

L'escalade vers `keybuzz_team` est gatee par :
1. Plan ENTERPRISE requis (`canEscalateToKeybuzz` = false pour tous les autres)
2. `escalation_target` dans `autopilot_settings` doit etre `keybuzz_team` ou `both`
3. Si bloque : `getKeybuzzEscalationError()` retourne le message UX

Placeholder Stripe : non active (prepare pour future table `billing_addons`)

---

## 6. Non-regressions

### DEV

| Endpoint | Status |
|---|---|
| API /health | 200 |
| Client /login | 200 |
| Client /inbox | 200 |
| Client /billing | 200 |
| Client /orders | 200 |

### PROD

| Endpoint | Status |
|---|---|
| API /health | 200 |
| Client /login | 200 |
| Client /inbox | 200 |
| Client /dashboard | 200 |
| Client /billing | 200 |
| Client /orders | 200 |

---

## 7. Rollback

### DEV
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.149-ai-consistency-dev -n keybuzz-api-dev
```

### PROD
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.149-ai-consistency-prod -n keybuzz-api-prod
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.149-ai-consistency-prod -n keybuzz-api-prod
```

Sources sauvegardees :
- `engine.ts.bak-pre-ph137d`
- `ai-assist-routes.ts.bak-pre-ph137d`

---

## 8. Verdict

**IA MODE STRUCTURED — PLAN GATED — ENTERPRISE READY — SCALABLE — ROLLBACK READY**

- Module `ai-mode-engine.ts` operationnel
- engine.ts et ai-assist-routes.ts utilisent `resolveIAMode()`
- Matrice plan/mode centralisee
- Gating KeyBuzz escalation prepare
- Image DEV : `v3.5.150-ai-mode-engine-dev` — Pod 1/1 Running
- Image PROD : `v3.5.150-ai-mode-engine-prod` — API + Worker 1/1 Running
- Non-regressions DEV + PROD : OK (tous endpoints 200)
- GitOps : 3 deployment.yaml mis a jour (API DEV, API PROD, Worker PROD)
- PROD deploye le 1 mars 2026 apres validation Ludovic
