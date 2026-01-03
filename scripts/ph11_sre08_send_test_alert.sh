#!/bin/bash
# PH11-SRE-08: Send test alert to Alertmanager

set -euo pipefail

SEVERITY=${1:-warning}
ALERT_NAME="KeyBuzzTestAlert"

echo "=== Sending test alert (severity=$SEVERITY) ==="

# Get Alertmanager service IP
AM_IP=$(kubectl get svc kube-prometheus-kube-prome-alertmanager -n observability -o jsonpath='{.spec.clusterIP}')

# Send test alert via k8s master
ssh root@10.0.0.100 "curl -X POST http://$AM_IP:9093/api/v2/alerts -H 'Content-Type: application/json' -d '[{\"status\":\"firing\",\"labels\":{\"alertname\":\"$ALERT_NAME\",\"severity\":\"$SEVERITY\",\"instance\":\"test-host\"},\"annotations\":{\"summary\":\"Test alert from PH11-SRE-08\",\"description\":\"This is a test alert to verify Slack/Email notifications\"},\"startsAt\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"endsAt\":\"0001-01-01T00:00:00Z\"}]'"

echo ""
echo "=== Checking log-only receiver on monitor-01 ==="
ssh root@10.0.0.152 "tail -2 /opt/keybuzz/logs/sre/alertmanager/alerts_*.jsonl | head -c 2000"

echo ""
echo "=== DONE ==="
echo "Check Slack channel #alerts-dev and email sre@keybuzz.io for notifications"