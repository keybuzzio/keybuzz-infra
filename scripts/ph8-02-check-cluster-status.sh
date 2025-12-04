#!/bin/bash
# PH8-02 - Check MariaDB Galera cluster status with detailed output
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== MariaDB Galera Cluster Status ==="
echo ""

for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "=== Checking $ip ==="
    ssh root@$ip bash <<'CHECK_SCRIPT'
    if systemctl is-active --quiet mariadb; then
        echo "✅ MariaDB is running"
        mysql -u root -p'CHANGE_ME_LATER_VIA_VAULT' -e "SHOW STATUS LIKE 'wsrep_cluster_size'; SHOW STATUS LIKE 'wsrep_local_state_comment';" 2>&1 | grep -E '(wsrep_cluster_size|wsrep_local_state_comment|Value)' || echo "⚠️  Could not query status"
    else
        echo "❌ MariaDB is NOT running"
        systemctl status mariadb --no-pager | head -5
    fi
CHECK_SCRIPT
    echo ""
done

echo "=== Check completed ==="

