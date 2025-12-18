#!/bin/bash
set -e

echo "[INFO] Fixing containerd configuration on all nodes..."

NODES=(
    "10.0.0.100"  # master-01
    "10.0.0.101"  # master-02
    "10.0.0.102"  # master-03
    "10.0.0.103"  # worker-01
    "10.0.0.104"  # worker-02
    "10.0.0.105"  # worker-03
    "10.0.0.106"  # worker-04
    "10.0.0.107"  # worker-05
)

for ip in "${NODES[@]}"; do
    echo "[INFO] Fixing containerd config on $ip..."
    ssh -o StrictHostKeyChecking=no root@"$ip" bash -c '
        set -e
        if [ ! -f /etc/containerd/config.toml ]; then
            echo "[INFO] Creating containerd config..."
            mkdir -p /etc/containerd
            containerd config default | tee /etc/containerd/config.toml > /dev/null
        fi
        echo "[INFO] Setting SystemdCgroup = true..."
        sed -i "s/SystemdCgroup = false/SystemdCgroup = true/" /etc/containerd/config.toml
        grep "SystemdCgroup = true" /etc/containerd/config.toml || echo "[WARN] SystemdCgroup setting not found or incorrect"
        echo "[INFO] Restarting containerd..."
        systemctl restart containerd
        sleep 3
        if systemctl is-active --quiet containerd; then
            echo "[OK] containerd is running"
        else
            echo "[ERROR] containerd failed to start!"
            systemctl status containerd --no-pager | head -10
            exit 1
        fi
    ' || {
        echo "[ERROR] Failed to fix containerd on $ip"
        exit 1
    }
done

echo "[INFO] Testing containerd CRI on master-01..."
ssh -o StrictHostKeyChecking=no root@10.0.0.100 bash << 'ENDRSCRIPT'
    crictl version 2>&1 | head -5 || {
        echo "[ERROR] crictl test failed!"
        exit 1
    }
    echo "[OK] containerd CRI is working"
ENDRSCRIPT

echo "[INFO] All nodes fixed successfully!"

