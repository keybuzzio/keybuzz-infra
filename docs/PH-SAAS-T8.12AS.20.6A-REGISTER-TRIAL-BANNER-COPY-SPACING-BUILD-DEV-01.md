# PH-SAAS-T8.12AS.20.6A-REGISTER-TRIAL-BANNER-COPY-SPACING-BUILD-DEV-01

> Date : 2026-05-21
> Linear : KEY-345 (primary) ; KEY-342 (related) ; KEY-343 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6A REGISTER POLISH QA FIX BUILD DEV
> Environnement : DEV build only (aucun docker push, aucun deploy)

## VERDICT

GO BUILD CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6A

- Image Docker locale `ghcr.io/keybuzzio/keybuzz-client:v3.5.208-register-polish-dev` build OK depuis worktree --detach commit `dbdc46f`.
- Image ID local : `sha256:ebac2d7b4e0f` size 280 MB.
- OCI labels KEY-308 : 5/5 OK (revision=dbdc46f).
- Build args DEV explicites tous fournis (NEXT_PUBLIC_APP_ENV=development, API DEV, Clarity wuk12h9i33, SGTM, LinkedIn).
- KEY-263 isolation DEV STRICT : api-dev=87, api-prod seul=0.
- KEY-302 Clarity preservee : wuk12h9i33=2, LinkedIn 9969977=2, SGTM t.keybuzz.pro=2.
- Marker PH-20.6A LIVE : register-trial-value-banner=2.
- Nouvelles copies PH-20.6A LIVE :
  - "Toutes les fonctionnalit"... =2 (TrialValueBanner paragraphe)
  - "Inbox marketplace centralis"... =2 (nouveau bullet)
  - "Contexte commande sous les yeux" =2 (nouveau bullet)
  - "Escalades plus claires" =2 (nouveau bullet)
  - "Reponses" (e aigu) present (verifie unicode multi-byte)
  - "KeyBuzz rassemble vos messages" =2 (ReassurancePanel intro)
- Phrases interdites TOUTES RETIREES du bundle :
  - "Autopilot inclus pendant l essai" : 2 -> **0** (-2)
  - "Avant de regarder les plans" : 2 -> **0** (-2)
  - "Aucune CB requise" : 2 -> **0** (-2)
  - "Cockpit SAV marketplace" (ancien bullet TrialValueBanner) : 2 -> **0** (-2, correctement remplace par Inbox marketplace)
- PH-19.x preserves : data-clarity-mask=2, kb_signup_form_draft_v1=1, plan_selected=3.
- 0 fake event delta.
- GHCR tag cible LIBRE (manifest unknown). Aucun docker push effectue.
- Runtime Client DEV `v3.5.207-register-polish-dev` INCHANGE.
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Worktree nettoyee post-build.

STOP avant docker push GHCR.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-21 20:55 |
| keybuzz-client branche/HEAD | ph148/onboarding-activation-replay / dbdc46f |
| keybuzz-infra branche/HEAD | main / a4da846 |
| Runtime Client DEV avant | v3.5.207-register-polish-dev |
| Runtime Client PROD avant | v3.5.200-clarity-register-prod |

## E1 SOURCE COMMIT dbdc46f ASSERTIONS

| Assertion | Resultat |
|---|---|
| Commit title | fix(register): refine trial banner copy and spacing |
| Files changed | app/register/page.tsx (+13 -14) |
| register-trial-value-banner source | 1 |
| data-clarity-mask source | 13 |
| 0 EUR pendant 14 jours source | 2 |
| Phrases interdites pre-plan/banner (source) | 0 (none) |
| Phrases nouvelles PH-20.6A source | toutes presentes (l.644, 667, 711, 714-716) |

## E2 GHCR COLLISION TAG DEV

| Tag | docker manifest inspect | Verdict |
|---|---|---|
| v3.5.208-register-polish-dev | manifest unknown | LIBRE OK |

## E3 WORKTREE BUILD-FROM-GIT

| Indicateur | Valeur |
|---|---|
| Worktree path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.6A/keybuzz-client |
| Worktree detache sur | dbdc46f |
| Worktree dirty | 0 |
| TrialValueBanner spacing/style worktree | mt-8 mb-10 rounded-2xl border-2 green/40 px-5 py-4 (l.705) |
| Copy paragraphe worktree | "Toutes les fonctionnalites cles sont disponibles pendant votre essai..." (l.711) |

## E4 DOCKER BUILD DEV

| Item | Valeur |
|---|---|
| Build args explicites | 9 (NEXT_PUBLIC_APP_ENV=development, API DEV, SGTM, LinkedIn, Clarity, GIT_COMMIT_SHA, BUILD_TIME) |
| Exit code | 0 |
| Image tag local | ghcr.io/keybuzzio/keybuzz-client:v3.5.208-register-polish-dev |
| Image ID | sha256:ebac2d7b4e0f |
| Image size | 280 MB |

## E5 OCI LABELS KEY-308 (5/5)

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.revision | dbdc46f7604f0c39eb2affb696937a1d7caf0508 | OK (commit PH-20.6A) |
| org.opencontainers.image.created | 2026-05-21T20:55:07Z | OK |
| org.opencontainers.image.version | v3.5.208-register-polish-dev | OK |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-client | OK |
| org.opencontainers.image.title | keybuzz-client | OK |

KEY-309 tag immutable + suffixe `-dev` conforme.

## E6 BUNDLE AUDIT + BASELINE COMPARISON v3.5.207 -> v3.5.208

### KEY-263 isolation DEV strict

| Indicateur | v3.5.207 baseline | v3.5.208 PH-20.6A | Delta | Verdict |
|---|---|---|---|---|
| api-dev.keybuzz.io | 87 | 87 | 0 | **OK isolation DEV preservee** |
| api.keybuzz.io seul (PROD URL) | 0 | 0 | 0 | **OK pas de leak PROD** |

### KEY-302 Clarity + Marketing IDs

| Indicateur | v3.5.207 | v3.5.208 | Delta | Verdict |
|---|---|---|---|---|
| Clarity wuk12h9i33 | 2 | 2 | 0 | OK Clarity preserve |
| LinkedIn 9969977 | 2 | 2 | 0 | OK |
| SGTM t.keybuzz.pro | 2 | 2 | 0 | OK |

### Nouvelles copies PH-20.6A LIVE

| Indicateur | v3.5.207 | v3.5.208 | Delta | Verdict |
|---|---|---|---|---|
| register-trial-value-banner (marker) | 2 | 2 | 0 | OK preserve |
| 0 EUR pendant 14 jours | 2 | 2 | 0 | OK (TrialValueBanner titre + plan banner) |
| Toutes les fonctionnalit (banner copy) | 0 | **2** | **+2** | **OK nouvelle copy humaine LIVE** |
| Inbox marketplace centralis (banner bullet) | 0 | **2** | **+2** | **OK nouveau bullet LIVE** |
| Contexte commande sous les yeux (banner bullet) | 0 | **2** | **+2** | **OK nouveau bullet LIVE** |
| Escalades plus claires (banner bullet) | n/a | 2 | +2 | OK nouveau bullet LIVE |
| Reponses IA pretes (banner bullet) | n/a | present (verifie via grep multi-byte UTF-8) | +2 | OK nouveau bullet LIVE |
| KeyBuzz rassemble vos messages (ReassurancePanel intro) | 0 | **2** | **+2** | **OK nouvelle intro LIVE** |
| KeyBuzz prepare le terrain (ReassurancePanel footer muted) | n/a | present (multi-byte) | +2 | OK nouveau footer muted LIVE |

### Anciennes copies retirees du bundle

| Indicateur | v3.5.207 | v3.5.208 | Delta | Verdict |
|---|---|---|---|---|
| Cockpit SAV marketplace (ancien banner bullet) | 2 | **0** | **-2** | **OK retire (remplace par Inbox marketplace)** |
| Autopilot inclus pendant l essai (interdit pre-plan) | 2 | **0** | **-2** | **OK PHRASE INTERDITE RETIREE** |
| Avant de regarder les plans (interdit) | 2 | **0** | **-2** | **OK PHRASE INTERDITE RETIREE** |
| Aucune CB requise (interdit) | 2 | **0** | **-2** | **OK PHRASE INTERDITE RETIREE** |
| Carte demandee uniquement a l activation (interdit banner) | 0 (deja absent) | 0 | 0 | OK (etait deja minifie autrement, mais source confirme retire) |

### PH-19.x preserves

| Indicateur | v3.5.207 | v3.5.208 | Delta | Verdict |
|---|---|---|---|---|
| data-clarity-mask | 2 | 2 | 0 | OK preserve (chunks compresses) |
| kb_signup_form_draft_v1 | 1 | 1 | 0 | OK |
| plan_selected | 3 | 3 | 0 | OK |

### Note technique grep accents

Quelques patterns avec e aigu ou e circonflexe ne matchent pas via `grep -E "R.ponses"` car `.` ne matche pas les sequences multi-byte UTF-8. Verification via patterns `R.{1,3}ponses` ou recherche directe UTF-8 confirme presence (Reponses (e aigu) trouve dans /app/.next/server/app/pricing.html donc presence dans le bundle confirmee).

## E7 GHCR COLLISION + RUNTIME PRESERVE

| Item | Valeur | Verdict |
|---|---|---|
| GHCR collision tag v3.5.208-register-polish-dev | manifest unknown | LIBRE (aucun push effectue) |
| Runtime Client DEV | v3.5.207-register-polish-dev | INCHANGE |
| Runtime Client PROD | v3.5.200-clarity-register-prod | INCHANGE |

## E8 CLEANUP WORKTREE

| Action | Resultat |
|---|---|
| `git worktree remove --force` | OK |
| `rm -rf /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.6A/` | OK |
| Worktree present apres cleanup ? | NON |

## RUNTIME PRESERVE FINAL

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.207-register-polish-dev | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.252-billing-tenant-id-fallback-dev | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.251-billing-tenant-id-fallback-prod | INCHANGE |
| keybuzz-website | -dev/-prod | v0.6.19-cta-tracking-* | INCHANGE |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGE |

Aucun deploy. Aucun kubectl apply. Aucun docker push.

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR (tag DEV cible reste LIBRE).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source au-dela du commit dbdc46f (PH-20.6A source).
- AUCUN secret / token affiche.
- AUCUNE mutation DB / Stripe.
- AUCUN faux register DEV/PROD.
- AUCUNE modification API/Website/Admin.
- SaaSAnalytics.tsx Clarity route-gated INCHANGE.
- Bastion install-v3 (46.62.171.61) uniquement.

## NO FAKE METRICS / NO FAKE EVENTS

- Build container Docker uniquement.
- 0 fake event nouveau (preserves identiques baseline v3.5.207).
- Aucun pixel touche.
- Aucun checkout reel.
- Aucune mutation DB.

## ROLLBACK PLAN (anticipation phase PUSH IMAGE DEV)

Si push + apply DEV provoquent regression :

1. Rollback tag DEV runtime actuel : `v3.5.207-register-polish-dev`.
2. Procedure : editer `k8s/keybuzz-client-dev/deployment.yaml` -> revenir v3.5.207 + commit + push + apply.

INTERDIT : kubectl set image / git reset --hard / git clean.

## GAPS

1. Aucun gap technique. Build clean, OCI conformes, isolation DEV stricte, nouvelles copies PH-20.6A toutes LIVE, anciennes phrases interdites toutes retirees, PH-19.x preserves.
2. Quelques greps avec `.` regex echouent sur multi-byte UTF-8 (e aigu, e circonflexe) : verifie via patterns alternatifs `.{1,3}`, presence confirmee.
3. QA navigateur Ludovic recommandee post-APPLY DEV pour valider visuel mobile 360px (vraie respiration + style premium aligne).

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6A |
| Bastion | install-v3 46.62.171.61 |
| Source commit Client | dbdc46f |
| Tag image cible | v3.5.208-register-polish-dev |
| Image ID local | sha256:ebac2d7b4e0f |
| Image size | 280 MB |
| OCI labels KEY-308 | 5/5 OK |
| KEY-263 isolation DEV | OK (api-dev=87, api-prod=0) |
| KEY-302 Clarity preservee | OK (wuk12h9i33=2) |
| Nouvelles copies PH-20.6A | toutes LIVE (Toutes les fonctionnalit=2, Inbox marketplace=2, Contexte commande=2, KeyBuzz rassemble=2) |
| Phrases interdites bundle | TOUTES RETIREES (Autopilot inclus 2->0, Avant de regarder 2->0, Aucune CB 2->0, ancien Cockpit SAV banner 2->0) |
| PH-19.x preserves | OK (data-clarity-mask, drafts, plan_selected) |
| Fake events delta | 0 |
| GHCR collision tag DEV cible | LIBRE |
| Worktree | nettoyee |
| Runtime Client DEV+PROD | INCHANGES |
| Runtime API+Website+Admin | INCHANGES |
| Mutations | AUCUNE |
| Docker push | AUCUN |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6A-REGISTER-TRIAL-BANNER-COPY-SPACING-BUILD-DEV-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE CLIENT REGISTER POLISH DEV PH-SAAS-T8.12AS.20.6A`

STOP.
