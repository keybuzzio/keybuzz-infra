#!/bin/sh
set -eu

ROOT="${ROOT:-.}"
SCRIPT_PATH="${SCRIPT_PATH:-/tmp/ph2139-monitoring-alerts.sh}"

awk '
  $0 ~ /^  monitoring-alerts\.sh: \|/ { in_script=1; next }
  in_script && $0 ~ /^    / { print substr($0, 5); next }
  in_script && $0 == "" { print ""; next }
  in_script && $0 !~ /^    / { exit }
' "$ROOT/k8s/monitoring-alerts/configmap-script.yaml" > "$SCRIPT_PATH"

sh -n "$SCRIPT_PATH"

out=$(MONITORING_ALERTS_SELF_TEST=delivery-safety \
  MONITORING_ALERTS_LOG_ONLY=true \
  ALERT_DELIVERY_MODE=log-only \
  WEBHOOK_URL="https://example.invalid/webhook" \
  SMTP_HOST="127.0.0.1" \
  SMTP_PORT="25" \
  SMTP_FROM="masked-sender" \
  SMTP_TO="masked-recipient" \
  sh "$SCRIPT_PATH")

echo "$out" | grep -q 'Alert delivery log-only: suppressed delivery for 1 alert(s)'
echo "$out" | grep -q 'ALERT \[CRITICAL\] delivery-safety: Self-test alert'

if echo "$out" | grep -q 'Sending [0-9][0-9]* alerts'; then
  echo "PH21.39 FAIL: delivery attempted in log-only mode"
  exit 1
fi

if echo "$out" | grep -q 'Email OK\|Email FAILED\|Webhook OK\|Webhook FAILED'; then
  echo "PH21.39 FAIL: email/webhook marker present in log-only mode"
  exit 1
fi

if echo "$out" | grep -q 'sre@keybuzz.io\|alerts@keybuzz.io\|example.invalid\|masked-recipient'; then
  echo "PH21.39 FAIL: recipient/webhook marker leaked"
  exit 1
fi

grep -q 'MONITORING_ALERTS_LOG_ONLY' "$ROOT/k8s/monitoring-alerts/configmap-script.yaml"
grep -q 'ALERT_DELIVERY_MODE' "$ROOT/k8s/monitoring-alerts/configmap-script.yaml"
grep -q 'Alert delivery log-only: suppressed delivery' "$ROOT/k8s/monitoring-alerts/configmap-script.yaml"
grep -q 'MONITORING_ALERTS_SELF_TEST:-}" = "delivery-safety"' "$ROOT/k8s/monitoring-alerts/configmap-script.yaml"

python3 - "$ROOT/k8s/monitoring-alerts/cronjob.yaml" <<'PY'
import sys
import yaml

doc = yaml.safe_load(open(sys.argv[1], encoding="utf-8"))
env = {
    item["name"]: item
    for item in doc["spec"]["jobTemplate"]["spec"]["template"]["spec"]["containers"][0].get("env", [])
}
assert env["MONITORING_ALERTS_LOG_ONLY"]["value"] == "true"
assert env["ALERT_DELIVERY_MODE"]["value"] == "log-only"
assert env["LLM_PROVIDER_CREDIT_TARGET_ENV"]["value"] == "prod"
assert env["LLM_PROVIDER_CREDIT_DRY_RUN"]["value"] == "false"
assert env["LLM_PROVIDER_CREDIT_LOG_ONLY"]["value"] == "true"
PY

echo "PH21.39 monitoring-alerts delivery safety tests PASS"
