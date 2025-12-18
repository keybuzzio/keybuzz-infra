#!/bin/bash
# PH9 - Diagnostic de l'API server

echo "=== Containers apiserver ==="
ssh root@10.0.0.100 'crictl ps -a | grep apiserver'

echo ""
echo "=== ETCD container ==="
ssh root@10.0.0.100 'crictl ps -a | grep etcd'

echo ""
echo "=== Derniers logs apiserver ==="
APISERVER_CTR=$(ssh root@10.0.0.100 'crictl ps -a | grep apiserver | head -1 | awk "{print \$1}"')
if [ -n "$APISERVER_CTR" ]; then
    ssh root@10.0.0.100 "crictl logs $APISERVER_CTR 2>&1 | tail -50"
fi

echo ""
echo "=== Port 6443 ==="
ssh root@10.0.0.100 'ss -tlnp | grep 6443'

echo ""
echo "=== Test connexion API ==="
timeout 5 curl -k https://10.0.0.100:6443/healthz 2>&1 || echo "API not responding"

