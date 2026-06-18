# PH-SAAS-T8.12AS.21.71 - Readonly design Website PROD visual hero parity from preview

## Verdict

READY_SOURCE_PATCH_REQUIRED

Next GO:

```text
GO SOURCE PATCH WEBSITE PROD VISUAL HERO PARITY FROM PREVIEW PH-SAAS-T8.12AS.21.72
```

## Scope

Mode: READONLY DESIGN WEBSITE PROD strict.

No source patch, no build, no docker push, no deploy, no kubectl apply, no event tracking,
no form submit, no checkout, no Webflow, no Linear.

Only authorized mutation: this docs-only infra report commit and push.

## Bastion and repos

| Check | Result |
| --- | --- |
| Bastion IP required | 46.62.171.61 present |
| Forbidden IP | 51.159.99.247 absent |
| Website repo | /opt/keybuzz/keybuzz-website |
| Website branch | main |
| Website HEAD | 4a12cfc801eda3d095bc43a984abc87522d6e41b |
| Website origin/main | 4a12cfc801eda3d095bc43a984abc87522d6e41b |
| Website origin/redesign-light | dfb299b6facbbe17cf36d9085aeed2ee8908e151 |
| Website ahead/behind | 0/0 |
| Infra branch | main |
| Infra HEAD before report | f127bc5b54e9876381485c8ab516366644a8e3c3 |
| Infra origin/main before report | f127bc5b54e9876381485c8ab516366644a8e3c3 |
| Infra ahead/behind before report | 0/0 |

## Runtime read-only

| Environment | Image | Ready | Generation |
| --- | --- | --- | --- |
| Website PROD | `ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod` | 2/2 | 37/37 |
| Website DEV preview reference | `ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev` | 1/1 | 69/69 |

Expected PROD digest from PH-21.70: `sha256:b28814ff31125f9e6566a78cfae5e90acd99fc14f22d2769602cb22677a1e46b`.

Runtime PROD is on the expected v0.7.1 image. Therefore the missing preview visual hero is
not explained first by an unapplied GitOps manifest or by PROD still running v0.6.22.

## Source comparison

Compared refs:

- PROD source: `origin/main` at `4a12cfc801eda3d095bc43a984abc87522d6e41b`
- Preview source reference: `origin/redesign/light-business` at `dfb299b6facbbe17cf36d9085aeed2ee8908e151`

Design diff:

```text
 src/app/layout.tsx                |   5 +-
 src/app/page.tsx                  | 348 ++++++++++++++++++++++++++++++--------
 src/components/kb2/Icon.tsx       |  60 +++++++
 src/components/kb2/WaveCanvas.tsx | 137 +++++++++++++++
 src/components/kb2/primitives.tsx | 123 ++++++++++++++
 src/styles/kb2.css                | 293 ++++++++++++++++++++++++++++++++
 6 files changed, 893 insertions(+), 73 deletions(-)
```

Name status:

```text
M	src/app/layout.tsx
M	src/app/page.tsx
A	src/components/kb2/Icon.tsx
A	src/components/kb2/WaveCanvas.tsx
A	src/components/kb2/primitives.tsx
A	src/styles/kb2.css
```

Numstat:

```text
3	2	src/app/layout.tsx
277	71	src/app/page.tsx
60	0	src/components/kb2/Icon.tsx
137	0	src/components/kb2/WaveCanvas.tsx
123	0	src/components/kb2/primitives.tsx
293	0	src/styles/kb2.css
```

Package or lockfile diff:

```text
none
```

Key source markers:

| Marker | origin/main | origin/redesign/light-business |
| --- | ---: | ---: |
| `layout imports kb2.css` | 0 | 1 |
| `page.tsx WaveCanvas` | 0 | 2 |
| `page.tsx kb2-* classes` | 0 | 2 |
| `page.tsx Reprenez le contr` | 1 | 1 |

### origin/main marker table

| Marker | Count in origin/main |
| --- | ---: |
| `Reprenez le contr` | 1 |
| `marges` | 1 |
| `Vous validez` | 4 |
| `automatisez seulement` | 1 |
| `WaveCanvas` | 0 |
| `src/components/kb2` | 0 |
| `styles/kb2.css` | 0 |
| `kb2-` | 0 |
| `client.keybuzz.io` | 19 |
| `client-dev.keybuzz.io` | 3 |
| `api.keybuzz.io/api/public/contact` | 4 |
| `api-dev.keybuzz.io` | 2 |
| `t.keybuzz.pro` | 2 |
| `wrff07upjx` | 4 |
| `G-R3QQDYEBFG` | 3 |
| `1234164602194748` | 3 |
| `D7PT12JC77U44OJIPC10` | 3 |
| `9969977` | 2 |
| `StartTrial` | 1 |
| `Purchase` | 2 |
| `CompletePayment` | 1 |
| `InitiateCheckout` | 2 |
| `Lead` | 3 |
| `checkout.stripe.com` | 0 |
| `preview.keybuzz.pro` | 2 |
| `49 EUR` | 0 |
| `199 EUR` | 0 |
| `-84` | 0 |

### origin/redesign/light-business marker table

| Marker | Count in origin/redesign/light-business |
| --- | ---: |
| `Reprenez le contr` | 1 |
| `marges` | 1 |
| `Vous validez` | 4 |
| `automatisez seulement` | 1 |
| `WaveCanvas` | 4 |
| `src/components/kb2` | 0 |
| `styles/kb2.css` | 1 |
| `kb2-` | 13 |
| `client.keybuzz.io` | 19 |
| `client-dev.keybuzz.io` | 3 |
| `api.keybuzz.io/api/public/contact` | 4 |
| `api-dev.keybuzz.io` | 2 |
| `t.keybuzz.pro` | 2 |
| `wrff07upjx` | 4 |
| `G-R3QQDYEBFG` | 3 |
| `1234164602194748` | 3 |
| `D7PT12JC77U44OJIPC10` | 3 |
| `9969977` | 2 |
| `StartTrial` | 1 |
| `Purchase` | 2 |
| `CompletePayment` | 1 |
| `InitiateCheckout` | 2 |
| `Lead` | 3 |
| `checkout.stripe.com` | 0 |
| `preview.keybuzz.pro` | 2 |
| `49 EUR` | 0 |
| `199 EUR` | 0 |
| `-84` | 0 |

## Precise explanation

PROD does have the PH-21.58/PH-21.65 hero copy. It does not have the same visual hero as
`preview.keybuzz.pro` because PH-21.65 deliberately patched only `src/app/page.tsx` on
`main` with copy-level changes compatible with the existing PROD page.

The preview visual system is not only text in `page.tsx`. It is a multi-file visual layer
from `redesign/light-business`:

- `src/app/layout.tsx` imports the kb2 stylesheet.
- `src/styles/kb2.css` defines the visual tokens, hero layout, animations, and kb2 classes.
- `src/components/kb2/WaveCanvas.tsx` provides the hero canvas/visual motion layer.
- `src/components/kb2/Icon.tsx` and `src/components/kb2/primitives.tsx` provide the
  supporting visual primitives.
- `src/app/page.tsx` in the redesign branch references that system through `WaveCanvas`
  and kb2 classes.

PH-21.65 explicitly did not port `layout/kb2/styles`, did not merge
`redesign/light-business`, and did not touch `src/components/kb2/*` or
`src/styles/kb2.css`. The result is expected: PROD runs the new copy/body parity image,
but it still renders the old `main` visual shell.

This is not a cache diagnosis by default. Runtime equality already proves PROD is running
the current v0.7.1 image and digest. The source delta explains the visual mismatch.

## Passive public check

No auth bypass and no secret used.

| Host | Result |
| --- | --- |
| www.keybuzz.pro | rc=0 http=200 bytes=72766 url=https://www.keybuzz.pro/ |
| www markers | Reprenez=1, kb2=0 |
| preview.keybuzz.pro | rc=60 curl: (60) SSL certificate problem: self-signed certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
http=000 bytes=0 url=https://preview.keybuzz.pro/ |
| preview markers | Reprenez=0, kb2=0 |

If preview is blocked by certificate/auth, this is non-blocking for the source design:
the git diff identifies the visual system that PROD does not currently include.

## Tracking and CTA safety notes

No tracking event was triggered. No form or checkout was submitted.

The PH-21.72 patch must preserve the existing PROD tracking contract:

- keep PROD URLs and IDs from explicit build args;
- keep `client.keybuzz.io` and `api.keybuzz.io/api/public/contact`;
- keep `t.keybuzz.pro`, Clarity, GA4, Meta, TikTok, and LinkedIn gates;
- keep attribution forwarding for UTM/click IDs;
- do not introduce direct fake `StartTrial`, `Purchase`, `CompletePayment`,
  `InitiateCheckout`, or `Lead` conversion triggers.

## Minimal source patch design for PH-21.72

Target repo and branch:

- repo: `/opt/keybuzz/keybuzz-website`
- branch: `main`
- base: `4a12cfc801eda3d095bc43a984abc87522d6e41b`

Patch principle:

Do not merge `redesign/light-business`. Port only the visual hero dependencies required
to make PROD render the same first-viewport hero as preview, while preserving the existing
PROD body, routes, CTA behavior, tracking, contact, legal, and build args.

Minimal expected source changes:

1. Add from `origin/redesign/light-business`:
   - `src/components/kb2/Icon.tsx`
   - `src/components/kb2/WaveCanvas.tsx`
   - `src/components/kb2/primitives.tsx`
   - `src/styles/kb2.css`
2. Modify `src/app/layout.tsx` only to import `../styles/kb2.css`, preserving metadata
   and all existing tracking/layout behavior.
3. Modify `src/app/page.tsx` only for the hero visual block and imports required by that
   hero. Keep the existing PROD body sections and existing CTA/forwarding behavior unless
   a line is strictly required by the hero visual.
4. Do not touch:
   - tracking files or server-side tracking;
   - pricing/contact/legal pages;
   - build args docs except PH report if needed;
   - GitOps manifests;
   - package or lockfiles unless an offline test proves a required dependency gap.

Acceptance gates for PH-21.72:

- `git diff --name-only` contains only the intended Website source files and docs report.
- `git diff --check` passes.
- targeted ESLint on touched files passes, or only pre-existing global lint debt is reported.
- source grep proves PROD URLs/IDs are preserved and DEV URLs are not introduced.
- no direct fake conversion trigger is added.
- no Docker build, docker push, deploy, kubectl apply, form, checkout, event tracking,
  Webflow, Linear, or PROD runtime mutation in PH-21.72 unless the GO explicitly changes scope.

Recommended following phases after PH-21.72:

1. push source patch;
2. build Website PROD from clean Git with explicit PROD build args;
3. push immutable image tag;
4. GitOps apply Website PROD by manifest commit/push then `kubectl apply -f`;
5. readonly verify with desktop/mobile visual evidence and passive tracking/network audit.

## Raw audit excerpts

See local raw file on bastion for command transcript:

`/tmp/ph2171/raw.txt`

## Final verdict

```text
GO READONLY DESIGN WEBSITE PROD VISUAL HERO PARITY FROM PREVIEW READY_SOURCE_PATCH_REQUIRED PH-SAAS-T8.12AS.21.71
```

Next GO:

```text
GO SOURCE PATCH WEBSITE PROD VISUAL HERO PARITY FROM PREVIEW PH-SAAS-T8.12AS.21.72
```
