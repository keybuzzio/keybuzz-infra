#!/bin/bash
# Script d'initialisation de Vault

set -e

VAULT_ADDR="https://vault.keybuzz.io:8200"
export VAULT_ADDR

# Ignorer les erreurs de certificat auto-signé pour l'instant
export VAULT_SKIP_VERIFY=true

echo "=== PH6-02 - Initialisation de Vault ==="
echo "Vault Address: ${VAULT_ADDR}"
echo ""

# Vérifier que Vault est accessible
echo "1. Vérification de l'accessibilité de Vault..."
if vault status 2>&1 | grep -q "Sealed.*true"; then
    echo "   ✅ Vault est accessible et sealed (non initialisé)"
else
    echo "   ⚠️  État de Vault:"
    vault status 2>&1 || true
fi
echo ""

# Initialiser Vault
echo "2. Initialisation de Vault..."
INIT_OUTPUT=$(vault operator init -key-shares=1 -key-threshold=1 2>&1)

if echo "$INIT_OUTPUT" | grep -q "Unseal Key"; then
    echo "$INIT_OUTPUT" > /root/vault_init.txt
    echo "   ✅ Vault initialisé"
    echo "   📝 Clés sauvegardées dans /root/vault_init.txt"
else
    echo "   ⚠️  Erreur lors de l'initialisation:"
    echo "$INIT_OUTPUT"
    exit 1
fi
echo ""

# Extraire l'unseal key
UNSEAL_KEY=$(grep 'Unseal Key 1:' /root/vault_init.txt | awk '{print $4}')
ROOT_TOKEN=$(grep 'Initial Root Token:' /root/vault_init.txt | awk '{print $4}')

if [ -z "$UNSEAL_KEY" ] || [ -z "$ROOT_TOKEN" ]; then
    echo "   ❌ Impossible d'extraire les clés"
    exit 1
fi

# Unseal Vault
echo "3. Unseal de Vault..."
vault operator unseal "$UNSEAL_KEY" 2>&1 | grep -q "Sealed.*false" && echo "   ✅ Vault unsealed" || echo "   ⚠️  État après unseal:"
vault status 2>&1 | head -5
echo ""

# Login avec root token
echo "4. Login avec root token..."
export VAULT_TOKEN="$ROOT_TOKEN"
vault login "$ROOT_TOKEN" > /dev/null 2>&1
echo "   ✅ Authentifié avec root token"
echo ""

# Afficher les informations (sans le token réel)
echo "5. Informations d'initialisation:"
echo "   Unseal Key: ${UNSEAL_KEY:0:10}... (${#UNSEAL_KEY} caractères)"
echo "   Root Token: ${ROOT_TOKEN:0:10}... (${#ROOT_TOKEN} caractères)"
echo "   📝 Fichier complet: /root/vault_init.txt"
echo ""

echo "=== ✅ Initialisation terminée ==="
echo ""
echo "⚠️  IMPORTANT: Sauvegardez /root/vault_init.txt dans un coffre sécurisé"
echo "   Ne jamais commiter ce fichier dans Git !"

