# PH-SAAS-T8.12AS.21.209 - SOURCE PATCH ADMIN/CLIENT SUPPORT IMPERSONATION DEV

Date: 2026-06-29

## Verdict

READY_FOR_DEV_BUILD.

## Objective

Add a secure Admin -> Client support access path so a super_admin can open the SaaS as a tenant user for diagnosis and guided support, without mutating customer data by default.

## Source changes

| Repo | Branch | Commit | Scope |
| --- | --- | --- | --- |
| keybuzz-admin-v2 | main | fb7fc15 | Issue one-time support impersonation URLs from tenant detail page |
| keybuzz-client | ph148/onboarding-activation-replay | b3f4eeb | Consume support token, create read-only support session, show banner, block mutations |
| keybuzz-infra | main | pending | This report only |

## Security model

- Admin action restricted to NextAuth `super_admin`.
- Token generated server-side with `randomBytes(32)`.
- Only SHA-256 token hash persisted in `admin_impersonation_tokens`.
- Raw token appears only in the short-lived URL opened by Admin.
- Token TTL: 5 minutes.
- Support session TTL: 60 minutes.
- Token is one-time use; exchange marks `used_at` and `used_user_agent`.
- Audit events:
  - `SUPPORT_IMPERSONATION_ISSUED`
  - `SUPPORT_IMPERSONATION_EXCHANGED`
- Client displays a visible support banner.
- Client middleware blocks support-session mutations on `/api/*` for `POST`, `PUT`, `PATCH`, `DELETE`.
- Only these support-session mutation routes are allowed:
  - `/api/auth/callback/support-impersonation`
  - `/api/auth/select-tenant`
  - `/api/auth/logout`

## Admin details

- Added tenant detail action: `Assistance SaaS`.
- Added API route: `POST /api/admin/tenants/[id]/impersonation`.
- Added public token exchange route: `POST /api/auth/support-impersonation/exchange`.
- Added lazy table creation for `admin_impersonation_tokens`.
- Added Next standalone tracing include for `pg` on `/api/auth/support-impersonation/**`.

## Client details

- Added NextAuth credentials provider: `support-impersonation`.
- Added `/support/impersonate` landing page.
- Token removed from URL with `window.history.replaceState`.
- Client selects tenant after support sign-in then redirects to `/inbox`.
- Added support metadata to session/JWT types and `/api/auth/me`.
- Added route access guard entries for `/support/impersonate`.
- Added global middleware mutation guard for support sessions.

## Tests

| Test | Result |
| --- | --- |
| Admin `git diff --check` | PASS |
| Admin `tsc --noEmit` | PASS |
| Admin PH21.209 Node test | PASS |
| Client `git diff --check` | PASS |
| Client `tsc --noEmit` | PASS |
| Client `npm run lint` | PASS |
| Client PH21.209 Node test | PASS |
| Cross-repo static PH21.209 checks | PASS |

## Known tooling limits

- Admin global `npm run lint` is not used as a gate because the repo currently invokes interactive `next lint` configuration when no ESLint config is present. This is a pre-existing tooling limitation, not introduced by PH-21.209.

## No side-effect confirmation

- No Docker build.
- No Docker push.
- No GitOps manifest change.
- No `kubectl apply`.
- No runtime deploy.
- No DB mutation executed.
- No fake event.
- No tracking event.
- No checkout.
- No Stripe write.
- No secret read or displayed.
- No PROD runtime mutation.

## Next phase

Build DEV images from clean pushed Git commits:

- Admin DEV target tag: `ghcr.io/keybuzzio/keybuzz-admin-v2:v2.12.3-support-impersonation-dev` or repo-established equivalent.
- Client DEV target tag: `ghcr.io/keybuzzio/keybuzz-client:v3.5.272-support-impersonation-dev` or repo-established equivalent.

Before pushing any Client image, verify bundle safety:

- DEV bundle contains `https://api-dev.keybuzz.io`.
- DEV bundle does not contain `https://api.keybuzz.io`.

After DEV apply, verify:

- Admin tenant detail opens support session.
- Client banner is visible.
- Read-only middleware blocks non-auth mutations.
- Logout exits support session.
- Runtime image equals manifest and last-applied.

