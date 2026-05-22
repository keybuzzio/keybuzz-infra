# PH-SAAS-T8.12AS.20.6C-REGISTER-CTA-TRIAL-COPY-BUILD-PROD-01

> Date : 2026-05-22
> Linear : KEY-345 (primary) ; KEY-342 (related) ; KEY-343 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6C REGISTER POLISH BUILD PROD
> Environnement : PROD build only (aucun docker push, aucun deploy)

## VERDICT

GO BUILD CLIENT REGISTER POLISH PROD READY PH-SAAS-T8.12AS.20.6C

- Image Docker locale `ghcr.io/keybuzzio/keybuzz-client:v3.5.201-register-polish-prod` build OK depuis worktree --detach commit `be45f1d`.
- Image ID local : `sha256:9fb8c455125b83447cdd939f15f034c420bf80249be9d7b03741fc548e11aa7d` size 280 MB.
- OCI labels KEY-308 : 5/5 OK (revision=be45f1d).
- Build args PROD explicites tous fournis (NEXT_PUBLIC_APP_ENV=production, API PROD https://api.keybuzz.io, Clarity, SGTM, LinkedIn).
- **KEY-263 isolation PROD STRICT** : api-prod=87, api-dev=0 (aucun leak DEV en PROD).
- KEY-302 Clarity preservee : wuk12h9i33=2, clarity.ms/tag=2.
- LinkedIn 9969977=2, SGTM t.keybuzz.pro=2 (baseline preserve).
- PH-20.6C nouveaux markers PROD LIVE bundle :
  - CTA "Demarrer mon essai gratuit" : 0 -> **2** (+2)
  - microcopy "seulement si vous continuez" : 0 -> **2** (+2)
  - "dans 14 jours" : 0 -> **2** (+2)
- PH-20.6A markers PROD LIVE :
  - register-trial-value-banner : 0 -> **2** (+2)
  - Toutes les fonctionnalit : 0 -> **2** (+2)
  - Inbox marketplace : 0 -> **2** (+2)
  - KeyBuzz rassemble : 0 -> **2** (+2)
- PH-20.6B markers ABSENTS PROD (correct) :
  - register-plan-trial-pricing : 0
  - Tarif annuel : 0
- Phrase interdite "Payez 0" : 0 (ABSENT).
- PH-19.x preserves : data-clarity-mask=2, kb_signup_form_draft_v1=1, plan_selected=3.
- 0 fake event delta vs baseline v3.5.200 (Lead=6, Purchase=7, SubmitForm=2, InitiateCheckout=2, StartTrial=0, CompletePayment=0 - tous identiques).
- GHCR tag cible LIBRE (manifest unknown). Aucun docker push.
- Runtime Client DEV `v3.5.210-register-polish-dev` INCHANGE.
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Worktree nettoyee.

STOP avant docker push GHCR.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22 |
| keybuzz-client HEAD | be45f1d (PH-20.6C source) |
| keybuzz-infra HEAD | 14237aa (post APPLY DEV PH-20.6C rapport) |
| Runtime Client DEV avant | v3.5.210-register-polish-dev |
| Runtime Client PROD avant | v3.5.200-clarity-register-prod |
| GHCR collision tag v3.5.201-register-polish-prod | manifest unknown (LIBRE) |

## E1 SOURCE COMMIT be45f1d ASSERTIONS

| Assertion | Resultat |
|---|---|
| Commit title | fix(register): refine plan CTA copy and trial microcopy |
| Files changed | app/register/page.tsx (+27 -17) |
| CTA Demarrer present source l.856 | OK |
| Microcopy seulement si vous continuez source l.858+ | OK |
| register-trial-value-banner source | 1 |
| register-plan-trial-pricing source (DOIT 0, PH-20.6B retire) | 0 |
| data-clarity-mask source | 13 |
| kb_signup_form_draft_v1 source | 2 |
| plan_selected source | 2 |
| SaaSAnalytics.tsx diff | 0 (Clarity route-gated INCHANGE) |

## E2 GHCR COLLISION TAG PROD

| Tag | docker manifest inspect | Verdict |
|---|---|---|
| v3.5.201-register-polish-prod | manifest unknown | LIBRE OK |

## E3 BUILD ARGS PROD (audit Dockerfile + baseline v3.5.200)

Dockerfile ARG declarees (l.16-26) :
- NEXT_PUBLIC_APP_ENV : obligatoire (`__MUST_BE_SET_BY_BUILD_ARG__`)
- NEXT_PUBLIC_API_URL : obligatoire
- NEXT_PUBLIC_API_BASE_URL : obligatoire
- NEXT_PUBLIC_LINKEDIN_PARTNER_ID : default `9969977`
- NEXT_PUBLIC_CLARITY_PROJECT_ID : default vide
- NEXT_PUBLIC_SGTM_URL : default vide
- NEXT_PUBLIC_GA4_MEASUREMENT_ID / META_PIXEL_ID / TIKTOK_PIXEL_ID : default vides
- GIT_COMMIT_SHA / BUILD_TIME : default unknown

Baseline v3.5.200-clarity-register-prod bundle counts utilises pour reproduire :
- api.keybuzz.io (PROD URL) : 87
- api-dev.keybuzz.io : 0 (isolation PROD stricte)
- Clarity wuk12h9i33 : 2
- clarity.ms/tag : 2
- LinkedIn 9969977 : 2
- SGTM t.keybuzz.pro : 2
- GA4 / Meta / TikTok : vides en PROD aussi

| Build arg | Valeur fournie PROD | Justification |
|---|---|---|
| NEXT_PUBLIC_APP_ENV | production | obligatoire Dockerfile |
| NEXT_PUBLIC_API_URL | https://api.keybuzz.io | KEY-263 PROD URL |
| NEXT_PUBLIC_API_BASE_URL | https://api.keybuzz.io | idem |
| NEXT_PUBLIC_SGTM_URL | https://t.keybuzz.pro | baseline preserve |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 | baseline preserve |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | wuk12h9i33 | KEY-302 Clarity preserve |
| GIT_COMMIT_SHA | be45f1d70... | OCI revision |
| BUILD_TIME | 2026-05-22T00:18:47Z | OCI created |

## E4 WORKTREE BUILD-FROM-GIT

| Indicateur | Valeur |
|---|---|
| Worktree path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.6C-PROD/keybuzz-client |
| Worktree detache sur | be45f1d |
| Worktree dirty | 0 |
| Source PH-20.6C present worktree | CTA Demarrer l.856 + microcopy seulement si vous continuez l.858+ |

## E5 DOCKER BUILD PROD

| Item | Valeur |
|---|---|
| Build args explicites | 8 (APP_ENV=production, API PROD, SGTM, LinkedIn, Clarity, GIT_COMMIT_SHA, BUILD_TIME) |
| Exit code | 0 |
| Image tag local | ghcr.io/keybuzzio/keybuzz-client:v3.5.201-register-polish-prod |
| Image ID | sha256:9fb8c455125b83447cdd939f15f034c420bf80249be9d7b03741fc548e11aa7d |
| Image size | 280 MB |
| Created | 2026-05-22T00:21:37Z |

## E6 OCI LABELS KEY-308 (5/5)

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.revision | be45f1d70c72a1c7431f8e40ace733e85258d3b6 | OK (commit PH-20.6C) |
| org.opencontainers.image.created | 2026-05-22T00:18:47Z | OK |
| org.opencontainers.image.version | v3.5.201-register-polish-prod | OK |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-client | OK |
| org.opencontainers.image.title | keybuzz-client | OK |

KEY-309 tag immutable + suffixe `-prod` conforme.

## E7+E8 BUNDLE AUDIT + BASELINE COMPARISON v3.5.200 PROD -> v3.5.201 PROD

### KEY-263 isolation PROD strict

| Indicateur | v3.5.200 PROD | v3.5.201 PROD | Delta | Verdict |
|---|---|---|---|---|
| api.keybuzz.io (PROD URL) | 87 | 87 | 0 | **OK isolation PROD preservee** |
| api-dev.keybuzz.io | 0 | 0 | 0 | **OK pas de leak DEV en PROD** |

### KEY-302 Clarity + Marketing IDs

| Indicateur | v3.5.200 | v3.5.201 | Delta | Verdict |
|---|---|---|---|---|
| Clarity wuk12h9i33 | 2 | 2 | 0 | OK preserve |
| clarity.ms/tag | 2 | 2 | 0 | OK |
| LinkedIn 9969977 | 2 | 2 | 0 | OK |
| SGTM t.keybuzz.pro | 2 | 2 | 0 | OK |

### Nouveaux markers PH-20.6C PROD LIVE

| Indicateur | v3.5.200 | v3.5.201 | Delta | Verdict |
|---|---|---|---|---|
| CTA "Demarrer mon essai gratuit" | 0 | **2** | **+2** | **OK CTA LIVE PROD** |
| microcopy "seulement si vous continuez" | 0 | **2** | **+2** | **OK microcopy LIVE PROD** |
| "dans 14 jours" | 0 | **2** | **+2** | **OK** |

### PH-20.6A markers PROD LIVE (promotion DEV -> PROD)

| Indicateur | v3.5.200 | v3.5.201 | Delta | Verdict |
|---|---|---|---|---|
| register-trial-value-banner | 0 | **2** | **+2** | **OK marker promote PROD** |
| Toutes les fonctionnalit | 0 | **2** | **+2** | **OK copy promote PROD** |
| Inbox marketplace | 0 | **2** | **+2** | **OK bullet promote PROD** |
| KeyBuzz rassemble | 0 | **2** | **+2** | **OK ReassurancePanel intro promote PROD** |

### PH-20.6B markers ABSENTS PROD (correct, source revert OK)

| Indicateur | v3.5.200 | v3.5.201 | Delta | Verdict |
|---|---|---|---|---|
| register-plan-trial-pricing (PH-20.6B abandonne) | 0 | 0 | 0 | OK absent |
| Tarif annuel (PH-20.6B abandonne) | 0 | 0 | 0 | OK absent |

### Phrase interdite brief

| Indicateur | v3.5.200 | v3.5.201 | Verdict |
|---|---|---|---|
| "Payez 0" (INTERDIT brief PH-20.6C) | 0 | 0 | **OK ABSENT** |

### PH-19.x preserves

| Indicateur | v3.5.200 | v3.5.201 | Delta | Verdict |
|---|---|---|---|---|
| data-clarity-mask | 2 | 2 | 0 | OK preserve (chunks compresses) |
| kb_signup_form_draft_v1 | 1 | 1 | 0 | OK |
| plan_selected | 3 | 3 | 0 | OK |

### No fake events delta

| Pattern | v3.5.200 | v3.5.201 | Delta | Verdict |
|---|---|---|---|---|
| Lead | 6 | 6 | 0 | OK preexistant |
| Purchase | 7 | 7 | 0 | OK preexistant |
| StartTrial | 0 | 0 | 0 | OK |
| CompletePayment | 0 | 0 | 0 | OK |
| SubmitForm | 2 | 2 | 0 | OK preexistant |
| InitiateCheckout | 2 | 2 | 0 | OK preexistant |

Aucun fake event ajoute par PH-20.6C en PROD. Tous patterns preexistants identiques baseline.

## E9 GHCR COLLISION + RUNTIME PRESERVE

| Item | Valeur | Verdict |
|---|---|---|
| GHCR collision tag v3.5.201-register-polish-prod | manifest unknown | LIBRE (aucun push) |
| Runtime Client DEV | v3.5.210-register-polish-dev | INCHANGE |
| Runtime Client PROD | v3.5.200-clarity-register-prod | INCHANGE |

## E10 CLEANUP WORKTREE

| Action | Resultat |
|---|---|
| `git worktree remove --force` | OK |
| `rm -rf /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.6C-PROD/` | OK |
| Worktree present apres cleanup ? | NON |

## RUNTIME PRESERVE FINAL

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.210-register-polish-dev (PH-20.6C live) | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-website | -dev/-prod | v0.6.19-cta-tracking-* | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

Aucun deploy. Aucun kubectl apply. Aucun docker push.

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR (tag PROD cible LIBRE).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source au-dela du commit be45f1d.
- AUCUN secret / token affiche.
- AUCUNE mutation DB / Stripe.
- AUCUN faux register DEV/PROD.
- AUCUNE modification API/Website/Admin.
- SaaSAnalytics.tsx Clarity route-gated INCHANGE.
- Logique pricing business INCHANGE (PRICING_CONFIG/getAnnualPrice/PLANS/ANNUAL_DISCOUNT/handleConfirmPlanAndCheckout).
- Bastion install-v3 (46.62.171.61) uniquement.

## NO FAKE METRICS / NO FAKE EVENTS

- Build container Docker uniquement.
- 0 fake event delta vs baseline v3.5.200 PROD.
- Aucun pixel touche.
- Aucun checkout reel.
- Aucune mutation DB.

## ROLLBACK PLAN (anticipation phase PUSH IMAGE PROD)

Si push + apply PROD provoquent regression :
1. Rollback tag PROD actuel `v3.5.200-clarity-register-prod`.
2. Procedure GitOps : editer `k8s/keybuzz-client-prod/deployment.yaml` -> revenir v3.5.200 + commit + push + apply.

INTERDIT : kubectl set image / git reset --hard / git clean.

## GAPS

1. Aucun. Build clean, OCI conformes, isolation PROD stricte (api.keybuzz.io seul, api-dev=0), nouveaux markers PH-20.6C PROD LIVE, PH-20.6A promote PROD, PH-20.6B absents (correct), "Payez 0" absent, 0 fake event delta vs baseline.
2. QA navigateur Ludovic en PROD recommandee post-APPLY PROD (preview/keybuzz.io ou registre PROD reel mais sans mutation Stripe live).

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD CLIENT REGISTER POLISH PROD READY PH-SAAS-T8.12AS.20.6C |
| Bastion | install-v3 46.62.171.61 |
| Source commit Client | be45f1d |
| Tag image cible PROD | v3.5.201-register-polish-prod |
| Image ID local | sha256:9fb8c455125b83447cdd939f15f034c420bf80249be9d7b03741fc548e11aa7d |
| Image size | 280 MB |
| OCI labels KEY-308 | 5/5 OK |
| KEY-263 isolation PROD | OK (api-prod=87, api-dev=0) |
| KEY-302 Clarity preservee | OK (wuk12h9i33=2) |
| PH-20.6C nouveaux markers PROD | LIVE (CTA=2, microcopy=2, dans 14 jours=2) |
| PH-20.6A markers promote PROD | LIVE (trial-banner=2, Toutes fonctionnalit=2, Inbox marketplace=2, KeyBuzz rassemble=2) |
| PH-20.6B markers PROD | ABSENTS (register-plan-trial-pricing=0, Tarif annuel=0) |
| "Payez 0" (interdit brief) | ABSENT |
| Fake events delta | 0 |
| GHCR collision tag PROD | LIBRE |
| Worktree | nettoyee |
| Runtime Client DEV+PROD | INCHANGES |
| Runtime API+Website+Admin | INCHANGES |
| Docker push | AUCUN |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6C-REGISTER-CTA-TRIAL-COPY-BUILD-PROD-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE CLIENT REGISTER POLISH PROD PH-SAAS-T8.12AS.20.6C`

STOP.
