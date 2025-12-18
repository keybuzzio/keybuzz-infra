#!/bin/bash
# PH9.5 Fix kube-apiserver timeout on master-03
# Augmente les timeouts ETCD pour éviter la race condition

set -e

MASTER3=10.0.0.102
MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"

echo "=============================================="
echo "PH9.5 FIX APISERVER TIMEOUT - MASTER-03"
echo "Date: $(date)"
echo "=============================================="

echo ""
echo "=== ÉTAPE 1: Backup du manifest actuel ==="
ssh root@$MASTER3 "cp $MANIFEST ${MANIFEST}.backup"
echo "Backup créé: ${MANIFEST}.backup"

echo ""
echo "=== ÉTAPE 2: Lecture des paramètres ETCD actuels ==="
ssh root@$MASTER3 "grep -E 'etcd' $MANIFEST || echo 'No etcd params found'"

echo ""
echo "=== ÉTAPE 3: Ajout des paramètres de timeout ETCD ==="
# Ajouter des paramètres pour augmenter la tolérance aux délais ETCD
ssh root@$MASTER3 bash <<'MODIFY_EOF'
MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"

# Vérifier si les paramètres existent déjà
if grep -q "etcd-compaction-interval" $MANIFEST; then
    echo "Paramètres ETCD déjà présents"
else
    # Ajouter après la ligne --etcd-servers
    sed -i '/--etcd-servers=/a\    - --etcd-compaction-interval=0' $MANIFEST
fi

# Ajouter request-timeout si absent
if ! grep -q "request-timeout" $MANIFEST; then
    sed -i '/--etcd-servers=/a\    - --request-timeout=2m0s' $MANIFEST
fi

# Ajouter default-not-ready-toleration-seconds si absent
if ! grep -q "default-not-ready-toleration-seconds" $MANIFEST; then
    sed -i '/--etcd-servers=/a\    - --default-not-ready-toleration-seconds=60' $MANIFEST
fi

echo "Paramètres ajoutés"
MODIFY_EOF

echo ""
echo "=== ÉTAPE 4: Vérification des paramètres ajoutés ==="
ssh root@$MASTER3 "grep -E 'etcd|timeout|toleration' $MANIFEST | head -10"

echo ""
echo "=== ÉTAPE 5: Redémarrage de kubelet pour appliquer ==="
ssh root@$MASTER3 "systemctl restart kubelet"
echo "Kubelet redémarré"

echo ""
echo "=== ÉTAPE 6: Attente 90 secondes ==="
sleep 90

echo ""
echo "=== ÉTAPE 7: Vérification du kube-apiserver ==="
export KUBECONFIG=/root/.kube/config
kubectl get pods -n kube-system | grep kube-apiserver-k8s-master-03

echo ""
echo "=============================================="
echo "PH9.5 FIX APISERVER TIMEOUT TERMINÉ"
echo "=============================================="

