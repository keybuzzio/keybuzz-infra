#!/bin/bash
# Force ArgoCD refresh and sync
kubectl patch application keybuzz-client-dev -n argocd --type=merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
sleep 5
kubectl get application keybuzz-client-dev -n argocd -o jsonpath='{.status.sync.status}' && echo ""
kubectl get application keybuzz-client-dev -n argocd -o jsonpath='{.status.sync.revision}' && echo ""
sleep 10
kubectl get deploy keybuzz-client -n keybuzz-client-dev -o jsonpath='{.spec.template.spec.containers[0].image}' && echo ""
kubectl get pods -n keybuzz-client-dev
