#!/bin/bash
# PH26.5K: Run simulation

POD=$(kubectl get pod -n keybuzz-backend-dev -l app=keybuzz-backend -o jsonpath='{.items[0].metadata.name}')
echo "Using pod: $POD"

kubectl cp /tmp/ph26.5k-simulate-storage.js keybuzz-backend-dev/$POD:/app/simulate-storage.js
kubectl exec -n keybuzz-backend-dev $POD -- node /app/simulate-storage.js
