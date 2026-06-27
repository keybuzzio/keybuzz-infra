# PH-SAAS-T8.12AS.21.177 - Amazon channel activation idempotence DEV

Date: 2026-06-28 Europe/Paris

## Verdict

READY_FOR_PROD_GO.

## Symptom

After Amazon OAuth on PROD, the backend callback completed successfully, but the Client displayed:

`OAuth termine mais l'activation du canal a echoue. Veuillez reconnecter Amazon.`

The UI also appeared stale with channels used at 0.

## Read-only findings

- Vault repair is effective: Amazon credentials are now stored.
- Backend PROD OAuth callback completed successfully for tenant `switaa-sasu-mqwuvv8z`.
- Backend created READY inbound connection and address.
- API PROD logs showed `/channels/activate-amazon` did activate `amazon-fr`.
- API DB read-only confirmed:
  - `tenant_channels.amazon-fr.status = active`
  - active channel count = 1
  - inbound connection = READY
  - inbound address exists, validation status still PENDING

## Root cause

`POST /channels/activate-amazon` was not idempotent.

The route updated only rows matching `status = 'pending'`. The first callback activation succeeded. Any repeated activation call returned `activated: []`, which the Client interpreted as failure even though the channel was already active.

## Patch

Repo: `keybuzz-api`
Branch: `ph147.4/source-of-truth`
Commit: `dc80c8a7`

Files:

- `src/modules/channels/channelsRoutes.ts`
- `src/tests/ph21177-activate-amazon-idempotent-tests.ts`

Change:

- Import and use `activateChannel`.
- Confirm already-active channels idempotently.
- Create the tenant channel via `addChannel` if OAuth callback arrives before a channel row exists.
- Return the activated marketplace key for confirmed active channels.

## Tests

- `git diff --check`: PASS
- `npx tsx src/tests/ph21177-activate-amazon-idempotent-tests.ts`: PASS
- `npx tsx src/tests/ph21172-start-latency-tests.ts`: PASS
- `npx tsc --noEmit`: PASS

## DEV build and deploy

Image:

`ghcr.io/keybuzzio/keybuzz-api:v3.5.274-amazon-channel-activation-idempotent-dev`

Digest:

`sha256:88761a9dbed5deae0e033a081a2d552aaa5c2224fc26434539ef03b161ca453d`

Image ID:

`sha256:d6917810f977ccd028848f7457eaaa20dca50880712af364da9b6b45057a8fcc`

GitOps:

- Manifest: `k8s/keybuzz-api-dev/deployment.yaml`
- Commit: `44af90b`
- Apply: `kubectl apply -f k8s/keybuzz-api-dev/deployment.yaml`

Runtime DEV:

- image tag matches manifest
- pod digest matches GHCR digest
- rollout successful
- pod Ready 1/1, restarts 0
- bundle marker `Activated/confirmed` present
- old pending-only marker absent
- health endpoint OK

## No side effects

- No fake event.
- No checkout.
- No form submission.
- No secret printed.
- No DB mutation outside GitOps/apply runtime rollout.
- PROD runtime not changed by this phase.

## Remaining action

PROD promotion requires explicit GO:

`GO BUILD PUSH APPLY API AMAZON CHANNEL ACTIVATION IDEMPOTENCE PROD PH-SAAS-T8.12AS.21.178`

