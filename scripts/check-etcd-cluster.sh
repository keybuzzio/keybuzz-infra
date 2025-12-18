#!/bin/bash
# Check ETCD cluster status

echo "=== ETCD Member List ==="
ssh root@10.0.0.100 bash << 'EOF'
ETCD_CTR=$(crictl ps --name etcd -q 2>/dev/null | head -1)
if [ -z "$ETCD_CTR" ]; then
    echo "ERROR: ETCD container not found"
    exit 1
fi
crictl exec $ETCD_CTR etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    member list -w table
echo ""
echo "=== ETCD Endpoint Status ==="
crictl exec $ETCD_CTR etcdctl \
    --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    endpoint status -w table
EOF

echo ""
echo "=== ETCD Endpoint Health ==="
ssh root@10.0.0.100 bash << 'EOF'
ETCD_CTR=$(crictl ps --name etcd -q 2>/dev/null | head -1)
crictl exec $ETCD_CTR etcdctl \
    --endpoints=https://10.0.0.100:2379,https://10.0.0.101:2379,https://10.0.0.102:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt \
    --cert=/etc/kubernetes/pki/etcd/server.crt \
    --key=/etc/kubernetes/pki/etcd/server.key \
    endpoint health -w table
EOF

