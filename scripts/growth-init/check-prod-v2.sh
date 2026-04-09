#!/bin/bash
set -e

NS=keybuzz-studio-api-prod
SECRET=keybuzz-studio-api-db

DB_HOST=$(kubectl get secret $SECRET -n $NS -o jsonpath='{.data.DB_HOST}' | base64 -d)
DB_USER=$(kubectl get secret $SECRET -n $NS -o jsonpath='{.data.DB_USER}' | base64 -d)
DB_PASSWORD=$(kubectl get secret $SECRET -n $NS -o jsonpath='{.data.DB_PASSWORD}' | base64 -d)
DB_NAME=$(kubectl get secret $SECRET -n $NS -o jsonpath='{.data.DB_NAME}' | base64 -d)

echo "DB: $DB_USER@$DB_HOST/$DB_NAME"

run_sql() {
    kubectl run psql-check-prod --rm -i --restart=Never --image=postgres:17-alpine -n $NS \
        --env="PGPASSWORD=$DB_PASSWORD" \
        -- psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -t -c "$1" 2>/dev/null
}

echo ""
echo "=== B1: TABLES PROD ==="
run_sql "SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name;"

echo ""
echo "=== B2: AI_FEEDBACK COLUMNS (migration 009) ==="
run_sql "SELECT column_name FROM information_schema.columns WHERE table_name='ai_feedback' ORDER BY ordinal_position;"

echo ""
echo "=== B3: LEARNING_ADJUSTMENTS COLUMNS ==="
run_sql "SELECT column_name FROM information_schema.columns WHERE table_name='learning_adjustments' ORDER BY ordinal_position;"

echo ""
echo "=== B4: WORKSPACE_AI_PREFERENCES COLUMNS ==="
run_sql "SELECT column_name FROM information_schema.columns WHERE table_name='workspace_ai_preferences' ORDER BY ordinal_position;"

echo "=== DB CHECK DONE ==="
