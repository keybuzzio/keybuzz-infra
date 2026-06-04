# PH-SAAS-T8.12AS.21.49 - Source config patch - LLM provider credit watcher PROD secret and API GitOps prep

Date UTC: 2026-06-04
Mode: SOURCE CONFIG PATCH only
Repo: keybuzz-infra
Branch: main
Start HEAD: 9285e00a
Source/config commit: 668df21f

## Objective

Prepare PROD source/config for the LLM provider credit watcher without any runtime apply.

This phase prepares:

- API PROD env and ExternalSecret metadata for a dedicated monitoring token.
- monitoring-alerts PROD target and dedicated token secretRef.
- GitOps/source tests for the PROD preparation.

This phase does not materialize or read any secret value and does not mutate runtime.

## Scope Applied

Changed source/config:

- `k8s/keybuzz-api-prod/deployment.yaml`
  - Added `LLM_PROVIDER_CREDIT_MONITOR_TOKEN`.
  - Source is `secretKeyRef` only: `monitoring-llm-provider-credit-token-prod/token`.
  - `optional: true` keeps API PROD boot-safe until OPS materializes the ExternalSecret.

- `k8s/keybuzz-api-prod/externalsecret-llm-provider-credit-monitor-token.yaml`
  - New ExternalSecret metadata for API PROD.
  - Vault remoteRef metadata: `secret/keybuzz/llm_provider_credit/prod/monitor_token`, property `value`.
  - No Secret, no stringData, no raw value.

- `k8s/keybuzz-api-prod/kustomization.yaml`
  - Added the new API PROD ExternalSecret resource.

- `k8s/monitoring-alerts/cronjob.yaml`
  - Switched `LLM_PROVIDER_CREDIT_TARGET_ENV` from `dev` to `prod` in source.
  - Switched `LLM_PROVIDER_CREDIT_TOKEN` secretRef to `monitoring-llm-provider-credit-token-prod/token`.
  - Kept global delivery safe:
    - `MONITORING_ALERTS_LOG_ONLY=true`
    - `ALERT_DELIVERY_MODE=log-only`
  - Kept watcher active/log-only:
    - `LLM_PROVIDER_CREDIT_DRY_RUN=false`
    - `LLM_PROVIDER_CREDIT_LOG_ONLY=true`

- `k8s/monitoring-alerts/externalsecret-llm-provider-credit-token-prod.yaml`
  - New ExternalSecret metadata for monitoring-alerts namespace.
  - Same PROD Vault remoteRef metadata as API PROD.
  - No Secret, no stringData, no raw value.

- Tests:
  - Updated PH-21.34, PH-21.39, PH-21.44 tests for the PROD source target.
  - Added PH-21.49 PROD prep test.

## Validation

All validation was offline or dry-run only.

- `git diff --check`: PASS
- YAML parse:
  - `k8s/keybuzz-api-prod/deployment.yaml`: PASS
  - `k8s/keybuzz-api-prod/kustomization.yaml`: PASS
  - `k8s/keybuzz-api-prod/externalsecret-llm-provider-credit-monitor-token.yaml`: PASS
  - `k8s/monitoring-alerts/cronjob.yaml`: PASS
  - `k8s/monitoring-alerts/externalsecret-llm-provider-credit-token-prod.yaml`: PASS
- Offline tests:
  - `k8s/tests/ph2128-monitoring-alerts-tests.sh`: PASS
  - `k8s/tests/ph2134-llm-provider-credit-watcher-secret-config-tests.sh`: PASS
  - `k8s/tests/ph2139-monitoring-alerts-delivery-safety-tests.sh`: PASS
  - `k8s/tests/ph2144-llm-provider-credit-watcher-activation-tests.sh`: PASS
  - `k8s/tests/ph2149-llm-provider-credit-watcher-prod-prep-tests.sh`: PASS
- `kubectl apply --dry-run=client -f ...`: PASS for the four changed/apply-target manifests.
- `kubectl apply --dry-run=server -f ...`: PASS for the four changed/apply-target manifests.
- Sensitive-pattern scan on new ExternalSecrets: PASS.

## Explicit Non-Actions

- No push.
- No real `kubectl apply`.
- No CronJob trigger.
- No Slack/email/webhook delivery.
- No secret value created, read, copied, or displayed.
- No build.
- No docker push.
- No DB mutation.
- No LLM call.
- No fake event.
- No Linear action.
- No runtime PROD mutation.

## Remaining Gates

- The PROD Vault value must be materialized by OPS at the expected PROD metadata path before apply.
- The API PROD runtime endpoint gate from PH-21.48 must still be handled in the PROD apply chain:
  - PH-21.48 observed current API PROD endpoint markers absent.
  - This phase prepares env/secret GitOps only.
- The monitoring-alerts source now targets PROD, but runtime remains unchanged until a later explicit GitOps apply phase.
- Global delivery remains log-only by default. Real Slack/email delivery stays out of scope.

## Verdict

`GO SOURCE CONFIG PATCH LLM PROVIDER CREDIT WATCHER PROD SECRET AND API GITOPS PREP READY_FOR_PUSH PH-SAAS-T8.12AS.21.49`

## Next GO

Immediate next GO:

`GO PUSH SOURCE CONFIG PATCH LLM PROVIDER CREDIT WATCHER PROD SECRET AND API GITOPS PREP PH-SAAS-T8.12AS.21.49`

Then in separate phases:

1. OPS materializes the PROD secret value in Vault without exposing it.
2. GitOps PROD apply only after source push and secret materialization are confirmed.
