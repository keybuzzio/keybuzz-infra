# PH136-A — GitOps Rollback Hardening

> Date : 30 mars 2026
> Auteur : Cursor Executor
> Statut : APPLIQUE (DEV + PROD aligne, drift = 0)

---

## Probleme

`kubectl set image` etait utilise comme methode de deploiement ET de rollback dans :
- **150+ rapports** (sections "Rollback" des phases PH43 a PH135)
- **100+ scripts** de build/deploy (scripts/*.sh)
- **13 scripts** infra (keybuzz-infra/scripts/*.sh)

Consequences :
- Le cluster divergeait des manifests Git (drift)
- Aucune tracabilite des rollbacks
- ArgoCD voyait un `OutOfSync` permanent
- Un rollback ne pouvait pas etre reproduit depuis Git

---

## Actions realisees

### 1. Audit drift cluster vs Git

Tous les services principaux ont ete compares :

| Service | Avant PH136-A | Apres PH136-A |
|---------|---------------|----------------|
| API DEV | OK | OK |
| API PROD | OK | OK |
| Worker DEV | OK | OK |
| Worker PROD | OK | OK |
| Client DEV | OK | OK |
| Client PROD | OK | OK |
| Backend DEV | **DRIFT** (v1.0.40 vs v1.0.42) | OK |
| Backend PROD | OK | OK |

**1 drift corrige** : Backend DEV manifest aligne sur `v1.0.42-ph-oauth-persist-dev`.

### 2. Synchronisation bastion

Les 8 manifests principaux ont ete synces depuis Git local vers le bastion.
Un probleme de `\r` (CRLF Windows) causait des faux positifs — corrige.

### 3. Scripts crees

#### `rollback-service.sh`

Script officiel de rollback GitOps :
```bash
/opt/keybuzz/keybuzz-infra/scripts/rollback-service.sh <service> <env> <version>
```

- Modifie le manifest YAML (source de verite)
- `kubectl apply -f` (pas `kubectl set image`)
- Attend le rollout
- Verifie l'image deployee
- Rappelle de syncer vers Git local

Services supportes : `api`, `worker`, `client`, `backend`

#### `check-drift.sh`

Script de verification drift cluster vs Git :
```bash
/opt/keybuzz/keybuzz-infra/scripts/check-drift.sh
```

Compare les 8 services principaux (API/Worker/Client/Backend x DEV/PROD).

### 4. Regle CE mise a jour

`deployment-safety.mdc` enrichi avec :
- **REGLE 8** : Rollback GitOps uniquement, interdiction de `kubectl set image` dans les rapports
- **REGLE 9** : Verification drift obligatoire apres chaque deploiement

---

## Decision sur les archives historiques

Les 150+ rapports et 100+ scripts existants contenant `kubectl set image` ne sont PAS modifies.

Raisons :
- Ce sont des archives historiques — les modifier n'apporte aucune valeur
- Le risque d'introduction d'erreur est disproportionne
- La regle CE (`deployment-safety.mdc`) empeche la repetition du pattern
- Les scripts anciens ne sont plus executes

---

## Verification finale

```
═══════════════════════════════════════════════════
  GitOps Drift Report
  2026-03-30 20:48:36 UTC
═══════════════════════════════════════════════════

  API DEV                   OK
  API PROD                  OK
  Worker DEV                OK
  Worker PROD               OK
  Client DEV                OK
  Client PROD               OK
  Backend DEV               OK
  Backend PROD              OK

  No drift detected. Git = Cluster.
```

---

## Fichiers crees / modifies

| Fichier | Action |
|---------|--------|
| `keybuzz-infra/scripts/rollback-service.sh` | Cree |
| `keybuzz-infra/scripts/check-drift.sh` | Cree |
| `keybuzz-infra/k8s/keybuzz-backend-dev/deployment.yaml` | Drift corrige |
| `.cursor/rules/deployment-safety.mdc` | Regles 8 + 9 ajoutees |

---

## Versions deployees (verifie 30 mars 2026)

| Service | DEV | PROD |
|---------|-----|------|
| API | `v3.5.144-replyto-subject-fix-dev` | `v3.5.144-replyto-subject-fix-prod` |
| Worker | `v3.6.09-replyto-subject-fix-dev` | `v3.6.09-replyto-subject-fix-prod` |
| Client | `v3.5.131-autopilot-contextual-draft-dev` | `v3.5.131-autopilot-contextual-draft-prod` |
| Backend | `v1.0.42-ph-oauth-persist-dev` | `v1.0.42-ph-oauth-persist-prod` |

---

## Verdict

GITOPS ROLLBACK ENFORCED — NO DIRECT KUBECTL — STATE CONSISTENT — ROLLBACK SAFE
