#!/usr/bin/env bash
set -euo pipefail

DB_URL="postgresql://kb_studio:zpybnBLbtyFUoTUgll1OvXfSQE2t30h@10.0.0.10:5432/keybuzz_studio"

echo "=== PH-STUDIO-04B — DB Migration ==="

echo "--- Applying migration to keybuzz_studio (DEV) ---"
kubectl run psql-migrate --rm -i --restart=Never \
  --image=postgres:17-alpine \
  --namespace=default \
  -- psql "$DB_URL" -c "
ALTER TABLE knowledge_documents ADD COLUMN IF NOT EXISTS status VARCHAR(50) NOT NULL DEFAULT 'draft';
ALTER TABLE knowledge_documents ADD COLUMN IF NOT EXISTS summary TEXT;
ALTER TABLE knowledge_documents ADD COLUMN IF NOT EXISTS content_structured JSONB DEFAULT '{}';
ALTER TABLE knowledge_documents ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';
ALTER TABLE knowledge_documents ADD COLUMN IF NOT EXISTS source VARCHAR(255);
ALTER TABLE knowledge_documents ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_knowledge_documents_status ON knowledge_documents(workspace_id, status);
ALTER TABLE content_items ADD COLUMN IF NOT EXISTS current_version_id UUID;
CREATE TABLE IF NOT EXISTS ideas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  title VARCHAR(500) NOT NULL,
  description TEXT,
  status VARCHAR(50) NOT NULL DEFAULT 'inbox',
  score INT NOT NULL DEFAULT 0,
  target_channel VARCHAR(100),
  source_type VARCHAR(100),
  source_reference TEXT,
  tags TEXT[] DEFAULT '{}',
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_ideas_workspace ON ideas(workspace_id);
CREATE INDEX IF NOT EXISTS idx_ideas_status ON ideas(workspace_id, status);
CREATE INDEX IF NOT EXISTS idx_ideas_channel ON ideas(workspace_id, target_channel);
DO \$\$ BEGIN
  CREATE TRIGGER trg_ideas_updated_at BEFORE UPDATE ON ideas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EXCEPTION WHEN duplicate_object THEN NULL;
END \$\$;
"

echo ""
echo "--- Verifying tables ---"
kubectl run psql-verify --rm -i --restart=Never \
  --image=postgres:17-alpine \
  --namespace=default \
  -- psql "$DB_URL" -c "\dt ideas" -c "\d knowledge_documents" -c "SELECT column_name FROM information_schema.columns WHERE table_name='ideas' ORDER BY ordinal_position;"

echo ""
echo "=== MIGRATION COMPLETE ==="
