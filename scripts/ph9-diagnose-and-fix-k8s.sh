#!/bin/bash
# PH9 - Diagnose and fix Kubernetes cluster issues
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9/ph9-diagnose-and-fix-k8s.log"
mkdir -p /opt/keybuzz/logs/phase9/
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "[INFO] =========================================="
echo "[INFO] PH9 - Diagnose and Fix Kubernetes Cluster"
echo "[INFO] =========================================="
echo ""

# Check if API server is accessible
echo "[INFO] Step 1: Checking API server accessibility..."
if kubectl cluster-info &>/dev/null; then
    echo "[INFO]   ✅ API server is accessible"
    API_OK=true
else
    echo "[WARN]   ⚠️  API server not accessible, checking master nodes..."
    API_OK=false
    
    # Check master nodes
    for ip in 10.0.0.100 10.0.0.101 10.0.0.102; do
        echo "[INFO]   Checking master $ip..."
        if ssh root@$ip "systemctl is-active kubelet >/dev/null 2>&1"; then
            echo "[INFO]     ✅ kubelet active"
            # Check if API server container is running
            API_CONTAINER=$(ssh root@$ip "crictl ps 2>/dev/null | grep kube-apiserver | wc -l" || echo "0")
            if [ "$API_CONTAINER" -eq 0 ]; then
                echo "[WARN]     ⚠️  kube-apiserver container not running"
                # Try to restart kubelet
                echo "[INFO]     Attempting to restart kubelet..."
                ssh root@$ip "systemctl restart kubelet" || true
                sleep 10
            else
                echo "[INFO]     ✅ kube-apiserver container running"
            fi
        else
            echo "[WARN]     ⚠️  kubelet not active, starting..."
            ssh root@$ip "systemctl start kubelet" || true
            sleep 5
        fi
    done
    
    # Wait a bit and re-check
    sleep 15
    if kubectl cluster-info &>/dev/null; then
        echo "[INFO]   ✅ API server is now accessible"
        API_OK=true
    else
        echo "[WARN]   ⚠️  API server still not accessible, may need full bootstrap"
    fi
fi

echo ""

# If API is OK, check nodes and pods
if [ "$API_OK" = true ]; then
    echo "[INFO] Step 2: Checking cluster status..."
    kubectl get nodes -o wide
    
    # Check for NotReady nodes
    NOT_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c "NotReady" || echo "0")
    if [ "$NOT_READY" -gt 0 ]; then
        echo "[WARN]   ⚠️  Found $NOT_READY NotReady nodes"
        kubectl get nodes | grep NotReady
    fi
    
    echo ""
    echo "[INFO] Step 3: Checking system pods..."
    kubectl get pods -n kube-system
    
    # Check for CrashLoopBackOff
    CRASH_LOOP=$(kubectl get pods -A --no-headers 2>/dev/null | grep -c "CrashLoopBackOff" || echo "0")
    if [ "$CRASH_LOOP" -gt 0 ]; then
        echo "[WARN]   ⚠️  Found $CRASH_LOOP pods in CrashLoopBackOff"
        kubectl get pods -A | grep CrashLoopBackOff
        
        # Try to delete and let them restart
        echo "[INFO]   Attempting to delete CrashLoopBackOff pods..."
        kubectl get pods -A | grep CrashLoopBackOff | awk '{print $1" "$2}' | while read ns pod; do
            echo "[INFO]     Deleting $ns/$pod..."
            kubectl delete pod "$pod" -n "$ns" --grace-period=0 --force 2>&1 || true
        done
        sleep 10
    fi
else
    echo "[WARN] Step 2: Skipping cluster checks (API server not accessible)"
    echo "[INFO]   Attempting to bootstrap cluster..."
    if [ -f scripts/ph9-01-bootstrap-k8s.sh ]; then
        bash scripts/ph9-01-bootstrap-k8s.sh || echo "[WARN] Bootstrap may need manual intervention"
    fi
fi

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ PH9 Diagnose and Fix Complete"
echo "[INFO] =========================================="
echo ""

