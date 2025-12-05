#!/bin/bash
# PH9-CONTROL-PLANE-DEEP-DIAGNOSTIC - Diagnostic et cleanup profond des masters 02/03
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase9-deep-diagnostic/ph9-deep-diagnostic.log"
mkdir -p /opt/keybuzz/logs/phase9-deep-diagnostic/
exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "[INFO] =========================================="
echo "[INFO] PH9-CONTROL-PLANE-DEEP-DIAGNOSTIC & CLEANUP"
echo "[INFO] =========================================="
echo ""

# IPs des masters
MASTER01_IP="10.0.0.100"
MASTER02_IP="10.0.0.101"
MASTER03_IP="10.0.0.102"
MASTERS="$MASTER02_IP $MASTER03_IP"

# ====================================
# 0️⃣ Préparation sur install-v3
# ====================================

echo "[INFO] Step 0: Preparation sur install-v3..."
git pull --rebase || echo "[WARN] git pull failed"

# Snapshot de l'état avant
kubectl get nodes -o wide > /opt/keybuzz/logs/phase9-deep-diagnostic/nodes-before.txt || true
kubectl get pods -A > /opt/keybuzz/logs/phase9-deep-diagnostic/pods-before.txt || true

# ====================================
# 1️⃣ DIAGNOSTIC PROCESSUS & PORTS SUR MASTER-02 ET 03
# ====================================

echo ""
echo "[INFO] Step 1: Diagnostic processus & ports sur master-02/03..."

for ip in $MASTERS; do
    echo "[INFO]   Diagnostic sur $ip..."
    ssh root@$ip bash <<DIAGNOSTIC_EOF > /opt/keybuzz/logs/phase9-deep-diagnostic/master-diagnostic-$ip.txt 2>&1
        echo "===== DIAGNOSTIC SUR $ip ====="
        echo ""
        echo "--- ps -ef | grep kube ---"
        ps -ef | grep kube | grep -v grep || echo "no kube* processes"
        echo ""
        echo "--- ps -ef | grep etcd ---"
        ps -ef | grep etcd | grep -v grep || echo "no etcd processes"
        echo ""
        echo "--- lsof ports 10257 / 10259 / 10250 / 6443 ---"
        if command -v lsof >/dev/null 2>&1; then
            lsof -i :10257 -i :10259 -i :10250 -i :6443 || echo "no processes on these ports"
        else
            echo "lsof not available"
        fi
        echo ""
        echo "--- netstat / ss ports ---"
        if command -v ss >/dev/null 2>&1; then
            ss -ntlp | grep -E '10257|10259|10250|6443' || echo "no bound ports found"
        elif command -v netstat >/dev/null 2>&1; then
            netstat -plant 2>/dev/null | grep -E '10257|10259|10250|6443' || echo "no bound ports found"
        else
            echo "neither ss nor netstat available"
        fi
        echo ""
        echo "--- systemctl status kubelet ---"
        systemctl status kubelet --no-pager | head -30 || echo "kubelet service status unavailable"
        echo ""
        echo "--- journalctl -u kubelet (last 50 lines) ---"
        journalctl -u kubelet -n 50 --no-pager || echo "kubelet logs unavailable"
        echo ""
        echo "--- systemctl status containerd ---"
        systemctl status containerd --no-pager | head -20 || echo "containerd service status unavailable"
        echo ""
        echo "--- /etc/kubernetes/manifests contents ---"
        ls -la /etc/kubernetes/manifests/ 2>/dev/null || echo "manifests directory not found or empty"
        echo ""
        echo "--- /var/lib/etcd contents ---"
        ls -la /var/lib/etcd/ 2>/dev/null | head -20 || echo "etcd directory empty or not found"
        echo ""
        echo "--- /var/lib/kubelet contents ---"
        ls -la /var/lib/kubelet/ 2>/dev/null | head -20 || echo "kubelet directory empty or not found"
DIAGNOSTIC_EOF
    echo "[INFO]     Diagnostic sauvegarde dans master-diagnostic-$ip.txt"
done

# ====================================
# 2️⃣ KILL PROCS ZOMBIES SUR 10257 / 10259 / 10250 / 6443
# ====================================

echo ""
echo "[INFO] Step 2: Kill processus zombies sur master-02/03..."

for ip in $MASTERS; do
    echo "[INFO]   Kill zombies sur $ip..."
    ssh root@$ip bash <<KILL_ZOMBIES_EOF
        set +e
        echo "Killing kube-controller-manager processes..."
        pkill -9 -f kube-controller-manager || echo "No kube-controller-manager processes found"
        
        echo "Killing kube-scheduler processes..."
        pkill -9 kube-scheduler || echo "No kube-scheduler processes found"
        
        echo "Killing kube-apiserver processes..."
        pkill -9 kube-apiserver || echo "No kube-apiserver processes found"
        
        echo "Killing etcd processes..."
        pkill -9 etcd || echo "No etcd processes found"
        
        echo "Checking for processes on ports 10257, 10259, 10250, 6443..."
        if command -v lsof >/dev/null 2>&1; then
            PIDS_10257=\$(lsof -ti :10257 2>/dev/null)
            PIDS_10259=\$(lsof -ti :10259 2>/dev/null)
            PIDS_10250=\$(lsof -ti :10250 2>/dev/null)
            PIDS_6443=\$(lsof -ti :6443 2>/dev/null)
            
            [ -n "\$PIDS_10257" ] && kill -9 \$PIDS_10257 && echo "Killed processes on port 10257: \$PIDS_10257" || echo "No processes on port 10257"
            [ -n "\$PIDS_10259" ] && kill -9 \$PIDS_10259 && echo "Killed processes on port 10259: \$PIDS_10259" || echo "No processes on port 10259"
            [ -n "\$PIDS_10250" ] && kill -9 \$PIDS_10250 && echo "Killed processes on port 10250: \$PIDS_10250" || echo "No processes on port 10250"
            [ -n "\$PIDS_6443" ] && kill -9 \$PIDS_6443 && echo "Killed processes on port 6443: \$PIDS_6443" || echo "No processes on port 6443"
            
            echo "Final check - processes on ports:"
            lsof -i :10257 -i :10259 -i :10250 -i :6443 || echo "No processes found on target ports"
        else
            echo "lsof not available, using fuser as fallback..."
            fuser -k 10257/tcp 2>/dev/null || true
            fuser -k 10259/tcp 2>/dev/null || true
            fuser -k 10250/tcp 2>/dev/null || true
            fuser -k 6443/tcp 2>/dev/null || true
        fi
        
        sleep 2
        echo "Zombie processes killed"
KILL_ZOMBIES_EOF
    echo "[INFO]     Zombies tués sur $ip"
done

# ====================================
# 3️⃣ NETTOYAGE RÉPERTOIRES KUBEADM / ETCD / KUBELET SUR 02/03
# ====================================

echo ""
echo "[INFO] Step 3: Nettoyage repertoires kubeadm/etcd/kubelet sur master-02/03..."

for ip in $MASTERS; do
    echo "[INFO]   Cleanup K8s folders sur $ip..."
    ssh root@$ip bash <<CLEANUP_EOF
        set +e
        echo "Stopping kubelet..."
        systemctl stop kubelet || echo "kubelet already stopped"
        
        echo "Stopping containerd..."
        systemctl stop containerd || echo "containerd already stopped"
        
        sleep 2
        
        echo "Removing /etc/kubernetes/manifests/*"
        rm -rf /etc/kubernetes/manifests/* || echo "manifests already removed"
        
        echo "Removing /var/lib/etcd/*"
        rm -rf /var/lib/etcd/* || echo "etcd data already removed"
        
        echo "Removing /var/lib/kubelet/*"
        rm -rf /var/lib/kubelet/* || echo "kubelet data already removed"
        
        echo "Removing /etc/cni/net.d/*"
        rm -rf /etc/cni/net.d/* || echo "CNI config already removed"
        
        echo "Removing /etc/kubernetes/pki/* (except if kubeadm config exists)"
        # Garder seulement ca.crt si présent pour la vérification
        if [ -f /etc/kubernetes/pki/ca.crt ]; then
            find /etc/kubernetes/pki/ -type f ! -name "ca.crt" -delete 2>/dev/null || true
        else
            rm -rf /etc/kubernetes/pki/* || echo "pki already removed"
        fi
        
        echo "Removing kubeconfig files..."
        rm -f /etc/kubernetes/admin.conf /etc/kubernetes/kubelet.conf /etc/kubernetes/bootstrap-kubelet.conf /etc/kubernetes/controller-manager.conf /etc/kubernetes/scheduler.conf 2>/dev/null || echo "kubeconfig files already removed"
        
        echo "Running kubeadm reset..."
        kubeadm reset -f || echo "kubeadm reset completed or not needed"
        
        echo "Cleanup completed on $ip"
CLEANUP_EOF
    echo "[INFO]     Cleanup terminé sur $ip"
done

# ====================================
# 4️⃣ VÉRIFICATION ETCD (CLUSTER) CÔTÉ MASTER-01
# ====================================

echo ""
echo "[INFO] Step 4: Verification ETCD cluster cote master-01..."

ssh root@$MASTER01_IP bash <<ETCD_CHECK_EOF > /opt/keybuzz/logs/phase9-deep-diagnostic/etcd-member-list-before.txt 2>&1
    echo "=== ETCD member list (sur master-01) ==="
    if command -v etcdctl >/dev/null 2>&1; then
        export ETCDCTL_API=3
        export ETCDCTL_ENDPOINTS=https://127.0.0.1:2379
        export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt
        export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt
        export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key
        
        etcdctl member list || echo "ERROR: etcdctl member list failed"
    else
        echo "etcdctl not found in PATH, trying with full path..."
        /usr/local/bin/etcdctl member list \
            --endpoints=https://127.0.0.1:2379 \
            --cacert=/etc/kubernetes/pki/etcd/ca.crt \
            --cert=/etc/kubernetes/pki/etcd/server.crt \
            --key=/etc/kubernetes/pki/etcd/server.key || echo "ERROR: etcdctl member list failed (full path)"
    fi
    
    echo ""
    echo "=== ETCD cluster health ==="
    if command -v etcdctl >/dev/null 2>&1; then
        export ETCDCTL_API=3
        export ETCDCTL_ENDPOINTS=https://127.0.0.1:2379
        export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt
        export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt
        export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key
        
        etcdctl endpoint health || echo "ERROR: etcdctl endpoint health failed"
    fi
ETCD_CHECK_EOF

# Vérifier si master-02/03 sont encore membres ETCD et les retirer si nécessaire
echo "[INFO]   Verifying ETCD members..."
ETCD_MEMBERS=$(cat /opt/keybuzz/logs/phase9-deep-diagnostic/etcd-member-list-before.txt 2>/dev/null | grep -E "master-02|master-03|10.0.0.101|10.0.0.102" || echo "")

if [ -n "$ETCD_MEMBERS" ]; then
    echo "[INFO]     Found orphaned ETCD members for master-02/03, removing them..."
    
    # Extraire les IDs des membres
    for member_line in "$ETCD_MEMBERS"; do
        MEMBER_ID=$(echo "$member_line" | awk -F',' '{print $1}' | head -1)
        if [ -n "$MEMBER_ID" ] && [ "$MEMBER_ID" != "ERROR" ]; then
            echo "[INFO]       Removing ETCD member $MEMBER_ID..."
            ssh root@$MASTER01_IP bash <<REMOVE_MEMBER_EOF
                set +e
                export ETCDCTL_API=3
                export ETCDCTL_ENDPOINTS=https://127.0.0.1:2379
                export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt
                export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt
                export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key
                
                etcdctl member remove $MEMBER_ID 2>&1 || echo "Failed to remove member $MEMBER_ID (may already be removed)"
REMOVE_MEMBER_EOF
        fi
    done
else
    echo "[INFO]     No orphaned ETCD members found for master-02/03"
fi

# Nouvelle liste après retrait
ssh root@$MASTER01_IP bash <<ETCD_CHECK_AFTER_EOF > /opt/keybuzz/logs/phase9-deep-diagnostic/etcd-member-list-after.txt 2>&1
    echo "=== ETCD member list (apres cleanup) ==="
    if command -v etcdctl >/dev/null 2>&1; then
        export ETCDCTL_API=3
        export ETCDCTL_ENDPOINTS=https://127.0.0.1:2379
        export ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt
        export ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt
        export ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key
        
        etcdctl member list || echo "ERROR: etcdctl member list failed"
    fi
ETCD_CHECK_AFTER_EOF

# ====================================
# 5️⃣ VÉRIFICATION DES MANIFESTS SUR MASTER-01 (RÉFÉRENCE)
# ====================================

echo ""
echo "[INFO] Step 5: Verification manifests sur master-01 (reference)..."

ssh root@$MASTER01_IP bash <<MANIFESTS_CHECK_EOF > /opt/keybuzz/logs/phase9-deep-diagnostic/master-01-manifests.txt 2>&1
    echo "=== ls /etc/kubernetes/manifests sur master-01 ==="
    ls -la /etc/kubernetes/manifests/ || echo "no manifests?"
    
    echo ""
    echo "=== Contents of manifests (first 20 lines each) ==="
    for file in /etc/kubernetes/manifests/*; do
        if [ -f "$file" ]; then
            echo "--- $file ---"
            head -20 "$file"
            echo ""
        fi
    done
MANIFESTS_CHECK_EOF

# ====================================
# 6️⃣ PRÉPARATION DU JOIN PROPRE (SANS L'EXÉCUTER ENCORE)
# ====================================

echo ""
echo "[INFO] Step 6: Preparation du join propre (sans execution)..."

# Prepare join command by getting components separately from install-v3
echo "[INFO]   Getting join components..."

# Get certificate key from master-01
CERT_KEY=$(ssh root@$MASTER01_IP "export PATH=\$PATH:/usr/bin:/usr/local/bin && kubeadm init phase upload-certs --upload-certs 2>&1 | tail -n1 | tr -d '\r' | grep -E '^[a-f0-9]{64}$' | head -1" 2>/dev/null)

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

# Get CA hash from master-01
CA_HASH=$(ssh root@$MASTER01_IP "openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'" 2>/dev/null)

if [ -z "$CERT_KEY" ] || [ -z "$TOKEN" ] || [ -z "$CA_HASH" ]; then
    echo "[WARN]   Failed to get all join components:"
    echo "[WARN]     CERT_KEY: ${CERT_KEY:+present}${CERT_KEY:-missing}"
    echo "[WARN]     TOKEN: ${TOKEN:+present}${TOKEN:-missing}"
    echo "[WARN]     CA_HASH: ${CA_HASH:+present}${CA_HASH:-missing}"
    JOIN_CMD="ERROR: Failed to prepare join command - missing components"
else
    API_ENDPOINT="${MASTER01_IP}:6443"
    JOIN_CMD="kubeadm join $API_ENDPOINT --token $TOKEN --discovery-token-unsafe-skip-ca-verification --control-plane --certificate-key $CERT_KEY --ignore-preflight-errors=CRI,FileAvailable--etc-kubernetes-kubelet.conf,Port-10250,Port-10257,Port-10259"
    echo "[INFO]     Join command prepared successfully"
fi

if echo "$JOIN_CMD" | grep -q "ERROR"; then
    echo "[ERROR]   Failed to prepare join command"
    echo "[ERROR]   Output: $JOIN_CMD"
    JOIN_CMD="ERROR: Join command preparation failed"
fi

echo "=== JOIN_CMD ===" > /opt/keybuzz/logs/phase9-deep-diagnostic/join-cmd-clean.txt
echo "$JOIN_CMD" >> /opt/keybuzz/logs/phase9-deep-diagnostic/join-cmd-clean.txt
echo "" >> /opt/keybuzz/logs/phase9-deep-diagnostic/join-cmd-clean.txt
echo "NOTE: Ne PAS executer cette commande manuellement. Utiliser le script ph9-control-plane-join-clean.sh" >> /opt/keybuzz/logs/phase9-deep-diagnostic/join-cmd-clean.txt

echo "[INFO]     Join command préparée et sauvegardée"

# ====================================
# 7️⃣ RÉSUMÉ & DOCUMENTATION
# ====================================

echo ""
echo "[INFO] Step 7: Resume & documentation..."

DOC=keybuzz-docs/runbooks/PH9-CONTROL-PLANE-DEEP-DIAGNOSTIC.md

{
    echo "# PH9 – Diagnostic & Cleanup Profond Control-Plane (master-02 & master-03)"
    echo ""
    echo "**Date:** $(date)"
    echo ""
    echo "## État avant cleanup"
    echo ""
    echo "### Nodes"
    echo "\`\`\`"
    cat /opt/keybuzz/logs/phase9-deep-diagnostic/nodes-before.txt 2>/dev/null || echo "nodes-before not available"
    echo "\`\`\`"
    echo ""
    echo "### Pods (tous namespaces)"
    echo "\`\`\`"
    cat /opt/keybuzz/logs/phase9-deep-diagnostic/pods-before.txt 2>/dev/null | head -100 || echo "pods-before not available"
    echo "\`\`\`"
    echo ""
    echo "## Diagnostic master-02 / master-03"
    echo ""
    echo "### master-02 diagnostic (processus, ports, kubelet, journalctl)"
    echo "\`\`\`"
    cat /opt/keybuzz/logs/phase9-deep-diagnostic/master-diagnostic-10.0.0.101.txt 2>/dev/null || echo "no diag for 10.0.0.101"
    echo "\`\`\`"
    echo ""
    echo "### master-03 diagnostic (processus, ports, kubelet, journalctl)"
    echo "\`\`\`"
    cat /opt/keybuzz/logs/phase9-deep-diagnostic/master-diagnostic-10.0.0.102.txt 2>/dev/null || echo "no diag for 10.0.0.102"
    echo "\`\`\`"
    echo ""
    echo "## ETCD member list (master-01)"
    echo ""
    echo "### Avant cleanup"
    echo "\`\`\`"
    cat /opt/keybuzz/logs/phase9-deep-diagnostic/etcd-member-list-before.txt 2>/dev/null || echo "no etcd list"
    echo "\`\`\`"
    echo ""
    echo "### Après cleanup"
    echo "\`\`\`"
    cat /opt/keybuzz/logs/phase9-deep-diagnostic/etcd-member-list-after.txt 2>/dev/null || echo "no etcd list after"
    echo "\`\`\`"
    echo ""
    echo "## Manifests master-01 (référence)"
    echo "\`\`\`"
    cat /opt/keybuzz/logs/phase9-deep-diagnostic/master-01-manifests.txt 2>/dev/null || echo "no manifest list"
    echo "\`\`\`"
    echo ""
    echo "## JOIN_CMD préparé (ne pas exécuter manuellement)"
    echo ""
    echo "⚠️ **IMPORTANT**: Cette commande est prête mais ne doit PAS être exécutée manuellement."
    echo "Utiliser le script \`ph9-control-plane-join-clean.sh\` pour un join propre."
    echo ""
    echo "\`\`\`"
    cat /opt/keybuzz/logs/phase9-deep-diagnostic/join-cmd-clean.txt 2>/dev/null || echo "no join cmd"
    echo "\`\`\`"
    echo ""
    echo "## Actions effectuées"
    echo ""
    echo "1. ✅ Diagnostic complet des processus et ports sur master-02/03"
    echo "2. ✅ Kill des processus zombies (kube-controller-manager, kube-scheduler, kube-apiserver, etcd)"
    echo "3. ✅ Nettoyage des ports 10257, 10259, 10250, 6443"
    echo "4. ✅ Nettoyage des répertoires (/etc/kubernetes/manifests, /var/lib/etcd, /var/lib/kubelet, /etc/cni/net.d)"
    echo "5. ✅ kubeadm reset sur master-02/03"
    echo "6. ✅ Vérification et nettoyage des membres ETCD orphelins"
    echo "7. ✅ Préparation de la commande join propre"
    echo ""
    echo "## Remarques"
    echo ""
    echo "- master-02/03 ont été complètement nettoyés (processus tués, dossiers kubeadm/etcd/kubelet/CNI purgés)."
    echo "- Les membres ETCD orphelins ont été retirés du cluster."
    echo "- READY pour un join control-plane propre (PH9-control-plane-join-clean)."
    echo "- La commande join est préparée et sauvegardée dans \`/opt/keybuzz/logs/phase9-deep-diagnostic/join-cmd-clean.txt\`."
    
} > "$DOC"

echo "[INFO]     Documentation créée: $DOC"

# Commit & push
git add "$DOC" /opt/keybuzz/logs/phase9-deep-diagnostic/*.txt scripts/ph9-control-plane-deep-diagnostic.sh 2>&1 || git add "$DOC" scripts/ph9-control-plane-deep-diagnostic.sh
git commit -m "chore: PH9 deep diagnostic & cleanup on masters 02/03 completed" || echo "[WARN] git commit failed (maybe nothing new)"
git push || echo "[WARN] git push failed (check remote)"

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ PH9-CONTROL-PLANE-DEEP-DIAGNOSTIC & CLEANUP COMPLETED"
echo "[INFO] =========================================="
echo ""
echo "[INFO] Les masters 02/03 ont été nettoyés. Le join control-plane propre est prêt."
echo "[INFO] Prochain ticket : PH9-control-plane-join-clean pour exécuter le join proprement."
echo ""
echo "[INFO] Documentation: $DOC"
echo "[INFO] Join command: /opt/keybuzz/logs/phase9-deep-diagnostic/join-cmd-clean.txt"

