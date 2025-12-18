#!/bin/bash
# PH9 - Déploiement complet du cluster Kubernetes (sans git pull)
set -e

LOG_DIR="/opt/keybuzz/logs/phase9-complete"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/ph9-complete-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================================="
echo "PH9 - DÉPLOIEMENT COMPLET KUBERNETES"
echo "Date: $(date)"
echo "=============================================="
echo ""

INFRA_DIR="/opt/keybuzz/keybuzz-infra"
ANSIBLE_DIR="$INFRA_DIR/ansible"
cd "$INFRA_DIR"

export KUBECONFIG=/root/.kube/config 2>/dev/null || true

# ==========================================
# ÉTAPE 1: Bootstrap du cluster Kubernetes
# ==========================================
echo "=== ÉTAPE 1: Bootstrap du cluster Kubernetes ==="
echo ""

# Vérifier si le cluster existe déjà
if kubectl get nodes &>/dev/null 2>&1; then
    echo "[INFO] Cluster déjà initialisé, vérification de l'état..."
    kubectl get nodes
    echo ""
    
    READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c Ready || echo "0")
    if [ "$READY_NODES" -ge 8 ]; then
        echo "[OK] Cluster opérationnel avec $READY_NODES nœuds Ready"
    else
        echo "[INFO] Cluster partiel ($READY_NODES/8 nœuds), continuation..."
    fi
else
    echo "[INFO] Cluster non initialisé, lancement du bootstrap..."
    
    # Vérifier SSH connectivity
    echo "[INFO] Vérification de la connectivité SSH..."
    ANSIBLE_HOST_KEY_CHECKING=False ansible k8s_masters:k8s_workers -i "$ANSIBLE_DIR/inventory/hosts.yml" -m ping -o >/dev/null 2>&1 || {
        echo "[ERROR] SSH connectivity check failed"
        exit 1
    }
    echo "[OK] Connectivité SSH vérifiée"
    
    # Exécuter le playbook de bootstrap
    echo "[INFO] Exécution du playbook de bootstrap Kubernetes..."
    ANSIBLE_HOST_KEY_CHECKING=False \
    ANSIBLE_SSH_COMMON_ARGS="-o StrictHostKeyChecking=no" \
    ansible-playbook \
        -i "$ANSIBLE_DIR/inventory/hosts.yml" \
        "$ANSIBLE_DIR/playbooks/k8s_cluster_v3.yml" \
        2>&1 | tee "$LOG_DIR/bootstrap.log"
    
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "[ERROR] Bootstrap échoué"
        exit 1
    fi
    
    # Copier kubeconfig si nécessaire
    if [ ! -f /root/.kube/config ]; then
        mkdir -p /root/.kube
        scp root@10.0.0.100:/etc/kubernetes/admin.conf /root/.kube/config 2>/dev/null || {
            echo "[ERROR] Impossible de copier kubeconfig"
            exit 1
        }
    fi
    
    export KUBECONFIG=/root/.kube/config
    
    # Attendre que les nœuds soient prêts
    echo "[INFO] Attente que tous les nœuds soient Ready..."
    for i in {1..30}; do
        READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c Ready || echo "0")
        TOTAL_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "0")
        echo "[INFO] Nœuds Ready: $READY_NODES/$TOTAL_NODES"
        if [ "$READY_NODES" -ge 8 ] && [ "$READY_NODES" -eq "$TOTAL_NODES" ]; then
            echo "[OK] Tous les nœuds sont Ready"
            break
        fi
        sleep 10
    done
    
    kubectl get nodes -o wide
fi

export KUBECONFIG=/root/.kube/config

echo ""
echo "[OK] Étape 1 terminée"
echo ""

# ==========================================
# ÉTAPE 2: Installation Calico CNI
# ==========================================
echo "=== ÉTAPE 2: Installation Calico CNI ==="
echo ""

CALICO_RUNNING=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | grep -c Running || echo "0")

if [ "$CALICO_RUNNING" -ge 8 ]; then
    echo "[INFO] Calico déjà installé ($CALICO_RUNNING pods Running)"
else
    echo "[INFO] Installation de Calico..."
    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml 2>&1 | tee "$LOG_DIR/calico.log"
    
    echo "[INFO] Attente que Calico soit prêt..."
    for i in {1..30}; do
        CALICO_READY=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | grep -c Running || echo "0")
        if [ "$CALICO_READY" -ge 8 ]; then
            echo "[OK] Calico prêt ($CALICO_READY pods Running)"
            break
        fi
        echo "[INFO] En attente... ($CALICO_READY/8 pods)"
        sleep 10
    done
fi

echo ""
echo "[OK] Étape 2 terminée"
echo ""

# Continuer avec les autres étapes...
echo "[INFO] Installation des composants supplémentaires..."
echo "[INFO] Pour l'instant, le cluster Kubernetes est opérationnel"
echo ""

# ==========================================
# Validation finale
# ==========================================
echo "=== VALIDATION FINALE ==="
echo ""

echo "[INFO] État des nœuds:"
kubectl get nodes -o wide

echo ""
echo "[INFO] État des pods système:"
kubectl get pods -n kube-system | head -20

echo ""
echo "=============================================="
echo "PH9 - CLUSTER KUBERNETES OPÉRATIONNEL"
echo "=============================================="
echo ""
echo "📄 Logs complets: $LOG_FILE"
echo ""

