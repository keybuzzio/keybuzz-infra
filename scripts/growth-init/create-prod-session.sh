#!/bin/bash
set -e

NS=keybuzz-studio-api-prod
DB_URL=$(kubectl get secret keybuzz-studio-api-db -n $NS -o jsonpath='{.data.DATABASE_URL}' | base64 -d)

TOKEN_RAW=$(openssl rand -hex 32)
TOKEN_HASH=$(echo -n "$TOKEN_RAW" | sha256sum | awk '{print $1}')

USER_ID=$(kubectl run psql-sess-1-$RANDOM --rm -i --restart=Never --image=postgres:17-alpine -n $NS \
    -- psql "$DB_URL" -t -c "SELECT id FROM users WHERE email='ludovic@keybuzz.pro' LIMIT 1;" 2>/dev/null | tr -d ' \n')

WORKSPACE_ID=$(kubectl run psql-sess-2-$RANDOM --rm -i --restart=Never --image=postgres:17-alpine -n $NS \
    -- psql "$DB_URL" -t -c "SELECT workspace_id FROM memberships WHERE user_id='$USER_ID' LIMIT 1;" 2>/dev/null | tr -d ' \n')

echo "User: $USER_ID"
echo "Workspace: $WORKSPACE_ID"

kubectl run psql-sess-3-$RANDOM --rm -i --restart=Never --image=postgres:17-alpine -n $NS \
    -- psql "$DB_URL" -t -c "INSERT INTO sessions (token_hash, user_id, workspace_id, expires_at) VALUES ('$TOKEN_HASH', '$USER_ID', '$WORKSPACE_ID', NOW() + INTERVAL '7 days') RETURNING id;" 2>/dev/null

echo "TOKEN=$TOKEN_RAW"
