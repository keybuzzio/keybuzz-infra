#!/usr/bin/env python3
"""Script pour initialiser Vault sur vault-01"""

import subprocess
import sys

vault_host = '10.0.0.150'
vault_addr = 'https://10.0.0.150:8200'
ssh_key = '/root/.ssh/id_rsa_keybuzz_v3'

def run_ssh(cmd):
    ssh_cmd = f"ssh -i {ssh_key} -o StrictHostKeyChecking=no root@{vault_host}"
    result = subprocess.run(f"{ssh_cmd} '{cmd}'", shell=True, capture_output=True, text=True)
    return result.stdout.strip(), result.returncode

print("=== PH6-02 - Initialisation de Vault ===")
print(f"Host: {vault_host}")
print(f"Vault Address: {vault_addr}")
print()

# Vérifier que Vault est accessible
print("1. Vérification de l'accessibilité de Vault...")
stdout, rc = run_ssh(f"export VAULT_ADDR='{vault_addr}' && export VAULT_SKIP_VERIFY=true && vault status 2>&1")
if 'Sealed.*true' in stdout or 'not initialized' in stdout.lower():
    print("   ✅ Vault est accessible et sealed (non initialisé)")
else:
    print(f"   ⚠️  État de Vault: {stdout[:200]}")
print()

# Initialiser Vault
print("2. Initialisation de Vault...")
# Sauvegarder directement dans un fichier
save_cmd = f"export VAULT_ADDR='{vault_addr}' && export VAULT_SKIP_VERIFY=true && vault operator init -key-shares=1 -key-threshold=1 > /root/vault_init.txt 2>&1 && echo 'INIT_DONE'"
stdout, rc = run_ssh(save_cmd)

if 'INIT_DONE' in stdout:
    # Lire le fichier
    read_cmd = "cat /root/vault_init.txt"
    init_output, rc = run_ssh(read_cmd)
    
    if 'Unseal Key' in init_output:
        print("   ✅ Vault initialisé")
        print("   📝 Clés sauvegardées dans /root/vault_init.txt sur vault-01")
        print()
        print("   Sortie complète:")
        print(init_output)
    else:
        print(f"   ⚠️  Erreur lors de l'initialisation: {init_output}")
        sys.exit(1)
else:
    print(f"   ⚠️  Erreur lors de l'initialisation: {stdout}")
    sys.exit(1)
print()

# Extraire l'unseal key et root token
extract_cmd = "grep 'Unseal Key 1:' /root/vault_init.txt | awk '{print $4}'"
unseal_key, rc = run_ssh(extract_cmd)

extract_token_cmd = "grep 'Initial Root Token:' /root/vault_init.txt | awk '{print $4}'"
root_token, rc = run_ssh(extract_token_cmd)

if not unseal_key or not root_token:
    print("   ❌ Impossible d'extraire les clés")
    sys.exit(1)

# Unseal Vault
print("3. Unseal de Vault...")
unseal_cmd = f"export VAULT_ADDR='{vault_addr}' && export VAULT_SKIP_VERIFY=true && vault operator unseal {unseal_key} 2>&1"
stdout, rc = run_ssh(unseal_cmd)
if 'Sealed.*false' in stdout or 'Vault is unsealed' in stdout:
    print("   ✅ Vault unsealed")
else:
    print(f"   ⚠️  État après unseal: {stdout[:200]}")
print()

# Vérifier le statut final
print("4. Vérification du statut final...")
status_cmd = f"export VAULT_ADDR='{vault_addr}' && export VAULT_SKIP_VERIFY=true && vault status 2>&1 | head -10"
stdout, rc = run_ssh(status_cmd)
print(stdout)
print()

# Afficher les informations (sans le token réel)
print("5. Informations d'initialisation:")
print(f"   Unseal Key: {unseal_key[:10]}... ({len(unseal_key)} caractères)")
print(f"   Root Token: {root_token[:10]}... ({len(root_token)} caractères)")
print("   📝 Fichier complet: /root/vault_init.txt sur vault-01")
print()

print("=== ✅ Initialisation terminée ===")
print()
print("⚠️  IMPORTANT: Sauvegardez /root/vault_init.txt dans un coffre sécurisé")
print("   Ne jamais commiter ce fichier dans Git !")

