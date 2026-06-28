# PH-SAAS-T8.12AS.21.186 - Apply API Client post-OAuth trial readiness PROD GitOps

## Verdict

GO APPLY API CLIENT POST-OAUTH TRIAL READINESS PROD GITOPS READY PH-SAAS-T8.12AS.21.186.

## GitOps

| Item | Value |
| --- | --- |
| Infra deploy commit | dfcdc71 |
| API manifest | `k8s/keybuzz-api-prod/deployment.yaml` |
| Client manifest | `k8s/keybuzz-client-prod/deployment.yaml` |
| Apply method | `kubectl apply -f` only |
| Rollout | API successful, Client successful |

## Manifest changes

Only the two container image lines changed.

| Service | Before | After |
| --- | --- | --- |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.275-ai-journal-startup-ddl-prod` | `ghcr.io/keybuzzio/keybuzz-api:v3.5.277-playbooks-read-repair-prod` |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.267-start-onboarding-latency-prod` | `ghcr.io/keybuzzio/keybuzz-client:v3.5.269-eslint-toolchain-post-oauth-trial-readiness-prod` |

## Images

| Service | Runtime digest | Source | Rollback |
| --- | --- | --- | --- |
| API PROD | sha256:1b6d466a955c9a647248a424e79a446dbd9887caeb4210f17988357d156ba4a3 | 485a3f5a4f33daa006a03e02a4d1d15d10e767f6 | `v3.5.275-ai-journal-startup-ddl-prod` |
| Client PROD | sha256:9dc1fa7122a58a1a9195f5612463d76ef5e3f538afe99d7856cb5a28fe59c968 | 7658a74133b6c7c2ed0693d13ad7906bf793d4e4 | `v3.5.267-start-onboarding-latency-prod` |

## Validations

| Check | Result |
| --- | --- |
| `git diff --check` | PASS |
| `kubectl apply --dry-run=client` API/Client | PASS |
| `kubectl apply --dry-run=server` API/Client | PASS |
| API rollout | PASS |
| Client rollout | PASS |
| Manifest = last-applied = deployment spec | PASS |
| Pod imageID digest API | PASS |
| Pod imageID digest Client | PASS |
| API ready/restarts | 1/1, restarts 0 |
| Client ready/restarts | 1/1, restarts 0 |
| API health | HTTP 200 |
| Client `/register` passive smoke | HTTP 200 |
| Client `/start` passive smoke | HTTP 307 |
| Client runtime bundle API PROD marker | present, count 91 |
| Client runtime bundle API DEV marker | absent, count 0 |
| Critical logs post-rollout | API 0, Client 0 |

## Conversion/tracking safety

- No browser click.
- No form submission.
- No checkout.
- No fake event.
- No POST `/funnel/event` by CE.
- Runtime bundle contains existing billing/KBActions purchase strings; `StartTrial`, `CompletePayment`, and `InitiateCheckout` counts were 0 in the targeted audit.

## Non-regression

- Website DEV/PROD not changed.
- Admin DEV/PROD not changed.
- Backend DEV/PROD not changed.
- `latest` tags not changed.
- No Stripe write.
- No DB mutation.
- No secret read or displayed.
- No Webflow or Linear mutation.

## Next

GO READONLY VERIFY API CLIENT POST-OAUTH TRIAL READINESS PROD PH-SAAS-T8.12AS.21.187.

STOP.
