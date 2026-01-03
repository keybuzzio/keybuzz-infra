#!/bin/bash
# PH11-DR-00 Server Reboot Script
# Usage: ./ph11_dr00_reboot_server.sh <server_name> <ip>

SERVER="$1"
IP="$2"
LOG_DIR="/opt/keybuzz/logs/dr00"
CHECK_SCRIPT="/opt/keybuzz/keybuzz-infra/scripts/ph11_dr00_pre_post_checks.sh"

if [ -z "$SERVER" ] || [ -z "$IP" ]; then
    echo "Usage: $0 <server_name> <ip>"
    exit 1
fi

echo "=============================================="
echo "PH11-DR-00: Rebooting $SERVER ($IP)"
echo "=============================================="
T0=$(date +%s)
T0_HR=$(date)

# Pre-check
echo ""
echo "=== PRE-REBOOT CHECK ==="
$CHECK_SCRIPT pre "$SERVER"

# Send reboot command
echo ""
echo "=== SENDING REBOOT COMMAND ==="
echo "Time: $(date)"
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@$IP 'sudo reboot' 2>/dev/null
echo "Reboot command sent"

# Wait for server to come back
echo ""
echo "=== WAITING FOR SERVER TO COME BACK ==="
sleep 10  # Give it time to start rebooting

MAX_WAIT=300  # 5 minutes max
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes root@$IP 'uptime' >/dev/null 2>&1; then
        echo "Server $SERVER ($IP) is back online!"
        break
    fi
    echo "Waiting... ($ELAPSED seconds)"
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done

if [ $ELAPSED -ge $MAX_WAIT ]; then
    echo "ERROR: Server did not come back within $MAX_WAIT seconds!"
    exit 1
fi

T1=$(date +%s)
DOWNTIME=$((T1 - T0))

# If this is a K8s node, wait for it to be Ready
if [[ "$SERVER" == k8s-* ]]; then
    echo ""
    echo "=== WAITING FOR K8S NODE TO BE READY ==="
    MAX_K8S_WAIT=180
    K8S_ELAPSED=0
    while [ $K8S_ELAPSED -lt $MAX_K8S_WAIT ]; do
        STATUS=$(kubectl get node "$SERVER" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
        if [ "$STATUS" == "True" ]; then
            echo "K8s node $SERVER is Ready!"
            break
        fi
        echo "K8s node status: $STATUS (waiting...)"
        sleep 10
        K8S_ELAPSED=$((K8S_ELAPSED + 10))
    done
    
    if [ $K8S_ELAPSED -ge $MAX_K8S_WAIT ]; then
        echo "WARNING: K8s node did not become Ready within $MAX_K8S_WAIT seconds"
    fi
fi

# Post-check
echo ""
echo "=== POST-REBOOT CHECK ==="
sleep 10  # Give services time to stabilize
$CHECK_SCRIPT post "$SERVER"

# Summary
T2=$(date +%s)
TOTAL_TIME=$((T2 - T0))

echo ""
echo "=============================================="
echo "SUMMARY: $SERVER"
echo "=============================================="
echo "Start: $T0_HR"
echo "End: $(date)"
echo "Server downtime: ~$DOWNTIME seconds"
echo "Total recovery time: $TOTAL_TIME seconds"

# Log result
RESULT_FILE="$LOG_DIR/${SERVER}_result.txt"
cat > "$RESULT_FILE" << EOF
Server: $SERVER
IP: $IP
Start: $T0_HR
End: $(date)
Downtime: ~${DOWNTIME}s
Total: ${TOTAL_TIME}s
Status: PASS
EOF

echo "Result saved to: $RESULT_FILE"
echo ""
