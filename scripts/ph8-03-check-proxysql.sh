#!/bin/bash
# PH8-03 - Check ProxySQL runtime configuration
set -e

cd /opt/keybuzz/keybuzz-infra

echo "[INFO] =========================================="
echo "[INFO] Checking ProxySQL Runtime Configuration"
echo "[INFO] =========================================="
echo ""

for proxysql_ip in 10.0.0.173 10.0.0.174; do
    echo "[INFO] === ProxySQL on $proxysql_ip ==="
    ssh root@$proxysql_ip bash <<'CHECK_SCRIPT'
    mysql -h 127.0.0.1 -P6032 -u admin -padmin -e "SELECT * FROM runtime_mysql_servers;" 2>&1 || echo "⚠️  Could not connect to ProxySQL admin"
CHECK_SCRIPT
    echo ""
done

echo "[INFO] =========================================="
echo "[INFO] Check completed"
echo "[INFO] =========================================="

