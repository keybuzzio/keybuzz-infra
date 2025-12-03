#!/usr/bin/env python3
"""Script pour créer la policy et AppRole Ansible dans Vault"""

import subprocess
import json
import sys

vault_host = '10.0.0.150'
vault_addr = 'https://10.0.0.150:8200'
ssh_key = '/root/.ssh/id_rsa_keybuzz_v3'

def run_ssh(cmd):
    ssh_cmd = f"ssh -i {ssh_key} -o StrictHostKeyChecking=no root@{vault_host}"
    result = subprocess.run(f"{ssh_cmd} '{cmd}'", shell=True, capture_output=True, text=True)
    return result.stdout.strip(), result.returncode

def vault_cmd(cmd, root_token):
    """Exécute une commande vault"""
    full_cmd = f"export VAULT_ADDR='{vault_addr}' && export VAULT_SKIP_VERIFY=true && export VAULT_TOKEN='{root_token}' && {cmd}"
    return run_ssh(full_cmd)

print("=== PH6-03 - Configuration AppRole Ansible ===")
print(f"Vault Address: {vault_addr}")
print()

# Récupérer le root token
print("1. Récupération du root token...")
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

# Créer la policy ansible-policy
print("3. Création de la policy ansible-policy...")
policy_content = '''path "kv/data/keybuzz/*" {
  capabilities = ["read"]
}

path "kv/metadata/keybuzz/*" {
  capabilities = ["read"]
}'''

# Écrire la policy dans un fichier temporaire
write_policy_cmd = f"cat > /tmp/ansible-policy.hcl << 'POLICYEOF'\n{policy_content}\nPOLICYEOF"
run_ssh(write_policy_cmd)

# Appliquer la policy
apply_policy_cmd = "vault policy write ansible-policy /tmp/ansible-policy.hcl 2>&1"
stdout, rc = vault_cmd(apply_policy_cmd, root_token)
if 'Success' in stdout or rc == 0:
    print("   ✅ Policy créée")
else:
    print(f"   ⚠️  {stdout}")
print()

# Activer AppRole
print("4. Activation de AppRole auth method...")
enable_approle_cmd = "vault auth enable approle 2>&1"
stdout, rc = vault_cmd(enable_approle_cmd, root_token)
if 'Successfully enabled' in stdout or 'path is already in use' in stdout:
    print("   ✅ AppRole activé")
else:
    print(f"   ⚠️  {stdout}")
print()

# Créer l'AppRole ansible
print("5. Création de l'AppRole ansible...")
create_approle_cmd = """vault write auth/approle/role/ansible \
    token_policies="ansible-policy" \
    secret_id_ttl=0 \
    token_ttl=1h \
    token_max_ttl=4h 2>&1"""
stdout, rc = vault_cmd(create_approle_cmd, root_token)
if 'Success' in stdout or rc == 0:
    print("   ✅ AppRole créé")
else:
    print(f"   ⚠️  {stdout}")
print()

# Récupérer role_id
print("6. Récupération du role_id...")
get_role_id_cmd = "vault read -format=json auth/approle/role/ansible/role-id 2>&1"
stdout, rc = vault_cmd(get_role_id_cmd, root_token)
if stdout:
    try:
        data = json.loads(stdout)
        role_id = data.get('data', {}).get('role_id', '')
        if role_id:
            # Sauvegarder dans un fichier
            save_cmd = f"echo '{role_id}' > /root/ansible_role_id.txt && chmod 600 /root/ansible_role_id.txt"
            run_ssh(save_cmd)
            print(f"   ✅ role_id récupéré: {role_id[:10]}... ({len(role_id)} caractères)")
            print(f"   📝 Sauvegardé dans /root/ansible_role_id.txt")
        else:
            print(f"   ❌ Impossible d'extraire role_id: {stdout}")
    except:
        print(f"   ⚠️  Erreur parsing JSON: {stdout[:200]}")
else:
    print(f"   ❌ Erreur récupération role_id: {stdout}")
print()

# Récupérer secret_id
print("7. Génération du secret_id...")
get_secret_id_cmd = "vault write -format=json -f auth/approle/role/ansible/secret-id 2>&1"
stdout, rc = vault_cmd(get_secret_id_cmd, root_token)
if stdout:
    try:
        data = json.loads(stdout)
        secret_id = data.get('data', {}).get('secret_id', '')
        if secret_id:
            # Sauvegarder dans un fichier
            save_cmd = f"echo '{secret_id}' > /root/ansible_secret_id.txt && chmod 600 /root/ansible_secret_id.txt"
            run_ssh(save_cmd)
            print(f"   ✅ secret_id généré: {secret_id[:10]}... ({len(secret_id)} caractères)")
            print(f"   📝 Sauvegardé dans /root/ansible_secret_id.txt")
        else:
            print(f"   ❌ Impossible d'extraire secret_id: {stdout}")
    except:
        print(f"   ⚠️  Erreur parsing JSON: {stdout[:200]}")
else:
    print(f"   ❌ Erreur génération secret_id: {stdout}")
print()

# Vérifier l'AppRole
print("8. Vérification de l'AppRole...")
read_approle_cmd = "vault read auth/approle/role/ansible 2>&1"
stdout, rc = vault_cmd(read_approle_cmd, root_token)
print(stdout)
print()

print("=== ✅ Configuration AppRole terminée ===")
print()
print("⚠️  IMPORTANT:")
print("   - role_id sauvegardé dans /root/ansible_role_id.txt sur vault-01")
print("   - secret_id sauvegardé dans /root/ansible_secret_id.txt sur vault-01")
print("   - NE JAMAIS commiter ces fichiers dans Git")
print("   - Copier ces fichiers sur install-v3 pour utilisation par Ansible")

