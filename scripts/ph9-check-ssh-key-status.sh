#!/bin/bash
# PH9 - Vérifier le statut de la clé SSH Hetzner sur les serveurs K8s
# Ce script vérifie si les serveurs ont déjà la clé SSH "install-v3-keybuzz"

set -e

LOG_DIR="/opt/keybuzz/logs/phase9-hcloud-rebuild"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/check-ssh-key-status-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================================="
echo "PH9 - VÉRIFICATION CLÉ SSH HETZNER"
echo "Date: $(date)"
echo "=============================================="
echo ""

# Configuration
ENV_FILE="/opt/keybuzz/credentials/hcloud.env"
HETZNER_SSH_KEY_NAME="install-v3-keybuzz"

# Liste des serveurs K8s
MASTERS=("k8s-master-01" "k8s-master-02" "k8s-master-03")
WORKERS=("k8s-worker-01" "k8s-worker-02" "k8s-worker-03" "k8s-worker-04" "k8s-worker-05")
ALL_SERVERS=("${MASTERS[@]}" "${WORKERS[@]}")

# Charger le token hcloud
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
    export HCLOUD_TOKEN
    echo "[OK] Token hcloud chargé depuis $ENV_FILE"
else
    echo "[ERROR] Fichier $ENV_FILE non trouvé"
    exit 1
fi

# Vérifier que la clé SSH Hetzner existe et obtenir son ID
SSH_KEY_ID=$(hcloud ssh-key list -o json 2>/dev/null | jq -r ".[] | select(.name == \"$HETZNER_SSH_KEY_NAME\") | .id // empty")

if [ -z "$SSH_KEY_ID" ]; then
    echo "[ERROR] Clé SSH Hetzner '$HETZNER_SSH_KEY_NAME' non trouvée"
    exit 1
fi

echo "[OK] Clé SSH Hetzner '$HETZNER_SSH_KEY_NAME' trouvée (ID: $SSH_KEY_ID)"
echo ""

# Vérifier le statut sur chaque serveur
HAS_KEY=0
MISSING_KEY=0

echo "=== Statut de la clé SSH sur les serveurs ==="
echo ""

for server in "${ALL_SERVERS[@]}"; do
    ssh_keys=$(hcloud server describe "$server" -o json 2>/dev/null | jq -r '[.ssh_keys[]?.name] | join(", ") // "none"')
    has_key=$(echo "$ssh_keys" | grep -c "$HETZNER_SSH_KEY_NAME" || echo "0")
    
    if [ "$has_key" -gt 0 ]; then
        echo "  ✓ $server: $ssh_keys"
        HAS_KEY=$((HAS_KEY + 1))
    else
        echo "  ✗ $server: $ssh_keys (MANQUE: $HETZNER_SSH_KEY_NAME)"
        MISSING_KEY=$((MISSING_KEY + 1))
    fi
done

echo ""
echo "=============================================="
echo "RÉSUMÉ"
echo "=============================================="
echo ""
echo "  - Serveurs avec la clé SSH: $HAS_KEY/${#ALL_SERVERS[@]}"
echo "  - Serveurs sans la clé SSH: $MISSING_KEY/${#ALL_SERVERS[@]}"
echo ""

if [ $MISSING_KEY -eq 0 ]; then
    echo "✅ Tous les serveurs ont déjà la clé SSH '$HETZNER_SSH_KEY_NAME'"
    echo "✅ Le rebuild conservera cette clé SSH"
    exit 0
else
    echo "⚠️  $MISSING_KEY serveur(s) n'ont pas la clé SSH"
    echo "ℹ️  Le script de rebuild utilisera l'API Hetzner pour rebuilder avec la clé SSH"
    exit 0
fi

