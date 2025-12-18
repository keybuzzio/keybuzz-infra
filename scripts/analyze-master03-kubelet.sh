#!/bin/bash
# Analyze kubelet issues on master-03

echo "=== Kubelet Status master-03 ==="
ssh root@10.0.0.102 'systemctl status kubelet --no-pager | head -20'

echo ""
echo "=== Kubelet Logs (sandbox/error) ==="
ssh root@10.0.0.102 'journalctl -u kubelet --since "10 minutes ago" 2>/dev/null | grep -iE "sandbox|failed|error|kill" | tail -40'

echo ""
echo "=== Containerd Status ==="
ssh root@10.0.0.102 'systemctl status containerd --no-pager | head -10'

echo ""
echo "=== Containerd cgroup driver ==="
ssh root@10.0.0.102 'grep -i systemdcgroup /etc/containerd/config.toml'

echo ""
echo "=== Kubelet cgroup driver ==="
ssh root@10.0.0.102 'cat /var/lib/kubelet/config.yaml 2>/dev/null | grep -i cgroup'

echo ""
echo "=== CNI configuration ==="
ssh root@10.0.0.102 'ls -la /etc/cni/net.d/'

