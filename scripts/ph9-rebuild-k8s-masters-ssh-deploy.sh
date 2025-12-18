#!/bin/bash
# PH9 - Rebuild des 3 masters K8s (automatique, sans interaction)
# Ce script:
# 1. Rebuild les 3 masters via hcloud avec Ubuntu 24.04
# 2. Attend que les serveurs soient "running"
# 3. Teste la connexion SSH avec la clé (comme pour les workers)
# Aucune interaction requise, aucun mot de passe nécessaire

set -e

LOG_DIR="/opt/keybuzz/logs/phase9-hcloud-rebuild"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/rebuild-masters-ssh-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================================="
echo "PH9 - REBUILD MASTERS K8S + DEPLOIEMENT SSH"
echo "Date: $(date)"
echo "=============================================="
echo ""

# Configuration
ENV_FILE="/opt/keybuzz/credentials/hcloud.env"
UBUNTU_IMAGE="ubuntu-24.04"
SSH_KEY_PATH="/root/.ssh/id_rsa_keybuzz_v3"
SSH_PUB_KEY_PATH="/root/.ssh/id_rsa_keybuzz_v3.pub"

# Liste des masters K8s
MASTERS=("k8s-master-01" "k8s-master-02" "k8s-master-03")

# IPs privées des masters (pour SSH après rebuild)
declare -A MASTER_IPS=(
    ["k8s-master-01"]="10.0.0.100"
    ["k8s-master-02"]="10.0.0.101"
    ["k8s-master-03"]="10.0.0.102"
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

# Vérifier la clé SSH
if [ ! -f "$SSH_PUB_KEY_PATH" ]; then
    echo "[ERROR] Clé SSH publique non trouvée: $SSH_PUB_KEY_PATH"
    exit 1
fi

SSH_PUB_KEY=$(cat "$SSH_PUB_KEY_PATH")
echo "[OK] Clé SSH publique chargée"
echo ""

# Tester la connexion
if ! hcloud server list &> /dev/null; then
    echo "[ERROR] Impossible de se connecter à Hetzner Cloud. Vérifiez le token."
    exit 1
fi

echo "[OK] Connexion Hetzner Cloud OK"
echo ""

# ==========================================
# PHASE 1: Rebuild des masters
# ==========================================
echo "=== PHASE 1: Rebuild des 3 masters avec Ubuntu 24.04 ==="
echo ""

REBUILT=0
REBUILD_FAILED=0

rebuild_server() {
    local hostname=$1
    
    echo "[INFO] Rebuild de $hostname avec $UBUNTU_IMAGE..."
    
    # Rebuild normal (Hetzner injecte automatiquement les clés SSH configurées)
    if hcloud server rebuild --image "$UBUNTU_IMAGE" "$hostname" 2>/dev/null; then
        echo "  [OK] Rebuild de $hostname lancé"
        return 0
    else
        echo "  [ERROR] Échec rebuild de $hostname"
        return 1
    fi
}

# Rebuild en parallèle (mais avec un délai pour éviter rate limiting)
REBUILD_PIDS=()
for server in "${MASTERS[@]}"; do
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
# PHASE 2: Attendre que les serveurs soient "running"
# ==========================================
echo "=== PHASE 2: Attente que tous les masters soient 'running' ==="
echo ""

wait_for_server() {
    local hostname=$1
    local max_wait=300  # 5 minutes max
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

for server in "${MASTERS[@]}"; do
    echo "[INFO] Attente de $server..."
    if wait_for_server "$server"; then
        echo "  [OK] $server est 'running'"
    else
        echo "  [WARN] $server n'est pas 'running' après 5 minutes"
    fi
done

echo ""
echo "[INFO] Attente supplémentaire de 60s pour stabilisation..."
sleep 60

# ==========================================
# PHASE 3: Attendre que SSH soit accessible avec la clé SSH
# ==========================================
echo ""
echo "=== PHASE 3: Attente que SSH soit accessible avec la clé SSH ==="
echo ""

wait_for_ssh() {
    local ip=$1
    local hostname=$2
    local max_wait=300  # 5 minutes max
    local elapsed=0
    
    while [ $elapsed -lt $max_wait ]; do
        # Essayer de se connecter avec la clé SSH (Hetzner l'injecte automatiquement si configurée)
        if ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes root@"$ip" "echo OK" &>/dev/null; then
            return 0
        fi
        
        sleep 10
        elapsed=$((elapsed + 10))
        if [ $((elapsed % 30)) -eq 0 ]; then
            echo "  [INFO] $hostname: SSH pas encore accessible avec la clé (${elapsed}s écoulés)..."
        fi
    done
    
    return 1
}

for server in "${MASTERS[@]}"; do
    ip="${MASTER_IPS[$server]}"
    echo "[INFO] Attente que SSH soit accessible sur $server ($ip) avec la clé SSH..."
    if wait_for_ssh "$ip" "$server"; then
        echo "  [OK] SSH accessible sur $server avec la clé"
    else
        echo "  [WARN] SSH pas accessible sur $server après 5 minutes"
    fi
done

echo ""
echo "[INFO] Attente supplémentaire de 30s pour stabilisation..."
sleep 30

# ==========================================
# PHASE 4: Vérification finale
# ==========================================
echo ""
echo "=== PHASE 4: Vérification finale ==="
echo ""

VERIFIED=0
FAILED_VERIFY=0

echo "[INFO] Statut des masters:"
for server in "${MASTERS[@]}"; do
    status=$(hcloud server describe "$server" -o json 2>/dev/null | jq -r '.status // "unknown"')
    ip="${MASTER_IPS[$server]}"
    ip_public=$(hcloud server describe "$server" -o json 2>/dev/null | jq -r '.public_net.ipv4.ip // "N/A"')
    echo "  - $server: $status (IP privée: $ip, IP publique: $ip_public)"
    
    # Tester la connexion SSH avec la clé (Hetzner l'injecte automatiquement)
    if ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes root@"$ip" "echo OK" &>/dev/null; then
        echo "    ✓ SSH accessible avec clé"
        VERIFIED=$((VERIFIED + 1))
    else
        echo "    ✗ SSH non accessible avec clé"
        FAILED_VERIFY=$((FAILED_VERIFY + 1))
    fi
done

echo ""
echo "=============================================="
echo "REBUILD MASTERS + DEPLOIEMENT SSH TERMINÉ"
echo "=============================================="
echo ""
echo "📋 RÉSUMÉ:"
echo "  - Rebuilds: $REBUILT réussis"
echo "  - Masters vérifiés (SSH avec clé): $VERIFIED/3"
echo "  - Échecs: $FAILED_VERIFY"
echo ""
echo "✅ Rebuild automatique sans interaction"
echo "✅ Connexion SSH testée avec la clé"
echo ""
echo "📄 Logs complets: $LOG_FILE"
echo ""

