# PH-SAAS-T8.12AS.21.142 - READONLY VERIFY CLIENT NO-CARD TRIAL ONBOARDING AND LAUNCH PRICING 2026 DEV

Date UTC: 2026-06-26

## RESUME LUDOVIC

Verdict: READY_WITH_LIMITS PH-SAAS-T8.12AS.21.142.

Client DEV runtime confirme:

`ghcr.io/keybuzzio/keybuzz-client:v3.5.261-no-card-trial-onboarding-dev`

Digest runtime:

`sha256:faabf11ffe605a0aa37310430c83b421007eb7c5547d47cd9727fd2a57a53597`

Runtime equality:

- manifest Git: PASS
- last-applied: PASS
- deployment spec: PASS
- pod imageID: PASS

Pod:

- `keybuzz-client-956c4f894-kxgq9`
- phase `Running`
- ready `True`
- restarts `0`

Smoke HTTP passif:

- `https://client-dev.keybuzz.io/register`
- HTTP `200`
- HTML `9285` bytes
- API PROD absente de l'HTML DEV: PASS

Audit `/register`:

- no-card trial BFF present: PASS
- `/api/billing/checkout-session` absent: PASS
- `register_confirm_plan_and_checkout` absent: PASS
- `trackBeginCheckout`, `InitiateCheckout`, `StartTrial`, `Purchase`, `CompletePayment` absents: PASS
- `marketing_owner_tenant_id` preserve: PASS

Pricing source:

- 47/97/197 presents: PASS
- 297/497 absents dans la source cible: PASS

Limites:

- Aucun vrai parcours navigateur/formulaire n'a ete execute.
- Aucun tenant trial n'a ete cree par CE.
- Le test fonctionnel end-to-end register -> dashboard attend un GO separe, car il mute un tenant.

Prochain GO:

`GO READONLY CLOSE CLIENT NO-CARD TRIAL ONBOARDING AND LAUNCH PRICING 2026 DEV PH-SAAS-T8.12AS.21.143`

STOP.

## RUNTIME

| Controle | Resultat |
|---|---|
| Deployment image | `ghcr.io/keybuzzio/keybuzz-client:v3.5.261-no-card-trial-onboarding-dev` |
| Last-applied image | `ghcr.io/keybuzzio/keybuzz-client:v3.5.261-no-card-trial-onboarding-dev` |
| Generation | `1026/1026` |
| Ready replicas | `1/1` |
| Pod | `keybuzz-client-956c4f894-kxgq9` |
| Pod phase | `Running` |
| Pod ready | `True` |
| Restarts | `0` |
| Pod imageID | `ghcr.io/keybuzzio/keybuzz-client@sha256:faabf11ffe605a0aa37310430c83b421007eb7c5547d47cd9727fd2a57a53597` |

## AUDIT BUNDLE / REGISTER

| Controle | Resultat |
|---|---|
| Build source HEAD | `05ac9cfb56664625938fda8aa6e40f4e23516a89` |
| `/register` no-card trial route | `2` |
| `/register` billing checkout route | `0` |
| `/register` old checkout CTA | `0` |
| `/register` `trackBeginCheckout` | `0` |
| `/register` `InitiateCheckout` | `0` |
| `/register` `StartTrial` | `0` |
| `/register` `Purchase` | `0` |
| `/register` `CompletePayment` | `0` |
| `/register` `marketing_owner_tenant_id` | `2` |
| BFF upstream `/tenant-context/no-card-trial` | `1` |

## HTTP PASSIF

| URL | HTTP | Bytes | Resultat |
|---|---:|---:|---|
| `https://client-dev.keybuzz.io/register` | `200` | `9285` | PASS |

## NON-REGRESSION

| Surface | Image lue |
|---|---|
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-prod` |
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.267-no-card-trial-runtime-endpoint-dev` |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod` |

## NO FAKE METRICS / NO FAKE EVENTS

| Point | Resultat |
|---|---|
| POST `/funnel/event` | `0` |
| Formulaire | `0` |
| Checkout Stripe | `0` |
| Tenant trial cree par CE | `0` |
| StartTrial/Purchase/CompletePayment fake | `0` |
| DB mutation volontaire | `0` |

## VERDICT

`GO READONLY VERIFY CLIENT NO-CARD TRIAL ONBOARDING AND LAUNCH PRICING 2026 DEV READY_WITH_LIMITS PH-SAAS-T8.12AS.21.142`

STOP.
