#!/bin/bash
# Deploy SSH key from install-v3 to all rebuildable servers (47 servers)
# PH2-04: SSH Mesh Key Deployment
# This script deploys /root/.ssh/id_rsa_keybuzz_v3.pub to all servers via their public IPs
# Uses direct SSH connection to inject the public key (NO password, NO sshpass)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "${SCRIPT_DIR}")"
TSV_FILE="${INFRA_DIR}/servers/servers_v3.tsv"
SSH_KEY="/root/.ssh/id_rsa_keybuzz_v3.pub"
SSH_KEY_PRIV="/root/.ssh/id_rsa_keybuzz_v3"
LOG_DIR="/opt/keybuzz/logs/phase2"
LOG_FILE="${LOG_DIR}/ssh-key-deployment.log"
EXCLUDED_HOSTS=("install-01" "install-v3")

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# Initialize log
cat > "${LOG_FILE}" << EOF
========================================
SSH Key Mesh Deployment Log
========================================
Started: $(date -Iseconds)
Key: ${SSH_KEY}
Target: All rebuildable servers (excluding bastions)
Method: Direct SSH injection (no password, no sshpass)
========================================

EOF

# Function to log
log_info() {
    echo "[INFO] $1" | tee -a "${LOG_FILE}"
}

log_success() {
    echo "[SUCCESS] $1" | tee -a "${LOG_FILE}"
}

log_error() {
    echo "[ERROR] $1" | tee -a "${LOG_FILE}"
}

log_warning() {
    echo "[WARNING] $1" | tee -a "${LOG_FILE}"
}

# Check SSH key exists
if [[ ! -f "${SSH_KEY}" ]]; then
    log_error "SSH public key not found: ${SSH_KEY}"
    exit 1
fi

if [[ ! -f "${SSH_KEY_PRIV}" ]]; then
    log_error "SSH private key not found: ${SSH_KEY_PRIV}"
    exit 1
fi

log_info "SSH key found: ${SSH_KEY}"
PUBLIC_KEY_CONTENT=$(cat "${SSH_KEY}")
log_info "Public key: ${PUBLIC_KEY_CONTENT:0:50}..."

log_info "Reading server list from: ${TSV_FILE}"

# Parse TSV and extract rebuildable servers using awk
TEMP_CSV="/tmp/rebuildable_servers.csv"

# Extract column indices from header
HEADER=$(head -1 "${TSV_FILE}")
HOSTNAME_COL=$(echo "${HEADER}" | awk -F'\t' '{for(i=1;i<=NF;i++) if($i=="HOSTNAME") print i}')
IP_PUB_COL=$(echo "${HEADER}" | awk -F'\t' '{for(i=1;i<=NF;i++) if($i=="IP_PUBLIQUE") print i}')
IP_PRIV_COL=$(echo "${HEADER}" | awk -F'\t' '{for(i=1;i<=NF;i++) if($i=="IP_PRIVEE") print i}')
ROLE_COL=$(echo "${HEADER}" | awk -F'\t' '{for(i=1;i<=NF;i++) if($i=="ROLE_V3") print i}')

log_info "TSV columns: HOSTNAME=${HOSTNAME_COL}, IP_PUBLIQUE=${IP_PUB_COL}, IP_PRIVEE=${IP_PRIV_COL}, ROLE_V3=${ROLE_COL}"

# Generate CSV file with rebuildable servers
echo "hostname,ip_public,ip_private,role" > "${TEMP_CSV}"

# Process TSV file (skip header, exclude install-01 and install-v3)
tail -n +2 "${TSV_FILE}" | while IFS=$'\t' read -r line; do
    hostname=$(echo "${line}" | awk -F'\t' -v col="${HOSTNAME_COL}" '{print $col}' | xargs)
    
    # Skip if hostname is empty or in excluded list
    [[ -z "${hostname}" ]] && continue
    [[ "${hostname}" == "install-01" ]] && continue
    [[ "${hostname}" == "install-v3" ]] && continue
    
    ip_public=$(echo "${line}" | awk -F'\t' -v col="${IP_PUB_COL}" '{print $col}' | xargs)
    ip_private=$(echo "${line}" | awk -F'\t' -v col="${IP_PRIV_COL}" '{print $col}' | xargs)
    role=$(echo "${line}" | awk -F'\t' -v col="${ROLE_COL}" '{print $col}' | xargs)
    
    # Only add if IP public is present
    if [[ -n "${ip_public}" ]]; then
        echo "${hostname},${ip_public},${ip_private},${role}" >> "${TEMP_CSV}"
    fi
done

if [[ ! -f "${TEMP_CSV}" ]]; then
    log_error "Failed to generate server list"
    exit 1
fi

TOTAL_SERVERS=$(tail -n +2 "${TEMP_CSV}" | wc -l)
log_info "Total servers to process: ${TOTAL_SERVERS}"

# Counters
SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_SERVERS=()

# Deploy key to each server
log_info "Starting SSH key deployment (direct injection method)..."
echo ""

while IFS=',' read -r hostname ip_public ip_private role; do
    # Skip header
    [[ "${hostname}" == "hostname" ]] && continue
    
    log_info "Processing: ${hostname} (${ip_public}) - ${role}"
    
    # Step 1: Inject public key directly via SSH
    # This assumes SSH access is already available (via console, existing key, or other method)
    log_info "  Injecting SSH public key..."
    
    if ssh -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/root/.ssh/known_hosts \
        -o ConnectTimeout=10 \
        -o BatchMode=yes \
        root@"${ip_public}" \
        "mkdir -p /root/.ssh && chmod 700 /root/.ssh && grep -q '${PUBLIC_KEY_CONTENT}' /root/.ssh/authorized_keys 2>/dev/null || echo '${PUBLIC_KEY_CONTENT}' >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys" \
        >> "${LOG_FILE}" 2>&1; then
        
        log_success "  ${hostname} (${ip_public}): Public key injected successfully"
        
        # Step 2: Test SSH connection with the new key
        log_info "  Testing SSH connection with deployed key..."
        if ssh -i "${SSH_KEY_PRIV}" \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=10 \
            -o PasswordAuthentication=no \
            -o BatchMode=yes \
            root@"${ip_public}" \
            "echo 'SSH_OK'" \
            >> "${LOG_FILE}" 2>&1; then
            log_success "  ${hostname} (${ip_public}): SSH key authentication verified"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            log_warning "  ${hostname} (${ip_public}): Key injected but SSH test failed (may need initial access setup)"
            FAILED_COUNT=$((FAILED_COUNT + 1))
            FAILED_SERVERS+=("${hostname} (${ip_public}) - SSH_TEST_FAILED")
        fi
    else
        EXIT_CODE=$?
        log_error "  ${hostname} (${ip_public}): Key injection failed (exit code: ${EXIT_CODE})"
        log_warning "  ${hostname} (${ip_public}): This server may require initial SSH access setup (console, existing key, or manual intervention)"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_SERVERS+=("${hostname} (${ip_public}) - KEY_INJECTION_FAILED")
    fi
    
    echo ""
    
done < "${TEMP_CSV}"

# Cleanup
rm -f "${TEMP_CSV}"

# Final summary
echo "" | tee -a "${LOG_FILE}"
echo "========================================" | tee -a "${LOG_FILE}"
echo "SSH Key Deployment Summary" | tee -a "${LOG_FILE}"
echo "========================================" | tee -a "${LOG_FILE}"
echo "Total servers: ${TOTAL_SERVERS}" | tee -a "${LOG_FILE}"
echo "Success: ${SUCCESS_COUNT}" | tee -a "${LOG_FILE}"
echo "Failed: ${FAILED_COUNT}" | tee -a "${LOG_FILE}"
echo "Completed: $(date -Iseconds)" | tee -a "${LOG_FILE}"
echo "" | tee -a "${LOG_FILE}"

if [[ ${FAILED_COUNT} -gt 0 ]]; then
    echo "Failed servers:" | tee -a "${LOG_FILE}"
    for server in "${FAILED_SERVERS[@]}"; do
        echo "  - ${server}" | tee -a "${LOG_FILE}"
    done
    echo "" | tee -a "${LOG_FILE}"
    log_warning "Some servers failed. This may be normal if SSH access is not yet configured."
    log_warning "For failed servers, you may need to:"
    log_warning "  1. Access via Hetzner console (KVM)"
    log_warning "  2. Manually configure SSH access"
    log_warning "  3. Or use another initial access method"
fi

echo "========================================" | tee -a "${LOG_FILE}"

# Exit with error if any failed
if [[ ${FAILED_COUNT} -gt 0 ]]; then
    log_warning "Deployment completed with ${FAILED_COUNT} failure(s)"
    log_warning "Check logs for details. Some failures may be expected if SSH access is not yet configured."
    exit 1
else
    log_success "All ${TOTAL_SERVERS} servers processed successfully"
    exit 0
fi
