#!/bin/bash
# PH11-DR-00 Pre/Post Reboot Checks
# Usage: ./ph11_dr00_pre_post_checks.sh [pre|post] [server_name]

PHASE="$1"
SERVER="$2"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="/opt/keybuzz/logs/dr00"
LOG_FILE="$LOG_DIR/${SERVER}_${PHASE}_${TIMESTAMP}.log"

echo "=== PH11-DR-00 $PHASE check for $SERVER ==" | tee "$LOG_FILE"
echo "Timestamp: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# K8s Nodes
echo "--- K8s Nodes ---" | tee -a "$LOG_FILE"
kubectl get nodes -o wide 2>&1 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# K8s Pods (summary)
echo "--- K8s Pods (issues) ---" | tee -a "$LOG_FILE"
kubectl get pods -A 2>&1 | grep -vE 'Running|Completed' | head -20 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Admin health
echo "--- Admin DEV Health ---" | tee -a "$LOG_FILE"
curl -ksI https://admin-dev.keybuzz.io/ 2>&1 | head -5 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Client health
echo "--- Client DEV Health ---" | tee -a "$LOG_FILE"
curl -ks https://client-dev.keybuzz.io/api/auth/me 2>&1 | head -3 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# API health
echo "--- API DEV Health ---" | tee -a "$LOG_FILE"
curl -ks https://api-dev.keybuzz.io/health 2>&1 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

echo "--- API DEV DB Health ---" | tee -a "$LOG_FILE"
curl -ks https://api-dev.keybuzz.io/health/db 2>&1 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Patroni (Postgres)
echo "--- Patroni Status ---" | tee -a "$LOG_FILE"
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@10.0.0.122 'patronictl -c /etc/patroni.yml list' 2>&1 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Redis (if available)
echo "--- Redis Status ---" | tee -a "$LOG_FILE"
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@10.0.0.123 'redis-cli ping' 2>&1 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# RabbitMQ (if available)
echo "--- RabbitMQ Status ---" | tee -a "$LOG_FILE"
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@10.0.0.126 'docker exec rabbitmq rabbitmqctl cluster_status 2>/dev/null | head -10' 2>&1 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# MariaDB (if available)
echo "--- MariaDB Galera Status ---" | tee -a "$LOG_FILE"
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@10.0.0.170 'docker exec mariadb mysql -uroot -e "SHOW STATUS LIKE '\''wsrep_cluster_size'\'';" 2>/dev/null' 2>&1 | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

echo "=== Check complete ===" | tee -a "$LOG_FILE"
echo "Log saved to: $LOG_FILE"
