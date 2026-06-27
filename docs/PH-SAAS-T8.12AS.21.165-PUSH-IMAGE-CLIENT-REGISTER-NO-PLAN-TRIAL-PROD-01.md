# PH-SAAS-T8.12AS.21.165 - Push image Client register no-plan trial PROD

Date: 2026-06-27

## Verdict

DONE.

## Image

Image pushed:

`ghcr.io/keybuzzio/keybuzz-client:v3.5.263-register-no-plan-trial-prod`

Manifest digest:

`sha256:bdcaa49061827c68d7bdab42f0383b2a240c82683ddf7920630178db9b364362`

Image ID:

`sha256:eabb138132bf44d34869c22116e2cca9e5e12026bb4fffcb1a32a8bb59ef110d`

Source revision:

`39b0e97f9f92521481aea532154a15cf18b01f6e`

## Verification

| Check | Result |
| --- | --- |
| Target tag before push | absent |
| Docker push | PASS |
| Pull-back RepoDigest | `ghcr.io/keybuzzio/keybuzz-client@sha256:bdcaa49061827c68d7bdab42f0383b2a240c82683ddf7920630178db9b364362` |
| Pull-back Image ID | `sha256:eabb138132bf44d34869c22116e2cca9e5e12026bb4fffcb1a32a8bb59ef110d` |
| OCI revision | `39b0e97f9f92521481aea532154a15cf18b01f6e` |
| OCI version | `v3.5.263-register-no-plan-trial-prod` |
| `latest` manifest hash before | `151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341` |
| `latest` manifest hash after | `151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341` |

## Runtime

No runtime deployment was executed in this phase.

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

GO APPLY CLIENT REGISTER NO-PLAN TRIAL PROD GITOPS PH-SAAS-T8.12AS.21.166
