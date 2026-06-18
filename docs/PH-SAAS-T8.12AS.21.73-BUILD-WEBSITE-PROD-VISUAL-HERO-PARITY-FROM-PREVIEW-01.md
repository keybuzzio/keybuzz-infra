# PH-SAAS-T8.12AS.21.73 - Build Website PROD visual hero parity from preview

## RESUME LUDOVIC - TERMINAL

PH-21.73 BUILD WEBSITE PROD VISUAL HERO PARITY FROM PREVIEW : READY

- Bastion : install-v3 / 46.62.171.61 conforme.
- Website source : main HEAD=origin/main=bd32fc8bc9d9554770cc611f0712998b111473ff, dirty=0, ahead/behind 0/0.
- Infra source avant rapport : main HEAD=origin/main=f789d1327080413da3ac674b593d238af0d30055, dirty=0, ahead/behind 0/0.
- Image locale construite uniquement : ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod
- Image ID : sha256:fe00622da7492b78ea8b9749ade882307f6d894e9d8ce81f142391de3f0c0ce2
- OCI labels : revision=bd32fc8bc9d9554770cc611f0712998b111473ff ; version=v0.7.2-visual-hero-parity-prod ; title=keybuzz-website ; source=https://github.com/keybuzzio/keybuzz-website
- Audit bundle : hero visuel preview present (kb2=5, kb2-hero=4, WaveCanvas=0, grid-overlay=4), hero copy present, body PROD conserve.
- Audit tracking PROD : client/api contact/SGTM/Clarity/GA/Meta/TikTok/LinkedIn presents.
- Interdits bundle : client-dev=0, api-dev=0, tag DEV=0, anciens prix=0, KPI -84=0, StartTrial=0, Purchase=0, CompletePayment=0, InitiateCheckout=0, Lead=3 (REVIEWED_NON_BLOCKING).
- Registry : tag cible absent avant/apres, aucun docker push, latest inchange.
- Runtime : Website PROD et DEV inchanges, aucun deploy/kubectl apply, aucun manifest modifie.
- Rapport : /opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.73-BUILD-WEBSITE-PROD-VISUAL-HERO-PARITY-FROM-PREVIEW-01.md
- Prochain GO exact : GO PUSH IMAGE WEBSITE PROD VISUAL HERO PARITY FROM PREVIEW PH-SAAS-T8.12AS.21.74

STOP

## Scope

Mode BUILD ONLY respecte.

Hors scope respecte :

- Aucun docker push.
- Aucun deploy.
- Aucun kubectl apply.
- Aucun manifest modifie.
- Aucun formulaire.
- Aucun checkout.
- Aucun fake event.
- Aucun Webflow.
- Aucun Linear.

## Preflight

| Controle | Resultat |
|---|---|
| Date UTC | 2026-06-18T08:44:38Z |
| Bastion | install-v3 |
| IP | 46.62.171.61 |
| Website branch | main |
| Website HEAD | bd32fc8bc9d9554770cc611f0712998b111473ff |
| Website origin/main | bd32fc8bc9d9554770cc611f0712998b111473ff |
| Website dirty before/after | 0 / 0 |
| Website ahead/behind before/after | 0/0 / 0/0 |
| Infra HEAD before report | f789d1327080413da3ac674b593d238af0d30055 |
| Infra dirty before report | 0 |
| Infra ahead/behind before report | 0/0 |

## Build

| Item | Value |
|---|---|
| Target image | ghcr.io/keybuzzio/keybuzz-website:v0.7.2-visual-hero-parity-prod |
| Build source | bd32fc8bc9d9554770cc611f0712998b111473ff |
| Build created | 2026-06-18T08:42:51Z |
| Image ID | sha256:fe00622da7492b78ea8b9749ade882307f6d894e9d8ce81f142391de3f0c0ce2 |
| Image size bytes | 213712959 |
| Docker push | not executed |
| latest push/tag | not executed |

## Build args

| Build arg | Value |
|---|---|
| NEXT_PUBLIC_SITE_MODE | production |
| NEXT_PUBLIC_CLIENT_APP_URL | https://client.keybuzz.io |
| NEXT_PUBLIC_CONTACT_API_URL | https://api.keybuzz.io/api/public/contact |
| NEXT_PUBLIC_SGTM_URL | https://t.keybuzz.pro |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | wrff07upjx |
| NEXT_PUBLIC_GA_ID | G-R3QQDYEBFG |
| NEXT_PUBLIC_META_PIXEL_ID | 1234164602194748 |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | D7PT12JC77U44OJIPC10 |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 |

## Image labels

| Label | Value |
|---|---|
| org.opencontainers.image.revision | bd32fc8bc9d9554770cc611f0712998b111473ff |
| org.opencontainers.image.version | v0.7.2-visual-hero-parity-prod |
| org.opencontainers.image.title | keybuzz-website |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-website |

## Bundle audit

| Marker | Count | Verdict |
|---|---:|---|
| kb2 | 5 | PASS |
| kb2-hero | 4 | PASS |
| WaveCanvas | 0 | INFO |
| grid-overlay | 4 | INFO |
| Reprenez le contr | 3 | PASS |
| marges | 3 | PASS |
| Vous validez | 9 | PASS |
| automatisez seulement | 3 | PASS |
| Ce que KeyBuzz change | 3 | PASS |
| Si vous vendez sur marketplace | 3 | PASS |
| SP-API | 35 | PASS |
| Questions frequentes | 14 | PASS |
| CTA final marker Voir les plans | 0 | INFO |

## Tracking audit

| Marker | Count | Verdict |
|---|---:|---|
| client.keybuzz.io | 33 | PASS |
| api.keybuzz.io/api/public/contact | 2 | PASS |
| t.keybuzz.pro | 18 | PASS |
| wrff07upjx | 2 | PASS |
| G-R3QQDYEBFG | 18 | PASS |
| 1234164602194748 | 2 | PASS |
| D7PT12JC77U44OJIPC10 | 2 | PASS |
| 9969977 | 18 | PASS |

## Forbidden marker audit

| Marker | Count | Verdict |
|---|---:|---|
| client-dev.keybuzz.io | 0 | PASS |
| api-dev.keybuzz.io | 0 | PASS |
| v0.7.1-hero-copy-prod-body-parity-dev | 0 | PASS |
| 49 EUR | 0 | PASS |
| 199 EUR | 0 | PASS |
| 49e/mois | 0 | PASS |
| 199e/mois | 0 | PASS |
| -84 | 0 | PASS |
| StartTrial | 0 | PASS |
| Purchase | 0 | PASS |
| CompletePayment | 0 | PASS |
| InitiateCheckout | 0 | PASS |
| Lead | 3 | REVIEWED_NON_BLOCKING |

## Registry and runtime safety

| Controle | Before | After | Verdict |
|---|---|---|---|
| Target tag registry | absent | absent | PASS |
| latest manifest hash | present:706a4e0e9134ecb4d6cda787a6583e653295fa18a84d7169cd668c55b885d4b5 | present:706a4e0e9134ecb4d6cda787a6583e653295fa18a84d7169cd668c55b885d4b5 | PASS |
| Manifest refs target | 0 | 0 | PASS |
| Website PROD runtime | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod|2/2|restarts=0 0 | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-prod|2/2|restarts=0 0 | PASS |
| Website DEV runtime | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev|1/1|restarts=0 | ghcr.io/keybuzzio/keybuzz-website:v0.7.1-hero-copy-prod-body-parity-dev|1/1|restarts=0 | PASS |

## Verdict

READY.

Image locale produite et auditee. Publication non effectuee.

Prochain GO exact :

```
GO PUSH IMAGE WEBSITE PROD VISUAL HERO PARITY FROM PREVIEW PH-SAAS-T8.12AS.21.74
```
