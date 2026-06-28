# PH-SAAS-T8.12AS.21.205 - Remove DEV advanced settings banner DEV/PROD

## Resume Ludovic

Verdict: READY.

Correction effectuee: suppression du bandeau jaune "DEV / environnement de developpement" dans l'onglet Parametres > Avance.

Source Client:

- repo: `/opt/keybuzz/keybuzz-client`
- branch: `ph148/onboarding-activation-replay`
- commit: `462287a1eea61a0ae5095805e8a78bead7578f41`
- scope source: `app/settings/components/AdvancedTab.tsx`

Runtime DEV:

- image: `ghcr.io/keybuzzio/keybuzz-client:v3.5.270-remove-dev-advanced-banner-dev`
- digest: `sha256:9d01bf680ba5a8933310e492d211230050c1d5a5c2a32867eb75eee2bf0c6eb2`
- image id: `sha256:eeb28f2c09458a345de8d18a857df5ecb7ec6d3ea7013adfa812c039d99643fd`
- ready: `1/1`
- restarts: `0`
- runtime banner text: `ABSENT`
- rollback: `v3.5.268-post-oauth-trial-readiness-dev`

Runtime PROD:

- image: `ghcr.io/keybuzzio/keybuzz-client:v3.5.270-remove-dev-advanced-banner-prod`
- digest: `sha256:2cb977762a14766ec78bfca25bee7ebbf60e596d4defad6abbb448269fd4bfc8`
- image id: `sha256:44b39411427df556f12dd688ee1bf3d4ef9490ca8ade8cd63fba50b691559150`
- ready: `1/1`
- restarts: `0`
- runtime banner text: `ABSENT`
- rollback: `v3.5.269-eslint-toolchain-post-oauth-trial-readiness-prod`

## Changements

| Fichier | Changement | Risque |
| --- | --- | --- |
| `app/settings/components/AdvancedTab.tsx` | Suppression du bloc informatif DEV affiche sans condition | Faible, pas de logique metier modifiee |
| `k8s/keybuzz-client-dev/deployment.yaml` | Bump image DEV uniquement | Faible, GitOps strict |
| `k8s/keybuzz-client-prod/deployment.yaml` | Bump image PROD uniquement | Faible, GitOps strict |

## Validations source

| Test | Resultat |
| --- | --- |
| `git diff --check -- app/settings/components/AdvancedTab.tsx` | PASS |
| `npx eslint app/settings/components/AdvancedTab.tsx` | PASS |
| Source Client clean apres commit/push | PASS |

## Build safety

| Image | Source | Build args | Bundle API URL |
| --- | --- | --- | --- |
| DEV `v3.5.270-remove-dev-advanced-banner-dev` | `462287a` | DEV explicites | `api-dev.keybuzz.io` present, `api.keybuzz.io` absent |
| PROD `v3.5.270-remove-dev-advanced-banner-prod` | `462287a` | PROD explicites + tracking PROD | `api.keybuzz.io` present, `api-dev.keybuzz.io` absent |

## GitOps

| Environnement | Commit infra | Apply | Rollout |
| --- | --- | --- | --- |
| DEV | `d060c6e` | `kubectl apply -f k8s/keybuzz-client-dev/deployment.yaml` | Successful |
| PROD | `f19667e` | `kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml` | Successful |

## Non-regression

- Aucun changement API.
- Aucun changement billing.
- Aucun changement onboarding.
- Aucun changement tracking volontaire.
- Aucun checkout, formulaire, event fake, DB mutation ou secret lu.
- `latest` intact, tags immuables utilises.

## Verdict

READY - le bandeau DEV incorrect est retire en DEV et PROD, avec runtime verifie.

STOP
