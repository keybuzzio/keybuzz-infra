#!/usr/bin/env python3
"""Script pour créer les policies et AppRoles pour les applications"""

import subprocess
import json
import sys
import os

vault_host = '10.0.0.150'
vault_addr = 'https://10.0.0.150:8200'
ssh_key = '/root/.ssh/id_rsa_keybuzz_v3'
base_dir = '/opt/keybuzz/keybuzz-infra'

def run_ssh(cmd):
    ssh_cmd = f"ssh -i {ssh_key} -o StrictHostKeyChecking=no root@{vault_host}"
    result = subprocess.run(f"{ssh_cmd} '{cmd}'", shell=True, capture_output=True, text=True)
    return result.stdout.strip(), result.returncode

def vault_cmd(cmd, root_token):
    full_cmd = f"export VAULT_ADDR='{vault_addr}' && export VAULT_SKIP_VERIFY=true && export VAULT_TOKEN='{root_token}' && {cmd}"
    return run_ssh(full_cmd)

def run_local(cmd):
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout.strip(), result.returncode

print("=== PH6-05 - Configuration Policies et AppRoles Applications ===")
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

# Applications et leurs policies
apps_config = {
    'chatwoot': {
        'policy_file': 'policy-chatwoot.hcl',
        'policy_name': 'chatwoot-policy',
        'approle_name': 'chatwoot'
    },
    'n8n': {
        'policy_file': 'policy-n8n.hcl',
        'policy_name': 'n8n-policy',
        'approle_name': 'n8n'
    },
    'keybuzz-api': {
        'policy_file': 'policy-keybuzz-api.hcl',
        'policy_name': 'keybuzz-api-policy',
        'approle_name': 'keybuzz-api'
    },
    'keybuzz-workers': {
        'policy_file': 'policy-keybuzz-workers.hcl',
        'policy_name': 'keybuzz-workers-policy',
        'approle_name': 'keybuzz-workers'
    }
}

# Créer le répertoire pour les identifiants
run_local(f"mkdir -p {base_dir}/roles")

print("1. Création des policies...")
for app_name, config in apps_config.items():
    policy_file = f"{base_dir}/scripts/vault_policies/{config['policy_file']}"
    
    # Lire le contenu de la policy
    with open(policy_file, 'r') as f:
        policy_content = f.read()
    
    # Écrire la policy dans un fichier temporaire sur vault-01
    write_policy_cmd = f"cat > /tmp/{config['policy_file']} << 'POLICYEOF'\n{policy_content}\nPOLICYEOF"
    run_ssh(write_policy_cmd)
    
    # Appliquer la policy
    apply_cmd = f"vault policy write {config['policy_name']} /tmp/{config['policy_file']} 2>&1"
    stdout, rc = vault_cmd(apply_cmd, root_token)
    
    if 'Success' in stdout or rc == 0:
        print(f"   ✅ {config['policy_name']}")
    else:
        print(f"   ⚠️  {config['policy_name']}: {stdout[:100]}")

print()

print("2. Création des AppRoles...")
for app_name, config in apps_config.items():
    create_approle_cmd = f"""vault write auth/approle/role/{config['approle_name']} \
    token_policies="{config['policy_name']}" \
    secret_id_ttl=0 \
    token_ttl=1h \
    token_max_ttl=4h 2>&1"""
    
    stdout, rc = vault_cmd(create_approle_cmd, root_token)
    
    if 'Success' in stdout or rc == 0:
        print(f"   ✅ AppRole {config['approle_name']}")
    else:
        print(f"   ⚠️  {config['approle_name']}: {stdout[:100]}")

print()

print("3. Récupération des identifiants AppRole...")
for app_name, config in apps_config.items():
    # Récupérer role_id
    get_role_id_cmd = f"vault read -format=json auth/approle/role/{config['approle_name']}/role-id 2>&1"
    stdout, rc = vault_cmd(get_role_id_cmd, root_token)
    
    if stdout:
        try:
            data = json.loads(stdout)
            role_id = data.get('data', {}).get('role_id', '')
            if role_id:
                # Sauvegarder localement
                role_file = f"{base_dir}/roles/{config['approle_name']}-role.json"
                with open(role_file, 'w') as f:
                    json.dump({'role_id': role_id}, f, indent=2)
                print(f"   ✅ {config['approle_name']} role_id sauvegardé")
        except:
            print(f"   ⚠️  Erreur parsing role_id pour {config['approle_name']}")
    
    # Générer secret_id
    get_secret_id_cmd = f"vault write -format=json -f auth/approle/role/{config['approle_name']}/secret-id 2>&1"
    stdout, rc = vault_cmd(get_secret_id_cmd, root_token)
    
    if stdout:
        try:
            data = json.loads(stdout)
            secret_id = data.get('data', {}).get('secret_id', '')
            if secret_id:
                # Sauvegarder localement
                secret_file = f"{base_dir}/roles/{config['approle_name']}-secret.json"
                with open(secret_file, 'w') as f:
                    json.dump({'secret_id': secret_id}, f, indent=2)
                print(f"   ✅ {config['approle_name']} secret_id sauvegardé")
        except:
            print(f"   ⚠️  Erreur parsing secret_id pour {config['approle_name']}")

print()

print("=== ✅ Configuration terminée ===")
print()
print("⚠️  IMPORTANT:")
print("   - Les identifiants sont sauvegardés dans roles/ sur install-v3")
print("   - NE JAMAIS commiter ces fichiers dans Git")
print("   - Ajouter roles/ à .gitignore")

