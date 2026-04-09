#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=$(cat /root/.vault-cluster-root-token 2>/dev/null || echo "")

echo "=== Check Ansible group_vars ==="
ls -la /opt/keybuzz/keybuzz-infra/ansible/group_vars/ 2>/dev/null

echo ""
echo "=== Check vault.yml format (encrypted?) ==="
head -3 /opt/keybuzz/keybuzz-infra/ansible/group_vars/vault.yml 2>/dev/null

echo ""
echo "=== Check postgres.yml for password vars ==="
cat /opt/keybuzz/keybuzz-infra/ansible/group_vars/postgres.yml 2>/dev/null

echo ""
echo "=== Check all group_vars files ==="
for f in /opt/keybuzz/keybuzz-infra/ansible/group_vars/*.yml; do
  echo "--- $(basename $f) ---"
  head -5 "$f" 2>/dev/null
  echo ""
done

echo ""
echo "=== Check host_vars ==="
ls -la /opt/keybuzz/keybuzz-infra/ansible/host_vars/ 2>/dev/null || echo "no host_vars"

echo ""
echo "=== Search for postgres_superuser_password ==="
grep -rl "postgres_superuser_password" /opt/keybuzz/keybuzz-infra/ 2>/dev/null | head -10

echo ""
echo "=== Check .env files on bastion ==="
find /opt/keybuzz -maxdepth 3 -name ".env*" -type f 2>/dev/null | head -10

echo ""
echo "=== Check Ansible vault password file ==="
find /root -name ".vault*" -o -name "vault_pass*" -o -name "ansible_vault*" 2>/dev/null | head -5
find /opt/keybuzz -name ".vault_pass*" -o -name "vault_password*" 2>/dev/null | head -5
ls -la /root/.ansible* 2>/dev/null || true

echo ""
echo "=== Check bash history for PG password ==="
grep -i "PGPASSWORD\|postgres_superuser\|createdb" /root/.bash_history 2>/dev/null | tail -10

echo ""
echo "=== Check etcd/Patroni DCS for superuser password (cluster config) ==="
# Patroni stores cluster config in etcd/DCS
# Check if etcd is running
which etcdctl 2>/dev/null && echo "etcdctl available" || echo "no etcdctl"

echo ""
echo "=== Check kubectl secret for Patroni ==="
kubectl get secrets -A 2>/dev/null | grep -i "patroni\|postgres" | head -10

echo ""
echo "=== Check any PG-related K8s secrets ==="
for ns in default kube-system; do
  kubectl get secrets -n $ns 2>/dev/null | grep -i "pg\|postgres\|patroni\|database" || true
done

echo ""
echo "DONE"
