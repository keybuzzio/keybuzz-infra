#!/bin/bash
# PH9 - Vérification directe sur master-01

echo "=== Containers sur master-01 ==="
ssh root@10.0.0.100 'crictl ps' || echo "SSH failed"

echo ""
echo "=== Kubelet status ==="
ssh root@10.0.0.100 'systemctl status kubelet --no-pager | head -30' || echo "SSH failed"

echo ""
echo "=== Port 6443 ==="
ssh root@10.0.0.100 'ss -tlnp | grep 6443' || echo "SSH failed"

