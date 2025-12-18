#!/bin/bash
# PH9 - Suppression de la page de test
# KeyBuzz v3 - Suppression des ressources de test avant le déploiement de KeyBuzz Admin (PH10)

set -euo pipefail

LOG_DIR="/opt/keybuzz/logs/phase9-tls"
mkdir -p "$LOG_DIR"

log_info() {
    echo "[INFO] $1" | tee -a "$LOG_DIR/test-page-remove.log"
}

log_error() {
    echo "[ERROR] $1" | tee -a "$LOG_DIR/test-page-remove.log" >&2
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

log_info "Suppression des ressources de test..."

# Supprimer les Services de test
log_info "Suppression des Services keybuzz-admin (test)..."
kubectl delete service keybuzz-admin -n keybuzz-admin-dev --ignore-not-found=true 2>&1 | tee -a "$LOG_DIR/test-page-remove.log"
kubectl delete service keybuzz-admin -n keybuzz-admin --ignore-not-found=true 2>&1 | tee -a "$LOG_DIR/test-page-remove.log"

# Supprimer les Deployments de test
log_info "Suppression des Deployments keybuzz-admin-test..."
kubectl delete deployment keybuzz-admin-test -n keybuzz-admin-dev --ignore-not-found=true 2>&1 | tee -a "$LOG_DIR/test-page-remove.log"
kubectl delete deployment keybuzz-admin-test -n keybuzz-admin --ignore-not-found=true 2>&1 | tee -a "$LOG_DIR/test-page-remove.log"

# Supprimer les ConfigMaps de test
log_info "Suppression des ConfigMaps test-page-html..."
kubectl delete configmap test-page-html -n keybuzz-admin-dev --ignore-not-found=true 2>&1 | tee -a "$LOG_DIR/test-page-remove.log"
kubectl delete configmap test-page-html -n keybuzz-admin --ignore-not-found=true 2>&1 | tee -a "$LOG_DIR/test-page-remove.log"

# Vérifier que tout est supprimé
log_info "Vérification de la suppression..."
sleep 2

if kubectl get deployment keybuzz-admin-test -n keybuzz-admin-dev &> /dev/null; then
    log_error "⚠️  Le Deployment keybuzz-admin-test existe encore dans keybuzz-admin-dev"
else
    log_info "✅ Deployment keybuzz-admin-test supprimé de keybuzz-admin-dev"
fi

if kubectl get deployment keybuzz-admin-test -n keybuzz-admin &> /dev/null; then
    log_error "⚠️  Le Deployment keybuzz-admin-test existe encore dans keybuzz-admin"
else
    log_info "✅ Deployment keybuzz-admin-test supprimé de keybuzz-admin"
fi

if kubectl get service keybuzz-admin -n keybuzz-admin-dev &> /dev/null; then
    log_error "⚠️  Le Service keybuzz-admin existe encore dans keybuzz-admin-dev"
else
    log_info "✅ Service keybuzz-admin supprimé de keybuzz-admin-dev"
fi

if kubectl get service keybuzz-admin -n keybuzz-admin &> /dev/null; then
    log_error "⚠️  Le Service keybuzz-admin existe encore dans keybuzz-admin"
else
    log_info "✅ Service keybuzz-admin supprimé de keybuzz-admin"
fi

log_info "✅ Page de test supprimée avec succès"
log_info "Vous pouvez maintenant déployer KeyBuzz Admin (PH10)"

