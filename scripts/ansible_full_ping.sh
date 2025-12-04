#!/bin/bash
# Full Ansible Ping Test - PH2-08
# Test complete Ansible connectivity (SSH via key + private IP) on 100% of infrastructure
# 49 hosts, 21 Ansible groups

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "${SCRIPT_DIR}")"
INVENTORY="${INFRA_DIR}/ansible/inventory/hosts.yml"
LOG_DIR="/opt/keybuzz/logs/phase2"
FULL_LOG="${LOG_DIR}/full-ansible-ping.log"
SUMMARY_LOG="${LOG_DIR}/ansible-ping-summary.log"

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

# Initialize logs
cat > "${FULL_LOG}" << EOF
========================================
Full Ansible Ping Test - PH2-08
========================================
Started: $(date -Iseconds)
Inventory: ${INVENTORY}
Target: All 49 hosts via private IP (10.0.0.x)
========================================

EOF

cat > "${SUMMARY_LOG}" << EOF
========================================
Ansible Ping Test Summary - PH2-08
========================================
Started: $(date -Iseconds)
========================================

EOF

# Function to log
log_info() {
    echo "[INFO] $1" | tee -a "${SUMMARY_LOG}"
}

log_success() {
    echo "[SUCCESS] $1" | tee -a "${SUMMARY_LOG}"
}

log_error() {
    echo "[ERROR] $1" | tee -a "${SUMMARY_LOG}"
}

log_warning() {
    echo "[WARNING] $1" | tee -a "${SUMMARY_LOG}"
}

# List of all groups to test
GROUPS=(
    "bastions"
    "k8s_masters"
    "k8s_workers"
    "db_postgres"
    "db_mariadb"
    "db_proxysql"
    "db_temporal"
    "db_analytics"
    "redis"
    "rabbitmq"
    "minio"
    "vector_db"
    "vault"
    "siem"
    "monitoring"
    "backup"
    "mail_core"
    "mail_mx"
    "builder"
    "apps_misc"
    "lb_internal"
)

log_info "Full Ansible Ping Test Starting..."
echo ""

# ========================================
# STEP A: Global Test (ansible all)
# ========================================
log_info "STEP A: Global test (ansible all -m ping)"
echo "========================================" | tee -a "${FULL_LOG}"
echo "Global Test - ansible all -m ping" | tee -a "${FULL_LOG}"
echo "========================================" | tee -a "${FULL_LOG}"

if ansible all -i "${INVENTORY}" -m ping -o >> "${FULL_LOG}" 2>&1; then
    log_success "Global test completed successfully"
else
    log_error "Global test completed with some failures"
fi

echo "" | tee -a "${FULL_LOG}"

# ========================================
# STEP B: Group-by-group Tests
# ========================================
log_info "STEP B: Group-by-group tests"
echo ""

TOTAL_SUCCESS=0
TOTAL_FAIL=0
GROUP_RESULTS=()
FAILED_HOSTS=()

for group in "${GROUPS[@]}"; do
    log_info "Testing group: ${group}"
    
    GROUP_LOG="${LOG_DIR}/ping-${group}.log"
    
    echo "========================================" | tee -a "${FULL_LOG}"
    echo "Group: ${group}" | tee -a "${FULL_LOG}"
    echo "========================================" | tee -a "${FULL_LOG}"
    
    # Test the group and capture results
    ansible "${group}" -i "${INVENTORY}" -m ping -o 2>&1 | tee -a "${GROUP_LOG}" | tee -a "${FULL_LOG}"
    GROUP_EXIT_CODE=${PIPESTATUS[0]}
    
    # Count successes and failures in this group
    GROUP_SUCCESS=$(grep -c "SUCCESS" "${GROUP_LOG}" 2>/dev/null || echo "0")
    GROUP_FAIL=$(grep -c "FAILED\|UNREACHABLE" "${GROUP_LOG}" 2>/dev/null || echo "0")
    
    TOTAL_SUCCESS=$((TOTAL_SUCCESS + GROUP_SUCCESS))
    TOTAL_FAIL=$((TOTAL_FAIL + GROUP_FAIL))
    
    # Extract failed hosts from this group
    while IFS= read -r line; do
        if [[ "${line}" =~ ^([a-z0-9-]+)\ \|\ (FAILED|UNREACHABLE) ]]; then
            FAILED_HOSTS+=("${BASH_REMATCH[1]}")
        fi
    done < <(grep -E "FAILED|UNREACHABLE" "${GROUP_LOG}" 2>/dev/null || true)
    
    if [[ ${GROUP_EXIT_CODE} -eq 0 && ${GROUP_FAIL} -eq 0 ]]; then
        GROUP_RESULTS+=("${group}: ${GROUP_SUCCESS}/${GROUP_SUCCESS} SUCCESS ✅")
        log_success "${group}: ${GROUP_SUCCESS}/${GROUP_SUCCESS} SUCCESS"
    else
        GROUP_RESULTS+=("${group}: ${GROUP_SUCCESS}/${GROUP_SUCCESS} SUCCESS, ${GROUP_FAIL} FAIL ❌")
        log_error "${group}: ${GROUP_SUCCESS} SUCCESS, ${GROUP_FAIL} FAIL"
    fi
    
    echo "" | tee -a "${FULL_LOG}"
    echo ""
done

# ========================================
# STEP C: Summary Generation
# ========================================
log_info "STEP C: Generating summary"
echo ""

# Get total number of hosts from inventory
TOTAL_HOSTS=$(ansible all -i "${INVENTORY}" --list-hosts 2>/dev/null | grep -c "^\s*[a-z0-9-]\+" || echo "49")

echo "" | tee -a "${SUMMARY_LOG}"
echo "========================================" | tee -a "${SUMMARY_LOG}"
echo "Full Ansible Ping Test Summary" | tee -a "${SUMMARY_LOG}"
echo "========================================" | tee -a "${SUMMARY_LOG}"
echo "Total hosts: ${TOTAL_HOSTS}" | tee -a "${SUMMARY_LOG}"
echo "Total SUCCESS: ${TOTAL_SUCCESS}" | tee -a "${SUMMARY_LOG}"
echo "Total FAIL: ${TOTAL_FAIL}" | tee -a "${SUMMARY_LOG}"
echo "Completed: $(date -Iseconds)" | tee -a "${SUMMARY_LOG}"
echo "" | tee -a "${SUMMARY_LOG}"

echo "Group-by-group results:" | tee -a "${SUMMARY_LOG}"
for result in "${GROUP_RESULTS[@]}"; do
    echo "  - ${result}" | tee -a "${SUMMARY_LOG}"
done
echo "" | tee -a "${SUMMARY_LOG}"

if [[ ${TOTAL_FAIL} -gt 0 ]]; then
    echo "Failed hosts:" | tee -a "${SUMMARY_LOG}"
    for host in "${FAILED_HOSTS[@]}"; do
        echo "  - ${host}" | tee -a "${SUMMARY_LOG}"
    done
    echo "" | tee -a "${SUMMARY_LOG}"
    log_error "Test completed with ${TOTAL_FAIL} failure(s)"
    exit 1
else
    log_success "Test completed successfully: ${TOTAL_SUCCESS}/${TOTAL_HOSTS} hosts reachable"
    log_success "Ansible mesh privé complet → OK"
    log_success "READY FOR PHASE 3 (Volumes + XFS)"
    exit 0
fi

