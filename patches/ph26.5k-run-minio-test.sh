#!/bin/bash
# PH26.5K: Run MinIO test in pod

POD=$(kubectl get pod -n keybuzz-backend-dev -l app=keybuzz-backend -o jsonpath='{.items[0].metadata.name}')
echo "Using pod: $POD"

kubectl cp /tmp/ph26.5k-test-minio.js keybuzz-backend-dev/$POD:/tmp/test-minio.js
kubectl exec -n keybuzz-backend-dev $POD -- node /tmp/test-minio.js
