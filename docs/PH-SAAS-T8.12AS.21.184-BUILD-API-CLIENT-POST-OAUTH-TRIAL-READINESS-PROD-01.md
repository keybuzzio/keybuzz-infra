# PH-SAAS-T8.12AS.21.184 - BUILD API CLIENT POST-OAUTH TRIAL READINESS PROD

Date: 2026-06-28
Phase: PH-SAAS-T8.12AS.21.184
Type: BUILD
Environment target: PROD
Verdict: READY_WITH_DEBTS

## Objective

Build PROD API and Client images for the post-OAuth trial readiness promotion designed in PH-21.183.

No image push, no GitOps apply, no runtime mutation.

## Source Baseline

| Repo | Branch | HEAD | Status |
| --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 485a3f5a4f33daa006a03e02a4d1d15d10e767f6 | clean, origin aligned |
| keybuzz-client | ph148/onboarding-activation-replay | f349118c09db2228847575322669fae3c7577000 | clean, origin aligned |
| keybuzz-infra | main | 63bc877afcf3614f49832bffcce2aa2a691e5898 | clean, origin aligned before report |

Build-from-git workspace:

`/tmp/ph21184-build-20260628T091110Z`

## Registry Safety

Target tags were absent before build and remained absent after build:

| Image | Remote status |
| --- | --- |
| ghcr.io/keybuzzio/keybuzz-api:v3.5.277-playbooks-read-repair-prod | ABSENT |
| ghcr.io/keybuzzio/keybuzz-client:v3.5.268-post-oauth-trial-readiness-prod | ABSENT |

No docker push was executed.

## Tests

### API

| Check | Result |
| --- | --- |
| npm ci | PASS, 0 vulnerabilities |
| `npx ts-node src/tests/ph21182-starter-playbook-activation-tests.ts` | PASS |
| `npx ts-node src/tests/ph21182-playbooks-read-repair-tests.ts` | PASS |
| `npx ts-node src/tests/ph21177-activate-amazon-idempotent-tests.ts` | PASS |
| `npx ts-node src/tests/ph21172-start-latency-tests.ts` | PASS |
| `npx tsc --noEmit` | PASS |
| source diff-check | PASS |

### Client

| Check | Result |
| --- | --- |
| npm ci --legacy-peer-deps | PASS, 0 vulnerabilities |
| `node scripts/ph21182-post-oauth-trial-ux.test.cjs` | PASS |
| `node scripts/ph21172-start-latency-tests.mjs` | PASS |
| `npm run prebuild` | PASS |
| `npx tsc --noEmit --incremental false --pretty false` | PASS |
| source diff-check | PASS |
| targeted ESLint | SKIPPED_PREEXISTING_ESLINT_CONFIG_INCOMPATIBLE |

Targeted ESLint debt detail:

- Local Client has `.eslintrc.json`.
- Current dependency set resolves ESLint/Next in a way that throws a circular config error.
- This was not introduced by PH-21.184.
- Build and TypeScript remain green.
- Recommended debt ticket/phase: migrate Client lint config to supported flat config or pin compatible lint toolchain.

## Build Args

### API

| Build arg | Value |
| --- | --- |
| IMAGE_REVISION | 485a3f5a4f33daa006a03e02a4d1d15d10e767f6 |
| IMAGE_CREATED | 2026-06-28T09:11:10Z |
| IMAGE_VERSION | v3.5.277-playbooks-read-repair-prod |

### Client

| Build arg | Value |
| --- | --- |
| NEXT_PUBLIC_APP_ENV | production |
| NEXT_PUBLIC_API_URL | https://api.keybuzz.io |
| NEXT_PUBLIC_API_BASE_URL | https://api.keybuzz.io |
| NEXT_PUBLIC_GA4_MEASUREMENT_ID | G-R3QQDYEBFG |
| NEXT_PUBLIC_META_PIXEL_ID | 1234164602194748 |
| NEXT_PUBLIC_SGTM_URL | https://t.keybuzz.pro |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | D7PT12JC77U44OJIPC10 |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | wuk12h9i33 |
| GIT_COMMIT_SHA | f349118c09db2228847575322669fae3c7577000 |
| BUILD_TIME | 2026-06-28T09:11:10Z |
| IMAGE_REVISION | f349118c09db2228847575322669fae3c7577000 |
| IMAGE_CREATED | 2026-06-28T09:11:10Z |
| IMAGE_VERSION | v3.5.268-post-oauth-trial-readiness-prod |

Client build args guard result:

- production Clarity present.
- APP_ENV=production.
- API_URL=https://api.keybuzz.io.
- API_BASE_URL=https://api.keybuzz.io.

## Built Local Images

| Service | Local image | Image ID | Source commit |
| --- | --- | --- | --- |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.277-playbooks-read-repair-prod | sha256:c40197f4bdf8753dd27a60d0b6c7decfa6596d93f461f7c3ee8084e03070e24b | 485a3f5a4f33daa006a03e02a4d1d15d10e767f6 |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.268-post-oauth-trial-readiness-prod | sha256:d48f6ecf413bf09cbd2daab7ac3808e8758fb3e27c8a6ac4c3ce814fc9abad60 | f349118c09db2228847575322669fae3c7577000 |

## Image Audits

### API

| Check | Result |
| --- | --- |
| dist exists | PASS |
| starter playbook markers | PASS |
| playbook read-repair markers | PASS |
| Amazon activation markers | PASS |
| tenant id markers | PASS |
| dist/tests absent | PASS |

### Client

| Check | Result |
| --- | --- |
| Next build | PASS |
| `https://api.keybuzz.io` present | PASS |
| `https://api-dev.keybuzz.io` absent | PASS |
| Clarity PROD marker present | PASS |
| GA4 PROD marker present | PASS |
| sGTM PROD marker present | PASS |
| post-OAuth / trial UX markers | PASS |
| forbidden conversion marker audit | REVIEWED_NON_BLOCKING |

Conversion marker review:

- `Purchase` appears in real KBActions/Stripe UI and billing code.
- `src/lib/tracking.ts` explicitly documents Meta Purchase and CompletePayment removed from browser-side tracking and kept server-side.
- No fake event was triggered by this phase.

## PROD Runtime Post-Build

PROD runtime unchanged after build:

| Service | Runtime image | Generation | Ready |
| --- | --- | --- | --- |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.275-ai-journal-startup-ddl-prod | 436/436 | 1 |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.267-start-onboarding-latency-prod | 434/434 | 1 |

## No Fake Metrics / No Fake Events

Confirmed:

- 0 docker push.
- 0 GitOps apply.
- 0 deploy.
- 0 DB mutation.
- 0 Stripe write.
- 0 checkout.
- 0 fake `POST /funnel/event`.
- 0 StartTrial/Purchase/CompletePayment generated by CE.
- 0 CAPI test.

## AI Feature Parity / Anti-Regression

This build preserves source scope from PH-21.182:

- Inbox untouched.
- messages untouched.
- AI drafts untouched.
- AI automatic responses untouched.
- playbooks starter activation/read repair present.
- escalations untouched.
- Agent KeyBuzz gating unchanged.
- KBActions existing purchase UI preserved.
- marketplace connectors preserved.
- orders sync post-OAuth present.
- billing conversion paths preserved.

The future AI response humanness improvement remains out of scope.

## Rollback Reference

| Service | Rollback image | Digest |
| --- | --- | --- |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.275-ai-journal-startup-ddl-prod | sha256:ad5950ee3bf86b7980fde0005a778565956ff1f6c931b2b8d6877f94b39157f8 |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.267-start-onboarding-latency-prod | sha256:ae5de89ed95da058ece6f93d85ae6a2f925d8aa6d1b437ae6f0dde06a1b5dbc0 |

## Final Decision

Verdict: READY_WITH_DEBTS.

Build output is usable for image push, with one non-runtime debt:

- Client targeted ESLint cannot currently run because the Client lint config/toolchain is incompatible.

Recommended next GO:

`GO PUSH IMAGE API CLIENT POST-OAUTH TRIAL READINESS PROD PH-SAAS-T8.12AS.21.185`

If strict zero-debt is required before push, recommended alternative:

`GO SOURCE PATCH CLIENT ESLINT TOOLCHAIN COMPATIBILITY DEV PH-SAAS-T8.12AS.21.184-BIS`
