#!/bin/bash
# PH9 - Installation cert-manager
# KeyBuzz v3 - cert-manager pour gestion automatique des certificats TLS
# Ce script installe cert-manager via Helm avec les CRDs

set -euo pipefail

LOG_DIR="/opt/keybuzz/logs/phase9-ingress"
mkdir -p "$LOG_DIR"

log_info() {
    echo "[INFO] $1" | tee -a "$LOG_DIR/cert-manager-install.log"
}

log_error() {
    echo "[ERROR] $1" | tee -a "$LOG_DIR/cert-manager-install.log" >&2
}

# Vérification kubectl
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl n'est pas installé"
    exit 1
fi

# Vérification helm
if ! command -v helm &> /dev/null; then
    log_error "helm n'est pas installé"
    exit 1
fi

log_info "Vérification de l'accès au cluster..."
export KUBECONFIG=/root/.kube/config
if ! kubectl cluster-info &> /dev/null; then
    log_error "Impossible d'accéder au cluster Kubernetes"
    exit 1
fi

log_info "Création du namespace cert-manager (si nécessaire)..."
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -

log_info "Installation des CRDs cert-manager..."
kubectl apply --validate=false -f \
    https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.crds.yaml \
    2>&1 | tee -a "$LOG_DIR/cert-manager-install.log"

log_info "Ajout du repository Helm jetstack..."
helm repo add jetstack https://charts.jetstack.io 2>&1 | tee -a "$LOG_DIR/cert-manager-install.log"
helm repo update 2>&1 | tee -a "$LOG_DIR/cert-manager-install.log"

log_info "Installation cert-manager via Helm (version v1.15.3)..."
helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --version v1.15.3 \
    --set installCRDs=false \
    2>&1 | tee -a "$LOG_DIR/cert-manager-install.log"

log_info "Attente des pods cert-manager (timeout 300s)..."
if kubectl wait --namespace cert-manager \
    --for=condition=Ready pods \
    --selector=app.kubernetes.io/instance=cert-manager \
    --timeout=300s 2>&1 | tee -a "$LOG_DIR/cert-manager-install.log"; then
    log_info "✅ Tous les pods cert-manager sont Ready"
else
    log_error "⚠️  Certains pods cert-manager ne sont pas encore Ready"
fi

log_info "État des pods cert-manager:"
kubectl get pods -n cert-manager -o wide | tee "$LOG_DIR/cert-manager-pods.txt"

log_info "Services cert-manager:"
kubectl get svc -n cert-manager | tee -a "$LOG_DIR/cert-manager-pods.txt"

log_info "✅ Installation cert-manager terminée"

