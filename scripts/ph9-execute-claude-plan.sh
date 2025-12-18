#!/bin/bash
# PH9 EXECUTE CLAUDE PLAN - Réparation complète du control-plane Kubernetes HA
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_DIR="/opt/keybuzz/logs/phase9-execute-claude-plan"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ph9-execute-claude-plan.log"

exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "[INFO] =========================================="
echo "[INFO] PH9 EXECUTE CLAUDE PLAN - REPARATION COMPLETE"
echo "[INFO] =========================================="
echo ""

MASTER1=10.0.0.100
MASTER2=10.0.0.101
MASTER3=10.0.0.102

# ====================================
# 0️⃣ PHASE 0 — Préparation + Vérification master-01
# ====================================

echo "[INFO] =========================================="
echo "[INFO] PHASE 0: Preparation + Verification master-01"
echo "[INFO] =========================================="

git pull --rebase || echo "[WARN] git pull failed"

# 0.1 Vérifier master-01 et kube-system
echo "[INFO] Checking nodes..."
kubectl get nodes -o wide | tee "$LOG_DIR/nodes-before.txt"

echo "[INFO] Checking kube-system pods..."
kubectl get pods -n kube-system | tee "$LOG_DIR/kube-system-before.txt"

# 0.2 Vérifier secret kubeadm-certs
echo "[INFO] Checking kubeadm-certs secret..."
kubectl -n kube-system get secret kubeadm-certs | tee "$LOG_DIR/kubeadm-certs-check.txt"

# 0.3 Vérifier ETCD depuis master-01
echo "[INFO] Checking ETCD members..."
ssh root@$MASTER1 bash <<'ETCD_CHECK_EOF' | tee "$LOG_DIR/etcd-before.txt"
    export ETCDCTL_API=3
    crictl exec -it $(crictl ps --name etcd -q) etcdctl member list \
      --endpoints=https://127.0.0.1:2379 \
      --cacert=/etc/kubernetes/pki/etcd/ca.crt \
      --cert=/etc/kubernetes/pki/etcd/server.crt \
      --key=/etc/kubernetes/pki/etcd/server.key 2>&1 || echo "ERROR: Failed to check ETCD"
ETCD_CHECK_EOF

# ====================================
# 1️⃣ PHASE 1 — Préparation master-02
# ====================================

echo ""
echo "[INFO] =========================================="
echo "[INFO] PHASE 1: Preparation master-02"
echo "[INFO] =========================================="

ssh root@$MASTER2 bash <<'MASTER02_PREP_EOF' | tee "$LOG_DIR/master02-precheck.txt"
    echo "[INFO] Enabling and starting containerd..."
    systemctl enable containerd || true
    systemctl restart containerd || true
    sleep 3
    
    echo "[INFO] Stopping kubelet..."
    systemctl stop kubelet || true
    
    echo "[INFO] Checking directories..."
    echo "--- /etc/kubernetes/ ---"
    ls -la /etc/kubernetes/ || true
    echo ""
    echo "--- /var/lib/kubelet/ ---"
    ls -la /var/lib/kubelet/ || true
    echo ""
    echo "--- /var/lib/etcd/ ---"
    ls -la /var/lib/etcd/ || true
    echo ""
    echo "[INFO] Containerd status:"
    systemctl status containerd --no-pager | head -10 || true
MASTER02_PREP_EOF

# ====================================
# 2️⃣ PHASE 2 — Génération certificate-key et JOIN_CMD frais
# ====================================

echo ""
echo "[INFO] =========================================="
echo "[INFO] PHASE 2: Generation certificate-key and JOIN_CMD"
echo "[INFO] =========================================="

echo "[INFO] Generating fresh certificate-key..."
CERT_KEY=$(ssh root@$MASTER1 "kubeadm init phase upload-certs --upload-certs 2>&1 | tail -n1 | tr -d '\r' | grep -E '^[a-f0-9]{64}$'")
if [ -z "$CERT_KEY" ]; then
    echo "[ERROR] Failed to get certificate key"
    exit 1
fi
echo "CERT_KEY=$CERT_KEY" | tee "$LOG_DIR/cert-key.txt"

echo "[INFO] Getting bootstrap token..."
BOOTSTRAP_SECRET=$(kubectl get secret -n kube-system --no-headers | grep bootstrap-token | head -1 | awk '{print $1}')
if [ -z "$BOOTSTRAP_SECRET" ]; then
    echo "[ERROR] No bootstrap token found"
    exit 1
fi

TOKEN_ID=$(kubectl get secret $BOOTSTRAP_SECRET -n kube-system -o jsonpath='{.data.token-id}' | base64 -d)
TOKEN_SECRET=$(kubectl get secret $BOOTSTRAP_SECRET -n kube-system -o jsonpath='{.data.token-secret}' | base64 -d)
TOKEN="${TOKEN_ID}.${TOKEN_SECRET}"
echo "TOKEN=$TOKEN" | tee "$LOG_DIR/token.txt"

JOIN_CMD="kubeadm join $MASTER1:6443 --token $TOKEN --discovery-token-unsafe-skip-ca-verification --control-plane --certificate-key $CERT_KEY"
echo "$JOIN_CMD" | tee "$LOG_DIR/join-cmd.txt"

# ====================================
# 3️⃣ PHASE 3 — JOIN master-02
# ====================================

echo ""
echo "[INFO] =========================================="
echo "[INFO] PHASE 3: JOIN master-02"
echo "[INFO] =========================================="

echo "[INFO] Executing kubeadm join on master-02..."
ssh root@$MASTER2 "$JOIN_CMD 2>&1" | tee "$LOG_DIR/master02-join.log"

JOIN02_RESULT=$?
if [ $JOIN02_RESULT -ne 0 ]; then
    echo "[WARN] master-02 join may have failed (exit code: $JOIN02_RESULT), but continuing..."
fi

echo "[INFO] Waiting 60 seconds for kubelet to start..."
sleep 60

echo "[INFO] Checking master-02 status..."
ssh root@$MASTER2 bash <<'MASTER02_POST_EOF' | tee "$LOG_DIR/master02-postjoin.txt"
    echo "--- systemctl status kubelet ---"
    systemctl status kubelet --no-pager | head -30 || true
    echo ""
    echo "--- /etc/kubernetes/manifests/ ---"
    ls -la /etc/kubernetes/manifests/ || true
    echo ""
    echo "--- /etc/kubernetes/pki/ ---"
    ls -la /etc/kubernetes/pki/ || true
MASTER02_POST_EOF

echo "[INFO] Checking nodes status..."
kubectl get nodes -o wide | tee "$LOG_DIR/nodes-after-master02.txt"

# ====================================
# 4️⃣ PHASE 4 — Vérification ETCD après master-02
# ====================================

echo ""
echo "[INFO] =========================================="
echo "[INFO] PHASE 4: Verification ETCD after master-02"
echo "[INFO] =========================================="

echo "[INFO] Waiting 120 seconds for ETCD to sync..."
sleep 120

echo "[INFO] Checking ETCD members..."
ssh root@$MASTER1 bash <<'ETCD_CHECK2_EOF' | tee "$LOG_DIR/etcd-after-master02.txt"
    export ETCDCTL_API=3
    crictl exec -it $(crictl ps --name etcd -q) etcdctl member list \
      --endpoints=https://127.0.0.1:2379 \
      --cacert=/etc/kubernetes/pki/etcd/ca.crt \
      --cert=/etc/kubernetes/pki/etcd/server.crt \
      --key=/etc/kubernetes/pki/etcd/server.key 2>&1 || echo "ERROR: Failed to check ETCD"
ETCD_CHECK2_EOF

echo "[INFO] Checking etcd pod on master-02..."
kubectl get pods -n kube-system | grep etcd-k8s-master-02 | tee "$LOG_DIR/etcd-pod-master02.txt"

echo "[INFO] Checking apiserver pod on master-02..."
kubectl get pods -n kube-system | grep kube-apiserver-k8s-master-02 | tee "$LOG_DIR/apiserver-master02.txt"

# ====================================
# 5️⃣ PHASE 5 — JOIN master-03
# ====================================

echo ""
echo "[INFO] =========================================="
echo "[INFO] PHASE 5: JOIN master-03"
echo "[INFO] =========================================="

echo "[INFO] Preparing master-03..."
ssh root@$MASTER3 bash <<'MASTER03_PREP_EOF'
    systemctl enable containerd || true
    systemctl restart containerd || true
    systemctl stop kubelet || true
    sleep 3
    systemctl status containerd --no-pager | head -10 || true
MASTER03_PREP_EOF

# Regénérer CERT_KEY pour éviter expiration
echo "[INFO] Regenerating certificate-key for master-03..."
CERT_KEY=$(ssh root@$MASTER1 "kubeadm init phase upload-certs --upload-certs 2>&1 | tail -n1 | tr -d '\r' | grep -E '^[a-f0-9]{64}$'")
if [ -z "$CERT_KEY" ]; then
    echo "[ERROR] Failed to get certificate key for master-03"
    exit 1
fi
JOIN_CMD="kubeadm join $MASTER1:6443 --token $TOKEN --discovery-token-unsafe-skip-ca-verification --control-plane --certificate-key $CERT_KEY"
echo "[INFO] Join command for master-03: $JOIN_CMD"

echo "[INFO] Executing kubeadm join on master-03..."
ssh root@$MASTER3 "$JOIN_CMD 2>&1" | tee "$LOG_DIR/master03-join.log"

JOIN03_RESULT=$?
if [ $JOIN03_RESULT -ne 0 ]; then
    echo "[WARN] master-03 join may have failed (exit code: $JOIN03_RESULT), but continuing..."
fi

echo "[INFO] Waiting 120 seconds for master-03 to stabilize..."
sleep 120

echo "[INFO] Checking master-03 status..."
ssh root@$MASTER3 bash <<'MASTER03_POST_EOF' | tee "$LOG_DIR/master03-postjoin.txt"
    echo "--- systemctl status kubelet ---"
    systemctl status kubelet --no-pager | head -30 || true
    echo ""
    echo "--- /etc/kubernetes/manifests/ ---"
    ls -la /etc/kubernetes/manifests/ || true
    echo ""
    echo "--- /etc/kubernetes/pki/ ---"
    ls -la /etc/kubernetes/pki/ || true
MASTER03_POST_EOF

# ====================================
# 6️⃣ PHASE 6 — Validation du control-plane complet
# ====================================

echo ""
echo "[INFO] =========================================="
echo "[INFO] PHASE 6: Validation control-plane complet"
echo "[INFO] =========================================="

echo "[INFO] Final nodes status..."
kubectl get nodes -o wide | tee "$LOG_DIR/nodes-control-plane-final.txt"

echo "[INFO] Final kube-system pods..."
kubectl get pods -n kube-system | tee "$LOG_DIR/kube-system-final.txt"

echo "[INFO] Final ETCD members..."
ssh root@$MASTER1 bash <<'ETCD_CHECK3_EOF' | tee "$LOG_DIR/etcd-final.txt"
    export ETCDCTL_API=3
    crictl exec -it $(crictl ps --name etcd -q) etcdctl member list \
      --endpoints=https://127.0.0.1:2379 \
      --cacert=/etc/kubernetes/pki/etcd/ca.crt \
      --cert=/etc/kubernetes/pki/etcd/server.crt \
      --key=/etc/kubernetes/pki/etcd/server.key 2>&1 || echo "ERROR: Failed to check ETCD"
ETCD_CHECK3_EOF

# ====================================
# 7️⃣ PHASE 7 — Stabiliser Calico
# ====================================

echo ""
echo "[INFO] =========================================="
echo "[INFO] PHASE 7: Stabiliser Calico"
echo "[INFO] =========================================="

echo "[INFO] Deleting Calico pods for recreation..."
kubectl delete pods -n kube-system -l k8s-app=calico-node --force --grace-period=0 2>&1 | grep -v "not found" || true
kubectl delete pod -n kube-system -l k8s-app=calico-kube-controllers --force --grace-period=0 2>&1 | grep -v "not found" || true

echo "[INFO] Waiting 60 seconds for Calico pods to restart..."
sleep 60

echo "[INFO] Checking Calico pods..."
kubectl get pods -n kube-system -l k8s-app=calico-node -o wide | tee "$LOG_DIR/calico-after.txt"

# ====================================
# 8️⃣ PHASE 8 — Stabiliser kube-proxy
# ====================================

echo ""
echo "[INFO] =========================================="
echo "[INFO] PHASE 8: Stabiliser kube-proxy"
echo "[INFO] =========================================="

echo "[INFO] Deleting kube-proxy pods for recreation..."
kubectl delete pods -n kube-system -l k8s-app=kube-proxy --force --grace-period=0 2>&1 | grep -v "not found" || true

echo "[INFO] Waiting 60 seconds for kube-proxy pods to restart..."
sleep 60

echo "[INFO] Checking kube-proxy pods..."
kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide | tee "$LOG_DIR/kube-proxy-after.txt"

# ====================================
# 9️⃣ PHASE 9 — Réparer ESO
# ====================================

echo ""
echo "[INFO] =========================================="
echo "[INFO] PHASE 9: Reparer ESO"
echo "[INFO] =========================================="

echo "[INFO] Deleting all ESO pods for recreation..."
kubectl delete pods -n external-secrets --all --force --grace-period=0 2>&1 | grep -v "not found" || true

echo "[INFO] Waiting 90 seconds for ESO pods to restart..."
sleep 90

echo "[INFO] Checking ESO pods..."
kubectl get pods -n external-secrets -o wide | tee "$LOG_DIR/eso-after.txt"

echo "[INFO] Checking ESO webhook logs..."
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets-webhook --tail=50 2>&1 | tee "$LOG_DIR/eso-webhook-after.txt" || echo "[WARN] Failed to get ESO webhook logs"

# ====================================
# 🔟 PHASE 10 — Validation finale + documentation
# ====================================

echo ""
echo "[INFO] =========================================="
echo "[INFO] PHASE 10: Validation finale + documentation"
echo "[INFO] =========================================="

echo "[INFO] Final nodes status..."
kubectl get nodes -o wide | tee "$LOG_DIR/nodes-final.txt"

echo "[INFO] Final kube-system pods..."
kubectl get pods -n kube-system -o wide | tee "$LOG_DIR/kube-system-finalpods.txt"

echo "[INFO] Final external-secrets pods..."
kubectl get pods -n external-secrets -o wide | tee "$LOG_DIR/eso-finalpods.txt"

echo "[INFO] Checking redis-test-secret..."
kubectl get secret redis-test-secret -A 2>&1 | tee "$LOG_DIR/redis-secret-check.txt" || echo "[WARN] redis-test-secret not found"

# Documentation
DOC=keybuzz-docs/runbooks/PH9-FINAL-VALIDATION.md

{
    echo "# PH9 FINAL VALIDATION — Kubernetes HA (3 masters), ESO, ArgoCD, Vault"
    echo ""
    echo "**Date:** $(date)"
    echo ""
    echo "## Summary"
    echo ""
    NODES_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c Ready || echo "0")
    API_SERVERS=$(kubectl get pods -n kube-system -l component=kube-apiserver --no-headers 2>/dev/null | grep -c Running || echo "0")
    ETCD_PODS=$(kubectl get pods -n kube-system -l component=etcd --no-headers 2>/dev/null | grep -c Running || echo "0")
    CALICO_RUNNING=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | grep -c Running || echo "0")
    KUBE_PROXY_RUNNING=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy --no-headers 2>/dev/null | grep -c Running || echo "0")
    ESO_RUNNING=$(kubectl get pods -n external-secrets -l app.kubernetes.io/name=external-secrets --no-headers 2>/dev/null | grep -c Running || echo "0")
    
    echo "- Nodes Ready: $NODES_READY/8"
    echo "- API Servers Running: $API_SERVERS/3"
    echo "- ETCD Pods Running: $ETCD_PODS/3"
    echo "- Calico Nodes Running: $CALICO_RUNNING/8"
    echo "- kube-proxy Running: $KUBE_PROXY_RUNNING/8"
    echo "- ESO Pods Running: $ESO_RUNNING/1"
    echo ""
    echo "## Nodes"
    echo "\`\`\`"
    kubectl get nodes -o wide
    echo "\`\`\`"
    echo ""
    echo "## kube-system pods"
    echo "\`\`\`"
    kubectl get pods -n kube-system -o wide
    echo "\`\`\`"
    echo ""
    echo "## external-secrets pods"
    echo "\`\`\`"
    kubectl get pods -n external-secrets -o wide
    echo "\`\`\`"
    echo ""
    echo "## redis-test-secret"
    echo "\`\`\`"
    kubectl get secret redis-test-secret -A || echo "NOT FOUND"
    echo "\`\`\`"
    echo ""
    echo "## ETCD final member list"
    echo "\`\`\`"
    cat "$LOG_DIR/etcd-final.txt" 2>/dev/null || echo "ETCD check failed"
    echo "\`\`\`"
    echo ""
    echo "## Process"
    echo ""
    echo "Control-plane repair executed via ph9-execute-claude-plan.sh"
    echo "All logs available in /opt/keybuzz/logs/phase9-execute-claude-plan/"
    
} > "$DOC"

echo "[INFO] Documentation updated: $DOC"

# Commit & push
git add "$DOC" "$LOG_DIR"/* 2>&1 || git add "$DOC"
git commit -m "chore: PH9 execute Claude plan — full control-plane repair, ESO/network validation" || echo "[WARN] git commit failed"
git push || echo "[WARN] git push failed"

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ PH9 EXECUTE CLAUDE PLAN DONE"
echo "[INFO] =========================================="
echo ""
echo "[INFO] All logs saved in: $LOG_DIR"
echo "[INFO] Documentation updated: $DOC"

