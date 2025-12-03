#!/usr/bin/env python3
"""Migrer le secret RabbitMQ vers Vault"""

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

# Le mot de passe RabbitMQ actuel est "ChangeMeInPH6-Vault"
# En production, il faudra le remplacer par un vrai mot de passe
rabbitmq_password = "ChangeMeInPH6-Vault"

print(f"Migration du secret RabbitMQ vers Vault...")
put_cmd = f"vault kv put kv/keybuzz/rabbitmq password='{rabbitmq_password}' 2>&1"
stdout, rc = vault_cmd(put_cmd, root_token)

if 'Successfully' in stdout or 'created_time' in stdout:
    print(f"✅ Secret RabbitMQ migré vers kv/keybuzz/rabbitmq")
else:
    print(f"⚠️  {stdout}")

