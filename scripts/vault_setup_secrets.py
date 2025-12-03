#!/usr/bin/env python3
"""Script pour configurer les secrets engines et créer l'arborescence KV dans Vault"""

import subprocess
import sys

vault_host = '10.0.0.150'
vault_addr = 'https://10.0.0.150:8200'
ssh_key = '/root/.ssh/id_rsa_keybuzz_v3'

def run_ssh(cmd):
    ssh_cmd = f"ssh -i {ssh_key} -o StrictHostKeyChecking=no root@{vault_host}"
    result = subprocess.run(f"{ssh_cmd} '{cmd}'", shell=True, capture_output=True, text=True)
    return result.stdout.strip(), result.returncode

def vault_cmd(cmd):
    """Exécute une commande vault"""
    full_cmd = f"export VAULT_ADDR='{vault_addr}' && export VAULT_SKIP_VERIFY=true && {cmd}"
    return run_ssh(full_cmd)

print("=== PH6-03 - Configuration des Secrets Engines ===")
print(f"Vault Address: {vault_addr}")
print()

# Récupérer le root token
print("1. Récupération du root token...")
# Lire le fichier complet
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
    print("   ⚠️  Impossible d'extraire le root token depuis /root/vault_init.txt")
    print("   Le fichier contient:")
    print(init_file[:500])
    print()
    print("   Veuillez fournir le root token manuellement ou vérifier le fichier")
    sys.exit(1)

print(f"   ✅ Root token récupéré: {root_token[:10]}... ({len(root_token)} caractères)")
print()

# Login avec root token
print("2. Authentification avec root token...")
login_cmd = f"vault login {root_token} > /dev/null 2>&1 && echo 'LOGGED_IN'"
stdout, rc = vault_cmd(login_cmd)
if 'LOGGED_IN' in stdout:
    print("   ✅ Authentifié")
else:
    print("   ⚠️  Login peut avoir échoué, continuons...")
print()

# Activer KV v2 secrets engine
print("3. Activation du secrets engine KV v2...")
enable_kv_cmd = "vault secrets enable -path=kv kv-v2 2>&1"
stdout, rc = vault_cmd(enable_kv_cmd)
if 'Successfully enabled' in stdout or 'path is already in use' in stdout:
    print("   ✅ KV v2 activé")
else:
    print(f"   ⚠️  {stdout}")
print()

# Créer l'arborescence des secrets
print("4. Création de l'arborescence des secrets...")
secrets_paths = [
    'kv/keybuzz/redis',
    'kv/keybuzz/rabbitmq',
    'kv/keybuzz/postgres',
    'kv/keybuzz/mariadb',
    'kv/keybuzz/minio',
    'kv/keybuzz/haproxy',
    'kv/keybuzz/n8n',
    'kv/keybuzz/chatwoot',
]

for path in secrets_paths:
    # Créer un secret placeholder
    put_cmd = f"vault kv put {path} password='PLACEHOLDER_CHANGE_IN_PH6_MIGRATION' 2>&1"
    stdout, rc = vault_cmd(put_cmd)
    if 'Successfully' in stdout or 'created_time' in stdout:
        print(f"   ✅ {path}")
    else:
        print(f"   ⚠️  {path}: {stdout[:100]}")
print()

# Lister les secrets créés
print("5. Vérification des secrets créés...")
list_cmd = "vault kv list kv/keybuzz/ 2>&1"
stdout, rc = vault_cmd(list_cmd)
print(stdout)
print()

print("=== ✅ Configuration des secrets engines terminée ===")
print()
print("Prochaines étapes:")
print("  - Migrer les vrais mots de passe depuis group_vars vers Vault")
print("  - Configurer l'intégration Ansible avec Vault")

