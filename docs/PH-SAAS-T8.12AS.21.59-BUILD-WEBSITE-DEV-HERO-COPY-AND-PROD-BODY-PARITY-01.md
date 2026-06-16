# PH-SAAS-T8.12AS.21.59 - BUILD WEBSITE DEV HERO COPY AND PROD BODY PARITY

Date UTC: 2026-06-16
Role: Codex Executor
Projet: KeyBuzz SaaS / Website / Design / Acquisition tracking
Mode: BUILD WEBSITE DEV only

## 1. Verdict

GO BUILD WEBSITE DEV HERO COPY AND PROD BODY PARITY READY_WITH_DEBTS PH-SAAS-T8.12AS.21.59

Image locale DEV construite depuis Git propre `dfb299b6facbbe17cf36d9085aeed2ee8908e151` :

`ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev`

Image locale qualifiee :

- Image ID: `sha256:0f552f8b55093a9afadfc56418ffde9144c8e1d8a6de6ea981077004549161bc`
- OCI revision: `dfb299b6facbbe17cf36d9085aeed2ee8908e151`
- OCI version: `v0.7.1-hero-copy-prod-body-parity-dev`
- GHCR tag target: still `manifest unknown`, not pushed
- Runtime Website DEV/PROD unchanged

Debts / notes:

- `npm ci` reports 9 npm audit vulnerabilities from existing dependency tree; no dependency patch was allowed in this build-only phase.
- Global Website lint debt remains pre-existing; targeted `npx eslint src/app/page.tsx` passed before build.
- Visual QA remains deferred until a DEV runtime deploy/verify phase.

## 2. Sources reread

| Source | Status |
| --- | --- |
| `PH-21.59_CE_MISSION.md` | read |
| `AI_MEMORY/CURRENT_STATE.md` | read |
| `AI_MEMORY/RULES_AND_RISKS.md` | read |
| `AI_MEMORY/DOCUMENT_MAP.md` | read |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | read |
| `PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01` | read |
| `PH-21.58_CE_MISSION.md` | read |
| `PH-21.58_CE_RETURN.md` | read |
| `PH-21.58_PUSH_CE_RETURN.md` | read |
| PH-21.58 remote report | read |
| PH-21.57 remote report | read |
| `keybuzz-website/docs/BUILD-ARGS.md` | read |
| `keybuzz-infra/docs/WEBSITE-AGENT-CONTEXT.md` | read |
| PH-20.10B Website DEV build report | read |
| PH-21.55 / PH-21.56 / PH-WEBSITE tracking and PH-20.15 build-args context | read targeted |

## 3. Preflight

| Control | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| Bastion | `install-v3` | `install-v3` | OK |
| IP | `46.62.171.61` | present in `hostname -I` | OK |
| Forbidden IP | no `51.159.99.247` | not used | OK |
| Date UTC | current | `Tue Jun 16 12:17:01 PM UTC 2026` | OK |
| Website DEV runtime | `v0.7.0-redesign-light-dev` | `v0.7.0-redesign-light-dev`, ready `1/1` | OK |
| Website PROD runtime | `v0.6.22-clarity-restore-prod` | `v0.6.22-clarity-restore-prod`, ready `2/2` | OK |
| GHCR target tag before build | absent | `manifest unknown` | OK |

## 4. Source Git audit

| Repo | Branch | HEAD | Origin | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| keybuzz-website | `redesign/light-business` | `dfb299b6facbbe17cf36d9085aeed2ee8908e151` | same | 0/0 | 0 | OK |

Commit scope:

| Commit | File | Expected scope | Verdict |
| --- | --- | --- | --- |
| `dfb299b` | `src/app/page.tsx` | PH-21.58 hero copy + PROD body parity | OK |

Checks:

| Check | Result |
| --- | --- |
| `git diff --check HEAD~1..HEAD` | PASS |
| `npx eslint src/app/page.tsx` | PASS |
| PH-21.58 hero markers in source | PASS |
| restored sections in source | PASS |
| obsolete homepage pricing / `-84` / `AW-` in `src/app/page.tsx` | absent |

## 5. Baseline tracking DEV before build

Baseline was read from the current running Website DEV pod bundle `/app/.next`, read-only. No public pageview, no form, no checkout, no provider event.

| Marker | Baseline DEV observed | PH-21.59 expected | Reason |
| --- | ---: | ---: | --- |
| `client-dev.keybuzz.io` | 3 | present | DEV client URL baseline |
| `api-dev.keybuzz.io/api/public/contact` | 2 | present | DEV contact endpoint baseline |
| `api.keybuzz.io/api/public/contact` | 0 | 0 | no PROD contact endpoint in DEV image |
| `t.keybuzz.pro` | 0 | 0 in bundle with GA empty | build arg passed, but Analytics renders nothing if all IDs empty |
| `G-R3QQDYEBFG` | 0 | 0 | GA4 absent in current v0.7.0 DEV baseline |
| `9969977` | 0 | 0 | LinkedIn absent in current v0.7.0 DEV baseline |
| `1234164602194748` | 0 | 0 | Meta absent in DEV baseline |
| `D7PT12JC77U44OJIPC10` | 0 | 0 | TikTok absent in DEV baseline |
| `wrff07upjx` | 0 | 0 | Clarity Website absent in DEV baseline |
| `Lead` | 3 | 3 | existing guard/comment string baseline, no new business event |
| `StartTrial` | 0 | 0 | server-side only, no browser event |
| `Purchase` | 0 | 0 | server-side only, no browser event |
| `CompletePayment` | 0 | 0 | server-side only, no browser event |
| `InitiateCheckout` | 0 | 0 | no browser conversion event |
| `AW-` | 0 | 0 | no direct Google Ads tag |

Decision: do not copy PROD tracking contract into DEV. Use explicit DEV args and keep GA/LinkedIn/Clarity/Meta/TikTok empty, matching the current DEV runtime baseline.

## 6. Build args

| Arg | Value passed | Source of decision | Verdict |
| --- | --- | --- | --- |
| `NEXT_PUBLIC_SITE_MODE` | `preview` | PH-21.59 + DEV contract | OK |
| `NEXT_PUBLIC_CLIENT_APP_URL` | `https://client-dev.keybuzz.io` | DEV contract + baseline | OK |
| `NEXT_PUBLIC_CONTACT_API_URL` | `https://api-dev.keybuzz.io/api/public/contact` | DEV contract + baseline | OK |
| `NEXT_PUBLIC_SGTM_URL` | `https://t.keybuzz.pro` | PH-21.59 mandatory arg; no rendered marker because GA empty | OK |
| `NEXT_PUBLIC_GA_ID` | empty | current DEV baseline count 0 | OK |
| `NEXT_PUBLIC_LINKEDIN_PARTNER_ID` | empty | current DEV baseline count 0 | OK |
| `NEXT_PUBLIC_CLARITY_PROJECT_ID` | empty | current DEV baseline count 0 | OK |
| `NEXT_PUBLIC_META_PIXEL_ID` | empty | current DEV baseline count 0 | OK |
| `NEXT_PUBLIC_TIKTOK_PIXEL_ID` | empty | current DEV baseline count 0 | OK |
| `IMAGE_REVISION` | `dfb299b6facbbe17cf36d9085aeed2ee8908e151` | Git HEAD | OK |
| `IMAGE_CREATED` | `2026-06-16T12:20:44Z` | UTC build time | OK |
| `IMAGE_VERSION` | `v0.7.1-hero-copy-prod-body-parity-dev` | target tag | OK |

## 7. Worktree build-from-git

| Worktree | Commit | Dirty | Verdict |
| --- | --- | --- | --- |
| `/opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.21.59-WEBSITE-DEV/keybuzz-website` | `dfb299b6facbbe17cf36d9085aeed2ee8908e151` | 0 | OK |

The worktree was created detached from the pushed source commit. Build was not run from pod/runtime/dist/SCP.

## 8. Docker build

Build command (no secrets, no push):

```bash
docker build --no-cache \
  --build-arg NEXT_PUBLIC_SITE_MODE=preview \
  --build-arg NEXT_PUBLIC_CLIENT_APP_URL=https://client-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_GA_ID= \
  --build-arg NEXT_PUBLIC_META_PIXEL_ID= \
  --build-arg NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro \
  --build-arg NEXT_PUBLIC_TIKTOK_PIXEL_ID= \
  --build-arg NEXT_PUBLIC_LINKEDIN_PARTNER_ID= \
  --build-arg NEXT_PUBLIC_CLARITY_PROJECT_ID= \
  --build-arg NEXT_PUBLIC_CONTACT_API_URL=https://api-dev.keybuzz.io/api/public/contact \
  --build-arg IMAGE_REVISION=dfb299b6facbbe17cf36d9085aeed2ee8908e151 \
  --build-arg IMAGE_CREATED=2026-06-16T12:20:44Z \
  --build-arg IMAGE_VERSION=v0.7.1-hero-copy-prod-body-parity-dev \
  -t ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev \
  .
```

| Image | Build exit | Image ID | Size | Created | Verdict |
| --- | ---: | --- | ---: | --- | --- |
| `ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev` | 0 | `sha256:0f552f8b55093a9afadfc56418ffde9144c8e1d8a6de6ea981077004549161bc` | 213707447 bytes | `2026-06-16T12:23:05.073659801Z` | OK |

Build notes:

- `scripts/check-website-build-args.sh` skipped enforcement as expected: `NEXT_PUBLIC_SITE_MODE=preview`.
- Next.js build compiled successfully and generated 19 static routes.
- `npm ci` emitted existing audit warnings: 9 vulnerabilities. No dependency mutation was allowed.

## 9. OCI labels and image inspection

| Label / field | Observed | Verdict |
| --- | --- | --- |
| Image ID | `sha256:0f552f8b55093a9afadfc56418ffde9144c8e1d8a6de6ea981077004549161bc` | OK |
| `org.opencontainers.image.revision` | `dfb299b6facbbe17cf36d9085aeed2ee8908e151` | OK |
| `org.opencontainers.image.version` | `v0.7.1-hero-copy-prod-body-parity-dev` | OK |
| `org.opencontainers.image.source` | `https://github.com/keybuzzio/keybuzz-website` | OK |
| `org.opencontainers.image.title` | `keybuzz-website` | OK |
| `org.opencontainers.image.created` | `2026-06-16T12:20:44Z` | OK |
| `/app/.next` file count | 454 | OK |

## 10. Bundle audit

| Marker | Expected | Count image | Verdict |
| --- | ---: | ---: | --- |
| `Reprenez le controle de votre SAV` equivalent with accents | >0 | 3 | OK |
| `protege vos marges` equivalent with accents | >0 | 3 | OK |
| `Vous validez` | >0 | 9 | OK |
| `automatisez seulement ce qui est sur` equivalent with accents | >0 | 3 | OK |
| `Si vous vendez sur marketplace` | >0 | 3 | OK |
| `Comment ca marche` equivalent with accents | >0 | 3 | OK |
| `Ce que KeyBuzz change` | >0 | 3 | OK |
| `Securite & protection` equivalent with accents | >0 | 2 | OK |
| `Marketplaces & Integrations` equivalent with accents | >0 | 2 | OK |
| `Questions frequentes` equivalent with accents | >0 | 14 | OK |
| `49 EUR`/`49 euro` homepage obsolete variants (`49 EUR`, `49EUR`) | 0 | 0 | OK |
| `199 EUR`/`199 euro` homepage obsolete variants (`199 EUR`, `199EUR`) | 0 | 0 | OK |
| `-84` / Unicode minus variant | 0 | 0 | OK |
| `api.keybuzz.io/api/public/contact` | 0 | 0 | OK |
| `api-dev.keybuzz.io/api/public/contact` | >0 | 2 | OK |
| `client-dev.keybuzz.io` | >0 | 3 | OK |
| `t.keybuzz.pro` | 0 with GA empty | 0 | OK |
| `G-R3QQDYEBFG` | 0 | 0 | OK |
| `9969977` | 0 | 0 | OK |
| `1234164602194748` | 0 | 0 | OK |
| `D7PT12JC77U44OJIPC10` | 0 | 0 | OK |
| `wrff07upjx` | 0 | 0 | OK |
| `Lead` | baseline 3 | 3 | OK, no delta |
| `StartTrial` | 0 | 0 | OK |
| `Purchase` | 0 | 0 | OK |
| `CompletePayment` | 0 | 0 | OK |
| `InitiateCheckout` | 0 | 0 | OK |
| `AW-` | 0 | 0 | OK |

## 11. GHCR / latest / runtime preservation

| Surface | Before | After | Verdict |
| --- | --- | --- | --- |
| GHCR target tag | `manifest unknown` | `manifest unknown` | OK, not pushed |
| Website DEV runtime | `v0.7.0-redesign-light-dev` | same, ready `1/1`, restarts `0` | OK |
| Website PROD runtime | `v0.6.22-clarity-restore-prod` | same, ready `2/2`, restarts `0` | OK |
| `latest` | no command touched it | no command touched it | OK |
| Docker push | 0 | 0 | OK |

## 12. Cleanup

| Action | Result |
| --- | --- |
| `git worktree remove` for PH-21.59 worktree | OK |
| `rmdir` empty build root | OK |
| Main Website repo dirty | 0 |
| Local image | kept for next push-image phase |

No `git clean` was used.

## 13. AI feature parity / anti-regression

| Surface | Result |
| --- | --- |
| `keybuzz-api` | not modified, no build/deploy |
| `keybuzz-client` | not modified, no build/deploy |
| `keybuzz-backend` | not modified, no build/deploy |
| `keybuzz-admin-v2` | not modified, no build/deploy |
| KBActions | unchanged |
| Amazon outbound | unchanged |
| LLM provider watcher / monitoring-alerts | unchanged |
| CAPI token encryption | unchanged |

Read-only dirty counts in those repos were pre-existing where non-zero and were not touched.

## 14. No fake metrics / no fake events

| Interdit | Result |
| --- | --- |
| Docker push | 0 |
| Deploy / kubectl apply | 0 |
| `kubectl set image/env`, patch, edit | 0 |
| DB mutation | 0 |
| Fake event / form / checkout | 0 |
| CAPI / GA4 / Meta / TikTok / LinkedIn test event | 0 |
| Stripe call | 0 |
| Webflow | 0 |
| Linear | 0 |
| PROD mutation | 0 |

## 15. Infra docs-only report

This report is the only infra change expected for PH-21.59.

Expected file:

`/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.59-BUILD-WEBSITE-DEV-HERO-COPY-AND-PROD-BODY-PARITY-01.md`

Infra pre-report state:

- branch `main`
- HEAD `344cbc8`
- origin/main `344cbc8`
- ahead/behind `0/0`
- dirty `0`

## 16. Rollback / cleanup documentation only

No runtime rollback is needed because nothing was deployed or pushed.

If the local image must be removed before push:

```bash
docker rmi ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev
```

Source rollback remains the PH-21.58 source rollback and was not executed:

```bash
git revert dfb299b
```

## 17. Next GO

`GO PUSH IMAGE WEBSITE DEV HERO COPY AND PROD BODY PARITY PH-SAAS-T8.12AS.21.60`

STOP.
