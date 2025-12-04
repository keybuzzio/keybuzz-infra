#!/bin/bash
# PH8-02 - Remove all parasite Galera config files
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== Removing parasite Galera config files ==="
echo ""

for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "=== Cleaning maria node $ip ==="
    ssh root@$ip bash <<'CLEAN_SCRIPT'
    # Find and remove files with unsupported variables
    for file in $(grep -Rl 'wsrep_replicate_myisam\|pxc_strict_mode' /etc/mysql 2>/dev/null || true); do
        echo "  Removing: $file"
        rm -f "$file"
    done
    
    # Also remove common backup/dist files
    rm -f /etc/mysql/conf.d/galera.cnf.dpkg-dist
    rm -f /etc/mysql/conf.d/galera.cnf.dpkg-old
    rm -f /etc/mysql/conf.d/galera.cnf.rpmnew
    rm -f /etc/mysql/conf.d/galera.cnf.rpmsave
    rm -f /etc/mysql/mariadb.conf.d/galera.cnf
    
    echo "  ✅ Cleaned $(hostname)"
CLEAN_SCRIPT
done

echo "✅ All parasite files removed"

