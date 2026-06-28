# PH-SAAS-T8.12AS.21.189 - Readonly verify post-OAuth trial readiness real user path PROD

## Verdict

GO READONLY VERIFY POST-OAUTH TRIAL READINESS REAL USER PATH PROD NO_GO_PLAYBOOK_TRIAL_REPAIR_GAP_FOUND PH-SAAS-T8.12AS.21.189.

## Runtime precheck

| Service | Image | Digest | Ready | Restarts |
| --- | --- | --- | --- | --- |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.277-playbooks-read-repair-prod` | sha256:1b6d466a955c9a647248a424e79a446dbd9887caeb4210f17988357d156ba4a3 | 1/1 | 0 |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.269-eslint-toolchain-post-oauth-trial-readiness-prod` | sha256:9dc1fa7122a58a1a9195f5612463d76ef5e3f538afe99d7856cb5a28fe59c968 | 1/1 | 0 |

## Passive HTTP

| Route | Result |
| --- | --- |
| API `/health` | HTTP 200 |
| Client `/register` | HTTP 200 |
| Client `/start` | HTTP 307 |
| Client `/billing` | HTTP 307 |
| Client `/channels` | HTTP 307 |
| Client `/playbooks` | HTTP 307 |

## Bundle safety

| Marker | Count |
| --- | --- |
| `https://api.keybuzz.io` | 91 |
| `https://api-dev.keybuzz.io` | 0 |
| `StartTrial` | 0 |
| `CompletePayment` | 0 |
| `InitiateCheckout` | 0 |

## Real user path data

Emails are masked in the report. Tenant resolution uses `user_tenants`, not `users.tenant_id`.

| User path | Tenant | Tenant status | Trial metadata | Billing |
| --- | --- | --- | --- | --- |
| PROD test no-card path | `switaa-sasu-mqwuvv8z` | active AUTOPILOT | `is_trial=true`, `trial_ends_at=2026-07-11T21:12:24.003Z` | no subscription row found |
| PROD test paid/Stripe path | `ecomlg-mqw7xv6f` | active AUTOPILOT | `is_trial=true`, `trial_ends_at=2026-07-11T10:30:06.162Z` | `trialing`, Stripe subscription present |

## Channels and OAuth

| Tenant | Channel state |
| --- | --- |
| `switaa-sasu-mqwuvv8z` | Amazon FR active in `tenant_channels`, inbound connection READY, inbound email present |
| `ecomlg-mqw7xv6f` | no channel found in this verification window |

## Gap found

Both real tenants had 15 starter playbooks created but inactive before the PH-21.190 fix:

| Tenant | Starter | Active | Inactive |
| --- | ---: | ---: | ---: |
| `switaa-sasu-mqwuvv8z` | 15 | 0 | 15 |
| `ecomlg-mqw7xv6f` | 15 | 0 | 15 |

Root cause: the read-repair condition in `playbook-seed.service.ts` required `tenants.trial_entitlement_plan`, but real no-card/Stripe-trial tenants stored the trial truth in `tenant_metadata.is_trial=true` and `tenant_metadata.trial_ends_at`, with `tenants.trial_entitlement_plan=null`.

## No fake metrics / no fake events

- 0 fake event.
- 0 checkout.
- 0 browser JS click/form by CE.
- 0 Stripe write.
- 0 secret read/display.
- 0 Webflow or Linear mutation.
- `conversion_events` last 24h count observed as 0.
- outbound failed last 24h count observed as 0.

## Decision

Do not close the chain at PH-21.189. Proceeded to PH-21.190 source/runtime fix.

STOP.
