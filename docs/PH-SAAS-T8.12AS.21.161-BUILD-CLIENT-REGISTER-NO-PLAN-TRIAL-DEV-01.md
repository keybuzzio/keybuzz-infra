# PH-SAAS-T8.12AS.21.161 - Build Client register no-plan trial DEV

Date: 2026-06-27

## Verdict

READY_WITH_DEBTS.

## Image

Image locale construite:

`ghcr.io/keybuzzio/keybuzz-client:v3.5.263-register-no-plan-trial-dev`

Image ID:

`sha256:100700b117c4dce5c0938a7eee79e1958779cef26be27d446f60935be0a46a17`

Source Git build:

`39b0e97f9f92521481aea532154a15cf18b01f6e`

Build-from-git propre:

`/tmp/ph21161-client-build-20260627T095809Z`

## Build Args DEV

| Build arg | Value |
| --- | --- |
| `NEXT_PUBLIC_APP_ENV` | `development` |
| `NEXT_PUBLIC_API_URL` | `https://api-dev.keybuzz.io` |
| `NEXT_PUBLIC_API_BASE_URL` | `https://api-dev.keybuzz.io` |
| `NEXT_PUBLIC_GA4_MEASUREMENT_ID` | `G-R3QQDYEBFG` |
| `NEXT_PUBLIC_META_PIXEL_ID` | empty |
| `NEXT_PUBLIC_SGTM_URL` | empty |
| `NEXT_PUBLIC_TIKTOK_PIXEL_ID` | empty |
| `NEXT_PUBLIC_LINKEDIN_PARTNER_ID` | `9969977` |
| `NEXT_PUBLIC_CLARITY_PROJECT_ID` | `wuk12h9i33` |
| `IMAGE_REVISION` | `39b0e97f9f92521481aea532154a15cf18b01f6e` |
| `IMAGE_VERSION` | `v3.5.263-register-no-plan-trial-dev` |

## Audit Image

| Check | Result |
| --- | --- |
| Docker build | PASS |
| OCI revision label | `39b0e97f9f92521481aea532154a15cf18b01f6e` |
| OCI version label | `v3.5.263-register-no-plan-trial-dev` |
| Global API DEV marker | `88` |
| Global API PROD marker | `0` |
| Register files identified | PASS |
| Register `register-trial-access-card` | `2` |
| Register `register-plan-grid` | `0` |
| Register `register-step-plan` | `0` |
| Register `register_continue_to_plan` | `0` |
| Register `/api/tenant-context/no-card-trial` | `2` |
| Register `/api/billing/checkout-session` | `0` |
| Register `StartTrial` | `0` |
| Register `Purchase` | `0` |
| Register `CompletePayment` | `0` |
| Register `InitiateCheckout` | `0` |

## Important Audit Note

The first broad bundle audit found `/api/billing/checkout-session=9` and `Purchase=7` globally. This is the same non-blocking global-bundle condition already documented in PH-21.139.

The corrected register-scoped audit checks only:

- `/app/.next/server/app/register`
- `/app/.next/static/chunks/app/register`

On that register surface, checkout and fake conversion markers are absent.

## Registry / Runtime

| Surface | Result |
| --- | --- |
| GHCR target tag before build | absent |
| GHCR target tag after local build | absent |
| Docker push | not executed |
| Client DEV runtime | unchanged |
| Client PROD runtime | unchanged |
| GitOps manifests | unchanged |
| `latest` | untouched |

## Source Tests Reused From PH-21.160

| Test | Result |
| --- | --- |
| `git diff --check` | PASS |
| `node scripts/ph21160-register-no-plan-selection.test.cjs` | PASS |
| `node scripts/ph21138-no-card-trial-onboarding.test.cjs` | PASS |
| `node scripts/ph2186-register-started-attribution.test.cjs` | PASS |
| targeted ESLint | PASS |
| global `tsc --noEmit` | FAIL_PREEXISTING `.next/types/app/api/debug-env/route.ts` |

## No Side Effects

- No docker push.
- No deploy.
- No kubectl apply.
- No DB mutation.
- No real event.
- No fake event.
- No form submission.
- No checkout.
- No Stripe write.
- No Webflow change.
- No Linear change.

## Next Step

GO PUSH IMAGE CLIENT REGISTER NO-PLAN TRIAL DEV PH-SAAS-T8.12AS.21.162
