# PH-TD-06 — Build Pipeline Hardening

> Date : 2026-03-20
> Environnement : DEV + GitOps
> Statut : **TERMINE — OPERATIONNEL**

## Probleme resolu

L'incident PH117 a revele que le client DEV avait ete build **avant** la synchronisation des fichiers source PH117 sur le bastion, tandis que le client PROD avait ete build **apres**. Cela a cree un desalignement invisible entre DEV et PROD.

**Cause racine** : aucun guardrail ne validait la coherence du code source, de l'environnement et du bundle avant deployment.

## Solution implementee

### 3 scripts de securisation

| Script | Role | Emplacement |
|---|---|---|
| `build-client.sh` | Build securise avec guardrails | `/opt/keybuzz/keybuzz-client/scripts/` |
| `verify-build-consistency.sh` | Verification post-build d'une image | `/opt/keybuzz/keybuzz-client/scripts/` |
| `client-runtime-audit.sh` | Audit runtime post-deploy | `/opt/keybuzz/keybuzz-client/scripts/` |

### Guardrails du build (`build-client.sh`)

| # | Guardrail | Action si echec |
|---|---|---|
| 1 | Repo dirty check | WARNING (affiche fichiers non commites) |
| 2 | Validation tag/env (DEV tag doit finir par `-dev`, PROD par `-prod`) | **BLOCK** |
| 3 | Fichiers requis presents | **BLOCK** |
| 4 | Post-build : `/ai-dashboard` present dans bundle | **BLOCK** |
| 5 | Post-build : BFF `/api/ai/dashboard` present | **BLOCK** |
| 6 | Post-build : zero URL de l'autre environnement | **BLOCK** |

### Usage

```bash
# Build DEV
cd /opt/keybuzz/keybuzz-client
bash scripts/build-client.sh dev v3.5.60-ph117-aligned-dev

# Build PROD
bash scripts/build-client.sh prod v3.5.60-ph117-aligned-prod

# Verification image
bash scripts/verify-build-consistency.sh ghcr.io/keybuzzio/keybuzz-client:v3.5.60-ph117-aligned-dev dev

# Audit runtime post-deploy
bash scripts/client-runtime-audit.sh dev
```

### Build metadata enrichi

Le generateur `generate-build-metadata.py` inclut maintenant :
- `gitSha` : commit SHA (avec suffixe `-dirty` si repo non commite)
- `buildDate` : timestamp UTC du build
- `environment` : `development` / `production`
- `apiUrl` : URL API injectee au build

Le Dockerfile accepte les build args `GIT_COMMIT_SHA` et `BUILD_TIME`.

## Tests de validation

### Guardrail tests (5/5 PASS)

| Test | Resultat |
|---|---|
| DEV tag `-prod` | REFUSE |
| PROD tag `-dev` | REFUSE |
| Env invalide | REFUSE |
| Args manquants | REFUSE avec usage |
| Tag correct | PASS guardrails |

### verify-build-consistency.sh (11/11 PASS)

| Check | Resultat |
|---|---|
| ai-dashboard page | PRESENT |
| BFF ai/dashboard | PRESENT |
| IA Performance label | FOUND |
| No wrong API URL | CLEAN |
| Correct API URL | FOUND |
| /channels, /billing, /inbox, /orders, /dashboard, /settings | OK |

### client-runtime-audit.sh (12/12 PASS)

| Check | Resultat |
|---|---|
| Pod running | PASS |
| Zero restarts | PASS |
| ai-dashboard page | PASS |
| BFF ai/dashboard | PASS |
| IA Performance menu | PASS |
| Core pages (6) | PASS |
| Correct API URL | PASS |

## Workflow recommande

```
1. git pull + verifier code source a jour
2. bash scripts/build-client.sh <env> <tag>
   -> guardrails automatiques
   -> build --no-cache
   -> verification post-build automatique
3. docker push <image>
4. Mettre a jour deployment.yaml dans keybuzz-infra
5. git push (ArgoCD sync automatique)
6. bash scripts/client-runtime-audit.sh <env>
   -> verification pod + features + URLs
```

## Prevention incidents futurs

| Risque | Prevention |
|---|---|
| Build depuis code non synchronise | Warning repo dirty |
| Melange DEV/PROD URLs | Guardrail tag suffix + URL check |
| Feature manquante dans bundle | Post-build verification automatique |
| Deployment sans verification | Script audit runtime disponible |
| Rollback sans reference | Tag de rollback documente dans deployment.yaml |

## ArgoCD

Le namespace `keybuzz-client-dev` est gere par ArgoCD.
Les deploiements via `kubectl set image` sont revertes par ArgoCD.
Procedure correcte : modifier `deployment.yaml` dans `keybuzz-infra`, push sur GitHub, ArgoCD sync automatique.
