# KEYBUZZ -- Operational source of truth

> Last updated : 2026-05-11 (AS.6.2 KEY-311)
> Status : canonical, vivant. Must be read before any operational phase (CE / Codex / human).

## 1. Purpose

This file is the single canonical source of truth for KeyBuzz operational state, conventions, and absolute rules. It is the FIRST file to read before any phase that may build, deploy, run kubectl, touch DB, modify GitOps, or affect runtime. It is concise on purpose : it is an operating manual, not a phase report.

Audience : Cursor Executor (CE), Claude Executor (CE), Codex, any human or AI agent acting on KeyBuzz infra/code.

When to update : whenever runtime baseline changes, source safe anchor changes, a new absolute rule is established by Ludovic, a do-not-redeploy image is identified, a blocker is added/closed, or a previous statement here turns out to be wrong. The update protocol is in section 15.

## 2. Canonical repos and paths

Real Git repositories live on the bastion. The local Windows folder `C:\DEV\KeyBuzz` is a partial mirror and is often out of date.

| Repo | Bastion path | Branch | Notes |
|---|---|---|---|
| keybuzz-api | /opt/keybuzz/keybuzz-api | ph147.4/source-of-truth | Fastify TS API, dual DB (`keybuzz` product + `keybuzz_backend` Prisma) |
| keybuzz-client | /opt/keybuzz/keybuzz-client | ph148/onboarding-activation-replay | Next.js client + BFF |
| keybuzz-infra | /opt/keybuzz/keybuzz-infra | main | K8s manifests, docs, PH reports |
| keybuzz-backend | /opt/keybuzz/keybuzz-backend | main | Inbound webhooks, OAuth callbacks |
| keybuzz-website | /opt/keybuzz/keybuzz-website | main | Public marketing site keybuzz.pro |
| keybuzz-admin-v2 | /opt/keybuzz/keybuzz-admin-v2 | main | Real admin runtime (Next.js / Metronic) |

CRITICAL : `keybuzz-admin` (no `-v2`) is the LEGACY repo, quarantined since PH86.0. It is NOT the runtime source for the admin app. The runtime source is `keybuzz-admin-v2`. Never build the admin from `keybuzz-admin`.

Local Windows path `C:\DEV\KeyBuzz` contains partial copies but is typically stale. Always operate on the bastion via SSH.

## 3. Bastion and SSH

| Item | Value |
|---|---|
| Bastion alias | install-v3 |
| IP (expected) | 46.62.171.61 |
| SSH key | C:\Users\ludov\.ssh\id_rsa_keybuzz_v3 (no passphrase) |
| Forbidden bastion | 51.159.99.247 -- STOP immediately if any prompt or tool points there |
| Legacy bastion | install-01 (91.98.128.153) -- forbidden unless explicitly justified in writing |

If the resolved IP differs from `46.62.171.61` : STOP.

## 4. Current safe runtime baseline (verified 2026-05-11)

| Env | Service | Image |
|---|---|---|
| DEV | keybuzz-api | v3.5.168-escalation-notifications-dev |
| DEV | keybuzz-client | v3.5.179-as1-1-build-args-fix-dev |
| DEV | keybuzz-backend | v1.0.47-cross-env-guard-fix-dev |
| DEV | keybuzz-outbound-worker | v3.5.165-escalation-flow-dev |
| DEV | keybuzz-website | v0.6.12-linkedin-insight-seo-dev |
| DEV | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-dev |
| PROD | keybuzz-api | v3.5.151-conversation-tone-metric-prod |
| PROD | keybuzz-client | v3.5.174-conversation-tone-metric-ux-prod |
| PROD | keybuzz-backend | v1.0.47-cross-env-guard-fix-prod |
| PROD | keybuzz-outbound-worker | v3.5.165-escalation-flow-prod |
| PROD | keybuzz-website | v0.6.12-linkedin-insight-seo-prod |
| PROD | keybuzz-admin-v2 | v2.12.2-media-buyer-lp-domain-qa-prod |

Always re-verify the runtime values before any action by running the smoke harness (section 9) or `kubectl -n <ns> get deploy <app> -o jsonpath='{.spec.template.spec.containers[0].image}'`. The table above is authoritative at the timestamp shown ; do not trust it blindly after several days.

## 5. Current source truth anchors

| Repo | Safe anchor commit | What it represents |
|---|---|---|
| keybuzz-api | 070707a1 | feat(notifications): internal escalation notifications + tenant-scoped routes (PH-SAAS-T8.12AS.1, KEY-263). Equivalent to runtime DEV v3.5.168. |
| keybuzz-client | f244a58 | fix(client-build): require explicit API build args for safe bundles (KEY-302). Equivalent to runtime DEV v3.5.179. |

AS.5.4 confirmed `git diff <anchor>..HEAD` is empty on the build perimeter for both repos. KEY-302 hardening on the Client must remain conserved : no Client build should ever happen without the sentinel guard active.

Any future change that moves the HEAD beyond these anchors must explicitly update this section and the smoke harness `SMOKE_EXPECTED_*_IMAGE`.

## 6. Mandatory preflight (before any phase)

Run these checks before any code/build/deploy phase :

1. `git rev-parse --abbrev-ref HEAD` for each touched repo : must equal the branch in section 2.
2. `git rev-parse --short HEAD` : record in the phase prompt and final report.
3. `git fetch origin -q && git rev-list --left-right --count origin/<branch>...HEAD` : must be `0	0` before any build.
4. `git status --porcelain` : must be clean OR only contain documented artifact dirty (e.g. keybuzz-client `tsconfig.tsbuildinfo`, keybuzz-api `D dist/*.js`). If anything else is dirty : STOP and investigate.
5. Runtime image = manifest spec image = `kubectl.kubernetes.io/last-applied-configuration` annotation (GitOps no drift).
6. All pods Ready.
7. For phases that touch DEV runtime : run the smoke harness V1 (section 9). PASS required.

If any check fails : STOP. Do not improvise.

## 7. GitOps rules

Absolute :
- No `kubectl set image`.
- No `kubectl patch`.
- No `kubectl edit`.
- No `kubectl set env`.
- No imperative cluster mutation. The only allowed write path : edit manifest in `keybuzz-infra` -> commit -> push -> `kubectl apply -f <manifest>` from a clean checkout.
- After apply : `kubectl rollout status` must succeed. Then re-check spec = last-applied = pod image.
- Cluster namespaces `*-prod` cannot be mutated without explicit Ludovic GO.
- Never touch `ingress-nginx` or `cert-manager`.
- Never touch `/opt/keybuzz/credentials/` or `/opt/keybuzz/secrets/`.

## 8. Build rules

Per build :
- Working tree clean (or only documented artifact dirty).
- `commit + push` before `docker build`. Build from a Git checkout, never from a pod/runtime/dist/SCP.
- Immutable tag (no `:latest`, no tag reuse, KEY-309).
- Document digest in the phase report.
- Document rollback target tag in the phase report.

Client-specific (KEY-302) :
- `docker build` of `keybuzz-client` MUST pass `--build-arg NEXT_PUBLIC_APP_ENV`, `NEXT_PUBLIC_API_URL`, `NEXT_PUBLIC_API_BASE_URL` for the target environment. The Dockerfile sentinel `__MUST_BE_SET_BY_BUILD_ARG__` makes any missing build arg fail before `npm run build`.
- After build, `scripts/verify-client-bundle-api-url.sh <image> <development|production>` must pass.

OCI image labels (AS.9 KEY-308) :
- Every Docker build SHOULD pass three build args :
  - `IMAGE_REVISION=$(git rev-parse HEAD)`
  - `IMAGE_CREATED=$(date -u +%Y-%m-%dT%H:%M:%SZ)`
  - `IMAGE_VERSION=<immutable-tag-from-release-prompt>`
- Dockerfiles inject these into 5 standard OCI labels :
  `org.opencontainers.image.revision`, `.created`, `.version`, `.source`, `.title`.
- Verification : `docker image inspect <image> --format '{{json .Config.Labels}}'` MUST show a non-"unknown" revision before any tag is pushed to GHCR.
- AS.9 status : labels added to 5 service Dockerfiles (api, client, admin-v2, backend, website). Defaults remain "unknown" for backward compatibility ; KEY-309 will later make non-"unknown" mandatory.

Tag discipline (AS.10 KEY-309) :
- One tag = one source = one digest. No tag reuse.
- Before any `docker push`, run `scripts/registry/check-image-tag-available.sh ghcr.io/keybuzzio/<repo>:<tag>`. Exit 0 = available, exit 1 = TAKEN (STOP), exit 2 = error (auth/network/usage, STOP).
- Tag naming convention : `v<major>.<minor>.<patch>-<scope-slug>-<env>` with `<env>` in {`dev`, `prod`}. No `:latest`. No numeric-base reuse with different `<scope-slug>` (cf the v3.5.169 dette in AS.5.5).
- Phase reports MUST capture : tag, digest, `org.opencontainers.image.revision`, build args used.
- Exceptions to tag reuse require explicit Ludovic GO + documented old/new digests.
- Full discipline reference : `keybuzz-infra/docs/DOCKER-TAG-DISCIPLINE.md`.

API and Backend Dockerfiles are self-contained ; build args constraints are simpler and documented in their respective READMEs.

## 9. Smoke harness rules (V1, AS.6 + AS.6.1)

- Script : `keybuzz-client/scripts/smoke/readonly-smoke-dev.sh`.
- Doc : `keybuzz-client/scripts/smoke/README.md`.
- Read-only by construction (curl -G only, no `-X POST|PATCH|PUT|DELETE`, no `-d`, no `--data*`). Self-checks at startup.
- PASS required before any build or deploy DEV.
- WARN tolerated only if each warning is documented in the phase prompt.
- FAIL blocks the phase.
- After build/deploy : re-run smoke with updated `SMOKE_EXPECTED_*_IMAGE`. PASS required again.
- The smoke does NOT replace Ludovic UX QA for visible UX paths. It catches gross errors (build args leak, GitOps drift, API down, bundle missing labels).
- V2 PROD-readonly mode is NOT implemented in V1. Only ad-hoc curl `/health` on PROD is permitted, no body fetch, no tenant-scoped probe.

## 10. Reports rules

- All phase reports live in `keybuzz-infra/docs/PH-SAAS-T8.12<PHASE>-...md`.
- ASCII strict : no BOM, no non-ASCII bytes, no em dash, no fancy quotes, no emoji, no box drawing.
- Frontmatter : `# title` ; `> Date :` ; `> Linear :` ; `> Phase :` ; `> Environnement :`.
- Mandatory sections per phase type ; see CE_PROMPTING_STANDARD.md for the full template.
- Verdict must be one of the explicit allowed verdicts of the prompt.

Docs-only report direct commit rule (AS.6.1) :
- If the report is ASCII strict, lives in `keybuzz-infra/docs/`, modifies a single docs file, and touches no manifest, no runtime, no secret, no CI deploy : CE may commit + push directly without intermediate GO.
- Otherwise : STOP and request GO.

## 11. Linear / disclosure rules

- API : `https://api.linear.app/graphql`.
- Token : load from a file outside the repo (e.g. `C:\DEV\KeyBuzz\Linear.txt`). Never commit the token. Never print it.
- Disclosure-controlled comments only :
  - No PoC, no curl/kubectl/git commands enabling reproduction.
  - No internal source file names that would help an attacker locate the security mechanism (KEY-301, KEY-304).
  - No PII (tenant id in clear, email, order id, tracking, draft text).
  - Commit hashes : avoid in public-ish issues unless strictly necessary.
- Mention of tenantGuard / fastify scope / BFF mirror : limited to "audit valid, mitigation not active runtime after rollback, endpoint-by-endpoint resumption required".
- Before commenting on a security-related issue : sanitize once, then sanitize again.

## 12. Do-not-redeploy images

These images are confirmed unsafe and must never be redeployed or retagged :

| Image | Reason |
|---|---|
| keybuzz-client:v3.5.177-escalation-notifications-ux-dev | built without explicit `--build-arg`, bundle leaks PROD URL (AS.1 incident). |
| keybuzz-client:v3.5.178-escalation-notifications-client-fix-dev | attempted fix without args, still broken (AS.1.1). |
| keybuzz-client:v3.5.180-messages-bff-tenant-guard-dev | AS.5 BFF /messages broke Brouillon IA SWITAA AUTOPILOT. |
| keybuzz-client:v3.5.181-inbox-ai-auto-suggestion-dev | AS.5.1 useEffect autotrigger wrong UX path. |
| keybuzz-client:v3.5.182-tenant-guard-bff-compat-fix2-dev | AS.4.x BFF generic broke channels / catalogue UI. |
| keybuzz-api:v3.5.169-tenant-guard-scope-fix-dev | AS.4.1 global tenant guard, broke multiple DEV flows. |
| keybuzz-api:v3.5.169-messages-tenant-guard-dev | AS.5 messages tenant guard, broke Brouillon IA SWITAA AUTOPILOT. |

Tag dette : `v3.5.169` was used for two distinct API builds (AS.4.1 and AS.5). KEY-309 covers the tag policy fix.

## 13. Current blockers and active tickets

| Linear | Topic | Status (2026-05-11) |
|---|---|---|
| KEY-263 | AS.1 escalation notifications PROD promotion | In Review (blocked by KEY-301 + KEY-304) |
| KEY-301 | tenantGuardPlugin runtime audit / fix | Open. Risk remains in DEV+PROD post AS.5 rollback. |
| KEY-302 | Client build args hardening | Done. KEY-302 guard must be preserved on any Client rebuild. |
| KEY-304 | TenantGuard /messages endpoint-by-endpoint redesign | Open (Todo). Requires design + QA matrix before resumption. |
| KEY-305 | Inbox auto-suggestion IA regression | In Review (post AS.5.4 source/runtime alignment + AS.5.3 rollback). |
| KEY-306 | JWT_SESSION_ERROR PROD investigation | Open (Todo). 31 occurrences observed Client PROD. |
| KEY-307 | Admin-v2 build args hardening | Open (Todo). Apply KEY-302 pattern to admin-v2. |
| KEY-308 | OCI image revision labels | Open (Todo). Add `org.opencontainers.image.revision` labels. |
| KEY-309 | Tag discipline / no tag reuse | Open (Todo). Prevent `v3.5.169` style ambiguity. |
| KEY-310 | Smoke harness read-only | V1 delivered AS.6 + AS.6.1. Status In Review / Done pending Ludovic confirm. |
| KEY-311 | Operational source of truth docs | This document (AS.6.2). |

## 14. Prompting standard

Long-form KeyBuzz prompts are mandatory whenever a phase touches code, build, deploy, DB, GitOps, tracking, billing, Admin, Website, Client, API, PROD, security, auth, infra, AI, Inbox, messaging, connectors, orders, tracking colis, playbooks, escalations, or source of truth. See `keybuzz-infra/docs/AI_MEMORY/CE_PROMPTING_STANDARD.md` for the full template.

CE must be treated as stateless. Every prompt must contain : objective, sources to re-read, context, absolute rules, forbidden actions, numbered steps, validations, rollback, final report path, allowed verdicts, `STOP`.

Forbidden : mini-prompt for any risky phase. Forbidden : prompts that point CE to "infer" rules from prior context.

## 15. Update protocol

| Trigger | Action |
|---|---|
| Runtime baseline image changes for any service | Update section 4. Add a row in section 12 if the previous image is now unsafe. |
| Source safe anchor moves (new feature merged, rollback applied) | Update section 5. |
| A new absolute rule established by Ludovic | Add it to the appropriate section (3 / 7 / 8 / 11 / 14). |
| A new blocker or ticket | Update section 13. |
| A new image confirmed unsafe | Add to section 12 with reason. |
| A contradiction is discovered between this file and reality | STOP all action. Bring the file back to truth in a docs-only commit. Never act on the contradicting belief. |

Commit message convention for updates : `docs(ai-memory): update operational source of truth (...)`.

This file must remain short and dense. If it grows past ~400 lines, split sections out into AI_MEMORY/ sibling files and keep only pointers here.
