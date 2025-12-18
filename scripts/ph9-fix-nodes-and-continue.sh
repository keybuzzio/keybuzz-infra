#!/bin/bash
# PH9 - Fix des nœuds NotReady et continuation jusqu'à 100%
set -e

LOG_DIR="/opt/keybuzz/logs/phase9-fix-nodes"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/ph9-fix-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "=============================================="
echo "PH9 - FIX NŒUDS ET CONTINUATION"
echo "Date: $(date)"
echo "=============================================="
echo ""

# Fonction pour redémarrer kubelet sur un nœud
restart_kubelet() {
    local node_ip=$1
    echo "[INFO] Redémarrage de kubelet sur $node_ip..."
    ssh root@$node_ip "systemctl restart kubelet && sleep 5 && systemctl is-active kubelet"
}

# Redémarrer kubelet sur les nœuds NotReady
echo "=== Fix des nœuds NotReady ==="
echo ""

NOTREADY_NODES=$(kubectl get nodes --no-headers | grep NotReady | awk '{print $1}')

for node in $NOTREADY_NODES; do
    echo "[INFO] Traitement de $node..."
    
    # Obtenir l'IP interne
    node_ip=$(kubectl get node $node -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "")
    
    if [ -z "$node_ip" ]; then
        # Essayer de trouver l'IP depuis l'inventory
        case "$node" in
            k8s-master-03) node_ip="10.0.0.102" ;;
            k8s-worker-02) node_ip="10.0.0.111" ;;
            k8s-worker-03) node_ip="10.0.0.112" ;;
        esac
    fi
    
    if [ -n "$node_ip" ]; then
        echo "[INFO] Redémarrage de kubelet sur $node ($node_ip)..."
        restart_kubelet "$node_ip"
        sleep 5
    fi
done

# Attendre que les nœuds redeviennent Ready
echo ""
echo "[INFO] Attente que les nœuds redeviennent Ready..."
for i in {1..60}; do
    READY_NODES=$(kubectl get nodes --no-headers | grep -c " Ready " || echo "0")
    TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l || echo "0")
    
    echo "[INFO] Nœuds Ready: $READY_NODES/$TOTAL_NODES (attente $i/60)"
    
    if [ "$READY_NODES" -ge 8 ]; then
        echo "[OK] Tous les nœuds sont Ready"
        break
    fi
    sleep 10
done

# Redémarrer les pods Calico en erreur
echo ""
echo "=== Fix des pods Calico ==="
echo ""

kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers | grep -v Running | awk '{print $1}' | while read pod; do
    echo "[INFO] Redémarrage du pod Calico: $pod"
    kubectl delete pod -n kube-system "$pod" --force --grace-period=0 2>/dev/null || true
done

sleep 30

# Vérification finale
echo ""
echo "=== ÉTAT FINAL ==="
echo ""

kubectl get nodes -o wide

echo ""
kubectl get pods -n kube-system -l k8s-app=calico-node

READY_NODES=$(kubectl get nodes --no-headers | grep -c " Ready " || echo "0")
TOTAL_NODES=$(kubectl get nodes --no-headers | wc -l || echo "0")

echo ""
echo "=============================================="
if [ "$READY_NODES" -eq 8 ]; then
    echo "✅ TOUS LES NŒUDS SONT READY"
else
    echo "⚠️  $READY_NODES/$TOTAL_NODES nœuds Ready"
fi
echo "=============================================="

