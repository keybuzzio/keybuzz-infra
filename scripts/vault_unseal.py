#!/usr/bin/env python3
"""Script pour unseal Vault si déjà initialisé"""

import subprocess
import sys

vault_host = '10.0.0.150'
vault_addr = 'https://10.0.0.150:8200'
ssh_key = '/root/.ssh/id_rsa_keybuzz_v3'

def run_ssh(cmd):
    ssh_cmd = f"ssh -i {ssh_key} -o StrictHostKeyChecking=no root@{vault_host}"
    result = subprocess.run(f"{ssh_cmd} '{cmd}'", shell=True, capture_output=True, text=True)
    return result.stdout.strip(), result.returncode

print("=== PH6-02 - Unseal de Vault ===")
print(f"Host: {vault_host}")
print(f"Vault Address: {vault_addr}")
print()

# Vérifier le statut
print("1. Vérification du statut de Vault...")
status_cmd = f"export VAULT_ADDR='{vault_addr}' && export VAULT_SKIP_VERIFY=true && vault status 2>&1"
stdout, rc = run_ssh(status_cmd)
print(stdout)
print()

if 'Sealed.*false' in stdout or 'Vault is unsealed' in stdout:
    print("   ✅ Vault est déjà unsealed")
    sys.exit(0)

# Vérifier si le fichier d'initialisation existe
print("2. Vérification du fichier d'initialisation...")
check_cmd = "test -f /root/vault_init.txt && echo 'EXISTS' || echo 'NOT_EXISTS'"
stdout, rc = run_ssh(check_cmd)

if 'NOT_EXISTS' in stdout:
    print("   ⚠️  Fichier /root/vault_init.txt non trouvé")
    print("   Vault doit être initialisé manuellement:")
    print(f"   ssh root@{vault_host}")
    print(f"   export VAULT_ADDR='{vault_addr}'")
    print(f"   export VAULT_SKIP_VERIFY=true")
    print(f"   vault operator init -key-shares=1 -key-threshold=1 > /root/vault_init.txt")
    sys.exit(1)

# Extraire l'unseal key
print("3. Extraction de l'unseal key...")
extract_cmd = "grep 'Unseal Key 1:' /root/vault_init.txt | awk '{print $4}'"
unseal_key, rc = run_ssh(extract_cmd)

if not unseal_key:
    print("   ❌ Impossible d'extraire l'unseal key")
    sys.exit(1)

print(f"   ✅ Unseal key extraite: {unseal_key[:10]}... ({len(unseal_key)} caractères)")
print()

# Unseal Vault
print("4. Unseal de Vault...")
unseal_cmd = f"export VAULT_ADDR='{vault_addr}' && export VAULT_SKIP_VERIFY=true && vault operator unseal {unseal_key} 2>&1"
stdout, rc = run_ssh(unseal_cmd)
print(stdout)
print()

# Vérifier le statut final
print("5. Vérification du statut final...")
status_cmd = f"export VAULT_ADDR='{vault_addr}' && export VAULT_SKIP_VERIFY=true && vault status 2>&1"
stdout, rc = run_ssh(status_cmd)
print(stdout)
print()

if 'Sealed.*false' in stdout or 'Vault is unsealed' in stdout:
    print("=== ✅ Vault unsealed avec succès ===")
else:
    print("=== ⚠️  Vault toujours sealed ===")

