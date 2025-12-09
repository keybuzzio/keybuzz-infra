#!/bin/bash
# PH9-TLS-01 - Création ClusterIssuer Let's Encrypt (production + staging)
# KeyBuzz v3 - Configuration cert-manager pour génération automatique de certificats TLS
# Ce script crée les ClusterIssuers Let's Encrypt (prod et staging) via manifests GitOps

set -euo pipefail

LOG_DIR="/opt/keybuzz/logs/phase9-tls"
mkdir -p "$LOG_DIR"

log_info() {
    echo "[INFO] $1" | tee -a "$LOG_DIR/clusterissuer-creation.log"
}

log_error() {
    echo "[ERROR] $1" | tee -a "$LOG_DIR/clusterissuer-creation.log" >&2
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

# Vérification cert-manager
log_info "Vérification de cert-manager..."
if ! kubectl get crd clusterissuers.cert-manager.io &> /dev/null; then
    log_error "cert-manager n'est pas installé (CRD clusterissuers.cert-manager.io introuvable)"
    exit 1
fi

# Vérification ingress-nginx
log_info "Vérification ingress-nginx..."
if ! kubectl get ingressclass nginx &> /dev/null; then
    log_error "ingress-nginx n'est pas installé (IngressClass nginx introuvable)"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "${SCRIPT_DIR}")"
MANIFESTS_DIR="$INFRA_DIR/k8s/cluster-issuers"

log_info "Création du répertoire pour les manifests GitOps..."
mkdir -p "$MANIFESTS_DIR"

# ClusterIssuer Let's Encrypt Production
log_info "Création du manifest ClusterIssuer Let's Encrypt Production..."
cat > "$MANIFESTS_DIR/letsencrypt-prod.yaml" <<'EOF'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
  labels:
    app: cert-manager
    issuer: letsencrypt
    environment: production
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@keybuzz.io
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

# ClusterIssuer Let's Encrypt Staging
log_info "Création du manifest ClusterIssuer Let's Encrypt Staging..."
cat > "$MANIFESTS_DIR/letsencrypt-staging.yaml" <<'EOF'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
  labels:
    app: cert-manager
    issuer: letsencrypt
    environment: staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: admin@keybuzz.io
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

log_info "Manifests créés dans $MANIFESTS_DIR/"
log_info "  - letsencrypt-prod.yaml"
log_info "  - letsencrypt-staging.yaml"

# Vérification si les ClusterIssuers existent déjà
log_info "Vérification des ClusterIssuers existants..."
if kubectl get clusterissuer letsencrypt-prod &> /dev/null; then
    log_info "⚠️  ClusterIssuer letsencrypt-prod existe déjà (idempotence OK)"
else
    log_info "ClusterIssuer letsencrypt-prod n'existe pas encore"
fi

if kubectl get clusterissuer letsencrypt-staging &> /dev/null; then
    log_info "⚠️  ClusterIssuer letsencrypt-staging existe déjà (idempotence OK)"
else
    log_info "ClusterIssuer letsencrypt-staging n'existe pas encore"
fi

log_info "✅ Manifests ClusterIssuer créés (GitOps-ready)"
log_info "📝 Pour appliquer via GitOps (ArgoCD) ou manuellement :"
log_info "   kubectl apply -f $MANIFESTS_DIR/letsencrypt-prod.yaml"
log_info "   kubectl apply -f $MANIFESTS_DIR/letsencrypt-staging.yaml"

