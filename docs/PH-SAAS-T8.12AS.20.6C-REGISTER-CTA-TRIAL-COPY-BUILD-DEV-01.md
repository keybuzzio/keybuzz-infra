# PH-SAAS-T8.12AS.20.6C-REGISTER-CTA-TRIAL-COPY-BUILD-DEV-01

> Date : 2026-05-22
> Linear : KEY-345 (primary) ; KEY-342 (related) ; KEY-343 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6C REGISTER CTA TRIAL COPY BUILD DEV
> Environnement : DEV build only (aucun docker push, aucun deploy)

## VERDICT

GO BUILD CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6C

- Image Docker locale `ghcr.io/keybuzzio/keybuzz-client:v3.5.210-register-polish-dev` build OK depuis worktree --detach commit `be45f1d`.
- Image ID local : `sha256:7772629cf126899910dcb9ee006afba2345ee4f5f5453e6d5a267380b491a3c8` size 280 MB.
- OCI labels KEY-308 : 5/5 OK (revision=be45f1d).
- Build args DEV explicites tous fournis (NEXT_PUBLIC_APP_ENV=development, API DEV, Clarity, SGTM, LinkedIn).
- KEY-263 isolation DEV STRICT : api-dev=87, api-prod seul=0.
- KEY-302 Clarity preservee : wuk12h9i33=2, LinkedIn=2.
- PH-20.6C nouveaux markers LIVE bundle :
  - "Demarrer mon essai gratuit" : 0 -> **2** (+2)
  - "seulement si vous continuez" : 0 -> **2** (+2)
- PH-20.6A markers PRESERVES : register-trial-value-banner=2, Toutes les fonctionnalit=2, Inbox marketplace=2, KeyBuzz rassemble=2, grand encart 0 EUR pendant 14 jours=2.
- PH-20.6B markers ABSENTS : register-plan-trial-pricing=0, Tarif annuel=0, "0 EUR maintenant"=0 (retire bundle).
- Phrase interdite "Payez 0 EUR" : 0 (absent).
- PH-19.x preserves : data-clarity-mask=2, kb_signup_form_draft_v1=1, plan_selected=3.
- 0 fake event delta vs baseline v3.5.208 (Lead=6, Purchase=7, SubmitForm=2, InitiateCheckout=2, StartTrial=0, CompletePayment=0 - tous identiques).
- GHCR tag cible LIBRE (manifest unknown). Aucun docker push.
- Runtime Client DEV `v3.5.208-register-polish-dev` INCHANGE.
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Worktree nettoyee.

STOP avant docker push GHCR.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22 |
| keybuzz-client HEAD | be45f1d (PH-20.6C source) |
| keybuzz-infra HEAD | 548cdc6 (post SOURCE PH-20.6C rapport) |
| Runtime Client DEV avant | v3.5.208-register-polish-dev |
| Runtime Client PROD avant | v3.5.200-clarity-register-prod |
| GHCR collision tag v3.5.210-register-polish-dev | manifest unknown (LIBRE) |

## E1 WORKTREE BUILD-FROM-GIT

| Indicateur | Valeur |
|---|---|
| Worktree path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.6C/keybuzz-client |
| Worktree detache sur | be45f1d |
| Worktree dirty | 0 |
| Source assertions worktree | CTA Demarrer mon essai gratuit l.856, microcopy seulement si vous continuez l.865, PH-20.6B retire (no register-plan-trial-pricing) |

## E2 DOCKER BUILD DEV

| Item | Valeur |
|---|---|
| Build args explicites | 9 (NEXT_PUBLIC_APP_ENV=development, API DEV, SGTM, LinkedIn, Clarity, GIT_COMMIT_SHA, BUILD_TIME) |
| Exit code | 0 |
| Image tag local | ghcr.io/keybuzzio/keybuzz-client:v3.5.210-register-polish-dev |
| Image ID | sha256:7772629cf126899910dcb9ee006afba2345ee4f5f5453e6d5a267380b491a3c8 |
| Image size | 280 MB |
| Created | 2026-05-21T23:43:44Z |

## E3 OCI LABELS KEY-308 (5/5)

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.revision | be45f1d70c72a1c7431f8e40ace733e85258d3b6 | OK (commit PH-20.6C) |
| org.opencontainers.image.created | 2026-05-21T23:40:59Z | OK |
| org.opencontainers.image.version | v3.5.210-register-polish-dev | OK |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-client | OK |
| org.opencontainers.image.title | keybuzz-client | OK |

KEY-309 tag immutable + suffixe `-dev` conforme.

## E4 BUNDLE AUDIT + BASELINE COMPARISON v3.5.208 -> v3.5.210

### KEY-263 isolation DEV strict

| Indicateur | v3.5.208 baseline | v3.5.210 PH-20.6C | Delta | Verdict |
|---|---|---|---|---|
| api-dev.keybuzz.io | 87 | 87 | 0 | **OK isolation DEV preservee** |
| api.keybuzz.io seul (PROD URL) | 0 | 0 | 0 | **OK pas de leak PROD** |

### KEY-302 Clarity + Marketing IDs

| Indicateur | v3.5.208 | v3.5.210 | Delta | Verdict |
|---|---|---|---|---|
| Clarity wuk12h9i33 | 2 | 2 | 0 | OK Clarity preserve |
| LinkedIn 9969977 | 2 | 2 | 0 | OK |

### PH-20.6A markers PRESERVES LIVE

| Indicateur | v3.5.208 | v3.5.210 | Delta | Verdict |
|---|---|---|---|---|
| register-trial-value-banner | 2 | 2 | 0 | OK preserve |
| Toutes les fonctionnalit | 2 | 2 | 0 | OK preserve |
| Inbox marketplace | 2 | 2 | 0 | OK preserve |
| KeyBuzz rassemble | 2 | 2 | 0 | OK preserve |
| 0 EUR pendant 14 jours (grand encart) | 2 | 2 | 0 | OK preserve |

### Nouveaux markers PH-20.6C LIVE bundle

| Indicateur | v3.5.208 | v3.5.210 | Delta | Verdict |
|---|---|---|---|---|
| **"Demarrer mon essai gratuit"** (CTA label) | 0 | **2** | **+2** | **OK CTA LIVE** |
| **"seulement si vous continuez"** (microcopy) | 0 | **2** | **+2** | **OK microcopy LIVE** |

### PH-20.6B markers ABSENTS (retire source)

| Indicateur | v3.5.208 | v3.5.210 | Delta | Verdict |
|---|---|---|---|---|
| register-plan-trial-pricing (data-testid PH-20.6B) | 0 | 0 | 0 | OK absent |
| Tarif annuel | 0 | 0 | 0 | OK absent |
| 0 EUR maintenant | 0 | 0 | 0 | OK absent |

### Phrase interdite brief

| Indicateur | v3.5.208 | v3.5.210 | Verdict |
|---|---|---|---|
| **"Payez 0 EUR"** (INTERDIT brief PH-20.6C) | 0 | 0 | **OK ABSENT** |

### PH-19.x preserves

| Indicateur | v3.5.208 | v3.5.210 | Delta | Verdict |
|---|---|---|---|---|
| data-clarity-mask | 2 | 2 | 0 | OK preserve |
| kb_signup_form_draft_v1 | 1 | 1 | 0 | OK |
| plan_selected | 3 | 3 | 0 | OK |

### No fake events delta

| Pattern | v3.5.208 | v3.5.210 | Delta | Verdict |
|---|---|---|---|---|
| Lead | 6 | 6 | 0 | OK preexistant |
| Purchase | 7 | 7 | 0 | OK preexistant |
| StartTrial | 0 | 0 | 0 | OK |
| CompletePayment | 0 | 0 | 0 | OK |
| SubmitForm | 2 | 2 | 0 | OK preexistant |
| InitiateCheckout | 2 | 2 | 0 | OK preexistant |

Aucun fake event ajoute par PH-20.6C. Tous patterns preexistants identiques baseline.

## E5 GHCR COLLISION + RUNTIME PRESERVE

| Item | Valeur | Verdict |
|---|---|---|
| GHCR collision tag v3.5.210-register-polish-dev | manifest unknown | LIBRE (aucun push) |
| Runtime Client DEV | v3.5.208-register-polish-dev | INCHANGE |
| Runtime Client PROD | v3.5.200-clarity-register-prod | INCHANGE |

## E6 CLEANUP WORKTREE

| Action | Resultat |
|---|---|
| `git worktree remove --force` | OK |
| `rm -rf /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.6C/` | OK |
| Worktree present apres cleanup ? | NON |

## RUNTIME PRESERVE FINAL

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.208-register-polish-dev (PH-20.6A live) | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-website | -dev/-prod | v0.6.19-cta-tracking-* | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

Aucun deploy. Aucun kubectl apply. Aucun docker push.

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR (tag DEV cible LIBRE).
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
- 0 fake event delta vs baseline v3.5.208.
- Aucun pixel touche.
- Aucun checkout reel.
- Aucune mutation DB.

## ROLLBACK PLAN

Si push + apply DEV provoquent regression : rollback tag DEV actuel `v3.5.208-register-polish-dev`. Procedure : editer manifest -> revenir v3.5.208 + commit + push + apply.

INTERDIT : kubectl set image / git reset --hard / git clean.

## GAPS

1. Aucun. Build clean, OCI conformes, isolation DEV stricte, nouveaux markers PH-20.6C LIVE, PH-20.6A preserves, PH-20.6B absents, "Payez 0 EUR" absent, 0 fake event delta.
2. QA navigateur Ludovic recommandee post-APPLY DEV pour valider visuel CTA + microcopy (3 plans starter/pro/autopilot en mensuel ET annuel).

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6C |
| Bastion | install-v3 46.62.171.61 |
| Source commit Client | be45f1d |
| Tag image cible | v3.5.210-register-polish-dev |
| Image ID local | sha256:7772629cf126899910dcb9ee006afba2345ee4f5f5453e6d5a267380b491a3c8 |
| Image size | 280 MB |
| OCI labels KEY-308 | 5/5 OK |
| KEY-263 isolation DEV | OK (api-dev=87, api-prod=0) |
| KEY-302 Clarity preservee | OK (wuk12h9i33=2) |
| PH-20.6C nouveaux markers | LIVE (Demarrer=2, seulement si vous continuez=2) |
| PH-20.6A preserves | LIVE (trial-banner=2, Toutes fonctionnalit=2, Inbox marketplace=2, KeyBuzz rassemble=2, grand encart=2) |
| PH-20.6B absents | OK (register-plan-trial-pricing=0, Tarif annuel=0, 0 EUR maintenant=0) |
| Phrase interdite "Payez 0 EUR" | ABSENTE |
| Fake events delta | 0 |
| GHCR collision tag DEV cible | LIBRE |
| Worktree | nettoyee |
| Runtime Client DEV+PROD | INCHANGES |
| Runtime API+Website+Admin | INCHANGES |
| Docker push | AUCUN |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6C-REGISTER-CTA-TRIAL-COPY-BUILD-DEV-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE CLIENT REGISTER POLISH DEV PH-SAAS-T8.12AS.20.6C`

STOP.
