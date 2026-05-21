# PH-SAAS-T8.12AS.20.6-REGISTER-ACCENTS-0EUR-BILLING-UX-BUILD-DEV-01

> Date : 2026-05-21
> Linear : KEY-342 (accents FR primary) ; KEY-345 (0 EUR every step + benefits primary) ; KEY-343 (UX billing error related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6 REGISTER POLISH BUILD DEV
> Environnement : DEV build only (aucun docker push, aucun deploy)

## VERDICT

GO BUILD CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6

- Image Docker locale `ghcr.io/keybuzzio/keybuzz-client:v3.5.207-register-polish-dev` build OK depuis worktree --detach commit `3f88217`.
- Image ID local : `sha256:2817c455a9646d69b2be6059592419f88aa995c6fd42fee478802ee3a8ff541f` size 280 MB.
- OCI labels KEY-308 : 5/5 OK (revision/created/version/source/title).
- Build args DEV explicites tous fournis (NEXT_PUBLIC_APP_ENV=development, API DEV, Clarity, SGTM, LinkedIn).
- KEY-263 isolation DEV STRICT respectee : api-dev.keybuzz.io=87, api.keybuzz.io seul=0.
- KEY-302 Clarity preservee : wuk12h9i33=2, clarity.ms/tag=2.
- Register polish markers presents : register-trial-value-banner=2, Cockpit SAV marketplace=2, "Votre espace a bien ete cree"=2.
- PH-19.x preserves : data-clarity-mask=2 (chunks), kb_signup_form_draft_v1=1, kb_signup_cgu_accepted=1, plan_selected=3.
- 0 fake event delta vs baseline v3.5.206 (Lead/SubmitForm/InitiateCheckout preexistants identiques).
- GHCR tag cible LIBRE (manifest unknown). Aucun docker push effectue.
- Runtime Client DEV `v3.5.206-clarity-register-dev` INCHANGE.
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Worktree nettoyee post-build.
- STOP avant docker push GHCR.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-21 19:03 |
| keybuzz-client branche/HEAD | ph148/onboarding-activation-replay / 3f88217 |
| keybuzz-client dirty | 1 (tsconfig.tsbuildinfo preexistant, hors scope) |
| keybuzz-infra branche/HEAD | main / 648095c (post PH-20.6 source rapport) |
| Runtime Client DEV avant | v3.5.206-clarity-register-dev |
| Runtime Client PROD avant | v3.5.200-clarity-register-prod |

## E1 SOURCE COMMIT 3f88217 ASSERTIONS

| Assertion | Attendu | Observe | Verdict |
|---|---|---|---|
| Commit title | fix(register): polish french copy trial banner and billing error | OK | OK |
| Files changed | app/register/page.tsx (+39 -19) | OK | OK |
| TrialValueBanner present (source) | l.705 data-testid | OK | OK |
| data-clarity-mask source | 13 | 13 | OK preserve |
| kb_signup_form_draft_v1 source | 2 | 2 | OK |
| kb_signup_cgu_accepted source | 2 | 2 | OK |
| plan_selected source | 2 | 2 | OK |
| 0 EUR pendant 14 jours source | 4 | 4 | OK delta attendu (+1) |
| SaaSAnalytics.tsx diff | 0 | 0 | OK Clarity route-gated INCHANGE |

## E2 GHCR COLLISION TAG DEV

| Tag | docker manifest inspect | Verdict |
|---|---|---|
| v3.5.207-register-polish-dev | manifest unknown | LIBRE OK |

## E3 BUILD ARGS DEV (audit Dockerfile + baseline)

Dockerfile ARG declarees (l.16-26) :
- NEXT_PUBLIC_APP_ENV : obligatoire (`__MUST_BE_SET_BY_BUILD_ARG__`)
- NEXT_PUBLIC_API_URL : obligatoire
- NEXT_PUBLIC_API_BASE_URL : obligatoire
- NEXT_PUBLIC_GA4_MEASUREMENT_ID : default vide
- NEXT_PUBLIC_META_PIXEL_ID : default vide
- NEXT_PUBLIC_SGTM_URL : default vide
- NEXT_PUBLIC_TIKTOK_PIXEL_ID : default vide
- NEXT_PUBLIC_LINKEDIN_PARTNER_ID : default `9969977`
- NEXT_PUBLIC_CLARITY_PROJECT_ID : default vide
- GIT_COMMIT_SHA : default `unknown`
- BUILD_TIME : default `unknown`

Baseline v3.5.206-clarity-register-dev bundle counts utilises pour reproduire :
- api-dev.keybuzz.io : 87
- api.keybuzz.io seul : 0
- Clarity wuk12h9i33 : 2
- clarity.ms/tag : 2
- LinkedIn 9969977 : 2
- SGTM t.keybuzz.pro : 2
- GA4 / Meta / TikTok : 0 (vides en DEV)

| Build arg | Valeur fournie PH-20.6 | Justification |
|---|---|---|
| NEXT_PUBLIC_APP_ENV | development | obligatoire Dockerfile, valeur DEV conventionnelle |
| NEXT_PUBLIC_API_URL | https://api-dev.keybuzz.io | KEY-263 isolation DEV stricte |
| NEXT_PUBLIC_API_BASE_URL | https://api-dev.keybuzz.io | idem |
| NEXT_PUBLIC_SGTM_URL | https://t.keybuzz.pro | baseline preserve |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 | baseline preserve (default Dockerfile aussi) |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | wuk12h9i33 | KEY-302 Clarity preserve |
| GIT_COMMIT_SHA | 3f88217... | OCI revision |
| BUILD_TIME | 2026-05-21T19:05:19Z | OCI created |
| NEXT_PUBLIC_GA4_MEASUREMENT_ID | (vide, default) | DEV pas de tracking |
| NEXT_PUBLIC_META_PIXEL_ID | (vide, default) | idem |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | (vide, default) | idem |

## E4 WORKTREE BUILD-FROM-GIT

| Indicateur | Valeur |
|---|---|
| Worktree path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.6/keybuzz-client |
| Fetch origin ph148/onboarding-activation-replay | OK |
| Worktree detache sur | 3f88217 |
| Worktree dirty | 0 |
| TrialValueBanner present worktree | l.705 OK |

## E5 DOCKER BUILD DEV

| Item | Valeur |
|---|---|
| Dockerfile | keybuzz-client/Dockerfile (multi-stage Next.js standalone) |
| Build args explicites | 9 (cf E3) |
| Exit code | 0 |
| Build duration | ~3 min |
| Image tag local | ghcr.io/keybuzzio/keybuzz-client:v3.5.207-register-polish-dev |
| Image ID | sha256:2817c455a9646d69b2be6059592419f88aa995c6fd42fee478802ee3a8ff541f |
| Image size | 280 MB |
| Created | 2026-05-21T19:08:16Z |

## E6 OCI LABELS KEY-308 (5/5)

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.revision | 3f882173b8e491a835cd58849665b483e9408041 | OK (commit PH-20.6 source) |
| org.opencontainers.image.created | 2026-05-21T19:05:19Z | OK |
| org.opencontainers.image.version | v3.5.207-register-polish-dev | OK |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-client | OK |
| org.opencontainers.image.title | keybuzz-client | OK |

KEY-309 tag immutable + suffixe `-dev` conforme.

## E7+E8 BUNDLE AUDIT + BASELINE COMPARISON

### KEY-263 isolation DEV strict

| Indicateur | v3.5.206 baseline | v3.5.207 PH-20.6 | Delta | Verdict |
|---|---|---|---|---|
| api-dev.keybuzz.io | 87 | 87 | 0 | **OK isolation DEV preservee** |
| api.keybuzz.io seul (PROD URL) | 0 | 0 | 0 | **OK pas de leak PROD** |

### KEY-302 Clarity + Marketing IDs

| Indicateur | v3.5.206 | v3.5.207 | Delta | Verdict |
|---|---|---|---|---|
| Clarity wuk12h9i33 | 2 | 2 | 0 | OK Clarity preserve |
| clarity.ms/tag | 2 | 2 | 0 | OK |
| LinkedIn 9969977 | 2 | 2 | 0 | OK |
| SGTM t.keybuzz.pro | 2 | 2 | 0 | OK |

### Register polish markers PH-20.6

| Indicateur | v3.5.206 | v3.5.207 | Delta | Verdict |
|---|---|---|---|---|
| register-trial-value-banner | 0 | **2** | **+2** | OK nouveau marker KEY-345 |
| 0 EUR pendant 14 jours | 2 | 2 | 0 | OK (bundle minifie deduplicate ; source = 4 -> bundle = 2) |
| Cockpit SAV marketplace | 0 | **2** | **+2** | OK nouveau benefit recap |
| Votre espace a bien ete cree | 0 | **2** | **+2** | OK nouveau message UX billing |

### PH-19.x preserves

| Indicateur | v3.5.206 | v3.5.207 | Delta | Verdict |
|---|---|---|---|---|
| data-clarity-mask | 2 | 2 | 0 | OK preserve (chunks compresses) |
| kb_signup_form_draft_v1 | 1 | 1 | 0 | OK |
| kb_signup_cgu_accepted | 1 | 1 | 0 | OK |
| plan_selected | 3 | 3 | 0 | OK |

### No fake events delta

| Pattern | v3.5.206 | v3.5.207 | Delta | Verdict |
|---|---|---|---|---|
| "Lead" | 2 | 2 | 0 | OK preexistant (probable "Lead Magnet" ou label UI, pas fake event ajoute) |
| "Purchase" | 0 | 0 | 0 | OK |
| "StartTrial" | 0 | 0 | 0 | OK |
| "CompletePayment" | 0 | 0 | 0 | OK |
| "SubmitForm" | 2 | 2 | 0 | OK preexistant |
| "InitiateCheckout" | 2 | 2 | 0 | OK preexistant |
| AW- direct | 0 | 0 | 0 | OK |

Aucun fake event ajoute par PH-20.6. Tous les patterns preexistaient dans v3.5.206.

## E9 RUNTIME PRESERVE

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-website | -dev/-prod | v0.6.19-cta-tracking-* | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

Aucun deploy. Aucun kubectl apply. Aucun docker push.

## E10 WORKTREE CLEANUP

| Action | Resultat |
|---|---|
| `git worktree remove --force` | OK |
| `rm -rf /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.6/` | OK |
| Worktree present apres cleanup ? | NON |

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR (tag DEV cible reste LIBRE).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source au-dela du commit 3f88217 (PH-20.6 source).
- AUCUN secret / token affiche.
- AUCUN `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/` ouvert.
- AUCUNE mutation DB.
- AUCUN appel Stripe.
- AUCUN faux register DEV/PROD.
- AUCUNE modification API/Website/Admin.
- AUCUN cleanup tenant orphan.
- AUCUN ticket Linear modifie statut automatiquement.
- SaaSAnalytics.tsx Clarity route-gated INCHANGE.
- data-clarity-mask preserves (2 dans bundle = chunks).
- Bastion install-v3 (46.62.171.61) uniquement.

## NO FAKE METRICS / NO FAKE EVENTS

- Build container Docker uniquement.
- 0 nouveau fake event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- (tous preexistants identiques baseline).
- Aucun pixel Meta/TikTok/LinkedIn/Google Ads ajoute (LinkedIn 9969977 preserve baseline).
- Aucun checkout Stripe test reel.
- Aucune mutation DB.
- Clarity Project ID `wuk12h9i33` preserve.

## ROLLBACK PLAN (anticipation phase PUSH IMAGE DEV)

Si push image + apply DEV provoquent regression :

1. Rollback tag DEV runtime actuel : `v3.5.206-clarity-register-dev`.
2. Rollback procedure : editer `k8s/keybuzz-client-dev/deployment.yaml` -> revenir image v3.5.206-clarity-register-dev + commit + push + apply.

INTERDIT : kubectl set image / git reset --hard / git clean.

## GAPS

1. Aucun. Build clean, image valide, OCI labels conformes, isolation DEV stricte, register polish markers presents, PH-19.x preserves, 0 fake event delta.
2. Note bundle minifie : source `0 EUR pendant 14 jours` count = 4 (3 anciens + 1 TrialValueBanner), bundle = 2 (probable dedup chunks JSX compiles). Le TrialValueBanner est neanmoins present (register-trial-value-banner = 2).
3. Note Clarity bundle counts (2) inferieur a source counts (13 data-clarity-mask) : artefacts de minification Next.js qui regroupe les chunks. Le comportement Clarity reste operationnel (route-gated via SaaSAnalytics.tsx INCHANGE).
4. QA navigateur Ludovic differee a phase APPLY DEV (port-forward Client DEV preview).

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6 |
| Bastion | install-v3 46.62.171.61 |
| Source commit Client | 3f88217 |
| Tag image cible | v3.5.207-register-polish-dev |
| Image ID local | sha256:2817c455a9646d69b2be6059592419f88aa995c6fd42fee478802ee3a8ff541f |
| Image size | 280 MB |
| OCI labels KEY-308 | 5/5 OK |
| KEY-263 isolation DEV | OK (api-dev=87, api-prod=0) |
| KEY-302 Clarity preservee | OK (wuk12h9i33=2) |
| Register polish markers | OK (trial-banner=2, Cockpit SAV=2, "Votre espace a bien"=2) |
| PH-19.x preserves | OK (drafts, cgu, plan_selected, masks) |
| Fake events delta | 0 (preexistants identiques) |
| GHCR collision tag DEV cible | LIBRE (manifest unknown) |
| Worktree | nettoyee |
| Runtime Client DEV+PROD | INCHANGES |
| Runtime API+Website+Admin | INCHANGES |
| Mutations | AUCUNE |
| Docker push | AUCUN |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6-REGISTER-ACCENTS-0EUR-BILLING-UX-BUILD-DEV-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE CLIENT REGISTER POLISH DEV PH-SAAS-T8.12AS.20.6`

STOP.
