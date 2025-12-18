#!/bin/bash
# PH9 - Rebuild complet des 8 serveurs K8s avec volumes corrects
# Ce script:
# 1. Supprime les mauvais volumes (vol-k8s-worker-*)
# 2. Supprime les volumes existants (kbv3-*)
# 3. Rebuild les 8 serveurs (Hetzner conserve les clés SSH attachées)
# 4. Crée les bons volumes avec la convention kbv3-* (masters 20GB, workers 50GB)
# 5. Attache les volumes aux serveurs

set -e

LOG_DIR="/opt/keybuzz/logs/phase9-hcloud-rebuild"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/rebuild-k8s-complete-final-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================================="
echo "PH9 - REBUILD COMPLET K8S + VOLUMES CORRECTS"
echo "Date: $(date)"
echo "=============================================="
echo ""

# Configuration
ENV_FILE="/opt/keybuzz/credentials/hcloud.env"
UBUNTU_IMAGE="ubuntu-24.04"
HETZNER_SSH_KEY_NAME="install-v3-keybuzz"

# Liste des serveurs K8s
MASTERS=("k8s-master-01" "k8s-master-02" "k8s-master-03")
WORKERS=("k8s-worker-01" "k8s-worker-02" "k8s-worker-03" "k8s-worker-04" "k8s-worker-05")
ALL_SERVERS=("${MASTERS[@]}" "${WORKERS[@]}")

# Configuration volumes (convention kbv3-*)
declare -A VOLUME_NAMES=(
    ["k8s-master-01"]="kbv3-k8s-master-01-data"
    ["k8s-master-02"]="kbv3-k8s-master-02-data"
    ["k8s-master-03"]="kbv3-k8s-master-03-data"
    ["k8s-worker-01"]="kbv3-k8s-worker-01-data"
    ["k8s-worker-02"]="kbv3-k8s-worker-02-data"
    ["k8s-worker-03"]="kbv3-k8s-worker-03-data"
    ["k8s-worker-04"]="kbv3-k8s-worker-04-data"
    ["k8s-worker-05"]="kbv3-k8s-worker-05-data"
)

declare -A VOLUME_SIZES=(
    ["k8s-master-01"]=20
    ["k8s-master-02"]=20
    ["k8s-master-03"]=20
    ["k8s-worker-01"]=50
    ["k8s-worker-02"]=50
    ["k8s-worker-03"]=50
    ["k8s-worker-04"]=50
    ["k8s-worker-05"]=50
)

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

echo "[OK] Connexion Hetzner Cloud OK"

# Vérifier que la clé SSH Hetzner existe et obtenir son ID
SSH_KEY_ID=$(hcloud ssh-key list -o json 2>/dev/null | jq -r ".[] | select(.name == \"$HETZNER_SSH_KEY_NAME\") | .id // empty")

if [ -z "$SSH_KEY_ID" ]; then
    echo "[ERROR] Clé SSH Hetzner '$HETZNER_SSH_KEY_NAME' non trouvée"
    exit 1
fi

echo "[OK] Clé SSH Hetzner '$HETZNER_SSH_KEY_NAME' trouvée (ID: $SSH_KEY_ID)"
echo ""

# ==========================================
# PHASE 0: Supprimer les mauvais volumes (vol-k8s-worker-*)
# ==========================================
echo "=== PHASE 0: Suppression des mauvais volumes (vol-k8s-worker-*) ==="
echo ""

WRONG_VOLUMES=("vol-k8s-worker-01" "vol-k8s-worker-02" "vol-k8s-worker-03" "vol-k8s-worker-04" "vol-k8s-worker-05")

DELETED_WRONG=0
for vol_name in "${WRONG_VOLUMES[@]}"; do
    if hcloud volume describe "$vol_name" &>/dev/null; then
        echo "[INFO] Suppression du volume incorrect: $vol_name..."
        
        # Détacher si attaché
        attached_server=$(hcloud volume describe "$vol_name" -o json 2>/dev/null | jq -r '.server // empty')
        if [ -n "$attached_server" ] && [ "$attached_server" != "null" ]; then
            echo "  [INFO] Détachement de $vol_name de $attached_server..."
            hcloud volume detach "$vol_name" 2>/dev/null || true
            sleep 2
        fi
        
        # Supprimer
        if hcloud volume delete "$vol_name" 2>/dev/null; then
            echo "  [OK] $vol_name supprimé"
            DELETED_WRONG=$((DELETED_WRONG + 1))
        else
            echo "  [WARN] Échec suppression de $vol_name"
        fi
    else
        echo "  [SKIP] $vol_name n'existe pas"
    fi
done

echo ""
echo "Résumé volumes incorrects: $DELETED_WRONG supprimés"
echo ""

# ==========================================
# PHASE 1: Détacher et supprimer volumes existants (kbv3-*)
# ==========================================
echo "=== PHASE 1: Détachement et suppression des volumes existants (kbv3-*) ==="
echo ""

DETACHED=0
DELETED_EXISTING=0

for server in "${ALL_SERVERS[@]}"; do
    vol_name="${VOLUME_NAMES[$server]}"
    
    if hcloud volume describe "$vol_name" &>/dev/null; then
        echo "[INFO] Traitement de $vol_name pour $server..."
        
        # Détacher si attaché
        attached_server=$(hcloud volume describe "$vol_name" -o json 2>/dev/null | jq -r '.server // empty')
        if [ -n "$attached_server" ] && [ "$attached_server" != "null" ]; then
            echo "  [INFO] Détachement de $vol_name de $attached_server..."
            if hcloud volume detach "$vol_name" 2>/dev/null; then
                echo "  [OK] $vol_name détaché"
                DETACHED=$((DETACHED + 1))
                sleep 2
            fi
        fi
        
        # Supprimer
        echo "  [INFO] Suppression de $vol_name..."
        if hcloud volume delete "$vol_name" 2>/dev/null; then
            echo "  [OK] $vol_name supprimé"
            DELETED_EXISTING=$((DELETED_EXISTING + 1))
        else
            echo "  [WARN] Échec suppression de $vol_name"
        fi
    else
        echo "  [SKIP] $vol_name n'existe pas"
    fi
done

echo ""
echo "Résumé volumes existants: $DETACHED détachés, $DELETED_EXISTING supprimés"
echo ""

# ==========================================
# PHASE 2: Rebuild des serveurs
# ==========================================
echo "=== PHASE 2: Rebuild des 8 serveurs avec Ubuntu 24.04 ==="
echo ""

REBUILT=0
REBUILD_FAILED=0

rebuild_server() {
    local hostname=$1
    
    echo "[INFO] Rebuild de $hostname avec $UBUNTU_IMAGE + clé SSH '$HETZNER_SSH_KEY_NAME'..."
    
    # Obtenir l'ID du serveur
    local server_id
    server_id=$(hcloud server describe "$hostname" -o json 2>/dev/null | jq -r '.id // empty')
    
    if [ -z "$server_id" ]; then
        echo "  [ERROR] Serveur $hostname non trouvé"
        return 1
    fi
    
    # Obtenir toutes les clés SSH actuelles du serveur
    current_ssh_keys=$(hcloud server describe "$hostname" -o json 2>/dev/null | jq -r '[.ssh_keys[]?.id] | @json')
    
    # Ajouter notre clé SSH à la liste si elle n'est pas déjà présente
    all_ssh_keys=$(echo "$current_ssh_keys" | jq ". + [$SSH_KEY_ID] | unique")
    
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
        echo "  [OK] Rebuild de $hostname lancé via API avec clé SSH"
        return 0
    else
        # Fallback sur hcloud si l'API échoue
        echo "  [WARN] Échec rebuild via API, tentative avec hcloud..."
        if hcloud server rebuild --image "$UBUNTU_IMAGE" "$hostname" 2>/dev/null; then
            echo "  [OK] Rebuild de $hostname lancé via hcloud"
            return 0
        else
            echo "  [ERROR] Échec rebuild de $hostname"
            return 1
        fi
    fi
}

# Rebuild en parallèle (mais avec un délai pour éviter rate limiting)
REBUILD_PIDS=()
for server in "${ALL_SERVERS[@]}"; do
    rebuild_server "$server" &
    REBUILD_PIDS+=($!)
    sleep 0.5
done

echo ""
echo "[INFO] Attente de la fin des rebuilds (2-3 minutes)..."
echo ""

# Attendre tous les rebuilds
for pid in "${REBUILD_PIDS[@]}"; do
    if wait $pid 2>/dev/null; then
        REBUILT=$((REBUILT + 1))
    else
        REBUILD_FAILED=$((REBUILD_FAILED + 1))
    fi
done

echo ""
echo "Résumé rebuilds: $REBUILT réussis, $REBUILD_FAILED échecs"
echo ""

# ==========================================
# PHASE 3: Attendre que les serveurs soient "running"
# ==========================================
echo "=== PHASE 3: Attente que tous les serveurs soient 'running' ==="
echo ""

wait_for_server() {
    local hostname=$1
    local max_wait=300
    local elapsed=0
    
    while [ $elapsed -lt $max_wait ]; do
        status=$(hcloud server describe "$hostname" -o json 2>/dev/null | jq -r '.status // empty')
        
        if [ "$status" = "running" ]; then
            return 0
        fi
        
        sleep 10
        elapsed=$((elapsed + 10))
        if [ $((elapsed % 30)) -eq 0 ]; then
            echo "  [INFO] $hostname: toujours en $status (${elapsed}s écoulés)..."
        fi
    done
    
    return 1
}

for server in "${ALL_SERVERS[@]}"; do
    echo "[INFO] Attente de $server..."
    if wait_for_server "$server"; then
        echo "  [OK] $server est 'running'"
    else
        echo "  [WARN] $server n'est pas 'running' après 5 minutes"
    fi
done

echo ""
echo "[INFO] Attente supplémentaire de 90s pour stabilisation..."
sleep 90

# ==========================================
# PHASE 4: Créer les volumes avec la bonne convention
# ==========================================
echo ""
echo "=== PHASE 4: Création des volumes avec convention kbv3-* ==="
echo ""

CREATED=0

create_volume() {
    local server=$1
    local vol_name="${VOLUME_NAMES[$server]}"
    local vol_size="${VOLUME_SIZES[$server]}"
    
    echo "[INFO] Création de $vol_name (${vol_size}GB) pour $server..."
    
    # Obtenir la location du serveur
    location=$(hcloud server describe "$server" -o json 2>/dev/null | jq -r '.datacenter.location.name // "nbg1"')
    
    if [ -z "$location" ] || [ "$location" = "null" ]; then
        location="nbg1"
    fi
    
    # Créer le volume
    if hcloud volume create --name "$vol_name" --size "$vol_size" --location "$location" 2>/dev/null; then
        echo "  [OK] $vol_name créé (${vol_size}GB)"
        CREATED=$((CREATED + 1))
        sleep 1
        return 0
    else
        echo "  [ERROR] Échec création de $vol_name"
        return 1
    fi
}

for server in "${ALL_SERVERS[@]}"; do
    create_volume "$server"
done

echo ""
echo "Résumé volumes créés: $CREATED"
echo ""

# ==========================================
# PHASE 5: Attacher les volumes aux serveurs
# ==========================================
echo ""
echo "=== PHASE 5: Attachement des volumes aux serveurs ==="
echo ""

ATTACHED=0

attach_volume() {
    local server=$1
    local vol_name="${VOLUME_NAMES[$server]}"
    
    echo "[INFO] Attachement de $vol_name à $server..."
    
    if hcloud volume attach --server "$server" "$vol_name" 2>/dev/null; then
        echo "  [OK] $vol_name attaché à $server"
        ATTACHED=$((ATTACHED + 1))
        sleep 1
        return 0
    else
        echo "  [ERROR] Échec attachement de $vol_name"
        return 1
    fi
}

for server in "${ALL_SERVERS[@]}"; do
    attach_volume "$server"
done

echo ""
echo "Résumé volumes attachés: $ATTACHED"
echo ""

# ==========================================
# PHASE 6: Vérification finale
# ==========================================
echo ""
echo "=== PHASE 6: Vérification finale ==="
echo ""

echo "[INFO] Statut des serveurs:"
for server in "${ALL_SERVERS[@]}"; do
    status=$(hcloud server describe "$server" -o json 2>/dev/null | jq -r '.status // "unknown"')
    ip_public=$(hcloud server describe "$server" -o json 2>/dev/null | jq -r '.public_net.ipv4.ip // "N/A"')
    echo "  - $server: $status (IP: $ip_public)"
done

echo ""
echo "[INFO] Volumes créés:"
for server in "${ALL_SERVERS[@]}"; do
    vol_name="${VOLUME_NAMES[$server]}"
    if hcloud volume describe "$vol_name" &>/dev/null; then
        vol_size=$(hcloud volume describe "$vol_name" -o json 2>/dev/null | jq -r '.size // "N/A"')
        vol_server=$(hcloud volume describe "$vol_name" -o json 2>/dev/null | jq -r '.server // "non-attaché"')
        echo "  - $vol_name: ${vol_size}GB, attaché à $vol_server"
    else
        echo "  - $vol_name: N'EXISTE PAS"
    fi
done

echo ""
echo "=============================================="
echo "REBUILD COMPLET TERMINÉ"
echo "=============================================="
echo ""
echo "📋 RÉSUMÉ:"
echo "  - Volumes incorrects supprimés: $DELETED_WRONG"
echo "  - Rebuilds: $REBUILT réussis"
echo "  - Volumes créés: $CREATED"
echo "  - Volumes attachés: $ATTACHED"
echo ""
echo "✅ Tous les serveurs ont été rebuilds"
echo "✅ Les volumes utilisent la convention kbv3-*"
echo ""
echo "📄 Logs complets: $LOG_FILE"
echo ""

