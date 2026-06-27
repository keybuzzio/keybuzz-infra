# PH-SAAS-T8.12AS.21.171 - Source patch billing events tenant_id and Octopia status route DEV

Date: 2026-06-27
Environment: DEV
Type: source patch + build + push image + GitOps apply + readonly verify
Verdict: READY_DEV_RUNTIME

## Objective

Close the two debts found in PH-21.170:

1. Persist `billing_events.tenant_id` from Stripe webhook metadata when available.
2. Expose the canonical Octopia status route expected by Client BFF:
   `/marketplaces/octopia/status`.

Keep backward compatibility for the legacy API route:
`/octopia/marketplaces/octopia/status`.

## Repositories

| Repo | Branch | Result |
| --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | source patched, committed, pushed |
| keybuzz-infra | main | DEV manifest patched, committed, pushed, applied |

## API source patch

API commit:

`d4f4f0b1becd4adda33be4407b4ab7ab398d3c81`

Files changed:

| File | Change | Risk control |
| --- | --- | --- |
| `src/modules/billing/routes.ts` | Adds safe Stripe tenant extraction and persists `tenant_id` in `billing_events` insert | Existing Stripe event handling preserved; no fake webhook emitted |
| `src/app.ts` | Registers canonical Octopia routes at root prefix while preserving legacy `/octopia` prefix | Backward compatibility preserved |
| `src/tests/ph21171-billing-events-octopia-route-tests.ts` | Adds offline tests for billing tenant_id persistence and Octopia route registration | Source-only, no DB mutation |

## Tests

| Test | Result |
| --- | --- |
| `npx ts-node src/tests/ph21171-billing-events-octopia-route-tests.ts` | PASS |
| `npx ts-node src/tests/ph21132a-no-card-trial-runtime-endpoint-tests.ts` | PASS |
| `npx tsc --noEmit` | PASS |
| `npm audit` | PASS, 0 vulnerabilities |

## Image

| Field | Value |
| --- | --- |
| Image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.272-billing-events-octopia-route-dev` |
| Image ID | `sha256:1052e0eba62a4e77b45aad2b7cc8da0559d207822e5fb3093ee8df9aa07d63d7` |
| GHCR digest | `sha256:e6d394a3ddde099348e89b7c56f7dab054b863d127a56a09da621175ecdf9363` |
| Source revision | `d4f4f0b1becd4adda33be4407b4ab7ab398d3c81` |
| Registry safety | target tag absent before push; `latest` unchanged |

## GitOps DEV

Manifest commit:

`adc4829`

Manifest changed:

`k8s/keybuzz-api-dev/deployment.yaml`

Dry-runs:

| Command | Result |
| --- | --- |
| `kubectl apply --dry-run=client -f k8s/keybuzz-api-dev/deployment.yaml` | PASS |
| `kubectl apply --dry-run=server -f k8s/keybuzz-api-dev/deployment.yaml` | PASS |

Apply:

`kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml`

Rollout:

`deployment "keybuzz-api" successfully rolled out`

## Runtime verification DEV

| Check | Result |
| --- | --- |
| Deployment image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.272-billing-events-octopia-route-dev` |
| Ready | `1/1` |
| Generation | `511/511` |
| Pod | `keybuzz-api-565f7b7b84-lz965` |
| Pod ready | `true` |
| Restarts | `0` |
| Pod imageID | `ghcr.io/keybuzzio/keybuzz-api@sha256:e6d394a3ddde099348e89b7c56f7dab054b863d127a56a09da621175ecdf9363` |
| Health | PASS |
| Canonical Octopia route `/marketplaces/octopia/status` | HTTP 400, route exists and is not 404 |
| Legacy Octopia route `/octopia/marketplaces/octopia/status` | HTTP 400, route exists and is not 404 |
| Billing tenant_id runtime markers | PASS |

HTTP 400 is expected for the passive route existence check because no tenant/auth payload is sent. The previous defect was HTTP 404 on the canonical route.

## Safety

No fake events were emitted.

No Stripe webhook replay was executed.

No checkout, form submission, DB mutation, retry/replay, CAPI test, Webflow change or Linear change was executed.

No PROD runtime was changed in this DEV phase.

## Debt status

DEV source/runtime debts found in PH-21.170 are closed:

| Debt | Status |
| --- | --- |
| `billing_events.tenant_id` missing from Stripe webhook inserts | CLOSED in source and DEV runtime |
| Client BFF Octopia route returning 404 because API only exposed legacy prefix | CLOSED in source and DEV runtime |

PROD promotion remains separate by KeyBuzz rule because the current GO is explicitly DEV.

## Next GO

`GO BUILD API BILLING EVENTS TENANT ID AND OCTOPIA STATUS ROUTE PROD PH-SAAS-T8.12AS.21.172`

STOP
