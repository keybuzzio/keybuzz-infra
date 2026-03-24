# PH-TD-08 — Safe Deploy Pipeline

> **Date** : 20 mars 2026
> **Prerequis** : PH-DEPLOY-PROCESS-ROOTCAUSE-01 (audit)
> **Objectif** : eliminer definitivement les builds contamines et les deploys non-reproductibles

---

## 1. PROBLEME RESOLU

Chaque build Docker client utilisait `COPY . .` depuis le bastion, embarquant silencieusement
des fichiers non commites de multiples phases. Le release gate approuvait les images cassees.
ArgoCD PROD etait casse. Les deploys etaient manuels via `kubectl set image`.

## 2. ARCHITECTURE DU PIPELINE

```
Developpeur (Windows/local)
    |
    | git push
    v
GitHub (keybuzz-client)
    |
    | git clone --depth 1
    v
Bastion (build-from-git.sh)
    |
    | docker build (Dockerfile.client = COPY explicite)
    v
Image Docker
    |
    | verify-image-clean.sh (non-regression)
    v
Verification OK ?
    |
    |-- NON --> BLOQUE (image non pushee)
    |
    | OUI
    v
docker push GHCR
    |
    | (PROD only) frontend-release-gate.sh
    v
Gate OK ?
    |
    |-- NON --> BLOQUE (image non deployee)
    |
    | OUI
    v
Update deployment.yaml (keybuzz-infra)
    |
    | git commit + push
    v
ArgoCD sync automatique
    |
    v
Cluster K8s
```

## 3. SCRIPTS FOURNIS

| Script | Role | Emplacement |
|--------|------|-------------|
| `build-client.sh` | Build avec guardrails bloquants (dirty check, git sync) | `keybuzz-infra/scripts/` |
| `build-from-git.sh` | Build depuis un clone Git fresh (zero contamination) | `keybuzz-infra/scripts/` |
| `verify-image-clean.sh` | Verification image : pages critiques, URLs, non-regression | `keybuzz-infra/scripts/` |
| `frontend-release-gate.sh` | Gate final avant promotion PROD | `keybuzz-infra/scripts/` |
| `deploy-safe.sh` | Pipeline unique (build → verify → gate → push → gitops → sync) | `keybuzz-infra/scripts/` |
| `block-manual-prod-deploy.sh` | Detection de drift PROD (kubectl vs gitops) | `keybuzz-infra/scripts/` |
| `Dockerfile.client` | Dockerfile securise (COPY explicite, pas de `COPY . .`) | `keybuzz-infra/dockerfiles/` |

## 4. UTILISATION

### Deploiement DEV

```bash
# Depuis le bastion
cd /opt/keybuzz/keybuzz-infra
./scripts/deploy-safe.sh dev v3.5.61-feature-name-dev main
```

### Deploiement PROD

```bash
# Depuis le bastion
cd /opt/keybuzz/keybuzz-infra
./scripts/deploy-safe.sh prod v3.5.61-feature-name-prod main
```

### Verification manuelle d'une image

```bash
./scripts/verify-image-clean.sh ghcr.io/keybuzzio/keybuzz-client:v3.5.61-feature-dev dev
```

### Gate PROD manuelle

```bash
./scripts/frontend-release-gate.sh ghcr.io/keybuzzio/keybuzz-client:v3.5.61-feature-prod
```

### Detection de drift PROD

```bash
./scripts/block-manual-prod-deploy.sh /opt/keybuzz/keybuzz-infra
```

## 5. GUARDRAILS IMPLEMENTES

| # | Guardrail | Comportement | Script |
|---|-----------|-------------|--------|
| G1 | Workspace dirty | **exit 1** (bloque le build) | build-client.sh |
| G2 | HEAD ≠ GitHub | **exit 1** (bloque le build) | build-client.sh |
| G3 | Tag suffix ≠ env | **exit 1** (dev→-dev, prod→-prod) | build-client.sh |
| G4 | Fichiers requis manquants | **exit 1** | build-client.sh |
| G5 | Pages critiques absentes | **exit 1** (ne pas pusher) | verify-image-clean.sh |
| G6 | /signup est un formulaire bypass | **exit 1** | verify-image-clean.sh |
| G7 | URL contamination (dev↔prod) | **exit 1** | verify-image-clean.sh |
| G8 | Routes manifest incomplet | **exit 1** | verify-image-clean.sh |
| G9 | DEV URL dans PROD | **exit 1** | frontend-release-gate.sh |
| G10 | Drift cluster vs gitops | **alerte** | block-manual-prod-deploy.sh |

## 6. DOCKERFILE SECURISE

Le `Dockerfile.client` remplace `COPY . .` par des COPY explicites :

```dockerfile
COPY package.json package-lock.json ./
COPY next.config.mjs ./
COPY tsconfig.json ./
COPY tailwind.config.ts ./
COPY postcss.config.cjs ./
COPY app ./app
COPY src ./src
COPY public ./public
COPY scripts/generate-build-metadata.py ./scripts/
```

Cela garantit que seuls les fichiers applicatifs sont inclus dans le build.
Les scripts, fichiers temporaires, et modifications non commitees sont exclus.

## 7. FIX ARGOCD PROD

Le fichier `k8s/keybuzz-client-prod/externalsecret-auth.yaml` a ete corrige :
- **Avant** : `apiVersion: external-secrets.io/v1beta1`
- **Apres** : `apiVersion: external-secrets.io/v1`

Cette correction debloquera ArgoCD PROD qui est en `SyncFailed` depuis le 4 mars 2026.

## 8. MIGRATION DEPUIS L'ANCIEN SYSTEME

### Avant (dangereux)

```bash
# SCP fichiers vers bastion
scp fichier.tsx root@bastion:/opt/keybuzz/keybuzz-client/app/

# Build depuis bastion sale
cd /opt/keybuzz/keybuzz-client
docker build --no-cache -t ghcr.io/keybuzzio/keybuzz-client:v3.5.60-fix-dev .
docker push ...

# Deploy manuel
kubectl set image deploy/keybuzz-client keybuzz-client=... -n keybuzz-client-prod
```

### Apres (securise)

```bash
# 1. Commit et push vers GitHub depuis local
git add -A && git commit -m "fix: description" && git push origin main

# 2. Pipeline unique depuis le bastion
cd /opt/keybuzz/keybuzz-infra
./scripts/deploy-safe.sh dev v3.5.61-fix-dev main
```

## 9. INTERDICTIONS

| Action | Statut |
|--------|--------|
| `docker build .` depuis `/opt/keybuzz/keybuzz-client/` | **INTERDIT** |
| `scp` de fichiers vers le bastion sans commit Git | **INTERDIT** |
| `kubectl set image` sur PROD | **INTERDIT** (sauf urgence documentee) |
| Build sans `--no-cache` | **INTERDIT** |
| Tag `:latest` | **INTERDIT** |
| Push sans verification image | **INTERDIT** |

## 10. PROCEDURE D'URGENCE

En cas d'urgence absolue necessitant un rollback :

```bash
# 1. Identifier l'image stable
kubectl get deploy keybuzz-client -n keybuzz-client-prod -o jsonpath='{.spec.template.spec.containers[0].image}'

# 2. Mettre a jour le manifest Git
cd /opt/keybuzz/keybuzz-infra
vim k8s/keybuzz-client-prod/deployment.yaml
git add . && git commit -m "EMERGENCY ROLLBACK: raison" && git push origin main

# 3. Si ArgoCD bloque, DERNIER RECOURS :
kubectl set image deploy/keybuzz-client keybuzz-client=<IMAGE_STABLE> -n keybuzz-client-prod
# PUIS documenter et mettre a jour le manifest Git
```
