#!/bin/bash
set -e

NS=keybuzz-studio-api-prod
DB_URL=$(kubectl get secret keybuzz-studio-api-db -n $NS -o jsonpath='{.data.DATABASE_URL}' | base64 -d)

run_sql() {
    kubectl run psql-prod-$RANDOM --rm -i --restart=Never --image=postgres:17-alpine -n $NS \
        -- psql "$DB_URL" -t -c "$1" 2>/dev/null | grep -v "^$" | head -40
}

echo "=== B1: ALL TABLES ==="
run_sql "SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name;"

echo ""
echo "=== B2: AI_FEEDBACK COLUMNS (migration 009 check) ==="
run_sql "SELECT column_name FROM information_schema.columns WHERE table_name='ai_feedback' ORDER BY ordinal_position;"

echo ""
echo "=== B3: LEARNING_ADJUSTMENTS EXISTS ==="
run_sql "SELECT column_name FROM information_schema.columns WHERE table_name='learning_adjustments' ORDER BY ordinal_position;"

echo ""
echo "=== B4: WORKSPACE_AI_PREFERENCES EXISTS ==="
run_sql "SELECT column_name FROM information_schema.columns WHERE table_name='workspace_ai_preferences' ORDER BY ordinal_position;"

echo ""
echo "=== C1: CLIENT PROFILES ==="
run_sql "SELECT id, business_name, niche FROM client_profiles LIMIT 5;"

echo ""
echo "=== C2: CLIENT SOURCES COUNT ==="
run_sql "SELECT COUNT(*) as source_count FROM client_sources;"

echo ""
echo "=== C3: CLIENT ANALYSIS ==="
run_sql "SELECT id, profile_id, provider FROM client_analysis LIMIT 5;"

echo ""
echo "=== C4: CLIENT STRATEGIES ==="
run_sql "SELECT id, analysis_id FROM client_strategies LIMIT 5;"

echo ""
echo "=== C5: IDEAS COUNT ==="
run_sql "SELECT COUNT(*) as idea_count, COUNT(CASE WHEN status='approved' THEN 1 END) as approved FROM ideas;"

echo ""
echo "=== C6: CONTENT ITEMS COUNT ==="
run_sql "SELECT COUNT(*) as content_count FROM content_items;"

echo ""
echo "=== C7: AI GENERATIONS COUNT ==="
run_sql "SELECT COUNT(*) as gen_count FROM ai_generations;"

echo ""
echo "=== C8: AI FEEDBACK COUNT ==="
run_sql "SELECT COUNT(*) as fb_count, COUNT(CASE WHEN rating='up' THEN 1 END) as up_count, COUNT(CASE WHEN rating='down' THEN 1 END) as down_count FROM ai_feedback;"

echo ""
echo "=== C9: LEARNING ADJUSTMENTS ==="
run_sql "SELECT COUNT(*) as adj_count FROM learning_adjustments;"

echo "=== DB CHECK COMPLETE ==="
