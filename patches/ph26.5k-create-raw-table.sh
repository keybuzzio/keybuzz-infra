#!/bin/bash
# PH26.5K: Create message_raw_mime table

echo "=== Creating message_raw_mime table ==="

kubectl run psql-k7 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://keybuzz_api_dev:IfVXI5kTGZ87Rh4LH9kVY3sGgDq3jNwR@10.0.0.10:5432/keybuzz' -c "
CREATE TABLE IF NOT EXISTS message_raw_mime (
  id TEXT PRIMARY KEY DEFAULT 'mrm_' || substr(md5(random()::text), 1, 24),
  message_id TEXT NOT NULL,
  tenant_id TEXT NOT NULL,
  minio_key TEXT NOT NULL,
  sha256 TEXT NOT NULL,
  size_bytes BIGINT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(message_id)
);

CREATE INDEX IF NOT EXISTS idx_message_raw_mime_tenant ON message_raw_mime(tenant_id);
CREATE INDEX IF NOT EXISTS idx_message_raw_mime_sha256 ON message_raw_mime(sha256);
"

echo ""
echo "=== Verifying table ==="

kubectl run psql-k8 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://keybuzz_api_dev:IfVXI5kTGZ87Rh4LH9kVY3sGgDq3jNwR@10.0.0.10:5432/keybuzz' -c "
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'message_raw_mime'
ORDER BY ordinal_position;
"

echo "=== Done ==="
