# PH-SAAS-T8.12AS.21.152 - WEBSITE AND STRIPE NO-CARD TRIAL LAUNCH PRICING 2026 CLOSE

Date UTC: 2026-06-26

## RESUME LUDOVIC

Verdict: READY_WITH_LIMITS PH-SAAS-T8.12AS.21.152.

Website DEV et PROD sont alignes sur le pricing de lancement 2026:

- Starter: 47 EUR / mois.
- Pro: 97 EUR / mois.
- Autopilot: 197 EUR / mois.
- Trial: 14 jours sans carte bancaire.

Stripe DEV et PROD sont alignes sur les memes montants:

- Starter monthly: 4 700 cents.
- Starter annual: 45 600 cents.
- Pro monthly: 9 700 cents.
- Pro annual: 93 600 cents.
- Autopilot monthly: 19 700 cents.
- Autopilot annual: 189 600 cents.

Les add-ons KBActions / canal supplementaire et Agent KeyBuzz sont restes inchanges.

Aucun checkout Stripe, formulaire, event tracking reel/fake, StartTrial, Purchase,
CompletePayment ou mutation DB volontaire n'a ete declenche par cette phase.

## WEBSITE DEV

| Controle | Resultat |
|---|---|
| Image | `ghcr.io/keybuzzio/keybuzz-website:v0.7.3-no-card-launch-pricing-dev` |
| Digest runtime | `sha256:b1af18d6c4e4e0d7046bb30fddc41d774f261c60432bfa528a885df39bef8996` |
| Image ID build | `sha256:0029fce9acce25a695f9829ecbaeaad9469077aaab97c5e526a3771d08157147` |
| Source Git | `0dc16900a1fd46317e6d4f5f72b8e9914a4c82ea` |
| Runtime | manifest = last-applied = deployment spec = pod spec |
| Ready / restarts | `1/1`, `0` |
| Client URL bundle | `https://client-dev.keybuzz.io` present |
| PROD client URL bundle | absent |
| Prix runtime | `47`, `97`, `197` presents |
| Ancien pricing visible | `297/497` absent |

## WEBSITE PROD

| Controle | Resultat |
|---|---|
| Image | `ghcr.io/keybuzzio/keybuzz-website:v0.7.3-no-card-launch-pricing-prod` |
| Digest runtime | `sha256:81adb5e2325953692c86fed3d15eae84882b5b4c78fd4fda0e666d3b1a856c35` |
| Image ID build | `sha256:d62459114c7b341e43e334d09ea700f511c9cc26219306118dce30655e2eab9e` |
| Source Git | `0dc16900a1fd46317e6d4f5f72b8e9914a4c82ea` |
| Runtime | manifest = last-applied = deployment spec = pod spec |
| Ready / restarts | `2/2`, `0/0` |
| Client URL bundle | `https://client.keybuzz.io` present |
| DEV client URL bundle | absent |
| Tracking PROD | GA4, Meta Pixel, TikTok, LinkedIn, Clarity, sGTM presents |
| Prix runtime | `47`, `97`, `197` presents |
| Ancien pricing visible | `297/497` absent |

## STRIPE DEV TEST

| Variable | Price ID | Montant | Produit |
|---|---:|---:|---|
| `STRIPE_PRICE_STARTER_MONTHLY` | `price_1TmhTjFC0QQLHISR7ztSAjKH` | 4 700 | KeyBuzz Starter |
| `STRIPE_PRICE_STARTER_ANNUAL` | `price_1TmhTkFC0QQLHISR3nPIz5hE` | 45 600 | KeyBuzz Starter |
| `STRIPE_PRICE_PRO_MONTHLY` | `price_1TmhTkFC0QQLHISRxTSa2SLd` | 9 700 | KeyBuzz Pro |
| `STRIPE_PRICE_PRO_ANNUAL` | `price_1TmhTkFC0QQLHISRYoWmsXxO` | 93 600 | KeyBuzz Pro |
| `STRIPE_PRICE_AUTOPILOT_MONTHLY` | `price_1TmhTlFC0QQLHISRn7uet5A8` | 19 700 | KeyBuzz Autopilot |
| `STRIPE_PRICE_AUTOPILOT_ANNUAL` | `price_1TmhTlFC0QQLHISRAsVw6YAN` | 189 600 | KeyBuzz Autopilot |

Controle runtime DEV:

- `stripe_key_mode=test`.
- Tous les Price IDs sont `active=true`, `livemode=false`, `currency=eur`.
- Pod API DEV observe: `keybuzz-api-9f8c4547c-bfljs`, Ready `1/1`, restarts `0`.
- API DEV runtime observe pendant le controle: `ghcr.io/keybuzzio/keybuzz-api:v3.5.267-no-card-trial-runtime-endpoint-dev`.

## STRIPE PROD LIVE

| Variable | Price ID | Montant | Produit |
|---|---:|---:|---|
| `STRIPE_PRICE_STARTER_MONTHLY` | `price_1TmhTnFC0QQLHISR8CMfefYQ` | 4 700 | KeyBuzz Starter |
| `STRIPE_PRICE_STARTER_ANNUAL` | `price_1TmhTnFC0QQLHISRjiZFukZ8` | 45 600 | KeyBuzz Starter |
| `STRIPE_PRICE_PRO_MONTHLY` | `price_1TmhToFC0QQLHISR9mqgYijQ` | 9 700 | KeyBuzz Pro |
| `STRIPE_PRICE_PRO_ANNUAL` | `price_1TmhToFC0QQLHISRaQz5yVag` | 93 600 | KeyBuzz Pro |
| `STRIPE_PRICE_AUTOPILOT_MONTHLY` | `price_1TmhToFC0QQLHISRvLYcF93t` | 19 700 | KeyBuzz Autopilot |
| `STRIPE_PRICE_AUTOPILOT_ANNUAL` | `price_1TmhTpFC0QQLHISRXV0nfwWb` | 189 600 | KeyBuzz Autopilot |

Controle runtime PROD:

- `stripe_key_mode=live`.
- Tous les Price IDs sont `active=true`, `livemode=true`, `currency=eur`.
- Pod API PROD observe: `keybuzz-api-69984dc555-xc99w`, Ready `1/1`, restarts `0`.
- API PROD runtime observe: `ghcr.io/keybuzzio/keybuzz-api:v3.5.265-meta-capi-error-observability-prod`.

## ADD-ONS INCHANGES

| Environnement | Add-on | Monthly | Annual |
|---|---|---:|---:|
| DEV | Canal supplementaire | 5 000 | 48 000 |
| DEV | Agent KeyBuzz | 79 700 | 765 600 |
| PROD | Canal supplementaire | 5 000 | 48 000 |
| PROD | Agent KeyBuzz | 79 700 | 765 600 |

## OPERATIONS EFFECTUEES

| Operation | DEV | PROD |
|---|---|---|
| Website source patch | oui | oui |
| Website build-from-git | oui | oui |
| Website image push immutable tag | oui | oui |
| Website GitOps apply | oui | oui |
| Stripe Prices creation | test mode | live mode |
| K8s Secret price refs | ExternalSecret/Vault sync | Secret price refs server-side apply |
| API pod runtime price refs | verifie | verifie |

## NO FAKE METRICS / NO FAKE EVENTS

| Point | Resultat |
|---|---|
| Checkout Stripe | `0` |
| Formulaire onboarding | `0` |
| POST `/funnel/event` | `0` |
| StartTrial/Purchase/CompletePayment | `0` |
| Event tracking reel/fake | `0` |
| Mutation DB volontaire | `0` |

## LIMITES RESTANTES

- Le parcours complet no-card trial doit encore etre verifie end-to-end avec une vraie inscription controlee.
- Les phases API/Client no-card trial continuent separement sous PH-21.124+ et ne sont pas reouvertes dans ce rapport.
- PROD Stripe a ete aligne sur les Price IDs live, mais aucun checkout live volontaire n'a ete lance.
- Le wording de promotion 2026 est deploye; la strategie commerciale finale reste une decision produit.

## VERDICT

`GO SOURCE PATCH WEBSITE DEV NO-CARD TRIAL AND LAUNCH PRICING 2026 PARITY READY_WITH_LIMITS PH-SAAS-T8.12AS.21.152`

STOP.
