# PH-SAAS-T8.12AS.21.168 - First-run onboarding start and dashboard latency DEV/PROD

Date UTC: 2026-06-27

## Verdict

READY_WITH_DEBTS.

## Resume Ludovic

Le blocage observe en PROD apres inscription no-card trial ne venait pas de la creation API:

- `create-signup` PROD avait repondu 201 en environ 228 ms.
- `no-card-trial` PROD avait repondu 200 en environ 44 ms.
- Le tenant PROD etait present, entitlement trialing actif, KBActions disponibles.

La cause etait cote Client premier chargement:

- retour API no-card trial encore dirige vers `/dashboard`;
- fallback Client register encore dirige vers `/dashboard`;
- cookie `currentTenantId` pas toujours hydrate assez tot;
- `TenantProvider` sans fallback robuste sur `isCurrent` / premier tenant;
- dashboard initial bloquable par chargements secondaires.

Correctif applique:

- API no-card trial renvoie maintenant `/start`;
- Client register redirige/fallback vers `/start`;
- BFF `/api/auth/me` et `/api/tenant-context/me` hydratent `currentTenantId`;
- `TenantProvider` fallback sur `currentTenantId`, tenant `isCurrent`, puis premier tenant;
- `EntitlementGuard` respecte `tenantLoading`;
- `/start` est exempt de gate billing;
- dashboard rend le resume principal avant supervision secondaire;
- dashboard summary BFF a un timeout de 8 s.

## Commits source

| Repo | Branche | Commit | Objet |
| --- | --- | --- | --- |
| keybuzz-api | ph147.4/source-of-truth | `2345b39c529439fcbf56f5558701d6c0d4be91b4` | no-card trial nextPath `/start` |
| keybuzz-client | ph148/onboarding-activation-replay | `b3192fa26244ef1ad2eed6c1996526101430d6e1` | hydration tenant + redirect `/start` + dashboard non bloquant |

## Tests source

| Surface | Test | Resultat |
| --- | --- | --- |
| API | `git diff --check` | PASS |
| API | `npx tsc -p tsconfig.json --noEmit` | PASS |
| API | PH-21.125 no-card trial pricing | PASS 31/31 |
| API | PH-21.132A no-card trial runtime endpoint | PASS 75/75 |
| Client | `git diff --check` | PASS |
| Client | targeted ESLint | PASS |
| Client | global tsc | FAIL_PREEXISTING `.next/types/app/api/debug-env/route.ts` |

## Images DEV

| Service | Image | Digest | Source | Image ID |
| --- | --- | --- | --- | --- |
| API DEV | `ghcr.io/keybuzzio/keybuzz-api:v3.5.269-first-run-onboarding-start-dev` | `sha256:e39a32d94a45f95bb2d4ce30786d34fa323a7908e521a77bc2d9cfed6f3cb404` | `2345b39c` | `sha256:d42c3b5476ca3dcbb6107ee4a54d27fd97939be42b528f00b8235d209d16650e` |
| Client DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.264-first-run-onboarding-start-dev` | `sha256:528f77232e33015790909f7ed742af1d32d5b02af12403605c4470260f888fcd` | `b3192fa` | `sha256:22eda417d8df58df7589297857d52ee16c28b9e701440eb94c20926171368f9b` |

DEV build args Client explicites:

- `NEXT_PUBLIC_APP_ENV=development`
- `NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io`
- `NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io`
- `NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG`
- `NEXT_PUBLIC_META_PIXEL_ID=`
- `NEXT_PUBLIC_SGTM_URL=`
- `NEXT_PUBLIC_TIKTOK_PIXEL_ID=`
- `NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977`
- `NEXT_PUBLIC_CLARITY_PROJECT_ID=wuk12h9i33`

DEV audit image:

| Controle | Resultat |
| --- | --- |
| API `nextPath.*start` | 1 |
| API `nextPath.*dashboard` | 0 |
| Client API DEV marker | 88 |
| Client API PROD marker | 0 |
| Register checkout route | 0 |
| Register StartTrial/Purchase/CompletePayment/InitiateCheckout | 0 |
| Register no-card route | 2 |

DEV GitOps:

| Etape | Resultat |
| --- | --- |
| Commit manifest | `9d01e9326d543375ff5fdc2499b8123d21fa68fd` |
| Dry-run client/server | PASS |
| `kubectl apply -f` | PASS |
| Rollout API DEV | PASS |
| Rollout Client DEV | PASS |
| Runtime equality | manifest = last-applied = deployment spec = pod spec |
| Pods | API Ready 1/1 restarts 0; Client Ready 1/1 restarts 0 |
| Smoke passif | `/register` 200, `/start` 307, `/dashboard` 307 |

## Images PROD

| Service | Image | Digest | Source | Image ID |
| --- | --- | --- | --- | --- |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.269-first-run-onboarding-start-prod` | `sha256:84ea6f3e277a0be1e84eb83867ffc191990d2f81f82401c384ab96905cdbc19b` | `2345b39c` | `sha256:a8e550e64d687079a33c2121cc79f5b590669a895f50446539508c3b2c9fe0ed` |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.264-first-run-onboarding-start-prod` | `sha256:5331aeba33226dc06568d947f441d4e38e94b6db9a9c96d6715baca05b8d98dd` | `b3192fa` | `sha256:9a6fb79b30194e961e4148b98c8e8506878435b72d8adae572fa3d395fba0235` |

PROD build args Client explicites:

- `NEXT_PUBLIC_APP_ENV=production`
- `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`
- `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`
- `NEXT_PUBLIC_GA4_MEASUREMENT_ID=G-R3QQDYEBFG`
- `NEXT_PUBLIC_META_PIXEL_ID=1234164602194748`
- `NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro`
- `NEXT_PUBLIC_TIKTOK_PIXEL_ID=D7PT12JC77U44OJIPC10`
- `NEXT_PUBLIC_LINKEDIN_PARTNER_ID=9969977`
- `NEXT_PUBLIC_CLARITY_PROJECT_ID=wuk12h9i33`

PROD audit image:

| Controle | Resultat |
| --- | --- |
| API `nextPath.*start` | 1 |
