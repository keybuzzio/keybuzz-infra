#!/bin/bash
# PH8-03 - Fix ProxySQL YAML syntax error
set -e

cd /opt/keybuzz/keybuzz-infra

echo "[INFO] Fixing ProxySQL YAML syntax error..."

# Fix line 100 in proxysql_v3/tasks/main.yml
sed -i '100s/.*/- name: "Configure ProxySQL users (default: root user can connect)"/' ansible/roles/proxysql_v3/tasks/main.yml

echo "[INFO] Verifying fix..."
if ansible-playbook --syntax-check ansible/playbooks/proxysql_v3.yml 2>&1 | grep -q "ERROR"; then
    echo "[ERROR] YAML syntax check still failing"
    exit 1
else
    echo "[INFO] ✅ YAML syntax check passed"
fi

echo "[INFO] Fix complete!"

