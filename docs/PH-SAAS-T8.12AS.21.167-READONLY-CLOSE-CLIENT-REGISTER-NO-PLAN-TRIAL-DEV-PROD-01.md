# PH-SAAS-T8.12AS.21.167 - Close Client register no-plan trial DEV/PROD

Date: 2026-06-27

## Verdict

READY_CLOSED.

## Product Outcome

The register flow no longer asks the user to choose Starter/Pro/Autopilot before starting the trial.

The flow now collects account, company and user details, then starts a 14-day no-card trial directly.

The trial technical entitlement remains full Autopilot access. Plan selection and card capture are deferred to the SaaS conversion flow after trial activation.

## Source

| Repo | Branch | Commit | Status |
| --- | --- | --- | --- |
| `keybuzz-client` | `ph148/onboarding-activation-replay` | `39b0e97f9f92521481aea532154a15cf18b01f6e` | pushed, ahead/behind `0/0` |
| `keybuzz-infra` | `main` | `062cf58e9f78f8f441697716a65dd46366d90431` | pushed, ahead/behind `0/0` |

Client dirty state:

`tsconfig.tsbuildinfo` remains a preexisting unstaged local generated-file debt and was not committed.

## DEV Runtime

| Check | Result |
| --- | --- |
| Image | `ghcr.io/keybuzzio/keybuzz-client:v3.5.263-register-no-plan-trial-dev` |
| Digest | `sha256:1ca7dba82b7853c53ece031798f4afc8c7c07633b2c115b317a8d70ecfae7d2c` |
| Ready | `1/1` |
| Pod | `keybuzz-client-5849bb7fd5-b5ng7` |
| Restarts | `0` |
| Manifest = last-applied = spec = pod | PASS |

## PROD Runtime

| Check | Result |
| --- | --- |
| Image | `ghcr.io/keybuzzio/keybuzz-client:v3.5.263-register-no-plan-trial-prod` |
| Digest | `sha256:bdcaa49061827c68d7bdab42f0383b2a240c82683ddf7920630178db9b364362` |
| Ready | `1/1` |
| Pod | `keybuzz-client-8df98946f-96vf2` |
| Restarts | `0` |
| Manifest = last-applied = spec = pod | PASS |

## Register Audit

DEV and PROD register runtime audits passed.

| Check | DEV | PROD |
| --- | ---: | ---: |
| `register-trial-access-card` | `2` | `2` |
| `register-plan-grid` | `0` | `0` |
| `register-step-plan` | `0` | `0` |
| `register_continue_to_plan` | `0` | `0` |
| `/api/tenant-context/no-card-trial` | `2` | `2` |
| `/api/billing/checkout-session` | `0` | `0` |
| `StartTrial` | `0` | `0` |
| `Purchase` | `0` | `0` |
| `CompletePayment` | `0` | `0` |
| `InitiateCheckout` | `0` | `0` |

## Passive PROD Smoke

| Route | Result |
| --- | --- |
| `/` | PASS, non-empty HTML |
| `/register` | PASS, non-empty HTML |
| `/login` | PASS, non-empty HTML |

## Build Safety

| Control | Result |
| --- | --- |
| Build-from-git | PASS |
| DEV bundle API URL | `https://api-dev.keybuzz.io` present, PROD API absent |
| PROD bundle API URL | `https://api.keybuzz.io` present, DEV API absent |
| Immutable tags | PASS |
| `latest` untouched | PASS |
| GitOps strict | PASS |
| `kubectl set image/env/patch/edit` | not used |

## Tracking / Billing Safety

- No browser JS execution.
- No form submission.
- No checkout.
- No Stripe write.
- No DB mutation.
- No real event.
- No fake event.
- No StartTrial/Purchase/CompletePayment pollution.

## Remaining Product Debt

1. The API still receives `plan=AUTOPILOT` as the technical entitlement for the trial. If the product model must store no commercial plan at all until conversion, a later API/data-model patch should separate `trial_entitlement_plan` from `selected_plan`.
2. The in-SaaS conversion path must now become the primary place to choose Starter/Pro/Autopilot and add card details.
3. Full end-to-end signup was intentionally not executed by CE/Codex to avoid creating real users, DB mutations and tracking events.
4. Global TypeScript still has the preexisting `.next/types/app/api/debug-env/route.ts` debt.
5. `tsconfig.tsbuildinfo` remains dirty in the Client worktree and was left untouched.

## No Further Technical GO Required For This Chain

The requested register/onboarding change is live on DEV and PROD with runtime verification.
