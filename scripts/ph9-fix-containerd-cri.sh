#!/bin/bash
set -e

echo "[INFO] Fixing containerd CRI configuration on all nodes..."

NODES=(
    "10.0.0.100"  # master-01
    "10.0.0.101"  # master-02
    "10.0.0.102"  # master-03
    "10.0.0.110"  # worker-01
    "10.0.0.111"  # worker-02
    "10.0.0.112"  # worker-03
    "10.0.0.113"  # worker-04
    "10.0.0.114"  # worker-05
)

for ip in "${NODES[@]}"; do
    echo "[INFO] Fixing containerd on $ip..."
    ssh -o StrictHostKeyChecking=no root@"$ip" << ENDRSCRIPT
        set -e
        echo "[INFO] Backing up old config..."
        mv /etc/containerd/config.toml /etc/containerd/config.toml.bak 2>/dev/null || true
        echo "[INFO] Generating new containerd config..."
        containerd config default | tee /etc/containerd/config.toml > /dev/null
        echo "[INFO] Enabling SystemdCgroup..."
        sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
        echo "[INFO] Restarting containerd..."
        systemctl restart containerd
        sleep 3
        if systemctl is-active --quiet containerd; then
            echo "[OK] containerd is running on $ip"
        else
            echo "[ERROR] containerd failed to start on $ip!"
            exit 1
        fi
ENDRSCRIPT
    if [ $? -eq 0 ]; then
        echo "[OK] $ip fixed"
    else
        echo "[ERROR] Failed to fix $ip"
    fi
done

echo "[INFO] Testing containerd CRI on master-01..."
ssh -o StrictHostKeyChecking=no root@10.0.0.100 << ENDRSCRIPT
    crictl version 2>&1 | head -5
ENDRSCRIPT

echo "[INFO] Done!"

