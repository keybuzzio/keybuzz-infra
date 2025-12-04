#!/bin/bash
# PH8-02 - Final fix for galera.cnf files
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== Final fix for galera.cnf files ==="
echo ""

for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "Fixing galera.cnf on $ip..."
    ssh root@$ip bash <<'FIX_SCRIPT'
    if [ -f /etc/mysql/conf.d/galera.cnf ]; then
        # Remove unsupported variables
        sed -i '/wsrep_replicate_myisam/d' /etc/mysql/conf.d/galera.cnf
        sed -i '/pxc_strict_mode/d' /etc/mysql/conf.d/galera.cnf
        sed -i '/PXC Strict Mode/d' /etc/mysql/conf.d/galera.cnf
        # Remove empty lines
        sed -i '/^$/N;/^\n$/d' /etc/mysql/conf.d/galera.cnf
        echo "✅ Fixed galera.cnf on $(hostname)"
        
        # Verify
        if grep -q 'wsrep_replicate_myisam\|pxc_strict_mode' /etc/mysql/conf.d/galera.cnf; then
            echo "❌ Still contains unsupported variables"
        else
            echo "✅ No unsupported variables found"
        fi
    else
        echo "⚠️  galera.cnf not found"
    fi
FIX_SCRIPT
done

echo ""
echo "✅ All galera.cnf files fixed"

