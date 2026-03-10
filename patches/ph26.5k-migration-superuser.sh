#!/bin/bash
# PH26.5K: Raw MIME storage migration with superuser

set -e

echo "=== PH26.5K: Raw MIME Storage Migration (superuser) ==="

POSTGRES_URL='postgresql://postgres:CHANGE_ME_LATER_VIA_VAULT@10.0.0.10:5432/keybuzz'

echo "Step 1: Adding raw_mime columns..."
kubectl run psql-k8 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql "$POSTGRES_URL" -c "
-- PH26.5K: Add raw MIME columns
ALTER TABLE messages ADD COLUMN IF NOT EXISTS raw_mime_key TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS raw_mime_sha256 TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS raw_mime_size_bytes BIGINT;

-- Create index for replay queries (messages with raw_mime stored)
CREATE INDEX IF NOT EXISTS idx_messages_raw_mime_key ON messages(raw_mime_key) WHERE raw_mime_key IS NOT NULL;

-- Grant permissions to app users
GRANT SELECT, UPDATE ON messages TO keybuzz_api_dev;
GRANT SELECT, UPDATE ON messages TO kb_backend;

SELECT 'Migration complete' as status;
"

echo ""
echo "Step 2: Verifying columns..."
kubectl run psql-k9 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql "$POSTGRES_URL" -c "
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'messages' 
  AND column_name LIKE 'raw_mime%'
ORDER BY column_name;
"

echo ""
echo "=== Migration Done ==="
