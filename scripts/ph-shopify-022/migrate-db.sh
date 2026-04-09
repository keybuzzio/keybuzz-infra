#!/bin/bash
POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n keybuzz-api-dev "$POD" -- node -e '
const {Pool} = require("pg");
const p = new Pool();
(async () => {
  const check = await p.query(
    "SELECT 1 FROM information_schema.columns WHERE table_name = $1 AND column_name = $2",
    ["shopify_connections", "token_expires_at"]
  );
  if (check.rows.length === 0) {
    await p.query("ALTER TABLE shopify_connections ADD COLUMN token_expires_at TIMESTAMPTZ");
    console.log("OK: token_expires_at column added");
  } else {
    console.log("OK: token_expires_at column already exists");
  }
  await p.end();
})();
'
