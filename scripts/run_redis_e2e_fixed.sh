#!/bin/bash
# Script wrapper corrigé pour exécuter le test Redis end-to-end
# Charge automatiquement le mot de passe depuis group_vars avec Python

set -e

cd /opt/keybuzz/keybuzz-infra

# Charger le mot de passe Redis avec Python (plus fiable pour YAML)
REDIS_PWD=$(python3 << 'PYEOF'
import yaml
import sys

try:
    with open('ansible/group_vars/redis.yml', 'r') as f:
        data = yaml.safe_load(f)
        password = data.get('redis_auth_password', '')
        if password:
            print(password)
        else:
            sys.exit(1)
except Exception as e:
    print(f"ERREUR: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
)

if [ -z "$REDIS_PWD" ]; then
    echo "ERREUR: Impossible de charger REDIS_PWD depuis group_vars/redis.yml"
    exit 1
fi

export REDIS_PWD

echo "REDIS_PWD chargé (${#REDIS_PWD} caractères)"
echo ""

# Vérification rapide avec PING direct
echo "Vérification rapide:"
if redis-cli -h 10.0.0.10 -p 6379 -a "$REDIS_PWD" PING 2>&1 | grep -q "PONG"; then
    echo "✅ Connexion Redis via LB OK"
else
    echo "⚠️  Connexion Redis via LB échouée, mais on continue le test complet"
fi
echo ""

# Créer le répertoire de logs
mkdir -p /opt/keybuzz/logs/phase4

# Exécuter le test
chmod +x scripts/redis_ha_end_to_end_test.sh
REDIS_PWD="$REDIS_PWD" bash scripts/redis_ha_end_to_end_test.sh 2>&1 | tee /opt/keybuzz/logs/phase4/redis-ha-e2e.log

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

