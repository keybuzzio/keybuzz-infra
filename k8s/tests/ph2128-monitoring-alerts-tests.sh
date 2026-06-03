#!/bin/sh
set -eu

ROOT="${ROOT:-.}"
SCRIPT_PATH="${SCRIPT_PATH:-/tmp/ph2128-monitoring-alerts.sh}"
STATE_FILE="${STATE_FILE:-/tmp/ph2128-monitoring-alerts-state.$$}"

awk '
  $0 ~ /^  monitoring-alerts\.sh: \|/ { in_script=1; next }
  in_script && $0 ~ /^    / { print substr($0, 5); next }
  in_script && $0 == "" { print ""; next }
  in_script && $0 !~ /^    / { exit }
' "$ROOT/k8s/monitoring-alerts/configmap-script.yaml" > "$SCRIPT_PATH"

sh -n "$SCRIPT_PATH"

zero_body='{"ok":true,"env":"dev","windowSeconds":3600,"count":0,"firstSeen":null,"lastSeen":null,"distinctTenantCount":0,"requestFailedCount":0,"providerModelCounts":[],"featureCounts":[]}'
one_body='{"ok":true,"env":"dev","windowSeconds":3600,"count":1,"firstSeen":"2026-06-01T12:00:00.000Z","lastSeen":"2026-06-01T12:01:00.000Z","distinctTenantCount":1,"requestFailedCount":2,"providerModelCounts":[{"provider":"litellm","model":"kbz-premium","count":1}],"featureCounts":[{"feature":"assist","count":1}]}'

out_zero=$(MONITORING_ALERTS_SELF_TEST=llm-provider-credit \
  LLM_PROVIDER_CREDIT_FIXTURE_BODY="$zero_body" \
  LLM_PROVIDER_CREDIT_STATE_DRY_RUN=true \
  sh "$SCRIPT_PATH")
echo "$out_zero" | grep -q 'OK (provider_credit_count=0, request_failed=0)'

out_one=$(MONITORING_ALERTS_SELF_TEST=llm-provider-credit \
  LLM_PROVIDER_CREDIT_FIXTURE_BODY="$one_body" \
  LLM_PROVIDER_CREDIT_DRY_RUN=true \
  LLM_PROVIDER_CREDIT_LOG_ONLY=true \
  LLM_PROVIDER_CREDIT_STATE_DRY_RUN=true \
  sh "$SCRIPT_PATH")
echo "$out_one" | grep -q 'DRY-RUN/LOG-ONLY LLM provider credit alert'
echo "$out_one" | grep -q 'provider=litellm'
echo "$out_one" | grep -q 'model=kbz-premium'

rm -f "$STATE_FILE"
out_first=$(MONITORING_ALERTS_SELF_TEST=llm-provider-credit \
  LLM_PROVIDER_CREDIT_FIXTURE_BODY="$one_body" \
  LLM_PROVIDER_CREDIT_DRY_RUN=false \
  LLM_PROVIDER_CREDIT_LOG_ONLY=true \
  MONITORING_ALERTS_LOG_ONLY=true \
  ALERT_DELIVERY_MODE=log-only \
  LLM_PROVIDER_CREDIT_TEST_STATE_FILE="$STATE_FILE" \
  sh "$SCRIPT_PATH")
out_second=$(MONITORING_ALERTS_SELF_TEST=llm-provider-credit \
  LLM_PROVIDER_CREDIT_FIXTURE_BODY="$one_body" \
  LLM_PROVIDER_CREDIT_DRY_RUN=false \
  LLM_PROVIDER_CREDIT_LOG_ONLY=true \
  LLM_PROVIDER_CREDIT_TEST_STATE_FILE="$STATE_FILE" \
  sh "$SCRIPT_PATH")
echo "$out_first" | grep -q 'ACTIVE LOG-ONLY LLM provider credit alert'
if echo "$out_first" | grep -q 'Email OK\|Email FAILED\|Webhook OK\|Webhook FAILED\|Sending [0-9][0-9]* alerts'; then
  echo "PH21.28 FAIL: active log-only attempted external delivery"
  exit 1
fi
echo "$out_second" | grep -q 'Debounced LLM provider credit alert'

grep -q 'LLM_PROVIDER_CREDIT_DRY_RUN' "$ROOT/k8s/monitoring-alerts/cronjob.yaml"
grep -q 'monitoring-alert-state' "$ROOT/k8s/monitoring-alerts/cronjob.yaml"
grep -q 'X-KeyBuzz-Monitor-Token' "$ROOT/k8s/monitoring-alerts/configmap-script.yaml"
grep -q 'monitoring-llm-provider-credit-token' "$ROOT/k8s/monitoring-alerts/cronjob.yaml"

echo "PH21.28 monitoring-alerts tests PASS"
