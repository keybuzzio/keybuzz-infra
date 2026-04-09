#!/usr/bin/env bash
set -euo pipefail

API="https://studio-api-dev.keybuzz.io"

echo "=== PH-STUDIO-04B — Validate DEV ==="

echo ""
echo "--- 1. Auth: setup/status ---"
curl -s "$API/api/v1/auth/setup/status"
echo ""

echo ""
echo "--- 2. Auth: request OTP ---"
OTP_RESP=$(curl -s -X POST "$API/api/v1/auth/request-otp" \
  -H "Content-Type: application/json" \
  -d '{"email":"ludovic@keybuzz.pro"}')
echo "$OTP_RESP"
DEV_CODE=$(echo "$OTP_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('devCode',''))" 2>/dev/null || echo "")

if [ -z "$DEV_CODE" ]; then
  echo "No devCode returned — SMTP likely sent the email"
  echo "SKIP OTP verification (no devCode available)"
else
  echo ""
  echo "--- 3. Auth: verify OTP ---"
  VERIFY_RESP=$(curl -s -w "\n%{http_code}" -X POST "$API/api/v1/auth/verify-otp" \
    -H "Content-Type: application/json" \
    -c /tmp/studio-cookies.txt \
    -d "{\"email\":\"ludovic@keybuzz.pro\",\"code\":\"$DEV_CODE\"}")
  HTTP_CODE=$(echo "$VERIFY_RESP" | tail -1)
  BODY=$(echo "$VERIFY_RESP" | head -n -1)
  echo "HTTP: $HTTP_CODE"
  echo "Body: $BODY"

  echo ""
  echo "--- 4. Auth: /auth/me ---"
  curl -s -b /tmp/studio-cookies.txt "$API/api/v1/auth/me"
  echo ""

  echo ""
  echo "--- 5. Dashboard stats ---"
  curl -s -b /tmp/studio-cookies.txt "$API/api/v1/dashboard/stats"
  echo ""

  echo ""
  echo "--- 6. Knowledge CRUD ---"
  K_RESP=$(curl -s -X POST -b /tmp/studio-cookies.txt \
    -H "Content-Type: application/json" \
    "$API/api/v1/knowledge" \
    -d '{"title":"Brand Positioning","doc_type":"positioning","status":"active","summary":"KeyBuzz brand positioning document","content":"Test content","tags":["brand","positioning"]}')
  echo "Create: $K_RESP"
  K_ID=$(echo "$K_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "")
  
  if [ -n "$K_ID" ]; then
    curl -s -b /tmp/studio-cookies.txt "$API/api/v1/knowledge/$K_ID" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'Get: id={d[\"id\"]} title={d[\"title\"]} status={d[\"status\"]}')"
    curl -s -X PATCH -b /tmp/studio-cookies.txt -H "Content-Type: application/json" "$API/api/v1/knowledge/$K_ID" -d '{"status":"draft"}' | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'Update: status={d[\"status\"]}')"
    echo "List: $(curl -s -b /tmp/studio-cookies.txt "$API/api/v1/knowledge" | python3 -c "import sys,json; print(len(json.load(sys.stdin)),'docs')")"
  fi

  echo ""
  echo "--- 7. Ideas CRUD ---"
  I_RESP=$(curl -s -X POST -b /tmp/studio-cookies.txt \
    -H "Content-Type: application/json" \
    "$API/api/v1/ideas" \
    -d '{"title":"LinkedIn thought leadership series","description":"Weekly posts about SaaS marketing","status":"inbox","score":75,"target_channel":"linkedin","tags":["linkedin","thought-leadership"]}')
  echo "Create: $I_RESP"
  I_ID=$(echo "$I_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "")
  
  if [ -n "$I_ID" ]; then
    curl -s -b /tmp/studio-cookies.txt "$API/api/v1/ideas/$I_ID" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'Get: id={d[\"id\"]} title={d[\"title\"]} score={d[\"score\"]}')"
    curl -s -X PATCH -b /tmp/studio-cookies.txt -H "Content-Type: application/json" "$API/api/v1/ideas/$I_ID" -d '{"status":"approved"}' | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'Update: status={d[\"status\"]}')"
    echo "List: $(curl -s -b /tmp/studio-cookies.txt "$API/api/v1/ideas" | python3 -c "import sys,json; print(len(json.load(sys.stdin)),'ideas')")"
  fi

  echo ""
  echo "--- 8. Content CRUD + versions ---"
  C_RESP=$(curl -s -X POST -b /tmp/studio-cookies.txt \
    -H "Content-Type: application/json" \
    "$API/api/v1/content" \
    -d '{"title":"Why SaaS needs content marketing","body":"Draft body text...","content_type":"linkedin_post","channel":"linkedin","tags":["marketing","saas"]}')
  echo "Create: $C_RESP"
  C_ID=$(echo "$C_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "")
  
  if [ -n "$C_ID" ]; then
    curl -s -b /tmp/studio-cookies.txt "$API/api/v1/content/$C_ID" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'Get: id={d[\"id\"]} title={d[\"title\"]} status={d[\"status\"]}')"
    
    echo "Create version 2:"
    curl -s -X POST -b /tmp/studio-cookies.txt -H "Content-Type: application/json" \
      "$API/api/v1/content/$C_ID/versions" \
      -d '{"title":"Why SaaS needs content marketing (v2)","body":"Improved body text...","notes":"Improved intro"}' | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'Version {d[\"version_number\"]} created')"
    
    echo "Versions:"
    curl -s -b /tmp/studio-cookies.txt "$API/api/v1/content/$C_ID/versions" | python3 -c "import sys,json; [print(f'  v{v[\"version_number\"]}: {v[\"title\"]}') for v in json.load(sys.stdin)]"
    
    curl -s -X PATCH -b /tmp/studio-cookies.txt -H "Content-Type: application/json" "$API/api/v1/content/$C_ID" -d '{"status":"review"}' | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'Update status: {d[\"status\"]}')"
    echo "List: $(curl -s -b /tmp/studio-cookies.txt "$API/api/v1/content" | python3 -c "import sys,json; print(len(json.load(sys.stdin)),'items')")"
  fi

  echo ""
  echo "--- 9. Dashboard stats (with data) ---"
  curl -s -b /tmp/studio-cookies.txt "$API/api/v1/dashboard/stats" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(f'Knowledge: {d[\"knowledge_count\"]}')
print(f'Ideas: {d[\"ideas_count\"]}')
print(f'Content: {d[\"content_count\"]}')
print(f'Drafts: {d[\"drafts_count\"]}')
print(f'Recent items: {len(d[\"recent_items\"])}')
"

  echo ""
  echo "--- 10. Auth: logout ---"
  curl -s -X POST -b /tmp/studio-cookies.txt -c /tmp/studio-cookies.txt "$API/api/v1/auth/logout"
  echo ""
  echo "After logout /auth/me:"
  curl -s -b /tmp/studio-cookies.txt "$API/api/v1/auth/me"
  echo ""
  
  rm -f /tmp/studio-cookies.txt
fi

echo ""
echo "--- 11. Frontend pages ---"
for page in login dashboard knowledge ideas content; do
  URL="https://studio-dev.keybuzz.io/$page"
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
  echo "$page: HTTP $CODE"
done

echo ""
echo "=== DEV VALIDATION COMPLETE ==="
