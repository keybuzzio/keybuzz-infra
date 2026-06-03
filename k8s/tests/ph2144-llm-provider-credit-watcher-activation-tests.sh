#!/bin/sh
set -eu

ROOT="${ROOT:-.}"
SCRIPT_PATH="${SCRIPT_PATH:-/tmp/ph2144-monitoring-alerts.sh}"
STATE_FILE="${STATE_FILE:-/tmp/ph2144-monitoring-alerts-state.$$}"

awk '
  $0 ~ /^  monitoring-alerts\.sh: \|/ { in_script=1; next }
  in_script && $0 ~ /^    / { print substr($0, 5); next }
  in_script && $0 == "" { print ""; next }
  in_script && $0 !~ /^    / { exit }
' "$ROOT/k8s/monitoring-alerts/configmap-script.yaml" > "$SCRIPT_PATH"

sh -n "$SCRIPT_PATH"

one_body='{"ok":true,"env":"dev","windowSeconds":3600,"count":1,"firstSeen":"2026-06-01T12:00:00.000Z","lastSeen":"2026-06-01T12:01:00.000Z","distinctTenantCount":1,"requestFailedCount":2,"providerModelCounts":[{"provider":"litellm","model":"kbz-premium","count":1}],"featureCounts":[{"feature":"assist","count":1}]}'

rm -f "$STATE_FILE"
active_log_only_out=$(MONITORING_ALERTS_SELF_TEST=llm-provider-credit \
  LLM_PROVIDER_CREDIT_FIXTURE_BODY="$one_body" \
  LLM_PROVIDER_CREDIT_DRY_RUN=false \
  LLM_PROVIDER_CREDIT_LOG_ONLY=true \
  MONITORING_ALERTS_LOG_ONLY=true \
  ALERT_DELIVERY_MODE=log-only \
  LLM_PROVIDER_CREDIT_TEST_STATE_FILE="$STATE_FILE" \
  WEBHOOK_URL="https://example.invalid/webhook" \
  SMTP_HOST="127.0.0.1" \
  SMTP_PORT="25" \
  SMTP_FROM="masked-sender" \
  SMTP_TO="masked-recipient" \
  sh "$SCRIPT_PATH")

echo "$active_log_only_out" | grep -q 'ACTIVE LOG-ONLY LLM provider credit alert'
echo "$active_log_only_out" | grep -q 'provider=litellm'
echo "$active_log_only_out" | grep -q 'model=kbz-premium'

if echo "$active_log_only_out" | grep -q 'DRY-RUN/LOG-ONLY LLM provider credit alert'; then
  echo "PH21.44 FAIL: active log-only was reported as dry-run"
  exit 1
fi

if echo "$active_log_only_out" | grep -q 'Sending [0-9][0-9]* alerts'; then
  echo "PH21.44 FAIL: active log-only attempted delivery"
  exit 1
fi

if echo "$active_log_only_out" | grep -q 'Email OK\|Email FAILED\|Webhook OK\|Webhook FAILED'; then
  echo "PH21.44 FAIL: delivery marker present"
  exit 1
fi

if echo "$active_log_only_out" | grep -q 'sre@keybuzz.io\|alerts@keybuzz.io\|example.invalid\|masked-recipient'; then
  echo "PH21.44 FAIL: recipient/webhook marker leaked"
  exit 1
fi

rm -f "$STATE_FILE"
dry_run_out=$(MONITORING_ALERTS_SELF_TEST=llm-provider-credit \
  LLM_PROVIDER_CREDIT_FIXTURE_BODY="$one_body" \
  LLM_PROVIDER_CREDIT_DRY_RUN=true \
  LLM_PROVIDER_CREDIT_LOG_ONLY=true \
  LLM_PROVIDER_CREDIT_TEST_STATE_FILE="$STATE_FILE" \
  sh "$SCRIPT_PATH")

echo "$dry_run_out" | grep -q 'DRY-RUN/LOG-ONLY LLM provider credit alert'

grep -q 'ACTIVE LOG-ONLY LLM provider credit alert' "$ROOT/k8s/monitoring-alerts/configmap-script.yaml"
grep -q 'DRY-RUN/LOG-ONLY LLM provider credit alert' "$ROOT/k8s/monitoring-alerts/configmap-script.yaml"

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
assert env["LLM_PROVIDER_CREDIT_TARGET_ENV"]["value"] == "dev"
assert env["LLM_PROVIDER_CREDIT_DRY_RUN"]["value"] == "false"
assert env["LLM_PROVIDER_CREDIT_LOG_ONLY"]["value"] == "true"
PY

echo "PH21.44 LLM provider credit watcher activation tests PASS"
