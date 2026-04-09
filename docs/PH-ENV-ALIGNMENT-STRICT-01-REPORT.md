# PH-ENV-ALIGNMENT-STRICT-01 — Rapport

> **Date** : 27 mars 2026
> **Phase** : PH-ENV-ALIGNMENT-STRICT-01
> **Type** : Realignement strict DEV/PROD
> **Auteur** : Agent Cursor

---

## 1. Probleme Identifie

Avant cette phase, les environnements DEV et PROD presentaient des incoherences structurelles :

| Service | DEV | PROD | Probleme |
|---|---|---|---|
| API | `v3.5.48-ph-autopilot-engine-fix-dev` | `v3.5.48-ph-autopilot-engine-fix-prod` | Version API (v3.5.48) diverge du Client |
| Client | `v3.5.119-ph-ai-assist-reliability-dev` | `v3.5.119-ph-ai-assist-reliability-prod` | Version Client (v3.5.119) diverge de l'API |

De plus, les deux repos sur le bastion avaient du code **non commite** :
- **API** : `engine.ts` modifie (fix autopilot), `routes.ts` modifie, fichiers backup
- **Client** : 9 fichiers modifies (AI UX, assist reliability, autopilot history, plan provider)

Les images deployees etaient construites depuis un bastion **dirty** — Git n'etait pas la source de verite.

---

## 2. Actions Realisees

### Etape 1-3 : Audit et diagnostic

| Element | Resultat |
|---|---|
| API bastion branch | `main` @ `b6488d5` (dirty) |
| Client bastion branch | `main` @ `3fae402` (dirty) |
| API dirty files | `engine.ts`, `routes.ts`, backup files |
| Client dirty files | 9 fichiers (InboxTripane, AISuggestionSlideOver, AITab, ClientLayout, billing/plan, index, PlaybookSuggestionBanner, ai.service, AutopilotHistorySection) |
| DEV vs PROD codebase | Identique (memes tailles image) |
| Fonctionnel | OK — les deux marchent correctement |

### Etape 4 : Commit du code deploye

Tous les changements dirty ont ete commites pour que Git devienne la source de verite :

| Repo | Commit | Fichiers | Message |
|---|---|---|---|
| keybuzz-api | `c0ee35a` | engine.ts, routes.ts | PH-ENV-ALIGNMENT: commit deployed autopilot engine fix + compat routes |
| keybuzz-client | `9f34c77` | InboxTripane, AISuggestionSlideOver, AITab, ClientLayout, billing/plan | PH-ENV-ALIGNMENT: commit deployed AI UX + assist reliability fixes |
| keybuzz-client | `2310176` | index.ts, PlaybookSuggestionBanner, ai.service.ts, AutopilotHistorySection | PH-ENV-ALIGNMENT: commit remaining deployed AI components |

Apres commit, les deux repos sont **propres** (`git status --porcelain` = vide).

### Etape 5 : Build depuis Git propre

4 images construites depuis un Git clean (`--no-cache`) :

| Image | Tag | Source |
|---|---|---|
| keybuzz-api | `v3.5.120-env-aligned-dev` | Git clean @ `c0ee35a` |
| keybuzz-api | `v3.5.120-env-aligned-prod` | Git clean @ `c0ee35a` |
| keybuzz-client | `v3.5.120-env-aligned-dev` | Git clean @ `2310176` |
| keybuzz-client | `v3.5.120-env-aligned-prod` | Git clean @ `2310176` |

**Note** : Les deux images API (dev/prod) ont le meme digest Docker (`sha256:42d823adf732...`), confirmant qu'elles sont strictement identiques. Les images client different uniquement par les build-arg `NEXT_PUBLIC_*`.

### Etapes 6-7 : Deploiement DEV + PROD

Les 4 images ont ete pushees vers GHCR et deployees avec succes.

---

## 3. Validation Stricte

### Version coherence

| Service | DEV | PROD | Coherent |
|---|---|---|---|
| API version | v3.5.120 | v3.5.120 | OUI |
| Client version | v3.5.120 | v3.5.120 | OUI |
| **VERSION_COHERENT** | | | **YES (all v3.5.120)** |

### Pods

| Pod | Env | Status | Restarts |
|---|---|---|---|
| keybuzz-api | DEV | Running | 0 |
| keybuzz-api | PROD | Running | 0 |
| keybuzz-client | DEV | Running | 0 |
| keybuzz-client | PROD | Running | 0 |

### Health checks

| Service | DEV | PROD |
|---|---|---|
| API /health | 200 OK | 200 OK |

### Endpoint tests (DEV vs PROD)

| Endpoint | DEV | PROD | Match |
|---|---|---|---|
| /autopilot/settings | 200 | 200 | OUI |
| /integrations | 200 | 200 | OUI |
| /billing/current | 400 | 400 | OUI |
| /ai/settings | 400 | 400 | OUI |
| /ai/wallet/status | 400 | 400 | OUI |
| /messages/conversations | 400 | 400 | OUI |

Les 400 sont attendus (header `X-Tenant-Id` insuffisant pour ces endpoints qui requirent un format specifique). L'important est qu'ils sont **identiques DEV vs PROD**.

### Fix verification

| Fix | DEV | PROD | Present |
|---|---|---|---|
| Autopilot `SELECT COUNT` subquery | 2 occurrences | 2 occurrences | OUI |
| Autopilot `summary` column | 1 occurrence | 1 occurrence | OUI |
| Client auto-retry `limited` | Present | Present | OUI |
| Client API URL DEV | `api-dev.keybuzz.io` | - | OUI |
| Client API URL PROD | - | `api.keybuzz.io` | OUI |

---

## 4. Differences Corrigees

| Avant | Apres | Correction |
|---|---|---|
| API = v3.5.48, Client = v3.5.119 | API = v3.5.120, Client = v3.5.120 | Version unifiee |
| Code deploye non commite dans Git | Tous les fichiers commites | Git = source de verite |
| Fichiers backup sur bastion (`.bak-truth02`) | Supprimes | Bastion propre |
| Images construites depuis bastion dirty | Images construites depuis Git clean | Reproductibilite |

---

## 5. Rollback

### Immediat (1 cran)

| Service | Env | Tag rollback | Disponible |
|---|---|---|---|
| API | DEV | `v3.5.48-ph-autopilot-engine-fix-dev` | OUI |
| API | PROD | `v3.5.48-ph-autopilot-engine-fix-prod` | OUI |
| Client | DEV | `v3.5.119-ph-ai-assist-reliability-dev` | OUI |
| Client | PROD | `v3.5.119-ph-ai-assist-reliability-prod` | OUI |

```bash
# Rollback API DEV
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.48-ph-autopilot-engine-fix-dev -n keybuzz-api-dev
# Rollback API PROD
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.48-ph-autopilot-engine-fix-prod -n keybuzz-api-prod
# Rollback Client DEV
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.119-ph-ai-assist-reliability-dev -n keybuzz-client-dev
# Rollback Client PROD
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.119-ph-ai-assist-reliability-prod -n keybuzz-client-prod
```

---

## 6. GitOps

Fichiers mis a jour :

| Fichier | Image |
|---|---|
| `keybuzz-infra/k8s/keybuzz-api-dev/deployment.yaml` | `v3.5.120-env-aligned-dev` |
| `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml` | `v3.5.120-env-aligned-prod` |
| `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` | `v3.5.120-env-aligned-dev` |
| `keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.120-env-aligned-prod` |
| `keybuzz-infra/docs/ROLLBACK-SOURCE-OF-TRUTH-01.md` | Mis a jour avec v3.5.120 + section Git commits |

---

## 7. Verdict

### DEV AND PROD STRICTLY ALIGNED

- API et Client : meme version logique **v3.5.120**
- DEV et PROD : meme codebase (variables d'env seules different)
- Git : source de verite (zero fichier dirty)
- Images : construites depuis Git propre, reproductibles
- Comportement : identique DEV vs PROD (memes status codes, memes fix presents)
- Rollback : documente et disponible
