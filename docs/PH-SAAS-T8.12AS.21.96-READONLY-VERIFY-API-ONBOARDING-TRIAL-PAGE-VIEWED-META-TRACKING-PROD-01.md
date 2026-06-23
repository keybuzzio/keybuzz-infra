# PH-SAAS-T8.12AS.21.96 - READONLY VERIFY API onboarding trial_page_viewed Meta tracking PROD

## Scope

- Mode: READONLY VERIFY API PROD.
- No patch, no build, no docker push, no deploy, no kubectl apply, no DB mutation.
- No POST /funnel/event, no form, no checkout, no CAPI test, no fake event, no Linear mutation.
- Docs-only report commit is the only write in this phase.

## Sources Relues

| Source | Status |
| --- | --- |
| PH-21.96 mission | Read |
| AI_MEMORY CURRENT_STATE / RULES_AND_RISKS / DOCUMENT_MAP / CE_PROMPTING_STANDARD | Read |
| PH-T8.10J model | Read |
| PH-21.79 / PH-21.84 / PH-21.92 / PH-21.93 / PH-21.94 / PH-21.95 returns | Read |
| Infra docs PH-21.79 / 21.84 / 21.92 / 21.93 / 21.94 / 21.95 | Present on bastion |

## Preflight

| Control | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| Host | install-v3 | install-v3 | PASS |
| IPv4 | 46.62.171.61 | 46.62.171.61 | PASS |
| UTC | displayed | 2026-06-23T07:57:35Z | PASS |
| Kube context | kubernetes-admin@kubernetes | kubernetes-admin@kubernetes | PASS |

## Repositories

| Repo | Branch | HEAD | Origin | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | ---: | --- |
| keybuzz-infra | main | 483c8b79b152 | 483c8b79b152 | 0/0 | 0 | PASS |
| keybuzz-api | ph147.4/source-of-truth | 35673e3b16f4 | 35673e3b16f4 | 0/0 | 223 | DIRTY_DOCUMENTED |
| keybuzz-client | ph148/onboarding-activation-replay | d9631ca087f1 | d9631ca087f1 | 0/0 | 1 | DIRTY_DOCUMENTED |
| keybuzz-website | main | bd32fc8bc9d9 | bd32fc8bc9d9 | 0/0 | 0 | PASS |
| keybuzz-admin-v2 | main | 3707c834d7bf | 3707c834d7bf | 0/0 | 0 | PASS |
| keybuzz-backend | main | c38583a8548e | c38583a8548e | 0/0 | 1 | DIRTY_DOCUMENTED |

## Runtime Equality

| Level | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| Manifest | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | PASS |
| Last-applied | contains API image | count 1 | PASS |
| Deployment spec | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | PASS |
| Pod spec | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | PASS |
| Pod imageID | ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | PASS |
| Generation observed | equal | 424 / 424 | PASS |
| Ready/restarts | ready true | true / 0 | PASS |
| Health | HTTP 200 JSON | PASS | PASS |

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

## Logs Passifs

| Log pattern | Expected | Observed | Verdict |
| --- | --- | ---: | --- |
| crash/fatal/unhandled/panic | 0 | 0 | PASS |
| token-like leaks | 0 | 0 | PASS |
| CAPI unexpected | 0 | 0 | PASS |
| trial_page_viewed natural logs | 0 or natural | 0 | OBSERVED |
| REQUEST_FAILED | 0 or documented | 0 | OBSERVED |

## DB / Tracking Read-only

| Counter | Before -> After | Verdict |
| --- | --- | --- |
| DB snapshot status | DB_SNAPSHOT_OK -> DB_SNAPSHOT_OK | OBSERVED |
| funnel_events.total | 304->304 | READ_ONLY |
| funnel_events.trial_page_viewed | 0->0 | READ_ONLY |
| funnel_events.register_started_24h | 0->0 | READ_ONLY |
| conversion_events.total | 3->3 | READ_ONLY |
| conversion_events.trial_page_viewed | 0->0 | READ_ONLY |
| outbound_conversion_delivery_logs.total | 19->19 | READ_ONLY |
| outbound_conversion_delivery_logs.trial_page_viewed | 0->0 | READ_ONLY |
| ai_usage.total | 346->346 | READ_ONLY |
| ai_actions_ledger.total | 393->393 | READ_ONLY |
| kb_actions_ledger.total | NA->NA | READ_ONLY |

Snapshots used BEGIN TRANSACTION READ ONLY and ROLLBACK from the API pod. No PII or secrets were printed.

## Non-regression Services

| Service | Env | Expected | Observed image | Pod imageID | Verdict |
| --- | --- | --- | --- | --- | --- |
| API | PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | PASS |
| API | DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | ghcr.io/keybuzzio/keybuzz-api@sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669 | PASS |
| Client | PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod | ghcr.io/keybuzzio/keybuzz-client@sha256:e63494dbe83368a300df4d199b6443ccef6442b5428edeca6cf94433b5abf791 | PASS |
| Client | DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | ghcr.io/keybuzzio/keybuzz-client@sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | PASS |
| GHCR latest API | 71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549 | 71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549 | n/a | PASS |

Website/Admin/Backend were read-only observed and not modified. No manifest apply was executed.

## Limites Figées

- API PROD is healthy and ready for server-side trial_page_viewed.
- Client PROD is still not promoted with marketing_owner_tenant_id, UTM and click IDs in register_started.properties.
- Therefore Antoine's end-to-end Ads Manager proof is not complete yet.
- No real journey, no fake journey, no form, no checkout, no CAPI test in this phase.
- NO_NATURAL_TRAFFIC remains an acceptable limit until a real eligible path exists after Client PROD promotion.

## No Fake Metrics / No Fake Events

| Item | Count |
| --- | ---: |
| build | 0 |
| docker push | 0 |
| deploy / kubectl apply | 0 |
| DB mutation | 0 |
| POST /funnel/event | 0 |
| Form submission | 0 |
| Checkout | 0 |
| CAPI test | 0 |
| LLM call | 0 |
| Linear mutation | 0 |

## Final Verdict

READY_WITH_LIMITS PH-SAAS-T8.12AS.21.96.

Next GO:

```text
GO READONLY CLOSE API ONBOARDING TRIAL_PAGE_VIEWED META TRACKING PROD PH-SAAS-T8.12AS.21.97
```
