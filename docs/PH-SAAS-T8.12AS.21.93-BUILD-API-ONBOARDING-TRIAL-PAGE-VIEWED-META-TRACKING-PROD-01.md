# PH-SAAS-T8.12AS.21.93 - BUILD API onboarding trial_page_viewed Meta tracking PROD

## Scope

- Mode: BUILD API PROD local only.
- Built local Docker image only: `ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod`.
- No docker push, no deploy, no kubectl apply, no DB mutation, no real/fake event.
- No POST /funnel/event, no form, no checkout, no CAPI test, no Linear mutation.

## Sources Relues

| Source | Status |
| --- | --- |
| PH-21.93 mission | Read |
| AI_MEMORY CURRENT_STATE / RULES_AND_RISKS / DOCUMENT_MAP / CE_PROMPTING_STANDARD | Read |
| PH-T8.10J model | Read |
| PH-21.79 / PH-21.80 / PH-21.84 / PH-21.85 / PH-21.92 returns | Read |
| Infra docs PH-21.79 / PH-21.80 / PH-21.84 / PH-21.92 | Present on bastion |

## Preflight

| Control | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| Host | install-v3 | install-v3 | PASS |
| IPv4 | 46.62.171.61 | 46.62.171.61 | PASS |
| UTC | displayed | 2026-06-23T06:34:07Z | PASS |
| Kube context | kubernetes-admin@kubernetes | kubernetes-admin@kubernetes | PASS |

## Repositories

| Repo | Branch | HEAD | Origin | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | ---: | --- |
| keybuzz-api | ph147.4/source-of-truth | 35673e3b16f4 | 35673e3b16f4 | 0/0 | 223 | DIRTY_DOCUMENTED |
| keybuzz-infra | main | f1d752a64e97 | f1d752a64e97 | 0/0 | 0 | PASS |
| keybuzz-client | ph148/onboarding-activation-replay | d9631ca087f1 | d9631ca087f1 | 0/0 | 1 | DIRTY_DOCUMENTED |
| keybuzz-website | main | bd32fc8bc9d9 | bd32fc8bc9d9 | 0/0 | 0 | PASS |
| keybuzz-admin-v2 | main | 3707c834d7bf | 3707c834d7bf | 0/0 | 0 | PASS |
| keybuzz-backend | main | c38583a8548e | c38583a8548e | 0/0 | 1 | DIRTY_DOCUMENTED |

Note: keybuzz-api main workspace dirty is pre-existing generated dist debt; build was not made from that workspace.

## Source Build

| Control | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| Build dir | /tmp/ph2193-* | /tmp/ph2193-api-build-20260623063407 | PASS |
| Commit | 35673e3b16f4843d6144c24a0ad9926e28525ed4 | 35673e3b16f4843d6144c24a0ad9926e28525ed4 | PASS |
| Remote | keybuzz-api GitHub | https://github.com/keybuzzio/keybuzz-api.git | PASS |
| Status | clean | 0 | PASS |

## Registry Before And After

| Control | Before | After | Verdict |
| --- | --- | --- | --- |
| Target tag remote | ABSENT | ABSENT | PASS |
| latest manifest hash | 71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549 | 71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549 | PASS |
| Docker push | forbidden | not executed | PASS |

## Pre-build Tests

| Test | Expected | Result | Verdict |
| --- | --- | --- | --- |
| git diff --check | PASS | PASS | PASS |
| tsc --noEmit | PASS | PASS | PASS |
| PH-21.79 compile + Node | PASS | PASS | PASS |

## Local Image Build

| Image | Source commit | Image ID | Size | Labels | Verdict |
| --- | --- | --- | ---: | --- | --- |
| ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | 35673e3b16f4843d6144c24a0ad9926e28525ed4 | sha256:cc0e2420ac16660d7e45e3ea906a775ff4d02b42a64464001cea6aea0bf92f0b | 346845048 | revision=35673e3b16f4843d6144c24a0ad9926e28525ed4; version=v3.5.264-onboarding-trial-page-viewed-meta-prod; source=https://github.com/keybuzzio/keybuzz-api | PASS |

RepoDigest: [], expected because no docker push was executed.

## Image Audit

| Control | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| trial_page_viewed | present | 7 | PASS |
| helper | present | 2 | PASS |
| Meta custom mapping | present | 1 | PASS |
| StartTrial | present | 9 | PASS |
| Purchase | present | 12 | PASS |
| PROVIDER_CREDIT_EXHAUSTED | present | 13 | PASS |
| llm-provider-errors | present | 4 | PASS |
| dist/tests | absent | absent | PASS |
| PH-21.79 tests | absent | 0 | PASS |
| fake CompletePayment in Meta/emitter | absent | 0 | PASS |
| fake InitiateCheckout in Meta/emitter | absent | 0 | PASS |
| test token markers | absent | 0 | PASS |

## Runtime Read-only Non-regression

| Service | Env | Expected / Baseline | Observed image | Pod imageID | Ready | Restarts | Verdict |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| API | DEV | v3.5.264 dev | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | ghcr.io/keybuzzio/keybuzz-api@sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669 | true | 0 | PASS |
| API | PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod / sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6 | ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod | ghcr.io/keybuzzio/keybuzz-api@sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6 | true | 0 | PASS |
| Client | DEV | v3.5.260 owner payload dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | ghcr.io/keybuzzio/keybuzz-client@sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | true | 0 | PASS |
| Client | PROD | v3.5.259 baseline | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod | ghcr.io/keybuzzio/keybuzz-client@sha256:e63494dbe83368a300df4d199b6443ccef6442b5428edeca6cf94433b5abf791 | true | 0 | PASS |

Runtime snapshots before/after were byte-identical.

## Rollback Reference

- Current API PROD rollback image: `ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod`.
- Current API PROD rollback digest: `sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6`.
- Rollback must remain GitOps-only in a later deploy phase; no imperative kubectl commands.

## No Fake Metrics / No Fake Events

| Item | Count |
| --- | ---: |
| Docker push | 0 |
| Deploy / kubectl apply | 0 |
| DB mutation | 0 |
| POST /funnel/event | 0 |
| Form submission | 0 |
| Checkout | 0 |
| CAPI test | 0 |
| LLM call | 0 |
| Linear mutation | 0 |

## Final Verdict

READY PH-SAAS-T8.12AS.21.93.

Next GO:

```text
GO PUSH IMAGE API ONBOARDING TRIAL_PAGE_VIEWED META TRACKING PROD PH-SAAS-T8.12AS.21.94
```
