#!/bin/bash
# Check ETCD status from master-01

ssh root@10.0.0.100 bash <<'EOF'
ETCD_CTR=$(crictl ps --name etcd -q 2>/dev/null | head -1)
echo "ETCD container: $ETCD_CTR"
echo ""
echo "=== ETCD member list ==="
crictl exec $ETCD_CTR etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key member list 2>&1
echo ""
echo "=== ETCD endpoint status ==="
crictl exec $ETCD_CTR etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key endpoint status --cluster 2>&1
EOF

