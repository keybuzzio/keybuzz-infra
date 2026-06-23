# PH-SAAS-T8.12AS.21.107 - Source Patch Meta CAPI Trial Page Viewed Delivery Error Observability DEV

Date: 2026-06-23
Mode: SOURCE PATCH DEV
Repos: keybuzz-api, keybuzz-infra
Runtime: not touched

## Verdict

READY_WITH_DEBTS.

PH-21.107 added source-side safe observability for failed Meta CAPI trial_page_viewed delivery errors.
No build, docker push, deploy, kubectl apply, database mutation, CAPI test, fake event, form submit, checkout, Webflow or Linear action was performed.

## Preflight

| Repo | Branch | Base HEAD | Final local HEAD | Origin parity |
| --- | --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 35673e3b | 547648fd | ahead 1, behind 0 |
| keybuzz-infra | main | 4ca4533 | pending docs commit | no push |

API worktree note: tracked dist deletions were already present before this phase and were not touched, staged or committed.

## API Source Patch

| File | Change | Risk control |
| --- | --- | --- |
| src/modules/outbound-conversions/lib/provider-error-normalizer.ts | Added safe Meta CAPI provider error normalizer, classifier, redactor and serializer | No runtime call, no provider call, no DB mutation |
| src/modules/outbound-conversions/adapters/meta-capi.ts | Non-OK and catch paths now return safeError with classification and redacted safeMessage | Existing success path unchanged |
| src/modules/outbound-conversions/emitter.ts | Failed Meta CAPI terminal delivery now stores the last safe provider error into outbound_conversion_delivery_logs.error_message | Existing field only, no migration |
| src/tests/ph21107-meta-capi-error-observability-tests.ts | Added offline/mock tests for classifications, redaction, adapter failure/success and persistence message | No real Meta/CAPI event |

## Classifications Covered

- META_INVALID_EVENT_NAME
- META_UNSUPPORTED_CUSTOM_EVENT
- META_MISSING_USER_DATA
- META_MISSING_ACTION_SOURCE_OR_EVENT_SOURCE_URL
- META_MISSING_FBC_FBP_OR_CLICK_ID
- META_INVALID_PIXEL_OR_TOKEN
- META_PERMISSION_OR_AUTH
- META_DEDUP_OR_EVENT_ID
- META_PAYLOAD_SCHEMA
- META_RATE_LIMIT_OR_TEMPORARY
- NETWORK_OR_PROVIDER_TIMEOUT
- KEYBUZZ_TOKEN_DECRYPTION
- KEYBUZZ_ROUTING_DESTINATION
- KEYBUZZ_SERIALIZATION
- UNKNOWN_SAFE_ERROR

## Persistence Decision

Existing table field used: outbound_conversion_delivery_logs.error_message.

No schema migration was required. The emitter records the serialized safe provider error from the last failed Meta CAPI attempt when all attempts fail. The stored value is non-empty and includes provider, classification, retryable, optional HTTP status, optional provider code/subcode and safeMessage.

## Secret And PII Safety

The patch redacts:

- Meta access tokens
- Authorization values
- cookies
- emails
- phone numbers
- raw user_data and common user data keys
- long provider messages are truncated

No secret, token, recipient or raw PII value was written to this report.

## Offline Tests

| Check | Result |
| --- | --- |
| git diff --check | PASS |
| tsc -p tsconfig.json --outDir /tmp/ph21107-api-tests-run5 | PASS |
| node /tmp/ph21107-api-tests-run5/tests/ph21107-meta-capi-error-observability-tests.js | PASS |
| node /tmp/ph21107-api-tests-run5/tests/ph2179-trial-page-viewed-meta-tests.js | PASS |

Test execution used NODE_PATH=/opt/keybuzz/keybuzz-api/node_modules for compiled files under /tmp.

## No Fake Events / No Runtime Mutation

| Control | Result |
| --- | --- |
| POST /funnel/event | 0 |
| retry/replay old failed delivery | 0 |
| Meta CAPI test event | 0 |
| form submit /register | 0 |
| checkout Stripe | 0 |
| DB mutation | 0 |
| build / docker push | 0 |
| deploy / kubectl apply | 0 |
| Linear | 0 |

## Remaining Debts

- API commit is local only and must be pushed in a separate GO.
- No image was built and no runtime was deployed in this phase.
- The next natural failed Meta CAPI delivery must be observed after deploy to prove the persisted provider classification on real traffic.
- Historical failed delivery 99541c23fe41 was not replayed or modified.
- API worktree still has pre-existing tracked dist deletions outside PH-21.107 scope.

## Next GO

GO PUSH SOURCE PATCH META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY DEV PH-SAAS-T8.12AS.21.107
