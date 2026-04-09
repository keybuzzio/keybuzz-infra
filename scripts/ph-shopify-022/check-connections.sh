#!/bin/bash
POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n keybuzz-api-dev "$POD" -- node -e '
const {Pool} = require("pg");
const p = new Pool();
(async () => {
  const cols = await p.query("SELECT column_name FROM information_schema.columns WHERE table_name = '\''shopify_connections'\'' ORDER BY ordinal_position");
  console.log("=== COLUMNS ===");
  console.log(cols.rows.map(r => r.column_name).join(", "));
  const r = await p.query("SELECT * FROM shopify_connections LIMIT 5");
  console.log("=== DATA ===");
  console.log(JSON.stringify(r.rows, null, 2));
  await p.end();
})();
'
