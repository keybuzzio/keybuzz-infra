# PH33.KBACTIONS.ACCESS.V2 — PROD Snapshot Before

## Rollback Tags
| Composant | Image | 
|-----------|-------|
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.4.1-ph343-daily-budget-fix-prod` |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.4.2-ph343-budget-ux-prod` |

## Rollback Commands
```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.4.1-ph343-daily-budget-fix-prod -n keybuzz-api-prod
kubectl rollout restart deploy/keybuzz-api -n keybuzz-api-prod
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.4.2-ph343-budget-ux-prod -n keybuzz-client-prod
kubectl rollout restart deploy/keybuzz-client -n keybuzz-client-prod
```

Date: 2026-02-18
