#!/bin/bash
set -e

NS=keybuzz-studio-api-prod
DB_URL=$(kubectl get secret keybuzz-studio-api-db -n $NS -o jsonpath='{.data.DATABASE_URL}' | base64 -d)

TOKEN_RAW=$(openssl rand -hex 32)
TOKEN_HASH=$(echo -n "$TOKEN_RAW" | sha256sum | awk '{print $1}')

echo "Creating session..."
echo "Token hash: ${TOKEN_HASH:0:16}..."

SQL="DO \$\$
DECLARE
  v_user_id UUID;
  v_ws_id UUID;
BEGIN
  SELECT id INTO v_user_id FROM users WHERE email='ludovic@keybuzz.pro' LIMIT 1;
  SELECT workspace_id INTO v_ws_id FROM memberships WHERE user_id=v_user_id LIMIT 1;
  INSERT INTO sessions (token_hash, user_id, workspace_id, expires_at)
  VALUES ('$TOKEN_HASH', v_user_id, v_ws_id, NOW() + INTERVAL '7 days');
  RAISE NOTICE 'user=%, workspace=%', v_user_id, v_ws_id;
END \$\$;"

kubectl run psql-session --rm -i --restart=Never --image=postgres:17-alpine -n $NS \
    -- psql "$DB_URL" -c "$SQL" 2>&1 | grep -v "^pod\|^If you"

echo "SESSION_TOKEN=$TOKEN_RAW"
