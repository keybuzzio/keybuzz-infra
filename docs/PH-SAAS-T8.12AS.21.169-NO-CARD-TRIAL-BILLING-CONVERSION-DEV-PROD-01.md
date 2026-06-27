# PH-SAAS-T8.12AS.21.169 - No-card trial billing conversion DEV/PROD

## Resume Ludovic

Verdict: READY.

Regression corrigee: le trial sans CB n'est plus traite comme un fallback/demo dans la facturation. Il est expose comme un vrai etat billing `trialing` avec `source=db`, `requiresCheckout=true`, `hasStripeSubscription=false`.

Effet produit attendu:

- le bandeau trial redevient visible pendant l'essai;
- la page Facturation ne doit plus afficher "Mode demonstration" pour un trial sans CB reel;
- le client peut choisir un forfait et ajouter sa carte via Stripe Checkout;
- le portail Stripe reste logiquement indisponible tant qu'aucune subscription Stripe n'existe;
- a J0, le blocage reste porte par l'entitlement central si aucun moyen de paiement n'est ajoute.

No side-effect: aucun fake event, aucun checkout cree par CE, aucune mutation DB volontaire, aucun webhook Stripe modifie, aucun tracking pollue.

## Sources

| Repo | Branche | Commit | Dirty note |
| --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 1310df0a1a64e85b6b5c0898fee462fb34e5ceeb | dist/ deletions preexistantes conservees |
| keybuzz-client | ph148/onboarding-activation-replay | b92c2ba4f60bb5849f6117c644147c472e9d8964 | tsconfig.tsbuildinfo preexistant conserve |
| keybuzz-infra | main | 158e584b98e5d0beb2cabd76caa6605f64317acc | clean |

## Patch

| Fichier | Changement |
| --- | --- |
| keybuzz-api/src/modules/billing/routes.ts | `GET /billing/current` lit l'entitlement central et renvoie un no-card trial reel en `source=db`, sans simuler de subscription Stripe |
| keybuzz-api/src/tests/ph21132a-no-card-trial-runtime-endpoint-tests.ts | test source ajoute pour le contrat billing no-card trial |
| keybuzz-client/src/features/billing/useCurrentPlan.tsx | expose `trialEndsAt`, `daysLeftTrial`, `hasStripeSubscription`, `requiresCheckout` |
| keybuzz-client/src/features/billing/components/TrialBanner.tsx | bandeau visible pour tout `trialing`, plus seulement `isTrialBoosted` |
| keybuzz-client/app/billing/plan/page.tsx | trial sans CB affiche le bloc Checkout "Ajouter ma carte"; `change-plan` reste reserve aux subscriptions Stripe existantes |

## Tests source

| Test | Resultat |
| --- | --- |
| API `git diff --check` | PASS |
| Client `git diff --check` | PASS |
| API `npx tsc --noEmit` | PASS |
| API `npx ts-node src/tests/ph21132a-no-card-trial-runtime-endpoint-tests.ts` | PASS 85/85 |
| Client ESLint cible | PASS |
| Client `npx tsc --noEmit` | FAIL_PREEXISTING `.next/types/app/api/debug-env/route.ts` |

## Images DEV

| Service | Image | Digest | Image ID | Source |
| --- | --- | --- | --- | --- |
| API DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.270-billing-no-card-trial-conversion-dev | sha256:e9fbfab8465567706c0d4ea39e43850e7fadbf6a5811001aaadfb23d35881557 | sha256:c7f1d7b4455c317cac2c45e526676987cdf9db1b844e612054ba179cfeb6c0d5 | 1310df0a |
| Client DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.265-billing-no-card-trial-conversion-dev | sha256:4d51f2a14217c9bf5704fe33063ac266f499ed9d138072e96610b252c78d7657 | sha256:91d8e65741236a455f217cfa7b24eec22cbb69ab58203cc5b839a06433af43fa | b92c2ba |

## Images PROD

| Service | Image | Digest | Image ID | Source |
| --- | --- | --- | --- | --- |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.270-billing-no-card-trial-conversion-prod | sha256:7e2b788b1f1d88174ed07d575ce0ebde8fb4671009a7aec8a662d44045f9ce86 | sha256:addd6d4e77c268a8b3498d577ba923d2c7dbad6756471756c304061e6cc219e1 | 1310df0a |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.265-billing-no-card-trial-conversion-prod | sha256:8206e19d75d3de47725037877bed64cc834b9e0725402429460c8ca45b771a05 | sha256:7bc3b2c7649e4efd2e0fb9883aeb5e50d9fd9557dab68ec79dedb5bc9730e029 | b92c2ba |

## GitOps

| Env | Commit infra | Manifests | Resultat |
| --- | --- | --- | --- |
| DEV | 7dae9e5 | k8s/keybuzz-api-dev/deployment.yaml, k8s/keybuzz-client-dev/deployment.yaml | apply + rollout OK |
| PROD | 158e584 | k8s/keybuzz-api-prod/deployment.yaml, k8s/keybuzz-client-prod/deployment.yaml | apply + rollout OK |

## Verification DEV

| Point | Resultat |
| --- | --- |
| API runtime | v3.5.270, digest sha256:e9fbfab..., ready=true, restarts=0 |
| Client runtime | v3.5.265, digest sha256:4d51f2..., ready=true, restarts=0 |
| API markers | OK |
| Client markers | OK |
| Client bundle API DEV | OK |
| Client bundle API PROD | ABSENT |
| Sample billing current | tenant trial -> `trialing`, `source=db`, `requiresCheckout=true`, `hasStripeSubscription=false`, `daysLeftTrial=14`, `plan=AUTOPILOT` |

## Verification PROD

| Point | Resultat |
| --- | --- |
| API runtime | v3.5.270, digest sha256:7e2b788..., ready=true, restarts=0 |
| Client runtime | v3.5.265, digest sha256:8206e19..., ready=true, restarts=0 |
| API markers | OK |
| Client markers | OK |
| Client bundle API PROD | OK |
| Client bundle API DEV | ABSENT |
| Client public tracking IDs PROD | OK |
| Sample billing current | tenant `ecomlg-mqw7xv6f` -> `trialing`, `source=db`, `requiresCheckout=true`, `hasStripeSubscription=false`, `daysLeftTrial=14`, `plan=AUTOPILOT` |

## Non-regression

- `change-plan` reste reserve aux subscriptions Stripe existantes.
- no-card trial ne cree pas de subscription Stripe fictive.
- aucun webhook Stripe modifie.
- aucun StartTrial/Purchase/CompletePayment declenche.
- aucun fake event CAPI/GA4/funnel cree.
- Client DEV build args: API DEV presente, API PROD absente.
- Client PROD build args: API PROD presente, API DEV absente, IDs publics tracking PROD presents.

## Rollback

Rollback GitOps strict uniquement:

- API DEV -> `v3.5.269-first-run-onboarding-start-dev`
- Client DEV -> `v3.5.264-first-run-onboarding-start-dev`
- API PROD -> `v3.5.269-first-run-onboarding-start-prod`
- Client PROD -> `v3.5.264-first-run-onboarding-start-prod`

Ne pas utiliser `kubectl set image`, `kubectl patch`, `kubectl edit` ou `kubectl set env`.

## Dettes restantes

- Dette Client preexistante: `.next/types/app/api/debug-env/route.ts` fait echouer `npx tsc --noEmit` global hors build Docker.
- Vulns npm preexistantes signalees pendant build API/Client.
- Validation visuelle Ludovic recommandee sur `/billing/plan` en session authentifiee PROD.

## Verdict

GO READONLY CLOSE NO-CARD TRIAL BILLING CONVERSION DEV PROD READY PH-SAAS-T8.12AS.21.169

STOP
