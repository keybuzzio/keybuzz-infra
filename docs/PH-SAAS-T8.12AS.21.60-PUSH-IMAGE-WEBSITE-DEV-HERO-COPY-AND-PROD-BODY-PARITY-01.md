# PH-SAAS-T8.12AS.21.60 - Push image Website DEV hero copy and PROD body parity

Date UTC: 2026-06-16
Mode: PUSH IMAGE WEBSITE DEV only
Environment: DEV image registry only
Operator: Codex Executor

## Objective

Push only the already-built PH-21.59 Website DEV image:

`ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev`

Expected Image ID:

`sha256:0f552f8b55093a9afadfc56418ffde9144c8e1d8a6de6ea981077004549161bc`

No Docker build, no retag, no latest push, no deploy, no kubectl apply, no GitOps manifest mutation, no DB mutation, no fake event, no form submission, no Stripe checkout, no Webflow change, no Linear change, no PROD mutation.

## Preflight

| Check | Result |
| --- | --- |
| Bastion alias | `install-v3` |
| Bastion public IP | `46.62.171.61` |
| Forbidden IP `51.159.99.247` | Not used |
| Target tag before push | Absent from GHCR |
| Website source branch | `redesign/light-business` |
| Website HEAD | `dfb299b6facbbe17cf36d9085aeed2ee8908e151` |
| Website origin parity | ahead/behind `0/0` |
| Website dirty before push | clean |

## Runtime Before Push

| Runtime | Image | Ready |
| --- | --- | --- |
| Website DEV | `ghcr.io/keybuzzio/keybuzz-website:v0.7.0-redesign-light-dev` | `1/1` |
| Website PROD | `ghcr.io/keybuzzio/keybuzz-website:v0.6.22-clarity-restore-prod` | `2/2` |

## Local Image Before Push

| Field | Value | Result |
| --- | --- | --- |
| Tag | `ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev` | OK |
| Image ID | `sha256:0f552f8b55093a9afadfc56418ffde9144c8e1d8a6de6ea981077004549161bc` | OK |
| OCI revision | `dfb299b6facbbe17cf36d9085aeed2ee8908e151` | OK |
| OCI version | `v0.7.1-hero-copy-prod-body-parity-dev` | OK |
| OCI source | `https://github.com/keybuzzio/keybuzz-website` | OK |
| OCI title | `keybuzz-website` | OK |
| OCI created | `2026-06-16T12:20:44Z` | OK |

## Push

Only this command class was used for registry mutation:

`docker push ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev`

Result:

| Field | Value |
| --- | --- |
| Push digest | `sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b` |
| Manifest config digest | `sha256:0f552f8b55093a9afadfc56418ffde9144c8e1d8a6de6ea981077004549161bc` |
| Push verdict | OK |

Note: the first verification script completed the push, `docker rmi`, and pull-back, then stopped on a too-strict local comparison of two hash files whose filenames differed. A second read-only postverify script validated the already completed push/pull-back without performing another push.

## Pull-Back

Sequence performed after push:

1. `docker rmi ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev`
2. `docker pull ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev`
3. `docker image inspect`

| Field | Value | Result |
| --- | --- | --- |
| Pulled RepoDigest | `ghcr.io/keybuzzio/keybuzz-website@sha256:209d4fc08de077d6f2af59d17bc9ae10ec853e97172955118fda0914e328400b` | OK |
| Pulled Image ID | `sha256:0f552f8b55093a9afadfc56418ffde9144c8e1d8a6de6ea981077004549161bc` | OK |
| OCI revision | `dfb299b6facbbe17cf36d9085aeed2ee8908e151` | OK |
| OCI version | `v0.7.1-hero-copy-prod-body-parity-dev` | OK |
| OCI source | `https://github.com/keybuzzio/keybuzz-website` | OK |
| OCI title | `keybuzz-website` | OK |
| OCI created | `2026-06-16T12:20:44Z` | OK |

## Latest Tag Safety

| Check | Result |
| --- | --- |
| `latest` before push | present |
| `latest` manifest hash before | `706a4e0e9134ecb4d6cda787a6583e653295fa18a84d7169cd668c55b885d4b5` |
| `latest` manifest hash after | `706a4e0e9134ecb4d6cda787a6583e653295fa18a84d7169cd668c55b885d4b5` |
| `latest` intact | OK |
| Retag/latest push | Not performed |

## Runtime After Push

| Runtime | Image | Ready | Restarts |
| --- | --- | --- | --- |
| Website DEV | `ghcr.io/keybuzzio/keybuzz-website:v0.7.0-redesign-light-dev` | `1/1` | `0` |
| Website PROD | `ghcr.io/keybuzzio/keybuzz-website:v0.6.22-clarity-restore-prod` | `2/2` | `0`, `0` |

Runtime images remained unchanged. No deploy and no `kubectl apply` were executed.

## GitOps Safety

| Check | Result |
| --- | --- |
| Infra branch | `main` |
| Infra HEAD before report | `4f288ef` |
| Infra origin/main before report | `4f288ef` |
| Infra ahead/behind before report | `0/0` |
| Infra dirty before report | clean |
| K8s manifests referencing target tag | none observed |
| Docs references to target tag | expected PH-21.59 build report references only |
| GitOps manifest mutation | none |

## Out Of Scope Confirmed

| Item | Result |
| --- | --- |
| Docker build | Not executed |
| Docker retag | Not executed |
| Docker push latest | Not executed |
| Deploy / kubectl apply | Not executed |
| GitOps manifest mutation | Not executed |
| DB mutation | Not executed |
| Fake event | Not executed |
| Form submission | Not executed |
| Stripe checkout | Not executed |
| Webflow change | Not executed |
| Linear change | Not executed |
| PROD mutation | Not executed |

## Verdict

DONE.

The PH-21.59 Website DEV image was pushed to GHCR and pull-back verified successfully.

Next recommended GO:

`GO APPLY WEBSITE DEV HERO COPY AND PROD BODY PARITY GITOPS PH-SAAS-T8.12AS.21.61`
