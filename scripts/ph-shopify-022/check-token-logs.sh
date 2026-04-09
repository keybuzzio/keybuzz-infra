#!/bin/bash
POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}')
echo "=== Token exchange logs ==="
kubectl logs -n keybuzz-api-dev "$POD" --tail=60 2>/dev/null | grep -i -E 'shopify|token|expires|rotat|managed'
echo ""
echo "=== DB connection check ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e '
const {Pool} = require("pg");
const p = new Pool();
(async () => {
  const r = await p.query("SELECT id, scopes, status, token_expires_at, created_at FROM shopify_connections WHERE status = '\''active'\'' ORDER BY created_at DESC LIMIT 1");
  if (r.rows.length) console.log(JSON.stringify(r.rows[0], null, 2));
  else console.log("No active connection found");
  await p.end();
})();
'
