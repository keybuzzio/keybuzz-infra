#!/usr/bin/env python3
"""Script pour créer la structure Vault pour les applications"""

import subprocess
import sys

vault_host = '10.0.0.150'
vault_addr = 'https://10.0.0.150:8200'
ssh_key = '/root/.ssh/id_rsa_keybuzz_v3'

def run_ssh(cmd):
    ssh_cmd = f"ssh -i {ssh_key} -o StrictHostKeyChecking=no root@{vault_host}"
    result = subprocess.run(f"{ssh_cmd} '{cmd}'", shell=True, capture_output=True, text=True)
    return result.stdout.strip(), result.returncode

def vault_cmd(cmd, root_token):
    full_cmd = f"export VAULT_ADDR='{vault_addr}' && export VAULT_SKIP_VERIFY=true && export VAULT_TOKEN='{root_token}' && {cmd}"
    return run_ssh(full_cmd)

print("=== PH6-05 - Création Structure Vault pour Applications ===")
print(f"Vault Address: {vault_addr}")
print()

# Récupérer le root token
read_cmd = "cat /root/vault_init.txt 2>&1"
init_file, rc = run_ssh(read_cmd)

root_token = None
for line in init_file.split('\n'):
    if 'Initial Root Token:' in line:
        parts = line.split(':')
        if len(parts) > 1:
            root_token = parts[1].strip()
            break

if not root_token:
    print("❌ Impossible d'extraire le root token")
    sys.exit(1)

print(f"✅ Root token récupéré: {root_token[:10]}... ({len(root_token)} caractères)")
print()

# Créer la structure des secrets
apps_structure = {
    'kv/keybuzz/apps/info': {'ready': 'true'},
    'kv/keybuzz/apps/chatwoot/database-url': {'value': 'placeholder'},
    'kv/keybuzz/apps/chatwoot/redis-url': {'value': 'placeholder'},
    'kv/keybuzz/apps/chatwoot/rabbitmq-url': {'value': 'placeholder'},
    'kv/keybuzz/apps/chatwoot/smtp-password': {'value': 'placeholder'},
    'kv/keybuzz/apps/n8n/rabbitmq-url': {'value': 'placeholder'},
    'kv/keybuzz/apps/n8n/redis-url': {'value': 'placeholder'},
    'kv/keybuzz/apps/n8n/webhook-secret': {'value': 'placeholder'},
    'kv/keybuzz/apps/n8n/jwt-secret': {'value': 'placeholder'},
    'kv/keybuzz/apps/keybuzz-api/postgres-url': {'value': 'placeholder'},
    'kv/keybuzz/apps/keybuzz-api/redis-url': {'value': 'placeholder'},
    'kv/keybuzz/apps/keybuzz-api/rabbitmq-url': {'value': 'placeholder'},
    'kv/keybuzz/apps/keybuzz-api/jwt-secret': {'value': 'placeholder'},
    'kv/keybuzz/apps/keybuzz-workers/api-token': {'value': 'placeholder'},
    'kv/keybuzz/apps/keybuzz-workers/rabbitmq-url': {'value': 'placeholder'},
    'kv/keybuzz/apps/keybuzz-workers/redis-url': {'value': 'placeholder'},
}

print("Création de la structure des secrets...")
for path, data in apps_structure.items():
    # Construire la commande vault kv put
    data_str = ' '.join([f"{k}='{v}'" for k, v in data.items()])
    put_cmd = f"vault kv put {path} {data_str} 2>&1"
    stdout, rc = vault_cmd(put_cmd, root_token)
    
    if 'Successfully' in stdout or 'created_time' in stdout or rc == 0:
        print(f"   ✅ {path}")
    else:
        print(f"   ⚠️  {path}: {stdout[:100]}")

print()

# Vérifier la structure
print("Vérification de la structure...")
list_cmd = "vault kv list kv/keybuzz/apps/ 2>&1"
stdout, rc = vault_cmd(list_cmd, root_token)
print(stdout)
print()

print("=== ✅ Structure créée ===")

