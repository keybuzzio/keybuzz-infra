#!/bin/bash
# PH9-TLS-04 - Création Ingress admin.keybuzz.io (production)
# KeyBuzz v3 - Ingress pour KeyBuzz Admin (production)
# Ce script crée le manifest Ingress GitOps pour admin.keybuzz.io

set -euo pipefail

LOG_DIR="/opt/keybuzz/logs/phase9-tls"
mkdir -p "$LOG_DIR"

log_info() {
    echo "[INFO] $1" | tee -a "$LOG_DIR/ingress-admin-prod-creation.log"
}

log_error() {
    echo "[ERROR] $1" | tee -a "$LOG_DIR/ingress-admin-prod-creation.log" >&2
}

# Vérification kubectl
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl n'est pas installé"
    exit 1
fi

log_info "Vérification de l'accès au cluster..."
export KUBECONFIG=/root/.kube/config
if ! kubectl cluster-info &> /dev/null; then
    log_error "Impossible d'accéder au cluster Kubernetes"
    exit 1
fi

# Vérification namespace
log_info "Vérification du namespace keybuzz-admin..."
if ! kubectl get namespace keybuzz-admin &> /dev/null; then
    log_error "Namespace keybuzz-admin n'existe pas. Exécutez d'abord ph9_create_kb_namespaces.sh"
    exit 1
fi

# Vérification ClusterIssuer
log_info "Vérification du ClusterIssuer letsencrypt-prod..."
if ! kubectl get clusterissuer letsencrypt-prod &> /dev/null; then
    log_error "ClusterIssuer letsencrypt-prod n'existe pas. Exécutez d'abord ph9_create_clusterissuer_letsencrypt.sh"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "${SCRIPT_DIR}")"
MANIFESTS_DIR="$INFRA_DIR/k8s/keybuzz-admin"

log_info "Création du répertoire pour les manifests GitOps..."
mkdir -p "$MANIFESTS_DIR"

log_info "Création du manifest Ingress admin.keybuzz.io..."
cat > "$MANIFESTS_DIR/ingress-admin-prod.yaml" <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-admin-prod
  namespace: keybuzz-admin
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/proxy-body-size: "20m"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - admin.keybuzz.io
    secretName: keybuzz-admin-prod-tls
  rules:
  - host: admin.keybuzz.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: keybuzz-admin
            port:
              number: 3000
EOF

log_info "Manifest créé dans $MANIFESTS_DIR/ingress-admin-prod.yaml"

# Vérification si l'Ingress existe déjà
log_info "Vérification de l'Ingress existant..."
if kubectl get ingress ingress-admin-prod -n keybuzz-admin &> /dev/null; then
    log_info "⚠️  Ingress ingress-admin-prod existe déjà (idempotence OK)"
else
    log_info "Ingress ingress-admin-prod n'existe pas encore"
fi

log_info "✅ Manifest Ingress admin.keybuzz.io créé (GitOps-ready)"
log_info "📝 Pour appliquer via GitOps (ArgoCD) ou manuellement :"
log_info "   kubectl apply -f $MANIFESTS_DIR/ingress-admin-prod.yaml"

