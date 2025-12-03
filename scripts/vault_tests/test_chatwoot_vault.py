#!/usr/bin/env python3
"""Test de récupération des secrets Vault pour Chatwoot"""

import json
import subprocess
import sys
import os

vault_addr = 'https://vault.keybuzz.io:8200'
base_dir = '/opt/keybuzz/keybuzz-infra'

def load_approle_creds(app_name):
    """Charge les identifiants AppRole depuis les fichiers JSON"""
    role_file = f"{base_dir}/roles/{app_name}-role.json"
    secret_file = f"{base_dir}/roles/{app_name}-secret.json"
    
    try:
        with open(role_file, 'r') as f:
            role_data = json.load(f)
        with open(secret_file, 'r') as f:
            secret_data = json.load(f)
        
        return role_data.get('role_id'), secret_data.get('secret_id')
    except Exception as e:
        print(f"❌ Erreur lecture fichiers: {e}")
        return None, None

def test_vault_secret(secret_path, role_id, secret_id):
    """Teste la récupération d'un secret depuis Vault"""
    # Utiliser vault CLI pour tester
    cmd = f"""export VAULT_ADDR='{vault_addr}' && \
export VAULT_SKIP_VERIFY=true && \
vault write -format=json auth/approle/login role_id='{role_id}' secret_id='{secret_id}' | \
jq -r .auth.client_token | \
xargs -I {{}} vault kv get -format=json -mount=kv {secret_path} --token={{}} 2>&1"""
    
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    
    if result.returncode == 0:
        try:
            data = json.loads(result.stdout)
            return True, data.get('data', {}).get('data', {}).get('value', '')
        except:
            return True, result.stdout[:100]
    else:
        return False, result.stderr

print("=== Test Vault Secrets pour Chatwoot ===")
print(f"Vault Address: {vault_addr}")
print()

# Charger les identifiants AppRole
role_id, secret_id = load_approle_creds('chatwoot')

if not role_id or not secret_id:
    print("❌ Impossible de charger les identifiants AppRole")
    sys.exit(1)

print(f"✅ Identifiants AppRole chargés")
print(f"   role_id: {role_id[:10]}... ({len(role_id)} caractères)")
print(f"   secret_id: {secret_id[:10]}... ({len(secret_id)} caractères)")
print()

# Secrets à tester
secrets_to_test = [
    'keybuzz/apps/chatwoot/database-url',
    'keybuzz/apps/chatwoot/redis-url',
    'keybuzz/apps/chatwoot/rabbitmq-url',
    'keybuzz/apps/chatwoot/smtp-password',
]

print("Test de récupération des secrets...")
all_success = True

for secret_path in secrets_to_test:
    success, value = test_vault_secret(secret_path, role_id, secret_id)
    
    if success:
        print(f"   ✅ {secret_path}: {value[:20]}...")
    else:
        print(f"   ❌ {secret_path}: {value[:100]}")
        all_success = False

print()

if all_success:
    print("=== ✅ Tous les tests réussis ===")
    sys.exit(0)
else:
    print("=== ❌ Certains tests ont échoué ===")
    sys.exit(1)

