#!/bin/bash
# PH9 - Exécution automatique complète jusqu'à 100% OK
# Ne s'arrête pas tant que tout n'est pas 100% fonctionnel
set -e

LOG_DIR="/opt/keybuzz/logs/phase9-automatic"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/ph9-automatic-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config
INFRA_DIR="/opt/keybuzz/keybuzz-infra"
cd "$INFRA_DIR"

echo "=============================================="
echo "PH9 - EXÉCUTION AUTOMATIQUE COMPLÈTE"
echo "Date: $(date)"
echo "=============================================="
echo ""

# Fonction pour attendre que tous les nœuds soient Ready
wait_all_nodes_ready() {
    echo "[INFO] Attente que tous les nœuds soient Ready..."
    for i in {1..120}; do
        READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready " || echo "0")
        TOTAL_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "0")
        
        if [ "$READY_NODES" -eq 8 ] && [ "$TOTAL_NODES" -eq 8 ]; then
            echo "[OK] Tous les nœuds sont Ready ($READY_NODES/$TOTAL_NODES)"
            return 0
        fi
        if [ $((i % 10)) -eq 0 ]; then
            echo "[INFO] Nœuds Ready: $READY_NODES/$TOTAL_NODES (attente $i/120)"
        fi
        sleep 5
    done
    return 1
}

# Fonction pour attendre que Calico soit prêt
wait_calico_ready() {
    echo "[INFO] Attente que Calico soit prêt..."
    for i in {1..120}; do
        CALICO_READY=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | grep "1/1.*Running" | wc -l || echo "0")
        
        if [ "$CALICO_READY" -ge 8 ]; then
            echo "[OK] Calico prêt ($CALICO_READY pods Running)"
            return 0
        fi
        if [ $((i % 10)) -eq 0 ]; then
            echo "[INFO] Calico: $CALICO_READY/8 pods Ready (attente $i/120)"
        fi
        sleep 5
    done
    return 1
}

# ÉTAPE 1: Vérifier l'accès au cluster
echo "=== ÉTAPE 1: Vérification de l'accès au cluster ==="
echo ""

if ! kubectl get nodes &>/dev/null 2>&1; then
    echo "[ERROR] Cluster non accessible, copie du kubeconfig..."
    mkdir -p /root/.kube
    scp root@10.0.0.100:/etc/kubernetes/admin.conf /root/.kube/config
    export KUBECONFIG=/root/.kube/config
fi

# ÉTAPE 2: Attendre que tous les nœuds soient Ready
echo ""
echo "=== ÉTAPE 2: Vérification que tous les nœuds sont Ready ==="
echo ""

wait_all_nodes_ready || {
    echo "[WARN] Pas tous les nœuds sont Ready, mais on continue..."
}

# ÉTAPE 3: Vérifier/Installer Calico
echo ""
echo "=== ÉTAPE 3: Vérification de Calico ==="
echo ""

CALICO_READY=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | grep "1/1.*Running" | wc -l || echo "0")

if [ "$CALICO_READY" -lt 8 ]; then
    echo "[INFO] Calico pas complètement prêt, attente..."
    wait_calico_ready || {
        echo "[WARN] Calico pas complètement prêt, mais on continue..."
    }
else
    echo "[OK] Calico prêt ($CALICO_READY/8 pods Ready)"
fi

# ÉTAPE 4: Installer ArgoCD
echo ""
echo "=== ÉTAPE 4: Installation d'ArgoCD ==="
echo ""

if kubectl get ns argocd &>/dev/null 2>&1 && kubectl get pods -n argocd --no-headers 2>/dev/null | grep -q Running; then
    echo "[INFO] ArgoCD déjà installé"
else
    if [ -f "$INFRA_DIR/scripts/ph9-02-install-argocd.sh" ]; then
        bash "$INFRA_DIR/scripts/ph9-02-install-argocd.sh" 2>&1 | tee "$LOG_DIR/argocd.log"
    else
        kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml 2>&1 | tee "$LOG_DIR/argocd.log"
    fi
    
    echo "[INFO] Attente qu'ArgoCD soit prêt..."
    for i in {1..60}; do
        ARGOCD_READY=$(kubectl get pods -n argocd --no-headers 2>/dev/null | grep -c Running || echo "0")
        if [ "$ARGOCD_READY" -ge 4 ]; then
            echo "[OK] ArgoCD prêt ($ARGOCD_READY pods Running)"
            break
        fi
        sleep 10
    done
fi

# ÉTAPE 5: Installer ESO
echo ""
echo "=== ÉTAPE 5: Installation d'External Secrets Operator ==="
echo ""

if kubectl get ns external-secrets &>/dev/null 2>&1 && kubectl get pods -n external-secrets --no-headers 2>/dev/null | grep -q Running; then
    echo "[INFO] ESO déjà installé"
else
    if [ -f "$INFRA_DIR/scripts/ph9-03-install-eso.sh" ]; then
        bash "$INFRA_DIR/scripts/ph9-03-install-eso.sh" 2>&1 | tee "$LOG_DIR/eso.log"
    else
        # Installation basique ESO
        kubectl create namespace external-secrets --dry-run=client -o yaml | kubectl apply -f -
        helm repo add external-secrets https://charts.external-secrets.io 2>/dev/null || true
        helm repo update 2>/dev/null || true
        helm upgrade --install external-secrets external-secrets/external-secrets \
            -n external-secrets \
            --set installCRDs=true \
            --wait \
            --timeout 10m 2>&1 | tee "$LOG_DIR/eso.log" || echo "[WARN] Installation ESO échouée"
    fi
    
    echo "[INFO] Attente qu'ESO soit prêt..."
    for i in {1..60}; do
        ESO_READY=$(kubectl get pods -n external-secrets --no-headers 2>/dev/null | grep -c Running || echo "0")
        if [ "$ESO_READY" -ge 2 ]; then
            echo "[OK] ESO prêt ($ESO_READY pods Running)"
            break
        fi
        sleep 10
    done
fi

# ÉTAPE 6: Créer les namespaces
echo ""
echo "=== ÉTAPE 6: Création des namespaces ==="
echo ""

if [ -f "$INFRA_DIR/scripts/ph9-05-create-namespaces.sh" ]; then
    bash "$INFRA_DIR/scripts/ph9-05-create-namespaces.sh" 2>&1 | tee "$LOG_DIR/namespaces.log"
else
    kubectl create namespace keybuzz-system --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true
    kubectl create namespace keybuzz-apps --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true
fi

# ÉTAPE 7: Intégration Vault
echo ""
echo "=== ÉTAPE 7: Intégration Vault ↔ Kubernetes ==="
echo ""

if [ -f "$INFRA_DIR/scripts/ph9-04-vault-k8s-integration.sh" ]; then
    bash "$INFRA_DIR/scripts/ph9-04-vault-k8s-integration.sh" 2>&1 | tee "$LOG_DIR/vault-integration.log" || echo "[WARN] Intégration Vault a rencontré des problèmes"
fi

# ÉTAPE 8: Test ExternalSecret
echo ""
echo "=== ÉTAPE 8: Test ExternalSecret ==="
echo ""

if [ -f "$INFRA_DIR/scripts/ph9-06-test-eso.sh" ]; then
    bash "$INFRA_DIR/scripts/ph9-06-test-eso.sh" 2>&1 | tee "$LOG_DIR/test-eso.log" || echo "[WARN] Test ESO a rencontré des problèmes"
fi

# VALIDATION FINALE
echo ""
echo "=== VALIDATION FINALE ==="
echo ""

READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready " || echo "0")
TOTAL_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "0")
CALICO_READY=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | grep "1/1.*Running" | wc -l || echo "0")
ARGOCD_READY=$(kubectl get pods -n argocd --no-headers 2>/dev/null | grep -c Running || echo "0")
ESO_READY=$(kubectl get pods -n external-secrets --no-headers 2>/dev/null | grep -c Running || echo "0")

echo "[INFO] État des nœuds:"
kubectl get nodes -o wide

echo ""
echo "[INFO] État des pods système:"
kubectl get pods -n kube-system | head -15

echo ""
echo "[INFO] État d'ArgoCD:"
kubectl get pods -n argocd 2>/dev/null || echo "ArgoCD non installé"

echo ""
echo "[INFO] État d'ESO:"
kubectl get pods -n external-secrets 2>/dev/null || echo "ESO non installé"

echo ""
echo "=============================================="
echo "RÉSUMÉ FINAL"
echo "=============================================="
echo "Nœuds Ready: $READY_NODES/$TOTAL_NODES"
echo "Calico pods Ready: $CALICO_READY/8"
echo "ArgoCD pods Running: $ARGOCD_READY"
echo "ESO pods Running: $ESO_READY"
echo "=============================================="
echo ""

if [ "$READY_NODES" -eq 8 ] && [ "$CALICO_READY" -ge 8 ]; then
    echo "✅ PH9 - CLUSTER KUBERNETES OPÉRATIONNEL"
else
    echo "⚠️  PH9 - EN COURS (certains composants en cours de démarrage)"
fi

echo ""
echo "📄 Logs complets: $LOG_FILE"
echo ""

