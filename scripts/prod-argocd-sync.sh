#!/bin/bash
# Force ArgoCD refresh for PROD
kubectl patch application keybuzz-client-prod -n argocd --type=merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
echo "Refresh triggered, waiting..."
sleep 15
kubectl get deploy keybuzz-client -n keybuzz-client-prod -o jsonpath='{.spec.template.spec.containers[0].image}' && echo ""
kubectl get pods -n keybuzz-client-prod
kubectl get application keybuzz-client-prod -n argocd -o jsonpath='{.status.sync.status}' && echo ""
