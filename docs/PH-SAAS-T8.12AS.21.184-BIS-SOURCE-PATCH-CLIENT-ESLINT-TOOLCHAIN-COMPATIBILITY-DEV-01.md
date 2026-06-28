# PH-SAAS-T8.12AS.21.184-BIS - SOURCE PATCH CLIENT ESLINT TOOLCHAIN COMPATIBILITY DEV

Date: 2026-06-28
Phase: PH-SAAS-T8.12AS.21.184-BIS
Type: SOURCE PATCH
Environment target: DEV source branch
Verdict: READY_NO_DEBTS

## Objective

Remove the Client lint toolchain debt found during PH-21.184 before continuing the PROD promotion chain.

Problem:

- Client uses ESLint 9.39.4 and Next 16.2.9.
- Source only had legacy `.eslintrc.json`.
- `npm run lint` still called `next lint`, which no longer works in the current Next version.
- Direct `npx eslint` hit the legacy config compatibility path and failed.

Goal:

- Restore `npm run lint`.
- Restore targeted `npx eslint`.
- Keep Next core-web-vitals rules.
- Remove lint errors and warnings.
- Avoid runtime/deploy/build side effects.

## Source Patch

Client branch:

`ph148/onboarding-activation-replay`

Client commit:

`e5b7491295fd4fe6e0210f8575104dcdda990a70`

Commit message:

`chore(client): restore eslint 9 lint compatibility`

## Files Changed

| File | Change | Risk |
| --- | --- | --- |
| `eslint.config.mjs` | Added ESLint 9 flat config using `FlatCompat` and `next/core-web-vitals` | Low |
| `package.json` | `lint` script changed from `next lint` to `eslint .` | Low |
| `app/billing/history/page.tsx` | Escaped JSX apostrophe | None |
| `app/settings/ai-supervision/page.tsx` | Escaped JSX apostrophe | None |
| `src/features/ai-ui/AISuggestionSlideOver.tsx` | Escaped JSX apostrophe; completed hook dependencies | Low |
| `src/features/demo/DemoBanner.tsx` | Escaped JSX apostrophe | None |
| `src/features/demo/DemoDashboardPreview.tsx` | Escaped JSX apostrophe | None |
| `src/features/demo/DemoInboxExperience.tsx` | Replaced `<img>` with `next/image` for marketplace icon | Low |
| `app/billing/options/page.tsx` | Moved provider logo map outside component to stabilize hook dependency | Low |
| `app/inbox/InboxTripane.tsx` | Completed hook dependencies | Low |
| `src/features/inbox/components/AISuggestionsPanel.tsx` | Completed hook dependencies | Low |

## Tests

| Test | Result |
| --- | --- |
| `git diff --check` | PASS |
| targeted `npx eslint app/channels/page.tsx src/services/amazon.service.ts src/features/billing/components/TrialBanner.tsx src/components/layout/ClientLayout.tsx` | PASS |
| `npm run lint` | PASS, 0 errors, 0 warnings |
| `node scripts/ph21182-post-oauth-trial-ux.test.cjs` | PASS |
| `node scripts/ph21172-start-latency-tests.mjs` | PASS |
| `npm run prebuild` | PASS |
| `npx tsc --noEmit --incremental false --pretty false` | PASS |

## Runtime / GitOps

No runtime action was executed.

Current runtime remains unchanged:

| Service | Runtime image | State |
| --- | --- | --- |
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.268-post-oauth-trial-readiness-dev` | generation 1032/1032, ready 1 |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.267-start-onboarding-latency-prod` | generation 434/434, ready 1 |

## Impact On PH-21.184 Build Artifacts

The PH-21.184 API local image remains valid because API source was not changed.

The PH-21.184 Client local image was built from previous commit `f349118c09db2228847575322669fae3c7577000`.

Because Client source now points to `e5b7491295fd4fe6e0210f8575104dcdda990a70`, the Client PROD image must be rebuilt before push. Do not push the old Client local image.

Recommended new Client PROD tag:

`ghcr.io/keybuzzio/keybuzz-client:v3.5.269-eslint-toolchain-post-oauth-trial-readiness-prod`

## No Fake Metrics / No Fake Events

Confirmed:

- 0 build Docker.
- 0 docker push.
- 0 GitOps apply.
- 0 deploy.
- 0 DB mutation.
- 0 Stripe write.
- 0 checkout.
- 0 fake event.
- 0 CAPI test.

## AI Feature Parity / Anti-Regression

No AI product behavior was intentionally changed.

Guarded areas:

- Inbox dependency warning fixed without changing visible UX.
- AI suggestion panel dependency warning fixed without changing visible UX.
- AI suggestion slide-over dependency warning fixed without changing visible UX.
- Playbooks, Agent KeyBuzz, KBActions, orders, connectors and billing runtime untouched.

The future AI response humanness improvement remains out of scope.

## Final Decision

Verdict: READY_NO_DEBTS.

Recommended next GO:

`GO BUILD CLIENT POST-OAUTH TRIAL READINESS PROD AFTER ESLINT FIX PH-SAAS-T8.12AS.21.184-TER`
