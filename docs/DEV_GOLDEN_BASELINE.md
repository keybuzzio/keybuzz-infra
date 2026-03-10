# DEV GOLDEN BASELINE

**Établi** : 2026-02-19T11:32Z
**Validé par** : CE (validation E2E automatisée, 17/17 tests OK)
**Stratégie** : Alignement DEV sur PROD golden baseline

---

## Images & Digests

| Namespace | Deploy | Image | Digest |
|-----------|--------|-------|--------|
| keybuzz-api-dev | keybuzz-api | `ghcr.io/keybuzzio/keybuzz-api:v3.4.4-ph353b-fixed-lock-dev` | `sha256:12bc6169e4e617d81492d549c9b78c0f7a9d75da51ccf18136c91c7c85939dd1` |
| keybuzz-api-dev | keybuzz-outbound-worker | `ghcr.io/keybuzzio/keybuzz-api:v3.4.4-ph353b-fixed-lock-dev` | `sha256:12bc6169e4e617d81492d549c9b78c0f7a9d75da51ccf18136c91c7c85939dd1` |
| keybuzz-client-dev | keybuzz-client | `ghcr.io/keybuzzio/keybuzz-client:v3.4.2-ph351-octopia-import-dev` | `sha256:0b6cbef5...` (DEV build) |
| keybuzz-backend-dev | keybuzz-backend | `ghcr.io/keybuzzio/keybuzz-backend:v3.1.3-ph342-inbound-prod-2` | `sha256:9c0f4ca0...` |
| keybuzz-backend-dev | amazon-items-worker | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.34-ph263` | `sha256:6b726ebb...` |
| keybuzz-backend-dev | amazon-orders-worker | `ghcr.io/keybuzzio/keybuzz-backend:v1.0.34-ph263` | `sha256:6b726ebb...` |

## Parité DEV / PROD

| Composant | DEV Tag | PROD Tag | Même image ? |
|-----------|---------|----------|-------------|
| API | `v3.4.4-ph353b-fixed-lock-dev` | `v3.4.4-ph353-octopia-readonly-prod-2` | **OUI** (même Docker ID) |
| Worker | `v3.4.4-ph353b-fixed-lock-dev` | `v3.4.4-ph353-octopia-readonly-prod-2` | **OUI** (même Docker ID) |
| Client | `v3.4.2-ph351-octopia-import-dev` | `v3.4.2-ph351-octopia-import-prod` | Non (builds séparés, même source) |
| Backend | `v3.1.3-ph342-inbound-prod-2` | `v3.1.3-ph342-inbound-prod-2` | **OUI** |

## Tenant de test

| Champ | Valeur |
|-------|--------|
| Tenant ID | `tenant-1771372217854` |
| Nom | SWITAA SASU |
| Plan | PRO |
| Trial | true (expire 2026-03-03) |
| User email | `contact@switaa.com` |
| User name | Ludovic GONTHIER |

**ATTENTION** : Le tenant PROD est différent (`tenant-1771372406836`). Ne pas confondre.

## Validation E2E — 17/17

| # | Test | Status | Détail |
|---|------|--------|--------|
| 1 | API Health | ✅ | 200 |
| 2 | Login/Auth (check-user) | ✅ | exists:true, hasTenants:true, userName:Ludovic GONTHIER |
| 3 | Tenants | ✅ | 1 tenant, plan=PRO, trial=true |
| 4 | Dashboard | ✅ | 200, données présentes |
| 5 | Messages | ✅ | count=3, channel=octopia |
| 6 | Channels | ✅ | octopia=232, amazon=3 |
| 7 | Suppliers | ✅ | count=2 |
| 8 | AI Settings | ✅ | mode=supervised, enabled=true |
| 9 | Octopia status | ✅ | status=ERROR (credentials connues) |
| 10 | Billing | ✅ | plan=PRO, monthly |
| 11 | BFF CheckEmail | ✅ | exists:true, hasTenants:true |
| 12 | Page /login | ✅ | 200 |
| 13 | Page /inbox | ✅ | 307 (auth redirect) |
| 14 | Page /orders | ✅ | 307 |
| 15 | Page /settings | ✅ | 307 |
| 16 | Page /suppliers | ✅ | 307 |
| 17 | Page /dashboard | ✅ | 307 |

## Contenu fonctionnel

| Phase | Contenu | Statut |
|-------|---------|--------|
| PH33KB | KBActions Access v2 | ✅ |
| PH34.2 | Inbound email provisioning | ✅ |
| PH34.3 | Sender policy + daily budget | ✅ |
| PH34.4B | Octopia header fix | ✅ |
| PH35.1 | Octopia import discussions | ✅ |
| PH35.2 | Octopia outbound adapter | ✅ (DEV only) |
| PH35.3 | Octopia backfill 232 convs + sync worker | ✅ |
| PH35.3B | Advisory lock anti-race | ✅ |

## Rollback commands

```bash
# API DEV
kubectl set image deployment/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.4.4-ph353b-fixed-lock-dev -n keybuzz-api-dev

# Worker DEV
kubectl set image deployment/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.4.4-ph353b-fixed-lock-dev -n keybuzz-api-dev

# Client DEV
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.4.2-ph351-octopia-import-dev -n keybuzz-client-dev
```

---

## STOP POINT

DEV golden baseline établie et validée 17/17. Aucune modification sans validation Ludovic.
