#!/bin/bash
# PH8-02 - Analyze Galera config files for unsupported variables
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== Analyzing Galera config files ==="
echo ""

for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "=== Analyzing maria node $ip ==="
    ssh root@$ip bash <<'ANALYZE_SCRIPT'
    echo "Searching for unsupported variables..."
    grep -R 'wsrep_replicate_myisam\|pxc_strict_mode' /etc/mysql 2>/dev/null || echo "  No unsupported variables found"
    
    echo ""
    echo "Listing /etc/mysql/conf.d:"
    ls -l /etc/mysql/conf.d/ 2>/dev/null || echo "  Directory not found"
    
    echo ""
    echo "Listing /etc/mysql/mariadb.conf.d:"
    ls -l /etc/mysql/mariadb.conf.d/ 2>/dev/null || echo "  Directory not found"
    
    echo ""
ANALYZE_SCRIPT
done

echo "=== Analysis completed ==="

