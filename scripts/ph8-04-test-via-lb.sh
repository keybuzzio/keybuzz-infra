#!/bin/bash
# PH8-04 - Test ERPNext database via LB
set -e

cd /opt/keybuzz/keybuzz-infra

# Get ERPNext password from log
ERP_PASS=$(grep "ERPNext Password" /opt/keybuzz/logs/phase8/ph8-04-erpnext-db-setup.log | tail -1 | awk '{print $NF}')

if [ -z "$ERP_PASS" ]; then
    echo "[ERROR] Could not find ERPNext password in log file"
    exit 1
fi

export ERP_PASS

echo "[INFO] Testing ERPNext database via LB (10.0.0.10:3306)..."
echo "[INFO] Password: ${ERP_PASS:0:20}..."

bash scripts/mariadb_erpnext_test.sh

