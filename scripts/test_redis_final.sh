#!/bin/bash
# Test final Redis via LB avec mot de passe correct

set -e

LB_IP="10.0.0.10"
REDIS_PORT=6379

cd /opt/keybuzz/keybuzz-infra

# Charger le mot de passe avec Python
REDIS_PWD=$(python3 << 'PYEOF'
import yaml
with open('ansible/group_vars/redis.yml', 'r') as f:
    data = yaml.safe_load(f)
    print(data['redis_auth_password'])
PYEOF
)

export REDIS_PWD

echo "=== Test Redis via LB ${LB_IP}:${REDIS_PORT} ==="
echo "Mot de passe: ${REDIS_PWD:0:10}... (${#REDIS_PWD} caractères)"
echo ""

# Test 1: PING
echo "1. Test PING..."
RESULT=$(redis-cli -h "${LB_IP}" -p "${REDIS_PORT}" -a "${REDIS_PWD}" PING 2>&1)
if echo "$RESULT" | grep -q "PONG"; then
    echo "   ✅ PING OK"
else
    echo "   ❌ PING FAILED: $RESULT"
    exit 1
fi
echo ""

# Test 2: SET
KEY="ha:test:$(date +%s)"
VALUE="kbv3-redis-ha-ok-$(hostname)-${RANDOM}"
echo "2. Test SET ${KEY} = ${VALUE}..."
RESULT=$(redis-cli -h "${LB_IP}" -p "${REDIS_PORT}" -a "${REDIS_PWD}" SET "${KEY}" "${VALUE}" 2>&1)
echo "   Réponse brute: $RESULT"
if echo "$RESULT" | grep -q "OK"; then
    echo "   ✅ SET OK"
else
    echo "   ❌ SET FAILED: $RESULT"
    exit 1
fi
echo ""

# Test 3: GET
echo "3. Test GET ${KEY}..."
RETRIEVED=$(redis-cli -h "${LB_IP}" -p "${REDIS_PORT}" -a "${REDIS_PWD}" GET "${KEY}" 2>&1 | grep -v "Warning:" | grep -v "Using a password" | tr -d '"')
echo "   Valeur récupérée: $RETRIEVED"
if [ "$RETRIEVED" = "$VALUE" ]; then
    echo "   ✅ GET OK"
else
    echo "   ❌ GET FAILED: attendu '$VALUE', obtenu '$RETRIEVED'"
    exit 1
fi
echo ""

# Nettoyage
echo "4. Nettoyage..."
redis-cli -h "${LB_IP}" -p "${REDIS_PORT}" -a "${REDIS_PWD}" DEL "${KEY}" >/dev/null 2>&1
echo "   ✅ Clé supprimée"
echo ""

echo "=== ✅ Tous les tests sont passés avec succès ==="

