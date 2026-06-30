# PH-SAAS-T8.12AS.21.225-226 - Shopify Connector Hardening And Readiness DEV

## Verdict

READY_DEV_VALIDATED / PROD_UNTOUCHED.

## Scope

- DEV source/API/Client patched, built, pushed and deployed through GitOps.
- PROD read-only only; no PROD build, push, apply, DB mutation, Shopify OAuth, webhook replay or fake event.
- Shopify remains orders-first: `supports_messaging=false` until real Shopify message ingestion exists.

## Source Commits

| Repo | Branch | Commit | Scope |
| --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | `28bcfa1e` | Shopify tenantGuard, OAuth shop/state validation, raw-body HMAC, webhook idempotence, uninstall handling, API version |
| keybuzz-client | ph148/onboarding-activation-replay | `9371e30` | Shopify catalog messaging capability disabled while coming soon |
| keybuzz-api | ph147.4/source-of-truth | `b0ce5fc5` | Shopify initial 90-day paginated sync readiness |
| keybuzz-client | ph148/onboarding-activation-replay | `b14710f` | Shopify entrypoints visible in DEV, no messaging claim |

## Images And Runtime DEV

| Service | Image | Digest | Source |
| --- | --- | --- | --- |
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.281-shopify-readiness-dev` | `sha256:88cbfd8c56668f44ec04b5fb631cb96dceed06da9e45e3a586ae0aa994405451` | `b0ce5fc523f43d5b9684c77648f1f771a5e08697` |
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.280-shopify-readiness-dev` | `sha256:242c62a14e9d31e6518fdddca6026c9acd6714158c0aef642fb609f18bb1f328` | `b14710f5757cea55a24d1785bd64b0eb7c4d088c` |

## GitOps

- `0c4562f`: DEV hardening image apply.
- `bdfa9c6`: DEV readiness image apply.
- Applies executed only with `kubectl apply -f` on:
  - `k8s/keybuzz-api-dev/deployment.yaml`
  - `k8s/keybuzz-client-dev/deployment.yaml`

## Validations

| Check | Result |
| --- | --- |
| API `npx tsc --noEmit` | PASS |
| API PH21.225 source tests | PASS |
| API PH21.226 source tests | PASS |
| Client targeted ESLint | PASS |
| API Docker build-from-git | PASS |
| Client Docker build-from-git with explicit DEV args | PASS |
| Client bundle API DEV present / API PROD absent | PASS |
| Image pull-back digest | PASS |
| API DEV rollout | PASS, Ready 1/1, restarts 0 |
| Client DEV rollout | PASS, Ready 1/1, restarts 0 |
| API runtime markers | PASS: raw HMAC, uninstall, 90-day sync, 2026-04 |
| Client runtime markers | PASS: Shopify entry, API DEV, no API PROD |
| PROD runtime read-only | PASS unchanged |

## Functional State

- `/shopify/status`, `/shopify/connect`, `/shopify/disconnect`, `/shopify/orders/sync` are tenant-guarded.
- Shopify OAuth callback rejects shop/state mismatch and invalid shop domains.
- Webhook HMAC is verified from raw body, not re-serialized JSON.
- Webhook events are idempotent through `x-shopify-webhook-id`.
- `app/uninstalled` disconnects the active Shopify connection.
- Shopify Admin API defaults to `2026-04`, overrideable by `SHOPIFY_API_VERSION`.
- Initial post-OAuth sync defaults to 90 days / max 1000 orders, paginated by cursor.
- Manual sync accepts `limit` and bounded `sinceDays`.
- Client DEV exposes Shopify in channels/onboarding, but does not claim messaging support.

## No Side Effect

- No Shopify OAuth executed by CE.
- No webhook replay.
- No fake event.
- No secret read/display.
- No PROD mutation.
- No DB mutation volontaire by CE.
- No Linear action.

## Remaining Gate

PROD promotion requires explicit Ludovic GO after DEV visual/functional check with a real Shopify test shop.
