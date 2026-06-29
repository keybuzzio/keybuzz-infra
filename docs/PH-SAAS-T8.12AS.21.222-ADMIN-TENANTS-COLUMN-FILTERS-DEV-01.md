# PH-SAAS-T8.12AS.21.222 - Admin tenants column filters DEV

Date UTC: 2026-06-29
Environment: DEV
Type: Source patch / build / image push / GitOps apply / read-only verify
Verdict: READY_DEV

## Objective

Add column-level sorting and filtering on the Admin tenants list:

- Page: `/tenants`
- DEV target: `https://admin-dev.keybuzz.io/tenants`
- PROD request is known but not applied in this phase because PROD runtime mutation requires explicit GO.

## Scope

Changed only:

- `keybuzz-admin-v2/src/app/(admin)/tenants/page.tsx`

No API changes.
No DB changes.
No auth/session changes.
No support impersonation changes.
No tenant action changes.

## Source

Repo:

- `/opt/keybuzz/keybuzz-admin-v2`

Branch:

- `main`

Source commit:

- `af5eaaaf1d87de2c42839db7afe98e204be724f1`

Commit message:

- `feat(admin): add tenant table column filters`

Preflight:

- Branch `main`.
- Repo clean before build.
- Ahead/behind `0/0`.

Note:

- The touched file was normalized to LF line endings, so the Git diff is larger than the logical change. Scope remains one file only.

## Functional Changes

Tenant table now supports:

- Clickable column headers for sort:
  - `Nom`
  - `ID`
  - `Plan`
  - `Statut`
  - `Admins`
  - `Cree le`
- Asc/desc toggle on repeated header click.
- Per-column filters below headers.
- Visible count `visible / total`.
- Filter reset button when a filter is active.
- Empty-filter result state.

Existing features preserved:

- Stats cards.
- Tenant creation form.
- Details link.
- Status badges.
- Plan badges.
- Admin user count.

## Validation

Source validations:

- `git diff --check`: PASS after LF normalization.
- Marker check: PASS.
- `npx tsc --noEmit`: PASS.

Build validation:

- Docker build: PASS.
- Next.js build: PASS.
- Route `/tenants` built successfully.

## DEV Image

Image:

- `ghcr.io/keybuzzio/keybuzz-admin:v2.12.4-tenant-column-filters-dev`

Digest:

- `sha256:0629a3914471e5dc548d94fa10bf5ac042d9d8da5d7b0ed1e3f3547984f2f2c7`

Image ID:

- `sha256:c6f34be2fe9bdb8bd7580c81b5c757852023f2b2216b677295f96620c9aca8e6`

Build safety:

- Build-from-git clean worktree.
- Explicit DEV build args:
  - `NEXT_PUBLIC_APP_ENV=development`
  - `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io`
- Immutable tag.
- No `latest` push.
- Image markers for filters/sort present.

## DEV GitOps

Infra repo:

- `/opt/keybuzz/keybuzz-infra`

Manifest:

- `k8s/keybuzz-admin-v2-dev/deployment.yaml`

Deploy commit:

- `ad47b051b2141d7729d88a96be7239f4de2903c9`

Method:

- Image-only manifest change.
- Commit + push before apply.
- `kubectl apply --dry-run=client -f`: PASS.
- `kubectl apply --dry-run=server -f`: PASS.
- `kubectl apply -f`: PASS.
- Rollout successful.

Forbidden actions not used:

- No `kubectl set image`.
- No `kubectl set env`.
- No `kubectl patch`.
- No `kubectl edit`.

Rollback DEV:

- `ghcr.io/keybuzzio/keybuzz-admin:v2.12.3-support-impersonation-dev`

## DEV Runtime Verification

Runtime:

- Image: `ghcr.io/keybuzzio/keybuzz-admin:v2.12.4-tenant-column-filters-dev`
- Ready: `1/1`
- Generation: `126/126`
- Pod: `keybuzz-admin-v2-54d9698894-nglsh`
- Restarts: `0`
- Pod imageID digest: `sha256:0629a3914471e5dc548d94fa10bf5ac042d9d8da5d7b0ed1e3f3547984f2f2c7`

Passive HTTP checks:

- `https://admin-dev.keybuzz.io/login`: HTTP 200
- `https://admin-dev.keybuzz.io/tenants`: HTTP 307 when unauthenticated, expected auth redirect behavior.

Non-regression read-only:

- Admin PROD unchanged: `v2.12.3-support-impersonation-prod`, ready `1/1`.
- Client PROD unchanged: `v3.5.278-auth-shell-bypass-prod`, ready `1/1`.

## No Side Effects

- No PROD runtime mutation.
- No DB mutation.
- No tenant creation.
- No support impersonation token.
- No secret read/displayed.
- No fake event.
- No checkout.
- No Linear action.

## PROD Gate

PROD requested target:

- `https://admin.keybuzz.io/tenants`

DEV is ready for manual visual validation. PROD promotion requires explicit GO.

Exact GO:

`GO BUILD PUSH APPLY ADMIN TENANTS COLUMN FILTERS PROD PH-SAAS-T8.12AS.21.223`

Expected PROD tag:

- `ghcr.io/keybuzzio/keybuzz-admin:v2.12.4-tenant-column-filters-prod`

Rollback PROD:

- `ghcr.io/keybuzzio/keybuzz-admin:v2.12.3-support-impersonation-prod`

## Final Verdict

READY_DEV.

The Admin tenants table column filters/sorting are deployed and verified in DEV. PROD promotion is gated by explicit GO.
