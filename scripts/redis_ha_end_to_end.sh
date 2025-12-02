#!/bin/bash
set -e

LB_IP="10.0.0.10"   # IP du lb-haproxy interne
REDIS_PORT=6379

# Le mot de passe Redis doit être passé en variable d'environnement ou en paramètre
if [ -z "$REDIS_PWD" ]; then
    echo "ERREUR: La variable REDIS_PWD n'est pas définie"
    echo "Usage: export REDIS_PWD='<password>' && $0"
    exit 1
fi

echo "=== Testing Redis via LB ${LB_IP}:${REDIS_PORT} ==="
echo ""

# Test ping
echo "1. Test PING..."
if redis-cli -h "${LB_IP}" -p "${REDIS_PORT}" -a "${REDIS_PWD}" PING 2>&1 | grep -q "PONG"; then
    echo "   ✅ PING OK"
else
    echo "   ❌ PING FAILED"
    exit 1
fi

echo ""

# Test SET/GET
KEY="ha:test:$(date +%s)"
VALUE="kbv3-redis-ha-ok-$(hostname)-${RANDOM}"

echo "2. Test SET ${KEY} = ${VALUE}..."
if redis-cli -h "${LB_IP}" -p "${REDIS_PORT}" -a "${REDIS_PWD}" SET "${KEY}" "${VALUE}" 2>&1 | grep -q "OK"; then
    echo "   ✅ SET OK"
else
    echo "   ❌ SET FAILED"
    exit 1
fi

echo ""

echo "3. Test GET ${KEY}..."
RETRIEVED=$(redis-cli -h "${LB_IP}" -p "${REDIS_PORT}" -a "${REDIS_PWD}" GET "${KEY}" 2>&1 | tr -d '"')

if [ "$RETRIEVED" = "$VALUE" ]; then
    echo "   ✅ GET OK: ${RETRIEVED}"
    echo ""
    echo "4. Nettoyage..."
    redis-cli -h "${LB_IP}" -p "${REDIS_PORT}" -a "${REDIS_PWD}" DEL "${KEY}" >/dev/null 2>&1
    echo "   ✅ Clé supprimée"
else
    echo "   ❌ GET FAILED: valeur attendue '${VALUE}', obtenue '${RETRIEVED}'"
    exit 1
fi

echo ""
echo "=== ✅ Tous les tests sont passés avec succès ==="

