#!/bin/bash
# PH9 - Rebuild complet des 8 serveurs Kubernetes via Hetzner Cloud
# Ce script:
# 1. Détache et supprime les volumes existants (workers)
# 2. Rebuild les serveurs via hcloud avec Ubuntu 24.04
# 3. Recrée les volumes (workers)
# 4. Prépare pour la phase 2 de configuration

set -e

LOG_DIR="/opt/keybuzz/logs/phase9-hcloud-rebuild"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/rebuild-k8s-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================================="
echo "PH9 - REBUILD COMPLET K8S SERVEURS VIA HCLOUD"
echo "Date: $(date)"
echo "=============================================="
echo ""

# Configuration
ENV_FILE="/opt/keybuzz/credentials/hcloud.env"
UBUNTU_IMAGE="ubuntu-24.04"

# Liste des serveurs K8s
MASTERS=("k8s-master-01" "k8s-master-02" "k8s-master-03")
WORKERS=("k8s-worker-01" "k8s-worker-02" "k8s-worker-03" "k8s-worker-04" "k8s-worker-05")
ALL_SERVERS=("${MASTERS[@]}" "${WORKERS[@]}")

# Configuration volumes workers (50GB pour containerd)
WORKER_VOLUME_SIZE=50
WORKER_MOUNT_PATH="/var/lib/containerd"

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

# Tester la connexion
if ! hcloud server list &> /dev/null; then
    echo "[ERROR] Impossible de se connecter à Hetzner Cloud. Vérifiez le token."
    exit 1
fi

echo "[OK] Connexion Hetzner Cloud OK"
echo ""

# ==========================================
# PHASE 1: Détacher et supprimer volumes workers
# ==========================================
echo "=== PHASE 1: Détachement et suppression des volumes workers ==="
echo ""

DETACHED=0
DELETED=0
FAILED=0

for worker in "${WORKERS[@]}"; do
    vol_name="vol-$worker"
    echo "[INFO] Traitement de $vol_name pour $worker..."
    
    # Vérifier si le volume existe
    if ! hcloud volume describe "$vol_name" &>/dev/null; then
        echo "  [SKIP] $vol_name n'existe pas"
        continue
    fi
    
    # Vérifier si le volume est attaché
    attached_server=$(hcloud volume describe "$vol_name" -o json 2>/dev/null | jq -r '.server // empty')
    
    if [ -n "$attached_server" ] && [ "$attached_server" != "null" ]; then
        echo "  [INFO] Détachement de $vol_name de $attached_server..."
        if hcloud volume detach "$vol_name" 2>/dev/null; then
            echo "  [OK] $vol_name détaché"
            DETACHED=$((DETACHED + 1))
            sleep 2
        else
            echo "  [WARN] Échec détachement de $vol_name"
        fi
    else
        echo "  [INFO] $vol_name déjà détaché"
    fi
    
    # Supprimer le volume
    echo "  [INFO] Suppression de $vol_name..."
    if hcloud volume delete "$vol_name" 2>/dev/null; then
        echo "  [OK] $vol_name supprimé"
        DELETED=$((DELETED + 1))
    else
        echo "  [WARN] Échec suppression de $vol_name (peut-être déjà supprimé)"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "Résumé volumes: $DETACHED détachés, $DELETED supprimés, $FAILED échecs"
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
    
    echo "[INFO] Rebuild de $hostname avec $UBUNTU_IMAGE..."
    
    if hcloud server rebuild --image "$UBUNTU_IMAGE" "$hostname" 2>/dev/null; then
        echo "  [OK] Rebuild de $hostname lancé"
        return 0
    else
        echo "  [ERROR] Échec rebuild de $hostname"
        return 1
    fi
}

# Rebuild en parallèle (mais avec un délai pour éviter rate limiting)
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

for server in "${ALL_SERVERS[@]}"; do
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
# PHASE 4: Créer et attacher volumes workers
# ==========================================
echo ""
echo "=== PHASE 4: Création et attachement des volumes workers ==="
echo ""

CREATED=0
ATTACHED=0

create_and_attach_volume() {
    local worker=$1
    local vol_name="vol-$worker"
    
    echo "[INFO] Création de $vol_name (${WORKER_VOLUME_SIZE}GB) pour $worker..."
    
    # Obtenir la location du serveur
    location=$(hcloud server describe "$worker" -o json 2>/dev/null | jq -r '.datacenter.location.name // "nbg1"')
    
    if [ -z "$location" ] || [ "$location" = "null" ]; then
        location="nbg1"  # Default
    fi
    
    # Créer le volume
    if hcloud volume create --name "$vol_name" --size "$WORKER_VOLUME_SIZE" --location "$location" 2>/dev/null; then
        echo "  [OK] $vol_name créé"
        CREATED=$((CREATED + 1))
        sleep 2
        
        # Attacher le volume
        echo "  [INFO] Attachement de $vol_name à $worker..."
        if hcloud volume attach --server "$worker" "$vol_name" 2>/dev/null; then
            echo "  [OK] $vol_name attaché à $worker"
            ATTACHED=$((ATTACHED + 1))
            sleep 2
        else
            echo "  [WARN] Échec attachement de $vol_name"
        fi
    else
        echo "  [ERROR] Échec création de $vol_name"
    fi
}

for worker in "${WORKERS[@]}"; do
    create_and_attach_volume "$worker"
done

echo ""
echo "Résumé volumes: $CREATED créés, $ATTACHED attachés"
echo ""

# ==========================================
# PHASE 5: Vérification finale
# ==========================================
echo ""
echo "=== PHASE 5: Vérification finale ==="
echo ""

echo "[INFO] Statut des serveurs:"
for server in "${ALL_SERVERS[@]}"; do
    status=$(hcloud server describe "$server" -o json 2>/dev/null | jq -r '.status // "unknown"')
    ip_public=$(hcloud server describe "$server" -o json 2>/dev/null | jq -r '.public_net.ipv4.ip // "N/A"')
    echo "  - $server: $status (IP: $ip_public)"
done

echo ""
echo "[INFO] Volumes workers:"
for worker in "${WORKERS[@]}"; do
    vol_name="vol-$worker"
    if hcloud volume describe "$vol_name" &>/dev/null; then
        vol_status=$(hcloud volume describe "$vol_name" -o json 2>/dev/null | jq -r '.server // "non-attaché"')
        echo "  - $vol_name: attaché à $vol_status"
    else
        echo "  - $vol_name: N'EXISTE PAS"
    fi
done

echo ""
echo "=============================================="
echo "REBUILD TERMINÉ"
echo "=============================================="
echo ""
echo "📋 PROCHAINES ÉTAPES:"
echo "1. Redéployer la clé SSH sur les 8 serveurs"
echo "2. Exécuter la phase 2 de configuration (Base OS & Sécurité)"
echo "3. Configurer les volumes (formatage XFS et montage)"
echo ""
echo "📄 Logs complets: $LOG_FILE"
echo ""

