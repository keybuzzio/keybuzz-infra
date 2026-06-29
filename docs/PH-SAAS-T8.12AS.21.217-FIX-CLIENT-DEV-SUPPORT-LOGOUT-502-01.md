# PH-SAAS-T8.12AS.21.217 - FIX CLIENT DEV SUPPORT LOGOUT 502

Date: 2026-06-29

## Verdict

READY_FOR_BROWSER_RETEST_DEV.

## Incident

Clicking `Deconnexion` / `Quitter` in the DEV Client support session returned a public `502` on:

`https://client-dev.keybuzz.io/api/auth/logout`

## Root cause

The previous cookie purge response emitted too many `Set-Cookie` headers. Internal pod checks passed, but the public ingress rejected the upstream response, producing a `502`.

## Fix

Client source commit:

- `e359976` - `fix(client): bound logout cookie purge headers`

Runtime Client DEV:

- Image: `ghcr.io/keybuzzio/keybuzz-client:v3.5.275-support-logout-502-fix-dev`
- GHCR digest: `sha256:84c00d38a56ada3cb1769f75f7e6b6b23586dcf656adf8dad5ff08084c292f93`
- Source: `e359976`
- Rollback: `v3.5.274-support-auth-cookie-purge-dev`

The purge now expires:

- incoming NextAuth cookies only, including chunked names when present;
- `currentTenantId`;
- `currentTenantRole`;
- `kb_session`;
- only host-only and `.keybuzz.io` variants.

No broad fallback cookie explosion remains.

## Validation

| Check | Result |
| --- | --- |
| Client tests | PASS |
| TypeScript | PASS |
| ESLint | PASS |
| Build from clean Git | PASS |
| Client DEV bundle contains `https://api-dev.keybuzz.io` | PASS |
| Client DEV bundle contains `https://api.keybuzz.io` | PASS, 0 occurrence |
| GHCR push/pull-back | PASS |
| GitOps image-only manifest patch | PASS |
| Dry-run client/server | PASS |
| Rollout DEV | PASS |
| Public `/api/auth/logout` without cookies | PASS, HTTP 302, no 502 |
| Public `/api/auth/logout` with invalid chunked cookie | PASS, HTTP 302, purge headers |
| Public `/api/auth/me` with invalid chunked cookie | PASS, HTTP 401, purge headers |

## Public proof

No-cookie logout:

- HTTP `302`
- Location: `https://client-dev.keybuzz.io/login`
- Header size: `1057` bytes

Invalid cookie logout:

- HTTP `302`
- Header size: `1649` bytes

Invalid cookie `/api/auth/me`:

- HTTP `401`
- Header size: `1634` bytes

## No side-effect confirmation

- No PROD deploy.
- No PROD manifest change.
- No fake event.
- No tracking event.
- No checkout.
- No Stripe write.
- No secret read/displayed.
- No business DB mutation.

## Browser retest

Open:

`https://client-dev.keybuzz.io/api/auth/logout`

Expected result:

- redirect to `/login`;
- no `502`;
- next Admin `Assistance SaaS` flow should open cleanly.

