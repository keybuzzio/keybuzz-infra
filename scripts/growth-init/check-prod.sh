#!/bin/bash
set -e

NS_API=keybuzz-studio-api-prod

echo "=== B1: TABLES PROD ==="
kubectl exec -n $NS_API deploy/keybuzz-studio-api -- sh -c 'PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -t -c "SELECT table_name FROM information_schema.tables WHERE table_schema = '\''public'\'' ORDER BY table_name;"'

echo ""
echo "=== B2: MIGRATION 009 CHECK ==="
kubectl exec -n $NS_API deploy/keybuzz-studio-api -- sh -c 'PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -t -c "SELECT column_name FROM information_schema.columns WHERE table_name = '\''ai_feedback'\'' ORDER BY ordinal_position;"'

echo ""
echo "=== B3: LEARNING TABLES ==="
kubectl exec -n $NS_API deploy/keybuzz-studio-api -- sh -c 'PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -t -c "SELECT column_name FROM information_schema.columns WHERE table_name = '\''learning_adjustments'\'' ORDER BY ordinal_position;"'

echo ""
echo "=== B4: WORKSPACE AI PREFS ==="
kubectl exec -n $NS_API deploy/keybuzz-studio-api -- sh -c 'PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -t -c "SELECT column_name FROM information_schema.columns WHERE table_name = '\''workspace_ai_preferences'\'' ORDER BY ordinal_position;"'

echo "=== DONE ==="
