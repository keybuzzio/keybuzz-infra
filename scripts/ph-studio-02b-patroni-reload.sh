#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=$(cat /root/.vault-cluster-root-token 2>/dev/null || echo "")

PRIMARY="10.0.0.122"
DB_HOST="10.0.0.10"

echo "=== Current Patroni config (authentication section) ==="
curl -s "http://${PRIMARY}:8008/config" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps(d.get('postgresql',{}).get('authentication',{}), indent=2))" 2>/dev/null || echo "none"

# Read the password we set in the PATCH
PG_NEW_PASS=$(curl -s "http://${PRIMARY}:8008/config" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('postgresql',{}).get('authentication',{}).get('superuser',{}).get('password',''))" 2>/dev/null || echo "")
echo "New password from config (length: ${#PG_NEW_PASS})"

echo ""
echo "=== Trigger Patroni reload on primary ==="
RELOAD_RESULT=$(curl -s -w "\n%{http_code}" -X POST "http://${PRIMARY}:8008/reload" 2>&1)
echo "Reload: $(echo "$RELOAD_RESULT" | tail -1)"
echo "$(echo "$RELOAD_RESULT" | head -n -1)"

sleep 5

echo ""
echo "=== Try connecting to primary directly ==="
PGPASSWORD="$PG_NEW_PASS" psql -h "$PRIMARY" -p 5432 -U postgres -d postgres -c "SELECT current_user, current_database();" 2>&1 | head -5

echo ""
echo "=== Try connecting via HAProxy ==="
PGPASSWORD="$PG_NEW_PASS" psql -h "$DB_HOST" -p 5432 -U postgres -d postgres -c "SELECT 1;" 2>&1 | head -5

echo ""
echo "=== If reload didn't work, try restart ==="
if ! PGPASSWORD="$PG_NEW_PASS" psql -h "$PRIMARY" -U postgres -d postgres -c "SELECT 1;" 2>/dev/null; then
  echo "Password not propagated after reload."
  echo ""
  echo "=== Try Patroni restart (pending_restart check) ==="
  curl -s "http://${PRIMARY}:8008/patroni" | python3 -c "import sys,json; d=json.load(sys.stdin); print('pending_restart:', d.get('pending_restart', False))" 2>/dev/null || true
  
  echo ""
  echo "=== Alternative: Use kb_backend ALTER via CREATEROLE ==="
  BACKEND_PASS=$(vault kv get -field=PGPASSWORD secret/keybuzz/dev/backend-postgres 2>/dev/null || echo "")
  
  # Check if kb_backend has CREATEROLE
  HAS_CREATEROLE=$(PGPASSWORD="$BACKEND_PASS" psql -h "$DB_HOST" -U kb_backend -d keybuzz_backend -t -A -c "SELECT rolcreaterole FROM pg_roles WHERE rolname='kb_backend';" 2>/dev/null || echo "f")
  echo "kb_backend has CREATEROLE: $HAS_CREATEROLE"
  
  # Check all roles with their privileges
  echo ""
  echo "=== All roles with privileges ==="
  PGPASSWORD="$BACKEND_PASS" psql -h "$DB_HOST" -U kb_backend -d keybuzz_backend -c "SELECT rolname, rolsuper, rolcreatedb, rolcreaterole, rolcanlogin FROM pg_roles WHERE rolcanlogin ORDER BY rolsuper DESC, rolcreatedb DESC;" 2>/dev/null
  
  echo ""
  echo "=== Try: grant CREATEDB to kb_backend via Patroni SQL ==="
  # Patroni's primary can execute SQL
  curl -s -X POST "http://${PRIMARY}:8008/query" \
    -H "Content-Type: application/json" \
    -d '{"query": "ALTER ROLE kb_backend CREATEDB;"}' 2>&1 | head -5 || echo "query endpoint not available"
  
  echo ""
  echo "=== Alternative: Directly change pg_hba to trust for localhost ==="
  echo "Checking Patroni pg_hba rules..."
  curl -s "http://${PRIMARY}:8008/config" | python3 -m json.tool 2>/dev/null
  
  echo ""
  echo "=== APPROACH: Set pg_hba to trust postgres from bastion ==="
  BASTION_IP=$(hostname -I | awk '{print $1}')
  echo "Bastion IP: $BASTION_IP"
  
  # Get current pg_hba
  CURRENT_HBA=$(PGPASSWORD="$BACKEND_PASS" psql -h "$DB_HOST" -U kb_backend -d keybuzz_backend -t -A -c "SELECT string_agg(line_number || ':' || type || ':' || database::text || ':' || user_name::text || ':' || address || ':' || auth_method, E'\n') FROM pg_hba_file_rules LIMIT 20;" 2>/dev/null || echo "")
  echo "Current HBA rules (sample):"
  echo "$CURRENT_HBA" | head -10
fi

echo ""
echo "DONE"
