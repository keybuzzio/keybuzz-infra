# PH-S03.2J — Nettoyage GitOps : drift kubectl set image + ArgoCD selector immutable (DEV only)

**Date :** 2026-01-30  
**Périmètre :** Corriger la cause ArgoCD (selector immutable sur seller-client), revenir à un cluster 100 % conforme Git, prouver Synced + Healthy.  
**Environnement :** keybuzz-seller-dev uniquement.

---

## 1. Contexte et objectifs

- **Problème :** Un `kubectl set image` manuel a été fait sur seller-api pour contourner un sync ArgoCD en échec (drift interdit).
- **Cause ArgoCD :** Échec de sync à cause d’un **selector immutable** sur le Deployment **seller-client**.
- **Objectifs :**
  1. Corriger la cause ArgoCD (seller-client selector immutable) via manifests GitOps.
  2. Revenir à un cluster 100 % conforme Git (seller-api image digest incluse).
  3. Prouver ArgoCD : Synced + Healthy.

**Invariants :** DEV only, GitOps only, aucun secret en clair.

---

## 2. Diagnostic — ressource fautive

### A) Ressource en échec

- **Application ArgoCD :** `keybuzz-seller-dev`
- **Objet en échec :** Deployment **seller-client** (namespace `keybuzz-seller-dev`)
- **Message typique (immutable field) :**  
  `Deployment.apps "seller-client" is invalid: spec.selector: Forbidden: field is immutable`

### B) Cause racine

La **Kustomization** `keybuzz-seller-dev` utilisait **commonLabels** :

```yaml
commonLabels:
  app.kubernetes.io/part-of: keybuzz-seller
  environment: dev
```

Kustomize injecte ces labels dans **tous** les champs concernés, notamment :

- `spec.selector.matchLabels` des Deployments
- `spec.template.metadata.labels` des Deployments
- `spec.selector` des Services
- `metadata.labels` de toutes les ressources

Sur un cluster déjà déployé, le Deployment **seller-client** avait été créé **avant** l’ajout de ces commonLabels (ou avec une version sans commonLabels). Son `spec.selector.matchLabels` était donc uniquement :

- `app: seller-client`

Après mise à jour du repo avec commonLabels, le build Kustomize produit :

- `spec.selector.matchLabels`: `{ app: seller-client, app.kubernetes.io/part-of: keybuzz-seller, environment: dev }`

Kubernetes **interdit** toute modification de `spec.selector` sur un Deployment existant. ArgoCD tente d’appliquer ce nouveau selector → **Forbidden: field is immutable** → sync en échec.

---

## 3. Correction GitOps réalisée

### A) Règle Kubernetes respectée

- **Ne jamais modifier `spec.selector.matchLabels`** d’un Deployment existant.
- Les labels d’organisation (`app.kubernetes.io/part-of`, `environment`) sont conservés **uniquement** dans **metadata.labels** des ressources, pas dans les selectors.

### B) Modifications dans le repo

**1) `k8s/keybuzz-seller-dev/kustomization.yaml`**

- **Suppression de `commonLabels`** pour éviter toute injection dans `spec.selector` et `spec.template.metadata.labels` des Deployments.
- Commentaire PH-S03.2J ajouté pour expliquer la raison (éviter selector immutable).

**2) Labels d’organisation en dur dans chaque manifest**

Les labels `app.kubernetes.io/part-of: keybuzz-seller` et `environment: dev` sont ajoutés **uniquement** dans **metadata.labels** des ressources suivantes (pas dans les selectors) :

- `deployment-client.yaml` — metadata.labels (+ commentaire PH-S03.2J)
- `deployment-api.yaml` — metadata.labels (+ commentaire PH-S03.2J)
- `service-client.yaml` — metadata.labels
- `service-api.yaml` — metadata.labels
- `ingress-client.yaml` — metadata.labels
- `ingress-api.yaml` — metadata.labels
- `externalsecret-postgres.yaml` — metadata.labels
- `externalsecret-vault.yaml` — metadata.labels (+ `environment: dev`)
- `configmap-migration-006.yaml` — metadata.labels (+ `environment: dev`)
- `job-migrate-006.yaml` — metadata.labels (+ `environment: dev`)

**Selectors inchangés :**

- Deployment **seller-client** : `spec.selector.matchLabels` = `{ app: seller-client }`, `spec.template.metadata.labels` = `{ app: seller-client }`.
- Deployment **seller-api** : `spec.selector.matchLabels` = `{ app: seller-api }`, `spec.template.metadata.labels` = `{ app: seller-api }`.
- Services : `selector` = `app: seller-client` / `app: seller-api` (inchangé).

Aucun nouveau Deployment (nouveau nom) n’a été créé : le fix consiste à aligner le Git sur le selector déjà présent en cluster.

---

## 4. Image seller-api par digest (conformité Git)

- **Fichier :** `k8s/keybuzz-seller-dev/deployment-api.yaml`
- **Image :** déjà définie par **digest** (PH-S03.2I) :
  - `image: ghcr.io/keybuzzio/seller-api@sha256:61ea8f895e1537cbd9fb1f04ec7b86c443f6d77d26bb817f8dd18a365029ef16`
- Aucun `kubectl set image` ne doit être utilisé : après sync ArgoCD réussi, le pod seller-api doit tourner sur ce digest.

---

## 5. Validation à effectuer (après push + sync)

À exécuter sur un environnement disposant de `kubectl` et d’accès ArgoCD (cluster DEV).

### A) ArgoCD

```bash
# Sync + Healthy
argocd app get keybuzz-seller-dev

# Ou via kubectl
kubectl get application -n argocd keybuzz-seller-dev -o wide
```

**Résultat attendu :** Synced, Healthy (plus d’erreur "selector immutable").

### B) Images conformes aux manifests

```bash
kubectl -n keybuzz-seller-dev get deploy seller-api seller-client -o wide
kubectl -n keybuzz-seller-dev get pod -l app=seller-api -o jsonpath='{.items[0].spec.containers[0].image}'
kubectl -n keybuzz-seller-dev get pod -l app=seller-client -o jsonpath='{.items[0].spec.containers[0].image}'
```

**Résultat attendu :**

- seller-api : image avec digest `sha256:61ea8f895e1537cbd9fb1f04ec7b86c443f6d77d26bb817f8dd18a365029ef16`
- seller-client : `ghcr.io/keybuzzio/seller-client:v1.0.0` (conforme deployment-client.yaml)

### C) Aucun drift

- Aucun `kubectl set image` en cours : les images viennent uniquement des manifests Git.
- ArgoCD ne signale plus de diff sur seller-client (selector identique au cluster).

---

## 6. Récapitulatif

| Élément | Avant | Après |
|--------|--------|--------|
| commonLabels | Injectés dans selector → immutable | Supprimés ; labels en dur dans metadata uniquement |
| Deployment seller-client | Sync échoue (selector immutable) | Selector inchangé → sync OK |
| seller-api image | Drift possible (kubectl set image) | Définie par digest dans Git, pas de set image |
| ArgoCD | OutOfSync / Degraded | Synced + Healthy (après validation) |

**Fichiers modifiés :**

- `k8s/keybuzz-seller-dev/kustomization.yaml` — suppression commonLabels + commentaire PH-S03.2J
- `k8s/keybuzz-seller-dev/deployment-client.yaml` — metadata.labels + commentaire
- `k8s/keybuzz-seller-dev/deployment-api.yaml` — metadata.labels + commentaire
- `k8s/keybuzz-seller-dev/service-client.yaml` — metadata.labels
- `k8s/keybuzz-seller-dev/service-api.yaml` — metadata.labels
- `k8s/keybuzz-seller-dev/ingress-client.yaml` — metadata.labels
- `k8s/keybuzz-seller-dev/ingress-api.yaml` — metadata.labels
- `k8s/keybuzz-seller-dev/externalsecret-postgres.yaml` — metadata.labels
- `k8s/keybuzz-seller-dev/externalsecret-vault.yaml` — metadata.labels (environment: dev)
- `k8s/keybuzz-seller-dev/configmap-migration-006.yaml` — metadata.labels (environment: dev)
- `k8s/keybuzz-seller-dev/job-migrate-006.yaml` — metadata.labels (environment: dev)

**Livrable :** ce rapport (`keybuzz-infra/docs/PH-S03.2J-GITOPS-CLEANUP.md`) avec cause, fix et preuves à collecter (ArgoCD + runtime images).

**Statut :** Corrections GitOps appliquées. Validation ArgoCD et runtime à faire après push sur le repo et sync sur le cluster DEV.
