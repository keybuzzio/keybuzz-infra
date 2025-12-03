#!/bin/bash
# Test détaillé Redis via LB avec diagnostic

set -e

LB_IP="10.0.0.10"
REDIS_PORT=6379

cd /opt/keybuzz/keybuzz-infra
REDIS_PWD=$(grep redis_auth_password ansible/group_vars/redis.yml | awk -F: '{print $2}' | tr -d ' "')

if [ -z "$REDIS_PWD" ]; then
    echo "ERREUR: REDIS_PWD non trouvé"
    exit 1
fi

echo "=== Test détaillé Redis via LB ${LB_IP}:${REDIS_PORT} ==="
echo "Mot de passe chargé: ${#REDIS_PWD} caractères"
echo ""

# Test 1: PING sans auth
echo "1. Test PING sans authentification:"
RESULT1=$(redis-cli -h "${LB_IP}" -p "${REDIS_PORT}" PING 2>&1)
echo "   Réponse: $RESULT1"
echo ""

# Test 2: PING avec auth
echo "2. Test PING avec authentification:"
RESULT2=$(redis-cli -h "${LB_IP}" -p "${REDIS_PORT}" -a "${REDIS_PWD}" PING 2>&1)
echo "   Réponse: $RESULT2"
if echo "$RESULT2" | grep -q "PONG"; then
    echo "   ✅ PING OK"
else
    echo "   ❌ PING FAILED: $RESULT2"
    exit 1
fi
echo ""

# Test 3: SET
KEY="ha:test:$(date +%s)"
VALUE="kbv3-redis-ha-ok-$(hostname)-${RANDOM}"
echo "3. Test SET ${KEY} = ${VALUE}:"
RESULT3=$(redis-cli -h "${LB_IP}" -p "${REDIS_PORT}" -a "${REDIS_PWD}" SET "${KEY}" "${VALUE}" 2>&1)
echo "   Réponse: $RESULT3"
if echo "$RESULT3" | grep -q "OK"; then
    echo "   ✅ SET OK"
else
    echo "   ❌ SET FAILED: $RESULT3"
    exit 1
fi
echo ""

# Test 4: GET
echo "4. Test GET ${KEY}:"
RETRIEVED=$(redis-cli -h "${LB_IP}" -p "${REDIS_PORT}" -a "${REDIS_PWD}" GET "${KEY}" 2>&1 | tr -d '"')
echo "   Valeur récupérée: $RETRIEVED"
if [ "$RETRIEVED" = "$VALUE" ]; then
    echo "   ✅ GET OK"
else
    echo "   ❌ GET FAILED: attendu '$VALUE', obtenu '$RETRIEVED'"
    exit 1
fi
echo ""

# Nettoyage
echo "5. Nettoyage:"
redis-cli -h "${LB_IP}" -p "${REDIS_PORT}" -a "${REDIS_PWD}" DEL "${KEY}" >/dev/null 2>&1
echo "   ✅ Clé supprimée"
echo ""

echo "=== ✅ Tous les tests sont passés avec succès ==="

