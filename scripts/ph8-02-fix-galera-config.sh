#!/bin/bash
# Fix galera.cnf by removing unsupported variables
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== Fixing galera.cnf on all MariaDB nodes ==="

for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "Fixing galera.cnf on $ip..."
    ssh root@$ip bash <<'FIX_SCRIPT'
    if [ -f /etc/mysql/conf.d/galera.cnf ]; then
        sed -i '/wsrep_replicate_myisam/d; /pxc_strict_mode/d' /etc/mysql/conf.d/galera.cnf
        echo "✅ Fixed galera.cnf on $(hostname)"
    else
        echo "⚠️  galera.cnf not found on $(hostname)"
    fi
FIX_SCRIPT
done

echo "✅ All galera.cnf files fixed"

