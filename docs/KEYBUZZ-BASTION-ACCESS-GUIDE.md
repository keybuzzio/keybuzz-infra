# Guide d'AccÃ¨s Bastion KeyBuzz â€” Pour Agent Cursor

## ðŸ” Connexion SSH

### Serveur Bastion
```
Hostname: install-v3
IP:       46.62.171.61
User:     root
OS:       Ubuntu 24.04.3 LTS
```

### Commande de connexion
```bash
ssh root@46.62.171.61 -i $env:USERPROFILE\.ssh\id_rsa_keybuzz_v3
```

> **Note**: La clÃ© SSH `id_rsa_keybuzz_v3` doit Ãªtre prÃ©sente dans `~/.ssh/` sur la machine locale.

---

## ðŸ“ Structure des RÃ©pertoires

```
/opt/keybuzz/
â”œâ”€â”€ keybuzz-admin/        # Admin panel (React/Metronic)
â”œâ”€â”€ keybuzz-api/          # API publique (Hono/TypeScript)
â”œâ”€â”€ keybuzz-backend/      # Backend principal (Fastify/Prisma)
â”œâ”€â”€ keybuzz-client/       # Client portal (Next.js)
â”œâ”€â”€ keybuzz-infra/        # Infrastructure K8S manifests
â”œâ”€â”€ keybuzz-docs/         # Documentation
â”œâ”€â”€ credentials/          # âš ï¸ NE PAS TOUCHER - secrets
â”œâ”€â”€ secrets/              # âš ï¸ NE PAS TOUCHER - secrets
â””â”€â”€ manifests-prod/       # Manifests production
```

---

## â˜¸ï¸ Kubernetes Cluster

### Namespaces Existants

| Namespace | Usage |
|-----------|-------|
| `keybuzz-client-dev` | Client portal DEV |
| `keybuzz-client-prod` | Client portal PROD |
| `keybuzz-backend-dev` | Backend API DEV |
| `keybuzz-admin-dev` | Admin panel DEV |
| `keybuzz-admin` | Admin panel PROD |
| `keybuzz-api-dev` | API publique DEV |
| `keybuzz-api-prod` | API publique PROD |
| `ingress-nginx` | Ingress controller |
| `cert-manager` | Certificats TLS Let's Encrypt |

### Domaines Existants

| Domaine | Service |
|---------|---------|
| `client-dev.keybuzz.io` | Client portal DEV |
| `client.keybuzz.io` | Client portal PROD |
| `backend-dev.keybuzz.io` | Backend API DEV |
| `admin-dev.keybuzz.io` | Admin DEV |
| `admin.keybuzz.io` | Admin PROD |
| `api-dev.keybuzz.io` | API publique DEV |
| `api.keybuzz.io` | API publique PROD |

---

## ðŸŒ CrÃ©er un Nouveau Site Web

### 1. CrÃ©er le Namespace

```bash
kubectl create namespace keybuzz-website
```

### 2. Template Deployment + Service + Ingress

CrÃ©er un fichier `/opt/keybuzz/keybuzz-infra/k8s/website/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keybuzz-website
  namespace: keybuzz-website
spec:
  replicas: 1
  selector:
    matchLabels:
      app: keybuzz-website
  template:
    metadata:
      labels:
        app: keybuzz-website
    spec:
      containers:
      - name: keybuzz-website
        image: ghcr.io/keybuzzio/keybuzz-website:latest
        ports:
        - containerPort: 3000
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      imagePullSecrets:
      - name: ghcr-secret
---
apiVersion: v1
kind: Service
metadata:
  name: keybuzz-website
  namespace: keybuzz-website
spec:
  selector:
    app: keybuzz-website
  ports:
  - port: 80
    targetPort: 3000
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: keybuzz-website
  namespace: keybuzz-website
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - www.keybuzz.io
    - keybuzz.io
    secretName: keybuzz-website-tls
  rules:
  - host: www.keybuzz.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: keybuzz-website
            port:
              number: 80
  - host: keybuzz.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: keybuzz-website
            port:
              number: 80
```

### 3. CrÃ©er le Secret pour GHCR

```bash
kubectl create secret docker-registry ghcr-secret \
  --namespace=keybuzz-website \
  --docker-server=ghcr.io \
  --docker-username=keybuzzio \
  --docker-password=<GITHUB_TOKEN>
```

> **Note**: Le token GitHub est dans `/opt/keybuzz/credentials/` ou demander Ã  l'admin.

### 4. Appliquer les Manifests

```bash
kubectl apply -f /opt/keybuzz/keybuzz-infra/k8s/website/deployment.yaml
```

### 5. VÃ©rifier le DÃ©ploiement

```bash
# VÃ©rifier les pods
kubectl get pods -n keybuzz-website

# VÃ©rifier l'ingress
kubectl get ingress -n keybuzz-website

# VÃ©rifier le certificat TLS
kubectl get certificate -n keybuzz-website
```

---

## ðŸ³ Docker Build & Push

### Build une image
```bash
cd /opt/keybuzz/keybuzz-website
docker build -t ghcr.io/keybuzzio/keybuzz-website:v1.0.0 .
```

### Push vers GHCR
```bash
docker push ghcr.io/keybuzzio/keybuzz-website:v1.0.0
```

### Mettre Ã  jour le dÃ©ploiement
```bash
kubectl -n keybuzz-website set image deployment/keybuzz-website \
  keybuzz-website=ghcr.io/keybuzzio/keybuzz-website:v1.0.0
```

---

## âš ï¸ RÃ¨gles de SÃ©curitÃ©

### âŒ NE PAS FAIRE

1. **Ne pas toucher aux namespaces `*-prod`** sans validation
2. **Ne pas modifier** `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/`
3. **Ne pas supprimer** de ressources existantes
4. **Ne pas modifier** `ingress-nginx` ou `cert-manager`
5. **Ne pas exposer** de secrets dans les logs

### âœ… BONNES PRATIQUES

1. **Toujours tester en DEV** avant PROD
2. **Utiliser des tags versionnÃ©s** pour les images (pas `latest` en prod)
3. **Committer les manifests** dans `keybuzz-infra` avant d'appliquer
4. **VÃ©rifier les logs** aprÃ¨s dÃ©ploiement:
   ```bash
   kubectl logs -n keybuzz-website deployment/keybuzz-website
   ```
5. **Rollback si problÃ¨me**:
   ```bash
   kubectl rollout undo deployment/keybuzz-website -n keybuzz-website
   ```

---

## ðŸ”§ Commandes Utiles

```bash
# Voir tous les pods
kubectl get pods -A

# Voir les logs d'un pod
kubectl logs -n <namespace> <pod-name>

# ExÃ©cuter une commande dans un pod
kubectl exec -it -n <namespace> <pod-name> -- sh

# Voir les events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Describe une ressource
kubectl describe pod -n <namespace> <pod-name>

# Port-forward pour test local
kubectl port-forward -n <namespace> svc/<service-name> 8080:80
```

---

## ðŸ“ž Support

- **Repo Infra**: `/opt/keybuzz/keybuzz-infra/`
- **Docs**: `/opt/keybuzz/keybuzz-infra/docs/`
- **Logs**: `/opt/keybuzz/logs/`

---

*DerniÃ¨re mise Ã  jour: 2026-01-22*
