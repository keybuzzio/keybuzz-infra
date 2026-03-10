#!/bin/bash
# PH26.5L: Create ai_context_attachments table

echo "=== PH26.5L: Creating ai_context_attachments table ==="

kubectl run psql-l1 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://postgres:CHANGE_ME_LATER_VIA_VAULT@10.0.0.10:5432/keybuzz' -c "
-- PH26.5L: AI Context Attachments table
CREATE TABLE IF NOT EXISTS ai_context_attachments (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  conversation_id TEXT NOT NULL,
  ai_action_log_id TEXT,
  minio_key TEXT NOT NULL,
  filename TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  size_bytes BIGINT NOT NULL,
  sha256 TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by TEXT
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_ai_context_att_tenant ON ai_context_attachments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_ai_context_att_conv ON ai_context_attachments(conversation_id);
CREATE INDEX IF NOT EXISTS idx_ai_context_att_action ON ai_context_attachments(ai_action_log_id) WHERE ai_action_log_id IS NOT NULL;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ai_context_attachments TO keybuzz_api_dev;
GRANT SELECT, INSERT, UPDATE, DELETE ON ai_context_attachments TO kb_backend;

SELECT 'Table ai_context_attachments created' as status;
"

echo ""
echo "=== Verifying table ==="
kubectl run psql-l2 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://postgres:CHANGE_ME_LATER_VIA_VAULT@10.0.0.10:5432/keybuzz' -c "
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'ai_context_attachments' ORDER BY ordinal_position;
"

echo "=== Done ==="
