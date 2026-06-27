# PH-SAAS-T8.12AS.21.160 - Source patch Client register no-plan selection DEV

Date: 2026-06-27

## Verdict

READY_FOR_BUILD_DEV.

## Objective

Remove the commercial plan selection from `client-dev.keybuzz.io/register`.

The register flow now collects the user and company information, then starts the 14-day no-card trial directly. The technical trial entitlement remains Autopilot/full access. The commercial plan and payment card are deferred to the SaaS conversion flow after the trial has started.

## Scope

Repository: `/opt/keybuzz/keybuzz-client`

Branch: `ph148/onboarding-activation-replay`

Source commit pushed: `39b0e97f9f92521481aea532154a15cf18b01f6e`

Files changed:

| File | Change | Risk |
| --- | --- | --- |
| `app/register/page.tsx` | Removed register plan step, plan cards, cycle toggle, plan recap, and plan-back actions. User submit now starts no-card trial directly. | Medium |
| `scripts/ph21160-register-no-plan-selection.test.cjs` | Adds source guard against reintroducing register plan selection or checkout/fake conversion triggers. | Low |

## Product Decision

Register no longer asks the user to choose Starter/Pro/Autopilot.

Trial starts with full Autopilot-capability access for 14 days, without card.

Plan selection and card capture must happen later inside the SaaS conversion flow.

## Preserved Features

- Magic-code email register flow.
- Google OAuth path.
- Company details collection.
- User details and CGU acceptance.
- Marketing attribution and `register_started` properties.
- `marketing_owner_tenant_id`, UTM and click ID forwarding.
- No-card trial BFF route.
- Redirect to dashboard after successful trial activation.
- KBActions and entitlement model unchanged in this patch.

## Tracking Safety

No browser-side business conversion event was added.

Forbidden conversion/event triggers remain absent from the register source:

- `StartTrial`
- `Purchase`
- `CompletePayment`
- `InitiateCheckout`
- Stripe checkout redirect
- fake `/funnel/event`

## Tests

| Test | Result |
| --- | --- |
| `git diff --check` | PASS |
| `node scripts/ph21160-register-no-plan-selection.test.cjs` | PASS |
| `node scripts/ph21138-no-card-trial-onboarding.test.cjs` | PASS |
| `node scripts/ph2186-register-started-attribution.test.cjs` | PASS |
| `npx eslint app/register/page.tsx app/api/tenant-context/no-card-trial/route.ts src/features/pricing/config.ts src/features/billing/planCapabilities.ts` | PASS |
| `npx tsc --noEmit --pretty false` | FAIL_PREEXISTING: `.next/types/app/api/debug-env/route.ts` references missing `app/api/debug-env/route.js` |

## No Side Effects

- No build.
- No docker push.
- No deploy.
- No kubectl apply.
- No DB mutation.
- No form submission.
- No checkout.
- No fake event.
- No Stripe write.
- No Webflow change.
- No Linear change.

## Known Debt

- `tsconfig.tsbuildinfo` remains dirty and was not staged.
- Global TypeScript still fails on the preexisting `.next/types/app/api/debug-env/route.ts` debt.
- API currently receives `plan=AUTOPILOT` as technical trial entitlement. Future cleanup should separate trial entitlement from commercial plan storage if the product model requires no selected plan at all in tenant metadata.

## Next Step

GO BUILD CLIENT REGISTER NO-PLAN TRIAL DEV PH-SAAS-T8.12AS.21.161
