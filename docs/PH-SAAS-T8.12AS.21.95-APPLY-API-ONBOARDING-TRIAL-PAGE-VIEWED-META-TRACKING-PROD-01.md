# PH-SAAS-T8.12AS.21.95 - APPLY API onboarding trial_page_viewed Meta tracking PROD

## Scope

- Mode: APPLY API PROD GitOps.
- Changed only manifest: `k8s/keybuzz-api-prod/deployment.yaml`.
- Applied only with `kubectl apply -f /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml`.
- No build, no docker push, no kubectl set image/env/patch/edit, no DB mutation, no event, no form, no checkout, no Linear.

## Sources Relues

| Source | Status |
| --- | --- |
| PH-21.95 mission | Read |
| AI_MEMORY CURRENT_STATE / RULES_AND_RISKS / DOCUMENT_MAP / CE_PROMPTING_STANDARD | Read |
| PH-T8.10J model | Read |
| PH-21.79 / PH-21.84 / PH-21.92 / PH-21.93 / PH-21.94 returns | Read |
| Infra docs PH-21.79 / 21.84 / 21.92 / 21.93 / 21.94 | Present on bastion |

## Preflight

| Control | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| Host | install-v3 | install-v3 | PASS |
| IPv4 | 46.62.171.61 | 46.62.171.61 | PASS |
| UTC | displayed | 2026-06-23T07:41:08Z | PASS |
| Kube context | kubernetes-admin@kubernetes | kubernetes-admin@kubernetes | PASS |

## Repositories

| Repo | Branch | HEAD | Origin | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | ---: | --- |
| keybuzz-infra | main | 6028c2705f95 | 6028c2705f95 | 0/0 | 0 | PASS |
| keybuzz-api | ph147.4/source-of-truth | 35673e3b16f4 | 35673e3b16f4 | 0/0 | 223 | DIRTY_DOCUMENTED |
| keybuzz-client | ph148/onboarding-activation-replay | d9631ca087f1 | d9631ca087f1 | 0/0 | 1 | DIRTY_DOCUMENTED |
| keybuzz-website | main | bd32fc8bc9d9 | bd32fc8bc9d9 | 0/0 | 0 | PASS |
| keybuzz-admin-v2 | main | 3707c834d7bf | 3707c834d7bf | 0/0 | 0 | PASS |
| keybuzz-backend | main | c38583a8548e | c38583a8548e | 0/0 | 1 | DIRTY_DOCUMENTED |

## Image Registry Gate

| Control | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| Target image | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | PASS |
| Manifest digest | sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | PASS |
| OCI revision | 35673e3b16f4843d6144c24a0ad9926e28525ed4 | documented PH-21.94 | PASS |
| latest hash | 71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549 | 71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549 -> 71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549 | PASS |
| Rollback image | ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod | sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6 | PASS |

## Manifest Diff And GitOps Commit

| Item | Value |
| --- | --- |
| Manifest | k8s/keybuzz-api-prod/deployment.yaml |
| Old image | ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod |
| New image | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod |
| Diff scope | one image line only |
| git diff --check | PASS |
| dry-run client | PASS |
| dry-run server | PASS |
| Deploy commit | 320021e9 |
| Commit pushed before apply | yes, ahead/behind 0/0 |

## Apply And Rollout

| Step | Result |
| --- | --- |
| kubectl apply -f manifest | PASS |
| rollout status deployment/keybuzz-api | PASS |
| Health GET localhost /health | PASS |
| Pod | keybuzz-api-6854bc98db-9mhjv |

## Runtime Equality

| Level | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| manifest | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | PASS |
| last-applied | contains new image | count 1 | PASS |
| deployment spec | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | PASS |
| pod spec | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | PASS |
| pod imageID | ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | PASS |
| ready/restarts | ready true | true / 0 | PASS |

## Runtime Marker Audit

| Marker | Expected | Observed | Verdict |
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

## DB / Logs Read-only

| Check | Result |
| --- | --- |
| DB snapshot before | DB_SNAPSHOT_OK |
| DB snapshot after | DB_SNAPSHOT_OK |
| Crash/fatal/unhandled log count tail 200 | 0 |
| Token-like log count tail 200 | 0 |
| DB mutation by CE | 0 |
| POST /funnel/event by CE | 0 |

DB snapshots, when available, were SELECT-only from the API pod inside BEGIN READ ONLY / ROLLBACK and reported counts only.

## Non-regression Services

| Service | Env | Observed image | Pod imageID | Verdict |
| --- | --- | --- | --- | --- |
| API | DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | ghcr.io/keybuzzio/keybuzz-api@sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669 | PASS |
| API | PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | PASS |
| Client | DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | ghcr.io/keybuzzio/keybuzz-client@sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | PASS |
| Client | PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod | ghcr.io/keybuzzio/keybuzz-client@sha256:e63494dbe83368a300df4d199b6443ccef6442b5428edeca6cf94433b5abf791 | PASS |

Website/Admin/Backend manifests were not touched. No Client, Website, Admin or Backend apply was executed.

## Rollback Reference

- Rollback image, if needed in a future phase: `ghcr.io/keybuzzio/keybuzz-api:v3.5.262-llm-provider-credit-alerting-prod`.
- Rollback digest: `sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6`.
- Rollback must be GitOps-only; no kubectl set image/patch/edit.

## No Fake Metrics / No Fake Events

| Item | Count |
| --- | ---: |
| build | 0 |
| docker push | 0 |
| kubectl set image/env/patch/edit | 0 |
| DB mutation | 0 |
| POST /funnel/event | 0 |
| Form submission | 0 |
| Checkout | 0 |
| CAPI test | 0 |
| LLM call | 0 |
| Linear mutation | 0 |

## Final Verdict

READY PH-SAAS-T8.12AS.21.95.

Next GO:

```text
GO READONLY VERIFY API ONBOARDING TRIAL_PAGE_VIEWED META TRACKING PROD PH-SAAS-T8.12AS.21.96
```
