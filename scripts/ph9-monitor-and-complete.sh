#!/bin/bash
# PH9 - Surveillance et complétion automatique jusqu'à 100% OK
set -e

LOG_DIR="/opt/keybuzz/logs/phase9-monitor"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/ph9-monitor-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

INFRA_DIR="/opt/keybuzz/keybuzz-infra"
ANSIBLE_DIR="$INFRA_DIR/ansible"
cd "$INFRA_DIR"

export KUBECONFIG=/root/.kube/config 2>/dev/null || true

echo "=============================================="
echo "PH9 - SURVEILLANCE ET COMPLÉTION AUTOMATIQUE"
echo "Date: $(date)"
echo "=============================================="
echo ""

# Fonction pour vérifier l'état du cluster
check_cluster_state() {
    if ! kubectl get nodes &>/dev/null 2>&1; then
        echo "NO_CLUSTER"
        return
    fi
    
    READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c Ready || echo "0")
    TOTAL_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "0")
    
    echo "$READY_NODES/$TOTAL_NODES"
}

# Fonction pour attendre que le playbook termine
wait_for_bootstrap() {
    echo "[INFO] Attente que le bootstrap se termine..."
    
    for i in {1..60}; do
        # Vérifier si le processus ansible-playbook est toujours en cours
        if ! pgrep -f "ansible-playbook.*k8s_cluster_v3.yml" &>/dev/null; then
            echo "[INFO] Playbook terminé, vérification de l'état..."
            break
        fi
        echo "[INFO] Bootstrap en cours... (attente $i/60)"
        sleep 30
    done
}

# Étape 1: Attendre que le bootstrap se termine
wait_for_bootstrap

# Étape 2: Vérifier l'état du cluster
echo ""
echo "=== Vérification de l'état du cluster ==="
echo ""

CLUSTER_STATE=$(check_cluster_state)

if [ "$CLUSTER_STATE" = "NO_CLUSTER" ]; then
    echo "[ERROR] Le cluster n'est pas initialisé"
    echo "[INFO] Relance du bootstrap..."
    
    ANSIBLE_HOST_KEY_CHECKING=False \
    ansible-playbook \
        -i "$ANSIBLE_DIR/inventory/hosts.yml" \
        "$ANSIBLE_DIR/playbooks/k8s_cluster_v3.yml" \
        2>&1 | tee "$LOG_DIR/bootstrap-retry.log"
    
    sleep 30
    CLUSTER_STATE=$(check_cluster_state)
fi

if [ "$CLUSTER_STATE" != "NO_CLUSTER" ]; then
    READY_NODES=$(echo "$CLUSTER_STATE" | cut -d'/' -f1)
    TOTAL_NODES=$(echo "$CLUSTER_STATE" | cut -d'/' -f2)
    
    echo "[INFO] État du cluster: $READY_NODES/$TOTAL_NODES nœuds Ready"
    kubectl get nodes -o wide
    
    if [ "$READY_NODES" -lt 8 ]; then
        echo "[INFO] Attente que tous les nœuds rejoignent le cluster..."
        for i in {1..60}; do
            CLUSTER_STATE=$(check_cluster_state)
            READY_NODES=$(echo "$CLUSTER_STATE" | cut -d'/' -f1)
            TOTAL_NODES=$(echo "$CLUSTER_STATE" | cut -d'/' -f2)
            
            echo "[INFO] Nœuds Ready: $READY_NODES/$TOTAL_NODES (attente $i/60)"
            
            if [ "$READY_NODES" -ge 8 ] && [ "$TOTAL_NODES" -eq 8 ]; then
                echo "[OK] Tous les nœuds sont Ready"
                break
            fi
            sleep 10
        done
    fi
fi

export KUBECONFIG=/root/.kube/config

# Étape 3: Installer Calico si nécessaire
echo ""
echo "=== Installation de Calico ==="
echo ""

CALICO_READY=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | grep -c Running || echo "0")

if [ "$CALICO_READY" -lt 8 ]; then
    echo "[INFO] Installation de Calico..."
    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml 2>&1 | tee "$LOG_DIR/calico.log"
    
    echo "[INFO] Attente que Calico soit prêt..."
    for i in {1..60}; do
        CALICO_READY=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | grep -c Running || echo "0")
        echo "[INFO] Calico pods Running: $CALICO_READY/8 (attente $i/60)"
        
        if [ "$CALICO_READY" -ge 8 ]; then
            echo "[OK] Calico prêt"
            break
        fi
        sleep 10
    done
else
    echo "[INFO] Calico déjà installé ($CALICO_READY pods Running)"
fi

# Étape 4: Vérification finale
echo ""
echo "=== VÉRIFICATION FINALE ==="
echo ""

export KUBECONFIG=/root/.kube/config

echo "[INFO] État des nœuds:"
kubectl get nodes -o wide

echo ""
echo "[INFO] État des pods système:"
kubectl get pods -n kube-system

CLUSTER_STATE=$(check_cluster_state)
READY_NODES=$(echo "$CLUSTER_STATE" | cut -d'/' -f1)
TOTAL_NODES=$(echo "$CLUSTER_STATE" | cut -d'/' -f2)

echo ""
echo "=============================================="
if [ "$READY_NODES" -eq 8 ] && [ "$TOTAL_NODES" -eq 8 ]; then
    echo "✅ PH9 - CLUSTER KUBERNETES 100% OK"
    echo "✅ 8/8 nœuds Ready"
    echo "✅ Calico installé et opérationnel"
else
    echo "⚠️  PH9 - CLUSTER PARTIELLEMENT OPÉRATIONNEL"
    echo "⚠️  $READY_NODES/$TOTAL_NODES nœuds Ready"
fi
echo "=============================================="
echo ""
echo "📄 Logs complets: $LOG_FILE"
echo ""

