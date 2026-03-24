# PH-ROLLBACK-DEV-PH116 — Rapport de rollback DEV vers PH116

> Date : 2026-03-20
> Environnement : DEV uniquement
> PROD : inchangee (lecture seule)

---

## 1. Objectif

Revenir a un etat 100% fonctionnel et valide en DEV, base sur PH116 (Real Execution Monitoring), sans perte de donnees ni effet secondaire.

---

## 2. Images avant/apres

### Avant rollback

| Service | Image |
|---|---|
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.60-ph117-aligned-dev` |
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.6.19-ph117-ai-dashboard-dev` |
| Backend DEV | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.40-pj-fix-dev` (inchange) |
| Outbound DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.6.00-td02-worker-resilience-dev` (inchange) |

### Apres rollback

| Service | Image | Status |
|---|---|---|
| **Client DEV** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.59-channels-stripe-sync-dev` | **DEPLOYED** |
| **API DEV** | `ghcr.io/keybuzzio/keybuzz-api:v3.6.18-ph116-real-execution-monitoring-dev` | **DEPLOYED** |
| Backend DEV | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.40-pj-fix-dev` | inchange |
| Outbound DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.6.00-td02-worker-resilience-dev` | inchange |

### PROD (inchangee)

| Service | Image |
|---|---|
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.59-channels-stripe-sync-prod` |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.6.19-ph117-ai-dashboard-prod` |

---

## 3. Procedure suivie

1. **Snapshot complet** — deployments, pods, services, images captures avant modification
2. **Verification registry** — les 2 images cibles existent dans GHCR (pull reussi)
3. **GitOps** — manifests `deployment.yaml` modifies dans `keybuzz-infra/k8s/`
4. **Push GitHub** — 2 commits pushes sur `main`
5. **kubectl apply** — manifests appliques directement
6. **Rollout** — client et API rollout confirmes
7. **Correction LEGACY_BACKEND_URL** — variable env manquante dans le manifest (ajoutee)

### Incident pendant rollback

Le manifest API DEV sur le bastion etait desynchronise (contenait `v3.5.98-ph97` au lieu de `v3.6.19-ph117`). Cela a cause :
- Le premier pod API en CrashLoopBackOff (variable `LEGACY_BACKEND_URL` manquante)
- Correction immediate : ajout de `LEGACY_BACKEND_URL=http://keybuzz-backend.keybuzz-backend-dev.svc.cluster.local:4000`
- Deuxieme apply : pod demarre correctement

---

## 4. Tests de validation

### API — Endpoints PH41 a PH116

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
| Couches presentes | costAwareness, buyerReputation, marketplacePolicy, sellerDNA, customerPatience, resolutionCostOptimizer, multiOrderContext, aiQualityScore, knowledgeGraph, longTermMemory, strategicResolution, autonomousOpsPlan, actionDispatcher, connectorAbstraction, caseManager, caseStatePersistence, controlledExecution, controlledActivation, safeExecution, aiGovernance, + 25 autres |

### Client — Routes et bundle

| Test | Resultat |
|---|---|
| `/login` route | **PASS** |
| `/channels` route | **PASS** |
| `/billing` route | **PASS** |
| `/inbox` route | **PASS** |
| `/orders` route | **PASS** |
| `/dashboard` route | **PASS** |
| `/settings` route | **PASS** |
| `/suppliers` route | **PASS** |
| `/signup` route | **PASS** |
| `/onboarding` route | **PASS** |
| Occurrences `api.keybuzz.io` (PROD) dans bundle | **0** (correct) |
| Occurrences `api-dev.keybuzz.io` (DEV) dans bundle | **2** (correct) |

**10/10 routes PASS**

### UI — Login page

| Test | Resultat |
|---|---|
| Page `/login` charge | **PASS** |
| Formulaire email visible | **PASS** |
| Bouton "Envoyer le code" visible | **PASS** |
| Boutons OAuth (Google/Microsoft) visibles | **PASS** |
| Envoi OTP fonctionne | **PASS** |
| Formulaire code verification affiche | **PASS** |

---

## 5. Etat final

| Composant | Etat |
|---|---|
| Client DEV | `v3.5.59-channels-stripe-sync-dev` — Running, 0 restarts |
| API DEV | `v3.6.18-ph116-real-execution-monitoring-dev` — Running, 0 restarts |
| Health check | 200 OK |
| Pipeline IA PH41-PH116 | 100% fonctionnel (45 couches decisionContext) |
| Routes client | 10/10 presentes |
| Bundle URLs | Correctes (api-dev.keybuzz.io uniquement) |
| PROD | Inchangee |

---

## 6. Reversibilite

Pour revenir a PH117 si necessaire :

```bash
# Client
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.60-ph117-aligned-dev -n keybuzz-client-dev

# API
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.19-ph117-ai-dashboard-dev -n keybuzz-api-dev
```

---

## 7. GitOps

| Fichier | Commit | Status |
|---|---|---|
| `k8s/keybuzz-client-dev/deployment.yaml` | `048d97d` | Pousse sur main |
| `k8s/keybuzz-api-dev/deployment.yaml` | `bd02de2` | Pousse sur main (avec LEGACY_BACKEND_URL) |

---

## 8. Verdict

**ROLLBACK REUSSI** — DEV est sur PH116 stable baseline, toutes les fonctionnalites PH41-PH116 sont operationnelles, aucune perte de donnees, aucun effet secondaire.
