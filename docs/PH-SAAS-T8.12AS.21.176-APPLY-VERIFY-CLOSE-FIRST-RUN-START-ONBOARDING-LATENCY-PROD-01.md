# PH-SAAS-T8.12AS.21.176 - Apply, verify and close first-run /start onboarding latency PROD

## Verdict

READY_CLOSED.

La correction de latence premier parcours `/register` -> `/start` est appliquee en PROD via GitOps strict, verifiee, et cloturee techniquement.

## Objectif

Promouvoir en PROD les images construites et poussees en PH-21.174/PH-21.175:

- API `ghcr.io/keybuzzio/keybuzz-api:v3.5.273-start-onboarding-latency-prod`
- Client `ghcr.io/keybuzzio/keybuzz-client:v3.5.267-start-onboarding-latency-prod`

Scope realise:

- patch image-only des manifests PROD;
- commit + push infra avant apply;
- `kubectl apply -f` uniquement;
- rollout status;
- verification runtime = manifest = last-applied = pod digest;
- smoke passif interne et public;
- close technique.

## Preconditions

| Controle | Resultat |
| --- | --- |
| Infra avant apply | clean, ahead/behind 0/0 |
| Images GHCR PH-21.175 | PRESENT |
| Runtime PROD avant apply | API `v3.5.271`, Client `v3.5.266`, ready 1/1 |
| Dry-run client | PASS API + Client |
| Dry-run server | PASS API + Client |
| Diff manifests | 2 lignes image uniquement |

## GitOps

Commit manifest:

- `2d8d348e4fe1371c257e26450ece898af3d23665`
- Message: `deploy(prod): apply start onboarding latency fixes`

Fichiers modifies:

| Fichier | Changement |
| --- | --- |
| `k8s/keybuzz-api-prod/deployment.yaml` | `v3.5.271-dependency-hardening-prod` -> `v3.5.273-start-onboarding-latency-prod` |
| `k8s/keybuzz-client-prod/deployment.yaml` | `v3.5.266-dependency-hardening-prod` -> `v3.5.267-start-onboarding-latency-prod` |

Commandes appliquees:

- `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`
- `kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml`
- `kubectl -n keybuzz-api-prod rollout status deploy/keybuzz-api --timeout=240s`
- `kubectl -n keybuzz-client-prod rollout status deploy/keybuzz-client --timeout=240s`

Interdits respectes:

- 0 `kubectl set image`
- 0 `kubectl set env`
- 0 `kubectl patch`
- 0 `kubectl edit`

## Runtime final PROD

| Service | Image runtime | Digest pod actif | Ready | Restarts | Generation |
| --- | --- | --- | --- | --- | --- |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.273-start-onboarding-latency-prod` | `sha256:424612fe036d604f95c0d843b02a0ca3b9035c0c5f07d122615b5bf1ea03a9c7` | 1/1 | 0 | 432/432 |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.267-start-onboarding-latency-prod` | `sha256:ae5de89ed95da058ece6f93d85ae6a2f925d8aa6d1b437ae6f0dde06a1b5dbc0` | 1/1 | 0 | 434/434 |

Equality:

| Service | Manifest | Last-applied | Deployment spec | Pod digest | Verdict |
| --- | --- | --- | --- | --- | --- |
| API PROD | cible PH-21.176 | cible PH-21.176 | cible PH-21.176 | digest GHCR PH-21.175 | PASS |
| Client PROD | cible PH-21.176 | cible PH-21.176 | cible PH-21.176 | digest GHCR PH-21.175 | PASS |

## Smoke passif interne

| Route | HTTP | Temps | Commentaire |
| --- | --- | --- | --- |
| API `/health` | OK | OK | pod local |
| Client `/start` | 307 | 0.015 s | hors session, redirect login attendu |
| Client `/register` | 200 | 0.018 s | HTML non vide |
| Client `/login` | 200 | 0.205 s | HTML non vide |

## Smoke passif public

| Route | HTTP | Temps | Commentaire |
| --- | --- | --- | --- |
| `https://client.keybuzz.io/start` | 307 | 0.102 s | hors session, redirect login attendu |
| `https://client.keybuzz.io/register` | 200 | 0.194 s | HTML non vide |
| `https://client.keybuzz.io/login` | 200 | 0.122 s | HTML non vide |

## Runtime markers

| Controle | Resultat | Verdict |
| --- | --- | --- |
| API `seedStarterPlaybooksAfterResponse` | 3 | PASS |
| API `await seedStarterPlaybooks(tenantId)` | 0 | PASS |
| API `/marketplaces/octopia/status` | 2 | PASS |
| Client `https://api.keybuzz.io` | 91 | PASS |
| Client `https://api-dev.keybuzz.io` | 0 | PASS |
| Client `location.assign` | 15 | PASS |
| Client timeout `2500` | 9 | PASS |
| Client `CompletePayment` browser marker | 0 | PASS |

## Logs

| Service | Fenetre | Erreurs critiques |
| --- | --- | --- |
| API PROD | 10 min | 0 |
| Client PROD | 10 min | 0 |

## No fake metrics / no fake events

- 0 formulaire lance par CE.
- 0 checkout Stripe.
- 0 POST `/funnel/event`.
- 0 fake StartTrial/Purchase/CompletePayment.
- 0 CAPI test.
- 0 DB mutation volontaire.
- 0 Webflow / Meta Ads / Linear.

## Non-regression

- No-card trial conserve.
- Billing conversion non modifiee pendant PH-21.176.
- Tracking server-side non modifie.
- `CompletePayment` browser absent.
- Client PROD compile vers API PROD, API DEV absente.
- API conserve PH-21.171 billing events tenant_id + route Octopia canonique.
- KBActions, Marketplace, Website, Admin, Backend non modifies.

## Rollback

Rollback GitOps uniquement:

| Service | Rollback |
| --- | --- |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.271-dependency-hardening-prod` |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.266-dependency-hardening-prod` |

Procedure rollback:

1. Modifier les deux manifests PROD vers les tags rollback.
2. Commit + push infra.
3. `kubectl apply -f` sur les deux manifests.
4. Rollout status.
5. Verifier runtime = manifest = last-applied = pod digest.

## Limites

Aucun nouveau compte reel n'a ete cree par CE. Le parcours utilisateur reel `/register` -> `/start` -> dashboard peut etre reteste par Ludovic pour validation UX, mais la verification technique passive est OK.

## Verdict final

GO APPLY API CLIENT FIRST-RUN START ONBOARDING LATENCY PROD GITOPS READY_CLOSED PH-SAAS-T8.12AS.21.176.

STOP.
