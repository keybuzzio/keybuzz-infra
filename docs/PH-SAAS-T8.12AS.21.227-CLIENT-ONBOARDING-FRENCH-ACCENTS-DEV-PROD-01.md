# PH-SAAS-T8.12AS.21.227 - Client onboarding French accents DEV/PROD

Date: 2026-06-30

## Verdict

READY_CLOSED.

Les accents manquants du parcours onboarding Client ont été corrigés, construits, poussés et déployés en DEV puis en PROD via GitOps strict.

## Scope

- Surface: Client onboarding `/register`, `/register/success`, `/start`, composants onboarding.
- Environnements: DEV et PROD.
- Changement fonctionnel: aucun.
- Objectif: correction de libellés FR mal accentués uniquement.

## Source

| Repo | Branche | Commit | Dirty |
| --- | --- | --- | --- |
| keybuzz-client DEV | ph148/onboarding-activation-replay | 8646ee6e54fe0f656b10bd5071f38253b7007cbd | 0 |
| keybuzz-client PROD release | ph148/prod-onboarding-accents-ph21227 | 8ef61e8e611acad53a997995f3aa939e112da6a2 | 0 |
| keybuzz-infra | main | 0025ef883bba4fe006008673c877960bd23356f6 | 0 |

## Images

| Env | Image | Digest | Source | Rollback |
| --- | --- | --- | --- | --- |
| DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.281-onboarding-french-accents-dev | sha256:c335d708d7b140b9f03cb5ef78dd938f2d1fa92027dee42984afa36bfea1e76c | 8646ee6e54fe0f656b10bd5071f38253b7007cbd | v3.5.280-shopify-readiness-dev |
| PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.279-onboarding-french-accents-prod | sha256:a9388533256d64b3f023f51a745e29c6583ea52435a8ba8baafc6c055ff6d219 | 8ef61e8e611acad53a997995f3aa939e112da6a2 | v3.5.278-auth-shell-bypass-prod |

## GitOps

| Env | Manifest | Résultat |
| --- | --- | --- |
| DEV | k8s/keybuzz-client-dev/deployment.yaml | image bump appliqué |
| PROD | k8s/keybuzz-client-prod/deployment.yaml | image bump appliqué |

Déploiement effectué par `kubectl apply -f` uniquement. Aucun `kubectl set image`, `kubectl patch`, `kubectl edit`.

## Runtime

| Env | Runtime image | Ready | Generation | Restart | Pod digest |
| --- | --- | --- | --- | --- | --- |
| DEV | ghcr.io/keybuzzio/keybuzz-client:v3.5.281-onboarding-french-accents-dev | 1/1 | 1043/1043 | 0 | sha256:c335d708d7b140b9f03cb5ef78dd938f2d1fa92027dee42984afa36bfea1e76c |
| PROD | ghcr.io/keybuzzio/keybuzz-client:v3.5.279-onboarding-french-accents-prod | 1/1 | 439/439 | 0 | sha256:a9388533256d64b3f023f51a745e29c6583ea52435a8ba8baafc6c055ff6d219 |

Égalité vérifiée: manifest Git = last-applied = deployment spec = pod spec = pod imageID.

## Bundle audit

| Env | Attendu | Résultat |
| --- | --- | --- |
| DEV | accents onboarding présents | PASS |
| DEV | `https://api-dev.keybuzz.io` présent | PASS |
| DEV | `https://api.keybuzz.io` absent | PASS |
| PROD | accents onboarding présents | PASS |
| PROD | `https://api.keybuzz.io` présent | PASS |
| PROD | `https://api-dev.keybuzz.io` absent | PASS |
| PROD | patch Shopify readiness DEV absent (`Commandes Shopify`) | PASS |

Chaînes validées dans les bundles:

- `Accès complet à KeyBuzz`
- `Démarrer mon essai gratuit sans CB`
- `Votre compte a été créé`

## Non-régression

- Aucun fake event.
- Aucun formulaire soumis.
- Aucun checkout Stripe.
- Aucune mutation DB volontaire.
- Aucun secret lu ou affiché.
- Aucun changement API/Admin/Website/Backend.
- PROD construite depuis le commit source PROD runtime précédent + correction accents uniquement, sans promotion accidentelle du patch Shopify DEV.

## Dette restante

Aucune dette technique restante sur ce scope.

STOP.
