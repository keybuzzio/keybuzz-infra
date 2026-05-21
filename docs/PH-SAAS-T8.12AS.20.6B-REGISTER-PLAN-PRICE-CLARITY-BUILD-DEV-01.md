# PH-SAAS-T8.12AS.20.6B-REGISTER-PLAN-PRICE-CLARITY-BUILD-DEV-01

> Date : 2026-05-21
> Linear : KEY-345 (primary) ; KEY-342 (related) ; KEY-343 (related) ; KEY-337 (parent PH-20)
> Phase : PH-SAAS-T8.12AS.20.6B REGISTER PLAN PRICE CLARITY BUILD DEV
> Environnement : DEV build only (aucun docker push, aucun deploy)

## VERDICT

GO BUILD CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6B

- Image Docker locale `ghcr.io/keybuzzio/keybuzz-client:v3.5.209-register-polish-dev` build OK depuis worktree --detach commit `97bdd5b`.
- Image ID local : `sha256:e329ea4d11af926d7be8e9708763ac92bc628595412e16483c5c4452cde0e892` size 280 MB.
- OCI labels KEY-308 : 5/5 OK (revision=97bdd5b).
- Build args DEV explicites tous fournis.
- KEY-263 isolation DEV STRICT : api-dev=87, api-prod seul=0.
- KEY-302 Clarity preservee : wuk12h9i33=2, LinkedIn=2, SGTM=2.
- Markers PH-20.6B LIVE bundle :
  - register-plan-trial-pricing : 0 -> **2** (+2)
  - dans 14 jours : 0 -> **2** (+2)
  - Tarif annuel : 0 -> **2** (+2)
  - "0 EUR" present (26 occurrences bundle), "maintenant" present (2 quoted, 6 total)
- Markers preserves : register-trial-value-banner=2, register-plan-card=2, register-plan-grid=2, 0 EUR pendant 14 jours=2 (grand encart).
- PH-19.x preserves : data-clarity-mask=2, kb_signup_form_draft_v1=1, plan_selected=3.
- 0 fake event delta vs baseline v3.5.208 (Lead=6, Purchase=7, SubmitForm=2, InitiateCheckout=2, StartTrial=0, CompletePayment=0, AW-=0 - tous identiques).
- GHCR tag cible LIBRE (manifest unknown). Aucun docker push.
- Runtime Client DEV `v3.5.208-register-polish-dev` INCHANGE.
- Runtime Client PROD `v3.5.200-clarity-register-prod` INCHANGE.
- Worktree nettoyee.

STOP avant docker push GHCR.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-21 21:53 |
| keybuzz-client HEAD | 97bdd5b (PH-20.6B QA fix source) |
| keybuzz-infra HEAD | f25bfd9 (post SOURCE PH-20.6B rapport) |
| Runtime Client DEV avant | v3.5.208-register-polish-dev |
| Runtime Client PROD avant | v3.5.200-clarity-register-prod |
| GHCR collision tag v3.5.209-register-polish-dev | manifest unknown (LIBRE) |

## E1 WORKTREE BUILD-FROM-GIT

| Indicateur | Valeur |
|---|---|
| Worktree path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.6B/keybuzz-client |
| Worktree detache sur | 97bdd5b |
| Worktree dirty | 0 |
| Bloc PH-20.6B present worktree | l.792-806 register-plan-trial-pricing data-testid OK |

## E2 DOCKER BUILD DEV

| Item | Valeur |
|---|---|
| Build args explicites | 9 (NEXT_PUBLIC_APP_ENV=development, API DEV, SGTM, LinkedIn, Clarity, GIT_COMMIT_SHA, BUILD_TIME) |
| Exit code | 0 |
| Image tag local | ghcr.io/keybuzzio/keybuzz-client:v3.5.209-register-polish-dev |
| Image ID | sha256:e329ea4d11af926d7be8e9708763ac92bc628595412e16483c5c4452cde0e892 |
| Image size | 280 MB |
| Created | 2026-05-21T21:55:58Z |

## E3 OCI LABELS KEY-308 (5/5)

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.revision | 97bdd5bf9f197807283c09e4a41e93e5fce11b5b | OK (commit PH-20.6B) |
| org.opencontainers.image.created | 2026-05-21T21:53:10Z | OK |
| org.opencontainers.image.version | v3.5.209-register-polish-dev | OK |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-client | OK |
| org.opencontainers.image.title | keybuzz-client | OK |

KEY-309 tag immutable + suffixe `-dev` conforme.

## E4 BUNDLE AUDIT + BASELINE COMPARISON v3.5.208 -> v3.5.209

### KEY-263 isolation DEV strict

| Indicateur | v3.5.208 baseline | v3.5.209 PH-20.6B | Delta | Verdict |
|---|---|---|---|---|
| api-dev.keybuzz.io | 87 | 87 | 0 | **OK isolation DEV preservee** |
| api.keybuzz.io seul (PROD URL) | 0 | 0 | 0 | **OK pas de leak PROD** |

### KEY-302 Clarity + Marketing IDs

| Indicateur | v3.5.208 | v3.5.209 | Delta | Verdict |
|---|---|---|---|---|
| Clarity wuk12h9i33 | 2 | 2 | 0 | OK preserve |
| LinkedIn 9969977 | 2 | 2 | 0 | OK |
| SGTM t.keybuzz.pro | 2 | 2 | 0 | OK |

### Nouveaux markers PH-20.6B LIVE bundle

| Indicateur | v3.5.208 | v3.5.209 | Delta | Verdict |
|---|---|---|---|---|
| **register-plan-trial-pricing** (data-testid) | 0 | **2** | **+2** | **OK marker LIVE** |
| **dans 14 jours** (nouvelle copy "puis X EUR/mois dans 14 jours") | 0 | **2** | **+2** | **OK copy LIVE** |
| **Tarif annuel** (ligne discrete annuel) | 0 | **2** | **+2** | **OK ligne annuel LIVE** |
| 0 EUR (presence bundle) | n/a | 26 | + | OK |
| maintenant (string quoted JSX) | n/a | 2 | + | OK |

Note technique : `0 EUR maintenant` string contigue = 0 dans bundle car le source utilise deux elements JSX separes (`<p>0 EUR</p>` puis `<p>maintenant</p>`), donc les minifier Next.js ne les concatene pas. La presence separee `0 EUR` (26) + `maintenant` (2 quoted, 6 total) confirme presence visuelle dans le bundle.

### Markers preserves PH-20.6A + PH-19.x

| Indicateur | v3.5.208 | v3.5.209 | Delta | Verdict |
|---|---|---|---|---|
| register-trial-value-banner (PH-20.6A marker) | 2 | 2 | 0 | OK preserve |
| register-plan-card (data-testid) | 2 | 2 | 0 | OK preserve |
| register-plan-grid (data-testid) | 2 | 2 | 0 | OK preserve |
| 0 EUR pendant 14 jours (grand encart preserve) | 2 | 2 | 0 | OK preserve |
| data-clarity-mask | 2 | 2 | 0 | OK preserve |
| kb_signup_form_draft_v1 | 1 | 1 | 0 | OK |
| plan_selected | 3 | 3 | 0 | OK |

### No fake events delta

| Pattern | v3.5.208 | v3.5.209 | Delta | Verdict |
|---|---|---|---|---|
| Lead | 6 | 6 | 0 | OK preexistant |
| Purchase | 7 | 7 | 0 | OK preexistant |
| StartTrial | 0 | 0 | 0 | OK |
| CompletePayment | 0 | 0 | 0 | OK |
| SubmitForm | 2 | 2 | 0 | OK preexistant |
| InitiateCheckout | 2 | 2 | 0 | OK preexistant |
| AW- | 0 | 0 | 0 | OK |

Aucun fake event ajoute par PH-20.6B. Tous les patterns preserves identiques baseline.

## E5 GHCR COLLISION + RUNTIME PRESERVE

| Item | Valeur | Verdict |
|---|---|---|
| GHCR collision tag v3.5.209-register-polish-dev | manifest unknown | LIBRE (aucun push effectue) |
| Runtime Client DEV | v3.5.208-register-polish-dev | INCHANGE |
| Runtime Client PROD | v3.5.200-clarity-register-prod | INCHANGE |

## E6 CLEANUP WORKTREE

| Action | Resultat |
|---|---|
| `git worktree remove --force` | OK |
| `rm -rf /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.6B/` | OK |
| Worktree present apres cleanup ? | NON |

## RUNTIME PRESERVE FINAL

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-client | keybuzz-client-dev | v3.5.208-register-polish-dev | INCHANGE |
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
- AUCUN patch source au-dela du commit 97bdd5b.
- AUCUN secret / token affiche.
- AUCUNE mutation DB / Stripe.
- AUCUN faux register DEV/PROD.
- AUCUNE modification API/Website/Admin.
- SaaSAnalytics.tsx Clarity route-gated INCHANGE.
- Logique pricing business INCHANGE (PRICING_CONFIG/getAnnualPrice/PLANS/ANNUAL_DISCOUNT).
- Bastion install-v3 (46.62.171.61) uniquement.

## NO FAKE METRICS / NO FAKE EVENTS

- Build container Docker uniquement.
- 0 fake event delta vs baseline v3.5.208.
- Aucun pixel touche.
- Aucun checkout reel.
- Aucune mutation DB.

## ROLLBACK PLAN

Si push + apply DEV provoquent regression : rollback tag DEV runtime actuel `v3.5.208-register-polish-dev`. Procedure : editer manifest -> revenir v3.5.208 + commit + push + apply.

INTERDIT : kubectl set image / git reset --hard / git clean.

## GAPS

1. Aucun. Build clean, OCI conformes, isolation DEV stricte, nouveaux markers PH-20.6B LIVE, anciens markers preserves, PH-19.x preserves, 0 fake event delta.
2. Note grep "0 EUR maintenant" string contigue = 0 (attendu : 2 elements JSX p separes, bundle minifie ne concatene pas). Presence verifiee separement (`0 EUR` = 26, `maintenant` = 2 quoted).
3. QA navigateur Ludovic recommandee post-APPLY DEV pour valider visuel cards (3 plans starter/pro/autopilot en mensuel ET annuel, mobile 360px + desktop).

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD CLIENT REGISTER POLISH DEV READY PH-SAAS-T8.12AS.20.6B |
| Bastion | install-v3 46.62.171.61 |
| Source commit Client | 97bdd5b |
| Tag image cible | v3.5.209-register-polish-dev |
| Image ID local | sha256:e329ea4d11af926d7be8e9708763ac92bc628595412e16483c5c4452cde0e892 |
| Image size | 280 MB |
| OCI labels KEY-308 | 5/5 OK |
| KEY-263 isolation DEV | OK (api-dev=87, api-prod=0) |
| KEY-302 Clarity preservee | OK (wuk12h9i33=2) |
| Nouveaux markers PH-20.6B | toutes LIVE (register-plan-trial-pricing=2, dans 14 jours=2, Tarif annuel=2, 0 EUR/maintenant presents separement) |
| Markers preserves (PH-20.6A + PH-19.x) | trial-banner=2, plan-card=2, plan-grid=2, grand encart=2, data-clarity-mask preserves |
| Logique pricing | INCHANGE |
| Fake events delta | 0 |
| GHCR collision tag DEV cible | LIBRE |
| Worktree | nettoyee |
| Runtime Client DEV+PROD | INCHANGES |
| Runtime API+Website+Admin | INCHANGES |
| Docker push | AUCUN |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.6B-REGISTER-PLAN-PRICE-CLARITY-BUILD-DEV-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE CLIENT REGISTER POLISH DEV PH-SAAS-T8.12AS.20.6B`

STOP.
