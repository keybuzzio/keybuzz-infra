#!/usr/bin/env bash
set -euo pipefail

API="https://studio-api-dev.keybuzz.io"
FE="https://studio-dev.keybuzz.io"
PASS=0
FAIL=0

ok()   { PASS=$((PASS+1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL+1)); echo "  ✗ $1"; }
check_http() {
  local label="$1" url="$2" expected="$3"
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
  if [ "$code" = "$expected" ]; then ok "$label (HTTP $code)"; else fail "$label (HTTP $code, expected $expected)"; fi
}

echo "=== PH-STUDIO-05 — Validation DEV ==="

# --- Auth: get session ---
echo ""
echo "--- Auth (get session via devCode) ---"
OTP_RESP=$(curl -s -X POST "$API/api/v1/auth/request-otp" \
  -H "Content-Type: application/json" \
  -d '{"email":"ludovic@keybuzz.pro"}')
DEV_CODE=$(echo "$OTP_RESP" | grep -o '"devCode":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -z "$DEV_CODE" ]; then
  fail "OTP devCode not returned"
  echo "OTP response: $OTP_RESP"
  echo "=== VALIDATION ABORTED ==="
  exit 1
fi
ok "OTP requested, devCode received"

VERIFY_RESP=$(curl -s -c /tmp/studio05-cookies.txt -X POST "$API/api/v1/auth/verify-otp" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"ludovic@keybuzz.pro\",\"code\":\"$DEV_CODE\"}")
if echo "$VERIFY_RESP" | grep -q '"user"'; then
  ok "OTP verified, session created"
else
  fail "OTP verify failed: $VERIFY_RESP"
  exit 1
fi

COOKIE="-b /tmp/studio05-cookies.txt"

# --- Dashboard ---
echo ""
echo "--- Dashboard stats ---"
STATS=$(curl -s $COOKIE "$API/api/v1/dashboard/stats")
for key in knowledge_count ideas_count content_count drafts_count scheduled_count published_count assets_count; do
  if echo "$STATS" | grep -q "\"$key\""; then ok "Dashboard has $key"; else fail "Dashboard missing $key"; fi
done

# --- Calendar CRUD ---
echo ""
echo "--- Calendar CRUD ---"
CAL=$(curl -s $COOKIE -X POST "$API/api/v1/calendar" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Calendar Entry","scheduled_date":"2026-04-15","scheduled_time":"10:00","channel":"linkedin","status":"draft"}')
CAL_ID=$(echo "$CAL" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -n "$CAL_ID" ]; then ok "Calendar create => $CAL_ID"; else fail "Calendar create failed: $CAL"; fi

CAL_LIST=$(curl -s $COOKIE "$API/api/v1/calendar?from=2026-04-01&to=2026-04-30")
if echo "$CAL_LIST" | grep -q "$CAL_ID"; then ok "Calendar list OK"; else fail "Calendar list missing entry"; fi

CAL_UPD=$(curl -s $COOKIE -X PATCH "$API/api/v1/calendar/$CAL_ID" \
  -H "Content-Type: application/json" \
  -d '{"status":"scheduled","notes":"Updated note"}')
if echo "$CAL_UPD" | grep -q '"scheduled"'; then ok "Calendar update OK"; else fail "Calendar update failed"; fi

CAL_DEL=$(curl -s $COOKIE -X DELETE "$API/api/v1/calendar/$CAL_ID")
if echo "$CAL_DEL" | grep -q '"success"'; then ok "Calendar delete OK"; else fail "Calendar delete failed"; fi

# --- Assets (upload + CRUD) ---
echo ""
echo "--- Assets CRUD ---"
echo "Test asset content" > /tmp/test-asset.txt

ASSET=$(curl -s $COOKIE -X POST "$API/api/v1/assets/upload" \
  -F "file=@/tmp/test-asset.txt" \
  -F "tags=test,studio05")
ASSET_ID=$(echo "$ASSET" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -n "$ASSET_ID" ]; then ok "Asset upload => $ASSET_ID"; else fail "Asset upload failed: $ASSET"; fi

ASSET_LIST=$(curl -s $COOKIE "$API/api/v1/assets")
if echo "$ASSET_LIST" | grep -q "$ASSET_ID"; then ok "Asset list OK"; else fail "Asset list missing asset"; fi

ASSET_GET=$(curl -s $COOKIE "$API/api/v1/assets/$ASSET_ID")
if echo "$ASSET_GET" | grep -q '"test-asset.txt"'; then ok "Asset get OK"; else fail "Asset get failed"; fi

ASSET_FILE=$(curl -s -o /dev/null -w "%{http_code}" "$API/api/v1/assets/$ASSET_ID/file")
if [ "$ASSET_FILE" = "200" ]; then ok "Asset file serve OK (HTTP 200)"; else fail "Asset file serve (HTTP $ASSET_FILE)"; fi

ASSET_UPD=$(curl -s $COOKIE -X PATCH "$API/api/v1/assets/$ASSET_ID" \
  -H "Content-Type: application/json" \
  -d '{"tags":["updated","tag"]}')
if echo "$ASSET_UPD" | grep -q '"updated"'; then ok "Asset update tags OK"; else fail "Asset update tags failed"; fi

ASSET_DEL=$(curl -s $COOKIE -X DELETE "$API/api/v1/assets/$ASSET_ID")
if echo "$ASSET_DEL" | grep -q '"success"'; then ok "Asset delete OK"; else fail "Asset delete failed"; fi

# --- Content workflow transitions ---
echo ""
echo "--- Content workflow transitions ---"
CONTENT=$(curl -s $COOKIE -X POST "$API/api/v1/content" \
  -H "Content-Type: application/json" \
  -d '{"title":"Workflow Test Post","content_type":"post","channel":"linkedin"}')
C_ID=$(echo "$CONTENT" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -n "$C_ID" ]; then ok "Content created => $C_ID (status=draft)"; else fail "Content create failed"; fi

# draft → review
T1=$(curl -s $COOKIE -X POST "$API/api/v1/content/$C_ID/transition" \
  -H "Content-Type: application/json" -d '{"status":"review"}')
if echo "$T1" | grep -q '"review"'; then ok "Transition draft→review OK"; else fail "Transition draft→review: $T1"; fi

# review → approved
T2=$(curl -s $COOKIE -X POST "$API/api/v1/content/$C_ID/transition" \
  -H "Content-Type: application/json" -d '{"status":"approved"}')
if echo "$T2" | grep -q '"approved"'; then ok "Transition review→approved OK"; else fail "Transition review→approved: $T2"; fi

# approved → scheduled
T3=$(curl -s $COOKIE -X POST "$API/api/v1/content/$C_ID/transition" \
  -H "Content-Type: application/json" -d '{"status":"scheduled"}')
if echo "$T3" | grep -q '"scheduled"'; then ok "Transition approved→scheduled OK"; else fail "Transition approved→scheduled: $T3"; fi

# scheduled → published
T4=$(curl -s $COOKIE -X POST "$API/api/v1/content/$C_ID/transition" \
  -H "Content-Type: application/json" -d '{"status":"published"}')
if echo "$T4" | grep -q '"published"'; then ok "Transition scheduled→published OK"; else fail "Transition scheduled→published: $T4"; fi

# published → archived
T5=$(curl -s $COOKIE -X POST "$API/api/v1/content/$C_ID/transition" \
  -H "Content-Type: application/json" -d '{"status":"archived"}')
if echo "$T5" | grep -q '"archived"'; then ok "Transition published→archived OK"; else fail "Transition published→archived: $T5"; fi

# Invalid: archived → published (should fail)
T6=$(curl -s -w "\n%{http_code}" $COOKIE -X POST "$API/api/v1/content/$C_ID/transition" \
  -H "Content-Type: application/json" -d '{"status":"published"}')
T6_CODE=$(echo "$T6" | tail -1)
if [ "$T6_CODE" = "400" ]; then ok "Invalid transition blocked (HTTP 400)"; else fail "Invalid transition not blocked (HTTP $T6_CODE)"; fi

# Cleanup
curl -s $COOKIE -X DELETE "$API/api/v1/content/$C_ID" > /dev/null

# --- Content-Asset linking ---
echo ""
echo "--- Content-Asset linking ---"
LINK_C=$(curl -s $COOKIE -X POST "$API/api/v1/content" \
  -H "Content-Type: application/json" \
  -d '{"title":"Link Test","content_type":"post"}')
LC_ID=$(echo "$LINK_C" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

echo "Link asset file" > /tmp/link-asset.txt
LINK_A=$(curl -s $COOKIE -X POST "$API/api/v1/assets/upload" -F "file=@/tmp/link-asset.txt")
LA_ID=$(echo "$LINK_A" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

ATTACH=$(curl -s $COOKIE -X POST "$API/api/v1/content/$LC_ID/assets" \
  -H "Content-Type: application/json" -d "{\"asset_id\":\"$LA_ID\"}")
if echo "$ATTACH" | grep -q '"success"'; then ok "Attach asset to content OK"; else fail "Attach failed"; fi

CA_LIST=$(curl -s $COOKIE "$API/api/v1/content/$LC_ID/assets")
if echo "$CA_LIST" | grep -q "$LA_ID"; then ok "List content assets OK"; else fail "List content assets missing"; fi

DETACH=$(curl -s $COOKIE -X DELETE "$API/api/v1/content/$LC_ID/assets/$LA_ID")
if echo "$DETACH" | grep -q '"success"'; then ok "Detach asset from content OK"; else fail "Detach failed"; fi

# Cleanup
curl -s $COOKIE -X DELETE "$API/api/v1/content/$LC_ID" > /dev/null
curl -s $COOKIE -X DELETE "$API/api/v1/assets/$LA_ID" > /dev/null

# --- Frontend pages ---
echo ""
echo "--- Frontend pages ---"
for page in /login /dashboard /calendar /assets /content /ideas /knowledge; do
  check_http "Page $page" "$FE$page" "200"
done

# --- Logout ---
echo ""
echo "--- Logout ---"
LOGOUT=$(curl -s $COOKIE -X POST "$API/api/v1/auth/logout")
if echo "$LOGOUT" | grep -q '"success"'; then ok "Logout OK"; else fail "Logout: $LOGOUT"; fi

echo ""
echo "================================"
echo "PASSED: $PASS"
echo "FAILED: $FAIL"
echo "================================"
if [ "$FAIL" -eq 0 ]; then
  echo "=== PH-STUDIO-05 DEV VALIDATION COMPLETE ==="
else
  echo "=== PH-STUDIO-05 DEV VALIDATION PARTIAL ==="
fi
