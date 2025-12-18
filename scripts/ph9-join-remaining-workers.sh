#!/bin/bash
# PH9 - Join des workers manquants

export KUBECONFIG=/root/.kube/config

echo "=== Join des workers manquants ==="

# Créer un nouveau token
TOKEN=$(ssh root@10.0.0.100 "kubeadm token create --ttl 4h")
echo "TOKEN: $TOKEN"

# Hash
HASH=$(ssh root@10.0.0.100 "openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'")
echo "HASH: sha256:$HASH"

# Join des workers manquants
for ip in 10.0.0.113 10.0.0.114; do
    echo ""
    echo "=== Joining worker $ip ==="
    ssh root@$ip bash << EOF
systemctl enable kubelet
systemctl start kubelet
kubeadm join 10.0.0.100:6443 --token $TOKEN --discovery-token-ca-cert-hash sha256:$HASH
EOF
done

echo ""
echo "=== Attente 60s ==="
sleep 60

echo ""
echo "=== État des nodes ==="
kubectl get nodes

