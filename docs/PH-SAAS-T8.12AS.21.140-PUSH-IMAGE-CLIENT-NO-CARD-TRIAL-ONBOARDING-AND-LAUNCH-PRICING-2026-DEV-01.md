# PH-SAAS-T8.12AS.21.140 - PUSH IMAGE CLIENT NO-CARD TRIAL ONBOARDING AND LAUNCH PRICING 2026 DEV

Date UTC: 2026-06-26

## RESUME LUDOVIC

Verdict: DONE PH-SAAS-T8.12AS.21.140.

Image poussee:

`ghcr.io/keybuzzio/keybuzz-client:v3.5.261-no-card-trial-onboarding-dev`

Manifest digest GHCR:

`sha256:faabf11ffe605a0aa37310430c83b421007eb7c5547d47cd9727fd2a57a53597`

Pull-back OK:

`ghcr.io/keybuzzio/keybuzz-client@sha256:faabf11ffe605a0aa37310430c83b421007eb7c5547d47cd9727fd2a57a53597`

Image ID / config:

`sha256:20be780c7b1155dee9a4b05a84662cc22f3afe69256dae33adedd15d30e2a573`

OCI revision:

`05ac9cfb56664625938fda8aa6e40f4e23516a89`

`latest` intact:

`151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341`

Aucun rebuild, aucun deploy, aucun `kubectl apply`, aucun event reel/fake, aucun formulaire, aucun checkout Stripe.

Prochain GO:

`GO APPLY CLIENT NO-CARD TRIAL ONBOARDING AND LAUNCH PRICING 2026 DEV GITOPS PH-SAAS-T8.12AS.21.141`

STOP.

## PREFLIGHT

| Controle | Attendu | Resultat |
|---|---|---|
| Image locale | presente | PASS |
| Image ID | `sha256:20be780c7b1155dee9a4b05a84662cc22f3afe69256dae33adedd15d30e2a573` | PASS |
| OCI revision | `05ac9cfb56664625938fda8aa6e40f4e23516a89` | PASS |
| Tag GHCR avant push | absent | PASS |
| `latest` avant push | intact | PASS |

## PUSH

| Point | Resultat |
|---|---|
| Docker push | PASS |
| Manifest digest | `sha256:faabf11ffe605a0aa37310430c83b421007eb7c5547d47cd9727fd2a57a53597` |
| Pull-back | PASS |
| RepoDigest | `ghcr.io/keybuzzio/keybuzz-client@sha256:faabf11ffe605a0aa37310430c83b421007eb7c5547d47cd9727fd2a57a53597` |
| Image ID apres pull-back | PASS |
| OCI revision apres pull-back | PASS |
| `latest` apres push | intact |

## NO FAKE METRICS / NO FAKE EVENTS

| Point | Resultat |
|---|---|
| Rebuild | `0` |
| Deploy/apply | `0` |
| POST `/funnel/event` | `0` |
| Formulaire | `0` |
| Checkout Stripe | `0` |
| DB mutation volontaire | `0` |

## NON-REGRESSION

| Surface | Resultat |
|---|---|
| Client DEV runtime | inchange |
| Client PROD runtime | inchange |
| API DEV/PROD | inchanges |
| Website/Admin/Backend | inchanges |
| Manifests GitOps | inchanges |
| `latest` | intact |

## VERDICT

`GO PUSH IMAGE CLIENT NO-CARD TRIAL ONBOARDING AND LAUNCH PRICING 2026 DEV DONE PH-SAAS-T8.12AS.21.140`

STOP.
