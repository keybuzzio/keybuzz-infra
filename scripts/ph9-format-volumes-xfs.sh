#!/bin/bash
# PH9 - Formater et monter les volumes en XFS sur les serveurs K8s
# Ce script formate les volumes attachés en XFS et les monte

set -e

LOG_DIR="/opt/keybuzz/logs/phase9-hcloud-rebuild"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/format-volumes-xfs-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================================="
echo "PH9 - FORMATAGE ET MONTAGE VOLUMES XFS"
echo "Date: $(date)"
echo "=============================================="
echo ""

SSH_KEY_PATH="/root/.ssh/id_rsa_keybuzz_v3"

# Liste des serveurs avec leurs IPs privées
declare -A SERVERS=(
    ["k8s-master-01"]="10.0.0.100"
    ["k8s-master-02"]="10.0.0.101"
    ["k8s-master-03"]="10.0.0.102"
    ["k8s-worker-01"]="10.0.0.110"
    ["k8s-worker-02"]="10.0.0.111"
    ["k8s-worker-03"]="10.0.0.112"
    ["k8s-worker-04"]="10.0.0.113"
    ["k8s-worker-05"]="10.0.0.114"
)

# Tailles des volumes (en GB)
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

# Points de montage
declare -A MOUNT_PATHS=(
    ["k8s-master-01"]="/opt/k8s/data"
    ["k8s-master-02"]="/opt/k8s/data"
    ["k8s-master-03"]="/opt/k8s/data"
    ["k8s-worker-01"]="/opt/k8s/data"
    ["k8s-worker-02"]="/opt/k8s/data"
    ["k8s-worker-03"]="/opt/k8s/data"
    ["k8s-worker-04"]="/opt/k8s/data"
    ["k8s-worker-05"]="/opt/k8s/data"
)

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "[ERROR] Clé SSH non trouvée: $SSH_KEY_PATH"
    exit 1
fi

FORMATTED=0
MOUNTED=0
FAILED=0

format_and_mount_volume() {
    local hostname=$1
    local server_ip=$2
    local vol_size=$3
    local mount_path=$4
    
    echo "[INFO] Formatage et montage du volume sur $hostname ($server_ip)..."
    
    if ssh -i "$SSH_KEY_PATH" \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=10 \
        root@"$server_ip" bash -s "$vol_size" "$mount_path" <<'FORMAT_SCRIPT'
        VOL_SIZE="$1"
        MOUNT_PATH="$2"
        
        set -e
        
        # Installer xfsprogs si nécessaire
        if ! command -v mkfs.xfs >/dev/null 2>&1; then
            apt-get update -qq && apt-get install -y -qq xfsprogs
        fi
        
        # Créer le point de montage
        mkdir -p "$MOUNT_PATH"
        
        # Détecter le device du volume
        DEVICE=""
        TARGET_SIZE=$((VOL_SIZE * 1000000000))
        TOLERANCE=$((TARGET_SIZE / 10))
        
        # Essayer d'abord avec /dev/disk/by-id (Hetzner Cloud)
        for dev in /dev/disk/by-id/scsi-*; do
            if [ -L "$dev" ]; then
                real_dev=$(readlink -f "$dev" 2>/dev/null || echo "")
                if [ -n "$real_dev" ] && [ -b "$real_dev" ]; then
                    if ! mount | grep -q "$real_dev"; then
                        DEV_SIZE=$(lsblk -b -n -o SIZE "$real_dev" 2>/dev/null | head -1)
                        if [ -n "$DEV_SIZE" ]; then
                            if [ $DEV_SIZE -gt $((TARGET_SIZE - TOLERANCE)) ] && [ $DEV_SIZE -lt $((TARGET_SIZE + TOLERANCE)) ]; then
                                DEVICE="$real_dev"
                                break
                            fi
                        fi
                    fi
                fi
            fi
        done
        
        # Fallback sur /dev/sdX
        if [ -z "$DEVICE" ]; then
            for dev in /dev/sd{b..z} /dev/vd{b..z}; do
                if [ -b "$dev" ]; then
                    if ! mount | grep -q "$dev"; then
                        DEV_SIZE=$(lsblk -b -n -o SIZE "$dev" 2>/dev/null | head -1)
                        if [ -n "$DEV_SIZE" ]; then
                            if [ $DEV_SIZE -gt $((TARGET_SIZE - TOLERANCE)) ] && [ $DEV_SIZE -lt $((TARGET_SIZE + TOLERANCE)) ]; then
                                DEVICE="$dev"
                                break
                            fi
                        fi
                    fi
                fi
            done
        fi
        
        if [ -z "$DEVICE" ]; then
            echo "ERROR: Device non trouvé pour volume de ${VOL_SIZE}GB"
            exit 1
        fi
        
        echo "Device détecté: $DEVICE"
        
        # Vérifier si déjà monté
        if mountpoint -q "$MOUNT_PATH" 2>/dev/null; then
            current_fs=$(df -T "$MOUNT_PATH" | tail -1 | awk '{print $2}')
            if [ "$current_fs" = "xfs" ]; then
                echo "Volume déjà monté en XFS sur $MOUNT_PATH"
                exit 0
            else
                echo "Démontage de $MOUNT_PATH (type: $current_fs)..."
                umount "$MOUNT_PATH" || true
            fi
        fi
        
        # Nettoyer toute signature de filesystem existante
        wipefs -af "$DEVICE" 2>/dev/null || true
        
        # Formater en XFS
        echo "Formatage XFS de $DEVICE..."
        mkfs.xfs -f -m crc=1,finobt=1 "$DEVICE" || {
            echo "ERROR: Échec formatage XFS"
            exit 1
        }
        
        # Monter le volume
        echo "Montage de $DEVICE sur $MOUNT_PATH..."
        mount -t xfs -o noatime,nodiratime,logbufs=8,logbsize=256k "$DEVICE" "$MOUNT_PATH" || {
            echo "ERROR: Échec montage"
            exit 1
        }
        
        # Obtenir l'UUID
        UUID=$(blkid -s UUID -o value "$DEVICE" 2>/dev/null || echo "")
        
        if [ -n "$UUID" ]; then
            # Ajouter au fstab si pas déjà présent
            if ! grep -q "$UUID" /etc/fstab 2>/dev/null; then
                echo "Ajout de $UUID au fstab..."
                echo "UUID=$UUID $MOUNT_PATH xfs defaults,noatime,nodiratime,logbufs=8,logbsize=256k,nofail 0 2" >> /etc/fstab
            fi
        fi
        
        # Vérifier le montage
        if mountpoint -q "$MOUNT_PATH" 2>/dev/null; then
            echo "OK: Volume monté avec succès sur $MOUNT_PATH"
            df -h "$MOUNT_PATH"
        else
            echo "ERROR: Montage échoué"
            exit 1
        fi
FORMAT_SCRIPT
    then
        echo "  [OK] Volume formaté et monté sur $hostname"
        FORMATTED=$((FORMATTED + 1))
        MOUNTED=$((MOUNTED + 1))
        return 0
    else
        echo "  [ERROR] Échec formatage/montage sur $hostname"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

for hostname in "${!SERVERS[@]}"; do
    server_ip="${SERVERS[$hostname]}"
    vol_size="${VOLUME_SIZES[$hostname]}"
    mount_path="${MOUNT_PATHS[$hostname]}"
    
    format_and_mount_volume "$hostname" "$server_ip" "$vol_size" "$mount_path"
    echo ""
done

echo "=============================================="
echo "RÉSUMÉ FORMATAGE XFS"
echo "=============================================="
echo ""
echo "✅ Volumes formatés en XFS: $FORMATTED/8"
echo "✅ Volumes montés: $MOUNTED/8"
echo "❌ Échecs: $FAILED/8"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 Tous les volumes sont formatés en XFS et montés !"
    echo ""
    echo "📄 Logs complets: $LOG_FILE"
    exit 0
else
    echo "⚠️  Certains volumes n'ont pas pu être formatés/montés"
    echo "📄 Logs complets: $LOG_FILE"
    exit 1
fi

