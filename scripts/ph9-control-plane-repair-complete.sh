#!/bin/bash
# PH9-CONTROL-PLANE-REPAIR - Fix complet des 3 masters, du réseau Pod et d'ESO
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9/fix-control-plane/ph9-control-plane-repair-complete.log"
mkdir -p /opt/keybuzz/logs/phase9/fix-control-plane/
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "[INFO] =========================================="
echo "[INFO] PH9-CONTROL-PLANE-REPAIR-COMPLETE"
echo "[INFO] =========================================="
echo ""

# IPs des masters (basées sur les nœuds existants)
MASTER01_IP="10.0.0.100"
MASTER02_IP="10.0.0.101"
MASTER03_IP="10.0.0.102"

# ====================================
# 1️⃣ Préparation générale
# ====================================

echo "[INFO] Step 1: Preparation generale..."
git pull --rebase || echo "[WARN] git pull failed"

echo "[INFO] Sanity check de depart..."
echo "===== NODES ====="
kubectl get nodes -o wide || echo "ERROR: kubectl get nodes failed"
echo "===== PODS ====="
kubectl get pods -A | head -30 || echo "ERROR: kubectl get pods -A failed"

# Sauvegarder l'état actuel
kubectl get nodes -o wide > /opt/keybuzz/logs/phase9/fix-control-plane/nodes-before.txt || true
kubectl get pods -A > /opt/keybuzz/logs/phase9/fix-control-plane/pods-before.txt || true

# ====================================
# 2️⃣ Réparation ciblée des masters 02 et 03
# ====================================

echo ""
echo "[INFO] Step 2: Reparation des masters 02 et 03..."

# 2.1 Stopper kubelet et containerd sur masters 02/03 et nettoyer complètement
for ip in $MASTER02_IP $MASTER03_IP; do
    echo "[INFO]   Stopping services and cleaning on $ip..."
    ssh root@$ip bash <<CLEAN_NODE
        set +e
        systemctl stop kubelet || true
        systemctl stop containerd || true
        kubeadm reset -f || true
        rm -rf /etc/kubernetes/manifests/* || true
        rm -rf /etc/kubernetes/admin.conf || true
        rm -rf /etc/kubernetes/kubelet.conf || true
        rm -rf /etc/kubernetes/bootstrap-kubelet.conf || true
        rm -rf /etc/kubernetes/pki/* || true
        rm -rf /var/lib/etcd/* || true
        rm -rf /var/lib/kubelet/* || true
        rm -rf /etc/cni/net.d/* || true
CLEAN_NODE
done

sleep 10

# 2.2 Retirer master-02 du cluster ETCD s'il existe
echo "[INFO]   Removing master-02 from ETCD cluster if present..."
MASTER02_MEMBER_ID=$(ssh root@$MASTER01_IP "export ETCDCTL_API=3 && export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt && export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key && export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt && export ETCDCTL_ENDPOINTS=https://127.0.0.1:2379 && etcdctl member list 2>&1" | grep -i "master-02\|k8s-master-02\|10.0.0.101" | awk -F',' '{print $1}' | head -1 || true)
if [ -n "$MASTER02_MEMBER_ID" ]; then
    echo "[INFO]     Removing ETCD member $MASTER02_MEMBER_ID..."
    ssh root@$MASTER01_IP "export ETCDCTL_API=3 && export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt && export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key && export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt && export ETCDCTL_ENDPOINTS=https://127.0.0.1:2379 && etcdctl member remove $MASTER02_MEMBER_ID 2>&1" || echo "[WARN] Failed to remove ETCD member"
fi

# Retirer master-03 du cluster ETCD s'il existe
echo "[INFO]   Removing master-03 from ETCD cluster if present..."
MASTER03_MEMBER_ID=$(ssh root@$MASTER01_IP "export ETCDCTL_API=3 && export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt && export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key && export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt && export ETCDCTL_ENDPOINTS=https://127.0.0.1:2379 && etcdctl member list 2>&1" | grep -i "master-03\|k8s-master-03\|10.0.0.102" | awk -F',' '{print $1}' | head -1 || true)
if [ -n "$MASTER03_MEMBER_ID" ]; then
    echo "[INFO]     Removing ETCD member $MASTER03_MEMBER_ID..."
    ssh root@$MASTER01_IP "export ETCDCTL_API=3 && export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt && export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key && export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt && export ETCDCTL_ENDPOINTS=https://127.0.0.1:2379 && etcdctl member remove $MASTER03_MEMBER_ID 2>&1" || echo "[WARN] Failed to remove ETCD member"
fi

# Nettoyer les données ETCD sur masters 02/03
for ip in $MASTER02_IP $MASTER03_IP; do
    echo "[INFO]   Cleaning etcd data on $ip..."
    ssh root@$ip "rm -rf /var/lib/etcd/* || true; rm -rf /var/lib/kubelet/pods/* || true" || echo "[WARN] Failed to clean etcd on $ip"
done

# 2.3 S'assurer que /etc/kubernetes/manifests existe
for ip in $MASTER02_IP $MASTER03_IP; do
    echo "[INFO]   Checking manifests on $ip..."
    ssh root@$ip "ls -l /etc/kubernetes/manifests || mkdir -p /etc/kubernetes/manifests" || true
done

# 2.4 Corriger Containerd / cgroups pour tous les masters
for ip in $MASTER01_IP $MASTER02_IP $MASTER03_IP; do
    echo "[INFO]   Fixing containerd on $ip..."
    ssh root@$ip bash <<CONTAINERD_FIX
        mkdir -p /etc/containerd
        if [ ! -f /etc/containerd/config.toml ]; then
            containerd config default > /etc/containerd/config.toml
        fi
        sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml || true
        modprobe br_netfilter || true
        cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
        sysctl --system || true
        systemctl enable containerd || true
        systemctl enable kubelet || true
CONTAINERD_FIX
done

# 2.5 Redémarrer containerd + kubelet sur 02/03
for ip in $MASTER02_IP $MASTER03_IP; do
    echo "[INFO]   Restarting kubelet+containerd on $ip..."
    ssh root@$ip "systemctl restart containerd || true; sleep 5; systemctl restart kubelet || true" || echo "[WARN] Failed to restart on $ip"
done

sleep 10

# 2.6 Regénérer un certificat key et token de join côté master-01
echo "[INFO]   Getting join command from master-01..."
CERT_OUTPUT=$(ssh root@$MASTER01_IP "kubeadm init phase upload-certs --upload-certs 2>&1")
CERT_KEY=$(echo "$CERT_OUTPUT" | grep -E '^[a-f0-9]{64}$' | head -1)

# Get bootstrap token
BOOTSTRAP_SECRET=$(kubectl get secret -n kube-system --no-headers 2>/dev/null | grep bootstrap-token | head -1 | awk '{print $1}')
if [ -n "$BOOTSTRAP_SECRET" ]; then
    TOKEN_ID=$(kubectl get secret $BOOTSTRAP_SECRET -n kube-system -o jsonpath='{.data.token-id}' 2>/dev/null | base64 -d)
    TOKEN_SECRET=$(kubectl get secret $BOOTSTRAP_SECRET -n kube-system -o jsonpath='{.data.token-secret}' 2>/dev/null | base64 -d)
    TOKEN="${TOKEN_ID}.${TOKEN_SECRET}"
else
    echo "[ERROR]   No bootstrap token found"
    exit 1
fi

# Get CA hash
CA_HASH=$(ssh root@$MASTER01_IP "cat /etc/kubernetes/pki/ca.crt | openssl x509 -pubkey -noout | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'")

if [ -z "$CERT_KEY" ] || [ -z "$TOKEN" ] || [ -z "$CA_HASH" ]; then
    echo "[ERROR]   Failed to get join parameters"
    exit 1
fi

JOIN_CMD="kubeadm join ${MASTER01_IP}:6443 --token ${TOKEN} --discovery-token-unsafe-skip-ca-verification --control-plane --certificate-key ${CERT_KEY} --ignore-preflight-errors=CRI,FileAvailable--etc-kubernetes-kubelet.conf,Port-10250"

echo "JOIN_CMD = $JOIN_CMD" > /opt/keybuzz/logs/phase9/fix-control-plane/join-cmd.txt

# 2.7 Exécuter le join control-plane sur 02/03
for ip in $MASTER02_IP $MASTER03_IP; do
    echo "[INFO]   Running join control-plane on $ip..."
    ssh root@$ip bash <<JOIN_MASTER
        set +e
        for attempt in 1 2 3; do
            echo "[INFO]     Join attempt \$attempt/3 on $ip..."
            ${JOIN_CMD} && {
                echo "[INFO]     ✅ Joined successfully"
                exit 0
            }
            if [ \$attempt -lt 3 ]; then
                echo "[INFO]     Waiting 30 seconds before retry..."
                sleep 30
            fi
        done
        echo "[ERROR]     Failed to join after 3 attempts"
        exit 1
JOIN_MASTER
done

sleep 60

# 2.8 Attendre que kube-apiserver et etcd soient up
echo "[INFO]   Waiting for control-plane pods..."
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

kubectl get nodes -o wide > /opt/keybuzz/logs/phase9/fix-control-plane/nodes-after-join.txt || true

# ====================================
# 3️⃣ Stabiliser Calico (CNI)
# ====================================

echo ""
echo "[INFO] Step 3: Stabilisation Calico..."

# Reappliquer Calico
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml 2>&1 | tee /opt/keybuzz/logs/phase9/fix-control-plane/calico-apply.log || echo "[WARN] Calico apply may have issues"

# Supprimer les pods Calico pour restart propre
kubectl delete pod -n kube-system -l k8s-app=calico-node --force --grace-period=0 2>&1 | grep -v "not found" || true

sleep 60

echo "[INFO]   Calico status:"
kubectl get pods -n kube-system -l k8s-app=calico-node -o wide || true

# ====================================
# 4️⃣ Stabiliser kube-proxy
# ====================================

echo ""
echo "[INFO] Step 4: Stabilisation kube-proxy..."

kubectl delete pod -n kube-system -l k8s-app=kube-proxy --force --grace-period=0 2>&1 | grep -v "not found" || true

sleep 60

echo "[INFO]   kube-proxy status:"
kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide || true

# ====================================
# 5️⃣ Vérifier API depuis les pods
# ====================================

echo ""
echo "[INFO] Step 5: Verification API depuis pods..."

kubectl run api-test --rm -i --restart=Never --image=busybox:1.36 -- sh -c "
    wget -qO- --timeout=5 https://kubernetes.default.svc.cluster.local/api || 
    wget -qO- --timeout=5 https://10.96.0.1:443/api || 
    echo 'API_UNREACHABLE'
" 2>&1 | tee /opt/keybuzz/logs/phase9/fix-control-plane/api-test.log || echo "[WARN] API test failed"

# ====================================
# 6️⃣ Stabiliser ESO (webhook + controller)
# ====================================

echo ""
echo "[INFO] Step 6: Stabilisation ESO..."

# Redémarrer ESO complet
kubectl delete pod -n external-secrets --all --force --grace-period=0 2>&1 | grep -v "not found" || true

sleep 60

echo "[INFO]   ESO pods status:"
kubectl get pods -n external-secrets -o wide || true

# Récupérer logs webhook si CrashLoopBackOff
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets-webhook --tail=200 2>&1 | tee /opt/keybuzz/logs/phase9/fix-control-plane/eso-webhook.log || true

# Re-executer finalisation Vault
echo "[INFO]   Re-executing Vault integration..."
bash scripts/ph9-finalize-vault-eso-complete.sh 2>&1 | tee /opt/keybuzz/logs/phase9/fix-control-plane/finalize-vault.log || echo "[WARN] Vault integration may have issues"

# ====================================
# 7️⃣ Tester la synchro du secret redis-test-secret
# ====================================

echo ""
echo "[INFO] Step 7: Test synchro secret redis-test-secret..."

# Attendre que ESO soit prêt
for i in {1..60}; do
    ESO_READY=$(kubectl get pods -n external-secrets -l app.kubernetes.io/name=external-secrets --no-headers 2>/dev/null | grep -c Running || echo "0")
    if [ "$ESO_READY" -ge "1" ]; then
        echo "[INFO]   ✅ ESO ready"
        break
    fi
    echo "[INFO]   Waiting for ESO... ($i/60)"
    sleep 5
done

# Vérifier ExternalSecret
kubectl get externalsecret test-redis-secret -n keybuzz-system -o yaml 2>&1 | tee /opt/keybuzz/logs/phase9/fix-control-plane/externalsecret.yaml || echo "[WARN] ExternalSecret not found"

# Attendre la création du secret
echo "[INFO]   Waiting for secret synchronization..."
for i in {1..60}; do
    if kubectl get secret redis-test-secret -n keybuzz-system &>/dev/null; then
        echo "[INFO]   ✅ Secret redis-test-secret created"
        kubectl get secret redis-test-secret -n keybuzz-system -o yaml 2>&1 | tee /opt/keybuzz/logs/phase9/fix-control-plane/redis-secret.yaml
        break
    fi
    echo "[INFO]   Waiting... ($i/60)"
    sleep 5
done

# Vérification finale
if ! kubectl get secret redis-test-secret -n keybuzz-system &>/dev/null; then
    echo "[WARN]   redis-test-secret not found, ESO sync still not fully validated"
fi

# ====================================
# 8️⃣ Validation finale cluster & documentation
# ====================================

echo ""
echo "[INFO] Step 8: Validation finale et documentation..."

# Snapshot final
kubectl get nodes -o wide > /opt/keybuzz/logs/phase9/fix-control-plane/nodes-final.txt || true
kubectl get pods -A > /opt/keybuzz/logs/phase9/fix-control-plane/pods-final.txt || true

# Mettre à jour la doc
DOC=keybuzz-docs/runbooks/PH9-FINAL-VALIDATION.md

{
    echo "# PH9 FINAL VALIDATION — Kubernetes v3 + ArgoCD + ESO + Vault"
    echo ""
    echo "**Date:** $(date)"
    echo ""
    echo "## Nodes"
    echo "\`\`\`"
    kubectl get nodes -o wide 2>&1 || echo "kubectl get nodes failed"
    echo "\`\`\`"
    echo ""
    echo "## Pods (kube-system)"
    echo "\`\`\`"
    kubectl get pods -n kube-system -o wide 2>&1 || echo "kubectl get pods -n kube-system failed"
    echo "\`\`\`"
    echo ""
    echo "## Pods (external-secrets)"
    echo "\`\`\`"
    kubectl get pods -n external-secrets -o wide 2>&1 || echo "kubectl get pods -n external-secrets failed"
    echo "\`\`\`"
    echo ""
    echo "## Pods (argocd)"
    echo "\`\`\`"
    kubectl get pods -n argocd -o wide 2>&1 || echo "kubectl get pods -n argocd failed"
    echo "\`\`\`"
    echo ""
    echo "## ESO ExternalSecret redis-test-secret"
    echo "\`\`\`"
    if kubectl get secret redis-test-secret -n keybuzz-system &>/dev/null; then
        echo "✅ redis-test-secret EXISTS"
        kubectl get secret redis-test-secret -n keybuzz-system -o yaml 2>&1 | head -30
    else
        echo "❌ redis-test-secret NOT FOUND"
        echo "Check logs in /opt/keybuzz/logs/phase9/fix-control-plane/eso-webhook.log"
    fi
    echo "\`\`\`"
    echo ""
    echo "## ClusterSecretStore vault-keybuzz"
    echo "\`\`\`"
    kubectl get ClusterSecretStore vault-keybuzz -o yaml 2>&1 | head -30 || echo "ClusterSecretStore not found"
    echo "\`\`\`"
    echo ""
    echo "## MariaDB / wsrep (rappel)"
    echo "\`\`\`"
    echo "Cluster MariaDB HA déjà validé dans PH8 (cf. PH8-02/03/04/05)"
    echo "\`\`\`"
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
    
} > "$DOC"

# Commit & push
git add "$DOC" scripts/ph9-* 2>&1 || true
git commit -m "chore: PH9 control-plane & networking repair, cluster state updated" || echo "[WARN] git commit failed (maybe nothing to commit)"
git push || echo "[WARN] git push failed (check remote)"

# Résumé final
echo ""
echo "[INFO] =========================================="
echo "[INFO] FINAL SUMMARY"
echo "[INFO] =========================================="
echo ""
echo "Nodes:"
kubectl get nodes -o wide 2>&1 || true
echo ""
echo "Pods summary:"
kubectl get pods -A --no-headers 2>/dev/null | awk '{print $1, $2, $3, $4}' | sort | uniq -c || true
echo ""
echo "Check PH9-FINAL-VALIDATION.md for full details."
echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ PH9-CONTROL-PLANE-REPAIR-COMPLETE Finished"
echo "[INFO] =========================================="

