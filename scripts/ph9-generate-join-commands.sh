#!/bin/bash
set -e

echo "[INFO] Generating join commands on master-01..."

ssh -o StrictHostKeyChecking=no root@10.0.0.100 << 'ENDRSCRIPT'
    set -e
    export KUBECONFIG=/etc/kubernetes/admin.conf
    
    echo "[INFO] Uploading certificates..."
    CERT_KEY=$(kubeadm init phase upload-certs --upload-certs 2>/dev/null | tail -1)
    
    echo "[INFO] Creating token and getting join command..."
    JOIN_OUTPUT=$(kubeadm token create --print-join-command 2>/dev/null)
    TOKEN=$(echo "$JOIN_OUTPUT" | awk '{print $5}')
    HASH=$(echo "$JOIN_OUTPUT" | awk '{print $7}')
    
    echo "[INFO] Creating control plane join command..."
    echo "kubeadm join 10.0.0.100:6443 --token $TOKEN --discovery-token-ca-cert-hash $HASH --control-plane --certificate-key $CERT_KEY" > /root/k8s_join_control_plane.txt
    
    echo "[INFO] Creating worker join command..."
    echo "$JOIN_OUTPUT" > /root/k8s_join_workers.txt
    
    echo "[OK] Join commands created:"
    echo "Control plane:"
    cat /root/k8s_join_control_plane.txt
    echo ""
    echo "Workers:"
    cat /root/k8s_join_workers.txt
ENDRSCRIPT

echo "[INFO] Done!"

