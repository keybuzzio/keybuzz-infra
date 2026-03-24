# PH-ROLLBACK-PROD-PH116 — Rapport de rollback PROD vers PH116

> Date : 2026-03-20
> Environnement : PROD
> DEV : deja rollback vers PH116 (meme session)

---

## 1. Objectif

Aligner PROD sur DEV en revenant a PH116 (Real Execution Monitoring) — etat stable et valide.

---

## 2. Images avant/apres

### Avant rollback

| Service | Image |
|---|---|
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.59-channels-stripe-sync-prod` |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.6.19-ph117-ai-dashboard-prod` |
| Outbound PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.6.00-td02-worker-resilience-prod` (inchange) |
| Backend PROD | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.40-pj-fix-prod` (inchange) |

### Apres rollback

| Service | Image | Action |
|---|---|---|
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.59-channels-stripe-sync-prod` | **DEJA OK** |
| **API PROD** | `ghcr.io/keybuzzio/keybuzz-api:v3.6.18-ph116-real-execution-monitoring-prod` | **ROLLBACK** |
| Outbound PROD | inchange | — |
| Backend PROD | inchange | — |

Note : le client PROD etait deja sur la version cible. Seule l'API a ete rollbackee.

---

## 3. Procedure

1. **Snapshot complet** — images, pods, deployments captures avant modification
2. **Verification registry** — image API PH116 PROD confirmee (digest SHA256 identique DEV/PROD : `e225b881ca61...`)
3. **GitOps** — manifest `keybuzz-api-prod/deployment.yaml` modifie
4. **Push GitHub** — commit `06834d2` sur `main`
5. **kubectl apply** — manifest applique
6. **Rollout** — pod demarre, 0 restarts

### Pas d'incident

Contrairement au rollback DEV, aucun incident : `LEGACY_BACKEND_URL` etait deja present dans le manifest PROD.

### Note pre-existante

`LEGACY_BACKEND_URL` dans le manifest PROD pointe vers `keybuzz-backend-dev` au lieu de `keybuzz-backend-prod`. C'est un probleme pre-existant non corrige pendant ce rollback (hors scope).

---

## 4. Tests de validation

### API — 17 endpoints PH41-PH116

| Endpoint | Status | Resultat |
|---|---|---|
| `/health` | 200 | **PASS** |
| `/ai/quality-score` | 200 | **PASS** |
| `/ai/self-improvement` | 200 | **PASS** |
| `/ai/governance` | 200 | **PASS** |
| `/ai/knowledge-graph` | 200 | **PASS** |
| `/ai/long-term-memory` | 200 | **PASS** |
| `/ai/strategic-resolution` | 200 | **PASS** |
| `/ai/autonomous-ops` | 200 | **PASS** |
| `/ai/action-dispatcher` | 200 | **PASS** |
| `/ai/connector-abstraction` | 200 | **PASS** |
| `/ai/case-manager` | 200 | **PASS** |
| `/ai/case-state` | 200 | **PASS** |
| `/ai/controlled-execution` | 200 | **PASS** |
| `/ai/controlled-activation` | 200 | **PASS** |
| `/ai/real-execution-monitoring` | 200 | **PASS** |
| `/ai/cross-tenant-intelligence` | 200 | **PASS** |
| `/ai/real-execution-live` | 200 | **PASS** |

**17/17 PASS**

### IA — Pipeline complet

| Test | Resultat |
|---|---|
| `POST /ai/assist` conversation Amazon reelle | **200 OK** |
| Suggestion generee | **1 suggestion** |
| Nombre de couches `decisionContext` | **45 couches** |

### Client — Routes

| Route | Status |
|---|---|
| `/login` | **PASS** |
| `/channels` | **PASS** |
| `/billing` | **PASS** |
| `/inbox` | **PASS** |
| `/orders` | **PASS** |
| `/dashboard` | **PASS** |
| `/settings` | **PASS** |
| `/suppliers` | **PASS** |
| `/signup` | **PASS** |
| `/onboarding` | **PASS** |

**10/10 PASS**

### Bundle URLs

| Check | Resultat |
|---|---|
| `api.keybuzz.io` dans bundle | 2 (correct, PROD URL) |
| `api-dev.keybuzz.io` dans bundle | 0 (correct, aucun DEV) |

### UI — Login page navigateur

| Element | Status |
|---|---|
| Page charge | **PASS** |
| Titre "KeyBuzz Client Portal" | **PASS** |
| Champ email | **PASS** |
| Bouton "Envoyer le code" | **PASS** |
| OAuth Google/Microsoft | **PASS** |
| Lien "Creer un compte" | **PASS** |

---

## 5. Parite DEV = PROD

| Element | DEV | PROD | Identique |
|---|---|---|---|
| Client image | `v3.5.59-channels-stripe-sync-dev` | `v3.5.59-channels-stripe-sync-prod` | **OUI** (meme codebase) |
| API image | `v3.6.18-ph116-...-dev` | `v3.6.18-ph116-...-prod` | **OUI** (meme digest SHA256) |
| API health | 200 OK | 200 OK | **OUI** |
| decisionContext layers | 45 | 45 | **OUI** |
| IA suggestion | 1 | 1 | **OUI** |
| Client routes | 10/10 | 10/10 | **OUI** |
| Pod restarts | 0 | 0 | **OUI** |

---

## 6. Reversibilite

Pour revenir a PH117 si necessaire :

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.19-ph117-ai-dashboard-prod -n keybuzz-api-prod
```

---

## 7. GitOps

| Fichier | Commit | Status |
|---|---|---|
| `k8s/keybuzz-api-prod/deployment.yaml` | `06834d2` | Pousse sur main |

---

## 8. Verdict

**ROLLBACK PROD REUSSI** — PROD est sur PH116, identique a DEV. 17/17 endpoints PASS, 45 couches IA, 10/10 routes client, 0 restarts, parite confirmee.
