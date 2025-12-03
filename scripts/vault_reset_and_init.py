#!/usr/bin/env python3
"""Script pour réinitialiser et initialiser Vault"""

import subprocess
import sys

vault_host = '10.0.0.150'
vault_addr = 'https://10.0.0.150:8200'
ssh_key = '/root/.ssh/id_rsa_keybuzz_v3'

def run_ssh(cmd):
    ssh_cmd = f"ssh -i {ssh_key} -o StrictHostKeyChecking=no root@{vault_host}"
    result = subprocess.run(f"{ssh_cmd} '{cmd}'", shell=True, capture_output=True, text=True)
    return result.stdout.strip(), result.returncode

print("=== PH6-02 - Réinitialisation et Initialisation de Vault ===")
print(f"Host: {vault_host}")
print(f"Vault Address: {vault_addr}")
print()
print("⚠️  ATTENTION: Ce script va réinitialiser Vault (perte de toutes les données)")
print()

# Arrêter Vault
print("1. Arrêt de Vault...")
stdout, rc = run_ssh("systemctl stop vault")
print("   ✅ Vault arrêté")
print()

# Supprimer les données existantes
print("2. Suppression des données existantes...")
stdout, rc = run_ssh("rm -rf /data/vault/storage/* && echo 'STORAGE_CLEARED'")
if 'STORAGE_CLEARED' in stdout:
    print("   ✅ Données supprimées")
else:
    print(f"   ⚠️  {stdout}")
print()

# Redémarrer Vault
print("3. Redémarrage de Vault...")
stdout, rc = run_ssh("systemctl start vault && sleep 5 && systemctl status vault --no-pager | head -5")
print("   ✅ Vault redémarré")
print()

# Attendre que Vault soit prêt
import time
print("4. Attente que Vault soit prêt...")
time.sleep(5)

# Initialiser Vault
print("5. Initialisation de Vault...")
init_cmd = f"export VAULT_ADDR='{vault_addr}' && export VAULT_SKIP_VERIFY=true && vault operator init -key-shares=1 -key-threshold=1 > /root/vault_init.txt 2>&1 && cat /root/vault_init.txt"
stdout, rc = run_ssh(init_cmd)

if 'Unseal Key' in stdout:
    print("   ✅ Vault initialisé")
    print("   📝 Clés sauvegardées dans /root/vault_init.txt")
    print()
    print("   Sortie complète:")
    print(stdout)
else:
    print(f"   ❌ Erreur lors de l'initialisation: {stdout}")
    sys.exit(1)
print()

# Extraire l'unseal key et root token
print("6. Extraction des clés...")
# Lire le fichier complet
read_cmd = "cat /root/vault_init.txt"
init_file, rc = run_ssh(read_cmd)

# Parser les clés depuis la sortie ou le fichier
unseal_key = None
root_token = None

for line in init_file.split('\n'):
    if 'Unseal Key 1:' in line:
        parts = line.split(':')
        if len(parts) > 1:
            unseal_key = parts[1].strip()
    elif 'Initial Root Token:' in line:
        parts = line.split(':')
        if len(parts) > 1:
            root_token = parts[1].strip()

# Si pas trouvé dans le fichier, essayer depuis stdout
if not unseal_key or not root_token:
    for line in stdout.split('\n'):
        if 'Unseal Key 1:' in line:
            parts = line.split(':')
            if len(parts) > 1:
                unseal_key = parts[1].strip()
        elif 'Initial Root Token:' in line:
            parts = line.split(':')
            if len(parts) > 1:
                root_token = parts[1].strip()

if not unseal_key or not root_token:
    print("   ❌ Impossible d'extraire les clés")
    print(f"   Debug - stdout: {stdout[:500]}")
    print(f"   Debug - init_file: {init_file[:500]}")
    sys.exit(1)

print(f"   ✅ Unseal Key: {unseal_key[:10]}... ({len(unseal_key)} caractères)")
print(f"   ✅ Root Token: {root_token[:10]}... ({len(root_token)} caractères)")
print()

# Unseal Vault
print("7. Unseal de Vault...")
unseal_cmd = f"export VAULT_ADDR='{vault_addr}' && export VAULT_SKIP_VERIFY=true && vault operator unseal {unseal_key} 2>&1"
stdout, rc = run_ssh(unseal_cmd)
print(stdout)
print()

# Vérifier le statut final
print("8. Vérification du statut final...")
status_cmd = f"export VAULT_ADDR='{vault_addr}' && export VAULT_SKIP_VERIFY=true && vault status 2>&1"
stdout, rc = run_ssh(status_cmd)
print(stdout)
print()

if 'Sealed.*false' in stdout or 'Vault is unsealed' in stdout:
    print("=== ✅ Vault initialisé et unsealed avec succès ===")
    print()
    print("⚠️  IMPORTANT: Sauvegardez /root/vault_init.txt dans un coffre sécurisé")
    print("   Ne jamais commiter ce fichier dans Git !")
else:
    print("=== ⚠️  Vault toujours sealed ===")

