# PH-SAAS-T8.12AS.21.218 - FIX CLIENT DEV SHELL ROUTE ENTITLEMENT BYPASS

Date: 2026-06-29

## Verdict

READY_FOR_BROWSER_RETEST_DEV.

## Incident

After support logout, multiple browsers stayed on:

`Preparation de votre espace...`

This happened even after `/api/auth/logout` was fixed and no longer returned `502`.

## Root cause

`/login` was correctly configured as:

- `PUBLIC_ROUTES`
- `SHELL_BYPASS_ROUTES`

However, the component tree is:

`AuthGuard -> I18nProvider -> PlanProvider -> EntitlementGuard -> LayoutContent`

`LayoutContent` bypassed shell routes, but `EntitlementGuard` ran before `LayoutContent`.

Because `/login` was not explicitly exempted from `EntitlementGuard`, an unauthenticated/no-tenant browser could hit the tenant guard and render:

`Preparation de votre espace...`

## Fix

Client source commit:

- `405f54f` - `fix(client): bypass entitlement guard on shell routes`

Runtime Client DEV:

- Image: `ghcr.io/keybuzzio/keybuzz-client:v3.5.276-shell-route-entitlement-bypass-dev`
- GHCR digest: `sha256:7a9e05da4003b09c411de2d95955df861b50e57e7bc07e0ecf3167563a499f92`
- Source: `405f54f`
- Rollback: `v3.5.275-support-logout-502-fix-dev`

Implementation:

- `EntitlementGuard` now bypasses routes when:
  - `isShellBypassRoute(pathname)` OR
  - `isBillingExemptRoute(pathname)`

This preserves billing locks for normal authenticated SaaS routes while allowing `/login`, `/logout`, `/support/impersonate`, `/select-tenant`, etc. to render without tenant context.

## Validation

| Check | Result |
| --- | --- |
| Client support/static test | PASS |
| TypeScript | PASS |
| ESLint | PASS |
| Build from clean Git | PASS |
| Client DEV bundle contains `https://api-dev.keybuzz.io` | PASS |
| Client DEV bundle contains `https://api.keybuzz.io` | PASS, 0 occurrence |
| Runtime marker `isGuardExempt` | PASS |
| GHCR push/pull-back | PASS |
| GitOps image-only patch | PASS |
| Dry-run client/server | PASS |
| Rollout DEV | PASS |
| Public `/api/auth/logout` | PASS, HTTP 302 to `/login` |
| Public `/login` | PASS, HTTP 200 |
| Public `/login` contains `Preparation de votre espace` | PASS, absent |
| Public `/support/impersonate` | PASS, HTTP 200 |

## Current DEV runtime

- Admin DEV: `ghcr.io/keybuzzio/keybuzz-admin:v2.12.3-support-impersonation-dev`
- Client DEV: `ghcr.io/keybuzzio/keybuzz-client:v3.5.276-shell-route-entitlement-bypass-dev`

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

Expected:

- redirect to `/login`;
- login page renders;
- no `502`;
- no `Preparation de votre espace`.

Then retest Admin DEV -> Tenant -> `Assistance SaaS` -> `Quitter`.

