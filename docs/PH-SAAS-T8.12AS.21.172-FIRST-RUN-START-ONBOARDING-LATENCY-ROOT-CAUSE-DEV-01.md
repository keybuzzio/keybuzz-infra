# PH-SAAS-T8.12AS.21.172 - First-run /start onboarding latency root cause DEV

## Verdict

READY_DEV_APPLIED.

DEV a ete corrige et deploye via GitOps strict pour reduire la latence percue sur le premier passage `/register` -> `/start`.

PROD n'a pas ete modifiee. La promotion PROD doit rester une phase separee avec GO explicite.

## Objectif

Identifier et corriger la cause racine de la lenteur observee sur `/start` et l'enregistrement initial, sans casser le no-card trial, la facturation, le tracking, les KBActions, les routes onboarding ni les builds Client/API.

## Cause racine

1. `TenantProvider` pouvait etre monte avant la creation du tenant. Si `/tenant-context/me` retournait une erreur pour un utilisateur encore non rattache, le provider restait dans un etat stale.
2. Apres creation trial, `register/page.tsx` utilisait une navigation SPA vers `/start`. Le provider pouvait donc rester monte avec l'ancien contexte et `/start` attendait un tenant absent.
3. `useOnboardingState()` gardait `isLoading=true` quand `tenantId` etait vide, ce qui pouvait produire une attente longue ou infinie cote UX.
4. `/start` attendait plusieurs checks secondaires avant de rendre l'ecran. Les checks marketplace/dashboard n'etaient pas tous bornes et pouvaient ralentir le premier rendu.
5. Cote API, `seedStarterPlaybooks(tenantId)` etait attendu dans la reponse de creation tenant. La graine playbooks est utile mais ne doit pas bloquer la reponse d'enregistrement.

Conclusion: la lenteur n'etait pas principalement due aux endpoints API recents, mais a une combinaison de contexte tenant stale, loading non termine, checks secondaires bloquants, et seed playbooks encore dans le chemin critique.

## Patch source

### Client

Repo: `/opt/keybuzz/keybuzz-client`

Branche: `ph148/onboarding-activation-replay`

Commit source pousse: `48147dc572b3b4444f3b85d2277867e15a1c3e5d`

Fichiers:

| Fichier | Changement | Risque |
| --- | --- | --- |
| `app/register/page.tsx` | Navigation post-trial par `window.location.assign(nextPath)` pour forcer un remount propre du contexte tenant | Faible, limite au post-signup |
| `src/features/onboarding/hooks/useOnboardingState.ts` | Fin de loading si tenant absent + timeouts 2500 ms sur checks secondaires | Faible, ameliore fallback UI |
| `src/features/onboarding/components/OnboardingHub.tsx` | Refresh tenant one-shot et etat de preparation si tenant pas encore disponible | Faible, garde onboarding intact |
| `scripts/ph21172-start-latency-tests.mjs` | Test source anti-regression | Aucun runtime |

### API

Repo: `/opt/keybuzz/keybuzz-api`

Branche: `ph147.4/source-of-truth`

Commit source pousse: `b60f506fe677af82563e77f2a1ad27110bf74593`

Fichiers:

| Fichier | Changement | Risque |
| --- | --- | --- |
| `src/modules/auth/tenant-context-routes.ts` | `seedStarterPlaybooks` planifie apres reponse via `setImmediate`, avec log safe en cas d'echec | Faible, retire un travail non critique du chemin signup |
| `src/tests/ph21172-start-latency-tests.ts` | Test source anti-regression | Aucun runtime |

## Tests source

| Repo | Test | Resultat |
| --- | --- | --- |
| Client | `node scripts/ph21172-start-latency-tests.mjs` | PASS |
| Client | `git diff --check` | PASS |
| Client | `npx tsc --noEmit --pretty false --incremental false` | PASS |
| Client | `npm audit --legacy-peer-deps --audit-level=moderate` | PASS, 0 vulnerabilities |
| API | `npx ts-node src/tests/ph21172-start-latency-tests.ts` | PASS |
| API | `npx ts-node src/tests/ph21171-billing-events-octopia-route-tests.ts` | PASS |
| API | `git diff --check` | PASS |
| API | `npx tsc --noEmit` | PASS |
| API | `npm audit --audit-level=moderate` | PASS, 0 vulnerabilities |

## Build DEV

Build-from-git uniquement, depuis clones propres.

| Service | Image | Image ID | Digest GHCR | Source |
| --- | --- | --- | --- | --- |
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.273-start-onboarding-latency-dev` | `sha256:88aaa7564915025358b595d15fe532150c11b5013830c59bc8d4e41eaa75541c` | `sha256:64ec8fcdb1dc73d01cc478d539a89536f3dc287d28db11267e50f2ac2fcf3de7` | `b60f506fe677af82563e77f2a1ad27110bf74593` |
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.267-start-onboarding-latency-dev` | `sha256:fbc3c50a13c95d440b7d50101ef579477bcb737ac6694ff9d32387525e67a805` | `sha256:1c228dd4d044c503e0a863941e431354513188ad34d12820aa739155dd115f09` | `48147dc572b3b4444f3b85d2277867e15a1c3e5d` |

Client DEV build args verifies: `https://api-dev.keybuzz.io` present, `https://api.keybuzz.io` absent.

`latest` intact pour API et Client.

## GitOps DEV

Repo: `/opt/keybuzz/keybuzz-infra`

Manifest commit pousse: `61c2c0391b8be43286a59450a36810ee6ec550c6`

Fichiers modifies:

| Fichier | Changement |
| --- | --- |
| `k8s/keybuzz-api-dev/deployment.yaml` | Image API DEV `v3.5.272` -> `v3.5.273-start-onboarding-latency-dev` |
| `k8s/keybuzz-client-dev/deployment.yaml` | Image Client DEV `v3.5.266` -> `v3.5.267-start-onboarding-latency-dev` |

Dry-runs:

| Manifest | Dry-run client | Dry-run server |
| --- | --- | --- |
| API DEV | PASS | PASS |
| Client DEV | PASS | PASS |

Apply:

`kubectl apply -f` uniquement sur les deux manifests DEV, puis rollout status.

## Runtime DEV final

| Service | Image runtime | Digest runtime | Ready | Restarts |
| --- | --- | --- | --- | --- |
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.273-start-onboarding-latency-dev` | `sha256:64ec8fcdb1dc73d01cc478d539a89536f3dc287d28db11267e50f2ac2fcf3de7` | 1/1 | 0 |
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.267-start-onboarding-latency-dev` | `sha256:1c228dd4d044c503e0a863941e431354513188ad34d12820aa739155dd115f09` | 1/1 | 0 |

Generation runtime:

| Service | Generation | Observed |
| --- | --- | --- |
| API DEV | 512 | 512 |
| Client DEV | 1031 | 1031 |

Runtime markers:

| Check | Resultat |
| --- | --- |
| API `seedStarterPlaybooksAfterResponse` | 3 |
| API `await seedStarterPlaybooks(tenantId)` | 0 |
| Client `location.assign` | 15 |
| Client timeout `2500` | 9 |
| Client API DEV marker | 91 |
| Client API PROD marker | 0 |

Smoke passif interne:

| Route | HTTP | Temps |
| --- | --- | --- |
| `/register` | 200 | 0.078 s |
| `/login` | 200 | 0.084 s |
| `/start` hors session | 307 attendu | 0.016 s |
| API `/health` | OK | OK |

Logs recents:

| Service | Erreurs critiques recentes |
| --- | --- |
| API DEV | 0 |
| Client DEV | 0 |

## No fake metrics / no fake events

- 0 formulaire lance par CE.
- 0 checkout Stripe.
- 0 POST `/funnel/event` volontaire.
- 0 fake StartTrial / Purchase / CompletePayment.
- 0 DB mutation volontaire hors rollout applicatif.
- 0 Webflow / Meta Ads / Linear.
- 0 secret lu ou affiche volontairement.

## Non-regression

- No-card trial conserve.
- Billing conversion non modifie.
- StartTrial/Purchase/CompletePayment non redefinis.
- KBActions non modifie.
- Tracking server-side non modifie.
- Website/Admin/Backend/PROD inchanges.

## PROD promotion memory

Ne pas promouvoir directement sans phase dediee.

Plan recommande:

1. `GO READONLY DESIGN FIRST-RUN START ONBOARDING LATENCY PROD PROMOTION SAFETY PH-SAAS-T8.12AS.21.173`
2. Build API PROD depuis `b60f506fe677af82563e77f2a1ad27110bf74593`
3. Build Client PROD depuis `48147dc572b3b4444f3b85d2277867e15a1c3e5d` avec build args PROD explicites.
4. Audit bundle Client PROD: `https://api.keybuzz.io` present, `https://api-dev.keybuzz.io` absent.
5. Push images tags PROD immuables.
6. GitOps PROD strict avec commit/push avant apply.
7. Verify runtime PROD = manifest = last-applied = pod spec = digest GHCR.
8. Parcours reel Ludovic/QA sur `/register` -> `/start` -> dashboard.

Rollback DEV:

| Service | Rollback tag |
| --- | --- |
| API DEV | `v3.5.272-billing-events-octopia-route-dev` |
| Client DEV | `v3.5.266-dependency-hardening-dev` |

## Limites

La verification CE est passive et ne cree pas de nouvel utilisateur. Le test utilisateur reel DEV reste a faire par Ludovic avec le lien de test non-media-buyer si une validation UX complete est souhaitee.

## Verdict final

GO SOURCE/BUILD/PUSH/APPLY FIRST-RUN START ONBOARDING LATENCY ROOT CAUSE DEV READY_DEV_APPLIED PH-SAAS-T8.12AS.21.172.
