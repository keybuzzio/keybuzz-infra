#!/bin/bash
# Restaurer redis-01 comme master

set -e

cd /opt/keybuzz/keybuzz-infra

# Charger le mot de passe
REDIS_PWD=$(python3 << 'PYEOF'
import yaml
with open('ansible/group_vars/redis.yml', 'r') as f:
    data = yaml.safe_load(f)
    print(data['redis_auth_password'])
PYEOF
)

export REDIS_PWD

echo "=== Restauration du master Redis ==="
echo ""

# Forcer redis-01 à devenir master
echo "1. Forcer redis-01 (10.0.0.123) en master..."
ssh root@10.0.0.123 "redis-cli -a '$REDIS_PWD' REPLICAOF NO ONE"
sleep 2

# Vérifier le rôle
ROLE=$(ssh root@10.0.0.123 "redis-cli -a '$REDIS_PWD' INFO replication | grep '^role:'")
echo "   $ROLE"

if echo "$ROLE" | grep -q "role:master"; then
    echo "   ✅ redis-01 est maintenant master"
else
    echo "   ❌ Échec de la promotion"
    exit 1
fi
echo ""

# Reconfigurer redis-02 et redis-03 comme replicas
echo "2. Reconfigurer redis-02 comme replica..."
ssh root@10.0.0.124 "redis-cli -a '$REDIS_PWD' REPLICAOF 10.0.0.123 6379"
sleep 3

echo "3. Reconfigurer redis-03 comme replica..."
ssh root@10.0.0.125 "redis-cli -a '$REDIS_PWD' REPLICAOF 10.0.0.123 6379"
sleep 3

# Vérification finale
echo "4. Vérification du cluster..."
echo ""
echo "redis-01:"
ssh root@10.0.0.123 "redis-cli -a '$REDIS_PWD' INFO replication | grep -E '^role:|connected_slaves'"
echo ""
echo "redis-02:"
ssh root@10.0.0.124 "redis-cli -a '$REDIS_PWD' INFO replication | grep -E '^role:|master_host|master_link_status'"
echo ""
echo "redis-03:"
ssh root@10.0.0.125 "redis-cli -a '$REDIS_PWD' INFO replication | grep -E '^role:|master_host|master_link_status'"
echo ""

echo "✅ Cluster Redis restauré avec redis-01 comme master"

