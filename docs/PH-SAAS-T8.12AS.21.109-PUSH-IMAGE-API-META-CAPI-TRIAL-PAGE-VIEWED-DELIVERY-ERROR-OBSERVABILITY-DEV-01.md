# PH-SAAS-T8.12AS.21.109 - Push image API Meta CAPI trial_page_viewed delivery error observability DEV

Date UTC: 2026-06-23T21:36:23Z

## Verdict

GO PUSH IMAGE API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY DEV DONE PH-SAAS-T8.12AS.21.109

## Scope

Goal: push the already built DEV API image to GHCR, verify it by pull-back, and keep all runtimes unchanged.

Target image:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-dev`

Expected Image ID / config digest:

`sha256:0b7a6c2326121afa316ecc6d3853f8ac1484a61c12778c5c35a9c0a8d5cb9fa0`

Expected source revision:

`547648fd`

Out of scope respected:

- 0 docker build / rebuild.
- 0 deploy / kubectl apply.
- 0 manifest change.
- 0 DB mutation.
- 0 POST /funnel/event.
- 0 retry / replay.
- 0 CAPI test endpoint.
- 0 form / checkout / browser tracking action.
- 0 Linear mutation.

## Sources reread

- `/opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CURRENT_STATE.md`
- `/opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/RULES_AND_RISKS.md`
- `/opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/DOCUMENT_MAP.md`
- `/opt/keybuzz/keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md`
- `C:\DEV\KeyBuzz\tmp\PH-21.108_CE_RETURN.md`
- `C:\DEV\KeyBuzz\tmp\PH-21.107_PUSH_CE_RETURN.md`
- `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.108-BUILD-API-META-CAPI-TRIAL-PAGE-VIEWED-DELIVERY-ERROR-OBSERVABILITY-DEV-01.md`
- `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.107-SOURCE-PATCH-META-CAPI-TRIAL-PAGE-VIEWED-DELIVERY-ERROR-OBSERVABILITY-DEV-01.md`
- `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.106-READONLY-DEEP-RCA-META-CAPI-FAILED-DELIVERY-ERROR-PERSISTENCE-PROD-01.md`

## Bastion preflight

| item | expected | observed | verdict |
| --- | --- | --- | --- |
| hostname | install-v3 | install-v3 | PASS |
| public IPv4 | 46.62.171.61 | 46.62.171.61 | PASS |
| forbidden IP | absent | 51.159.99.247 absent | PASS |

## Repo preflight

| repo | branch | HEAD | origin | ahead/behind | dirty | decision |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 547648fd | 547648fd | 0/0 | 223 tracked dist deletions, non-dist dirty 0 | ACCEPT preexisting dist-only dirty |
| keybuzz-infra | main | 3749cd8 | 3749cd8 | 0/0 | 0 | ACCEPT docs-only report |

## Local image before push

| check | expected | observed | verdict |
| --- | --- | --- | --- |
| image exists | present | present | PASS |
| Image ID | sha256:0b7a6c2326121afa316ecc6d3853f8ac1484a61c12778c5c35a9c0a8d5cb9fa0 | sha256:0b7a6c2326121afa316ecc6d3853f8ac1484a61c12778c5c35a9c0a8d5cb9fa0 | PASS |
| OCI revision | 547648fd | 547648fd | PASS |
| OCI version | v3.5.265-meta-capi-error-observability-dev | v3.5.265-meta-capi-error-observability-dev | PASS |
| provider normalizer file | present | PRESENT | PASS |
| Meta CAPI adapter file | present | PRESENT | PASS |
| emitter file | present | PRESENT | PASS |
| dist/tests | absent | ABSENT | PASS |
| ph21107 artifacts | 0 | 0 | PASS |
| tests path artifacts | 0 | 0 | PASS |
| fixture sensitive count | 0 | 0 | PASS |

Markers observed in the image:

- `normalizeMetaCapiProviderError`: 4
- `buildSafeMetaCapiDeliveryErrorMessage`: 3
- `trial_page_viewed`: 7
- `StartTrial`: 9
- `Purchase`: 31
- `PROVIDER_CREDIT_EXHAUSTED`: 13
- `META_MISSING_USER_DATA`: 1
- `UNKNOWN_SAFE_ERROR`: 3

## Registry pre-check

| image | state before push | digest / hash | verdict |
| --- | --- | --- | --- |
| target tag | absent | n/a | PASS |
| latest | present | manifest JSON sha256 `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` | BASELINE_CAPTURED |

## Push

Pushed only:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-dev`

GHCR push digest:

`sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb`

No `latest` push, no other tag push, no build.

## Pull-back verification

The local target tag was removed only to force a pull-back. No prune and no other tag deletion.

| item | expected | observed | verdict |
| --- | --- | --- | --- |
| pull digest | sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb | sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb | PASS |
| RepoDigest | target repo digest with push manifest | ghcr.io/keybuzzio/keybuzz-api@sha256:a19fbf42fe108b193bd75bcc484d09a122cb39b7d84cc8e975fef8051a8924bb | PASS |
| Image ID / config | sha256:0b7a6c2326121afa316ecc6d3853f8ac1484a61c12778c5c35a9c0a8d5cb9fa0 | sha256:0b7a6c2326121afa316ecc6d3853f8ac1484a61c12778c5c35a9c0a8d5cb9fa0 | PASS |
| OCI revision | 547648fd | 547648fd | PASS |
| OCI version | v3.5.265-meta-capi-error-observability-dev | v3.5.265-meta-capi-error-observability-dev | PASS |

Target manifest JSON sha256 after push:

`77a6ad30d2dbe5a37ee585ffe0b1fad93fc9aab1f57ec928cfbadea5a74a9e88`

## Latest integrity

| check | before | after | verdict |
| --- | --- | --- | --- |
| latest manifest JSON sha256 | 71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549 | 71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549 | PASS |

## Runtime no-side-effect

| service | runtime image | ready | decision |
| --- | --- | --- | --- |
| API DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-dev | 1/1, pod restart 0 | UNCHANGED |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod | 1/1, pod restart 0 | UNCHANGED |
| Client DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev | 1/1 | UNCHANGED |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod | 1/1 | UNCHANGED |
| Website DEV | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev | 1/1 | UNCHANGED |
| Website PROD | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod | 2/2 | UNCHANGED |
| Admin DEV | ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-dev | 1/1 | UNCHANGED |
| Admin PROD | ghcr.io/keybuzzio/keybuzz-admin:v2.12.2-media-buyer-lp-domain-qa-prod | 1/1 | UNCHANGED |
| Backend PROD keybuzz-backend/jobs-worker | ghcr.io/keybuzzio/keybuzz-backend:v1.0.56-amazon-inbound-dedup-prod | 1/1 | UNCHANGED |

Observed API pod imageIDs remained:

- DEV: `ghcr.io/keybuzzio/keybuzz-api@sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669`
- PROD: `ghcr.io/keybuzzio/keybuzz-api@sha256:1a682256a2f870f84236d80ca0c52510657288ab9516237a1ac7972b85a000ad`

## Secret / PII safety

- No secret value read.
- No token displayed.
- No Secret.data read or decoded.
- No `/opt/keybuzz/credentials/` access.
- No `/opt/keybuzz/secrets/` access.
- No raw Meta payload displayed.
- Image fixture sensitive count: 0.

## No fake metrics / no fake events

- 0 POST `/funnel/event`.
- 0 retry.
- 0 replay.
- 0 CAPI test endpoint.
- 0 browser JS tracking action.
- 0 form submit.
- 0 checkout Stripe.
- 0 DB mutation.

## Non-regression

This phase only published the immutable DEV API image to GHCR. It did not change runtime,
source, manifests, DB, tracking state, secrets, Webflow, or Linear.

## Limits

- The image is published but not deployed.
- End-to-end delivery observability in DEV still requires a separate GitOps apply phase.
- No real Meta delivery event was triggered or replayed in this phase.

## Next GO

GO APPLY API META CAPI TRIAL_PAGE_VIEWED DELIVERY ERROR OBSERVABILITY DEV GITOPS PH-SAAS-T8.12AS.21.110
