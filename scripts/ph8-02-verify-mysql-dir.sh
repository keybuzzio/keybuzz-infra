#!/bin/bash
# PH8-02 - Verify mysql directory exists on all nodes
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== Verifying mysql directory on all nodes ==="
echo ""

for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "=== Checking $ip ==="
    ssh root@$ip bash <<'VERIFY_SCRIPT'
    if [ -d /data/mariadb/data/mysql ]; then
        echo "✅ mysql directory exists"
        ls -l /data/mariadb/data | grep mysql
        echo "  Files in mysql directory:"
        ls -l /data/mariadb/data/mysql | head -10
    else
        echo "❌ mysql directory missing"
        echo "  Contents of /data/mariadb/data:"
        ls -la /data/mariadb/data
    fi
VERIFY_SCRIPT
    echo ""
done

echo "=== Verification complete ==="

