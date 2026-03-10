#!/bin/bash
# PH26.5K: Decode secret

kubectl get secret keybuzz-backend-db -n keybuzz-backend-dev -o json | python3 -c '
import json, sys, base64
d = json.load(sys.stdin)
for k, v in d.get("data", {}).items():
    print(k, "=", base64.b64decode(v).decode())
'
