#!/bin/bash
# Verify SSH private IP access from install-v3 to all rebuildable servers (47 servers)
# PH2-06: SSH Private IP Verification
# This script verifies that install-v3 can connect via SSH (using its private key) to all servers via their private IPs (10.0.0.x)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "${SCRIPT_DIR}")"
TSV_FILE="${INFRA_DIR}/servers/servers_v3.tsv"
SSH_KEY_PRIV="/root/.ssh/id_rsa_keybuzz_v3"
LOG_DIR="/opt/keybuzz/logs/phase2"
LOG_FILE="${LOG_DIR}/ssh-private-verification.log"
EXCLUDED_HOSTS=("install-01" "install-v3")

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# Initialize log
cat > "${LOG_FILE}" << EOF
========================================
SSH Private IP Access Verification Log
========================================
Started: $(date -Iseconds)
SSH Key: ${SSH_KEY_PRIV}
Target: All rebuildable servers (excluding bastions)
Method: SSH private IP connection (10.0.0.x) via private key
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
if [[ ! -f "${SSH_KEY_PRIV}" ]]; then
    log_error "SSH private key not found: ${SSH_KEY_PRIV}"
    exit 1
fi

log_info "SSH private key found: ${SSH_KEY_PRIV}"
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
    
    # Only add if IP private is present
    if [[ -n "${ip_private}" ]]; then
        echo "${hostname},${ip_public},${ip_private},${role}" >> "${TEMP_CSV}"
    fi
done

if [[ ! -f "${TEMP_CSV}" ]]; then
    log_error "Failed to generate server list"
    exit 1
fi

TOTAL_SERVERS=$(tail -n +2 "${TEMP_CSV}" | wc -l)
log_info "Total servers to verify: ${TOTAL_SERVERS}"

# Counters
SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_SERVERS=()

# Verify SSH access to each server via private IP
log_info "Starting SSH private IP access verification..."
echo ""

# Use process substitution to avoid stdin conflicts with ssh
while IFS=',' read -r hostname ip_public ip_private role <&3; do
    # Skip header
    [[ "${hostname}" == "hostname" ]] && continue
    
    log_info "Verifying: ${hostname} (${ip_private}) - ${role}"
    
    # Test SSH connection via private IP
    # Redirect stdin to /dev/null to prevent ssh from consuming the CSV input
    if ssh -i "${SSH_KEY_PRIV}" \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=5 \
        -o PasswordAuthentication=no \
        -o BatchMode=yes \
        -n \
        root@"${ip_private}" \
        "echo 'SSH_PRIVATE_OK'" \
        </dev/null \
        >> "${LOG_FILE}" 2>&1; then
        log_success "${hostname} (${ip_private}): SSH private IP access OK"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        EXIT_CODE=$?
        log_error "${hostname} (${ip_private}): SSH private IP access FAILED (exit code: ${EXIT_CODE})"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_SERVERS+=("${hostname} (${ip_private})")
    fi
    
    echo ""
    
done 3< "${TEMP_CSV}"

# Cleanup
rm -f "${TEMP_CSV}"

# Final summary
echo "" | tee -a "${LOG_FILE}"
echo "========================================" | tee -a "${LOG_FILE}"
echo "SSH Private IP Access Verification Summary" | tee -a "${LOG_FILE}"
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
fi

echo "========================================" | tee -a "${LOG_FILE}"

# Exit with error if any failed (STOP PHASE if failures)
if [[ ${FAILED_COUNT} -gt 0 ]]; then
    log_error "Verification completed with ${FAILED_COUNT} failure(s)"
    log_error "STOPPING PHASE: Cannot proceed to PH2-07 with failed servers"
    log_error "The private network (10.0.0.x) must be fully operational before Ansible inventory update"
    log_error "Please resolve SSH private IP access issues before continuing"
    exit 1
else
    log_success "All ${TOTAL_SERVERS} servers verified successfully via private IP"
    log_success "SSH private mesh (10.0.0.x) is functional"
    log_success "Ready to proceed to PH2-07 (Ansible inventory update to use private IPs)"
    exit 0
fi

