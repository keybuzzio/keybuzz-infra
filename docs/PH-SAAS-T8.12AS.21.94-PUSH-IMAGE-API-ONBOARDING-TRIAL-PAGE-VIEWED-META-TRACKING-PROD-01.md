# PH-SAAS-T8.12AS.21.94 - PUSH IMAGE API onboarding trial_page_viewed Meta tracking PROD

## Scope

- Mode: PUSH IMAGE API PROD only.
- Pushed only: `ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod`.
- No build/rebuild, no latest tag, no deploy, no kubectl apply, no DB mutation.
- No POST /funnel/event, no form, no checkout, no CAPI test, no fake event, no Linear mutation.

## Sources Relues

| Source | Status |
| --- | --- |
| PH-21.94 mission | Read |
| AI_MEMORY CURRENT_STATE / RULES_AND_RISKS / DOCUMENT_MAP / CE_PROMPTING_STANDARD | Read |
| PH-T8.10J model | Read |
| PH-21.92 and PH-21.93 returns | Read |
| Infra docs PH-21.79 / PH-21.80 / PH-21.84 / PH-21.92 / PH-21.93 | Available on bastion |

## Preflight

| Control | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| Host | install-v3 | install-v3 | PASS |
| IPv4 | 46.62.171.61 | 46.62.171.61 | PASS |
| UTC | displayed | 2026-06-23T06:44:31Z | PASS |
| Kube context | kubernetes-admin@kubernetes | kubernetes-admin@kubernetes | PASS |

## Repositories

| Repo | Branch | HEAD | Origin | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | ---: | --- |
| keybuzz-api | ph147.4/source-of-truth | 35673e3b16f4 | 35673e3b16f4 | 0/0 | 223 | DIRTY_DOCUMENTED |
| keybuzz-infra | main | adb18e9553d3 | adb18e9553d3 | 0/0 | 0 | PASS |
| keybuzz-client | ph148/onboarding-activation-replay | d9631ca087f1 | d9631ca087f1 | 0/0 | 1 | DIRTY_DOCUMENTED |
| keybuzz-website | main | bd32fc8bc9d9 | bd32fc8bc9d9 | 0/0 | 0 | PASS |
| keybuzz-admin-v2 | main | 3707c834d7bf | 3707c834d7bf | 0/0 | 0 | PASS |
| keybuzz-backend | main | c38583a8548e | c38583a8548e | 0/0 | 1 | DIRTY_DOCUMENTED |

## Local Image Pre-push

| Control | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| Tag local | present | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | PASS |
| Image ID | sha256:cc0e2420ac16660d7e45e3ea906a775ff4d02b42a64464001cea6aea0bf92f0b | sha256:cc0e2420ac16660d7e45e3ea906a775ff4d02b42a64464001cea6aea0bf92f0b | PASS |
| OCI revision | 35673e3b16f4843d6144c24a0ad9926e28525ed4 | 35673e3b16f4843d6144c24a0ad9926e28525ed4 | PASS |
| OCI version | v3.5.264-onboarding-trial-page-viewed-meta-prod | v3.5.264-onboarding-trial-page-viewed-meta-prod | PASS |
| OCI source | keybuzz-api | https://github.com/keybuzzio/keybuzz-api | PASS |
| RepoDigest local | absent before push acceptable | [] | PASS |

## Image Audit Before Push

| Control | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| trial_page_viewed | present | 7 | PASS |
| helper | present | 2 | PASS |
| Meta mapping | present | 1 | PASS |
| StartTrial | present | 9 | PASS |
| Purchase | present | 12 | PASS |
| PROVIDER_CREDIT_EXHAUSTED | present | 13 | PASS |
| llm-provider-errors | present | 4 | PASS |
| dist/tests | absent | absent | PASS |
| PH-21.79 tests | absent | 0 | PASS |
| fake CompletePayment in Meta/emitter | absent | 0 | PASS |
| fake InitiateCheckout in Meta/emitter | absent | 0 | PASS |
| test token markers | absent | 0 | PASS |

## Registry And Pull-back

| Control | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| Target remote before push | absent | ABSENT | PASS |
| Manifest digest GHCR | sha256 | sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | PASS |
| RepoDigest pull-back | ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | PASS |
| Pull-back Image ID/config | sha256:cc0e2420ac16660d7e45e3ea906a775ff4d02b42a64464001cea6aea0bf92f0b | sha256:cc0e2420ac16660d7e45e3ea906a775ff4d02b42a64464001cea6aea0bf92f0b | PASS |
| Pull-back OCI revision | 35673e3b16f4843d6144c24a0ad9926e28525ed4 | 35673e3b16f4843d6144c24a0ad9926e28525ed4 | PASS |
| latest hash | unchanged | 71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549 -> 71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549 | PASS |

## Image Audit After Pull-back

| Control | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| trial_page_viewed | present | 7 | PASS |
| helper | present | 2 | PASS |
| Meta mapping | present | 1 | PASS |
| StartTrial | present | 9 | PASS |
| Purchase | present | 12 | PASS |
| PROVIDER_CREDIT_EXHAUSTED | present | 13 | PASS |
| llm-provider-errors | present | 4 | PASS |
| dist/tests | absent | absent | PASS |
| PH-21.79 tests | absent | 0 | PASS |

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
- Later apply/rollback must remain GitOps-only.

## No Fake Metrics / No Fake Events

| Item | Count |
| --- | ---: |
| docker build/rebuild | 0 |
| docker push latest | 0 |
| deploy / kubectl apply | 0 |
| DB mutation | 0 |
| POST /funnel/event | 0 |
| Form submission | 0 |
| Checkout | 0 |
| CAPI test | 0 |
| LLM call | 0 |
| Linear mutation | 0 |

## Final Verdict

DONE PH-SAAS-T8.12AS.21.94.

Next GO:

```text
GO APPLY API ONBOARDING TRIAL_PAGE_VIEWED META TRACKING PROD GITOPS PH-SAAS-T8.12AS.21.95
```
