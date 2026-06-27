# PH-SAAS-T8.12AS.21.163 - Apply Client register no-plan trial DEV GitOps

Date: 2026-06-27

## Verdict

READY.

## GitOps

Manifest changed:

`k8s/keybuzz-client-dev/deployment.yaml`

Deploy commit pushed before apply:

`ba2ae10`

Applied command:

`kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml`

Rollout:

`deployment "keybuzz-client" successfully rolled out`

## Runtime DEV

| Check | Result |
| --- | --- |
| Runtime image | `ghcr.io/keybuzzio/keybuzz-client:v3.5.263-register-no-plan-trial-dev` |
| Runtime digest | `sha256:1ca7dba82b7853c53ece031798f4afc8c7c07633b2c115b317a8d70ecfae7d2c` |
| Pod | `keybuzz-client-5849bb7fd5-b5ng7` |
| Ready | `1/1` |
| Generation | `1027/1027` |
| Restarts | `0` |
| Git manifest image | PASS |
| Last-applied image | PASS |
| Deployment spec image | PASS |
| Pod image | PASS |
| Pod imageID digest | PASS |

## Register Runtime Audit

| Check | Result |
| --- | --- |
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
| passive GET `/register` bytes | `9285` |

## No Side Effects

- No manual trigger.
- No form submission.
- No checkout.
- No Stripe write.
- No DB mutation.
- No real event.
- No fake event.
- No Webflow change.
- No Linear change.
- PROD unchanged in this phase.

## Next Step

GO BUILD CLIENT REGISTER NO-PLAN TRIAL PROD PH-SAAS-T8.12AS.21.164
