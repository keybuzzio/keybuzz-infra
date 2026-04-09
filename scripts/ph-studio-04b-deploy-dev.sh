#!/usr/bin/env bash
set -euo pipefail

TAG="v0.3.0-dev"
REGISTRY="ghcr.io/keybuzzio"
API_DIR="/opt/keybuzz/keybuzz-studio-api"
FE_DIR="/opt/keybuzz/keybuzz-studio"
NS_API="keybuzz-studio-api-dev"
NS_FE="keybuzz-studio-dev"

echo "=== PH-STUDIO-04B — Deploy DEV ($TAG) ==="

# --- 1. Apply DB migration ---
echo ""
echo "--- Step 1: Apply DB migration ---"
DB_HOST=$(kubectl get secret keybuzz-studio-api-db -n $NS_API -o jsonpath='{.data.host}' | base64 -d 2>/dev/null || echo "10.0.0.150")
DB_USER=$(kubectl get secret keybuzz-studio-api-db -n $NS_API -o jsonpath='{.data.username}' | base64 -d 2>/dev/null || echo "studio_user")
DB_PASS=$(kubectl get secret keybuzz-studio-api-db -n $NS_API -o jsonpath='{.data.password}' | base64 -d 2>/dev/null || echo "")
DB_NAME="keybuzz_studio"

export PGPASSWORD="$DB_PASS"
if psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -p 5432 -f "$API_DIR/src/db/migrations/002-knowledge-ideas-content.sql" 2>&1; then
  echo "Migration applied OK"
else
  echo "Migration via psql failed, trying via kubectl exec..."
  PATRONI_POD=$(kubectl get pod -n patroni -l app=patroni -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "patroni-0")
  kubectl exec -n patroni "$PATRONI_POD" -- psql -U "$DB_USER" -d "$DB_NAME" -c "
    ALTER TABLE knowledge_documents ADD COLUMN IF NOT EXISTS status VARCHAR(50) NOT NULL DEFAULT 'draft';
    ALTER TABLE knowledge_documents ADD COLUMN IF NOT EXISTS summary TEXT;
    ALTER TABLE knowledge_documents ADD COLUMN IF NOT EXISTS content_structured JSONB DEFAULT '{}';
    ALTER TABLE knowledge_documents ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';
    ALTER TABLE knowledge_documents ADD COLUMN IF NOT EXISTS source VARCHAR(255);
    ALTER TABLE knowledge_documents ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id) ON DELETE SET NULL;
    CREATE INDEX IF NOT EXISTS idx_knowledge_documents_status ON knowledge_documents(workspace_id, status);
    ALTER TABLE content_items ADD COLUMN IF NOT EXISTS current_version_id UUID;
    CREATE TABLE IF NOT EXISTS ideas (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
      title VARCHAR(500) NOT NULL, description TEXT, status VARCHAR(50) NOT NULL DEFAULT 'inbox',
      score INT NOT NULL DEFAULT 0, target_channel VARCHAR(100), source_type VARCHAR(100),
      source_reference TEXT, tags TEXT[] DEFAULT '{}', created_by UUID REFERENCES users(id) ON DELETE SET NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
    CREATE INDEX IF NOT EXISTS idx_ideas_workspace ON ideas(workspace_id);
    CREATE INDEX IF NOT EXISTS idx_ideas_status ON ideas(workspace_id, status);
    CREATE INDEX IF NOT EXISTS idx_ideas_channel ON ideas(workspace_id, target_channel);
  " 2>&1 || echo "kubectl exec migration also failed"
fi

# --- 2. Build API image ---
echo ""
echo "--- Step 2: Build API image ---"
cd "$API_DIR"
docker build -t "$REGISTRY/keybuzz-studio-api:$TAG" . 2>&1 | tail -5
echo "API image built"

# --- 3. Build Frontend image ---
echo ""
echo "--- Step 3: Build Frontend image ---"
cd "$FE_DIR"
docker build \
  --build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=development \
  -t "$REGISTRY/keybuzz-studio:$TAG" . 2>&1 | tail -5
echo "Frontend image built"

# --- 4. Push images ---
echo ""
echo "--- Step 4: Push images ---"
docker push "$REGISTRY/keybuzz-studio-api:$TAG" 2>&1 | tail -3
docker push "$REGISTRY/keybuzz-studio:$TAG" 2>&1 | tail -3
echo "Images pushed"

# --- 5. Update K8s deployments ---
echo ""
echo "--- Step 5: Update K8s deployments ---"
kubectl set image deployment/keybuzz-studio-api keybuzz-studio-api="$REGISTRY/keybuzz-studio-api:$TAG" -n "$NS_API"
kubectl set image deployment/keybuzz-studio keybuzz-studio="$REGISTRY/keybuzz-studio:$TAG" -n "$NS_FE"

# --- 6. Wait for rollouts ---
echo ""
echo "--- Step 6: Waiting for rollouts ---"
kubectl rollout status deployment/keybuzz-studio-api -n "$NS_API" --timeout=120s
kubectl rollout status deployment/keybuzz-studio -n "$NS_FE" --timeout=120s

# --- 7. Verify ---
echo ""
echo "--- Step 7: Verification ---"
echo "Pods:"
kubectl get pods -n "$NS_API" --no-headers
kubectl get pods -n "$NS_FE" --no-headers

sleep 5

echo ""
echo "Health checks:"
curl -s https://studio-api-dev.keybuzz.io/health
echo ""
curl -s https://studio-api-dev.keybuzz.io/api/v1/auth/setup/status
echo ""
curl -s -o /dev/null -w "Frontend: HTTP %{http_code}\n" https://studio-dev.keybuzz.io/login

echo ""
echo "API logs (last 10):"
kubectl logs deployment/keybuzz-studio-api -n "$NS_API" --tail=10

echo ""
echo "=== DEV DEPLOY COMPLETE ($TAG) ==="
