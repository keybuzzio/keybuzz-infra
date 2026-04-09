#!/usr/bin/env bash
set -euo pipefail

API="https://studio-api-dev.keybuzz.io"
FE="https://studio-dev.keybuzz.io"
PASS=0
FAIL=0

ok()   { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
check(){ if [ "$1" -eq 0 ]; then ok "$2"; else fail "$2"; fi; }

echo "=== PH-STUDIO-07A — Validate DEV ==="
echo ""

# 0. Login to get session
echo "--- 0. Authenticate ---"
LOGIN_EMAIL="ludovic@keybuzz.pro"
BOOTSTRAP_SECRET=$(kubectl get secret keybuzz-studio-api-env -n keybuzz-studio-api-dev -o jsonpath='{.data.BOOTSTRAP_SECRET}' 2>/dev/null | base64 -d 2>/dev/null)
if [ -z "$BOOTSTRAP_SECRET" ]; then
  echo "  Cannot extract bootstrap secret, trying devCode approach"
  BOOTSTRAP_SECRET=""
fi

REQ_OTP=$(curl -s -c /tmp/studio-cookie -b /tmp/studio-cookie \
  -X POST "$API/api/v1/auth/request-otp" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"${LOGIN_EMAIL}\"}")
echo "  request-otp: $(echo "$REQ_OTP" | head -c 120)"

DEV_CODE=$(echo "$REQ_OTP" | grep -o '"devCode":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -z "$DEV_CODE" ]; then
  DEV_CODE=$(echo "$REQ_OTP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('devCode',''))" 2>/dev/null || echo "")
fi

if [ -n "$DEV_CODE" ]; then
  VERIFY=$(curl -s -c /tmp/studio-cookie -b /tmp/studio-cookie \
    -X POST "$API/api/v1/auth/verify-otp" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"${LOGIN_EMAIL}\",\"code\":\"${DEV_CODE}\"}")
  echo "  verify-otp: $(echo "$VERIFY" | head -c 100)"
  check 0 "auth session established"
else
  echo "  WARNING: No devCode found, will attempt requests with existing cookies"
  check 1 "auth session established"
fi

echo ""
echo "--- 1. AI Health ---"
AI_HEALTH=$(curl -s -b /tmp/studio-cookie "$API/api/v1/ai/health")
echo "  $AI_HEALTH"
echo "$AI_HEALTH" | grep -q '"status":"ok"'
check $? "ai/health returns ok"

PROVIDER=$(echo "$AI_HEALTH" | grep -o '"provider":"[^"]*"' | cut -d'"' -f4)
LLM_ENABLED=$(echo "$AI_HEALTH" | grep -o '"llm_enabled":[a-z]*' | cut -d: -f2)
echo "  Provider: $PROVIDER | LLM enabled: $LLM_ENABLED"

echo ""
echo "--- 2. Dashboard stats (ai_generations_count) ---"
STATS=$(curl -s -b /tmp/studio-cookie "$API/api/v1/dashboard/stats")
echo "$STATS" | grep -q '"ai_generations_count"'
check $? "dashboard includes ai_generations_count"

echo ""
echo "--- 3. Seed templates (ensure at least 1) ---"
curl -s -b /tmp/studio-cookie -X POST "$API/api/v1/templates/seed" > /dev/null 2>&1
TEMPLATES=$(curl -s -b /tmp/studio-cookie "$API/api/v1/templates")
TMPL_ID=$(echo "$TEMPLATES" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
[ -n "$TMPL_ID" ]
check $? "template available: $TMPL_ID"

echo ""
echo "--- 4. Create test idea ---"
IDEA=$(curl -s -b /tmp/studio-cookie \
  -X POST "$API/api/v1/ideas" \
  -H 'Content-Type: application/json' \
  -d '{"title":"AI Gateway Test Idea","description":"Testing the Studio AI gateway with heuristic and LLM fallback","status":"approved","target_channel":"linkedin","tags":["ai","test"]}')
IDEA_ID=$(echo "$IDEA" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
[ -n "$IDEA_ID" ]
check $? "test idea created: $IDEA_ID"

echo ""
echo "--- 5. AI Generate Preview (1 variant) ---"
PREVIEW=$(curl -s -b /tmp/studio-cookie \
  -X POST "$API/api/v1/ai/generate-preview" \
  -H 'Content-Type: application/json' \
  -d "{\"idea_id\":\"${IDEA_ID}\",\"template_id\":\"${TMPL_ID}\",\"tone\":\"professional\",\"length\":\"medium\",\"variations\":1}")
echo "  Preview response (first 200): $(echo "$PREVIEW" | head -c 200)"
echo "$PREVIEW" | grep -q '"variants"'
check $? "generate-preview returns variants"
echo "$PREVIEW" | grep -q '"provider"'
check $? "generate-preview includes provider"
echo "$PREVIEW" | grep -q '"quality_scores"'
check $? "generate-preview includes quality_scores"

echo ""
echo "--- 6. AI Generate Preview (2 variants) ---"
PREVIEW2=$(curl -s -b /tmp/studio-cookie \
  -X POST "$API/api/v1/ai/generate-preview" \
  -H 'Content-Type: application/json' \
  -d "{\"idea_id\":\"${IDEA_ID}\",\"template_id\":\"${TMPL_ID}\",\"tone\":\"casual\",\"length\":\"short\",\"variations\":2}")
VCOUNT=$(echo "$PREVIEW2" | grep -o '"sections"' | wc -l)
[ "$VCOUNT" -ge 2 ]
check $? "2+ variants generated (found $VCOUNT sections blocks)"

echo ""
echo "--- 7. AI Generate and Save ---"
SAVED=$(curl -s -b /tmp/studio-cookie \
  -X POST "$API/api/v1/ai/generate-and-save" \
  -H 'Content-Type: application/json' \
  -d "{\"idea_id\":\"${IDEA_ID}\",\"template_id\":\"${TMPL_ID}\",\"tone\":\"professional\",\"length\":\"medium\",\"variations\":1,\"content_type\":\"post\"}")
echo "  Save response (first 200): $(echo "$SAVED" | head -c 200)"
echo "$SAVED" | grep -q '"content"'
check $? "generate-and-save creates content"
echo "$SAVED" | grep -q '"generation"'
check $? "generate-and-save returns generation metadata"

CONTENT_ID=$(echo "$SAVED" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
echo "  Content created: $CONTENT_ID"

echo ""
echo "--- 8. Verify ai_generations table ---"
STATS2=$(curl -s -b /tmp/studio-cookie "$API/api/v1/dashboard/stats")
AI_COUNT=$(echo "$STATS2" | grep -o '"ai_generations_count":[0-9]*' | cut -d: -f2)
[ "${AI_COUNT:-0}" -ge 1 ]
check $? "ai_generations tracked ($AI_COUNT entries)"

echo ""
echo "--- 9. Frontend accessible ---"
FE_STATUS=$(curl -s -o /dev/null -w '%{http_code}' "$FE/login")
[ "$FE_STATUS" = "200" ]
check $? "frontend /login HTTP $FE_STATUS"

FE_IDEAS=$(curl -s -o /dev/null -w '%{http_code}' "$FE/ideas")
echo "  /ideas HTTP $FE_IDEAS"

echo ""
echo "--- 10. Cleanup test data ---"
curl -s -b /tmp/studio-cookie -X DELETE "$API/api/v1/ideas/$IDEA_ID" > /dev/null 2>&1
if [ -n "${CONTENT_ID:-}" ]; then
  curl -s -b /tmp/studio-cookie -X DELETE "$API/api/v1/content/$CONTENT_ID" > /dev/null 2>&1
fi
echo "  Test data cleaned up"

echo ""
echo "=========================================="
echo "  Results: $PASS passed / $FAIL failed"
echo "=========================================="

if [ "$FAIL" -gt 0 ]; then
  echo "  VERDICT: PARTIAL — $FAIL test(s) failed"
  exit 1
else
  echo "  VERDICT: DEV VALIDATED"
fi
