#!/bin/bash
set -euo pipefail

# PH-STUDIO-02 — Create Studio database + user + schema
# Run on bastion: bash /opt/keybuzz/keybuzz-infra/scripts/setup-studio-db.sh

DB_HOST="10.0.0.10"
DB_NAME="keybuzz_studio"
DB_USER="kb_studio"
DB_PASS="$(openssl rand -base64 32 | tr -d '=/+' | head -c 40)"

echo "=== PH-STUDIO-02 — Database Setup ==="
echo "Host: $DB_HOST"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo ""

export PGPASSWORD="${ADMIN_PG_PASS:-}"
if [ -z "$PGPASSWORD" ]; then
  echo "ERROR: ADMIN_PG_PASS not set"
  echo "Usage: ADMIN_PG_PASS=xxx bash $0"
  exit 1
fi

echo "--- Creating role $DB_USER ---"
psql -h "$DB_HOST" -U postgres -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS' NOSUPERUSER NOCREATEDB NOCREATEROLE;" 2>&1 || echo "Role may already exist"

echo "--- Creating database $DB_NAME ---"
psql -h "$DB_HOST" -U postgres -c "CREATE DATABASE $DB_NAME OWNER $DB_USER ENCODING 'UTF8';" 2>&1

echo "--- Installing extensions ---"
psql -h "$DB_HOST" -U postgres -d "$DB_NAME" -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"; CREATE EXTENSION IF NOT EXISTS pgcrypto;' 2>&1

echo "--- Granting privileges ---"
psql -h "$DB_HOST" -U postgres -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER; GRANT ALL ON SCHEMA public TO $DB_USER;" 2>&1

echo "--- Applying schema ---"
SCHEMA_FILE="/opt/keybuzz/keybuzz-client/keybuzz-studio-api/src/db/schema.sql"
if [ -f "$SCHEMA_FILE" ]; then
  PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f "$SCHEMA_FILE" 2>&1
  echo "PASS: Schema applied"
else
  echo "WARN: Schema file not found at $SCHEMA_FILE — apply manually after git pull"
fi

DATABASE_URL="postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:5432/${DB_NAME}"

echo ""
echo "=== DATABASE SETUP COMPLETE ==="
echo "DATABASE_URL=$DATABASE_URL"
echo ""
echo "Create K8s secret:"
echo "  kubectl create namespace keybuzz-studio-api-dev --dry-run=client -o yaml | kubectl apply -f -"
echo "  kubectl create secret generic keybuzz-studio-api-db --namespace=keybuzz-studio-api-dev --from-literal=DATABASE_URL='$DATABASE_URL'"
