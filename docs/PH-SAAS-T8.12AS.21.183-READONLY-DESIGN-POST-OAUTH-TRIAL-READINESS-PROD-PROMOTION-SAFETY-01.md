# PH-SAAS-T8.12AS.21.183 - READONLY DESIGN POST-OAUTH TRIAL READINESS PROD PROMOTION SAFETY

Date: 2026-06-28
Phase: PH-SAAS-T8.12AS.21.183
Type: READONLY DESIGN
Environment target: PROD
Verdict: READY_FOR_BUILD_PROD

## Objective

Prepare the PROD promotion path for the post-OAuth trial readiness fixes validated in DEV during PH-21.182.

The promotion must keep all existing KeyBuzz features functional while moving the following DEV-validated behavior to PROD:

- Amazon post-OAuth channel readiness refresh.
- Immediate channel counter coherence after OAuth return.
- Background 3-month orders sync launch from the client after successful Amazon connection.
- Manual order sync preserved.
- No-card trial starter playbooks active for new trial tenants.
- Safe read-time repair for trial tenants that still have inactive starter playbooks.
- Trial billing banner cleanup after a card/subscription conversion.
- Focus-mode first-use hint.
- Agent KeyBuzz gating unchanged: unavailable during trial, available after paid activation.

Out of scope for this phase:

- No build.
- No image push.
- No GitOps apply.
- No DB mutation.
- No Stripe write.
- No checkout/test payment.
- No tracking fake event.

## Sources Relues

- AI_MEMORY current state, rules, document map and CE prompting standard.
- PH-21.176 first-run /start latency PROD close.
- PH-21.181 current debts close.
- PH-21.182 post-OAuth trial readiness DEV apply/verify report.
- Current runtime and manifests on install-v3.

## Source Baseline

| Repo | Branch | HEAD | Status |
| --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 485a3f5a4f33daa006a03e02a4d1d15d10e767f6 | clean, origin aligned |
| keybuzz-client | ph148/onboarding-activation-replay | f349118c09db2228847575322669fae3c7577000 | clean, origin aligned |
| keybuzz-infra | main | 441c5789f9721ae5bee0e6f4755a7bb63a41d080 | clean, origin aligned |

## DEV Reference Validated In PH-21.182

| Service | Image | Digest | Runtime |
| --- | --- | --- | --- |
| API DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.277-playbooks-read-repair-dev | sha256:2786b32176cf9727050e7b69117a2685da77b75eaded1f68af825d72d8fbf45a | generation 518/518, ready 1, restarts 0 |
| Client DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.268-post-oauth-trial-readiness-dev | sha256:c6a6c43c8b4a20c082eb2974a8024a7631e139e302f1ce334e248c84bb512a0b | generation 1032/1032, ready 1, restarts 0 |

PH-21.182 validated the behavior in DEV after Ludovic's manual checks:

- `/start` latency corrected.
- Amazon OAuth flow completes.
- Channel card becomes connected.
- Channel counter catches up.
- Trial playbooks are active or repaired.
- No-card trial billing/activation behavior remains coherent.

## PROD Runtime Baseline

| Service | Current PROD image | Digest | Runtime |
| --- | --- | --- | --- |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.275-ai-journal-startup-ddl-prod | sha256:ad5950ee3bf86b7980fde0005a778565956ff1f6c931b2b8d6877f94b39157f8 | generation 436/436, ready 1, restarts 0 |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.267-start-onboarding-latency-prod | sha256:ae5de89ed95da058ece6f93d85ae6a2f925d8aa6d1b437ae6f0dde06a1b5dbc0 | generation 434/434, ready 1, restarts 0 |

Current GitOps manifests match the current PROD images:

- `k8s/keybuzz-api-prod/deployment.yaml` -> `v3.5.275-ai-journal-startup-ddl-prod`.
- `k8s/keybuzz-client-prod/deployment.yaml` -> `v3.5.267-start-onboarding-latency-prod`.

## PROD Target Images

| Service | Target tag | Source commit | Registry status before build |
| --- | --- | --- | --- |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.277-playbooks-read-repair-prod | 485a3f5a4f33daa006a03e02a4d1d15d10e767f6 | absent |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.268-post-oauth-trial-readiness-prod | f349118c09db2228847575322669fae3c7577000 | absent |

The DEV tags exist in GHCR and remain the functional reference. The PROD target tags are safe to build because no manifest exists yet for either target tag.

## Required Build Gates

API PROD build must be from a clean git checkout of `485a3f5a4f33daa006a03e02a4d1d15d10e767f6`.

Required API checks before image build:

| Test | Expected |
| --- | --- |
| git diff --check | PASS |
| TypeScript compile | PASS |
| PH21.172 no-card trial tests | PASS |
| PH21.177 Amazon activation idempotence tests | PASS |
| PH21.182 starter playbook seed/read-repair tests | PASS |
| Runtime marker audit in image | playbook repair, trial seed, Amazon activation, billing tenant-id logic present |
| Dist/tests audit | tests absent from runtime image |

Client PROD build must be from a clean git checkout of `f349118c09db2228847575322669fae3c7577000`.

Required Client PROD build args:

| Build arg | Required value |
| --- | --- |
| NEXT_PUBLIC_APP_ENV | production |
| NEXT_PUBLIC_API_URL | https://api.keybuzz.io |
| NEXT_PUBLIC_API_BASE_URL | https://api.keybuzz.io |
| NEXT_PUBLIC_GA4_MEASUREMENT_ID | PROD value |
| NEXT_PUBLIC_META_PIXEL_ID | PROD value |
| NEXT_PUBLIC_SGTM_URL | PROD value |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | PROD value |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | PROD value |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | PROD value |

Required Client checks before image push:

| Test | Expected |
| --- | --- |
| git diff --check | PASS |
| PH21.172 no-card trial tests | PASS |
| PH21.182 post-OAuth trial UX tests | PASS |
| Targeted lint | PASS |
| TypeScript compile | PASS |
| Bundle audit | `https://api.keybuzz.io` present |
| Bundle audit | `https://api-dev.keybuzz.io` absent |
| Fake trigger audit | no fake checkout/tracking events |

## Apply Gates

Promotion must stay GitOps-only:

1. Build API and Client PROD images from git.
2. Push immutable PROD tags.
3. Pull back each image and record RepoDigest.
4. Patch only the image lines in:
   - `k8s/keybuzz-api-prod/deployment.yaml`
   - `k8s/keybuzz-client-prod/deployment.yaml`
5. Commit and push infra before apply.
6. Run client and server dry-run.
7. Apply only with:
   - `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`
   - `kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml`
8. Wait for rollout status.
9. Verify:
   - manifest image = last-applied image = deployment spec image = pod spec image.
   - pod imageID digest = GHCR digest.
   - ready replicas OK.
   - restarts remain 0.

Forbidden deployment methods:

- `kubectl set image`.
- `kubectl set env`.
- `kubectl patch`.
- `kubectl edit`.
- build from pod/runtime/dist/copied source.
- dirty build.
- `latest`.

## Post-Apply Verification Gates

Read-only verification must cover:

| Area | Expected |
| --- | --- |
| API health | OK |
| Client public routes | `/`, `/register`, `/login`, `/start` passive HTTP OK |
| Amazon OAuth callback behavior | no Vault 403 regression, no activation idempotence regression |
| Channels counter | coherent immediately or after post-OAuth refresh without manual page reload debt |
| Orders sync | 3-month background sync starts only after a real connected Amazon channel |
| Manual orders sync | still available |
| Playbooks | 15 starter playbooks active for no-card trial tenants |
| Playbooks repair | scoped repair available on read for no-card trial tenants |
| Agent KeyBuzz | blocked during trial, purchasable/available after paid activation |
| Billing banner | no obsolete "choose plan" CTA after paid card/subscription activation |
| Focus mode | first-use hint present |
| Tracking | no fake StartTrial/Purchase/CompletePayment/Lead |
| Stripe | no write outside real user action |
| DB | no migration expected |

## Rollback

Rollback must also be GitOps-only:

| Service | Rollback image | Rollback digest |
| --- | --- | --- |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.275-ai-journal-startup-ddl-prod | sha256:ad5950ee3bf86b7980fde0005a778565956ff1f6c931b2b8d6877f94b39157f8 |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.267-start-onboarding-latency-prod | sha256:ae5de89ed95da058ece6f93d85ae6a2f925d8aa6d1b437ae6f0dde06a1b5dbc0 |

Rollback steps:

1. Patch only image lines back to rollback tags.
2. Commit and push infra.
3. `kubectl apply -f` the relevant manifest.
4. Verify rollout, pod imageID digest, ready replicas, restarts.

## No Fake Metrics / No Fake Events

This promotion must not generate fake business metrics.

Forbidden in build/push/apply/verify phases:

- fake `POST /funnel/event`.
- fake checkout.
- fake payment.
- fake StartTrial.
- fake Purchase.
- fake CompletePayment.
- fake Lead.
- manual CAPI test unless a separate explicit GO says so.

Only real user paths may generate real conversion/tracking events.

## AI Feature Parity / Anti-Regression

Although the scope is onboarding/post-OAuth readiness, the promotion must not regress:

- Inbox.
- messages.
- AI drafts.
- AI automatic responses.
- playbooks.
- escalations.
- Agent KeyBuzz gating.
- KBActions.
- marketplace connectors.
- orders.
- tracking.
- billing conversion.

The upcoming AI response humanness improvement remains a separate future scope and must not be mixed into this PROD promotion.

## Final Decision

Verdict: READY_FOR_BUILD_PROD.

Recommended next GO:

`GO BUILD API CLIENT POST-OAUTH TRIAL READINESS PROD PH-SAAS-T8.12AS.21.184`

No side effect in PH-21.183:

- 0 build.
- 0 image push.
- 0 GitOps apply.
- 0 deploy.
- 0 DB mutation.
- 0 Stripe write.
- 0 fake event.
- 0 checkout.
- 0 secret displayed.
