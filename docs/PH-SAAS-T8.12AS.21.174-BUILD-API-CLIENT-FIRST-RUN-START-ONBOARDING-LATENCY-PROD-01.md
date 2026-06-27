# PH-SAAS-T8.12AS.21.174 - Build API Client first-run /start onboarding latency PROD

## Verdict

READY_LOCAL_IMAGES.

Images PROD locales construites et auditees:

- API: `ghcr.io/keybuzzio/keybuzz-api:v3.5.273-start-onboarding-latency-prod`
- Client: `ghcr.io/keybuzzio/keybuzz-client:v3.5.267-start-onboarding-latency-prod`

Aucun docker push, aucun deploy, aucun `kubectl apply`, aucun formulaire, aucun checkout, aucun fake event, aucune mutation DB.

## Objectif

Construire localement les images API + Client PROD depuis les sources DEV validees en PH-21.172, apres validation promotion safety PH-21.173.

## Sources

| Repo | Branche | Commit | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- |
| `keybuzz-api` | `ph147.4/source-of-truth` | `b60f506fe677af82563e77f2a1ad27110bf74593` | 0/0 | 0 | PASS |
| `keybuzz-client` | `ph148/onboarding-activation-replay` | `48147dc572b3b4444f3b85d2277867e15a1c3e5d` | 0/0 | 0 | PASS |
| `keybuzz-infra` | `main` | `d9c126f13c92eced1714188ebc5ce954788265fa` | 0/0 | 0 | PASS |

Build-from-git effectue depuis clone propre:

- `/tmp/ph21174-build-prod-20260627T204130Z/keybuzz-api`
- `/tmp/ph21174-build-prod-20260627T204130Z/keybuzz-client`

Les clones temporaires ont ensuite ete supprimes pour eviter de remplir le disque root du bastion. Les images Docker locales restent presentes.

## Registry precheck

| Image cible | Statut distant avant build | Statut distant apres build | Verdict |
| --- | --- | --- | --- |
| `ghcr.io/keybuzzio/keybuzz-api:v3.5.273-start-onboarding-latency-prod` | ABSENT | ABSENT | PASS |
| `ghcr.io/keybuzzio/keybuzz-client:v3.5.267-start-onboarding-latency-prod` | ABSENT | ABSENT | PASS |

`latest` intact:

| Repo image | latest avant | latest apres | Verdict |
| --- | --- | --- | --- |
| API | `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` | `71d7e988869441ff2686ebbeefb13fea890c48b1ce4ae605bad537abb4c26549` | PASS |
| Client | `151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341` | `151a4fde8c1afc29b1f01d484643aa47f8e37e26a951c1b7be6c17ec81817341` | PASS |

## Incident build non produit

Le premier passage du build Client a echoue avant construction Docker sur `npm ci` avec `ENOSPC` parce que le disque root du bastion etait a 100%.

Action corrective:

- suppression limitee a des workdirs temporaires de build/test sous `/tmp`;
- nettoyage du cache npm root;
- aucune suppression dans `/opt/keybuzz/keybuzz-*`;
- aucun repo, manifest, runtime, secret ou donnees applicatives touches.

Etat disque final:

| Mount | Taille | Utilise | Libre | Usage |
| --- | --- | --- | --- | --- |
| `/` | 38G | 24G | 13G | 66% |
| `/tmp` | 38G | 24G | 13G | 66% |
| `/var/lib/docker` | 98G | 47G | 47G | 51% |

Le build complet a ensuite ete relance depuis nouveaux clones propres et termine avec succes.

## Tests pre-build API

| Test | Resultat |
| --- | --- |
| `git diff --check` | PASS |
| `npm ci` | PASS |
| `npx ts-node src/tests/ph21172-start-latency-tests.ts` | PASS |
| `npx ts-node src/tests/ph21171-billing-events-octopia-route-tests.ts` | PASS |
| `npx tsc --noEmit` | PASS |
| `npm audit --audit-level=moderate` | PASS, 0 vulnerabilities |

## Image API PROD locale

| Champ | Valeur |
| --- | --- |
| Image | `ghcr.io/keybuzzio/keybuzz-api:v3.5.273-start-onboarding-latency-prod` |
| Image ID | `sha256:7b7aefc7eb4dd7e07ebc6e3cc6bbb1edf788244f78fb60aecf76b14643f93784` |
| Source | `b60f506fe677af82563e77f2a1ad27110bf74593` |
| Label revision | `b60f506fe677af82563e77f2a1ad27110bf74593` |
| Label version | `v3.5.273-start-onboarding-latency-prod` |
| RepoDigest | absent attendu, image non poussee |

Audit image API:

| Controle | Resultat | Verdict |
| --- | --- | --- |
| `seedStarterPlaybooksAfterResponse` | 3 | PASS |
| `await seedStarterPlaybooks(tenantId)` | 0 | PASS |
| `/marketplaces/octopia/status` | 2 | PASS |
| `billing_events` | 5 | PASS |
| `dist/tests` | 0 | PASS |

## Tests pre-build Client

| Test | Resultat |
| --- | --- |
| `git diff --check` | PASS |
| `npm ci --legacy-peer-deps` | PASS |
| `npm run prebuild` | PASS |
| `node scripts/ph21172-start-latency-tests.mjs` | PASS |
| `npx tsc --noEmit --pretty false --incremental false` | PASS |
| `npm audit --legacy-peer-deps --audit-level=moderate` | PASS, 0 vulnerabilities |

## Build args Client PROD

| Build arg | Valeur | Source |
| --- | --- | --- |
| `NEXT_PUBLIC_APP_ENV` | `production` | Dockerfile guard |
| `NEXT_PUBLIC_API_URL` | `https://api.keybuzz.io` | PROD |
| `NEXT_PUBLIC_API_BASE_URL` | `https://api.keybuzz.io` | PROD |
| `NEXT_PUBLIC_GA4_MEASUREMENT_ID` | `G-R3QQDYEBFG` | manifest/docs PROD |
| `NEXT_PUBLIC_META_PIXEL_ID` | `1234164602194748` | manifest/docs PROD |
| `NEXT_PUBLIC_SGTM_URL` | `https://t.keybuzz.pro` | manifest/docs PROD |
| `NEXT_PUBLIC_TIKTOK_PIXEL_ID` | `D7PT12JC77U44OJIPC10` | manifest/docs PROD |
| `NEXT_PUBLIC_LINKEDIN_PARTNER_ID` | `9969977` | manifest/docs PROD |
| `NEXT_PUBLIC_CLARITY_PROJECT_ID` | `wuk12h9i33` | guard/docs PROD |
| `GIT_COMMIT_SHA` | `48147dc572b3b4444f3b85d2277867e15a1c3e5d` | source |
| `IMAGE_REVISION` | `48147dc572b3b4444f3b85d2277867e15a1c3e5d` | OCI |
| `IMAGE_VERSION` | `v3.5.267-start-onboarding-latency-prod` | OCI |

Dockerfile guard:

- production Clarity present: PASS
- APP_ENV=production API_URL/API_BASE_URL=`https://api.keybuzz.io`: PASS

## Image Client PROD locale

| Champ | Valeur |
| --- | --- |
| Image | `ghcr.io/keybuzzio/keybuzz-client:v3.5.267-start-onboarding-latency-prod` |
| Image ID | `sha256:542292c3e98308da7cd2538bb2f2ab08144b4b71170754b3f21664329499ae8e` |
| Source | `48147dc572b3b4444f3b85d2277867e15a1c3e5d` |
| Label revision | `48147dc572b3b4444f3b85d2277867e15a1c3e5d` |
| Label version | `v3.5.267-start-onboarding-latency-prod` |
| RepoDigest | absent attendu, image non poussee |

Audit image Client:

| Controle | Resultat | Verdict |
| --- | --- | --- |
| API PROD marker `https://api.keybuzz.io` | 91 | PASS |
| API DEV marker `https://api-dev.keybuzz.io` | 0 | PASS |
| `location.assign` | 15 | PASS |
| timeout marker `2500` | 9 | PASS |
| `/api/dashboard/summary` | 17 | PASS |
| GA4 `G-R3QQDYEBFG` | 5 | PASS |
| Meta Pixel `1234164602194748` | 2 | PASS |
| sGTM `https://t.keybuzz.pro` | 5 | PASS |
| TikTok `D7PT12JC77U44OJIPC10` | 2 | PASS |
| LinkedIn `9969977` | 2 | PASS |
| Clarity `wuk12h9i33` | 2 | PASS |
| `CompletePayment` browser marker | 0 | PASS |

## Runtime PROD inchange

| Service | Runtime observe | Ready |
| --- | --- | --- |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.271-dependency-hardening-prod` | 1/1 |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.266-dependency-hardening-prod` | 1/1 |

Generations PROD inchangees au controle final:

- API PROD: `431/431`
- Client PROD: `433/433`

## No fake metrics / no fake events

- 0 docker push.
- 0 deploy.
- 0 `kubectl apply`.
- 0 `kubectl set image/env/patch/edit`.
- 0 formulaire.
- 0 checkout Stripe.
- 0 POST `/funnel/event`.
- 0 fake StartTrial/Purchase/CompletePayment.
- 0 CAPI test.
- 0 DB mutation volontaire.
- 0 Webflow / Meta Ads / Linear.

## Non-regression

- API PH-21.171 billing events + Octopia route conservee.
- API PH-21.172 seed playbooks non bloquant present.
- Client API PROD compilee, API DEV absente.
- Client tracking public PROD compile.
- Client `/start` latency markers presents.
- No-card trial / billing / tracking semantics non modifies pendant le build.

## Rollback pour phase apply future

| Service | Rollback |
| --- | --- |
| API PROD | `ghcr.io/keybuzzio/keybuzz-api:v3.5.271-dependency-hardening-prod` |
| Client PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.266-dependency-hardening-prod` |

Rollback GitOps uniquement, jamais `kubectl set image`.

## Prochaine phase

`GO PUSH IMAGE API CLIENT FIRST-RUN START ONBOARDING LATENCY PROD PH-SAAS-T8.12AS.21.175`

## Verdict final

GO BUILD API CLIENT FIRST-RUN START ONBOARDING LATENCY PROD READY_LOCAL_IMAGES PH-SAAS-T8.12AS.21.174.

STOP.
