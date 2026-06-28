# PH-SAAS-T8.12AS.21.184-TER - BUILD CLIENT POST-OAUTH TRIAL READINESS PROD AFTER ESLINT FIX

Date: 2026-06-28
Phase: PH-SAAS-T8.12AS.21.184-TER
Type: BUILD
Environment target: PROD
Verdict: READY_NO_DEBTS

## Objective

Rebuild the Client PROD image after PH-21.184-BIS lint toolchain correction.

Reason:

- PH-21.184 built Client PROD image from commit `f349118c09db2228847575322669fae3c7577000`.
- PH-21.184-BIS fixed Client lint compatibility and pushed source commits after that build.
- Therefore, the old local Client image must not be pushed.

This phase rebuilds Client PROD from the current validated Client source.

No image push, no GitOps apply, no runtime mutation.

## Source Baseline

| Repo | Branch | HEAD | Status |
| --- | --- | --- | --- |
| keybuzz-client | ph148/onboarding-activation-replay | 7658a74133b6c7c2ed0693d13ad7906bf793d4e4 | clean, origin aligned |
| keybuzz-api | ph147.4/source-of-truth | 485a3f5a4f33daa006a03e02a4d1d15d10e767f6 | clean, origin aligned |
| keybuzz-infra | main | 803d03f3865ceb8f0b3660da1a0a4b9c6e6b7c84 | clean, origin aligned before report |

Build-from-git workspace:

`/tmp/ph21184-ter-client-build-20260628T101639Z`

## PH-21.184-BIS Correction Note

PH-21.184-BIS initially restored lint in the existing worktree, then clean-clone testing exposed that `FlatCompat + next/core-web-vitals` was not robust after `npm ci`.

Follow-up Client source commit:

`7658a74133b6c7c2ed0693d13ad7906bf793d4e4 chore(client): use clean eslint 9 flat config`

Final lint policy:

- Uses official Next 16 flat import `eslint-config-next/core-web-vitals`.
- Uses `eslint/config` `defineConfig` and `globalIgnores`.
- Keeps existing product behavior.
- Disables new React Compiler lint rules that would require broad historical refactors outside this promotion.
- `npm run lint` passes from a clean clone after `npm ci`.

## Registry Safety

Target tag was absent before build and remained absent after build:

| Image | Remote status |
| --- | --- |
| ghcr.io/keybuzzio/keybuzz-client:v3.5.269-eslint-toolchain-post-oauth-trial-readiness-prod | ABSENT |

No docker push was executed.

## Tests

| Check | Result |
| --- | --- |
| clean clone from `/opt/keybuzz/keybuzz-client` | PASS |
| checkout commit `7658a74133b6c7c2ed0693d13ad7906bf793d4e4` | PASS |
| `npm ci --legacy-peer-deps` | PASS, 0 vulnerabilities |
| `npm run lint` | PASS, 0 errors, 0 warnings |
| `node scripts/ph21182-post-oauth-trial-ux.test.cjs` | PASS |
| `node scripts/ph21172-start-latency-tests.mjs` | PASS |
| `npm run prebuild` | PASS |
| `npx tsc --noEmit --incremental false --pretty false` | PASS |
| source diff-check | PASS |

## Build Args

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
| GIT_COMMIT_SHA | 7658a74133b6c7c2ed0693d13ad7906bf793d4e4 |
| BUILD_TIME | 2026-06-28T10:16:39Z |
| IMAGE_REVISION | 7658a74133b6c7c2ed0693d13ad7906bf793d4e4 |
| IMAGE_CREATED | 2026-06-28T10:16:39Z |
| IMAGE_VERSION | v3.5.269-eslint-toolchain-post-oauth-trial-readiness-prod |

Build args guard result:

- production Clarity present.
- APP_ENV=production.
- API_URL=https://api.keybuzz.io.
- API_BASE_URL=https://api.keybuzz.io.

## Built Local Image

| Service | Local image | Image ID | Source commit |
| --- | --- | --- | --- |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.269-eslint-toolchain-post-oauth-trial-readiness-prod | sha256:dbc74545e7eed7125d769d8163a8246e8196125341bca1dbe34b5c537a5a85f4 | 7658a74133b6c7c2ed0693d13ad7906bf793d4e4 |

## Image Audits

| Check | Result |
| --- | --- |
| Next build | PASS |
| `https://api.keybuzz.io` present | PASS |
| `https://api-dev.keybuzz.io` absent | PASS |
| Clarity PROD marker present | PASS |
| GA4 PROD marker present | PASS |
| Meta Pixel PROD marker present | PASS |
| sGTM PROD marker present | PASS |
| TikTok PROD marker present | PASS |
| post-OAuth / trial UX markers | PASS |
| forbidden conversion marker audit | PASS, absent |

## API Image Status

The API image built in PH-21.184 remains valid and was not rebuilt:

| Service | Local image | Image ID | Source commit |
| --- | --- | --- | --- |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.277-playbooks-read-repair-prod | sha256:c40197f4bdf8753dd27a60d0b6c7decfa6596d93f461f7c3ee8084e03070e24b | 485a3f5a4f33daa006a03e02a4d1d15d10e767f6 |

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
- 0 StartTrial/Purchase/CompletePayment generated by CE/Codex.
- 0 CAPI test.

## AI Feature Parity / Anti-Regression

This build preserves the post-OAuth trial readiness scope:

- Inbox source lint dependencies stabilized, no runtime action.
- AI suggestion components lint dependencies stabilized, no AI behavior change.
- playbooks, Agent KeyBuzz, KBActions, marketplace connectors, orders, tracking and billing paths preserved.
- Future AI response humanness remains out of scope.

## Final Decision

Verdict: READY_NO_DEBTS.

Images ready to push:

- API: `ghcr.io/keybuzzio/keybuzz-api:v3.5.277-playbooks-read-repair-prod`
- Client: `ghcr.io/keybuzzio/keybuzz-client:v3.5.269-eslint-toolchain-post-oauth-trial-readiness-prod`

Recommended next GO:

`GO PUSH IMAGE API CLIENT POST-OAUTH TRIAL READINESS PROD PH-SAAS-T8.12AS.21.185`
