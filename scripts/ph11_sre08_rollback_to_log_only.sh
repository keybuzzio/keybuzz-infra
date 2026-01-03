#!/bin/bash
# PH11-SRE-08: Rollback to log-only alerting
# Reverts routing to only use keybuzz-log-only receiver

set -euo pipefail

echo "=== PH18-SRE+r08: Rollback to log-only ==="

# Backup current config
echo "[1/3] Backing up current config..."
cp /opt/keybuzz/keybuzz-infra/k8s/observability/kube-prometheus-values-dev.yaml /opt/keybuzz/keybuzz-infra/k8s/observability/kube-prometheus-values-dev.yaml.bak

# Create log-only config
echo "[2/3] Applying log-only config..."
cat > /tmp/kube-prometheus-values-logonly.yaml << 'EOF'
alertmanager:
  enabled: true
  config:
    global:
      resolve_timeout: 5m
    inhibit_rules:
      - equal: [namespace, alertname]
        source_matchers: [severity = critical]
        target_matchers: [severity =~ warning|info]
      - equal: [namespace, alertname]
        source_matchers: [severity = warning]
        target_matchers: [severity = info]
      - equal: [namespace]
        source_matchers: [alertname = InfoInhibitor]
        target_matchers: [severity = info]
      - target_matchers: [alertname = InfoInhibitor]
    receivers:
      - name: "null"
      - name: keybuzz-log-only
        webhook_configs:
          - url: http://10.0.0.152:9099/alerts
            send_resolved: true
    route:
      group_by: [alertname, instance]
      group_interval: 5m
      group_wait: 30s
      receiver: keybuzz-log-only
      repeat_interval: 1h
      routes:
        - matchers: [alertname = "Watchdog"]
          receiver: "null"
    templates: [/etc/alertmanager/config/*.tmpl]
grafana:
  enabled: true
prometheus:
  prometheusSpec:
    retention: 15d
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: [ReadWriteOnce]
          resources:
            requests:
              storage: 20Gi
          storageClassName: local-path
prometheusOperator:
  enabled: true
EOF

helm upgrade kube-prometheus prometheus-community/kube-prometheus-stack -n observability -f /tmp/kube-prometheus-values-logonly.yaml --wait --timeout 5m

echo "[3/3] Verifying..."
sleep 10
AM_IP=$(kubectl get svc kube-prometheus-kube-prome-alertmanager -n observability -o jsonpath='{.spec.clusterIP}')
ssh root@10.0.0.100 "curl -s http://$AM_IP:9093/api/v2/status" | grep -o 'receiver.:"*bkeybuzz-log-only"%

echo ""
echo "=== Rollback complete ==="
echo "Only log-only receiver is now active"
echo "To re-enable Slack/Email, restore from .bak file and helm upgrade"