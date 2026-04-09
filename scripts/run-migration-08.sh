#!/bin/bash
set -e

NAMESPACE=$1
CONFIGMAP_NAME=$2
POD_NAME=$3

echo "Running migration in namespace: $NAMESPACE"

kubectl delete pod "$POD_NAME" --namespace default 2>/dev/null || true

kubectl run "$POD_NAME" --rm -it --restart=Never \
  --image=postgres:17-alpine \
  --namespace=default \
  --overrides="{
    \"spec\": {
      \"containers\": [{
        \"name\": \"$POD_NAME\",
        \"image\": \"postgres:17-alpine\",
        \"command\": [\"sh\", \"-c\", \"psql \\\"\$DB_URL\\\" -f /sql/migration.sql\"],
        \"env\": [{\"name\": \"DB_URL\", \"valueFrom\": {\"secretKeyRef\": {\"name\": \"keybuzz-studio-api-db\", \"key\": \"DATABASE_URL\"}}}],
        \"volumeMounts\": [{\"name\": \"sql\", \"mountPath\": \"/sql\"}]
      }],
      \"volumes\": [{\"name\": \"sql\", \"configMap\": {\"name\": \"$CONFIGMAP_NAME\"}}]
    }
  }" 2>&1 || echo "Pod exited"

echo "Migration done"
