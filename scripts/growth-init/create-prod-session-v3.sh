#!/bin/bash
set -e

NS=keybuzz-studio-api-prod
DB_URL=$(kubectl get secret keybuzz-studio-api-db -n $NS -o jsonpath='{.data.DATABASE_URL}' | base64 -d)

TOKEN_RAW=$(openssl rand -hex 32)
TOKEN_HASH=$(echo -n "$TOKEN_RAW" | sha256sum | awk '{print $1}')

cat > /tmp/create-session.sql << 'ENDSQL'
INSERT INTO sessions (token_hash, user_id, workspace_id, expires_at)
SELECT '__HASH__', u.id, m.workspace_id, NOW() + INTERVAL '7 days'
FROM users u
JOIN memberships m ON m.user_id = u.id
WHERE u.email = 'ludovic@keybuzz.pro'
LIMIT 1
RETURNING id, user_id, workspace_id;
ENDSQL

sed -i "s/__HASH__/$TOKEN_HASH/" /tmp/create-session.sql

echo "Creating session..."
cat /tmp/create-session.sql

kubectl create configmap session-sql -n $NS --from-file=session.sql=/tmp/create-session.sql --dry-run=client -o yaml | kubectl apply -f -

kubectl run psql-session --rm -i --restart=Never --image=postgres:17-alpine -n $NS \
    -- psql "$DB_URL" -f - < /tmp/create-session.sql 2>&1 | grep -v "^pod\|^If you"

echo ""
echo "SESSION_TOKEN=$TOKEN_RAW"

kubectl delete configmap session-sql -n $NS 2>/dev/null || true
