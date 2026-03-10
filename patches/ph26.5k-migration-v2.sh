#!/bin/bash
# PH26.5K: Raw MIME storage migration with correct user

set -e

echo "=== PH26.5K: Raw MIME Storage Migration ==="

# Use keybuzz_api_dev user (owner of messages table)
DB_URL='postgresql://keybuzz_api_dev:IfVXI5kTGZ87Rh4LH9kVY3sGgDq3jNwR@10.0.0.10:5432/keybuzz'

echo "Step 1: Adding raw_mime columns..."
kubectl run psql-k5 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql "$DB_URL" -c "
-- Add raw MIME columns if not exists
ALTER TABLE messages ADD COLUMN IF NOT EXISTS raw_mime_key TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS raw_mime_sha256 TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS raw_mime_size_bytes BIGINT;

-- Create index for replay queries
CREATE INDEX IF NOT EXISTS idx_messages_raw_mime_key ON messages(raw_mime_key) WHERE raw_mime_key IS NOT NULL;

SELECT 'Migration complete' as status;
"

echo ""
echo "Step 2: Verifying columns..."
kubectl run psql-k6 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql "$DB_URL" -c "
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'messages' 
  AND column_name LIKE 'raw_mime%'
ORDER BY column_name;
"

echo ""
echo "=== Migration Done ==="
