# PH-ROLLBACK-PROD-PH115 — Rapport de rollback PROD vers PH115

> Date : 2026-03-20
> Environnement : PROD uniquement
> Objectif : isoler si PH116 contribue au probleme UI visible

---

## 1. Objectif

Rollbacker l'API PROD de PH116 vers PH115 pour determiner si PH116 est la cause des symptomes UI signales. Le client n'est pas impacte (meme image).

---

## 2. Images avant/apres

### Avant rollback (PH116)

| Service | Image |
|---|---|
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.59-channels-stripe-sync-prod` |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.6.18-ph116-real-execution-monitoring-prod` |

### Apres rollback (PH115)

| Service | Image | Action |
|---|---|---|
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.59-channels-stripe-sync-prod` | **INCHANGE** |
| **API PROD** | `ghcr.io/keybuzzio/keybuzz-api:v3.6.17-ph115-real-execution-prod` | **ROLLBACK** |

### Digests

| Image | SHA256 |
|---|---|
| PH116 PROD | `e225b881ca6138533e4f4ca70e78d62351eaa4642f9772b391009558cd01f800` |
| PH115 PROD | `14b8a8fc7a9fc8a8d85d0731f7ffbffe53305f466d889d780e8bf2eded7e60cd` |

Les deux digests sont differents — codebase distinct confirme.

---

## 3. Procedure

1. **Snapshot complet** — images, pods, deployments captures
2. **Verification registry** — image PH115 PROD confirmee
3. **GitOps** — manifest `keybuzz-api-prod/deployment.yaml` modifie
4. **Push GitHub** — commit `950aad9` sur `main`
5. **kubectl apply** — manifest applique
6. **Rollout** — pod demarre, 0 restarts
7. Aucun incident

---

## 4. Tests de validation

### API — 16 endpoints PH41-PH115

| Endpoint | PH116 | PH115 | Status |
|---|---|---|---|
| `/health` | 200 | 200 | **PASS** |
| `/ai/quality-score` | 200 | 200 | **PASS** |
| `/ai/self-improvement` | 200 | 200 | **PASS** |
| `/ai/governance` | 200 | 200 | **PASS** |
| `/ai/knowledge-graph` | 200 | 200 | **PASS** |
| `/ai/long-term-memory` | 200 | 200 | **PASS** |
| `/ai/strategic-resolution` | 200 | 200 | **PASS** |
| `/ai/autonomous-ops` | 200 | 200 | **PASS** |
| `/ai/action-dispatcher` | 200 | 200 | **PASS** |
| `/ai/connector-abstraction` | 200 | 200 | **PASS** |
| `/ai/case-manager` | 200 | 200 | **PASS** |
| `/ai/case-state` | 200 | 200 | **PASS** |
| `/ai/controlled-execution` | 200 | 200 | **PASS** |
| `/ai/controlled-activation` | 200 | 200 | **PASS** |
| `/ai/cross-tenant-intelligence` | 200 | 200 | **PASS** |
| `/ai/real-execution-live` | 200 | 200 | **PASS** |
| `/ai/real-execution-monitoring` | **200** | **404** | Attendu (endpoint PH116) |

**16/16 PASS** (hors endpoint PH116 absent par design)

### IA — Pipeline complet

| Test | PH116 | PH115 | Identique |
|---|---|---|---|
| `POST /ai/assist` status | 200 | 200 | OUI |
| Suggestions generees | 1 | 1 | OUI |
| decisionContext layers | 45 | 45 | **OUI** |
| Couches presentes | identiques | identiques | **OUI** |

### Client — Routes et UI

| Test | PH116 | PH115 | Identique |
|---|---|---|---|
| Routes client | 10/10 | 10/10 | **OUI** |
| Login page | OK | OK | **OUI** |
| Client image | `v3.5.59` | `v3.5.59` | **OUI** (meme image) |

---

## 5. Comparaison PH116 vs PH115

### Differences API

| Element | PH116 | PH115 |
|---|---|---|
| Endpoint `/ai/real-execution-monitoring` | 200 | 404 (absent) |
| Tout le reste | Identique | Identique |

### Impact UI

| Element UI | PH116 | PH115 | Change apres rollback ? |
|---|---|---|---|
| Client image | `v3.5.59` | `v3.5.59` | **NON** |
| Login page | OK | OK | **NON** |
| Routes | 10/10 | 10/10 | **NON** |
| Menu | Inchange | Inchange | **NON** |
| Focus mode | Inchange | Inchange | **NON** |

---

## 6. Verdict

### Le rollback PH115 change-t-il le symptome UI ?

**NON.**

Le client PROD est sur la meme image (`v3.5.59-channels-stripe-sync-prod`) avant et apres le rollback API. Tout symptome UI visible (menu fixe, focus mode, etc.) est **independant de PH116 vs PH115** :

- Le rollback API de PH116 a PH115 n'impacte que l'endpoint `/ai/real-execution-monitoring` (absent en PH115)
- Le pipeline IA est strictement identique (45 couches, memes suggestions)
- L'UI est identique car le client n'a pas change

### Conclusion

> **Le probleme UI, s'il existe, est pre-existant et independant de PH116.**
> Il se situe dans le **client** (`v3.5.59-channels-stripe-sync-prod`) et non dans l'API.
> Le rollback API vers PH115 ne corrige rien cote UI.

---

## 7. Reversibilite

Pour revenir a PH116 :

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.18-ph116-real-execution-monitoring-prod -n keybuzz-api-prod
```

Pour revenir a PH117 :

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.19-ph117-ai-dashboard-prod -n keybuzz-api-prod
```

---

## 8. GitOps

| Fichier | Commit | Status |
|---|---|---|
| `k8s/keybuzz-api-prod/deployment.yaml` | `950aad9` | Pousse sur main |

---

## 9. Etat final

| Service | DEV | PROD |
|---|---|---|
| Client | `v3.5.59-channels-stripe-sync-dev` | `v3.5.59-channels-stripe-sync-prod` |
| API | `v3.6.18-ph116-...-dev` | `v3.6.17-ph115-...-prod` |

Note : DEV reste sur PH116, PROD est sur PH115 pour isolation.
