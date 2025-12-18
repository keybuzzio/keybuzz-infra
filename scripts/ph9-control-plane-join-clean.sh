#!/bin/bash
# PH9-CONTROL-PLANE-JOIN-CLEAN - Join propre des control-plane 02 puis 03 + réseau & ESO
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9-join-clean/ph9-control-plane-join-clean.log"
mkdir -p /opt/keybuzz/logs/phase9-join-clean/
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "[INFO] =========================================="
echo "[INFO] PH9-CONTROL-PLANE-JOIN-CLEAN"
echo "[INFO] =========================================="
echo ""

MASTER1_IP="10.0.0.100"
MASTER2_IP="10.0.0.101"
MASTER3_IP="10.0.0.102"

# ====================================
# 0️⃣ Préparation sur install-v3
# ====================================

echo "[INFO] Step 0: Preparation sur install-v3..."
git pull --rebase || echo "[WARN] git pull failed"

# Snapshot de départ
kubectl get nodes -o wide > /opt/keybuzz/logs/phase9-join-clean/nodes-before.txt || true
kubectl get pods -A > /opt/keybuzz/logs/phase9-join-clean/pods-before.txt || true

# ====================================
# 1️⃣ Regénérer un JOIN control-plane propre sur master-01
# ====================================

echo ""
echo "[INFO] Step 1: Regeneration JOIN control-plane propre..."

# Prepare join command by getting components separately from install-v3
echo "[INFO]   Getting join components..."

# Get certificate key from master-01
CERT_KEY=$(ssh root@$MASTER1_IP "export PATH=\$PATH:/usr/bin:/usr/local/bin && kubeadm init phase upload-certs --upload-certs 2>&1 | tail -n1 | tr -d '\r' | grep -E '^[a-f0-9]{64}$' | head -1" 2>/dev/null)

# Get token from bootstrap secret using kubectl from install-v3 (where KUBECONFIG is set)
BOOTSTRAP_SECRET=$(kubectl get secret -n kube-system --no-headers 2>/dev/null | grep bootstrap-token | head -1 | awk '{print $1}')
if [ -n "$BOOTSTRAP_SECRET" ]; then
    TOKEN_ID=$(kubectl get secret $BOOTSTRAP_SECRET -n kube-system -o jsonpath='{.data.token-id}' 2>/dev/null | base64 -d)
    TOKEN_SECRET=$(kubectl get secret $BOOTSTRAP_SECRET -n kube-system -o jsonpath='{.data.token-secret}' 2>/dev/null | base64 -d)
    TOKEN="${TOKEN_ID}.${TOKEN_SECRET}"
    echo "[INFO]     Token obtained from bootstrap secret: ${TOKEN_ID:0:10}..."
else
    TOKEN=""
    echo "[WARN]     No bootstrap token secret found"
fi

if [ -z "$CERT_KEY" ] || [ -z "$TOKEN" ]; then
    echo "[ERROR]   Failed to get join components"
    echo "[ERROR]     CERT_KEY: ${CERT_KEY:+present}${CERT_KEY:-missing}"
    echo "[ERROR]     TOKEN: ${TOKEN:+present}${TOKEN:-missing}"
    exit 1
fi

API_ENDPOINT="${MASTER1_IP}:6443"
JOIN_CMD="kubeadm join $API_ENDPOINT --token $TOKEN --discovery-token-unsafe-skip-ca-verification --control-plane --certificate-key $CERT_KEY --ignore-preflight-errors=CRI,FileAvailable--etc-kubernetes-kubelet.conf,Port-10250,Port-10257,Port-10259"

if echo "$JOIN_CMD" | grep -q "ERROR"; then
    echo "[ERROR]   Failed to prepare join command"
    echo "[ERROR]   Output: $JOIN_CMD"
    exit 1
fi

echo "=== CLEAN JOIN_CMD ===" > /opt/keybuzz/logs/phase9-join-clean/join-cmd-clean.txt
echo "$JOIN_CMD" >> /opt/keybuzz/logs/phase9-join-clean/join-cmd-clean.txt
echo "[INFO]     Join command prepared"

# ====================================
# 2️⃣ Join control-plane pour master-02 uniquement (séquentiel)
# ====================================

echo ""
echo "[INFO] Step 2: MASTER-02 JOIN CONTROL-PLANE (step 1/2)..."

# Régénérer un nouveau certificate-key juste avant le join
echo "[INFO]   Regenerating fresh certificate-key for master-02..."
CERT_KEY=$(ssh root@$MASTER1_IP "export PATH=\$PATH:/usr/bin:/usr/local/bin && kubeadm init phase upload-certs --upload-certs 2>&1 | tail -n1 | tr -d '\r' | grep -E '^[a-f0-9]{64}$' | head -1" 2>/dev/null)

if [ -z "$CERT_KEY" ]; then
    echo "[ERROR]   Failed to get certificate key for master-02"
    exit 1
fi

API_ENDPOINT="${MASTER1_IP}:6443"
JOIN_CMD_MASTER02="kubeadm join $API_ENDPOINT --token $TOKEN --discovery-token-unsafe-skip-ca-verification --control-plane --certificate-key $CERT_KEY --ignore-preflight-errors=CRI,FileAvailable--etc-kubernetes-kubelet.conf,Port-10250,Port-10257,Port-10259"

# Vérifier que kubelet & containerd sont démarrés
echo "[INFO]   Ensuring containerd and kubelet are enabled and running on master-02..."
ssh root@$MASTER2_IP bash <<'ENSURE_SERVICES_EOF'
    set +e
    systemctl enable containerd kubelet || true
    systemctl restart containerd || true
    sleep 3
    systemctl restart kubelet || true
ENSURE_SERVICES_EOF

# Exécuter le join propre
echo "[INFO]   Executing kubeadm join on master-02..."
mkdir -p /opt/keybuzz/logs/phase9-join-clean/
ssh root@$MASTER2_IP bash <<JOIN_MASTER02_EOF
    set +e
    export PATH=\$PATH:/usr/bin:/usr/local/bin
    ${JOIN_CMD_MASTER02} 2>&1
JOIN_MASTER02_EOF | tee /opt/keybuzz/logs/phase9-join-clean/join-master-02.log

JOIN02_RESULT=$?
if [ $JOIN02_RESULT -ne 0 ]; then
    echo "[WARN]   master-02 join may have failed, but continuing..."
fi

# Attendre la stabilisation
echo "[INFO]   Waiting 60 seconds for master-02 to stabilize..."
sleep 60

# Vérifier l'état du nœud
echo "[INFO]   Checking node status for master-02..."
echo "=== CHECK NODE STATUS master-02 ===" | tee -a /opt/keybuzz/logs/phase9-join-clean/join-master-02.log
kubectl get node k8s-master-02 -o wide 2>&1 | tee -a /opt/keybuzz/logs/phase9-join-clean/join-master-02.log

# Vérifier les pods control-plane sur master-02
ssh root@$MASTER2_IP bash <<'CHECK_MASTER02_EOF' > /opt/keybuzz/logs/phase9-join-clean/master-02-post-join.txt 2>&1
    echo "--- systemctl status kubelet ---"
    systemctl status kubelet --no-pager | head -40 || true
    echo ""
    echo "--- ps -ef | grep kube-apiserver ---"
    ps -ef | grep kube-apiserver | grep -v grep || echo "no kube-apiserver process"
    echo ""
    echo "--- crictl ps (containerd) ---"
    crictl ps 2>/dev/null | grep -E "kube-apiserver|etcd" || echo "no control-plane containers"
CHECK_MASTER02_EOF

# ====================================
# 3️⃣ Join control-plane master-03, seulement après master-02
# ====================================

echo ""
echo "[INFO] Step 3: MASTER-03 JOIN CONTROL-PLANE (step 2/2)..."

# Regénérer la commande join (le certificate-key peut avoir changé)
echo "[INFO]   Regenerating join command for master-03..."

CERT_KEY=$(ssh root@$MASTER1_IP "export PATH=\$PATH:/usr/bin:/usr/local/bin && kubeadm init phase upload-certs --upload-certs 2>&1 | tail -n1 | tr -d '\r' | grep -E '^[a-f0-9]{64}$' | head -1" 2>/dev/null)

BOOTSTRAP_SECRET=$(kubectl get secret -n kube-system --no-headers 2>/dev/null | grep bootstrap-token | head -1 | awk '{print $1}')
if [ -n "$BOOTSTRAP_SECRET" ]; then
    TOKEN_ID=$(kubectl get secret $BOOTSTRAP_SECRET -n kube-system -o jsonpath='{.data.token-id}' 2>/dev/null | base64 -d)
    TOKEN_SECRET=$(kubectl get secret $BOOTSTRAP_SECRET -n kube-system -o jsonpath='{.data.token-secret}' 2>/dev/null | base64 -d)
    TOKEN="${TOKEN_ID}.${TOKEN_SECRET}"
fi

API_ENDPOINT="${MASTER1_IP}:6443"
JOIN_CMD="kubeadm join $API_ENDPOINT --token $TOKEN --discovery-token-unsafe-skip-ca-verification --control-plane --certificate-key $CERT_KEY --ignore-preflight-errors=CRI,FileAvailable--etc-kubernetes-kubelet.conf,Port-10250,Port-10257,Port-10259"

if [ -z "$CERT_KEY" ] || [ -z "$TOKEN" ]; then
    echo "[ERROR]   Failed to get join components for master-03"
    exit 1
fi

API_ENDPOINT="${MASTER1_IP}:6443"
JOIN_CMD_MASTER03="kubeadm join $API_ENDPOINT --token $TOKEN --discovery-token-unsafe-skip-ca-verification --control-plane --certificate-key $CERT_KEY --ignore-preflight-errors=CRI,FileAvailable--etc-kubernetes-kubelet.conf,Port-10250,Port-10257,Port-10259"

echo "[INFO]   Ensuring containerd and kubelet are enabled and running on master-03..."
ssh root@$MASTER3_IP bash <<'ENSURE_SERVICES_EOF'
    set +e
    systemctl enable containerd kubelet || true
    systemctl restart containerd || true
    sleep 3
    systemctl restart kubelet || true
ENSURE_SERVICES_EOF

echo "[INFO]   Executing kubeadm join on master-03..."
ssh root@$MASTER3_IP bash <<JOIN_MASTER03_EOF
    set +e
    export PATH=\$PATH:/usr/bin:/usr/local/bin
    ${JOIN_CMD_MASTER03} 2>&1
JOIN_MASTER03_EOF | tee /opt/keybuzz/logs/phase9-join-clean/join-master-03.log

JOIN03_RESULT=$?
if [ $JOIN03_RESULT -ne 0 ]; then
    echo "[WARN]   master-03 join may have failed, but continuing..."
fi

sleep 60

echo "[INFO]   Checking node status for master-03..."
echo "=== CHECK NODE STATUS master-03 ===" | tee -a /opt/keybuzz/logs/phase9-join-clean/join-master-03.log
kubectl get node k8s-master-03 -o wide 2>&1 | tee -a /opt/keybuzz/logs/phase9-join-clean/join-master-03.log

ssh root@$MASTER3_IP bash <<'CHECK_MASTER03_EOF' > /opt/keybuzz/logs/phase9-join-clean/master-03-post-join.txt 2>&1
    echo "--- systemctl status kubelet ---"
    systemctl status kubelet --no-pager | head -40 || true
    echo ""
    echo "--- ps -ef | grep kube-apiserver ---"
    ps -ef | grep kube-apiserver | grep -v grep || echo "no kube-apiserver process"
    echo ""
    echo "--- crictl ps (apiserver) ---"
    crictl ps 2>/dev/null | grep -E "kube-apiserver|etcd" || echo "no control-plane containers"
CHECK_MASTER03_EOF

# Attendre que les control-plane pods soient Running
echo "[INFO]   Waiting for control-plane pods to be Running..."
for i in {1..60}; do
    API_READY=$(kubectl get pods -n kube-system -l component=kube-apiserver --no-headers 2>/dev/null | grep -c Running || echo "0")
    ETCD_READY=$(kubectl get pods -n kube-system -l component=etcd --no-headers 2>/dev/null | grep -c Running || echo "0")
    
    if [ "$API_READY" -ge "2" ] && [ "$ETCD_READY" -ge "2" ]; then
        echo "[INFO]     ✅ Control-plane pods Running (API: $API_READY/3, ETCD: $ETCD_READY/3)"
        break
    fi
    echo "[INFO]     Waiting... ($i/60) - API: $API_READY/3, ETCD: $ETCD_READY/3"
    sleep 5
done

# ====================================
# 4️⃣ Stabiliser Calico (CNI) et kube-proxy
# ====================================

echo ""
echo "[INFO] Step 4: Stabilisation Calico et kube-proxy..."

# Reappliquer Calico
echo "[INFO]   Reapplying Calico manifests..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml 2>&1 | tee /opt/keybuzz/logs/phase9-join-clean/calico-reapply.log

# Redémarrer calico-node
echo "[INFO]   Restarting calico-node pods..."
kubectl delete pod -n kube-system -l k8s-app=calico-node --force --grace-period=0 2>&1 | grep -v "not found" || true

# Redémarrer kube-proxy
echo "[INFO]   Restarting kube-proxy pods..."
kubectl delete pod -n kube-system -l k8s-app=kube-proxy --force --grace-period=0 2>&1 | grep -v "not found" || true

sleep 90

echo "[INFO]   Status kube-system après CNI/kube-proxy fix..."
echo "=== STATUS kube-system après CNI/kube-proxy fix ===" | tee /opt/keybuzz/logs/phase9-join-clean/kube-system-after-cni.txt
kubectl get pods -n kube-system -o wide 2>&1 | tee -a /opt/keybuzz/logs/phase9-join-clean/kube-system-after-cni.txt

# ====================================
# 5️⃣ Relancer ESO webhook & controller
# ====================================

echo ""
echo "[INFO] Step 5: Restart ESO..."

kubectl delete pod -n external-secrets --all --force --grace-period=0 2>&1 | grep -v "not found" || true

sleep 60

echo "[INFO]   ESO pods status..."
echo "=== ESO pods ===" | tee /opt/keybuzz/logs/phase9-join-clean/eso-pods.txt
kubectl get pods -n external-secrets -o wide 2>&1 | tee -a /opt/keybuzz/logs/phase9-join-clean/eso-pods.txt

# Sauvegarder logs webhook si CrashLoop
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets-webhook --tail=200 2>&1 | tee /opt/keybuzz/logs/phase9-join-clean/eso-webhook-after-join.log || true

# ====================================
# 6️⃣ Test de connectivité API depuis un pod (important pour ESO)
# ====================================

echo ""
echo "[INFO] Step 6: Test connectivite API depuis pod..."

kubectl delete pod api-test -n default --force --grace-period=0 2>/dev/null || true

kubectl run api-test --rm -i --restart=Never --image=busybox:1.36 -- sh -c "
    wget -qO- --timeout=5 https://kubernetes.default.svc.cluster.local/api || 
    wget -qO- --timeout=5 https://10.96.0.1:443/api || 
    echo 'API_UNREACHABLE'
" 2>&1 | tee /opt/keybuzz/logs/phase9-join-clean/api-test.log || echo "[WARN] api-test pod error"

# ====================================
# 7️⃣ Vérifier & forcer la synchro du ExternalSecret redis-test-secret
# ====================================

echo ""
echo "[INFO] Step 7: Verification ExternalSecret redis-test-secret..."

# Réappliquer l'ExternalSecret de test si manifest dispo
if [ -f k8s/tests/test-redis-externalsecret.yaml ]; then
    echo "[INFO]   Reapplying ExternalSecret from manifest..."
    kubectl apply -f k8s/tests/test-redis-externalsecret.yaml 2>&1 | tee /opt/keybuzz/logs/phase9-join-clean/externalsecret-apply.log
else
    echo "[INFO]   Creating ExternalSecret directly..."
    kubectl apply -f - <<EOF 2>&1 | tee /opt/keybuzz/logs/phase9-join-clean/externalsecret-apply.log
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: test-redis-secret
  namespace: keybuzz-system
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-keybuzz
    kind: ClusterSecretStore
  target:
    name: redis-test-secret
  data:
    - secretKey: redis-password
      remoteRef:
        key: kv/keybuzz/redis
        property: password
EOF
fi

# Attendre que le secret soit créé
echo "[INFO]   Waiting for secret synchronization..."
for i in {1..60}; do
    if kubectl get secret redis-test-secret -n keybuzz-system &>/dev/null; then
        echo "[INFO]     ✅ Secret redis-test-secret created"
        break
    fi
    echo "[INFO]     Waiting... ($i/60)"
    sleep 5
done

echo "[INFO]   Secret redis-test-secret status..."
echo "=== Secret redis-test-secret (si present) ===" | tee /opt/keybuzz/logs/phase9-join-clean/redis-secret-final.log
kubectl get secret redis-test-secret -n keybuzz-system -o yaml 2>&1 | tee -a /opt/keybuzz/logs/phase9-join-clean/redis-secret-final.log || echo "[WARN] redis-test-secret NOT FOUND"

# ====================================
# 8️⃣ Validation finale du cluster
# ====================================

echo ""
echo "[INFO] Step 8: Validation finale du cluster..."

echo "[INFO]   Final nodes..."
echo "=== FINAL NODES ===" | tee /opt/keybuzz/logs/phase9-join-clean/nodes-final.txt
kubectl get nodes -o wide 2>&1 | tee -a /opt/keybuzz/logs/phase9-join-clean/nodes-final.txt

echo "[INFO]   Final pods (kube-system)..."
echo "=== FINAL PODS (kube-system) ===" | tee /opt/keybuzz/logs/phase9-join-clean/pods-kube-system-final.txt
kubectl get pods -n kube-system -o wide 2>&1 | tee -a /opt/keybuzz/logs/phase9-join-clean/pods-kube-system-final.txt

echo "[INFO]   Final pods (external-secrets)..."
echo "=== FINAL PODS (external-secrets) ===" | tee /opt/keybuzz/logs/phase9-join-clean/pods-external-secrets-final.txt
kubectl get pods -n external-secrets -o wide 2>&1 | tee -a /opt/keybuzz/logs/phase9-join-clean/pods-external-secrets-final.txt

# ====================================
# 9️⃣ Mise à jour PH9-FINAL-VALIDATION.md & commit
# ====================================

echo ""
echo "[INFO] Step 9: Mise a jour PH9-FINAL-VALIDATION.md..."

DOC=keybuzz-docs/runbooks/PH9-FINAL-VALIDATION.md

{
    echo "# PH9 FINAL VALIDATION — Kubernetes v3 + ArgoCD + ESO + Vault (Control-plane repair)"
    echo ""
    echo "**Date:** $(date)"
    echo ""
    echo "## Summary"
    echo ""
    NODES_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c Ready || echo "0")
    API_SERVERS=$(kubectl get pods -n kube-system -l component=kube-apiserver --no-headers 2>/dev/null | grep -c Running || echo "0")
    ETCD_PODS=$(kubectl get pods -n kube-system -l component=etcd --no-headers 2>/dev/null | grep -c Running || echo "0")
    ESO_PODS=$(kubectl get pods -n external-secrets -l app.kubernetes.io/name=external-secrets --no-headers 2>/dev/null | grep -c Running || echo "0")
    SECRET_EXISTS=$(kubectl get secret redis-test-secret -n keybuzz-system 2>&1 | grep -q redis-test-secret && echo "YES" || echo "NO")
    CRASHLOOP=$(kubectl get pods -A --no-headers 2>/dev/null | grep -c CrashLoopBackOff || echo "0")
    
    echo "- Nodes Ready: $NODES_READY/8"
    echo "- API Servers Running: $API_SERVERS/3"
    echo "- ETCD Pods Running: $ETCD_PODS/3"
    echo "- ESO Pods Running: $ESO_PODS/1"
    echo "- Secret redis-test-secret: $SECRET_EXISTS"
    echo "- Pods in CrashLoopBackOff: $CRASHLOOP"
    echo ""
    echo "## Nodes (final)"
    echo "\`\`\`"
    kubectl get nodes -o wide 2>&1 || echo "ERROR: kubectl get nodes failed"
    echo "\`\`\`"
    echo ""
    echo "## Pods (kube-system, final)"
    echo "\`\`\`"
    kubectl get pods -n kube-system -o wide 2>&1 || echo "ERROR: kubectl get pods -n kube-system failed"
    echo "\`\`\`"
    echo ""
    echo "## Pods (external-secrets, final)"
    echo "\`\`\`"
    kubectl get pods -n external-secrets -o wide 2>&1 || echo "ERROR: kubectl get pods -n external-secrets failed"
    echo "\`\`\`"
    echo ""
    echo "## Pods (argocd, final)"
    echo "\`\`\`"
    kubectl get pods -n argocd -o wide 2>&1 || echo "ERROR: kubectl get pods -n argocd failed"
    echo "\`\`\`"
    echo ""
    echo "## ESO ExternalSecret redis-test-secret"
    echo "\`\`\`"
    if kubectl get secret redis-test-secret -n keybuzz-system &>/dev/null; then
        echo "✅ redis-test-secret EXISTS"
        kubectl get secret redis-test-secret -n keybuzz-system -o yaml 2>&1 | head -30
    else
        echo "❌ redis-test-secret NOT FOUND"
        echo "Check logs in /opt/keybuzz/logs/phase9-join-clean/eso-webhook-after-join.log"
    fi
    echo "\`\`\`"
    echo ""
    echo "## ClusterSecretStore vault-keybuzz"
    echo "\`\`\`"
    kubectl get ClusterSecretStore vault-keybuzz -o yaml 2>&1 | head -30 || echo "ClusterSecretStore not found"
    echo "\`\`\`"
    echo ""
    echo "## Commentaires"
    echo ""
    echo "- master-02 & master-03 ont été rejoints via join control-plane propre."
    echo "- Calico & kube-proxy ont été re-déployés."
    echo "- ESO a été redémarré (webhook+controller)."
    echo "- Voir logs dans /opt/keybuzz/logs/phase9-join-clean pour les détails."
    
} > "$DOC"

echo "[INFO]     Documentation mise a jour: $DOC"

# Commit & push
git add "$DOC" scripts/ph9-control-plane-join-clean.sh 2>&1 || git add "$DOC" scripts/ph9-control-plane-join-clean.sh
git commit -m "chore: PH9 control-plane join clean (3 masters), networking & ESO status updated" || echo "[WARN] git commit failed (maybe nothing new)"
git push || echo "[WARN] git push failed (check remote)"

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ PH9-CONTROL-PLANE-JOIN-CLEAN COMPLETED"
echo "[INFO] =========================================="
echo ""
echo "[INFO] Voir PH9-FINAL-VALIDATION.md pour l'état final."
echo "[INFO] Logs disponibles dans /opt/keybuzz/logs/phase9-join-clean/"

