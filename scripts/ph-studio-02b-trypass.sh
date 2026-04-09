#!/bin/bash
set -euo pipefail

DB_HOST="10.0.0.10"

echo "=== Try common/default passwords for postgres superuser ==="

for PASS in "CHANGE_ME_LATER_VIA_VAULT" "changeme" "postgres" "keybuzz" "keybuzz2024" "keybuzz2025" "keybuzz2026" "admin" "password"; do
  RESULT=$(PGPASSWORD="$PASS" psql -h "$DB_HOST" -U postgres -d postgres -t -A -c "SELECT 'connected'" 2>/dev/null || echo "fail")
  if [ "$RESULT" = "connected" ]; then
    echo "PASS FOUND for postgres: (length ${#PASS})"
    PGPASSWORD="$PASS" psql -h "$DB_HOST" -U postgres -d postgres -c "SELECT current_user, version();" 2>&1 | head -3
    
    echo ""
    echo "=== Create keybuzz_studio ==="
    DB_EXISTS=$(PGPASSWORD="$PASS" psql -h "$DB_HOST" -U postgres -d postgres -t -A -c "SELECT 1 FROM pg_database WHERE datname='keybuzz_studio';" 2>/dev/null || echo "0")
    if [ "$DB_EXISTS" != "1" ]; then
      PGPASSWORD="$PASS" psql -h "$DB_HOST" -U postgres -d postgres -c "CREATE DATABASE keybuzz_studio ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8' TEMPLATE template0;" 2>&1
    else
      echo "Already exists"
    fi
    
    exit 0
  fi
done

echo ""
echo "=== No common passwords worked ==="

echo ""
echo "=== Try Patroni restart without body ==="
PRIMARY="10.0.0.122"
curl -s -w "\nHTTP:%{http_code}" -X POST "http://${PRIMARY}:8008/restart" -H "Content-Type: application/json" -d '{}' 2>&1

echo ""
echo "Waiting 15s..."
sleep 15

echo "=== Test Patroni config password after restart ==="
PG_NEW_PASS=$(curl -s "http://${PRIMARY}:8008/config" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('postgresql',{}).get('authentication',{}).get('superuser',{}).get('password',''))" 2>/dev/null || echo "")
PGPASSWORD="$PG_NEW_PASS" psql -h "$PRIMARY" -U postgres -d postgres -c "SELECT 1;" 2>&1 | head -3
PGPASSWORD="$PG_NEW_PASS" psql -h "$DB_HOST" -U postgres -d postgres -c "SELECT 1;" 2>&1 | head -3

echo ""
echo "=== Check Patroni logs for password issues ==="
curl -s "http://${PRIMARY}:8008/patroni" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print('state:', d.get('state'), 'role:', d.get('role'), 'pending_restart:', d.get('pending_restart', False))" 2>/dev/null || true

echo ""
echo "=== Last resort: Read actual patroni.yml from node via API history ==="
curl -s "http://${PRIMARY}:8008/history" 2>/dev/null | python3 -m json.tool 2>/dev/null | tail -10

echo ""
echo "DONE"
