# PH-SAAS-T8.12AS.21.164 - Build Client register no-plan trial PROD

Date: 2026-06-27

## Verdict

READY.

## Image

Image locale construite:

`ghcr.io/keybuzzio/keybuzz-client:v3.5.263-register-no-plan-trial-prod`

Image ID:

`sha256:eabb138132bf44d34869c22116e2cca9e5e12026bb4fffcb1a32a8bb59ef110d`

Source Git build:

`39b0e97f9f92521481aea532154a15cf18b01f6e`

Build-from-git propre:

`/tmp/ph21164-client-build-20260627T100921Z`

## Build Args PROD

| Build arg | Value |
| --- | --- |
| `NEXT_PUBLIC_APP_ENV` | `production` |
| `NEXT_PUBLIC_API_URL` | `https://api.keybuzz.io` |
| `NEXT_PUBLIC_API_BASE_URL` | `https://api.keybuzz.io` |
| `NEXT_PUBLIC_GA4_MEASUREMENT_ID` | `G-R3QQDYEBFG` |
| `NEXT_PUBLIC_META_PIXEL_ID` | `1234164602194748` |
| `NEXT_PUBLIC_SGTM_URL` | `https://t.keybuzz.pro` |
| `NEXT_PUBLIC_TIKTOK_PIXEL_ID` | `D7PT12JC77U44OJIPC10` |
| `NEXT_PUBLIC_LINKEDIN_PARTNER_ID` | `9969977` |
| `NEXT_PUBLIC_CLARITY_PROJECT_ID` | `wuk12h9i33` |
| `IMAGE_REVISION` | `39b0e97f9f92521481aea532154a15cf18b01f6e` |
| `IMAGE_VERSION` | `v3.5.263-register-no-plan-trial-prod` |

## Audit Image

| Check | Result |
| --- | --- |
| Docker build | PASS |
| OCI revision label | `39b0e97f9f92521481aea532154a15cf18b01f6e` |
| OCI version label | `v3.5.263-register-no-plan-trial-prod` |
| Global API PROD marker | `88` |
| Global API DEV marker | `0` |
| Meta pixel marker | `2` |
| sGTM marker | `5` |
| Register `register-trial-access-card` | `2` |
| Register `register-plan-grid` | `0` |
| Register `register-step-plan` | `0` |
| Register `register_continue_to_plan` | `0` |
| Register `/api/tenant-context/no-card-trial` | `2` |
| Register `/api/billing/checkout-session` | `0` |
| Register `StartTrial` | `0` |
| Register `Purchase` | `0` |
| Register `CompletePayment` | `0` |
| Register `InitiateCheckout` | `0` |

## Registry / Runtime

| Surface | Result |
| --- | --- |
| GHCR target tag before build | absent |
| GHCR target tag after local build | absent |
| Docker push | not executed |
| Client PROD runtime | unchanged |
| GitOps manifests | unchanged |
| `latest` | untouched |

## No Side Effects

- No docker push.
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

GO PUSH IMAGE CLIENT REGISTER NO-PLAN TRIAL PROD PH-SAAS-T8.12AS.21.165
