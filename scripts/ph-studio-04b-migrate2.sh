#!/usr/bin/env bash
set -euo pipefail

DB_URL="postgresql://kb_studio:zpybnBLbtyFUoTUgll1OvXfSQE2t30h@10.0.0.10:5432/keybuzz_studio"

echo "=== PH-STUDIO-04B — DB Migration ==="

cat > /tmp/migration-04b.sql << 'SQLEOF'
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
DO $$ BEGIN
  CREATE TRIGGER trg_ideas_updated_at BEFORE UPDATE ON ideas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
SQLEOF

echo "--- Creating ConfigMap with migration SQL ---"
kubectl delete configmap migration-04b -n default 2>/dev/null || true
kubectl create configmap migration-04b --from-file=migration.sql=/tmp/migration-04b.sql -n default

echo ""
echo "--- Running migration ---"
kubectl run psql-migrate --rm -i --restart=Never \
  --image=postgres:17-alpine \
  --namespace=default \
  --overrides='{
    "spec": {
      "containers": [{
        "name": "psql-migrate",
        "image": "postgres:17-alpine",
        "command": ["psql", "'"$DB_URL"'", "-f", "/sql/migration.sql"],
        "volumeMounts": [{"name": "sql", "mountPath": "/sql"}]
      }],
      "volumes": [{"name": "sql", "configMap": {"name": "migration-04b"}}]
    }
  }'

echo ""
echo "--- Verifying ---"
kubectl run psql-check --rm -i --restart=Never \
  --image=postgres:17-alpine \
  --namespace=default \
  -- psql "$DB_URL" -c "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name IN ('ideas','knowledge_documents','content_items') ORDER BY table_name;"

kubectl delete configmap migration-04b -n default 2>/dev/null || true

echo ""
echo "=== MIGRATION COMPLETE ==="
