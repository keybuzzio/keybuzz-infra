#!/bin/bash
cd /opt/keybuzz/keybuzz-infra
git add k8s/keybuzz-client-dev/deployment.yaml
git commit -m "fix: pass tenantId to status/sav-status updates in InboxTripane - DEV v3.5.49"
git push origin main
