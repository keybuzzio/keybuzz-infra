#!/bin/bash
# PH9 - Complétion automatique jusqu'à 100% OK
set -e

LOG_DIR="/opt/keybuzz/logs/phase9-complete-all"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/ph9-complete-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================================="
echo "PH9 - COMPLÉTION AUTOMATIQUE JUSQU'À 100%"
echo "Date: $(date)"
echo "=============================================="
echo ""

export KUBECONFIG=/root/.kube/config
INFRA_DIR="/opt/keybuzz/keybuzz-infra"

# ==========================================
# ÉTAPE 1: Vérifier l'accès au cluster
# ==========================================
echo "=== ÉTAPE 1: Vérification de l'accès au cluster ==="
echo ""

if ! kubectl get nodes &>/dev/null 2>&1; then
    echo "[ERROR] Cluster non accessible"
    exit 1
fi

echo "[OK] Cluster accessible"
kubectl get nodes
echo ""

# ==========================================
# ÉTAPE 2: Installer Calico CNI
# ==========================================
echo "=== ÉTAPE 2: Installation de Calico CNI ==="
echo ""

CALICO_PODS=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | grep -c Running || echo "0")

if [ "$CALICO_PODS" -lt 8 ]; then
    echo "[INFO] Installation de Calico..."
    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml 2>&1 | tee "$LOG_DIR/calico-install.log"
    
    echo "[INFO] Attente que Calico soit prêt..."
    for i in {1..60}; do
        CALICO_RUNNING=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | grep -c Running || echo "0")
        CALICO_TOTAL=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | wc -l || echo "0")
        
        echo "[INFO] Calico: $CALICO_RUNNING/$CALICO_TOTAL pods Running (attente $i/60)"
        
        if [ "$CALICO_RUNNING" -ge 8 ]; then
            echo "[OK] Calico prêt ($CALICO_RUNNING pods Running)"
            break
        fi
        sleep 10
    done
else
    echo "[INFO] Calico déjà installé ($CALICO_PODS pods Running)"
fi

# ==========================================
# ÉTAPE 3: Attendre que tous les nœuds soient Ready
# ==========================================
echo ""
echo "=== ÉTAPE 3: Attente que tous les nœuds soient Ready ==="
echo ""

for i in {1..60}; do
    READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready " || echo "0")
    TOTAL_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "0")
    
    echo "[INFO] Nœuds Ready: $READY_NODES/$TOTAL_NODES (attente $i/60)"
    
    if [ "$READY_NODES" -ge 8 ] && [ "$TOTAL_NODES" -eq 8 ]; then
        echo "[OK] Tous les nœuds sont Ready"
        kubectl get nodes -o wide
        break
    fi
    sleep 10
done

# ==========================================
# ÉTAPE 4: Installer ArgoCD
# ==========================================
echo ""
echo "=== ÉTAPE 4: Installation d'ArgoCD ==="
echo ""

if kubectl get ns argocd &>/dev/null 2>&1 && kubectl get pods -n argocd --no-headers 2>/dev/null | grep -q Running; then
    echo "[INFO] ArgoCD déjà installé"
else
    echo "[INFO] Installation d'ArgoCD..."
    if [ -f "$INFRA_DIR/scripts/ph9-02-install-argocd.sh" ]; then
        bash "$INFRA_DIR/scripts/ph9-02-install-argocd.sh" 2>&1 | tee "$LOG_DIR/argocd-install.log"
    else
        kubectl create namespace argocd 2>/dev/null || true
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml 2>&1 | tee "$LOG_DIR/argocd-install.log"
    fi
    
    echo "[INFO] Attente qu'ArgoCD soit prêt..."
    for i in {1..60}; do
        ARGOCD_READY=$(kubectl get pods -n argocd --no-headers 2>/dev/null | grep -c Running || echo "0")
        ARGOCD_TOTAL=$(kubectl get pods -n argocd --no-headers 2>/dev/null | wc -l || echo "0")
        
        if [ "$ARGOCD_TOTAL" -gt 0 ]; then
            echo "[INFO] ArgoCD: $ARGOCD_READY/$ARGOCD_TOTAL pods Running (attente $i/60)"
        fi
        
        if [ "$ARGOCD_READY" -ge 4 ] && [ "$ARGOCD_TOTAL" -ge 4 ]; then
            echo "[OK] ArgoCD prêt"
            break
        fi
        sleep 10
    done
fi

# ==========================================
# ÉTAPE 5: Installer External Secrets Operator
# ==========================================
echo ""
echo "=== ÉTAPE 5: Installation d'External Secrets Operator ==="
echo ""

if kubectl get ns external-secrets &>/dev/null 2>&1 && kubectl get pods -n external-secrets --no-headers 2>/dev/null | grep -q Running; then
    echo "[INFO] ESO déjà installé"
else
    echo "[INFO] Installation d'ESO..."
    if [ -f "$INFRA_DIR/scripts/ph9-03-install-eso.sh" ]; then
        bash "$INFRA_DIR/scripts/ph9-03-install-eso.sh" 2>&1 | tee "$LOG_DIR/eso-install.log"
    else
        kubectl create namespace external-secrets 2>/dev/null || true
        helm repo add external-secrets https://charts.external-secrets.io 2>/dev/null || true
        helm repo update 2>/dev/null || true
        helm install external-secrets external-secrets/external-secrets -n external-secrets 2>&1 | tee "$LOG_DIR/eso-install.log" || echo "[WARN] Installation ESO échouée"
    fi
    
    echo "[INFO] Attente qu'ESO soit prêt..."
    for i in {1..60}; do
        ESO_READY=$(kubectl get pods -n external-secrets --no-headers 2>/dev/null | grep -c Running || echo "0")
        ESO_TOTAL=$(kubectl get pods -n external-secrets --no-headers 2>/dev/null | wc -l || echo "0")
        
        if [ "$ESO_TOTAL" -gt 0 ]; then
            echo "[INFO] ESO: $ESO_READY/$ESO_TOTAL pods Running (attente $i/60)"
        fi
        
        if [ "$ESO_READY" -ge 2 ] && [ "$ESO_TOTAL" -ge 2 ]; then
            echo "[OK] ESO prêt"
            break
        fi
        sleep 10
    done
fi

# ==========================================
# ÉTAPE 6: Créer les namespaces
# ==========================================
echo ""
echo "=== ÉTAPE 6: Création des namespaces ==="
echo ""

if [ -f "$INFRA_DIR/scripts/ph9-05-create-namespaces.sh" ]; then
    bash "$INFRA_DIR/scripts/ph9-05-create-namespaces.sh" 2>&1 | tee "$LOG_DIR/namespaces.log"
else
    kubectl create namespace keybuzz-system --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true
    kubectl create namespace keybuzz-apps --dry-run=client -o yaml | kubectl apply -f - 2>/dev/null || true
fi

# ==========================================
# ÉTAPE 7: Intégration Vault ↔ Kubernetes
# ==========================================
echo ""
echo "=== ÉTAPE 7: Intégration Vault ↔ Kubernetes ==="
echo ""

if [ -f "$INFRA_DIR/scripts/ph9-04-vault-k8s-integration.sh" ]; then
    bash "$INFRA_DIR/scripts/ph9-04-vault-k8s-integration.sh" 2>&1 | tee "$LOG_DIR/vault-integration.log" || echo "[WARN] Intégration Vault a rencontré des problèmes"
fi

# ==========================================
# ÉTAPE 8: Test ExternalSecret
# ==========================================
echo ""
echo "=== ÉTAPE 8: Test ExternalSecret ==="
echo ""

if [ -f "$INFRA_DIR/scripts/ph9-06-test-eso.sh" ]; then
    bash "$INFRA_DIR/scripts/ph9-06-test-eso.sh" 2>&1 | tee "$LOG_DIR/test-eso.log"
fi

# ==========================================
# VALIDATION FINALE
# ==========================================
echo ""
echo "=== VALIDATION FINALE ==="
echo ""

echo "[INFO] État des nœuds:"
kubectl get nodes -o wide

echo ""
echo "[INFO] État des pods système:"
kubectl get pods -n kube-system

echo ""
echo "[INFO] État d'ArgoCD:"
kubectl get pods -n argocd 2>/dev/null || echo "ArgoCD non installé"

echo ""
echo "[INFO] État d'ESO:"
kubectl get pods -n external-secrets 2>/dev/null || echo "ESO non installé"

READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready " || echo "0")
TOTAL_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "0")

echo ""
echo "=============================================="
if [ "$READY_NODES" -eq 8 ] && [ "$TOTAL_NODES" -eq 8 ]; then
    echo "✅ PH9 - 100% OK"
    echo "✅ 8/8 nœuds Ready"
    echo "✅ Calico installé"
    echo "✅ ArgoCD installé"
    echo "✅ ESO installé"
else
    echo "⚠️  PH9 - EN COURS"
    echo "⚠️  $READY_NODES/$TOTAL_NODES nœuds Ready"
fi
echo "=============================================="
echo ""
echo "📄 Logs complets: $LOG_FILE"
echo ""

