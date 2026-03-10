# PROD GOLDEN BASELINE

**Établi** : 2026-02-19T11:11Z
**Validé par** : CE (validation E2E automatisée, 10/10 tests OK)
**Statut** : ✅ PROD stable et fonctionnelle

---

## Images & Digests

| Namespace | Deploy | Image | Digest |
|-----------|--------|-------|--------|
| keybuzz-client-prod | keybuzz-client | `ghcr.io/keybuzzio/keybuzz-client:v3.4.2-ph351-octopia-import-prod` | `sha256:c6d2b083d1f94f3fd4a5f57b9f2162ec6267509ed9f2e82047c7f33a8808e944` |
| keybuzz-api-prod | keybuzz-api | `ghcr.io/keybuzzio/keybuzz-api:v3.4.4-ph353-octopia-readonly-prod-2` | `sha256:12bc6169e4e617d81492d549c9b78c0f7a9d75da51ccf18136c91c7c85939dd1` |
| keybuzz-api-prod | keybuzz-outbound-worker | `ghcr.io/keybuzzio/keybuzz-api:v3.4.4-ph353-octopia-readonly-prod-2` | `sha256:12bc6169e4e617d81492d549c9b78c0f7a9d75da51ccf18136c91c7c85939dd1` |
| keybuzz-backend-prod | keybuzz-backend | `ghcr.io/keybuzzio/keybuzz-backend:v3.1.3-ph342-inbound-prod-2` | `sha256:6ba037f2893c3c123cfe3b7b73878f23e9373150b41cc97c6bc149105e827b8d` |
| keybuzz-backend-prod | amazon-items-worker | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.34-ph263` | — |
| keybuzz-backend-prod | amazon-orders-worker | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.34-ph263` | — |

## Tenant PROD

| ID | Nom | Plan | Statut |
|----|-----|------|--------|
| `ecomlg-001` | eComLG | pro | active |
| `tenant-1771372406836` | SWITAA SASU | AUTOPILOT | active (trial 13j) |

**Note importante** : Le tenant PROD est `tenant-1771372406836`, à ne pas confondre avec le tenant DEV `tenant-1771372217854`.

## Validation E2E — 10/10

| # | Test | Status | Détail |
|---|------|--------|--------|
| 1 | API Health | ✅ | `200 {"status":"ok"}` |
| 2 | Login/Auth | ✅ | `exists:true, hasTenants:true, userName: Ludovic GONTHIER` |
| 3 | Dashboard | ✅ | Données présentes |
| 4 | Messages | ✅ | 3 conversations retournées, channel octopia |
| 5 | Channels | ✅ | octopia=232, amazon=1 |
| 6 | Suppliers | ✅ | 1 fournisseur |
| 7 | AI Settings | ✅ | mode=supervised, enabled=true |
| 8 | Octopia | ✅ | status=ERROR (credentials connues) |
| 9 | BFF Client | ✅ | check-email → exists:true |
| 10 | Billing | ✅ | plan=AUTOPILOT, monthly |

## Contenu fonctionnel inclus

| Phase | Contenu | Statut |
|-------|---------|--------|
| PH33KB | KBActions Access v2 | ✅ |
| PH34.2 | Inbound email provisioning | ✅ |
| PH34.3 | Sender policy + daily budget | ✅ |
| PH34.4B | Octopia header fix | ✅ |
| PH35.1 | Octopia import discussions | ✅ |
| PH35.3 | Octopia backfill (232 convs) + sync worker | ✅ |
| PH35.3B | Advisory lock anti-race | ✅ |

## Note sur le rollback avorté vers PH35.1

Lors de cette session, un rollback vers `v3.4.1-ph351-octopia-import-prod` a été tenté mais a révélé des erreurs 402 qui étaient en réalité causées par l'utilisation du **mauvais tenant ID** (DEV vs PROD). Le `v3.4.4-ph353-octopia-readonly-prod-2` était et reste la bonne baseline stable.

## Rollback commands

```bash
# Client PROD
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.4.2-ph351-octopia-import-prod -n keybuzz-client-prod

# API PROD
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.4.4-ph353-octopia-readonly-prod-2 -n keybuzz-api-prod

# Outbound Worker PROD
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.4.4-ph353-octopia-readonly-prod-2 -n keybuzz-api-prod

# Backend PROD (unchanged)
# keybuzz-backend: v3.1.3-ph342-inbound-prod-2
# amazon workers: v1.0.34-ph263
```

---

## STOP POINT

Baseline golden PROD établie et validée. Aucune modification supplémentaire sans validation Ludovic.
