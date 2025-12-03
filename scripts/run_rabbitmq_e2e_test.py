#!/usr/bin/env python3
"""Wrapper pour exécuter le test RabbitMQ end-to-end"""

import subprocess
import sys
import os

# Charger le mot de passe
pwd = 'ChangeMeInPH6-Vault'  # Mot de passe par défaut

os.environ['RABBITMQ_PASSWORD'] = pwd

print("=== Test RabbitMQ HA End-to-End ===")
print(f"Mot de passe: {pwd[:10]}... ({len(pwd)} caractères)")
print()

# Exécuter le script
script_path = '/opt/keybuzz/keybuzz-infra/scripts/rabbitmq_ha_end_to_end.sh'
log_path = '/opt/keybuzz/logs/phase5/rabbitmq-ha-e2e.log'

result = subprocess.run(
    ['bash', script_path],
    env=os.environ,
    capture_output=True,
    text=True
)

# Afficher la sortie
print(result.stdout)
if result.stderr:
    print("STDERR:", result.stderr, file=sys.stderr)

# Écrire dans le log
with open(log_path, 'w') as f:
    f.write(result.stdout)
    if result.stderr:
        f.write("\nSTDERR:\n" + result.stderr)

if result.returncode == 0:
    print("\n✅ TEST RÉUSSI")
    sys.exit(0)
else:
    print(f"\n❌ TEST ÉCHOUÉ (code: {result.returncode})")
    sys.exit(result.returncode)

