#!/usr/bin/env bash
set -eo pipefail

BASE="${1:-https://studio-api-dev.keybuzz.io}"
COOKIE_FILE="/tmp/studio-bench-cookie"

echo "=== PH-STUDIO-07A.1 — Benchmark Suite ==="
echo "Target: $BASE"
echo ""

get_session() {
  if [ ! -f "$COOKIE_FILE" ]; then
    echo "[INFO] No cookie file — tests will run unauthenticated (may fail on protected routes)"
  fi
}

api_post() {
  local endpoint="$1"
  local body="$2"
  if [ -f "$COOKIE_FILE" ]; then
    curl -s -w "\n%{http_code}|%{time_total}" -X POST "$BASE$endpoint" \
      -H "Content-Type: application/json" \
      -b "$COOKIE_FILE" \
      -d "$body" 2>/dev/null
  else
    curl -s -w "\n%{http_code}|%{time_total}" -X POST "$BASE$endpoint" \
      -H "Content-Type: application/json" \
      -d "$body" 2>/dev/null
  fi
}

get_session

# Fetch first idea and template for benchmarks
echo "--- Fetching test data ---"
if [ -f "$COOKIE_FILE" ]; then
  IDEAS=$(curl -s "$BASE/api/v1/ideas" -b "$COOKIE_FILE" 2>/dev/null)
  TEMPLATES=$(curl -s "$BASE/api/v1/templates" -b "$COOKIE_FILE" 2>/dev/null)
else
  IDEAS=$(curl -s "$BASE/api/v1/ideas" 2>/dev/null)
  TEMPLATES=$(curl -s "$BASE/api/v1/templates" 2>/dev/null)
fi

IDEA_ID=$(echo "$IDEAS" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
TEMPLATE_ID=$(echo "$TEMPLATES" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$IDEA_ID" ] || [ -z "$TEMPLATE_ID" ]; then
  echo "[ERROR] No idea or template found — cannot run benchmarks"
  echo "  Ideas response: $(echo "$IDEAS" | head -c 200)"
  echo "  Templates response: $(echo "$TEMPLATES" | head -c 200)"
  exit 1
fi

echo "  Idea: $IDEA_ID"
echo "  Template: $TEMPLATE_ID"

run_benchmark() {
  local label="$1"
  local mode="$2"
  local variations="$3"
  local tone="$4"

  echo ""
  echo "--- Benchmark: $label ---"
  local body="{\"idea_id\":\"$IDEA_ID\",\"template_id\":\"$TEMPLATE_ID\",\"tone\":\"$tone\",\"length\":\"medium\",\"variations\":$variations,\"pipeline_mode\":\"$mode\"}"

  local start=$(date +%s%N 2>/dev/null || echo "0")
  local response=$(api_post "/api/v1/ai/generate-preview" "$body")
  local end=$(date +%s%N 2>/dev/null || echo "0")

  local http_line=$(echo "$response" | tail -1)
  local http_code=$(echo "$http_line" | cut -d'|' -f1)
  local curl_time=$(echo "$http_line" | cut -d'|' -f2)
  local body_content=$(echo "$response" | head -n -1)

  local provider=$(echo "$body_content" | grep -o '"provider":"[^"]*"' | head -1 | cut -d'"' -f4)
  local model=$(echo "$body_content" | grep -o '"model":"[^"]*"' | head -1 | cut -d'"' -f4)
  local is_fallback=$(echo "$body_content" | grep -o '"is_fallback":[a-z]*' | head -1 | cut -d':' -f2)
  local pipeline=$(echo "$body_content" | grep -o '"pipeline_mode":"[^"]*"' | head -1 | cut -d'"' -f4)
  local total_latency=$(echo "$body_content" | grep -o '"total_latency_ms":[0-9]*' | head -1 | cut -d':' -f2)
  local cost=$(echo "$body_content" | grep -o '"estimated_cost":[0-9.]*' | head -1 | cut -d':' -f2)
  local quality=$(echo "$body_content" | grep -o '"quality_scores":\[[0-9,]*\]' | head -1)

  echo "  HTTP: $http_code"
  echo "  Provider: $provider"
  echo "  Model: $model"
  echo "  Pipeline: $pipeline"
  echo "  Fallback: $is_fallback"
  echo "  Latency (server): ${total_latency:-N/A}ms"
  echo "  Latency (curl): ${curl_time}s"
  echo "  Cost: \$${cost:-0}"
  echo "  Quality: $quality"

  local variant_count=$(echo "$body_content" | grep -o '"variants":\[' | wc -l)
  echo "  Variants: $variant_count"

  if [ "$http_code" != "200" ]; then
    echo "  [ERROR] Response: $(echo "$body_content" | head -c 300)"
  fi
}

# --- 5 Benchmark cases ---

echo ""
echo "========================================="
echo "  CASE 1: LinkedIn post — Single (heuristic/LLM)"
echo "========================================="
run_benchmark "LinkedIn single" "single" 1 "professional"

echo ""
echo "========================================="
echo "  CASE 2: LinkedIn post — Standard pipeline"
echo "========================================="
run_benchmark "LinkedIn standard" "standard" 1 "professional"

echo ""
echo "========================================="
echo "  CASE 3: LinkedIn post — Premium pipeline"
echo "========================================="
run_benchmark "LinkedIn premium" "premium" 1 "professional"

echo ""
echo "========================================="
echo "  CASE 4: Reddit post — Single, 2 variants"
echo "========================================="
run_benchmark "Reddit 2-variants" "single" 2 "casual"

echo ""
echo "========================================="
echo "  CASE 5: Founder post — Premium, friendly"
echo "========================================="
run_benchmark "Founder premium" "premium" 1 "friendly"

echo ""
echo "======================================="
echo "  BENCHMARK COMPLETE"
echo "======================================="
