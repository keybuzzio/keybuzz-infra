# PH10-UI-DEPLOY-01 — KeyBuzz Admin Kubernetes Deployment

**Date** : 2025-12-09  
**Phase** : PH10-UI-DEPLOY-01  
**Objectif** : Manifests Kubernetes et Applications ArgoCD pour KeyBuzz Admin

---

## 📁 Arborescence

```
keybuzz-infra/
├── k8s/
│   ├── keybuzz-admin-dev/
│   │   ├── deployment.yaml      # Deployment pour dev
│   │   ├── service.yaml          # Service ClusterIP pour dev
│   │   └── kustomization.yaml   # Kustomization pour dev
│   └── keybuzz-admin/
│       ├── deployment.yaml      # Deployment pour prod
│       ├── service.yaml          # Service ClusterIP pour prod
│       └── kustomization.yaml   # Kustomization pour prod
└── argocd/
    └── apps/
        ├── keybuzz-admin-dev.yaml  # Application ArgoCD pour dev
        └── keybuzz-admin.yaml      # Application ArgoCD pour prod
```

---

## 🎯 Manifests Kubernetes

### keybuzz-admin-dev

**Namespace** : `keybuzz-admin-dev`

**Deployment** :
- Replicas : 1
- Image : `REGISTRY_PLACEHOLDER/keybuzz-admin:DEV_TAG`
- Port : 3000
- Resources : 100m CPU / 256Mi RAM (requests), 500m CPU / 512Mi RAM (limits)

**Service** :
- Type : ClusterIP
- Port : 3000 → 3000
- Backend pour Ingress : `admin-dev.keybuzz.io`

### keybuzz-admin

**Namespace** : `keybuzz-admin`

**Deployment** :
- Replicas : 2
- Image : `REGISTRY_PLACEHOLDER/keybuzz-admin:PROD_TAG`
- Port : 3000
- Resources : 200m CPU / 512Mi RAM (requests), 1000m CPU / 1Gi RAM (limits)

**Service** :
- Type : ClusterIP
- Port : 3000 → 3000
- Backend pour Ingress : `admin.keybuzz.io`

---

## 🔄 Applications ArgoCD

### Configuration

Les Applications ArgoCD sont configurées pour :

- **Source** : Repository Git `keybuzz-infra` (branch `main`)
- **Sync Policy** : Automatique avec `prune` et `selfHeal`
- **CreateNamespace** : Activé
- **RevisionHistoryLimit** : 3

### keybuzz-admin-dev

- **Name** : `keybuzz-admin-dev`
- **Namespace** : `argocd`
- **Path** : `k8s/keybuzz-admin-dev`
- **Destination** : `keybuzz-admin-dev`

### keybuzz-admin

- **Name** : `keybuzz-admin`
- **Namespace** : `argocd`
- **Path** : `k8s/keybuzz-admin`
- **Destination** : `keybuzz-admin`

---

## 🔀 Pipeline GitOps attendu

### 1. Build & Push Image

```bash
# Build
cd /opt/keybuzz/keybuzz-admin
docker build -t ghcr.io/keybuzzio/keybuzz-admin:v1.0.0-dev .

# Push
docker push ghcr.io/keybuzzio/keybuzz-admin:v1.0.0-dev
```

### 2. Mise à jour des Manifests

```bash
# Mettre à jour l'image dans les manifests
cd /opt/keybuzz/keybuzz-infra
sed -i 's|REGISTRY_PLACEHOLDER/keybuzz-admin:DEV_TAG|ghcr.io/keybuzzio/keybuzz-admin:v1.0.0-dev|g' k8s/keybuzz-admin-dev/deployment.yaml
```

### 3. Commit & Push

```bash
git add k8s/keybuzz-admin-dev/deployment.yaml
git commit -m "feat: update keybuzz-admin-dev image to v1.0.0-dev"
git push origin main
```

### 4. Sync ArgoCD

ArgoCD détecte automatiquement le changement et synchronise :

```bash
# Ou manuellement
argocd app sync keybuzz-admin-dev
```

### 5. Vérification

```bash
kubectl get pods -n keybuzz-admin-dev
kubectl get svc -n keybuzz-admin-dev
curl -k https://admin-dev.keybuzz.io
```

---

## ⚠️ Actions manuelles requises

### 1. Configuration du Registry

Avant le premier déploiement, remplacer les placeholders dans les manifests :

- `REGISTRY_PLACEHOLDER/keybuzz-admin:DEV_TAG` → Image réelle
- `REGISTRY_PLACEHOLDER/keybuzz-admin:PROD_TAG` → Image réelle

### 2. Push de l'image

L'image Docker doit être pushée vers le registry configuré avant le déploiement.

### 3. Création des Applications ArgoCD

Les fichiers YAML des Applications ArgoCD sont prêts, mais doivent être créés dans le cluster :

```bash
# Via ArgoCD CLI
argocd app create -f argocd/apps/keybuzz-admin-dev.yaml
argocd app create -f argocd/apps/keybuzz-admin.yaml

# Ou via kubectl (si ArgoCD est installé)
kubectl apply -f argocd/apps/keybuzz-admin-dev.yaml
kubectl apply -f argocd/apps/keybuzz-admin.yaml
```

### 4. Sync initial

Après création des Applications, déclencher la synchronisation :

```bash
argocd app sync keybuzz-admin-dev
argocd app sync keybuzz-admin
```

---

## 📝 Notes importantes

1. **GitOps uniquement** : Les manifests ne doivent pas être appliqués directement avec `kubectl apply`. Tout passe par ArgoCD.

2. **Images** : Les placeholders doivent être remplacés avant le premier déploiement.

3. **Ingress** : Les Ingress `admin-dev.keybuzz.io` et `admin.keybuzz.io` existent déjà et pointent vers le Service `keybuzz-admin:3000`.

4. **TLS** : Les certificats Let's Encrypt sont gérés par cert-manager et sont déjà fonctionnels.

5. **Namespaces** : Les namespaces `keybuzz-admin-dev` et `keybuzz-admin` existent déjà (créés en PH9-TLS-02).

---

**Auteur** : KeyBuzz Infrastructure Team  
**Dernière mise à jour** : 2025-12-09

