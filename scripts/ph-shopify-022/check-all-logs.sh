#!/bin/bash
POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}')
echo "=== Last 80 API lines ==="
kubectl logs -n keybuzz-api-dev "$POD" --tail=80 2>/dev/null | grep -v 'level":30.*incoming request' | grep -v 'level":30.*res.*statusCode'
