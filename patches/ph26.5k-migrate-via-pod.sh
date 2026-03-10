#!/bin/bash
# PH26.5K: Migrate via psql pod - need postgres user

echo "=== Adding raw_mime columns ==="

# Use postgres superuser
kubectl run psql-migrate --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://postgres:oP4bzjM3HZ5L9Rt3e1u29yw6kFGDqx5hfei4lcXso8@10.0.0.10:5432/keybuzz' -c "
ALTER TABLE messages ADD COLUMN IF NOT EXISTS raw_mime_key TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS raw_mime_sha256 TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS raw_mime_size_bytes BIGINT;
CREATE INDEX IF NOT EXISTS idx_messages_raw_mime_key ON messages(raw_mime_key) WHERE raw_mime_key IS NOT NULL;
"
