# PH-SAAS-T8.12AS.21.190 - Fix playbook trial metadata repair DEV PROD

## Verdict

GO FIX PLAYBOOK TRIAL METADATA REPAIR DEV PROD READY PH-SAAS-T8.12AS.21.190.

## Objective

Close the PH-21.189 gap where real trial tenants had starter playbooks present but inactive because the read-repair condition required `tenants.trial_entitlement_plan`, while real tenants stored trial truth in `tenant_metadata.is_trial` and `tenant_metadata.trial_ends_at`.

## Source patch

| Repo | Branch | Commit |
| --- | --- | --- |
| keybuzz-api | `ph147.4/source-of-truth` | 5656987a09b3b38e8dc5025d1d2d4de255e46406 |

Changed files:

| File | Change |
| --- | --- |
| `src/services/playbook-seed.service.ts` | Read-repair now accepts active trial tenants when `tenant.trial_entitlement_plan || tenant.selected_plan || tenant.plan` is present, while still requiring `tenant_metadata.is_trial=true` and future `trial_ends_at`. |
| `src/tests/ph21182-playbooks-read-repair-tests.ts` | Regression expectation updated for metadata trial tenants with null legacy entitlement field. |
| `src/tests/ph21182-starter-playbook-activation-tests.ts` | Regression expectation updated for real no-card/Stripe-trial metadata shape. |

## Tests

| Test | Result |
| --- | --- |
| `git diff --check` | PASS |
| `npx ts-node src/tests/ph21182-playbooks-read-repair-tests.ts` | PASS |
| `npx ts-node src/tests/ph21182-starter-playbook-activation-tests.ts` | PASS |
| `npx ts-node src/tests/ph21177-activate-amazon-idempotent-tests.ts` | PASS |
| `npx ts-node src/tests/ph21172-start-latency-tests.ts` | PASS |
| `npx tsc --noEmit` | PASS |

## DEV

| Item | Value |
| --- | --- |
| Image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.278-playbook-trial-metadata-repair-dev` |
| Digest | sha256:cdae6d425d435af93c9fe38eb99fcfd65e8a3af0f198be5334cf54b5d786d673 |
| Image ID | sha256:b7a6fb6e429338170b527714924dc3330db8b92863764d578647405b8aa31896 |
| GitOps deploy commit | 0dcef1a |
| Runtime | Ready 1/1, restarts 0 |

DEV functional validation:

| Tenant | Result |
| --- | --- |
| `ecomlg-mqxgrj2b` | GET `/playbooks` returned 15 starter playbooks, 15 active, 0 inactive |

## PROD

| Item | Value |
| --- | --- |
| Image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.278-playbook-trial-metadata-repair-prod` |
| Digest | sha256:83b9d2388b2e350c4c41bd647bb1104eaf12bac95e06755cad97b671c56b700f |
| Image ID | sha256:7edd10409d38f1498b5bbe55bfb6babcbb6b6266565a658d4c8939c4e9198cc8 |
| GitOps deploy commit | a5fcf99 |
| Runtime | Ready 1/1, restarts 0 |

PROD functional validation used the real GET `/playbooks` repair path for the two real test tenants:

| Tenant | Starter | Active | Inactive |
| --- | ---: | ---: | ---: |
| `switaa-sasu-mqwuvv8z` | 15 | 15 | 0 |
| `ecomlg-mqw7xv6f` | 15 | 15 | 0 |

## Post-fix safety

| Check | Result |
| --- | --- |
| API PROD `/health` | HTTP 200 |
| Client PROD `/register` | HTTP 200 |
| API critical logs | 0 |
| `conversion_events` last 24h | 0 |
| outbound failed last 24h | 0 |

## No side-effect

- No fake event.
- No checkout.
- No Stripe write.
- No secret read/display.
- No Webflow or Linear mutation.
- No Client/Website/Admin/Backend build or deploy.
- Runtime mutation intentionally limited to the idempotent product repair path that activates existing starter playbooks for verified trial tenants.

## Rollback

GitOps rollback only:

| Environment | Rollback image |
| --- | --- |
| DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.277-playbooks-read-repair-dev` |
| PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.277-playbooks-read-repair-prod` |

## Final status

No open technical debt remains for the playbook trial repair gap.

STOP.
