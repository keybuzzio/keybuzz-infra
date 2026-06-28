# PH-SAAS-T8.12AS.21.178 - Amazon channel activation idempotence PROD

Date: 2026-06-28 Europe/Paris

## Verdict

READY.

## Objective

Promote the DEV-validated Amazon channel activation idempotence fix to PROD.

The fix prevents the Client from showing a false Amazon activation failure when `/channels/activate-amazon` is called more than once after a successful OAuth callback.

## Source

Repo: `keybuzz-api`

Branch: `ph147.4/source-of-truth`

Commit: `dc80c8a7740ac805d2deb66e2fdf37074a9b02bc`

Files included:

- `src/modules/channels/channelsRoutes.ts`
- `src/tests/ph21177-activate-amazon-idempotent-tests.ts`

## Preflight

API source:

- local HEAD = origin/ph147.4/source-of-truth = `dc80c8a7740ac805d2deb66e2fdf37074a9b02bc`
- source repo clean before build

Infra source:

- pre-apply HEAD = origin/main = `aa30b3bd1dd6b866a455d21241c564a312f4a3e6`
- manifest changed only: `k8s/keybuzz-api-prod/deployment.yaml`

PROD baseline:

- Previous API PROD image: `ghcr.io/keybuzzio/keybuzz-api:v3.5.273-start-onboarding-latency-prod`
- Previous digest: `sha256:424612fe036d604f95c0d843b02a0ca3b9035c0c5f07d122615b5bf1ea03a9c7`

## Build

Build method:

- build-from-git from clean clone
- branch: `ph147.4/source-of-truth`
- commit: `dc80c8a7740ac805d2deb66e2fdf37074a9b02bc`

Tests before build:

- `npm ci`: PASS
- `npx tsx src/tests/ph21177-activate-amazon-idempotent-tests.ts`: PASS
- `npx tsx src/tests/ph21172-start-latency-tests.ts`: PASS
- `npx tsc --noEmit`: PASS

Image:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.274-amazon-channel-activation-idempotent-prod`

Image ID:

`sha256:36e1a6261da3488edf9012216c949954014912486b384788533c074938fde7b9`

## Push

GHCR digest:

`sha256:7bec821136ff8d77056a2a3ce7050f923bb26240ec1bd4cca880eee14a3cbf1a`

Pull-back:

- RepoDigest matches expected digest
- Image ID matches local build
- OCI revision label: `dc80c8a7740ac805d2deb66e2fdf37074a9b02bc`
- OCI version label: `v3.5.274-amazon-channel-activation-idempotent-prod`

## GitOps apply

Manifest commit:

`a5e2db782e7ea105e8a90c10c94e45903fbe8052`

Apply method:

`kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`

Rollout:

- successful
- API PROD generation: `435/435`
- pod ready: true
- restarts: 0

Runtime:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.274-amazon-channel-activation-idempotent-prod`

Runtime digest:

`sha256:7bec821136ff8d77056a2a3ce7050f923bb26240ec1bd4cca880eee14a3cbf1a`

Equality:

- deployment spec image = last-applied image = expected manifest image
- pod imageID digest = GHCR digest

## Runtime verification

Bundle markers:

- `Activated/confirmed` marker present in `/app/dist/modules/channels/channelsRoutes.js`
- old pending-only marker `status = 'pending'` absent from runtime channels bundle

Health:

- API `/health`: OK

DB read-only verification for tenant `switaa-sasu-mqwuvv8z`:

- `tenant_channels.amazon-fr.status = active`
- active channel count = 1
- inbound connection = READY
- inbound address exists
- inbound address validation/pipeline/marketplace status = PENDING
- inbound email exists, not printed

## Non-regression

Other PROD runtimes unchanged:

- Client PROD remains `ghcr.io/keybuzzio/keybuzz-client:v3.5.267-start-onboarding-latency-prod`
- Backend PROD remains `ghcr.io/keybuzzio/keybuzz-backend:v1.0.56-amazon-inbound-dedup-prod`

No fake event, no checkout, no form submission, no secret printed, no manual DB write, no Webflow/Meta/Stripe action.

Known unrelated warning observed in API startup logs:

- `[AIJournal] Could not ensure table`
- message: `must be owner of table ai_journal_events`
- classified as pre-existing/non-blocking for this phase because API is healthy and the Amazon channel activation path is verified.

## Rollback

GitOps rollback image:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.273-start-onboarding-latency-prod`

Rollback digest:

`sha256:424612fe036d604f95c0d843b02a0ca3b9035c0c5f07d122615b5bf1ea03a9c7`

Rollback method:

- edit `k8s/keybuzz-api-prod/deployment.yaml`
- commit + push
- `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`
- rollout status
- verify runtime = manifest = last-applied = pod imageID

## User-facing note

The current PROD tenant already has the Amazon FR channel active. If the old browser tab still displays the stale OAuth activation error, reload `/channels`; future repeated activation calls should be treated idempotently.

