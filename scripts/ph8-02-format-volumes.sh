#!/bin/bash
# PH8-02 - Format and mount volumes
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== PH8-02 Format and Mount Volumes ==="
echo ""

# Function to format and mount volume
setup_volume() {
    local SERVER_IP=$1
    local MOUNT_POINT=$2
    local SERVICE_NAME=$3
    
    echo "=== Setting up $SERVICE_NAME on $SERVER_IP ==="
    
    ssh root@$SERVER_IP bash <<EOF
set -e

    # Find volume device (non-mounted disk)
    VOLUME_DEVICE=""
    
    # Try via /dev/disk/by-id (Hetzner volumes)
    for vol in /dev/disk/by-id/scsi-*; do
        [ -L "\$vol" ] || continue
        device=\$(readlink -f "\$vol")
        [ -b "\$device" ] || continue
        if ! mount | grep -q "\$device"; then
            VOLUME_DEVICE="\$device"
            break
        fi
    done
    
    # If not found, try /dev/sd* and /dev/vd*
    if [ -z "\$VOLUME_DEVICE" ]; then
        for dev in /dev/sd{b..z} /dev/vd{b..z}; do
            [ -b "\$dev" ] || continue
            if ! mount | grep -q "\$dev"; then
                VOLUME_DEVICE="\$dev"
                break
            fi
        done
    fi

    if [ -z "\$VOLUME_DEVICE" ] || [ ! -b "\$VOLUME_DEVICE" ]; then
        echo "❌ Could not find volume device"
        lsblk
        exit 1
    fi

    echo "Volume device: \$VOLUME_DEVICE"

# Check if already formatted
if blkid "$VOLUME_DEVICE" | grep -q xfs; then
    echo "Volume already formatted with XFS"
else
    echo "Formatting volume with XFS..."
    mkfs.xfs -f "$VOLUME_DEVICE" || {
        echo "❌ Failed to format volume"
        exit 1
    }
fi

# Create mount point
mkdir -p ${MOUNT_POINT}

# Get UUID
UUID=$(blkid "$VOLUME_DEVICE" -s UUID -o value)
echo "UUID: $UUID"

# Mount volume
mount "$VOLUME_DEVICE" ${MOUNT_POINT} || {
    echo "❌ Failed to mount volume"
    exit 1
}

# Add to fstab if not already present
if ! grep -q "${MOUNT_POINT}" /etc/fstab; then
    echo "UUID=$UUID ${MOUNT_POINT} xfs defaults,noatime 0 2" >> /etc/fstab
    echo "Added to fstab"
fi

# Set permissions
chown -R root:root ${MOUNT_POINT}
chmod 755 ${MOUNT_POINT}

echo "✅ Volume mounted at ${MOUNT_POINT}"
VOLUME_SCRIPT

    echo "✅ $SERVICE_NAME volume setup completed"
    echo ""
}

# Setup MariaDB volumes
echo "Step 1: Setting up MariaDB volumes..."
setup_volume "10.0.0.170" "/data/mariadb" "maria-01"
setup_volume "10.0.0.171" "/data/mariadb" "maria-02"
setup_volume "10.0.0.172" "/data/mariadb" "maria-03"

# Setup ProxySQL volumes
echo "Step 2: Setting up ProxySQL volumes..."
setup_volume "10.0.0.173" "/data/proxysql" "proxysql-01"
setup_volume "10.0.0.174" "/data/proxysql" "proxysql-02"

echo "=== All volumes formatted and mounted ==="

