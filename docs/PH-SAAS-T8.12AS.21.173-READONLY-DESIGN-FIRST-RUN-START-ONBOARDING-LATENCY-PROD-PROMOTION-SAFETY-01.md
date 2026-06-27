# PH-SAAS-T8.12AS.21.173 - Readonly design first-run /start onboarding latency PROD promotion safety

## Verdict

READY_FOR_BUILD_PROD.

La correction DEV PH-21.172 est validee par Ludovic et techniquement promouvable en PROD sous phases separees build -> push image -> GitOps apply -> verify -> close.

Aucun build, push image, deploy, apply, patch runtime, formulaire, checkout, fake event ou mutation DB n'a ete effectue pendant PH-21.173.

## Objectif

Verifier en lecture seule que la correction de latence premier parcours `/register` -> `/start` appliquee en DEV peut etre promue en PROD sans casser le reste.

## Sources relues

- `AI_MEMORY/CURRENT_STATE.md`
- `AI_MEMORY/RULES_AND_RISKS.md`
- `AI_MEMORY/DOCUMENT_MAP.md`
- `AI_MEMORY/CE_PROMPTING_STANDARD.md`
- `PH-21.172_CE_RETURN.md`
- Rapport DEV PH-21.172: `/opt/keybuzz/keybuzz-infra/docs/PH-SAAS-T8.12AS.21.172-FIRST-RUN-START-ONBOARDING-LATENCY-ROOT-CAUSE-DEV-01.md`

## Decision produit / technique

Promouvoir les deux briques ensemble en PROD:

1. API: retirer `seedStarterPlaybooks` du chemin critique de creation tenant.
2. Client: forcer un remount apres signup, terminer le loading si tenant absent, borner les checks secondaires de `/start`.

Promouvoir seulement l'API ou seulement le Client laisserait une cause racine partielle en PROD.

## Etat source

| Repo | Branche | HEAD | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- |
| `keybuzz-api` | `ph147.4/source-of-truth` | `b60f506fe677af82563e77f2a1ad27110bf74593` | 0/0 | 0 | OK |
| `keybuzz-client` | `ph148/onboarding-activation-replay` | `48147dc572b3b4444f3b85d2277867e15a1c3e5d` | 0/0 | 0 | OK |
| `keybuzz-infra` | `main` | `53fa61bea32190eb1c90f1f47927f05b599b172c` | 0/0 | 0 | OK |

Ascendance:

| Service | Source PROD actuelle | Source cible | Resultat |
| --- | --- | --- | --- |
| API | `80694ce082fff80357d6e30fb2f2d8abc65cb833` | `b60f506fe677af82563e77f2a1ad27110bf74593` | Descendant direct OK |
| Client | `5a9d298f0c3cd6c3ba27f0ce3d78570fd91328f3` | `48147dc572b3b4444f3b85d2277867e15a1c3e5d` | Descendant direct OK |

## Etat DEV valide

| Service | Image DEV validee | Digest | Ready | Restarts |
| --- | --- | --- | --- | --- |
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.273-start-onboarding-latency-dev` | `sha256:64ec8fcdb1dc73d01cc478d539a89536f3dc287d28db11267e50f2ac2fcf3de7` | 1/1 | 0 |
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.267-start-onboarding-latency-dev` | `sha256:1c228dd4d044c503e0a863941e431354513188ad34d12820aa739155dd115f09` | 1/1 | 0 |

Validation Ludovic: DEV nettement plus rapide, OK pour passage PROD.

## Etat PROD actuel

| Service | Image PROD actuelle | Digest runtime | Ready | Restarts |
| --- | --- | --- | --- | --- |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.271-dependency-hardening-prod` | `sha256:2e54cfa32d91fe19bc10514157fe270b55ea10220226c1c5f0a2559c093158ca` | 1/1 | 0 |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.266-dependency-hardening-prod` | `sha256:93509dab8b9c18fd0c2d13ed6a159aa853a91df14f83d8374bb060bd5f240190` | 1/1 | 0 |

GitOps:

| Service | Manifest | Last-applied | Runtime | Verdict |
| --- | --- | --- | --- | --- |
| API PROD | `v3.5.271-dependency-hardening-prod` | `v3.5.271-dependency-hardening-prod` | `v3.5.271-dependency-hardening-prod` | OK |
| Client PROD | `v3.5.266-dependency-hardening-prod` | `v3.5.266-dependency-hardening-prod` | `v3.5.266-dependency-hardening-prod` | OK |

Logs recents PROD:

| Service | Erreurs critiques recentes |
| --- | --- |
| API PROD | 0 |
| Client PROD | 0 |

Smoke passif PROD:

| Route | Voie | HTTP | Temps |
| --- | --- | --- | --- |
| `/register` | publique `https://client.keybuzz.io/register` | 200 | 0.207 s |
| `/start` | publique `https://client.keybuzz.io/start` | 307 attendu hors session | 0.111 s |
| `/register` | service interne port 80 | 200 | 0.016 s |
| `/login` | service interne port 80 | 200 | 0.018 s |
| `/start` | service interne port 80 | 307 attendu hors session | 0.019 s |
| API `/health` | pod local | OK | OK |

Note: une sonde initiale vers `keybuzz-client-prod:3000` a timeoute. Ce n'est pas une dette produit: en PROD, le service K8s expose le port service `80`. Les sondes correctes sur port service `80` passent.

## Tags PROD cibles

| Service | Tag PROD cible | Statut registry | Source |
| --- | --- | --- | --- |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.273-start-onboarding-latency-prod` | ABSENT | `b60f506fe677af82563e77f2a1ad27110bf74593` |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.267-start-onboarding-latency-prod` | ABSENT | `48147dc572b3b4444f3b85d2277867e15a1c3e5d` |

Les tags sont libres. Ils peuvent etre construits sans ecraser une image existante.

## Build requirements PROD

### API PROD

Build-from-git uniquement depuis:

- Repo: `/opt/keybuzz/keybuzz-api`
- Branche: `ph147.4/source-of-truth`
- Commit: `b60f506fe677af82563e77f2a1ad27110bf74593`
- Tag: `ghcr.io/keybuzzio/keybuzz-api:v3.5.273-start-onboarding-latency-prod`

Pre-build tests minimum:

- `npx ts-node src/tests/ph21172-start-latency-tests.ts`
- `npx ts-node src/tests/ph21171-billing-events-octopia-route-tests.ts`
- `npx tsc --noEmit`
- `npm audit --audit-level=moderate`
- `git diff --check`

Image audit minimum:

- `seedStarterPlaybooksAfterResponse` present.
- `await seedStarterPlaybooks(tenantId)` absent.
- `StartTrial`, `Purchase`, billing, Octopia route markers toujours presents.
- `dist/tests` absent.

### Client PROD

Build-from-git uniquement depuis:

- Repo: `/opt/keybuzz/keybuzz-client`
- Branche: `ph148/onboarding-activation-replay`
- Commit: `48147dc572b3b4444f3b85d2277867e15a1c3e5d`
- Tag: `ghcr.io/keybuzzio/keybuzz-client:v3.5.267-start-onboarding-latency-prod`

Build args PROD obligatoires:

- `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`
- `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`
- variables PROD actuelles preservees pour auth/tracking selon baseline Client PROD.

Pre-build tests minimum:

- `node scripts/ph21172-start-latency-tests.mjs`
- `git diff --check`
- `npm run prebuild` si requis par le repo
- `npx tsc --noEmit --pretty false --incremental false`
- `npm audit --legacy-peer-deps --audit-level=moderate`

Image audit minimum:

- `window.location.assign` present.
- timeout `/start` `2500` present.
- `https://api.keybuzz.io` present.
- `https://api-dev.keybuzz.io` absent.
- fake tracking triggers absents.

## GitOps PROD requirements

Phases recommandees:

1. `GO BUILD API CLIENT FIRST-RUN START ONBOARDING LATENCY PROD PH-SAAS-T8.12AS.21.174`
2. `GO PUSH IMAGE API CLIENT FIRST-RUN START ONBOARDING LATENCY PROD PH-SAAS-T8.12AS.21.175`
3. `GO APPLY API CLIENT FIRST-RUN START ONBOARDING LATENCY PROD GITOPS PH-SAAS-T8.12AS.21.176`
4. `GO READONLY VERIFY FIRST-RUN START ONBOARDING LATENCY PROD PH-SAAS-T8.12AS.21.177`
5. `GO READONLY CLOSE FIRST-RUN START ONBOARDING LATENCY PROD PH-SAAS-T8.12AS.21.178`

GitOps apply doit modifier uniquement:

- `k8s/keybuzz-api-prod/deployment.yaml`
- `k8s/keybuzz-client-prod/deployment.yaml`

Avec commit/push avant apply, puis:

- `kubectl apply -f k8s/keybuzz-api-prod/deployment.yaml`
- `kubectl apply -f k8s/keybuzz-client-prod/deployment.yaml`
- rollout status API PROD
- rollout status Client PROD
- verifier runtime = manifest = last-applied = pod imageID = digest GHCR.

Interdits:

- `kubectl set image`
- `kubectl set env`
- `kubectl patch`
- `kubectl edit`
- tag `latest`
- build depuis pod/runtime/dist/SCP
- build repo dirty
- push image avant audit bundle

## Rollback

Rollback GitOps uniquement.

| Service | Rollback image |
| --- | --- |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.271-dependency-hardening-prod` |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.266-dependency-hardening-prod` |

Rollback procedure:

1. Modifier les deux manifests PROD vers les tags ci-dessus.
2. Commit + push infra.
3. `kubectl apply -f` sur les manifests PROD.
4. Rollout status.
5. Verifier runtime = manifest = last-applied = pod imageID.

## No fake metrics / no fake events

- Aucun POST `/funnel/event`.
- Aucun formulaire.
- Aucun checkout Stripe.
- Aucun fake StartTrial/Purchase/CompletePayment.
- Aucun CAPI test.
- Aucune mutation DB volontaire.
- Aucun Webflow, Meta Ads, Linear.

## Non-regression gates PROD

Apres apply PROD:

| Surface | Verification |
| --- | --- |
| Register | page publique 200, no-card trial intact |
| Start | redirection hors session rapide, parcours session reel Ludovic rapide |
| Dashboard | premiere arrivee sans loading long, fallback correct si donnees secondaires lentes |
| Billing | conversion forfait/Stripe intacte |
| KBActions | trial cap et entitlements intacts |
| Tracking | aucun fake event, StartTrial/Purchase semantics intactes |
| Marketplace | Amazon/Octopia/Shopify routes intactes |
| Client bundle | API PROD presente, API DEV absente |
| API | seed playbooks async, billing events PH-21.171 conserves |

## Limites

Cette phase ne prouve pas le parcours utilisateur PROD apres correction, car aucune image PROD n'a encore ete construite ni appliquee. Elle prouve que la promotion est prete et encadree.

## Verdict final

GO READONLY DESIGN FIRST-RUN START ONBOARDING LATENCY PROD PROMOTION SAFETY READY_FOR_BUILD_PROD PH-SAAS-T8.12AS.21.173.

STOP.
