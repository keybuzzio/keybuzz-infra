# PH-SAAS-T8.12AS.21.139 - BUILD CLIENT NO-CARD TRIAL ONBOARDING AND LAUNCH PRICING 2026 DEV

Date UTC: 2026-06-26

## RESUME LUDOVIC

Verdict: READY_WITH_DEBTS PH-SAAS-T8.12AS.21.139.

Image Client DEV locale construite:

`ghcr.io/keybuzzio/keybuzz-client:v3.5.261-no-card-trial-onboarding-dev`

Image ID:

`sha256:20be780c7b1155dee9a4b05a84662cc22f3afe69256dae33adedd15d30e2a573`

Source Git build:

`keybuzz-client` branche `ph148/onboarding-activation-replay`, commit `05ac9cfb56664625938fda8aa6e40f4e23516a89`, build-from-git propre depuis `/tmp/ph21139-client-build-20260626T193048Z`.

Build args DEV explicites:

- `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io`
- `NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io`
- `NEXT_PUBLIC_APP_ENV=development`
- `NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG`
- `NEXT_PUBLIC_CLARITY_PROJECT_ID=wuk12h9i33`
- `NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977`

Audit bundle:

- API DEV presente globalement dans le bundle: `api_dev_count=88`.
- API PROD absente globalement du bundle: `api_prod_count=0`.
- `/register` appelle le BFF no-card trial: `register_no_card_trial_route=2`.
- `/register` ne contient plus `/api/billing/checkout-session`: `register_billing_checkout_route=0`.
- `/register` ne contient pas `trackBeginCheckout`, `InitiateCheckout`, `StartTrial`, `Purchase`, `CompletePayment`.
- Source pricing cible: 47/97/197 presents, 297/497 absents.
- Attribution preservee: `marketing_owner_tenant_id`, `utm/click IDs` source et register_started PH-21.86 conserves.

Tests:

- `node scripts/ph2186-register-started-attribution.test.cjs`: PASS.
- `node scripts/ph21138-no-card-trial-onboarding.test.cjs`: PASS.
- `npx eslint app/register/page.tsx app/api/tenant-context/no-card-trial/route.ts src/features/pricing/config.ts src/features/billing/planCapabilities.ts`: PASS.
- `npx tsc --noEmit --pretty false`: PASS.

Registry/runtime:

- Tag GHCR cible absent avant/apres build: `manifest unknown`.
- `latest` intact: manifest JSON sha256 `151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341`.
- Aucun docker push.
- Aucun deploy.
- Aucun `kubectl apply`.
- Client DEV/PROD runtime inchanges.

Dette/limite:

- Le clone de build est clean avant build. Apres les checks, `tsconfig.tsbuildinfo` est modifie par `tsc`; ce fichier n'est pas une source applicative build-from-git et n'a pas ete committe.
- L'audit global du bundle trouve des occurrences hors scope de `/api/billing/checkout-session`, `Purchase`, `297` et `497`; l'audit cible source + `/register` les classe non bloquantes pour PH-21.139.

Prochain GO:

`GO PUSH IMAGE CLIENT NO-CARD TRIAL ONBOARDING AND LAUNCH PRICING 2026 DEV PH-SAAS-T8.12AS.21.140`

STOP.

## PREFLIGHT

| Point | Attendu | Resultat |
|---|---|---|
| Bastion | `install-v3` | PASS |
| IP bastion | `46.62.171.61` | PASS |
| Repo Client | `/opt/keybuzz/keybuzz-client` | PASS |
| Branche Client | `ph148/onboarding-activation-replay` | PASS |
| HEAD Client | `05ac9cfb56664625938fda8aa6e40f4e23516a89` | PASS |
| Ahead/behind Client | `0/0` | PASS |
| Dirty Client | preexisting `tsconfig.tsbuildinfo` hors scope | PASS_WITH_DEBT |
| Repo Infra | `/opt/keybuzz/keybuzz-infra` | PASS |
| Infra ahead/behind avant rapport | `0/0` | PASS |

## SOURCE ET BUILD

| Element | Valeur |
|---|---|
| Repo source | `keybuzz-client` |
| Branche source | `ph148/onboarding-activation-replay` |
| Commit source | `05ac9cfb56664625938fda8aa6e40f4e23516a89` |
| Build dir | `/tmp/ph21139-client-build-20260626T193048Z` |
| Image locale | `ghcr.io/keybuzzio/keybuzz-client:v3.5.261-no-card-trial-onboarding-dev` |
| Image ID | `sha256:20be780c7b1155dee9a4b05a84662cc22f3afe69256dae33adedd15d30e2a573` |
| OCI revision | `05ac9cfb56664625938fda8aa6e40f4e23516a89` |
| OCI version | `v3.5.261-no-card-trial-onboarding-dev` |

## AUDIT BUNDLE

| Controle | Resultat |
|---|---|
| `https://api-dev.keybuzz.io` global | `88` |
| `https://api.keybuzz.io` global | `0` |
| `/api/tenant-context/no-card-trial` global | `5` |
| `/register` no-card trial route | `2` |
| `/register` checkout Stripe route | `0` |
| `/register` old checkout CTA | `0` |
| `/register` `trackBeginCheckout` | `0` |
| `/register` `InitiateCheckout` | `0` |
| `/register` `StartTrial` | `0` |
| `/register` `Purchase` | `0` |
| `/register` `CompletePayment` | `0` |
| `/register` `marketing_owner_tenant_id` | `2` |
| API BFF upstream `/tenant-context/no-card-trial` | `1` |

## PRICING

| Controle source cible | Resultat |
|---|---|
| `47` | `3` |
| `97` | `5` |
| `197` | `2` |
| `297` | `0` |
| `497` | `0` |

## NO FAKE METRICS / NO FAKE EVENTS

| Point | Resultat |
|---|---|
| POST `/funnel/event` | `0` |
| Faux StartTrial | `0` |
| Faux Purchase | `0` |
| Faux CompletePayment | `0` |
| Formulaire reel | `0` |
| Checkout Stripe | `0` |
| DB mutation volontaire | `0` |

## NON-REGRESSION

| Surface | Resultat |
|---|---|
| Client DEV runtime | inchange |
| Client PROD runtime | inchange |
| API DEV/PROD | inchanges |
| Website/Admin/Backend | inchanges |
| GitOps manifests | inchanges |
| `latest` GHCR | intact |

## VERDICT

`GO BUILD CLIENT NO-CARD TRIAL ONBOARDING AND LAUNCH PRICING 2026 DEV READY_WITH_DEBTS PH-SAAS-T8.12AS.21.139`

STOP.
