# PH-SAAS-T8.12AS.21.162 - Push image Client register no-plan trial DEV

Date: 2026-06-27

## Verdict

DONE.

## Image

Image pushed:

`ghcr.io/keybuzzio/keybuzz-client:v3.5.263-register-no-plan-trial-dev`

Manifest digest:

`sha256:1ca7dba82b7853c53ece031798f4afc8c7c07633b2c115b317a8d70ecfae7d2c`

Image ID:

`sha256:100700b117c4dce5c0938a7eee79e1958779cef26be27d446f60935be0a46a17`

Source revision:

`39b0e97f9f92521481aea532154a15cf18b01f6e`

## Verification

| Check | Result |
| --- | --- |
| Target tag before push | absent |
| Docker push | PASS |
| Pull-back RepoDigest | `ghcr.io/keybuzzio/keybuzz-client@sha256:1ca7dba82b7853c53ece031798f4afc8c7c07633b2c115b317a8d70ecfae7d2c` |
| Pull-back Image ID | `sha256:100700b117c4dce5c0938a7eee79e1958779cef26be27d446f60935be0a46a17` |
| OCI revision | `39b0e97f9f92521481aea532154a15cf18b01f6e` |
| OCI version | `v3.5.263-register-no-plan-trial-dev` |
| `latest` manifest hash before | `151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341` |
| `latest` manifest hash after | `151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341` |

## Runtime

No runtime deployment was executed in this phase.

Client DEV and Client PROD remained unchanged.

## No Side Effects

- No rebuild.
- No deploy.
- No kubectl apply.
- No DB mutation.
- No real event.
- No fake event.
- No form submission.
- No checkout.
- No Stripe write.
- No Webflow change.
- No Linear change.

## Next Step

GO APPLY CLIENT REGISTER NO-PLAN TRIAL DEV GITOPS PH-SAAS-T8.12AS.21.163
