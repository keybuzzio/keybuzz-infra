# PH-SAAS-T8.12AS.21.92 - READONLY DESIGN - Client onboarding register_started owner payload PROD promotion safety

## Scope

- Mode: READONLY DESIGN with docs-only report.
- No patch source/runtime, no build, no docker push, no deploy, no kubectl apply.
- No POST /funnel/event, no form submission, no Stripe checkout, no real/fake event.
- No DB mutation and no Linear mutation.
- Goal: decide PROD promotion ordering between API trial_page_viewed and Client register_started owner payload.

## Preflight

| Item | Value |
| --- | --- |
| Host | install-v3 |
| IP | 46.62.171.61 |
| UTC | 2026-06-22T20:11:31Z |
| Kube context | kubernetes-admin@kubernetes |

## Repository Snapshot

| Repo | Branch | HEAD | Origin HEAD | Ahead/Behind | Dirty count | Dirty summary |
| --- | --- | --- | --- | --- | ---: | --- |
| keybuzz-api | ph147.4/source-of-truth | 35673e3b16f4 | 35673e3b16f4 | 0/0 | 223 |  223 D; |
| keybuzz-client | ph148/onboarding-activation-replay | d9631ca087f1 | d9631ca087f1 | 0/0 | 1 |  1 M; |
| keybuzz-infra before report | main | 59cb3853fd2b | 59cb3853fd2b | 0/0 | 0 | clean |

Notes:

- API working tree has pre-existing generated dist deletions. They were not modified in this phase.
- Client working tree has pre-existing tsconfig.tsbuildinfo dirt. It was not modified in this phase.
- Infra was clean before creating this docs-only report.

## Runtime Snapshot

| Environment | Service | Image | Pod imageID / digest | Ready | Restarts |
| --- | --- | --- | --- | --- | ---: |
| DEV | API |  | ghcr.io/keybuzzio/keybuzz-api@sha256:bc2892c9d2c93634c35d09144f74e822b4dea3db4dcd3b13b93f7519978ba669 | true | 0 |
| DEV | Client |  | ghcr.io/keybuzzio/keybuzz-client@sha256:0e8675faa5071d66991c43b3e340d0fb4167c9cb453d254365eec3043d5af3b9 | true | 0 |
| PROD | API |  | ghcr.io/keybuzzio/keybuzz-api@sha256:668bcff0b2ac3f5651ca1dc100ebcfe056996f131a200754fda1985ae0ceabe6 | true | 0 |
| PROD | Client |  | ghcr.io/keybuzzio/keybuzz-client@sha256:e63494dbe83368a300df4d199b6443ccef6442b5428edeca6cf94433b5abf791 | true | 0 |

## DEV State Confirmed From Prior Chain

| Phase | Component | Result |
| --- | --- | --- |
| PH-21.79 to PH-21.84 | API DEV | v3.5.264 deployed and closed with limits. trial_page_viewed server-side handler is present. No fake events were generated. |
| PH-21.86 to PH-21.91 | Client DEV | v3.5.260 deployed and closed with limits. register_started payload includes marketing_owner_tenant_id, UTM fields and click IDs. No fake events were generated. |
| PH-21.83 / PH-21.90 | Natural traffic | NO_NATURAL_TRAFFIC / no real Ads Manager proof yet. |

## Source And Runtime Findings

| Check | Result | Interpretation |
| --- | --- | --- |
| API DEV marker | trial_page_viewed present in runtime bundle | API handler exists in DEV. |
| API PROD marker | trial_page_viewed absent in runtime bundle | Current PROD API v3.5.262 cannot emit the new trial_page_viewed event. |
| API source at PH-21.79 | register_started from client drives trial_page_viewed through outbound conversions | PROD must receive this source/runtime before Antoine can observe the new event. |
| API source route | properties object is accepted and inserted for funnel events | Client extra payload is backward-compatible at the JSON contract level. |
| Client DEV source | register_started properties include marketing_owner_tenant_id, UTM fields and click IDs with a safe retry on invalid owner tenant | Payload patch is source-ready for PROD build. |
| Client PROD runtime | Current image remains v3.5.259 baseline | It is not the PH-21.86 DEV promotion artifact. |

## Compatibility Decision

| Question | Decision |
| --- | --- |
| Can the Client payload shape be sent to the current API PROD route? | PASS_BACKWARD_COMPATIBLE. The event accepts a JSON properties object; additional keys are safe for the funnel insert contract. |
| Would Client PROD promotion alone make Antoine see trial_page_viewed? | NO. Current API PROD has no trial_page_viewed runtime marker and cannot emit that new server-side CAPI event. |
| Would API PROD promotion first break the current Client PROD? | No blocker found. The API handler listens to register_started from client and remains compatible with the existing event contract. Attribution quality may remain limited until the Client payload is promoted. |
| Which component is the gating dependency for the new Meta event? | API PROD is the first gate because it owns trial_page_viewed emission. Client PROD is the enrichment/input gate. |

## Recommended Promotion Order

Verdict: READY_API_PROD_FIRST.

Recommended sequence:

1. Promote API trial_page_viewed to PROD first.
2. Verify API PROD runtime and no regression in StartTrial/Purchase.
3. Promote Client register_started owner payload to PROD after API PROD is stable.
4. Verify Client PROD bundle with PROD API URL only and no DEV API URL.
5. Wait for a real eligible /register path; do not create fake events.

Rationale:

- API PROD currently lacks the server-side trial_page_viewed handler, so Client-only promotion would be incomplete for Antoine's expected Meta signal.
- API-first is backward-compatible with current Client traffic and prepares the server-side path before sending enriched owner/UTM/click payloads at scale.
- Client promotion then completes attribution richness and owner routing without relying on a partial PROD event pipeline.

## Gates For Next API PROD Chain

| Gate | Requirement |
| --- | --- |
| Source | Build from API commit 35673e3b16f4843d6144c24a0ad9926e28525ed4 only. |
| Image | Use immutable PROD tag, expected naming: ghcr.io/keybuzzio/keybuzz-api:v3.5.264-onboarding-trial-page-viewed-meta-prod unless the release ledger requires the next patch tag. |
| Build args | PROD explicit, build-from-git clean source only. |
| Audit | trial_page_viewed present; register_started source preserved; StartTrial and Purchase intact; dist/tests absent from runtime image. |
| Push | Dedicated image push phase with pull-back digest verification; no latest. |
| GitOps | Commit + push manifest before kubectl apply -f; verify manifest = last-applied = spec = pod. |
| Runtime | API PROD ready 1/1, restarts 0, expected image digest documented. |
| Tracking safety | No fake /funnel/event, no form, no checkout, no CAPI test event. |

## Gates For Later Client PROD Chain

| Gate | Requirement |
| --- | --- |
| Source | Build from Client commit d9631ca087f1751b2def8ad06a049ad93226ffbd only. |
| Image | Expected naming: ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod unless the release ledger requires the next patch tag. |
| Build args | PROD explicit; bundle must contain https://api.keybuzz.io and must not contain https://api-dev.keybuzz.io. |
| Audit | register_started preserved; marketing_owner_tenant_id, UTM fields and click IDs present; StartTrial/Purchase not touched by this Client patch. |
| GitOps | Client PROD manifest only; commit + push before kubectl apply -f. |
| Rollback reference | Current Client PROD image before any later promotion:  / ghcr.io/keybuzzio/keybuzz-client@sha256:e63494dbe83368a300df4d199b6443ccef6442b5428edeca6cf94433b5abf791. |

## No Fake Metrics / No Fake Events

| Item | Count |
| --- | ---: |
| POST /funnel/event | 0 |
| /register form submissions | 0 |
| Stripe checkout starts/completions | 0 |
| CAPI test events | 0 |
| Real or fake tracking events generated by CE | 0 |

## Remaining Debts And Limits

- Ads Manager observation remains unproved until a real eligible journey occurs.
- Webflow/Antoine URLs must preserve marketing_owner_tenant_id and relevant UTM/click IDs into client.keybuzz.io/register.
- Test without card is still out of scope for this phase.
- Client-only PROD promotion is not recommended because it would not surface trial_page_viewed without API PROD v3.5.264+.
- During API-first interval, attribution may be limited until Client owner payload is promoted.

## Final Verdict

READY_API_PROD_FIRST PH-SAAS-T8.12AS.21.92.

Next GO:

```text
GO BUILD API ONBOARDING TRIAL_PAGE_VIEWED META TRACKING PROD PH-SAAS-T8.12AS.21.93
```
