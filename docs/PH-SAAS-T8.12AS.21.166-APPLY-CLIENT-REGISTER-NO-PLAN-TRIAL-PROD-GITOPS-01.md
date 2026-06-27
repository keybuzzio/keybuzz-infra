# PH-SAAS-T8.12AS.21.166 - Apply Client register no-plan trial PROD GitOps

Date: 2026-06-27

## Verdict

READY.

## GitOps

Manifest changed:

`k8s/keybuzz-client-prod/deployment.yaml`

Deploy commit pushed before apply:

`ea70464`

Applied command:

`kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml`

Rollout:

`deployment "keybuzz-client" successfully rolled out`

## Runtime PROD

| Check | Result |
| --- | --- |
| Runtime image | `ghcr.io/keybuzzio/keybuzz-client:v3.5.263-register-no-plan-trial-prod` |
| Runtime digest | `sha256:bdcaa49061827c68d7bdab42f0383b2a240c82683ddf7920630178db9b364362` |
| Pod | `keybuzz-client-8df98946f-96vf2` |
| Ready | `1/1` |
| Generation | `430/430` |
| Restarts | `0` |
| Git manifest image | PASS |
| Last-applied image | PASS |
| Deployment spec image | PASS |
| Pod image | PASS |
| Pod imageID digest | PASS |

## Register Runtime Audit

| Check | Result |
| --- | --- |
| Global API PROD marker | `88` |
| Global API DEV marker | `0` |
| `register-trial-access-card` | `2` |
| `register-plan-grid` | `0` |
| `register-step-plan` | `0` |
| `register_continue_to_plan` | `0` |
| `/api/tenant-context/no-card-trial` | `2` |
| `/api/billing/checkout-session` | `0` |
| `StartTrial` | `0` |
| `Purchase` | `0` |
| `CompletePayment` | `0` |
| `InitiateCheckout` | `0` |
| passive GET `/register` bytes | `9274` |

## Passive Route Smoke

| Route | Bytes | Result |
| --- | ---: | --- |
| `/` | `9046` | PASS |
| `/register` | `9274` | PASS |
| `/login` | `8849` | PASS |

## No Side Effects

- No browser JS execution.
- No form submission.
- No checkout.
- No Stripe write.
- No DB mutation.
- No real event.
- No fake event.
- No Webflow change.
- No Linear change.

## Next Step

GO READONLY CLOSE CLIENT REGISTER NO-PLAN TRIAL DEV PROD PH-SAAS-T8.12AS.21.167
