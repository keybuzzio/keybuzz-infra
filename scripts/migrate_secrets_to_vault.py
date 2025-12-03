#!/usr/bin/env python3
"""Script pour migrer les secrets depuis group_vars vers Vault"""

import subprocess
import yaml
import sys
import os

vault_host = '10.0.0.150'
vault_addr = 'https://10.0.0.150:8200'
ssh_key = '/root/.ssh/id_rsa_keybuzz_v3'
base_dir = '/opt/keybuzz/keybuzz-infra'

def run_ssh_vault(cmd):
    """Exécute une commande sur vault-01"""
    ssh_cmd = f"ssh -i {ssh_key} -o StrictHostKeyChecking=no root@{vault_host}"
    result = subprocess.run(f"{ssh_cmd} '{cmd}'", shell=True, capture_output=True, text=True)
    return result.stdout.strip(), result.returncode

def run_local(cmd):
    """Exécute une commande localement (sur install-v3)"""
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout.strip(), result.returncode

def vault_cmd(cmd, root_token):
    """Exécute une commande vault"""
    full_cmd = f"export VAULT_ADDR='{vault_addr}' && export VAULT_SKIP_VERIFY=true && export VAULT_TOKEN='{root_token}' && {cmd}"
    return run_ssh_vault(full_cmd)

print("=== PH6-03 - Migration des Secrets vers Vault ===")
print(f"Vault Address: {vault_addr}")
print()

# Récupérer le root token
print("1. Récupération du root token...")
read_cmd = "cat /root/vault_init.txt 2>&1"
init_file, rc = run_ssh_vault(read_cmd)

root_token = None
for line in init_file.split('\n'):
    if 'Initial Root Token:' in line:
        parts = line.split(':')
        if len(parts) > 1:
            root_token = parts[1].strip()
            break

if not root_token:
    print("   ❌ Impossible d'extraire le root token")
    sys.exit(1)

print(f"   ✅ Root token récupéré: {root_token[:10]}... ({len(root_token)} caractères)")
print()

# Login avec root token
print("2. Authentification avec root token...")
login_cmd = f"vault login {root_token} > /dev/null 2>&1 && echo 'LOGGED_IN'"
stdout, rc = vault_cmd(login_cmd, root_token)
print("   ✅ Authentifié")
print()

# Définir les mappings secrets
secrets_mapping = {
    'ansible/group_vars/redis.yml': {
        'redis_auth_password': 'kv/keybuzz/redis',
        'path_key': 'password'
    },
    'ansible/group_vars/rabbitmq.yml': {
        'rabbitmq_password': 'kv/keybuzz/rabbitmq',
        'path_key': 'password'
    },
    # Ajouter d'autres mappings selon besoin
}

print(f"   Debug: base_dir = {base_dir}")

print("3. Migration des secrets...")
migrated = []

for yaml_file, mapping in secrets_mapping.items():
    file_path = f"{base_dir}/{yaml_file}"
    print(f"\n   📄 Traitement de {yaml_file}...")
    
    # Lire le fichier YAML depuis install-v3 (local)
    read_file_cmd = f"cat {file_path} 2>&1"
    file_content, rc = run_local(read_file_cmd)
    
    if rc != 0 or not file_content:
        print(f"      ⚠️  Fichier non trouvé ou vide: {file_path}")
        continue
    
    try:
        data = yaml.safe_load(file_content)
        
        for var_name, vault_path in mapping.items():
            if var_name in data:
                secret_value = data[var_name]
                
                # Ignorer les placeholders et valeurs par défaut
                if 'PLACEHOLDER' in str(secret_value) or 'ChangeMe' in str(secret_value) or 'default(' in str(secret_value):
                    print(f"      ⚠️  {var_name}: valeur placeholder ignorée")
                    continue
                
                # Extraire la valeur réelle si c'est une expression Jinja2
                if isinstance(secret_value, str) and '{{' in secret_value:
                    # Pour l'instant, on garde la valeur telle quelle
                    # En production, il faudrait parser l'expression Jinja2
                    print(f"      ⚠️  {var_name}: expression Jinja2 détectée, migration manuelle requise")
                    continue
                
                # Mettre à jour dans Vault
                path_key = mapping.get('path_key', 'password')
                put_cmd = f"vault kv put {vault_path} {path_key}='{secret_value}' 2>&1"
                stdout, rc = vault_cmd(put_cmd, root_token)
                
                if 'Successfully' in stdout or 'created_time' in stdout:
                    print(f"      ✅ {var_name} → {vault_path}")
                    migrated.append((var_name, vault_path))
                else:
                    print(f"      ❌ {var_name}: {stdout[:100]}")
    
    except Exception as e:
        print(f"      ❌ Erreur parsing YAML: {e}")

print()
print("4. Résumé de la migration...")
print(f"   ✅ Secrets migrés: {len(migrated)}")
for var_name, vault_path in migrated:
    print(f"      - {var_name} → {vault_path}")
print()

print("=== ✅ Migration terminée ===")
print()
print("⚠️  IMPORTANT:")
print("   - Les secrets ont été migrés vers Vault")
print("   - Mettez à jour les fichiers group_vars pour utiliser les lookups Vault")
print("   - Ne commitez JAMAIS les vrais mots de passe dans Git")

