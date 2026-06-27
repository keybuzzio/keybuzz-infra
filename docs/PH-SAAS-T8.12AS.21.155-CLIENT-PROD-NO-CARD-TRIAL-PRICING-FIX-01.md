# PH-SAAS-T8.12AS.21.155 - CLIENT PROD NO-CARD TRIAL PRICING FIX

Date UTC: 2026-06-27

## RESUME LUDOVIC

Verdict: READY_FIXED PH-SAAS-T8.12AS.21.155.

Symptome signale:

- `https://client-dev.keybuzz.io/register` OK.
- `https://client.keybuzz.io/register` affichait encore les anciens prix.

Cause:

- Client DEV avait bien ete promu sur `v3.5.261-no-card-trial-onboarding-dev`.
- Client PROD etait encore sur `v3.5.260-onboarding-register-started-owner-payload-prod`.
- La promotion Client PROD no-card trial / launch pricing n'avait pas encore ete faite.

Correction effectuee:

- Build Client PROD depuis source Git propre `05ac9cfb56664625938fda8aa6e40f4e23516a89`.
- Image poussee: `ghcr.io/keybuzzio/keybuzz-client:v3.5.262-no-card-trial-onboarding-prod`.
- Digest GHCR: `sha256:d16815cf2fd99fe7344925e234064af12677e13c82b698613eff7df99f67fdc0`.
- Config/Image ID: `sha256:cfe15b58a436c00f9cc47f37d88be806655fec3e7d10105312ec2a2dd073d9a3`.
- GitOps PROD applique via `k8s/keybuzz-client-prod/deployment.yaml`.
- Manifest commit: `53a9304`.

Runtime final:

- Client PROD image: `ghcr.io/keybuzzio/keybuzz-client:v3.5.262-no-card-trial-onboarding-prod`.
- Runtime equality: manifest = last-applied = deployment spec = pod spec.
- Pod imageID digest: `sha256:d16815cf2fd99fe7344925e234064af12677e13c82b698613eff7df99f67fdc0`.
- Ready: `1/1`.
- Restarts: `0`.
- Generation: `429/429`.

Verification pricing:

- Bundle image: `price:47`, `price:97`, `price:197` presents.
- Bundle image: `price:297`, `price:497` absents.
- Public passive GET `https://client.keybuzz.io/register`: old prices `297/497` absents.
- Public passive GET: `api-dev.keybuzz.io` absent.

No fake metrics / no fake events:

- Aucun formulaire soumis.
- Aucun checkout Stripe.
- Aucun POST `/funnel/event`.
- Aucun StartTrial/Purchase/CompletePayment declenche.
- Aucune mutation DB volontaire.

## SOURCE

| Controle | Resultat |
|---|---|
| Repo | `/opt/keybuzz/keybuzz-client` |
| Branche | `ph148/onboarding-activation-replay` |
| Commit source | `05ac9cfb56664625938fda8aa6e40f4e23516a89` |
| Dirty source | `tsconfig.tsbuildinfo` preexistant, non touche |
| Build dir | `/tmp/ph21153-client-build-20260627T080314Z` |

## TESTS PRE-BUILD

| Test | Resultat |
|---|---|
| `node scripts/ph2186-register-started-attribution.test.cjs` | PASS |
| `node scripts/ph21138-no-card-trial-onboarding.test.cjs` | PASS |
| `eslint` cible register/no-card/pricing/capabilities | PASS |
| `tsc --noEmit` | PASS apres generation build metadata |

## BUILD ARGS PROD

| Build arg | Resultat |
|---|---|
| `NEXT_PUBLIC_APP_ENV` | `production` |
| `NEXT_PUBLIC_API_URL` | `https://api.keybuzz.io` |
| `NEXT_PUBLIC_API_BASE_URL` | `https://api.keybuzz.io` |
| `NEXT_PUBLIC_GA4_MEASUREMENT_ID` | present |
| `NEXT_PUBLIC_META_PIXEL_ID` | present |
| `NEXT_PUBLIC_SGTM_URL` | present |
| `NEXT_PUBLIC_TIKTOK_PIXEL_ID` | present |
| `NEXT_PUBLIC_LINKEDIN_PARTNER_ID` | present |
| `NEXT_PUBLIC_CLARITY_PROJECT_ID` | present |

## AUDIT IMAGE

| Controle | Resultat |
|---|---|
| API PROD occurrences | `88` |
| API DEV occurrences | `0` |
| No-card route occurrences | `13` |
| `register_confirm_plan_and_start_trial` | `2` |
| `register_confirm_plan_and_checkout` | `0` |
| `handleConfirmPlanAndCheckout` | `0` |
| `trackBeginCheckout` | `0` |
| `InitiateCheckout` | `0` |
| `StartTrial` | `0` |
| `CompletePayment` | `0` |

## PRICING BUNDLE

| Controle | Resultat |
|---|---|
| `price:47` | `17` |
| `price:97` | `17` |
| `price:197` | `17` |
| `price:297` | `0` |
| `price:497` | `0` |

## GITOPS

| Controle | Resultat |
|---|---|
| Manifest modifie | `k8s/keybuzz-client-prod/deployment.yaml` |
| Commit infra | `53a9304` |
| Apply | `kubectl apply -f` uniquement |
| Dry-run client | PASS |
| Dry-run server | PASS |
| Rollout | successful |

## VERDICT

`GO READONLY VERIFY CLIENT PROD NO-CARD TRIAL PRICING FIX READY_FIXED PH-SAAS-T8.12AS.21.155`

STOP.
