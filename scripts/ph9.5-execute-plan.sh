#!/bin/bash
# PH9.5 EXECUTE PLAN - Réparation complète ETCD HA (3 masters)
# Ce script exécute les phases 0-9 du plan SRE

set -e

cd /opt/keybuzz/keybuzz-infra

LOG_DIR="/opt/keybuzz/logs/phase9.5"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ph9.5-execute-plan.log"

exec > >(tee -a "$LOG_FILE") 2>&1

export KUBECONFIG=/root/.kube/config

echo "=============================================="
echo "PH9.5 EXECUTE PLAN - RÉPARATION ETCD HA"
echo "Date: $(date)"
echo "=============================================="
echo ""

MASTER1=10.0.0.100
MASTER2=10.0.0.101
MASTER3=10.0.0.102

# ============================================
# PHASE 0 : Vérifications préalables
# ============================================

echo "=============================================="
echo "PHASE 0: Vérifications préalables"
echo "=============================================="

echo "[INFO] Vérification des nodes..."
kubectl get nodes -o wide | tee "$LOG_DIR/nodes-before.txt"

echo ""
echo "[INFO] Vérification des pods kube-system..."
kubectl get pods -n kube-system | tee "$LOG_DIR/kube-system-before.txt"

echo ""
echo "[INFO] Vérification des certificats peer sur master-02..."
ssh root@$MASTER2 "openssl x509 -in /etc/kubernetes/pki/etcd/peer.crt -noout -text 2>/dev/null | grep -A2 'Subject Alternative Name' || echo 'No peer cert found'" | tee "$LOG_DIR/master02-peer-cert.txt"

echo ""
echo "[INFO] Vérification ETCD actuel sur master-01..."
ssh root@$MASTER1 bash <<'ETCD_CHECK_EOF' | tee "$LOG_DIR/etcd-members-before.txt"
export ETCDCTL_API=3
OPTS="--endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key"
etcdctl $OPTS member list 2>&1 || echo "ERROR: etcdctl failed"
ETCD_CHECK_EOF

echo ""
echo "[INFO] Phase 0 terminée"
echo ""

# ============================================
# PHASE 1 : Nettoyer les membres ETCD orphelins et préparer master-02
# ============================================

echo "=============================================="
echo "PHASE 1: Nettoyage ETCD et préparation master-02"
echo "=============================================="

echo "[INFO] Identification des membres ETCD à supprimer..."
ETCD_MEMBERS=$(ssh root@$MASTER1 bash <<'MEMBER_LIST_EOF'
export ETCDCTL_API=3
OPTS="--endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key"
etcdctl $OPTS member list 2>/dev/null
MEMBER_LIST_EOF
)
echo "$ETCD_MEMBERS" | tee "$LOG_DIR/etcd-members-list.txt"

# Supprimer les membres qui ne sont pas master-01
echo "[INFO] Suppression des membres ETCD orphelins (si présents)..."
ssh root@$MASTER1 bash <<'REMOVE_MEMBERS_EOF'
export ETCDCTL_API=3
OPTS="--endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key"

# Lister les membres
MEMBERS=$(etcdctl $OPTS member list 2>/dev/null)
echo "Current members:"
echo "$MEMBERS"

# Pour chaque membre qui n'est pas k8s-master-01, le supprimer
echo "$MEMBERS" | while read line; do
    if echo "$line" | grep -v "k8s-master-01" | grep -q "k8s-master"; then
        MEMBER_ID=$(echo "$line" | cut -d',' -f1)
        MEMBER_NAME=$(echo "$line" | grep -oP 'k8s-master-\d+')
        echo "Removing orphan member: $MEMBER_NAME (ID: $MEMBER_ID)"
        etcdctl $OPTS member remove $MEMBER_ID 2>&1 || echo "Failed to remove $MEMBER_ID"
    fi
done

echo "Members after cleanup:"
etcdctl $OPTS member list 2>/dev/null
REMOVE_MEMBERS_EOF

echo ""
echo "[INFO] Préparation de master-02 pour un join propre..."
ssh root@$MASTER2 bash <<'PREP_MASTER02_EOF'
echo "[master-02] Arrêt de kubelet..."
systemctl stop kubelet || true

echo "[master-02] Suppression des manifests..."
rm -rf /etc/kubernetes/manifests/*

echo "[master-02] Suppression des données ETCD..."
rm -rf /var/lib/etcd/*

echo "[master-02] Suppression des certificats ETCD..."
rm -rf /etc/kubernetes/pki/etcd/*

echo "[master-02] Suppression du kubelet PKI..."
rm -rf /var/lib/kubelet/pki/*

echo "[master-02] Redémarrage de containerd..."
systemctl restart containerd
sleep 3

echo "[master-02] Préparation terminée"
ls -la /etc/kubernetes/
ls -la /var/lib/etcd/ || echo "etcd dir empty"
PREP_MASTER02_EOF

echo ""
echo "[INFO] Phase 1 terminée"
echo ""

# ============================================
# PHASE 2 : Join master-02 avec IP interne
# ============================================

echo "=============================================="
echo "PHASE 2: Join master-02 au control-plane"
echo "=============================================="

echo "[INFO] Génération du CERT_KEY sur master-01..."
CERT_KEY=$(ssh root@$MASTER1 "kubeadm init phase upload-certs --upload-certs 2>&1 | tail -n1 | tr -d '\r' | grep -E '^[a-f0-9]{64}$'")
if [ -z "$CERT_KEY" ]; then
    echo "[ERROR] Failed to get CERT_KEY"
    exit 1
fi
echo "CERT_KEY=$CERT_KEY" | tee "$LOG_DIR/cert-key-master02.txt"

echo ""
echo "[INFO] Création d'un nouveau token..."
TOKEN=$(ssh root@$MASTER1 "kubeadm token create --ttl 2h 2>/dev/null")
if [ -z "$TOKEN" ]; then
    echo "[ERROR] Failed to create token"
    exit 1
fi
echo "TOKEN=$TOKEN" | tee "$LOG_DIR/token-master02.txt"

echo ""
echo "[INFO] Construction de la commande JOIN pour master-02..."
# Utiliser --apiserver-advertise-address pour forcer l'IP interne
JOIN_CMD="kubeadm join $MASTER1:6443 --token $TOKEN --discovery-token-unsafe-skip-ca-verification --control-plane --certificate-key $CERT_KEY --apiserver-advertise-address=$MASTER2"
echo "$JOIN_CMD" | tee "$LOG_DIR/join-cmd-master02.txt"

echo ""
echo "[INFO] Exécution du JOIN sur master-02..."
ssh root@$MASTER2 "$JOIN_CMD" 2>&1 | tee "$LOG_DIR/master02-join.log"

JOIN_RESULT=${PIPESTATUS[0]}
if [ $JOIN_RESULT -ne 0 ]; then
    echo "[ERROR] master-02 join failed with exit code $JOIN_RESULT"
    echo "[ERROR] Check logs in $LOG_DIR/master02-join.log"
    echo ""
    echo "=== Last 50 lines of join log ==="
    tail -50 "$LOG_DIR/master02-join.log"
    exit 1
fi

echo ""
echo "[INFO] Attente de 90 secondes pour stabilisation..."
sleep 90

echo ""
echo "[INFO] Vérification de master-02 après join..."
ssh root@$MASTER2 bash <<'POST_JOIN_02_EOF' | tee "$LOG_DIR/master02-postjoin.txt"
echo "=== systemctl status kubelet ==="
systemctl status kubelet --no-pager | head -20 || true

echo ""
echo "=== /etc/kubernetes/manifests/ ==="
ls -la /etc/kubernetes/manifests/ || true

echo ""
echo "=== /etc/kubernetes/pki/etcd/ ==="
ls -la /etc/kubernetes/pki/etcd/ || true

echo ""
echo "=== ETCD manifest peer URLs ==="
grep -E "peer-urls|advertise" /etc/kubernetes/manifests/etcd.yaml 2>/dev/null | head -10 || true
POST_JOIN_02_EOF

echo ""
echo "[INFO] Vérification des nodes après join master-02..."
kubectl get nodes -o wide | tee "$LOG_DIR/nodes-after-master02.txt"

echo ""
echo "[INFO] Phase 2 terminée"
echo ""

# ============================================
# PHASE 3 : Vérification ETCD avec 2 membres
# ============================================

echo "=============================================="
echo "PHASE 3: Vérification ETCD (2 membres)"
echo "=============================================="

echo "[INFO] Attente de 60 secondes supplémentaires..."
sleep 60

echo ""
echo "[INFO] Vérification des membres ETCD..."
ssh root@$MASTER1 bash <<'ETCD_CHECK2_EOF' | tee "$LOG_DIR/etcd-after-master02.txt"
export ETCDCTL_API=3
OPTS="--endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key"
echo "=== ETCD member list ==="
etcdctl $OPTS member list 2>&1

echo ""
echo "=== ETCD endpoint health ==="
etcdctl $OPTS endpoint health 2>&1 || true
ETCD_CHECK2_EOF

echo ""
echo "[INFO] Vérification des pods ETCD et API server..."
kubectl get pods -n kube-system | grep -E 'etcd-|kube-apiserver-' | tee "$LOG_DIR/control-plane-pods-after-master02.txt"

# Vérifier si etcd-k8s-master-02 est Running
ETCD02_STATUS=$(kubectl get pods -n kube-system etcd-k8s-master-02 -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
if [ "$ETCD02_STATUS" != "Running" ]; then
    echo "[WARN] etcd-k8s-master-02 is not Running (status: $ETCD02_STATUS)"
    echo "[INFO] Checking etcd logs on master-02..."
    kubectl logs -n kube-system etcd-k8s-master-02 --tail=30 2>&1 | tee "$LOG_DIR/etcd-master02-logs.txt" || true
fi

echo ""
echo "[INFO] Phase 3 terminée"
echo ""

# ============================================
# PHASE 4 : Join master-03
# ============================================

echo "=============================================="
echo "PHASE 4: Join master-03 au control-plane"
echo "=============================================="

echo "[INFO] Préparation de master-03 pour un join propre..."
ssh root@$MASTER3 bash <<'PREP_MASTER03_EOF'
echo "[master-03] Arrêt de kubelet..."
systemctl stop kubelet || true

echo "[master-03] Suppression des manifests..."
rm -rf /etc/kubernetes/manifests/*

echo "[master-03] Suppression des données ETCD..."
rm -rf /var/lib/etcd/*

echo "[master-03] Suppression des certificats ETCD..."
rm -rf /etc/kubernetes/pki/etcd/*

echo "[master-03] Suppression du kubelet PKI..."
rm -rf /var/lib/kubelet/pki/*

echo "[master-03] Redémarrage de containerd..."
systemctl restart containerd
sleep 3

echo "[master-03] Préparation terminée"
PREP_MASTER03_EOF

echo ""
echo "[INFO] Régénération du CERT_KEY pour master-03..."
CERT_KEY=$(ssh root@$MASTER1 "kubeadm init phase upload-certs --upload-certs 2>&1 | tail -n1 | tr -d '\r' | grep -E '^[a-f0-9]{64}$'")
if [ -z "$CERT_KEY" ]; then
    echo "[ERROR] Failed to get CERT_KEY for master-03"
    exit 1
fi
echo "CERT_KEY=$CERT_KEY" | tee "$LOG_DIR/cert-key-master03.txt"

echo ""
echo "[INFO] Construction de la commande JOIN pour master-03..."
JOIN_CMD="kubeadm join $MASTER1:6443 --token $TOKEN --discovery-token-unsafe-skip-ca-verification --control-plane --certificate-key $CERT_KEY --apiserver-advertise-address=$MASTER3"
echo "$JOIN_CMD" | tee "$LOG_DIR/join-cmd-master03.txt"

echo ""
echo "[INFO] Exécution du JOIN sur master-03..."
ssh root@$MASTER3 "$JOIN_CMD" 2>&1 | tee "$LOG_DIR/master03-join.log"

JOIN_RESULT=${PIPESTATUS[0]}
if [ $JOIN_RESULT -ne 0 ]; then
    echo "[ERROR] master-03 join failed with exit code $JOIN_RESULT"
    echo "[ERROR] Check logs in $LOG_DIR/master03-join.log"
    echo ""
    echo "=== Last 50 lines of join log ==="
    tail -50 "$LOG_DIR/master03-join.log"
    exit 1
fi

echo ""
echo "[INFO] Attente de 90 secondes pour stabilisation..."
sleep 90

echo ""
echo "[INFO] Vérification de master-03 après join..."
ssh root@$MASTER3 bash <<'POST_JOIN_03_EOF' | tee "$LOG_DIR/master03-postjoin.txt"
echo "=== systemctl status kubelet ==="
systemctl status kubelet --no-pager | head -20 || true

echo ""
echo "=== /etc/kubernetes/manifests/ ==="
ls -la /etc/kubernetes/manifests/ || true

echo ""
echo "=== /etc/kubernetes/pki/etcd/ ==="
ls -la /etc/kubernetes/pki/etcd/ || true
POST_JOIN_03_EOF

echo ""
echo "[INFO] Phase 4 terminée"
echo ""

# ============================================
# PHASE 5 : Validation du control-plane complet
# ============================================

echo "=============================================="
echo "PHASE 5: Validation du control-plane complet"
echo "=============================================="

echo "[INFO] Attente de 60 secondes supplémentaires..."
sleep 60

echo ""
echo "[INFO] Vérification des nodes..."
kubectl get nodes -o wide | tee "$LOG_DIR/nodes-control-plane-final.txt"

echo ""
echo "[INFO] Vérification ETCD final (3 membres attendus)..."
ssh root@$MASTER1 bash <<'ETCD_FINAL_EOF' | tee "$LOG_DIR/etcd-final.txt"
export ETCDCTL_API=3
OPTS="--endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key"
echo "=== ETCD member list ==="
etcdctl $OPTS member list 2>&1

echo ""
echo "=== ETCD endpoint status ==="
etcdctl $OPTS endpoint status --cluster 2>&1 || true
ETCD_FINAL_EOF

echo ""
echo "[INFO] Vérification des pods control-plane..."
kubectl get pods -n kube-system | grep -E 'etcd-|kube-apiserver-|kube-controller-|kube-scheduler-' | tee "$LOG_DIR/control-plane-pods-final.txt"

echo ""
echo "[INFO] Phase 5 terminée"
echo ""

# ============================================
# PHASE 6 : Stabiliser Calico
# ============================================

echo "=============================================="
echo "PHASE 6: Stabiliser Calico"
echo "=============================================="

echo "[INFO] Suppression des pods Calico pour recréation..."
kubectl delete pods -n kube-system -l k8s-app=calico-node --force --grace-period=0 2>&1 | grep -v "not found" || true
kubectl delete pods -n kube-system -l k8s-app=calico-kube-controllers --force --grace-period=0 2>&1 | grep -v "not found" || true

echo ""
echo "[INFO] Attente de 90 secondes..."
sleep 90

echo ""
echo "[INFO] Vérification des pods Calico..."
kubectl get pods -n kube-system -l k8s-app=calico-node -o wide | tee "$LOG_DIR/calico-after.txt"
kubectl get pods -n kube-system -l k8s-app=calico-kube-controllers -o wide | tee -a "$LOG_DIR/calico-after.txt"

echo ""
echo "[INFO] Phase 6 terminée"
echo ""

# ============================================
# PHASE 7 : Stabiliser kube-proxy
# ============================================

echo "=============================================="
echo "PHASE 7: Stabiliser kube-proxy"
echo "=============================================="

echo "[INFO] Suppression des pods kube-proxy pour recréation..."
kubectl delete pods -n kube-system -l k8s-app=kube-proxy --force --grace-period=0 2>&1 | grep -v "not found" || true

echo ""
echo "[INFO] Attente de 60 secondes..."
sleep 60

echo ""
echo "[INFO] Vérification des pods kube-proxy..."
kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide | tee "$LOG_DIR/kube-proxy-after.txt"

echo ""
echo "[INFO] Phase 7 terminée"
echo ""

# ============================================
# PHASE 8 : Réparer ESO
# ============================================

echo "=============================================="
echo "PHASE 8: Réparer ESO"
echo "=============================================="

echo "[INFO] Suppression des pods ESO pour recréation..."
kubectl delete pods -n external-secrets --all --force --grace-period=0 2>&1 | grep -v "not found" || true

echo ""
echo "[INFO] Attente de 90 secondes..."
sleep 90

echo ""
echo "[INFO] Vérification des pods ESO..."
kubectl get pods -n external-secrets -o wide | tee "$LOG_DIR/eso-after.txt"

echo ""
echo "[INFO] Logs du webhook ESO..."
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets-webhook --tail=30 2>&1 | tee "$LOG_DIR/eso-webhook-logs.txt" || echo "No webhook logs"

echo ""
echo "[INFO] Phase 8 terminée"
echo ""

# ============================================
# PHASE 9 : Test ExternalSecret et documentation
# ============================================

echo "=============================================="
echo "PHASE 9: Test ExternalSecret et documentation"
echo "=============================================="

echo "[INFO] Réapplication de l'ExternalSecret de test..."
if [ -f k8s/tests/test-redis-externalsecret.yaml ]; then
    kubectl apply -f k8s/tests/test-redis-externalsecret.yaml 2>&1 | tee "$LOG_DIR/externalsecret-apply.log"
else
    echo "[WARN] test-redis-externalsecret.yaml not found"
fi

echo ""
echo "[INFO] Attente de la synchronisation du secret (max 2 minutes)..."
for i in {1..24}; do
    if kubectl get secret redis-test-secret -n keybuzz-system >/dev/null 2>&1; then
        echo "[INFO] redis-test-secret found!"
        break
    fi
    echo "[INFO] Tentative $i/24..."
    sleep 5
done

echo ""
echo "[INFO] Vérification du secret redis-test-secret..."
kubectl get secret redis-test-secret -n keybuzz-system -o yaml 2>&1 | tee "$LOG_DIR/redis-secret.txt" || echo "redis-test-secret NOT FOUND"

echo ""
echo "[INFO] État final des nodes..."
kubectl get nodes -o wide | tee "$LOG_DIR/nodes-final.txt"

echo ""
echo "[INFO] État final des pods kube-system..."
kubectl get pods -n kube-system -o wide | tee "$LOG_DIR/kube-system-final.txt"

echo ""
echo "[INFO] État final des pods external-secrets..."
kubectl get pods -n external-secrets -o wide | tee "$LOG_DIR/eso-final.txt"

# ============================================
# DOCUMENTATION
# ============================================

echo ""
echo "[INFO] Mise à jour de la documentation..."

DOC=keybuzz-docs/runbooks/PH9-FINAL-VALIDATION.md

{
    echo "# PH9 FINAL VALIDATION — Kubernetes HA (3 masters)"
    echo ""
    echo "**Date:** $(date)"
    echo "**Script:** ph9.5-execute-plan.sh"
    echo ""
    echo "## Résumé"
    echo ""
    NODES_READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready" || echo "0")
    ETCD_RUNNING=$(kubectl get pods -n kube-system -l component=etcd --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    API_RUNNING=$(kubectl get pods -n kube-system -l component=kube-apiserver --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    CALICO_RUNNING=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    PROXY_RUNNING=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    ESO_RUNNING=$(kubectl get pods -n external-secrets -l app.kubernetes.io/name=external-secrets --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    
    echo "| Composant | État |"
    echo "|-----------|------|"
    echo "| Nodes Ready | $NODES_READY/8 |"
    echo "| ETCD Running | $ETCD_RUNNING/3 |"
    echo "| API Servers Running | $API_RUNNING/3 |"
    echo "| Calico Running | $CALICO_RUNNING/8 |"
    echo "| kube-proxy Running | $PROXY_RUNNING/8 |"
    echo "| ESO Running | $ESO_RUNNING/1 |"
    echo ""
    echo "## Nodes"
    echo ""
    echo "\`\`\`"
    kubectl get nodes -o wide 2>&1
    echo "\`\`\`"
    echo ""
    echo "## ETCD Members"
    echo ""
    echo "\`\`\`"
    cat "$LOG_DIR/etcd-final.txt" 2>/dev/null || echo "ETCD check not available"
    echo "\`\`\`"
    echo ""
    echo "## Control Plane Pods"
    echo ""
    echo "\`\`\`"
    kubectl get pods -n kube-system | grep -E 'etcd-|kube-apiserver-|kube-controller-|kube-scheduler-' 2>&1
    echo "\`\`\`"
    echo ""
    echo "## Calico Pods"
    echo ""
    echo "\`\`\`"
    kubectl get pods -n kube-system -l k8s-app=calico-node 2>&1
    echo "\`\`\`"
    echo ""
    echo "## kube-proxy Pods"
    echo ""
    echo "\`\`\`"
    kubectl get pods -n kube-system -l k8s-app=kube-proxy 2>&1
    echo "\`\`\`"
    echo ""
    echo "## ESO Pods"
    echo ""
    echo "\`\`\`"
    kubectl get pods -n external-secrets 2>&1
    echo "\`\`\`"
    echo ""
    echo "## redis-test-secret"
    echo ""
    echo "\`\`\`"
    kubectl get secret redis-test-secret -n keybuzz-system 2>&1 || echo "NOT FOUND"
    echo "\`\`\`"
    echo ""
    echo "## Logs"
    echo ""
    echo "Tous les logs sont disponibles dans: /opt/keybuzz/logs/phase9.5/"
    
} > "$DOC"

echo "[INFO] Documentation mise à jour: $DOC"

# Commit & push
git add "$DOC" 2>/dev/null || true
git add scripts/ph9.5-execute-plan.sh 2>/dev/null || true
git commit -m "fix: PH9.5 control-plane repair - ETCD HA restoration" 2>&1 || echo "[WARN] git commit failed"
git push 2>&1 || echo "[WARN] git push failed"

echo ""
echo "=============================================="
echo "✅ PH9.5 EXECUTE PLAN TERMINÉ"
echo "=============================================="
echo ""
echo "Résumé:"
echo "- Nodes Ready: $NODES_READY/8"
echo "- ETCD Running: $ETCD_RUNNING/3"
echo "- API Servers: $API_RUNNING/3"
echo "- Calico: $CALICO_RUNNING/8"
echo "- kube-proxy: $PROXY_RUNNING/8"
echo "- ESO: $ESO_RUNNING/1"
echo ""
echo "Logs: $LOG_DIR"
echo "Documentation: $DOC"

