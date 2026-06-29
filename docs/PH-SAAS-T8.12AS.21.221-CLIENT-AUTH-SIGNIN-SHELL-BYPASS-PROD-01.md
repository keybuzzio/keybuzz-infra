# PH-SAAS-T8.12AS.21.221 - Client auth signin shell bypass PROD

Date UTC: 2026-06-29
Environment: PROD
Type: Build / push image / GitOps apply / read-only verify
Verdict: READY

## Objective

Promote the DEV-validated fix from PH-21.220 to PROD for the unauthenticated loop after logout:

- `https://client.keybuzz.io`
- `https://client.keybuzz.io/auth/signin?callbackUrl=%2F`

Reported symptom: page showed `Préparation de votre espace...` instead of a public auth/login route.

## Root Cause

`/auth/signin` was public in middleware and route access, but `/auth/*` was not included in `SHELL_BYPASS_ROUTES`.

As a result, the public NextAuth sign-in page could still be wrapped by `ClientLayout` and `EntitlementGuard`. With no selected tenant after logout, `EntitlementGuard` displayed the tenant preparation loader.

The build also required a related Next.js compatibility fix on `/auth/error`: `useSearchParams()` is now wrapped in `Suspense`.

## Source

Repo: `/opt/keybuzz/keybuzz-client`
Branch: `ph148/onboarding-activation-replay`

Commits:
- `73231e073d5c8917be85b7bab1c4cbbcf577a22a` - `fix(client): bypass shell guard for auth routes`
- `e7aefa15ee2ce9f2d5a43f359dd31c12ae3b8d5f` - `fix(client): wrap auth error search params in suspense`

Files:

| File | Change |
| --- | --- |
| `src/lib/routeAccessGuard.ts` | Added `/auth` to `SHELL_BYPASS_ROUTES` |
| `app/auth/error/page.tsx` | Wrapped `useSearchParams()` in `Suspense` |

Source preflight:
- Branch OK.
- HEAD `e7aefa1`.
- Repo clean.
- Ahead/behind `0/0`.

## Build And Image

PROD image:
- `ghcr.io/keybuzzio/keybuzz-client:v3.5.278-auth-shell-bypass-prod`

Digest:
- `sha256:82803dde2788ca5f8941a823e66f751cd24d646619c56e6c86f8613b8e3dc26a`

Image ID:
- `sha256:1360917a70401468353eed0d9969c2e39672340e490088cc5182c17a1d53463e`

Build safety:
- Build-from-git clean worktree from `e7aefa15ee2ce9f2d5a43f359dd31c12ae3b8d5f`.
- Immutable tag was absent before push.
- Explicit PROD build args:
  - `NEXT_PUBLIC_APP_ENV=production`
  - `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`
  - `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`
  - `NEXT_PUBLIC_CLARITY_PROJECT_ID=wuk12h9i33`
- Bundle verification PASS:
  - `api.keybuzz.io`: 5
  - `api-dev.keybuzz.io`: 0
  - Clarity marker `wuk12h9i33`: 1
- `latest` was not pushed.

## GitOps

Infra repo:
- `/opt/keybuzz/keybuzz-infra`
- Branch: `main`
- Deploy commit: `6e5842d07b22d7f580dd66b41250dab28895a097`

Manifest changed:
- `k8s/keybuzz-client-prod/deployment.yaml`

Runtime change:
- From `ghcr.io/keybuzzio/keybuzz-client:v3.5.276-shell-route-entitlement-bypass-prod`
- To `ghcr.io/keybuzzio/keybuzz-client:v3.5.278-auth-shell-bypass-prod`

Method:
- Image-only manifest patch.
- Commit + push before apply.
- `kubectl apply --dry-run=client -f` PASS.
- `kubectl apply --dry-run=server -f` PASS.
- `kubectl apply -f`.
- Rollout successful.

Forbidden actions not used:
- No `kubectl set image`.
- No `kubectl set env`.
- No `kubectl patch`.
- No `kubectl edit`.

Rollback:
- `ghcr.io/keybuzzio/keybuzz-client:v3.5.276-shell-route-entitlement-bypass-prod`

## PROD Runtime Verification

Runtime:
- Image: `ghcr.io/keybuzzio/keybuzz-client:v3.5.278-auth-shell-bypass-prod`
- Ready: `1/1`
- Generation: `438/438`
- Pod: `keybuzz-client-574855c6d9-wcdx2`
- Restarts: `0`
- Pod imageID digest: `sha256:82803dde2788ca5f8941a823e66f751cd24d646619c56e6c86f8613b8e3dc26a`

Equality:
- Manifest Git = last-applied = deployment spec = pod image.
- Pod imageID digest matches GHCR digest.

## Passive HTTP Checks

Routes checked on `client.keybuzz.io`:

| Route | Result |
| --- | --- |
| `/` with redirects | HTTP 200 |
| `/auth/signin?callbackUrl=%2F` with redirects | HTTP 200 |
| `/login?callbackUrl=%2F` with redirects | HTTP 200 |
| `/auth/error?error=Default` with redirects | HTTP 200 |
| `/support/impersonate` with redirects | HTTP 200 |
| Text `Préparation de votre espace...` | ABSENT on all checked pages |
| `/api/auth/logout` | HTTP 302 |
| `/api/auth/logout` with invalid/chunked cookies | HTTP 302 + 12 purge headers |
| `/api/auth/me` with invalid/chunked cookies | HTTP 401 + 12 purge headers |

## Non-Regression

Read-only runtime check:
- Client DEV unchanged: `v3.5.278-auth-shell-bypass-dev`, ready `1/1`.
- Admin PROD unchanged: `v2.12.3-support-impersonation-prod`, ready `1/1`.
- API PROD unchanged: `v3.5.279-ai-response-humanness-prod`, ready `1/1`.

No side effects:
- No fake event.
- No checkout.
- No tracking event.
- No form submission.
- No support token generated.
- No business DB mutation.
- No secret read or displayed.

## Final Verdict

READY.

The PROD auth/signin shell bypass is deployed and verified. The reported loop on `https://client.keybuzz.io/auth/signin?callbackUrl=%2F` is fixed by passive checks.
