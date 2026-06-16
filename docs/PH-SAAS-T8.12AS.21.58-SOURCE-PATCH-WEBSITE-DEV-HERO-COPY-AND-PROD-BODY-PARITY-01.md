# PH-SAAS-T8.12AS.21.58 - SOURCE PATCH WEBSITE DEV HERO COPY AND PROD BODY PARITY

Date UTC: 2026-06-16
Role: Codex Executor
Projet: KeyBuzz SaaS / Website / Design / Acquisition tracking
Mode: SOURCE PATCH WEBSITE DEV strict
Linear: KEY-337 reference PH-21 ; KEY-284 / KEY-285 media buyer LP contract ; KEY-322 / KEY-325 Clarity references ; no Linear change

## 1. Verdict

GO SOURCE PATCH WEBSITE DEV HERO COPY AND PROD BODY PARITY READY_WITH_DEBTS PH-SAAS-T8.12AS.21.58

Summary:

- Website DEV source branch `redesign/light-business` patched locally only.
- Hero variant A was applied with French accents in source.
- Body below hero was restored from PROD `main` source-of-truth sections.
- Dangerous DEV gaps were removed from the homepage: obsolete homepage pricing `49/199/devis`, unproven `-84` KPI, overbroad channel claims, and missing PROD compliance/about/FAQ/reassurance sections.
- CTA/tracking/Clarity/server-side tracking files were not modified.
- No fake event, no form submission, no checkout, no Webflow change, no DB/runtime mutation.
- Website local commit created: `dfb299b`.
- Debts: visual QA deferred; global `npm run lint` still fails on pre-existing repo-wide lint issues outside `src/app/page.tsx`.

## 2. Preflight

| Repo/service | Expected | Observed | Dirty/ready | Verdict |
| --- | --- | --- | --- | --- |
| Bastion | `install-v3` | `install-v3` | IP includes `46.62.171.61` | OK |
| Forbidden IP | no `51.159.99.247` | not used | n/a | OK |
| Date UTC | current audit | `Tue Jun 16 06:45:01 AM UTC 2026` | n/a | OK |
| Website source | `/opt/keybuzz/keybuzz-website`, branch `redesign/light-business` | HEAD/origin `020794b` before patch | clean before patch | OK |
| Infra report repo | `/opt/keybuzz/keybuzz-infra`, branch `main` | HEAD/origin `afeec85` before report | clean before report | OK |
| Website DEV runtime | read-only | `v0.7.0-redesign-light-dev`, ready `1/1` | unchanged | OK |
| Website PROD runtime | read-only | `v0.6.22-clarity-restore-prod`, ready `2/2` | unchanged | OK |

## 3. Sources reread

| Source | Status |
| --- | --- |
| `PH-21.58_CE_MISSION.md` | read |
| `AI_MEMORY/CURRENT_STATE.md` | read |
| `AI_MEMORY/RULES_AND_RISKS.md` | read |
| `AI_MEMORY/DOCUMENT_MAP.md` | read |
| `AI_MEMORY/CE_PROMPTING_STANDARD.md` | read |
| `PH-T8.10J-MARKETING-OWNER-STACK-PROD-PROMOTION-01` | read |
| `PH-21.57_CE_RETURN.md` | read |
| `PH-SAAS-T8.12AS.21.57-READONLY-DESIGN-COPY-TRACKING-PARITY-AUDIT-PROD-01.md` | read |
| `PH-WEBSITE-T8.12AQ.1B` | read |
| `PH-WEBSITE-T8.12AQ.1A.1` | read |
| `PH-WEBSITE-T8.12AQ.1A.2` | read |
| `PH-WEBSITE-T8.12AQ.2` | read |
| `PH-WEBSITE-T8.12AQ.3` | read |
| `PH-WEBSITE-T8.12AQ.4` | read |
| `PH-WEBSITE-T8.12AQ.4.1` | read |
| `AI_MEMORY/MEDIA_BUYER_LP_TRACKING_CONTRACT.md` | read |
| `PH-21.55` StartTrial RCA report | read |
| `PH-21.56` website-to-Stripe precheckout report | read |
| `PH-2015E/I/J/K` reports and website/client `BUILD-ARGS.md` | read targeted |

## 4. Source-of-truth branch audit

| File | DEV branch | PROD main source | Role | Action |
| --- | --- | --- | --- | --- |
| `src/app/page.tsx` | redesign hero page | PROD body reference from `main:src/app/page.tsx` | homepage hero/body | patched |
| `src/app/pricing/page.tsx` | current branch | current branch | pricing and forwarding | unchanged |
| `src/components/Analytics.tsx` | current branch | current branch/docs | public analytics tags | unchanged |
| `src/components/ClarityProvider.tsx` | current branch | current branch/docs | Clarity consent/runtime | unchanged |
| `src/components/Navbar.tsx` | current branch | current branch | forwarding params | unchanged |
| `src/lib/tracking.ts` | current branch | current branch/docs | browser event guardrails | unchanged |
| `src/lib/marketing-tracking.ts` | current branch | current branch/docs | CTA click metadata | unchanged |

`git diff --stat main..HEAD -- src/app/page.tsx` before patch showed only homepage divergence in the redesign branch for the page surface. PROD body was extracted from Git, not runtime/pod source.

## 5. Files modified

| Repo | File | Change | Risk |
| --- | --- | --- | --- |
| keybuzz-website | `src/app/page.tsx` | Apply hero variant A and restore PROD body sections below hero | Medium, homepage UI surface |
| keybuzz-infra | this report | Documentation only | None |

No tracking provider file was modified.

## 6. Hero before/after

| Element | Before | After | Justification |
| --- | --- | --- | --- |
| H1 | `Automatisez votre SAV marketplace sans perdre le controle` | `Reprenez le controle de votre SAV marketplace avec une IA qui protege vos marges` | Variant A from PH-21.57, better seller-protection positioning |
| Subtitle | `KeyBuzz centralise vos messages, commandes et litiges Amazon, Cdiscount, Fnac, Shopify, Mirakl, Octopia ...` | `KeyBuzz centralise vos messages, retrouve le contexte commande et prepare des reponses controlees pour Amazon, Cdiscount et vos canaux e-mail. Vous validez, automatisez seulement ce qui est sur.` | More prudent scope and explicit human validation |
| Primary CTA | `/pricing`, `homepage_hero_primary_pricing` | unchanged | Preserve tracking contract |
| Secondary CTA | `#solution`, `homepage_hero_secondary_learn_more` | `#comment`, same CTA id | Restored PROD body has `#comment`; avoids broken anchor |
| Badges | 14 jours / IA validation humaine / sans engagement | unchanged | Baseline-safe claims |

Source uses French accents in JSX because the file already contains French accented copy.

## 7. PROD body restored below hero

| Section | DEV before | PROD main source | Action | Risk |
| --- | --- | --- | --- | --- |
| Pain points | missing/replaced by redesign blocks | present | restored | low |
| Comment ca marche | missing from restored anchor shape | present | restored with `id=comment` | low |
| CTA mid-page | missing/replaced | present | restored | low |
| Benefices | partial/different | present | restored | low |
| Reassurance | missing | present | restored | low |
| Amazon SP-API security | missing | present | restored | low |
| Marketplaces & integrations | different and broader | present | restored | low |
| About founder | missing | present | restored | low |
| FAQ | missing | present | restored | low |
| CTA final | missing/replaced | present | restored | low |
| Footer/legal/cookies | layout/global | layout/global | preserved, not modified | low |

## 8. DEV dangerous gaps corrected

| Gap | Before | After | Evidence |
| --- | --- | --- | --- |
| Obsolete homepage pricing | `49/199/devis` risk in DEV copy | absent from homepage source | `grep` found no `49 EUR`, `199 EUR`, `49e`, `199e` style homepage markers |
| Unproven KPI | `-84` risk | absent | `grep` found no `-84` / Unicode minus variant |
| Overbroad channels | Fnac/Shopify/Mirakl/Octopia in hero subtitle | limited to Amazon, Cdiscount and email channels | hero subtitle patched |
| Missing compliance/About/FAQ | absent in redesign body | restored from PROD main | grep confirms section headings |

## 9. Tracking, CTA, Clarity and forwarding parity

| Surface/file | Marker/CTA | Expected | Observed after patch | Verdict |
| --- | --- | --- | --- | --- |
| `src/app/page.tsx` | primary CTA | `/pricing`, `homepage_hero_primary_pricing` | preserved | OK |
| `src/app/page.tsx` | secondary CTA | no broken anchor | changed to `#comment` with same CTA id | OK |
| `src/app/pricing/page.tsx` | forwarding | `utm_*`, `gclid`, `fbclid`, `ttclid`, `li_fat_id`, `_gl`, `promo`, `marketing_owner_tenant_id` | preserved, file unchanged | OK |
| `src/components/Navbar.tsx` | forwarding params | preserved | unchanged | OK |
| `src/lib/marketing-tracking.ts` | CTA metadata | no business conversion event | unchanged; comments only mention no Lead/Purchase/Signup | OK |
| `src/lib/tracking.ts` | business event guardrails | no browser `StartTrial` / `Purchase` / `CompletePayment` additions | unchanged; comments keep server-side-only warning | OK |
| Clarity | website public ID `wrff07upjx` | preserve build args/source docs | present in `docs/BUILD-ARGS.md` | OK |
| GA4 | `G-R3QQDYEBFG` | preserve | present in `docs/BUILD-ARGS.md` | OK |
| sGTM | `t.keybuzz.pro` | preserve | present in `docs/BUILD-ARGS.md` | OK |
| Meta | `1234164602194748` | preserve | present in `docs/BUILD-ARGS.md` | OK |
| TikTok | `D7PT12JC77U44OJIPC10` | preserve | present in `docs/BUILD-ARGS.md` | OK |
| LinkedIn | `9969977` | preserve | present in `docs/BUILD-ARGS.md` | OK |
| Google Ads direct | `AW-` | absent | absent in scanned surfaces | OK |
| DEV URL leaks | `client-dev.keybuzz.io`, `api-dev.keybuzz.io` | absent from Website CTA surfaces | absent in scanned surfaces | OK |

No new `Lead`, `InitiateCheckout`, `Purchase`, `CompletePayment`, or `StartTrial` browser-side event was added. Matches in `src/lib/tracking.ts` and `src/lib/marketing-tracking.ts` are existing guardrail comments only.

## 10. No fake metrics / no fake events

| Control | Result |
| --- | --- |
| Fake signup | 0 |
| Fake trial | 0 |
| Fake checkout | 0 |
| Fake purchase | 0 |
| CAPI test endpoint | 0 |
| Provider test event | 0 |
| Form submitted | 0 |
| Stripe checkout opened/submitted | 0 |
| DB mutation | 0 |
| Webflow change | 0 |
| Linear change | 0 |

StartTrial contract remains unchanged: StartTrial is tied to a real Stripe checkout/trial completion, not a browser click or page arrival.

## 11. Validations

| Test | Command | Expected | Result |
| --- | --- | --- | --- |
| Patch whitespace | `git diff --check` | pass | PASS |
| Homepage forbidden price/KPI/dev URL scan | `grep` for `49 EUR`, `199 EUR`, `-84`, `client-dev`, `api-dev`, `AW-` | no dangerous marker | PASS |
| Restored section scan | `grep` hero/body headings in `src/app/page.tsx` | all present | PASS |
| Tracking markers expected | `grep` public IDs / forwarding params in source/docs | preserved | PASS |
| Changed file lint | `npx eslint src/app/page.tsx` | pass | PASS |
| Repo lint | `npm run lint` | ideally pass | FAIL_PREEXISTING: 275 problems across unrelated pages/components; `src/app/page.tsx` has no issue in targeted lint |
| Typecheck | npm script | if available | NO_SCRIPT: `package.json` has no `typecheck` script |
| Docker build | n/a | forbidden | NOT_RUN |
| Deploy/apply | n/a | forbidden | NOT_RUN |

## 12. QA visual

`VISUAL_QA_DEFERRED`.

Reason: PH-21.58 is source patch only, no deploy/build. No remote browser/dev-server visual session was started to avoid generated artifacts and any public pageview confusion. Next phase should include preview build/deploy and desktop/mobile visual QA.

## 13. Local commits

| Repo | Commit local | Ahead/behind | Dirty final | Push |
| --- | --- | --- | --- | --- |
| keybuzz-website | `dfb299b` | ahead 1 / behind 0 | clean after commit | NO |
| keybuzz-infra | `<infra_docs_commit_ph2158>` | expected ahead 1 / behind 0 after commit | expected clean after commit | NO |

## 14. Runtime and PROD safety

| Surface | Status |
| --- | --- |
| Website DEV runtime | unchanged; no build/deploy/apply |
| Website PROD runtime | unchanged; read-only only |
| API/Client/Admin/Backend | not modified |
| Kubernetes | no `kubectl apply`, no `kubectl set`, no `kubectl patch`, no `kubectl edit` |
| Docker | no build, no push |
| DB | no mutation |
| Webflow `try.keybuzz.io` | unchanged, out of scope |

## 15. Gaps remaining

| Gap | Status | Recommendation |
| --- | --- | --- |
| `try.keybuzz.io` Webflow owner forwarding P0 | still out of scope PH-21.58 | separate GO PH-21.58A/Webflow owner forwarding |
| Client GA4 runtime parity | separate PH-21.55 debt | keep separate |
| Website DEV runtime preview | source only, not deployed | next phase build/push/apply DEV |
| Visual QA desktop/mobile | deferred | do after DEV runtime deployment |
| Global Website lint | failing pre-existing unrelated issues | fix in separate lint hardening phase, not mixed with homepage parity patch |
| PROD Website | untouched | promote only after DEV validation |

## 16. Rollback source documentation only

Do not execute in PH-21.58.

- Website rollback: `git revert dfb299b`
- Infra docs rollback: `git revert <infra_docs_commit_ph2158>`

Do not use `git reset --hard`.
Do not use `git clean`.
Do not use `kubectl set image`, `kubectl set env`, `kubectl patch`, or `kubectl edit`.

## 17. Recommended next GO

`GO PUSH SOURCE PATCH WEBSITE DEV HERO COPY AND PROD BODY PARITY PH-SAAS-T8.12AS.21.58`

Then, in separated phases only:

1. Build Website DEV from Git.
2. Push Website DEV image with digest verification.
3. Apply GitOps DEV only.
4. Read-only verify DEV preview with visual desktop/mobile QA and tracking safety checks.

STOP.
