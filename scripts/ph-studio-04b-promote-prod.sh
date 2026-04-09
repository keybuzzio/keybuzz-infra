#!/usr/bin/env bash
set -euo pipefail

DEV_TAG="v0.3.0-dev"
PROD_TAG="v0.3.0-prod"
REGISTRY="ghcr.io/keybuzzio"
NS_API="keybuzz-studio-api-prod"
NS_FE="keybuzz-studio-prod"
PROD_DB_URL="postgresql://kb_studio_prod:OxNXCMwoNPDHCIL7ysMBV53bdhlsOYUz@10.0.0.10:5432/keybuzz_studio_prod"
BOOTSTRAP_SECRET="BOOTSTRAP_SECRET_REDACTED"
API="https://studio-api.keybuzz.io"

echo "=== PH-STUDIO-04B — PROD Promotion ==="

# --- 1. Apply migration to PROD DB ---
echo "--- Step 1: Apply migration to PROD DB ---"
cat > /tmp/migration-04b-prod.sql << 'SQLEOF'
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

kubectl delete configmap migration-04b-prod -n default 2>/dev/null || true
kubectl create configmap migration-04b-prod --from-file=migration.sql=/tmp/migration-04b-prod.sql -n default

kubectl run psql-prod-migrate --rm -i --restart=Never \
  --image=postgres:17-alpine \
  --namespace=default \
  --overrides='{
    "spec": {
      "containers": [{
        "name": "psql-prod-migrate",
        "image": "postgres:17-alpine",
        "command": ["psql", "'"$PROD_DB_URL"'", "-f", "/sql/migration.sql"],
        "volumeMounts": [{"name": "sql", "mountPath": "/sql"}]
      }],
      "volumes": [{"name": "sql", "configMap": {"name": "migration-04b-prod"}}]
    }
  }'

kubectl delete configmap migration-04b-prod -n default 2>/dev/null || true
echo "PROD migration done"

# --- 2. Tag and push PROD images ---
echo ""
echo "--- Step 2: Tag + push PROD images ---"
docker tag "$REGISTRY/keybuzz-studio-api:$DEV_TAG" "$REGISTRY/keybuzz-studio-api:$PROD_TAG"
docker tag "$REGISTRY/keybuzz-studio:$DEV_TAG" "$REGISTRY/keybuzz-studio:$PROD_TAG"
docker push "$REGISTRY/keybuzz-studio-api:$PROD_TAG" 2>&1 | tail -3
docker push "$REGISTRY/keybuzz-studio:$PROD_TAG" 2>&1 | tail -3
echo "PROD images pushed"

# --- 3. Update PROD deployments ---
echo ""
echo "--- Step 3: Update PROD deployments ---"
kubectl set image deployment/keybuzz-studio-api keybuzz-studio-api="$REGISTRY/keybuzz-studio-api:$PROD_TAG" -n "$NS_API"
kubectl set image deployment/keybuzz-studio keybuzz-studio="$REGISTRY/keybuzz-studio:$PROD_TAG" -n "$NS_FE"

echo ""
echo "--- Step 4: Waiting for rollouts ---"
kubectl rollout status deployment/keybuzz-studio-api -n "$NS_API" --timeout=120s
kubectl rollout status deployment/keybuzz-studio -n "$NS_FE" --timeout=120s

echo ""
echo "--- Pods ---"
kubectl get pods -n "$NS_API" --no-headers
kubectl get pods -n "$NS_FE" --no-headers

sleep 5

# --- 4. Bootstrap owner PROD ---
echo ""
echo "--- Step 5: Bootstrap owner PROD ---"
SETUP_STATUS=$(curl -s "$API/api/v1/auth/setup/status")
echo "Setup status: $SETUP_STATUS"
NEEDED=$(echo "$SETUP_STATUS" | python3 -c "import sys,json; print(json.load(sys.stdin).get('needed',False))" 2>/dev/null || echo "")

if [ "$NEEDED" = "True" ]; then
  cat > /tmp/bootstrap-prod.json << 'EOF'
{
  "email": "ludovic@keybuzz.pro",
  "displayName": "Ludovic GONTHIER",
  "workspaceName": "KeyBuzz",
  "workspaceSlug": "keybuzz"
}
EOF

  python3 -c "
import json
with open('/tmp/bootstrap-prod.json') as f:
    d = json.load(f)
d['bootstrapSecret'] = '$BOOTSTRAP_SECRET'
with open('/tmp/bootstrap-prod.json','w') as f:
    json.dump(d, f)
"

  BOOT_RESP=$(curl -s -w "\n%{http_code}" -X POST "$API/api/v1/auth/setup" \
    -H "Content-Type: application/json" \
    -d @/tmp/bootstrap-prod.json)
  HTTP_CODE=$(echo "$BOOT_RESP" | tail -1)
  BODY=$(echo "$BOOT_RESP" | head -n -1)
  echo "Bootstrap HTTP: $HTTP_CODE"
  echo "Bootstrap response: $BODY"
  rm -f /tmp/bootstrap-prod.json
else
  echo "Bootstrap not needed (owner already exists)"
fi

# --- 5. Verify PROD ---
echo ""
echo "--- Step 6: PROD verification ---"
curl -s "$API/health"
echo ""
curl -s "$API/api/v1/auth/setup/status"
echo ""
curl -s -o /dev/null -w "Frontend login: HTTP %{http_code}\n" https://studio.keybuzz.io/login

echo ""
echo "PROD API logs:"
kubectl logs deployment/keybuzz-studio-api -n "$NS_API" --tail=10

echo ""
echo "=== PROD PROMOTION COMPLETE ==="
