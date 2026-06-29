# PH-SAAS-T8.12AS.21.214-216 - FIX SUPPORT LOGOUT AUTH COOKIE PURGE DEV

Date: 2026-06-29

## Verdict

READY_FOR_BROWSER_RETEST_DEV.

## Incident

After a DEV support impersonation session, logout could leave the Client stuck on:

`Preparation de votre espace...`

Client logs showed NextAuth JWT decode/decryption errors. The practical effect was that a stale/invalid auth cookie could keep the app in a bad intermediate state and prevent a clean new login.

## Root cause

The custom Client logout route purged only simple NextAuth cookie names. It did not robustly handle:

- chunked NextAuth cookies such as `__Secure-next-auth.session-token.0`;
- stale tenant cookies;
- `/api/auth/me` returning unauthenticated without throwing, which previously returned `401` without purge headers.

An intermediate patch generated too many fallback `Set-Cookie` headers. This was caught by an explicit invalid-JWT test via `HeadersOverflowError`, then reduced to a bounded purge strategy.

## Final fix

Client source commits:

- `f063287` - purge invalid support auth cookies.
- `1400bda` - purge stale auth cookies on unauthenticated `/api/auth/me`.
- `2eec329` - cap auth cookie purge headers.

Runtime Client DEV:

- `ghcr.io/keybuzzio/keybuzz-client:v3.5.274-support-auth-cookie-purge-dev`
- GHCR manifest digest: `sha256:6131bf99db1842ab19c553a92c5eaf9c30d90156a5e7357495cc54d3a550527f`
- Config/Image ID: `sha256:760fd65642a93129e040b010648ac4f20379e7b4ae5d3bfe8ddc0cfe71d311ee`
- Source: `2eec329`
- Rollback: `v3.5.273-support-auth-cookie-purge-dev`

## Validation

| Check | Result |
| --- | --- |
| Client source tests | PASS |
| `npx tsc --noEmit` | PASS |
| `npm run lint` | PASS |
| Build from clean Git worktree | PASS |
| Client DEV build args explicit | PASS |
| Client bundle contains `https://api-dev.keybuzz.io` | PASS |
| Client bundle contains `https://api.keybuzz.io` | PASS, 0 occurrence |
| Runtime marker `FALLBACK_CHUNKED_COOKIE_NAMES` / `hasAuthCookies` | PASS |
| GHCR push and pull-back | PASS |
| GitOps manifest image-only patch | PASS |
| Dry-run client/server | PASS |
| `kubectl apply -f` Client DEV only | PASS |
| Rollout Client DEV | PASS |
| Runtime Client DEV ready/restarts | PASS, 1/1, 0 |
| Invalid JWT `/api/auth/me` | PASS, `401` plus purge headers |
| Invalid JWT `/api/auth/logout` | PASS, `302` plus purge headers |

## Current DEV runtime

| Service | Image | Status |
| --- | --- | --- |
| Admin DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.12.3-support-impersonation-dev` | Ready 1/1, restarts 0 |
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.274-support-auth-cookie-purge-dev` | Ready 1/1, restarts 0 |

## No side-effect confirmation

- No PROD deploy.
- No PROD manifest change.
- No fake event.
- No tracking event.
- No checkout.
- No Stripe write.
- No secret read/displayed.
- No business DB mutation by CE.

## Browser retest required

Because the reported failure was browser-cookie state, final validation must be done in the browser that was stuck:

1. Open `https://client-dev.keybuzz.io/api/auth/logout` once.
2. Return to `https://admin-dev.keybuzz.io`.
3. Open tenant detail.
4. Click `Assistance SaaS`.
5. Confirm Client opens and exits cleanly with `Quitter`.

