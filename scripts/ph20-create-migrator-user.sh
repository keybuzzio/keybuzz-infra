#!/bin/bash
# PH20-SLA-01A-DB-MIGRATION-02: Create migrator user (ONE-TIME SETUP)
# 
# This script creates a dedicated DB user for migrations with DDL rights.
# Run once with postgres password, then all future migrations are automated.

set -e

echo "🔧 PH20: Creating keybuzz_migrator user for automated migrations..."
echo ""
echo "This script will:"
echo "  1. Create user keybuzz_migrator with random password"
echo "  2. Grant DDL rights on database keybuzz"
echo "  3. Store credentials in Vault KV"
echo ""

# Generate random password
MIGRATOR_PASSWORD=$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-32)

# PostgreSQL connection (requires postgres password)
export PGHOST=10.0.0.10
export PGPORT=5432
export PGDATABASE=keybuzz
export PGUSER=postgres

echo "Please enter the postgres user password:"
read -s PGPASSWORD
export PGPASSWORD

echo ""
echo "Testing connection..."
psql -c "SELECT version();" > /dev/null || {
  echo "❌ Cannot connect with postgres user. Check password."
  exit 1
}

echo "✅ Connected successfully"
echo ""
echo "Creating user keybuzz_migrator..."

# Create user and grant rights
psql << EOF
-- Create user
CREATE USER keybuzz_migrator WITH PASSWORD '$MIGRATOR_PASSWORD';

-- Grant connection
GRANT CONNECT ON DATABASE keybuzz TO keybuzz_migrator;

-- Grant schema usage
GRANT USAGE ON SCHEMA public TO keybuzz_migrator;

-- Grant all on existing tables
GRANT ALL ON ALL TABLES IN SCHEMA public TO keybuzz_migrator;

-- Grant all on existing sequences
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO keybuzz_migrator;

-- Grant create (for new tables/indexes)
GRANT CREATE ON SCHEMA public TO keybuzz_migrator;

-- Grant alter on existing tables (DDL)
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO keybuzz_migrator;

-- Verify
SELECT usename, usesuper FROM pg_user WHERE usename='keybuzz_migrator';
EOF

if [ $? -eq 0 ]; then
  echo "✅ User created successfully"
else
  echo "❌ Failed to create user"
  exit 1
fi

echo ""
echo "Storing credentials in Vault KV..."

export VAULT_ADDR=https://vault.keybuzz.io:8200
export VAULT_TOKEN=$(cat ~/.vault-token)

vault kv put secret/keybuzz/dev/db_migrator \
  username=keybuzz_migrator \
  password="$MIGRATOR_PASSWORD" \
  host=10.0.0.10 \
  port=5432 \
  database=keybuzz

if [ $? -eq 0 ]; then
  echo "✅ Credentials stored in Vault: secret/keybuzz/dev/db_migrator"
else
  echo "❌ Failed to store in Vault"
  echo "Credentials (save manually):"
  echo "  Username: keybuzz_migrator"
  echo "  Password: $MIGRATOR_PASSWORD"
  exit 1
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Create ExternalSecret pointing to secret/keybuzz/dev/db_migrator"
echo "  2. Run migration Job"
echo ""
echo "This was a ONE-TIME setup. Future migrations will use this user automatically."
