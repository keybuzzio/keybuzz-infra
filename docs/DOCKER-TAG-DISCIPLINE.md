# Docker tag discipline (PH-SAAS-T8.12AS.10 -- KEY-309)

## TL;DR

**One tag = one source = one digest. No tag reuse.**

Before any `docker push` of a KeyBuzz image, run :

```
scripts/registry/check-image-tag-available.sh ghcr.io/keybuzzio/<repo>:<tag>
```

Exit codes :
- `0` : tag AVAILABLE -> safe to push.
- `1` : tag TAKEN -> **STOP**. Do not push. Choose a new tag or follow the exception procedure (section "Exceptions").
- `2` : error (auth/network/usage) -> STOP. Investigate (likely registry login missing).

## Why

AS.5.5 identified a tag re-use dette : `v3.5.169` was used for two distinct API images :
- `v3.5.169-tenant-guard-scope-fix-dev` (AS.4.1)
- `v3.5.169-messages-tenant-guard-dev` (AS.5)

Even with descriptive suffixes, the underlying numeric base `v3.5.169` overlap created ambiguity in audit logs and rollback decisions. AS.10 introduces a discipline so a release manager cannot accidentally tag two different builds with the same tag.

This complements :
- AS.2 / AS.8 (KEY-302 / KEY-307) build args sentinels : prevent the wrong source being baked in.
- AS.9 (KEY-308) OCI labels : prevent untraceable images.
- AS.10 (KEY-309, this doc) tag discipline : prevent two different images being indexed under the same tag.

## Tag naming convention

KeyBuzz image tags MUST follow this shape :

```
v<major>.<minor>.<patch>-<scope-slug>-<env>
```

Where :
- `v<major>.<minor>.<patch>` : the API/Client semver-like version.
- `<scope-slug>` : short kebab-case description (e.g. `tenant-guard-scope-fix`, `meta-capi-error-sanitization`, `escalation-flow`).
- `<env>` : `dev` or `prod`.

Examples (current runtime, verified 2026-05-11) :
- `keybuzz-api:v3.5.168-escalation-notifications-dev`
- `keybuzz-api:v3.5.151-conversation-tone-metric-prod`
- `keybuzz-client:v3.5.179-as1-1-build-args-fix-dev`
- `keybuzz-client:v3.5.174-conversation-tone-metric-ux-prod`
- `keybuzz-admin-v2:v2.12.2-media-buyer-lp-domain-qa-dev`
- `keybuzz-backend:v1.0.47-cross-env-guard-fix-dev`
- `keybuzz-website:v0.6.12-linkedin-insight-seo-prod`

Forbidden :
- `:latest`
- Numeric base reuse with different `<scope-slug>` (the AS.5.5 dette must not repeat).
- Mixing `<env>` between source-of-truth branches : DEV branches must produce `-dev` tags, PROD branches must produce `-prod` tags.

## Pre-push procedure

1. Determine the target image and tag according to the convention above.
2. Run the guard :
   ```
   scripts/registry/check-image-tag-available.sh ghcr.io/keybuzzio/<repo>:<tag>
   ```
3. If exit 0 (available) :
   - Proceed to `docker build` with required build args (OCI labels included).
   - `docker push` only if the build succeeded.
   - Document in the phase report : tag, digest, OCI revision label, build args used.
4. If exit 1 (taken) :
   - **STOP**.
   - Reuse the existing image (do not rebuild a different image under the same tag).
   - If forced to overwrite, see "Exceptions".
5. If exit 2 (error) :
   - Investigate. Likely cause : `docker login ghcr.io` missing on the build host, or registry unreachable.
   - Do not push until resolved.

## Post-push documentation

For every successful `docker push`, the phase report MUST capture :
- the target tag,
- the resulting `sha256:...` digest,
- the `org.opencontainers.image.revision` label value (commit SHA),
- the build args used (`IMAGE_REVISION`, `IMAGE_CREATED`, `IMAGE_VERSION`, plus any KEY-302/KEY-307 NEXT_PUBLIC args for Client/Admin-v2).

Rollback procedure must reference both the previous tag AND its digest, so a rollback can be applied even if the registry is later mutated (defense in depth).

## Exceptions

Tag reuse is forbidden by default. The only allowed exception is :
- explicit Ludovic GO in the conversation, AND
- documented justification in the phase prompt and report, AND
- old digest + new digest both captured in the report.

Even with an exception, the preferred path is to pick a fresh tag (`-v2`, `-fix2`, or a bumped patch number).

## Limitations of the guard

`scripts/registry/check-image-tag-available.sh` uses `docker manifest inspect` against the configured registry.

Known limits (intentional, acceptable for KeyBuzz operations) :
- If the repo itself does not exist (typo in repo name), GHCR returns the same `manifest unknown` as an absent tag. The script reports exit 0 (available) in this case. Practical impact : nil for KeyBuzz because all release repos are pre-existing (`keybuzz-api`, `keybuzz-client`, `keybuzz-admin-v2`, `keybuzz-backend`, `keybuzz-website`). A typo in repo name will fail the subsequent `docker push` (permissions/repo missing) which catches the error there.
- If the bastion is not logged in to `ghcr.io`, `docker manifest inspect` returns an auth error. The script exits 2. This is the correct behavior : do not proceed without auth.
- The script does not verify mediaTypes ; any manifest format counts as "tag exists".

## References

- `keybuzz-infra/docs/PH-SAAS-T8.12AS.10-DOCKER-TAG-DISCIPLINE-FOUNDATION-01.md` (this phase report)
- `keybuzz-infra/docs/AI_MEMORY/KEYBUZZ_OPERATIONAL_SOURCE_OF_TRUTH.md` section 8 (build rules)
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.9-DOCKER-OCI-REVISION-LABELS-FOUNDATION-01.md` (OCI labels)
- `keybuzz-infra/docs/PH-SAAS-T8.12AS.5.5-SAAS-RUNTIME-SOURCE-TRUTH-AUDIT-01.md` (the v3.5.169 tag dette)
