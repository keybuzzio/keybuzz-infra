# PH-SAAS-T8.12AS.21.87 - Build Client onboarding register_started owner payload DEV

Date UTC: 2026-06-22T13:10:18Z

Verdict: READY

Phrase finale:

`GO BUILD CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD DEV READY PH-SAAS-T8.12AS.21.87`

## Resume Ludovic

Image Client DEV locale construite depuis Git propre `d9631ca087f1` avec build args DEV explicites. Audit bundle OK: `https://api-dev.keybuzz.io` present, `https://api.keybuzz.io` absent, marqueurs `register_started`, `marketing_owner_tenant_id`, UTM et click IDs presents. Aucun docker push, deploy, DB, event, formulaire, checkout, Webflow ou Linear.

## Sources relues

- Mission PH-21.87.
- AI_MEMORY KeyBuzz: CURRENT_STATE, RULES_AND_RISKS, DOCUMENT_MAP, CE_PROMPTING_STANDARD.
- Retours PH-21.86 source/push.
- Dockerfile Client et build args Client DEV.

## Preflight bastion

| Point | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| Host | install-v3 | install-v3 | PASS |
| IP | 46.62.171.61 | 46.62.171.61 | PASS |
| Date UTC | documentee | 2026-06-22T13:10:18Z | PASS |

## Repos

| Repo | Branche | Remote | HEAD | Origin HEAD | Ahead/behind | Dirty | Verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| keybuzz-client | ph148/onboarding-activation-replay | origin/ph148/onboarding-activation-replay | d9631ca087f1 | d9631ca087f1 | 0/0 |  M tsconfig.tsbuildinfo | PASS |
| keybuzz-infra avant rapport | main | origin/main | d73f9618282e | d73f9618282e | 0/0 | 0 | PASS |

## Confirmation PH-21.86 PUSH

| Point | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| PH-21.86 source | READY_FOR_PUSH | confirme par retour PH-21.86 | PASS |
| PH-21.86 push | DONE | confirme par retour PH-21.86 PUSH | PASS |
| Client commit | d9631ca087f1 | d9631ca087f1 | PASS |
| Fichiers Client | scope attendu | app/register/page.tsx,scripts/ph2186-register-started-attribution.test.cjs,src/lib/attribution.ts, | PASS |
| No fake events | 0 | 0 | PASS |

## Source build propre

| Point | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| Build dir | /tmp/keybuzz-client-ph2187-build-* | /tmp/keybuzz-client-ph2187-build-d9631ca087f1-20260622T122554Z | PASS |
| Build HEAD | d9631ca087f1751b2def8ad06a049ad93226ffbd | d9631ca087f1751b2def8ad06a049ad93226ffbd | PASS |
| Build dirty | 0 | 0 | PASS |

## Build args DEV explicites

| Build arg | Valeur | Verdict |
| --- | --- | --- |
| NEXT_PUBLIC_APP_ENV | development | PASS |
| NEXT_PUBLIC_API_URL | https://api-dev.keybuzz.io | PASS |
| NEXT_PUBLIC_API_BASE_URL | https://api-dev.keybuzz.io | PASS |
| NEXT_PUBLIC_GA4_MEASUREMENT_ID | DEV explicite | PASS |
| NEXT_PUBLIC_META_PIXEL_ID | vide DEV explicite | PASS |
| NEXT_PUBLIC_SGTM_URL | vide DEV explicite | PASS |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | vide DEV explicite | PASS |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | DEV explicite | PASS |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | DEV explicite | PASS |
| OCI revision/version/created | explicites | PASS |

## Commande build

Commande executee dans la source Git propre, sans secret:

```bash
docker build \
  --build-arg NEXT_PUBLIC_APP_ENV=development \
  --build-arg NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_GA4_MEASUREMENT_ID=<DEV_PUBLIC_ID> \
  --build-arg NEXT_PUBLIC_META_PIXEL_ID= \
  --build-arg NEXT_PUBLIC_SGTM_URL= \
  --build-arg NEXT_PUBLIC_TIKTOK_PIXEL_ID= \
  --build-arg NEXT_PUBLIC_LINKEDIN_PARTNER_ID=<DEV_PUBLIC_ID> \
  --build-arg NEXT_PUBLIC_CLARITY_PROJECT_ID=<DEV_PUBLIC_ID> \
  --build-arg GIT_COMMIT_SHA=d9631ca087f1751b2def8ad06a049ad93226ffbd \
  --build-arg BUILD_TIME=2026-06-22T13:10:18Z \
  --build-arg IMAGE_REVISION=d9631ca087f1751b2def8ad06a049ad93226ffbd \
  --build-arg IMAGE_CREATED=2026-06-22T13:10:18Z \
  --build-arg IMAGE_VERSION=v3.5.260-onboarding-register-started-owner-payload-dev \
  -t ghcr.io/keybuzzio/keybuzz-client:v3.5.260-onboarding-register-started-owner-payload-dev .
```

## Image locale

| Image | Tag | Source HEAD | Image ID | Digest registry | Verdict |
| --- | --- | --- | --- | --- | --- |
| keybuzz-client | v3.5.260-onboarding-register-started-owner-payload-dev | d9631ca087f1 | sha256:d80c84d3b00a9e65c84d2e9665385be185392c0ba45df8a0dc98209e0259f80e | absent_or_unavailable_rc_1 | READY_LOCAL_ONLY |

Labels OCI:

| Label | Valeur |
| --- | --- |
| org.opencontainers.image.revision | d9631ca087f1751b2def8ad06a049ad93226ffbd |
| org.opencontainers.image.version | v3.5.260-onboarding-register-started-owner-payload-dev |
| org.opencontainers.image.created | 2026-06-22T12:25:54Z |

## Audit bundle/image

| Marqueur | Attendu | Resultat | Verdict |
| --- | --- | --- | --- |
| https://api-dev.keybuzz.io | present | 87 | PASS |
| https://api.keybuzz.io | absent | 0 | PASS |
| register_started | present | 1 | PASS |
| marketing_owner_tenant_id | present | 3 | PASS |
| utm_source / utm_medium / utm_campaign | present | 1/1/1 | PASS |
| fbclid / gclid / ttclid / li_fat_id | present | 1/1/1/1 | PASS |
| trial_page_viewed | absent Client | 0 | PASS |
| fbq trackCustom trial_page_viewed | absent | 0 | PASS |
| PH-21.86 test script | absent runtime | 0 | PASS |
| Complete private key candidate | absent | END=0, RSA=0, OPENSSH=0 | PASS |
| Public token candidates | absent applicatif | sk_live=0, ghp=0, xoxb=0, EAAG-app=0 | PASS |

Note audit: `-----BEGIN PRIVATE KEY-----` apparait 2 fois dans le code de parsing JOSE/Next embarque, sans `-----END PRIVATE KEY-----`, sans RSA/OpenSSH et sans valeur candidate; classe faux positif library parser, pas secret material.
Note audit: les candidats `EAAG...` bruts apparaissent 4 fois uniquement sous `/app/node_modules/next/dist/compiled/edge-runtime`; aucun candidat `EAAG...` applicatif hors `node_modules`.

## Tests pre-build

| Test | Attendu | Resultat |
| --- | --- | --- |
| git diff --check | PASS | PASS |
| node scripts/ph2186-register-started-attribution.test.cjs | PASS | PH-21.86 register_started attribution payload test OK |
| lint cible register/attribution | PASS | PASS |
| tsc cible attribution | PASS | bytes=0 |
| tsc global | non bloquant si dette preexistante | non-zero preexisting .next/types debug-env debt |

TSC global extrait redige:

```text
.next/types/app/api/debug-env/route.ts(2,24): error TS2307: Cannot find module '../../../../../app/api/debug-env/route.js' or its corresponding type declarations.
.next/types/app/api/debug-env/route.ts(5,29): error TS2307: Cannot find module '../../../../../app/api/debug-env/route.js' or its corresponding type declarations.
```

## Registry postcheck

| Surface | Resultat | Interpretation |
| --- | --- | --- |
| GHCR tag cible | absent_or_unavailable_rc_1 | Lecture seule; aucun docker push execute |

## Runtime read-only

| Service | Namespace | Image | Ready | Restarts | Verdict |
| --- | --- | --- | --- | --- | --- |
| keybuzz-client | keybuzz-client-dev | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-dev | 1/1 | keybuzz-client-5757fcd8fc-lt5bm:0 | INCHANGE |
| keybuzz-client | keybuzz-client-prod | ghcr.io/keybuzzio/keybuzz-client:v3.5.259-ai-assist-notification-scope-prod | 1/1 | keybuzz-client-778b4879bf-dtrpj:0 | INCHANGE |

## No fake metrics / no fake events

| Surface | Attendu | Resultat |
| --- | --- | --- |
| Docker push | 0 | 0 |
| Deploy / kubectl apply | 0 | 0 |
| DB mutation | 0 | 0 |
| POST /funnel/event | 0 | 0 |
| Event reel/fake | 0 | 0 |
| Formulaire /register | 0 | 0 |
| Checkout Stripe | 0 | 0 |
| Webflow / Linear | 0 | 0 |

## Build log tail

```text
 ---> Removed intermediate container 6f8a627b209d
 ---> 0907ee07effc
Step 59/62 : EXPOSE 3000
 ---> Running in 759722a2021e
 ---> Removed intermediate container 759722a2021e
 ---> 27f8041824dc
Step 60/62 : ENV PORT=3000
 ---> Running in b9d2ee1990d0
 ---> Removed intermediate container b9d2ee1990d0
 ---> a6b5de521fdd
Step 61/62 : ENV HOSTNAME=0.0.0.0
 ---> Running in ea552d7c9a95
 ---> Removed intermediate container ea552d7c9a95
 ---> 2a856952c851
Step 62/62 : CMD node server.js
 ---> Running in d70512412dc7
 ---> Removed intermediate container d70512412dc7
 ---> d80c84d3b00a
Successfully built d80c84d3b00a
Successfully tagged ghcr.io/keybuzzio/keybuzz-client:v3.5.[REDACTED_LONG_VALUE]
```

## Dettes / limites

- Image locale uniquement, non poussee.
- Aucun trafic naturel ou Ads Manager prouve dans cette phase.
- TSC global conserve une dette preexistante si rc non-zero, sans impact sur le tsc cible ni le build Docker reussi.
- Le tag GHCR peut etre absent ou exister hors phase; PH-21.87 n'a execute aucun docker push.

## Prochain GO

`GO PUSH IMAGE CLIENT ONBOARDING REGISTER_STARTED OWNER PAYLOAD DEV PH-SAAS-T8.12AS.21.88`
