#!/bin/bash
# Script wrapper pour exécuter le test Redis end-to-end
# Charge automatiquement le mot de passe depuis group_vars

set -e

cd /opt/keybuzz/keybuzz-infra

# Charger le mot de passe Redis
REDIS_PWD=$(grep redis_auth_password ansible/group_vars/redis.yml | awk -F: '{print $2}' | tr -d ' "')
export REDIS_PWD

if [ -z "$REDIS_PWD" ]; then
    echo "ERREUR: Impossible de charger REDIS_PWD depuis group_vars/redis.yml"
    exit 1
fi

echo "REDIS_PWD chargé (${#REDIS_PWD} caractères)"
echo ""

# Créer le répertoire de logs
mkdir -p /opt/keybuzz/logs/phase4

# Exécuter le test
chmod +x scripts/redis_ha_end_to_end_test.sh
bash scripts/redis_ha_end_to_end_test.sh 2>&1 | tee /opt/keybuzz/logs/phase4/redis-ha-e2e.log

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ TEST RÉUSSI"
    exit 0
else
    echo ""
    echo "❌ TEST ÉCHOUÉ (code: $EXIT_CODE)"
    exit $EXIT_CODE
fi

