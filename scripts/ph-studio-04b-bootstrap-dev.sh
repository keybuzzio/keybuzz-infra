#!/usr/bin/env bash
set -euo pipefail

echo "=== PH-STUDIO-04B — Bootstrap Owner DEV ==="

cat > /tmp/bootstrap-dev.json <<'EOF'
{
  "email": "ludovic@keybuzz.pro",
  "displayName": "Ludovic GONTHIER",
  "workspaceName": "KeyBuzz",
  "workspaceSlug": "keybuzz",
  "bootstrapSecret": "BOOTSTRAP_SECRET_DEV_REDACTED"
}
EOF

echo "--- Calling setup endpoint ---"
RESULT=$(curl -s -w "\n%{http_code}" -X POST \
  https://studio-api-dev.keybuzz.io/api/v1/auth/setup \
  -H "Content-Type: application/json" \
  -d @/tmp/bootstrap-dev.json)

HTTP_CODE=$(echo "$RESULT" | tail -1)
BODY=$(echo "$RESULT" | head -n -1)

echo "HTTP: $HTTP_CODE"
echo "Response: $BODY"

rm -f /tmp/bootstrap-dev.json

if [ "$HTTP_CODE" -ne 201 ]; then
  echo "ERROR: Bootstrap failed"
  exit 1
fi

echo ""
echo "--- Verifying setup status ---"
curl -s https://studio-api-dev.keybuzz.io/api/v1/auth/setup/status
echo ""

echo ""
echo "--- Verifying DB state ---"
PGPASSWORD=$(vault kv get -field=password secret/keybuzz/dev/studio-db 2>/dev/null || echo "")
if [ -z "$PGPASSWORD" ]; then
  PGPASSWORD=$(kubectl get secret keybuzz-studio-api-db -n keybuzz-studio-api-dev -o jsonpath='{.data.password}' | base64 -d)
fi

DB_HOST=$(kubectl get secret keybuzz-studio-api-db -n keybuzz-studio-api-dev -o jsonpath='{.data.host}' | base64 -d 2>/dev/null || echo "10.0.0.150")

export PGPASSWORD
psql -h "$DB_HOST" -U studio_user -d keybuzz_studio -p 5432 -c "SELECT id, email, display_name, status FROM users;" 2>/dev/null || echo "DB check skipped (psql not available or creds differ)"
psql -h "$DB_HOST" -U studio_user -d keybuzz_studio -p 5432 -c "SELECT id, name, slug FROM workspaces;" 2>/dev/null || echo ""
psql -h "$DB_HOST" -U studio_user -d keybuzz_studio -p 5432 -c "SELECT m.role, u.email FROM memberships m JOIN users u ON m.user_id = u.id;" 2>/dev/null || echo ""

echo ""
echo "=== BOOTSTRAP DEV COMPLETE ==="
