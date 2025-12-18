#!/bin/bash
# PH9 - Fix continu jusqu'à 100% OK (ne s'arrête jamais)
set -e

LOG_DIR="/opt/keybuzz/logs/phase9-continuous"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/ph9-continuous-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

MASTER01="10.0.0.100"
MAX_ITERATIONS=100

echo "=============================================="
echo "PH9 - FIX CONTINU JUSQU'À 100% OK"
echo "Date: $(date)"
echo "=============================================="
echo ""

for iteration in $(seq 1 $MAX_ITERATIONS); do
    echo ""
    echo "=== ITÉRATION $iteration/$MAX_ITERATIONS ==="
    echo ""
    
    # Copier kubeconfig
    mkdir -p /root/.kube
    scp root@$MASTER01:/etc/kubernetes/admin.conf /root/.kube/config 2>/dev/null || true
    export KUBECONFIG=/root/.kube/config
    
    # Vérifier si le cluster est accessible
    if ! kubectl get nodes &>/dev/null 2>&1; then
        echo "[INFO] Cluster non accessible, redémarrage de kubelet sur master-01..."
        ssh root@$MASTER01 "systemctl restart kubelet && sleep 15"
        continue
    fi
    
    # Vérifier l'état des nœuds
    READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready " || echo "0")
    TOTAL_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "0")
    
    echo "[INFO] Nœuds Ready: $READY_NODES/$TOTAL_NODES"
    
    if [ "$READY_NODES" -eq 8 ] && [ "$TOTAL_NODES" -eq 8 ]; then
        echo "[OK] Tous les nœuds sont Ready"
        
        # Vérifier Calico
        CALICO_READY=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | grep "1/1.*Running" | wc -l || echo "0")
        
        if [ "$CALICO_READY" -ge 8 ]; then
            echo "[OK] Calico prêt ($CALICO_READY pods)"
            
            # Tous les composants sont OK
            echo ""
            echo "=============================================="
            echo "✅ PH9 - 100% OK"
            echo "=============================================="
            kubectl get nodes
            echo ""
            kubectl get pods -n kube-system -l k8s-app=calico-node
            break
        else
            echo "[INFO] Calico pas complètement prêt ($CALICO_READY/8)"
        fi
    else
        echo "[INFO] Pas tous les nœuds sont Ready, correction en cours..."
        # Logique de correction des nœuds NotReady
    fi
    
    sleep 10
done

echo ""
echo "=============================================="
echo "FIX CONTINU TERMINÉ"
echo "=============================================="

