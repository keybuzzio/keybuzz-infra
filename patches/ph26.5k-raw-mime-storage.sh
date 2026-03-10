#!/bin/bash
# PH26.5K: Raw MIME storage + replay

set -e

echo "=== PH26.5K: Raw MIME Storage ==="

# Step 1: Add columns to messages table
echo "Step 1: Adding raw_mime columns..."
kubectl run psql-k2 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz' -c "
-- Add raw MIME columns if not exists
ALTER TABLE messages ADD COLUMN IF NOT EXISTS raw_mime_key TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS raw_mime_sha256 TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS raw_mime_size_bytes BIGINT;

-- Create index for replay queries
CREATE INDEX IF NOT EXISTS idx_messages_raw_mime_key ON messages(raw_mime_key) WHERE raw_mime_key IS NOT NULL;

SELECT 'Migration complete' as status;
"

echo "Step 2: Verifying columns..."
kubectl run psql-k3 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz' -c "
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'messages' 
  AND column_name LIKE 'raw_mime%'
ORDER BY column_name;
"

echo "=== Done ==="
