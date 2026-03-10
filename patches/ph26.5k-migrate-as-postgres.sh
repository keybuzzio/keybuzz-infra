#!/bin/bash
# PH26.5K: Migrate as postgres user

echo "=== Adding raw_mime columns ==="

kubectl exec -n db postgresql-0 -- psql -U postgres -d keybuzz -c "
ALTER TABLE messages ADD COLUMN IF NOT EXISTS raw_mime_key TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS raw_mime_sha256 TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS raw_mime_size_bytes BIGINT;
CREATE INDEX IF NOT EXISTS idx_messages_raw_mime_key ON messages(raw_mime_key) WHERE raw_mime_key IS NOT NULL;
"

echo ""
echo "=== Verifying columns ==="

kubectl exec -n db postgresql-0 -- psql -U postgres -d keybuzz -c "
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'messages' 
  AND column_name LIKE 'raw_mime%'
ORDER BY column_name;
"

echo ""
echo "=== Grant permissions to kb_backend ==="

kubectl exec -n db postgresql-0 -- psql -U postgres -d keybuzz -c "
GRANT SELECT, INSERT, UPDATE ON messages TO kb_backend;
"

echo "=== Done ==="
