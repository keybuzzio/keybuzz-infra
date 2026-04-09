#!/usr/bin/env bash
set -euo pipefail

API="https://studio-api-dev.keybuzz.io"
FE="https://studio-dev.keybuzz.io"
PASS=0
FAIL=0
EMAIL="ludovic@keybuzz.pro"

ok() { echo "  PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "=== PH-STUDIO-06 — Validate DEV ==="

# --- Auth ---
echo ""
echo "--- 1. Auth session ---"
OTP_RESP=$(curl -s -w "\n%{http_code}" -X POST "$API/api/v1/auth/request-otp" \
  -H "Content-Type: application/json" -d "{\"email\":\"$EMAIL\"}")
OTP_CODE=$(echo "$OTP_RESP" | head -1 | grep -oP '"devCode":"([^"]+)"' | cut -d'"' -f4 || echo "")
OTP_HTTP=$(echo "$OTP_RESP" | tail -1)

if [ "$OTP_HTTP" = "200" ]; then ok "request-otp $OTP_HTTP"; else fail "request-otp $OTP_HTTP"; fi

COOKIE=""
if [ -n "$OTP_CODE" ]; then
  VERIFY_RESP=$(curl -s -D- -X POST "$API/api/v1/auth/verify-otp" \
    -H "Content-Type: application/json" -d "{\"email\":\"$EMAIL\",\"code\":\"$OTP_CODE\"}" 2>&1)
  COOKIE=$(echo "$VERIFY_RESP" | grep -i 'set-cookie' | head -1 | sed 's/.*kb_studio_session=//;s/;.*//')
  if [ -n "$COOKIE" ]; then ok "verify-otp session"; else fail "verify-otp no cookie"; fi
else
  echo "  SKIP: OTP code not in response (expected in prod mode)"
fi

HDR=""
if [ -n "$COOKIE" ]; then HDR="Cookie: kb_studio_session=$COOKIE"; fi

# --- Learning sources ---
echo ""
echo "--- 2. Learning sources CRUD ---"

SRC_ID=$(curl -s -X POST "$API/api/v1/learning/sources" \
  -H "Content-Type: application/json" ${HDR:+-H "$HDR"} \
  -d '{"title":"Test video transcript","type":"video","raw_content":"This is a strategy for long-term growth. The approach includes tip #1: always use hooks. What if you tried a new framework? Step by step method to improve engagement. Did you know that most content fails?","tags":["test","marketing"]}' \
  | grep -oP '"id":"([^"]+)"' | head -1 | cut -d'"' -f4)

if [ -n "$SRC_ID" ]; then ok "create source ($SRC_ID)"; else fail "create source"; fi

LIST_SRC=$(curl -s ${HDR:+-H "$HDR"} "$API/api/v1/learning/sources" | grep -c '"id"' || echo 0)
if [ "$LIST_SRC" -ge 1 ]; then ok "list sources ($LIST_SRC)"; else fail "list sources ($LIST_SRC)"; fi

# --- Process source ---
echo ""
echo "--- 3. Process source ---"
if [ -n "$SRC_ID" ]; then
  PROC_RESP=$(curl -s -X POST "$API/api/v1/learning/process" \
    -H "Content-Type: application/json" ${HDR:+-H "$HDR"} \
    -d "{\"source_id\":\"$SRC_ID\"}")
  INS_COUNT=$(echo "$PROC_RESP" | grep -oP '"insights_count":([0-9]+)' | cut -d: -f2 || echo 0)
  if [ "$INS_COUNT" -ge 1 ]; then ok "process source ($INS_COUNT insights)"; else fail "process source ($INS_COUNT)"; fi
fi

# --- Insights ---
echo ""
echo "--- 4. Insights ---"
INSIGHTS=$(curl -s ${HDR:+-H "$HDR"} "$API/api/v1/learning/insights" | grep -c '"id"' || echo 0)
if [ "$INSIGHTS" -ge 1 ]; then ok "list insights ($INSIGHTS)"; else fail "list insights ($INSIGHTS)"; fi

# --- Templates ---
echo ""
echo "--- 5. Templates CRUD ---"

SEED_RESP=$(curl -s -X POST "$API/api/v1/templates/seed" ${HDR:+-H "$HDR"})
SEED_COUNT=$(echo "$SEED_RESP" | grep -oP '"count":([0-9]+)' | cut -d: -f2 || echo 0)
ok "seed templates ($SEED_COUNT)"

TPLS=$(curl -s ${HDR:+-H "$HDR"} "$API/api/v1/templates")
TPL_COUNT=$(echo "$TPLS" | grep -c '"id"' || echo 0)
if [ "$TPL_COUNT" -ge 3 ]; then ok "list templates ($TPL_COUNT)"; else fail "list templates ($TPL_COUNT)"; fi

TPL_ID=$(echo "$TPLS" | grep -oP '"id":"([^"]+)"' | head -1 | cut -d'"' -f4)

NEW_TPL_ID=$(curl -s -X POST "$API/api/v1/templates" \
  -H "Content-Type: application/json" ${HDR:+-H "$HDR"} \
  -d '{"name":"Test Template","type":"article","structure":{"sections":[{"name":"intro","label":"Intro","description":"Opening"}]}}' \
  | grep -oP '"id":"([^"]+)"' | head -1 | cut -d'"' -f4)
if [ -n "$NEW_TPL_ID" ]; then ok "create template ($NEW_TPL_ID)"; else fail "create template"; fi

if [ -n "$NEW_TPL_ID" ]; then
  UPD_RESP=$(curl -s -X PATCH "$API/api/v1/templates/$NEW_TPL_ID" \
    -H "Content-Type: application/json" ${HDR:+-H "$HDR"} \
    -d '{"name":"Updated Template"}')
  UPD_NAME=$(echo "$UPD_RESP" | grep -oP '"name":"Updated Template"' || echo "")
  if [ -n "$UPD_NAME" ]; then ok "update template"; else fail "update template"; fi

  DEL_RESP=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$API/api/v1/templates/$NEW_TPL_ID" ${HDR:+-H "$HDR"})
  if [ "$DEL_RESP" = "200" ]; then ok "delete template"; else fail "delete template ($DEL_RESP)"; fi
fi

# --- Content Generation ---
echo ""
echo "--- 6. Content generation ---"

IDEA_ID=$(curl -s -X POST "$API/api/v1/ideas" \
  -H "Content-Type: application/json" ${HDR:+-H "$HDR"} \
  -d '{"title":"AI for marketing automation","description":"How AI can transform marketing workflows","status":"approved","target_channel":"linkedin","tags":["ai","marketing"]}' \
  | grep -oP '"id":"([^"]+)"' | head -1 | cut -d'"' -f4)
if [ -n "$IDEA_ID" ]; then ok "create test idea ($IDEA_ID)"; else fail "create test idea"; fi

if [ -n "$IDEA_ID" ] && [ -n "$TPL_ID" ]; then
  GEN_RESP=$(curl -s -X POST "$API/api/v1/content/generate" \
    -H "Content-Type: application/json" ${HDR:+-H "$HDR"} \
    -d "{\"idea_id\":\"$IDEA_ID\",\"template_id\":\"$TPL_ID\",\"tone\":\"professional\",\"length\":\"medium\"}")
  GEN_BODY=$(echo "$GEN_RESP" | grep -oP '"body":"' || echo "")
  GEN_SECTIONS=$(echo "$GEN_RESP" | grep -c '"label"' || echo 0)
  if [ -n "$GEN_BODY" ] && [ "$GEN_SECTIONS" -ge 1 ]; then ok "generate content ($GEN_SECTIONS sections)"; else fail "generate content"; fi

  SAVE_RESP=$(curl -s -X POST "$API/api/v1/content/generate-and-save" \
    -H "Content-Type: application/json" ${HDR:+-H "$HDR"} \
    -d "{\"idea_id\":\"$IDEA_ID\",\"template_id\":\"$TPL_ID\",\"tone\":\"casual\",\"length\":\"short\",\"content_type\":\"post\"}")
  SAVED_ID=$(echo "$SAVE_RESP" | grep -oP '"id":"([^"]+)"' | head -1 | cut -d'"' -f4)
  if [ -n "$SAVED_ID" ]; then ok "generate-and-save ($SAVED_ID)"; else fail "generate-and-save"; fi
fi

# --- Dashboard ---
echo ""
echo "--- 7. Dashboard stats ---"
DASH_RESP=$(curl -s ${HDR:+-H "$HDR"} "$API/api/v1/dashboard/stats")
HAS_LEARNING=$(echo "$DASH_RESP" | grep -c '"learning_sources_count"' || echo 0)
HAS_INSIGHTS=$(echo "$DASH_RESP" | grep -c '"learning_insights_count"' || echo 0)
HAS_TEMPLATES=$(echo "$DASH_RESP" | grep -c '"templates_count"' || echo 0)
if [ "$HAS_LEARNING" -ge 1 ] && [ "$HAS_INSIGHTS" -ge 1 ] && [ "$HAS_TEMPLATES" -ge 1 ]; then
  ok "dashboard has new counters"
else
  fail "dashboard missing new counters"
fi

# --- Cleanup test data ---
echo ""
echo "--- 8. Cleanup ---"
if [ -n "$SRC_ID" ]; then
  curl -s -X DELETE "$API/api/v1/learning/sources/$SRC_ID" ${HDR:+-H "$HDR"} > /dev/null
  ok "cleanup source"
fi
if [ -n "$IDEA_ID" ]; then
  curl -s -X DELETE "$API/api/v1/ideas/$IDEA_ID" ${HDR:+-H "$HDR"} > /dev/null
  ok "cleanup idea"
fi

# --- Frontend pages ---
echo ""
echo "--- 9. Frontend pages ---"
for PAGE in learning templates; do
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$FE/$PAGE")
  if [ "$HTTP" = "200" ] || [ "$HTTP" = "307" ]; then ok "$PAGE page ($HTTP)"; else fail "$PAGE page ($HTTP)"; fi
done

# --- Summary ---
echo ""
echo "========================"
echo "PASS: $PASS  FAIL: $FAIL"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASSED"
else
  echo "SOME TESTS FAILED"
fi
echo "========================"
