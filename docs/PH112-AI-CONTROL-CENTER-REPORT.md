# PH112 - AI Control Panel (Admin V2 Integration)

> Date : 17 mars 2026
> Environnement : DEV
> API Image : `v3.6.14-ph112-ai-control-center-dev`
> Admin Image : `v2.1.4-ph112-ai-control-center`

---

## Objectif

Connecter PH111 Controlled Activation Layer a une interface admin exploitable dans Admin V2, permettant de :
- Voir l'etat IA global (gouvernance, autonomie, rollout)
- Controler l'activation des actions par connecteur
- Gerer les policies d'activation
- Monitorer les performances et la sante IA
- Debugger les endpoints IA

## Architecture

### Composants modifies

**keybuzz-api** (v3.6.14) :
- `controlledActivationEngine.ts` : ajout `upsertActivationPolicy()` et `deleteActivationPolicy()`
- `ai-policy-debug-routes.ts` : ajout endpoints POST/DELETE `/controlled-activation/policies`

**keybuzz-admin-v2** (v2.1.4) :
- `config/navigation.ts` : nouvelle section "Intelligence IA" (5 entrees)
- `config/endpoints.ts` : registre complet des endpoints AI control
- `components/layout/Sidebar.tsx` : icones BrainCircuit, ToggleRight, ShieldCheck, BarChart3, Bug
- `features/ai-control/services/ai-control.service.ts` : service API complet
- 5 nouvelles pages dans `app/(admin)/ai-control/`

## Pages creees

| Route | Titre | Fonctionnalite |
|-------|-------|----------------|
| `/ai-control` | Overview | Gouvernance, autonomie, rollout, execution |
| `/ai-control/activation` | Activation Control | Matrice actions, toggle mode, confirmation |
| `/ai-control/policies` | Execution Policies | CRUD policies, rollout stages |
| `/ai-control/monitoring` | AI Monitoring | Health, metrics, audit, logs execution |
| `/ai-control/debug` | Debug IA | 15 endpoints debug, inspection brute JSON |

## Endpoints API

### Lecture (existants, PH98-PH111)
| Endpoint | Usage |
|----------|-------|
| GET `/ai/controlled-activation` | Etat activation tenant |
| GET `/ai/controlled-activation/policies` | Policies configurees |
| GET `/ai/controlled-activation/matrix` | Matrice complte actions |
| GET `/ai/controlled-execution` | Etat execution |
| GET `/ai/controlled-execution/policies` | Policies execution |
| GET `/ai/controlled-execution/logs` | Logs tentatives |
| GET `/ai/governance` | Etat gouvernance |
| GET `/ai/health-monitoring` | Sante systeme |
| GET `/ai/performance-metrics` | Metriques performance |
| GET `/ai/execution-audit` | Audit execution |

### Ecriture (nouveaux PH112)
| Endpoint | Usage |
|----------|-------|
| POST `/ai/controlled-activation/policies` | Creer/modifier policy |
| DELETE `/ai/controlled-activation/policies` | Supprimer policy |

## Securite UX

- **Confirmation obligatoire** pour `REAL_ALLOWED` et `REAL_WITH_HUMAN_REVIEW`
- **Confirmation obligatoire** avant suppression de policy
- **Actions exclues definitivement** : ESCALATE_LEGAL, ESCALATE_FRAUD, PREPARE_REFUND_REVIEW
- **Acces admin uniquement** (middleware NextAuth)
- **Tenant scoping** : toutes les operations sont scopees par tenant

## Verification DEV

```
PASS health: 200
PASS PH111-activation: 200
PASS PH111-policies: 200
PASS PH112-matrix: 200 (12 actions)
PASS PH100-governance: 200
PASS PH110-execution: 200
PASS PH110-exec-policies: 200
PASS PH110-exec-logs: 200
PASS PH99-selfimprovement: 200
PASS PH108-casemanager: 200
PASS PH109-casestate: 200
PASS PH106-dispatcher: 200
PASS PH107-connector: 200
PASS PH105-ops: 200
PASS PH103-strategy: 200

API: 15 PASS / 1 SKIP (PH98 require conversationId)
Admin: Running, image v2.1.4-ph112-ai-control-center
```

## Non-regression

Pipeline IA PH41 -> PH111 intact :
- Aucun endpoint modifie, uniquement ajout POST/DELETE
- Aucun comportement IA modifie
- Aucun impact KBActions

## Rollback

**API :**
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.13-ph111-controlled-activation-dev -n keybuzz-api-dev
```

**Admin :**
```bash
kubectl set image deploy/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.1.3-ws -n keybuzz-admin-v2-dev
```
