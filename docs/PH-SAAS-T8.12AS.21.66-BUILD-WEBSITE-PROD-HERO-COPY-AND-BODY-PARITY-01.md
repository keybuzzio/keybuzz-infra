# PH-SAAS-T8.12AS.21.66 - Build Website PROD hero copy and body parity

Date UTC: 2026-06-17
Mode: BUILD WEBSITE PROD strict
Environment: PROD build only, local image only
Verdict: READY_WITH_DEBTS

## Objective

Build the PROD Website image locally from the pushed Website source commit produced by
PH-21.65, using explicit PROD build arguments, then audit the image and static bundle.

No docker push, no latest mutation, no deploy, no kubectl apply, no manifest change,
no fake tracking event, no form submit, no checkout, no Webflow, no Linear, no PROD
runtime mutation.

## Bastion and safety

| Check | Result |
| --- | --- |
| Bastion host | install-v3 |
| Required IP | 46.62.171.61 present |
| Forbidden IP | 51.159.99.247 absent |
| Credentials paths | Not touched |
| Secrets paths | Not touched |

## Source state

### Website

| Field | Value |
| --- | --- |
| Repo | /opt/keybuzz/keybuzz-website |
| Remote | https://github.com/keybuzzio/keybuzz-website.git |
| Branch | main |
| HEAD | 4a12cfc801eda3d095bc43a984abc87522d6e41b |
| origin/main | 4a12cfc801eda3d095bc43a984abc87522d6e41b |
| Ahead/behind | 0/0 |
| Dirty | 0 |

### Infra before report commit

| Field | Value |
| --- | --- |
| Repo | /opt/keybuzz/keybuzz-infra |
| Branch | main |
| HEAD before docs report | 0975b941384f |
| origin/main before docs report | 0975b941384f |
| Ahead/behind before docs report | 0/0 |
| Dirty before docs report | 0 |

## Runtime baseline before build

| Environment | Image | Ready | Digest |
| --- | --- | --- | --- |
| Website DEV | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev | 1/1 | sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b |
| Website PROD | ghcr.io/keybuzzio/keybuzz-website:v0.6.22-clarity-restore-prod | 2/2 | sha256:974350d524ba80df77fcece54dc92156a9a3cc578d862e8cd1b2ffe21cee87ac |

## Target image

| Field | Value |
| --- | --- |
| Target tag | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod |
| Source commit | 4a12cfc801eda3d095bc43a984abc87522d6e41b |
| Build mode | docker build --no-cache from clean Git worktree |
| Docker push | Not executed |
| latest tag | Not touched |

Remote target tag was absent before and after the build. Remote latest manifest digest
remained unchanged.

## Explicit PROD build arguments

| Build arg | Value |
| --- | --- |
| NEXT_PUBLIC_SITE_MODE | production |
| NEXT_PUBLIC_CLIENT_APP_URL | https://client.keybuzz.io |
| NEXT_PUBLIC_CONTACT_API_URL | https://api.keybuzz.io/api/public/contact |
| NEXT_PUBLIC_SGTM_URL | https://t.keybuzz.pro |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | wrff07upjx |
| NEXT_PUBLIC_GA_ID | G-R3QQDYEBFG |
| NEXT_PUBLIC_META_PIXEL_ID | 1234164602194748 |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | D7PT12JC77U44OJIPC10 |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 |

Prebuild guard result:

```text
[WEBSITE-BUILD-ARGS-GUARD] OK (production): CLARITY=wrff07upjx META=1234164602194748 TIKTOK=D7PT12JC77U44OJIPC10 GA=G-R3QQDYEBFG
```

## Build result

| Check | Result |
| --- | --- |
| Docker build | PASS |
| Next.js compile | PASS |
| Static pages generated | 19 |
| Local image tag | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod |
| Local image ID | sha256:43fbf7e9f386ee8af74e68fb02c935cd87a6a8af7c449c178fad2d30896b6794 |
| Created | 2026-06-17T13:20:00.87721531Z |
| Size | 213665146 bytes |
| .next file count | 454 |

## OCI labels

| Label | Value |
| --- | --- |
| org.opencontainers.image.revision | 4a12cfc801eda3d095bc43a984abc87522d6e41b |
| org.opencontainers.image.version | v0.7.1-hero-copy-prod-body-parity-prod |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-website |
| org.opencontainers.image.title | keybuzz-website |

## Bundle audit

### Hero and body parity markers

| Marker | Count | Result |
| --- | ---: | --- |
| Reprenez le contr | 3 | PASS |
| marges | 3 | PASS |
| Vous validez | 9 | PASS |
| automatisez seulement | 3 | PASS |
| Ce que KeyBuzz change | 3 | PASS |
| Si vous vendez sur marketplace | 3 | PASS |

### PROD tracking and routing markers

| Marker | Count | Result |
| --- | ---: | --- |
| client.keybuzz.io | 33 | PASS |
| api.keybuzz.io/api/public/contact | 2 | PASS |
| t.keybuzz.pro | 18 | PASS |
| wrff07upjx | 2 | PASS |
| G-R3QQDYEBFG | 18 | PASS |
| 1234164602194748 | 2 | PASS |
| D7PT12JC77U44OJIPC10 | 2 | PASS |
| 9969977 | 18 | PASS |

### Forbidden DEV and obsolete business markers

| Marker | Count | Result |
| --- | ---: | --- |
| client-dev.keybuzz.io | 0 | PASS |
| api-dev.keybuzz.io | 0 | PASS |
| v0.7.1-hero-copy-prod-body-parity-dev | 0 | PASS |
| 49 EUR | 0 | PASS |
| 199 EUR | 0 | PASS |
| 49e/mois | 0 | PASS |
| 199e/mois | 0 | PASS |
| -84 | 0 | PASS |

### No fake metrics / no fake events

| Marker | Count | Result |
| --- | ---: | --- |
| StartTrial | 0 | PASS |
| Purchase | 0 | PASS |
| CompletePayment | 0 | PASS |
| InitiateCheckout | 0 | PASS |
| Lead | 3 | REVIEWED_NON_BLOCKING |

The three "Lead" occurrences are comments or guard text in the built source bundle, not
runtime conversion calls. Source context checked:

- src/lib/marketing-tracking.ts: comment states no Lead, no Purchase, no Signup.
- src/lib/tracking.ts: comments document business conversions, including "Lead final".
- src/lib/tracking.ts: active tracking remains PageView, ViewContent, marketing CTA click
  and Contact; no fake Lead trigger was introduced.

## Runtime after build

| Environment | Image | Ready | Digest | Result |
| --- | --- | --- | --- | --- |
| Website DEV | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev | 1/1 | sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b | Unchanged |
| Website PROD | ghcr.io/keybuzzio/keybuzz-website:v0.6.22-clarity-restore-prod | 2/2 | sha256:974350d524ba80df77fcece54dc92156a9a3cc578d862e8cd1b2ffe21cee87ac | Unchanged |

## Source checks

| Check | Result |
| --- | --- |
| PH-21.65 source scope | src/app/page.tsx only |
| git diff --check | PASS |
| npx eslint src/app/page.tsx | PASS |
| npm run lint | FAIL_PREEXISTING |

Global lint remains a pre-existing repository debt already observed in PH-21.65:
275 problems, including 258 errors and 17 warnings. It is not introduced by PH-21.66.

## Dependency audit debt

The Docker build ran npm ci and reported 9 vulnerabilities:

- 1 low
- 4 moderate
- 4 high

This is tracked as dependency hygiene debt and did not block the strict local build.

## Non-regression summary

| Area | Result |
| --- | --- |
| Build from clean Git commit | PASS |
| Explicit PROD build args | PASS |
| PROD API/contact/client URLs | PASS |
| DEV URLs absent | PASS |
| Clarity/GA4/Meta/TikTok/LinkedIn PROD IDs present | PASS |
| Obsolete prices/KPI absent | PASS |
| Fake conversion triggers absent | PASS |
| Docker push absent | PASS |
| latest unchanged | PASS |
| DEV runtime unchanged | PASS |
| PROD runtime unchanged | PASS |
| Manifest mutation absent | PASS |
| Webflow/Linear absent | PASS |

## Debts

1. Global Website lint remains failing due pre-existing repository-wide issues.
2. npm audit reports 9 vulnerabilities during npm ci.
3. The image is local only and still requires PH-21.67 to push the target immutable tag.
4. PROD deployment remains untouched and still requires a separate explicit GitOps GO after
   image push.

## Verdict

GO BUILD WEBSITE PROD HERO COPY AND BODY PARITY READY_WITH_DEBTS PH-SAAS-T8.12AS.21.66

Next GO:

GO PUSH IMAGE WEBSITE PROD HERO COPY AND BODY PARITY PH-SAAS-T8.12AS.21.67
