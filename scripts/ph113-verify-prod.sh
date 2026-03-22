#!/bin/bash
set -euo pipefail

echo "=== PH113 PROD Verification ==="
NAMESPACE="keybuzz-api-prod"
sleep 5

POD=$(kubectl get pods -n "$NAMESPACE" -l app=keybuzz-api --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -z "$POD" ]; then
  echo "ERROR: No running pod found"
  exit 1
fi
echo "Pod: $POD"

kubectl exec -n "$NAMESPACE" "$POD" -- node -e '
const http = require("http");
const tests = [
  { name: "health", path: "/health", headers: {} },
  { name: "PH113-status", path: "/ai/real-execution-status?tenantId=ecomlg-001", headers: { "x-user-email": "ludo.gonthier@gmail.com" } },
  { name: "PH113-safe-exec", path: "/ai/safe-execution?tenantId=ecomlg-001&channel=amazon", headers: { "x-user-email": "ludo.gonthier@gmail.com" } },
  { name: "PH111-activation", path: "/ai/controlled-activation?tenantId=ecomlg-001", headers: { "x-user-email": "ludo.gonthier@gmail.com" } },
  { name: "PH110-execution", path: "/ai/controlled-execution?tenantId=ecomlg-001", headers: { "x-user-email": "ludo.gonthier@gmail.com" } },
  { name: "PH100-governance", path: "/ai/governance?tenantId=ecomlg-001", headers: { "x-user-email": "ludo.gonthier@gmail.com" } },
];
let pass=0,fail=0;
function check(t){return new Promise(r=>{const o={hostname:"127.0.0.1",port:3001,path:t.path,method:"GET",headers:t.headers,timeout:10000};const q=http.request(o,res=>{let b="";res.on("data",d=>b+=d);res.on("end",()=>{const ok=res.statusCode>=200&&res.statusCode<400;console.log(ok?"PASS":"FAIL",t.name,res.statusCode,b.substring(0,200));ok?pass++:fail++;r()})});q.on("error",e=>{console.log("FAIL",t.name,e.message);fail++;r()});q.on("timeout",()=>{q.destroy();console.log("FAIL",t.name,"timeout");fail++;r()});q.end();})}
(async()=>{for(const t of tests)await check(t);console.log("---");console.log("Results:",pass,"PASS /",fail,"FAIL");if(fail>0)process.exit(1)})();
' 2>&1

echo ""
echo "=== PH113 PROD Verification Complete ==="
