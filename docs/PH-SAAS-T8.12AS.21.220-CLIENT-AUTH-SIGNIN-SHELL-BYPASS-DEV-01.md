# PH-SAAS-T8.12AS.21.220 - Client auth signin shell bypass DEV

Date UTC: 2026-06-29
Environment: DEV
Type: Source patch / build / GitOps apply / read-only verify
Verdict: READY_DEV

## Objective

Fix the unauthenticated loop reported after logout when opening:

- `https://client.keybuzz.io`
- `https://client.keybuzz.io/auth/signin?callbackUrl=%2F`

The same symptom was reported on DEV and PROD: the page showed `Préparation de votre espace...` instead of a public sign-in flow.

## Root Cause

`/auth/signin` was already public in middleware / route access:

- `PUBLIC_ROUTES` contained `/auth/signin`, `/auth/error`, `/auth/callback`.
- `proxy.ts` allowed `/auth/*`.

But `SHELL_BYPASS_ROUTES` did not contain `/auth` routes. Therefore the public NextAuth sign-in route could still be wrapped by `ClientLayout` and `EntitlementGuard`. Without a tenant, the guard rendered `Préparation de votre espace...`.

During build, `/auth/error` also surfaced a Next.js 16 requirement: `useSearchParams()` must be wrapped in a `Suspense` boundary.

## Source Changes

Repo: `/opt/keybuzz/keybuzz-client`
Branch: `ph148/onboarding-activation-replay`

Commits:
- `73231e073d5c8917be85b7bab1c4cbbcf577a22a` - `fix(client): bypass shell guard for auth routes`
- `e7aefa15ee2ce9f2d5a43f359dd31c12ae3b8d5f` - `fix(client): wrap auth error search params in suspense`

Files:

| File | Change | Risk |
| --- | --- | --- |
| `src/lib/routeAccessGuard.ts` | Added `/auth` to `SHELL_BYPASS_ROUTES` | Low: aligns shell guard with existing public middleware behavior |
| `app/auth/error/page.tsx` | Wrapped `useSearchParams()` in `Suspense` | Low: build compatibility only |

Validations:
- `npx eslint src/lib/routeAccessGuard.ts`
- `npx eslint app/auth/error/page.tsx src/lib/routeAccessGuard.ts`
- Source marker checks PASS.

## DEV Image

Image:
- `ghcr.io/keybuzzio/keybuzz-client:v3.5.278-auth-shell-bypass-dev`

Digest:
- `sha256:4a30db72b70f8dd6539d881003cf4c918f5ef4580dc5da4048820c1c50f348bc`

Image ID:
- `sha256:0979ef47490fe92eeea5ba71ff927f01b36574ccde5c9994eeaf93d99c2806e5`

Build safety:
- Build-from-git clean worktree from `e7aefa15ee2ce9f2d5a43f359dd31c12ae3b8d5f`.
- Explicit DEV build args.
- Bundle verification PASS:
  - `api-dev.keybuzz.io`: 5
  - `api.keybuzz.io`: 0
- No `latest` push.

## DEV GitOps

Infra commit:
- `2c77b5996125b726f09838d8b64ff1bcd15640a7`

Manifest:
- `k8s/keybuzz-client-dev/deployment.yaml`

Method:
- image-only manifest change
- commit + push before apply
- `kubectl apply --dry-run=client -f` PASS
- `kubectl apply --dry-run=server -f` PASS
- `kubectl apply -f`
- rollout successful

No `kubectl set image`, `kubectl set env`, `kubectl patch`, `kubectl edit`.

## DEV Runtime Verification

Runtime:
- Image: `ghcr.io/keybuzzio/keybuzz-client:v3.5.278-auth-shell-bypass-dev`
- Ready: `1/1`
- Generation: `1040/1040`
- Pod: `keybuzz-client-9ccc967f-2b4rh`
- Restarts: `0`
- Pod imageID digest: `sha256:4a30db72b70f8dd6539d881003cf4c918f5ef4580dc5da4048820c1c50f348bc`

Passive HTTP checks on `client-dev.keybuzz.io`:

| Route | Result |
| --- | --- |
| `/` with redirects | HTTP 200 |
| `/auth/signin?callbackUrl=%2F` with redirects | HTTP 200 |
| `/login?callbackUrl=%2F` with redirects | HTTP 200 |
| `/auth/error?error=Default` with redirects | HTTP 200 |
| Loop text `Préparation de votre espace...` | ABSENT |
| `/api/auth/logout` | HTTP 302 |
| `/api/auth/me` with invalid/chunked cookies | HTTP 401 + purge headers |

## No Side Effects

- No fake event.
- No checkout.
- No tracking event.
- No form submission.
- No business DB mutation.
- No secret read or displayed.
- PROD runtime not touched in PH-21.220.

## PROD Gate

The same bug was reported in PROD. DEV is validated and ready for PROD promotion.

Required next explicit GO:

`GO BUILD PUSH APPLY CLIENT AUTH SIGNIN SHELL BYPASS PROD PH-SAAS-T8.12AS.21.221`

Expected PROD tag:

`ghcr.io/keybuzzio/keybuzz-client:v3.5.278-auth-shell-bypass-prod`

Rollback PROD:

`ghcr.io/keybuzzio/keybuzz-client:v3.5.276-shell-route-entitlement-bypass-prod`

## Final Verdict

READY_DEV.

DEV is fixed and verified. PROD promotion requires explicit GO because it mutates PROD runtime.
