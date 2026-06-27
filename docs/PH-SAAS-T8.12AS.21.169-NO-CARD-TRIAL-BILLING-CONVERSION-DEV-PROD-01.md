# PH-SAAS-T8.12AS.21.169 - No-card trial billing conversion DEV/PROD

## Resume Ludovic

Verdict: READY_NO_DEBT_KNOWN.

Regression corrigee: le trial sans CB n'est plus traite comme un fallback/demo dans la facturation. Il est expose comme un vrai etat billing `trialing` avec `source=db`, `requiresCheckout=true`, `hasStripeSubscription=false`.

Effet produit attendu:

- le bandeau trial reste visible pendant l'essai;
- la page Facturation ne doit plus afficher "Mode demonstration" pour un trial sans CB reel;
- le client peut choisir un forfait et ajouter sa carte via Stripe Checkout;
- le portail Stripe reste logiquement indisponible tant qu'aucune subscription Stripe n'existe;
- a J0, le blocage reste porte par l'entitlement central si aucun moyen de paiement n'est ajoute.

No side-effect: aucun fake event, aucun checkout cree par CE, aucune mutation DB volontaire, aucun webhook Stripe modifie, aucun tracking pollue.

## Sources finales

| Repo | Branche | Commit final | Dirty |
| --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | 80694ce082fff80357d6e30fb2f2d8abc65cb833 | 0 |
| keybuzz-client | ph148/onboarding-activation-replay | 5a9d298f0c3cd6c3ba27f0ce3d78570fd91328f3 | 0 |
| keybuzz-infra | main | 365ee16 | 0 |

## Patch fonctionnel billing

| Fichier | Changement |
| --- | --- |
| keybuzz-api/src/modules/billing/routes.ts | `GET /billing/current` lit l'entitlement central et renvoie un no-card trial reel en `source=db`, sans simuler de subscription Stripe |
| keybuzz-api/src/tests/ph21132a-no-card-trial-runtime-endpoint-tests.ts | test source ajoute pour le contrat billing no-card trial |
| keybuzz-client/src/features/billing/useCurrentPlan.tsx | expose `trialEndsAt`, `daysLeftTrial`, `hasStripeSubscription`, `requiresCheckout` |
| keybuzz-client/src/features/billing/components/TrialBanner.tsx | bandeau visible pour tout `trialing`, plus seulement `isTrialBoosted` |
| keybuzz-client/app/billing/plan/page.tsx | trial sans CB affiche le bloc Checkout "Ajouter ma carte"; `change-plan` reste reserve aux subscriptions Stripe existantes |

## Fermeture des dettes

| Dette initiale | Resolution |
| --- | --- |
| API dirty `dist/` preexistant | `git restore dist`; repo API final clean |
| Client dirty `tsconfig.tsbuildinfo` preexistant | `git restore tsconfig.tsbuildinfo`; repo Client final clean |
| Client `npx tsc --noEmit` bloque par stale `.next/types/app/api/debug-env` | artefact stale deplace dans `/tmp/ph21169-stale-next-debug-env-20260627-1`; `npx tsc --noEmit --pretty false --incremental false` PASS |
| Vulns npm API | dependances durcies; `npm audit` complet = 0 vulnerabilities |
| Vulns npm Client | Next 16.2.9 + dependances/overrides durcis; `npm audit --legacy-peer-deps` complet = 0 vulnerabilities |
| Warning Docker Client metadata git lookup | `GIT_COMMIT_SHA` prioritaire + fallback git silencieux |
| Warning Next telemetry build | `NEXT_TELEMETRY_DISABLED=1` en builder et runner |
| Middleware Next 16 | migration `middleware.ts` -> `proxy.ts` + Dockerfile `COPY proxy.ts` |

Dette restante connue dans le perimetre PH-21.169: aucune.

## Tests source finaux

| Test | Resultat |
| --- | --- |
| API `git diff --check` | PASS |
| Client `git diff --check` | PASS |
| API `npx tsc --noEmit` | PASS |
| Client `npx tsc --noEmit --pretty false --incremental false` | PASS |
| API PH21.107 / PH21.79 tests | PASS |
| Client payload/lint cible/tsc cible | PASS |
| API `npm audit` | PASS, 0 vulnerabilities |
| Client `npm audit --legacy-peer-deps` | PASS, 0 vulnerabilities |

## Images DEV finales

| Service | Image | Digest | Image ID | Source |
| --- | --- | --- | --- | --- |
| API DEV | ghcr.io/keybuzzio/keybuzz-api:v3.5.271-dependency-hardening-dev | sha256:c2e0279efd0a7a1cff5fece944119342f1b86bf79ea1e695899593279bb260ae | sha256:6621f1545a6a71a3e0f72e220927f693ce89287f925c2353e84a780019638330 | 80694ce0 |
| Client DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.266-dependency-hardening-dev | sha256:fbccb1e4526fbec6210fb63d08fa681faf83af77b409b294167905ba3d561974 | sha256:0525725c2e5091f3b3237203eb5621631d92a7cd1837c89f4812ce5bd82c323a | 5a9d298 |

## Images PROD finales

| Service | Image | Digest | Image ID | Source |
| --- | --- | --- | --- | --- |
| API PROD | ghcr.io/keybuzzio/keybuzz-api:v3.5.271-dependency-hardening-prod | sha256:2e54cfa32d91fe19bc10514157fe270b55ea10220226c1c5f0a2559c093158ca | sha256:21efbf9ad406132fd13c060967ee2dc0d8e81c30d0f2397f1c61cf4e2d2283c4 | 80694ce0 |
| Client PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.266-dependency-hardening-prod | sha256:93509dab8b9c18fd0c2d13ed6a159aa853a91df14f83d8374bb060bd5f240190 | sha256:7c5739b88dab1cd02ea27a030da36663a32ddca8273180aebc2ed4734abe5304 | 5a9d298 |

## GitOps final

| Env | Commit infra | Manifests | Resultat |
| --- | --- | --- | --- |
| DEV | 7b3685d | k8s/keybuzz-api-dev/deployment.yaml, k8s/keybuzz-client-dev/deployment.yaml | dry-run client/server OK, apply + rollout OK |
| PROD | 365ee16 | k8s/keybuzz-api-prod/deployment.yaml, k8s/keybuzz-client-prod/deployment.yaml | dry-run client/server OK, apply + rollout OK |

## Verification DEV finale

| Point | Resultat |
| --- | --- |
| API runtime | v3.5.271, digest sha256:c2e0279..., ready 1/1, restarts 0 |
| Client runtime | v3.5.266, digest sha256:fbccb1e..., ready 1/1, restarts 0 |
| Last-applied | API/Client = manifests Git |
| Client bundle API DEV | `api_dev_count=91` |
| Client bundle API PROD | `api_prod_count=0` |
| API audit source | 0 vulnerabilities |
| Client audit source | 0 vulnerabilities |
| Repos | API dirty 0, Client dirty 0, Infra dirty 0 |

## Verification PROD finale

| Point | Resultat |
| --- | --- |
| API runtime | v3.5.271, digest sha256:2e54cfa..., ready 1/1, restarts 0 |
| Client runtime | v3.5.266, digest sha256:93509d..., ready 1/1, restarts 0 |
| Last-applied | API/Client = manifests Git |
| API health | OK |
| Client `/billing/plan` HTML interne | OK |
| Client bundle API PROD | `api_prod_count=91` |
| Client bundle API DEV | `api_dev_count=0` |
| API audit source | 0 vulnerabilities |
| Client audit source | 0 vulnerabilities |
| Repos | API dirty 0, Client dirty 0, Infra dirty 0 |

## Non-regression

- `change-plan` reste reserve aux subscriptions Stripe existantes.
- no-card trial ne cree pas de subscription Stripe fictive.
- aucun webhook Stripe modifie.
- aucun StartTrial/Purchase/CompletePayment declenche.
- aucun fake event CAPI/GA4/funnel cree.
- Client DEV build args: API DEV presente, API PROD absente.
- Client PROD build args: API PROD presente, API DEV absente, IDs publics tracking PROD presents.
- API et Client restent build-from-git, tags immuables, digests documentes.

## Rollback

Rollback GitOps strict uniquement:

- API DEV -> `v3.5.270-billing-no-card-trial-conversion-dev`
- Client DEV -> `v3.5.265-billing-no-card-trial-conversion-dev`
- API PROD -> `v3.5.270-billing-no-card-trial-conversion-prod`
- Client PROD -> `v3.5.265-billing-no-card-trial-conversion-prod`

Ne pas utiliser `kubectl set image`, `kubectl patch`, `kubectl edit` ou `kubectl set env`.

## Verdict

GO READONLY CLOSE NO-CARD TRIAL BILLING CONVERSION DEV PROD READY_NO_DEBT_KNOWN PH-SAAS-T8.12AS.21.169

STOP
