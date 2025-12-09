#!/bin/bash
# PH9-TLS-02 - Création des namespaces KeyBuzz Admin
# KeyBuzz v3 - Namespaces pour keybuzz-admin-dev et keybuzz-admin
# Ce script crée les namespaces avec les labels appropriés

set -euo pipefail

LOG_DIR="/opt/keybuzz/logs/phase9-tls"
mkdir -p "$LOG_DIR"

log_info() {
    echo "[INFO] $1" | tee -a "$LOG_DIR/namespaces-creation.log"
}

log_error() {
    echo "[ERROR] $1" | tee -a "$LOG_DIR/namespaces-creation.log" >&2
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

# Namespace keybuzz-admin-dev
log_info "Création du namespace keybuzz-admin-dev (si nécessaire)..."
if kubectl get namespace keybuzz-admin-dev &> /dev/null; then
    log_info "⚠️  Namespace keybuzz-admin-dev existe déjà (idempotence OK)"
    log_info "Mise à jour des labels..."
    kubectl label namespace keybuzz-admin-dev \
        app=keybuzz \
        tier=frontend \
        env=dev \
        --overwrite \
        2>&1 | tee -a "$LOG_DIR/namespaces-creation.log"
else
    log_info "Création du namespace keybuzz-admin-dev..."
    kubectl create namespace keybuzz-admin-dev \
        --dry-run=client -o yaml | \
    kubectl label --local -f - \
        app=keybuzz \
        tier=frontend \
        env=dev \
        --dry-run=client -o yaml | \
    kubectl apply -f - \
        2>&1 | tee -a "$LOG_DIR/namespaces-creation.log"
fi

# Namespace keybuzz-admin
log_info "Création du namespace keybuzz-admin (si nécessaire)..."
if kubectl get namespace keybuzz-admin &> /dev/null; then
    log_info "⚠️  Namespace keybuzz-admin existe déjà (idempotence OK)"
    log_info "Mise à jour des labels..."
    kubectl label namespace keybuzz-admin \
        app=keybuzz \
        tier=frontend \
        env=prod \
        --overwrite \
        2>&1 | tee -a "$LOG_DIR/namespaces-creation.log"
else
    log_info "Création du namespace keybuzz-admin..."
    kubectl create namespace keybuzz-admin \
        --dry-run=client -o yaml | \
    kubectl label --local -f - \
        app=keybuzz \
        tier=frontend \
        env=prod \
        --dry-run=client -o yaml | \
    kubectl apply -f - \
        2>&1 | tee -a "$LOG_DIR/namespaces-creation.log"
fi

log_info "Vérification des namespaces créés..."
kubectl get namespaces keybuzz-admin-dev keybuzz-admin -o wide | tee "$LOG_DIR/namespaces-list.txt"

log_info "Labels des namespaces:"
kubectl get namespace keybuzz-admin-dev -o jsonpath='{.metadata.labels}' | tee -a "$LOG_DIR/namespaces-list.txt"
echo "" | tee -a "$LOG_DIR/namespaces-list.txt"
kubectl get namespace keybuzz-admin -o jsonpath='{.metadata.labels}' | tee -a "$LOG_DIR/namespaces-list.txt"
echo "" | tee -a "$LOG_DIR/namespaces-list.txt"

log_info "✅ Namespaces KeyBuzz créés avec succès"

