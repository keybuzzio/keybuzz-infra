#!/bin/bash
# PH9 - Installation ingress-nginx (bare-metal mode)
# KeyBuzz v3 - Ingress NGINX pour routage HTTP/HTTPS dans K8s
# Ce script installe ingress-nginx en mode bare-metal (hostNetwork/hostPorts)

set -euo pipefail

LOG_DIR="/opt/keybuzz/logs/phase9-ingress"
mkdir -p "$LOG_DIR"

log_info() {
    echo "[INFO] $1" | tee -a "$LOG_DIR/ingress-nginx-install.log"
}

log_error() {
    echo "[ERROR] $1" | tee -a "$LOG_DIR/ingress-nginx-install.log" >&2
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

log_info "Création du namespace ingress-nginx (si nécessaire)..."
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -

log_info "Installation ingress-nginx via manifeste officiel bare-metal..."
kubectl apply -f \
    https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/baremetal/deploy.yaml \
    2>&1 | tee -a "$LOG_DIR/ingress-nginx-install.log"

log_info "Attente des pods ingress-nginx (timeout 300s)..."
if kubectl wait --namespace ingress-nginx \
    --for=condition=Ready pods \
    --selector=app.kubernetes.io/name=ingress-nginx \
    --timeout=300s 2>&1 | tee -a "$LOG_DIR/ingress-nginx-install.log"; then
    log_info "✅ Tous les pods ingress-nginx sont Ready"
else
    log_error "⚠️  Certains pods ingress-nginx ne sont pas encore Ready"
fi

log_info "État des pods ingress-nginx:"
kubectl get pods -n ingress-nginx -o wide | tee "$LOG_DIR/ingress-nginx-pods.txt"

log_info "Services ingress-nginx:"
kubectl get svc -n ingress-nginx | tee -a "$LOG_DIR/ingress-nginx-pods.txt"

log_info "✅ Installation ingress-nginx terminée"

