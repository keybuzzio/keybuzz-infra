# PH-SAAS-T8.12AS.21.108 - Build API Meta CAPI Trial Page Viewed Delivery Error Observability DEV

Date: 2026-06-23
Mode: BUILD API DEV LOCAL ONLY
Verdict: GO BUILD API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY DEV READY PH-SAAS-T8.12AS.21.108

## GO

Build local only:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-dev`

Source:

`547648fd` on `origin/ph147.4/source-of-truth`.

No docker push, no deploy, no kubectl apply, no manifest change, no DB mutation, no event, no CAPI test, no Webflow and no Linear action.

## Sources Relues

| Source | Result |
| --- | --- |
| AI_MEMORY/CURRENT_STATE.md | OK |
| AI_MEMORY/RULES_AND_RISKS.md | OK |
| AI_MEMORY/DOCUMENT_MAP.md | OK |
| AI_MEMORY/CE_PROMPTING_STANDARD.md | OK |
| PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01 | OK |
| C:\DEV\KeyBuzz\tmp\PH-21.107_CE_RETURN.md | OK |
| C:\DEV\KeyBuzz\tmp\PH-21.107_PUSH_CE_RETURN.md | OK |
| PH-SAAS-T8.12AS.21.107 source patch report | OK |
| PH-SAAS-T8.12AS.21.106 deep RCA report | OK |
| PH-SAAS-T8.12AS.21.105 RCA report | OK |
| PH-SAAS-T8.12AS.21.104 real traffic observation report | OK |

## Preflight Bastion

| Check | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| hostname | install-v3 | install-v3 | PASS |
| IPv4 | 46.62.171.61 | 46.62.171.61 | PASS |
| date UTC | captured | 2026-06-23T21:13:32Z | PASS |
| forbidden IP | absent | 51.159.99.247 not observed | PASS |

## Repo Preflight

| repo | branch | HEAD | origin | ahead/behind | dirty | decision |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 547648fd | 547648fd | 0/0 | non-dist dirty=0; 223 tracked dist deletions preexisting | OK, do not build from dirty repo |
| keybuzz-infra | main | c7e7856 | c7e7856 | 0/0 | 0 before report | OK docs-only |

API commit scope:

- src/modules/outbound-conversions/adapters/meta-capi.ts
- src/modules/outbound-conversions/emitter.ts
- src/modules/outbound-conversions/lib/provider-error-normalizer.ts
- src/tests/ph21107-meta-capi-error-observability-tests.ts

## Build Source

| build source | path | HEAD | dirty | verdict |
| --- | --- | --- | --- | --- |
| git worktree detached from API repo | /tmp/ph21108-api-build-20260623-2114 | 547648fd | 0 | PASS |

The worktree was created with `git worktree add --detach` from `/opt/keybuzz/keybuzz-api`.
No source was copied by SCP and no build was run from `/opt/keybuzz/keybuzz-api`.
The worktree was removed after build with `git worktree remove /tmp/ph21108-api-build-20260623-2114`.

## Pre-build Tests

| test | command | result |
| --- | --- | --- |
| whitespace | git diff --check | PASS |
| TypeScript | ./node_modules/.bin/tsc -p tsconfig.json --noEmit | PASS |
| compile tests to tmp | ./node_modules/.bin/tsc -p tsconfig.json --outDir /tmp/ph21108-api-tests-run | PASS |
| PH21.107 | node /tmp/ph21108-api-tests-run/tests/ph21107-meta-capi-error-observability-tests.js | PASS |
| PH21.79 | node /tmp/ph21108-api-tests-run/tests/ph2179-trial-page-viewed-meta-tests.js | PASS |

Tests used `NODE_PATH=/tmp/ph21108-api-build-20260623-2114/node_modules`.
Fetch was mocked in PH21.107 tests. No Meta call, no POST /funnel/event and no DB mutation occurred.

## Registry Pre-check

| image | state before build | state after build | verdict |
| --- | --- | --- | --- |
| ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-dev | ABSENT | ABSENT | PASS, no docker push |
| ghcr.io/keybuzzio/keybuzz-api:latest | present sha256 manifest hash 71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549 | same hash 71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549 | PASS |

## Build

Command:

```text
docker build --build-arg IMAGE_REVISION=547648fd --build-arg IMAGE_CREATED=2026-06-23T21:16:38Z --build-arg IMAGE_VERSION=v3.5.265-meta-capi-error-observability-dev -t ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-dev .
```

Build result:

| item | value |
| --- | --- |
| image | ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-dev |
| image ID | sha256:0b7a6c2326121afa316ecc6d3853f8ac1484a61c12778c5c35a9c0a8d5cb9fa0 |
| local size | 346855977 bytes, Docker display 347MB |
| OCI revision | 547648fd |
| OCI version | v3.5.265-meta-capi-error-observability-dev |
| OCI created | 2026-06-23T21:16:38Z |
| OCI source | https://github.com/keybuzzio/keybuzz-api |
| OCI title | keybuzz-api |

Build note: `npm prune --omit=dev` reported existing npm audit vulnerabilities in dependency metadata. This phase did not modify dependencies and did not run dependency remediation.

## Image Audit

Audit method:

- `docker image inspect` for labels and ID.
- `docker run --rm --network none --entrypoint sh` for simple runtime filesystem checks.
- `docker create` + `docker cp /app/dist` to `/tmp/ph21108-image-audit-dist-20260623-2118` for reliable marker counts without running the API.

| audit | expected | observed | verdict |
| --- | --- | --- | --- |
| provider error normalizer file | present | present | PASS |
| meta-capi adapter file | present | present | PASS |
| emitter file | present | present | PASS |
| normalizeMetaCapiProviderError marker | >0 | 4 | PASS |
| buildSafeMetaCapiDeliveryErrorMessage marker | >0 | 3 | PASS |
| serializeSafeProviderError marker | >0 | 3 | PASS |
| trial_page_viewed marker | >0 | 7 | PASS |
| StartTrial marker | >0 | 9 | PASS |
| Purchase marker | >0 | 31 | PASS |
| PROVIDER_CREDIT_EXHAUSTED marker | >0 | 13 | PASS |
| redaction token marker | >0 | 6 | PASS |
| redaction cookie marker | >0 | 2 | PASS |
| redaction email marker | >0 | 1 | PASS |
| redaction phone marker | >0 | 1 | PASS |
| redaction user_data marker | >0 | 3 | PASS |
| all PH21.107 classifications | present | present, counts >=1 | PASS |
| /app/dist/tests | absent | absent | PASS |
| /app/src/tests | absent | absent | PASS |
| ph21107 artifacts | absent | 0 | PASS |
| tests path artifacts | absent | 0 | PASS |
| .git directories | absent | 0 | PASS |
| source maps | absent | 0 | PASS |
| test fixture sensitive strings | absent | 0 | PASS |

Classification counts:

| classification | count |
| --- | ---: |
| META_INVALID_EVENT_NAME | 1 |
| META_UNSUPPORTED_CUSTOM_EVENT | 1 |
| META_MISSING_USER_DATA | 1 |
| META_MISSING_ACTION_SOURCE_OR_EVENT_SOURCE_URL | 1 |
| META_MISSING_FBC_FBP_OR_CLICK_ID | 1 |
| META_INVALID_PIXEL_OR_TOKEN | 1 |
| META_PERMISSION_OR_AUTH | 1 |
| META_DEDUP_OR_EVENT_ID | 1 |
| META_PAYLOAD_SCHEMA | 1 |
| META_RATE_LIMIT_OR_TEMPORARY | 3 |
| NETWORK_OR_PROVIDER_TIMEOUT | 2 |
| KEYBUZZ_TOKEN_DECRYPTION | 1 |
| KEYBUZZ_ROUTING_DESTINATION | 1 |
| KEYBUZZ_SERIALIZATION | 1 |
| UNKNOWN_SAFE_ERROR | 3 |

## Runtime No-side-effect

| service | image | ready | verdict |
| --- | --- | --- | --- |
| API DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | 1/1 | unchanged |
| API DEV imageID | ghcr.io/keybuzzio/keybuzz-api@sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669 | ready true restarts 0 | unchanged |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | 1/1 | unchanged |
| API PROD imageID | ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad | ready true restarts 0 | unchanged |
| Client DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | 1/1 | unchanged |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | 1/1 | unchanged |
| Website PROD | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod | 2/2 | unchanged |
| Admin PROD | ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-prod | 1/1 | unchanged |
| Backend PROD | ghcr.io/keybuzzio/keybuzz-backend:v1.0.56-amazon-inbound-dedup-prod | 1/1 | unchanged |

## Secret / PII Safety

| control | result |
| --- | --- |
| token/Authorization/cookie displayed | 0 |
| raw PII displayed | 0 |
| secret files touched | 0 |
| build args secrets | 0 |
| test fixture sensitive strings in image | 0 |

## No Fake Metrics / No Fake Events

| control | count |
| --- | ---: |
| POST /funnel/event | 0 |
| retry/replay | 0 |
| CAPI test endpoint | 0 |
| DB mutation | 0 |
| browser JS/register form/checkout | 0 |
| Webflow/Meta Ads/Linear | 0 |

## Non-regression

- StartTrial and Purchase markers remain present.
- PROVIDER_CREDIT_EXHAUSTED marker remains present.
- Runtime API DEV/PROD and Client DEV/PROD were not changed.
- Website/Admin/Backend read-only snapshot unchanged.

## Remaining Debts

- Image is local only and not pushed.
- No runtime deploy has occurred.
- The next natural failed Meta CAPI delivery cannot prove the new observability until the image is pushed and deployed in a later phase.
- npm audit vulnerability output remains a dependency debt outside this phase.

## Next GO

GO PUSH IMAGE API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY DEV PH-SAAS-T8.12AS.21.109
