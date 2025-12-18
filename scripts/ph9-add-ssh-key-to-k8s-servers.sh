#!/bin/bash
# PH9 - Ajouter la clé SSH Hetzner "install-v3-keybuzz" aux 8 serveurs K8s
# Ce script ajoute la clé SSH Hetzner aux serveurs via l'API Hetzner

set -e

LOG_DIR="/opt/keybuzz/logs/phase9-hcloud-rebuild"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/add-ssh-key-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================================="
echo "PH9 - AJOUT CLÉ SSH HETZNER AUX SERVEURS K8S"
echo "Date: $(date)"
echo "=============================================="
echo ""

# Configuration
ENV_FILE="/opt/keybuzz/credentials/hcloud.env"
HETZNER_SSH_KEY_NAME="install-v3-keybuzz"
UBUNTU_IMAGE="ubuntu-24.04"

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

# Vérifier hcloud
if ! command -v hcloud &> /dev/null; then
    echo "[ERROR] hcloud CLI n'est pas installé"
    exit 1
fi

# Vérifier jq
if ! command -v jq &> /dev/null; then
    echo "[ERROR] jq n'est pas installé"
    exit 1
fi

# Vérifier curl
if ! command -v curl &> /dev/null; then
    echo "[ERROR] curl n'est pas installé"
    exit 1
fi

# Tester la connexion
if ! hcloud server list &> /dev/null; then
    echo "[ERROR] Impossible de se connecter à Hetzner Cloud. Vérifiez le token."
    exit 1
fi

# Vérifier que la clé SSH Hetzner existe et obtenir son ID
SSH_KEY_ID=$(hcloud ssh-key list -o json 2>/dev/null | jq -r ".[] | select(.name == \"$HETZNER_SSH_KEY_NAME\") | .id // empty")

if [ -z "$SSH_KEY_ID" ]; then
    echo "[ERROR] Clé SSH Hetzner '$HETZNER_SSH_KEY_NAME' non trouvée"
    exit 1
fi

echo "[OK] Connexion Hetzner Cloud OK"
echo "[OK] Clé SSH Hetzner '$HETZNER_SSH_KEY_NAME' trouvée (ID: $SSH_KEY_ID)"
echo ""

# ==========================================
# Ajouter la clé SSH aux serveurs
# ==========================================
echo "=== Ajout de la clé SSH Hetzner aux serveurs ==="
echo ""

ADDED=0
ALREADY_HAS_KEY=0
FAILED=0

add_ssh_key_to_server() {
    local hostname=$1
    
    echo "[INFO] Traitement de $hostname..."
    
    # Obtenir l'ID du serveur
    local server_id
    server_id=$(hcloud server describe "$hostname" -o json 2>/dev/null | jq -r '.id // empty')
    
    if [ -z "$server_id" ]; then
        echo "  [ERROR] Serveur $hostname non trouvé"
        return 1
    fi
    
    # Vérifier si le serveur a déjà la clé SSH
    has_ssh_key=$(hcloud server describe "$hostname" -o json 2>/dev/null | jq -r ".ssh_keys[]?.id // empty" | grep -c "^$SSH_KEY_ID$" || echo "0")
    
    if [ "$has_ssh_key" -gt 0 ]; then
        echo "  [SKIP] $hostname a déjà la clé SSH '$HETZNER_SSH_KEY_NAME'"
        return 2
    fi
    
    # Obtenir toutes les clés SSH actuelles du serveur
    current_ssh_keys=$(hcloud server describe "$hostname" -o json 2>/dev/null | jq -r '[.ssh_keys[]?.id] | @json')
    
    # Ajouter notre clé SSH à la liste si elle n'est pas déjà présente
    all_ssh_keys=$(echo "$current_ssh_keys" | jq ". + [$SSH_KEY_ID] | unique")
    
    # Utiliser l'API Hetzner pour rebuild avec la clé SSH
    # Note: L'API Hetzner permet de rebuild avec des clés SSH spécifiques
    echo "  [INFO] Rebuild de $hostname avec la clé SSH '$HETZNER_SSH_KEY_NAME'..."
    
    # Obtenir l'ID de l'image Ubuntu 24.04
    image_id=$(hcloud image list -o json 2>/dev/null | jq -r ".[] | select(.name | contains(\"$UBUNTU_IMAGE\")) | .id" | head -1)
    
    if [ -z "$image_id" ]; then
        echo "  [ERROR] Image $UBUNTU_IMAGE non trouvée"
        return 1
    fi
    
    # Utiliser l'API Hetzner pour rebuild avec la clé SSH
    response=$(curl -s -X POST \
        -H "Authorization: Bearer $HCLOUD_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"image\": \"$image_id\", \"ssh_keys\": $all_ssh_keys}" \
        "https://api.hetzner.cloud/v1/servers/$server_id/actions/rebuild" 2>&1)
    
    if echo "$response" | jq -e '.action // empty' &>/dev/null; then
        echo "  [OK] Rebuild de $hostname lancé avec clé SSH"
        return 0
    else
        echo "  [ERROR] Échec rebuild avec clé SSH"
        echo "  [DEBUG] Réponse API: $response"
        return 1
    fi
}

for server in "${ALL_SERVERS[@]}"; do
    if add_ssh_key_to_server "$server"; then
        ADDED=$((ADDED + 1))
    elif [ $? -eq 2 ]; then
        ALREADY_HAS_KEY=$((ALREADY_HAS_KEY + 1))
    else
        FAILED=$((FAILED + 1))
    fi
    sleep 0.5
done

echo ""
echo "=============================================="
echo "AJOUT CLÉ SSH TERMINÉ"
echo "=============================================="
echo ""
echo "📋 RÉSUMÉ:"
echo "  - Clés SSH ajoutées: $ADDED"
echo "  - Serveurs ayant déjà la clé: $ALREADY_HAS_KEY"
echo "  - Échecs: $FAILED"
echo ""

# Vérification finale
echo "=== Vérification finale ==="
echo ""
echo "[INFO] Clés SSH attachées aux serveurs:"
for server in "${ALL_SERVERS[@]}"; do
    ssh_keys=$(hcloud server describe "$server" -o json 2>/dev/null | jq -r '[.ssh_keys[]?.name] | join(", ") // "none"')
    has_key=$(echo "$ssh_keys" | grep -c "$HETZNER_SSH_KEY_NAME" || echo "0")
    if [ "$has_key" -gt 0 ]; then
        echo "  ✓ $server: $ssh_keys"
    else
        echo "  ✗ $server: $ssh_keys (MANQUE: $HETZNER_SSH_KEY_NAME)"
    fi
done

echo ""
echo "📄 Logs complets: $LOG_FILE"
echo ""

# Retourner 0 si succès, 1 si échecs
if [ $FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi

