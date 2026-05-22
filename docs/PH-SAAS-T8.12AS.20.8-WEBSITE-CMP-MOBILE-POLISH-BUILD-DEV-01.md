# PH-SAAS-T8.12AS.20.8-WEBSITE-CMP-MOBILE-POLISH-BUILD-DEV-01

> Date : 2026-05-22
> Linear : KEY-344 (primary) ; KEY-337 (parent PH-20) ; KEY-338/KEY-340 (related tracking acquisition)
> Phase : PH-SAAS-T8.12AS.20.8 WEBSITE CMP MOBILE POLISH BUILD DEV
> Environnement : DEV build only (aucun docker push, aucun deploy)

## VERDICT

GO BUILD WEBSITE CMP MOBILE POLISH DEV READY PH-SAAS-T8.12AS.20.8

- Image Docker locale `ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-dev` build OK depuis worktree --detach commit `bb49798`.
- Image ID local : `sha256:5bd890c7544819243f40fad8499bbe3713880d2460d010ba77d47c212ef4aea8` size 214 MB.
- OCI labels KEY-308 : 5/5 OK (revision=bb497984c53c45452cc96a58eed7e3a9dd3ad9f1).
- Build args DEV explicites identiques au baseline v0.6.19-cta-tracking-dev (9 args : SITE_MODE=preview, CLIENT_APP_URL=client-dev, GA_ID=G-R3QQDYEBFG, SGTM=t.keybuzz.pro, LinkedIn=9969977, Clarity vide, Meta vide, TikTok vide, CONTACT_API=api-dev).
- KEY-263 isolation DEV : api-dev=2, api-prod seul=0 (preserve baseline).
- Baseline 100% preserve : GA=18, SGTM=39, LinkedIn=18, Clarity=0 (baseline), client-dev=3, CMP strings preserves.
- PH-20.8 nouveaux markers LIVE bundle :
  - `max-h-[60vh]` (mobile compact CSS class) : 0 -> **2** (+2)
  - `sm:hidden` (mobile-only copy class) : 0 -> **2** (+2)
  - copy mobile "Nous utilisons les cookies necessaires" : 0 -> **2** (+2)
- Desktop copy preservee : "Microsoft Clarity" = 16 (inchange).
- CMP buttons preserves : Accepter=1, Refuser les cookies optionnels=2 (= chunks JS et HTML).
- CMP liens preserves : politique cookies=2, politique de confidentialit=7.
- 0 fake event delta vs baseline (Lead=3 et autres=0 preexistants identiques ; Lead=3 = faux positifs Tailwind `leading-*` classes).
- GHCR tag cible LIBRE (`manifest unknown`). Aucun docker push.
- Runtime Website DEV `v0.6.19-cta-tracking-dev` INCHANGE.
- Runtime Website PROD `v0.6.19-cta-tracking-prod` INCHANGE.
- Worktree nettoyee.

STOP avant docker push GHCR.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22 |
| keybuzz-website HEAD | bb49798 (PH-20.8 source) |
| keybuzz-infra HEAD | e5cedae (post SOURCE PH-20.8 rapport) |
| Runtime Website DEV avant | v0.6.19-cta-tracking-dev |
| Runtime Website PROD avant | v0.6.19-cta-tracking-prod |
| GHCR collision tag v0.6.20-cmp-mobile-polish-dev | manifest unknown (LIBRE) |

## E1 WORKTREE BUILD-FROM-GIT

| Indicateur | Valeur |
|---|---|
| Worktree path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.8/keybuzz-website |
| Worktree detache sur | bb49798 |
| Worktree dirty | 0 |
| Source PH-20.8 assertions worktree | max-h-[60vh] l.76, sm:hidden l.90, copy mobile compacte present |

## E2 DOCKER BUILD DEV

| Item | Valeur |
|---|---|
| Build args explicites | 9 (SITE_MODE preview, CLIENT_APP_URL client-dev, GA_ID G-R3QQDYEBFG, SGTM t.keybuzz.pro, LinkedIn 9969977, Clarity vide, Meta vide, TikTok vide, CONTACT_API api-dev) |
| Exit code | 0 |
| Image tag local | ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-dev |
| Image ID | sha256:5bd890c7544819243f40fad8499bbe3713880d2460d010ba77d47c212ef4aea8 |
| Image size | 214 MB |
| Created | 2026-05-22T08:04:56Z |

## E3 OCI LABELS KEY-308 (5/5)

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.revision | bb497984c53c45452cc96a58eed7e3a9dd3ad9f1 | OK commit PH-20.8 |
| org.opencontainers.image.created | 2026-05-22T08:04:13Z | OK |
| org.opencontainers.image.version | v0.6.20-cmp-mobile-polish-dev | OK |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-website | OK |
| org.opencontainers.image.title | keybuzz-website | OK |

KEY-309 tag immutable + suffixe `-dev` conforme.

## E4 BUNDLE AUDIT + BASELINE COMPARISON v0.6.19 vs v0.6.20

### KEY-263 isolation DEV strict

| Indicateur | v0.6.19 baseline | v0.6.20 PH-20.8 | Delta | Verdict |
|---|---|---|---|---|
| api-dev.keybuzz.io | 2 | 2 | 0 | **OK isolation DEV preservee** |
| api.keybuzz.io seul (PROD URL) | 0 | 0 | 0 | OK pas de leak PROD |
| client-dev.keybuzz.io | 3 | 3 | 0 | OK preserve |

### Marketing IDs preserves

| Indicateur | v0.6.19 | v0.6.20 | Delta | Verdict |
|---|---|---|---|---|
| GA G-R3QQDYEBFG | 18 | 18 | 0 | OK preserve |
| SGTM t.keybuzz.pro | 39 | 39 | 0 | OK preserve |
| LinkedIn 9969977 | 18 | 18 | 0 | OK preserve |
| Clarity wuk12h9i33 | 0 | 0 | 0 | OK preserve (baseline website = ID Clarity non baked dans bundle DEV ; comportement attendu, KEY-322 activation Clarity Website non-DEV) |

### Tracking helpers preserves

| Indicateur | v0.6.19 | v0.6.20 | Delta | Verdict |
|---|---|---|---|---|
| marketing_cta_click (PH-20.3) | 1 | 1 | 0 | OK preserve |
| trackMarketingClick (PH-20.3) | 15 | 15 | 0 | OK preserve |

### CMP elements preserves

| Indicateur | v0.6.19 | v0.6.20 | Delta | Verdict |
|---|---|---|---|---|
| "Nous respectons votre vie" (h2) | 2 | 2 | 0 | OK preserve |
| "Accepter" (button CMP) | 1 | 1 | 0 | OK preserve |
| "Refuser les cookies optionnels" | 2 | 2 | 0 | OK preserve |
| "politique cookies" (link) | 2 | 2 | 0 | OK preserve |
| "politique de confidentialit" (link) | 7 | 7 | 0 | OK preserve |
| "Microsoft Clarity" (desktop copy preserve) | 16 | 16 | 0 | OK preserve |

### Nouveaux markers PH-20.8 LIVE bundle

| Indicateur | v0.6.19 | v0.6.20 | Delta | Verdict |
|---|---|---|---|---|
| **`max-h-[60vh]`** (mobile compact CSS) | 0 | **2** | **+2** | **OK LIVE** |
| **`sm:hidden`** (mobile-only copy class) | 0 | **2** | **+2** | **OK LIVE** |
| **copy mobile "cookies necessaires au service"** | 0 | **2** | **+2** | **OK LIVE** |

### No fake events delta

| Pattern | v0.6.19 | v0.6.20 | Delta | Verdict |
|---|---|---|---|---|
| Lead | 3 | 3 | 0 | OK preexistants (faux positifs `leading-*` Tailwind classes) |
| Purchase | 0 | 0 | 0 | OK |
| StartTrial | 0 | 0 | 0 | OK |
| CompletePayment | 0 | 0 | 0 | OK |
| SubmitForm | 0 | 0 | 0 | OK |
| InitiateCheckout | 0 | 0 | 0 | OK |

Aucun fake event ajoute par PH-20.8. Tous patterns preexistants identiques baseline.

## E5 GHCR COLLISION + RUNTIME PRESERVE

| Item | Valeur | Verdict |
|---|---|---|
| GHCR collision tag v0.6.20-cmp-mobile-polish-dev | manifest unknown | LIBRE (aucun push) |
| Runtime Website DEV | v0.6.19-cta-tracking-dev | INCHANGE |
| Runtime Website PROD | v0.6.19-cta-tracking-prod | INCHANGE |

## E6 CLEANUP WORKTREE

| Action | Resultat |
|---|---|
| `git worktree remove --force` | OK |
| `rm -rf /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.8/` | OK |
| Worktree present apres cleanup ? | NON |

## RUNTIME PRESERVE FINAL

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-website | keybuzz-website-dev | v0.6.19-cta-tracking-dev | INCHANGE |
| keybuzz-website | keybuzz-website-prod | v0.6.19-cta-tracking-prod | INCHANGE |
| keybuzz-client | keybuzz-client-dev/-prod | v3.5.210 / v3.5.201 | INCHANGES |
| keybuzz-api | keybuzz-api-dev/-prod | v3.5.252 / v3.5.251 | INCHANGES |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGES |

Aucun deploy. Aucun kubectl apply. Aucun docker push.

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR (tag DEV cible LIBRE).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source au-dela du commit bb49798.
- AUCUN secret / token affiche.
- AUCUNE mutation DB / Stripe.
- AUCUN faux register / checkout.
- AUCUNE modification Client/API/Admin.
- AUCUN changement IDs analytics.
- AUCUN changement logique consentement tracking.
- AUCUN dark pattern.
- Bastion install-v3 (46.62.171.61) uniquement.

## NO FAKE METRICS / NO FAKE EVENTS

- Build container Docker uniquement.
- 0 fake event delta vs baseline v0.6.19.
- Aucun pixel touche.
- Aucun checkout reel.
- Aucune mutation DB.
- "Lead" detecte = faux positifs `leading-relaxed`, `leading-tight`, etc. (Tailwind utility classes line-height).

## ROLLBACK PLAN

Si push + apply DEV provoquent regression : rollback tag DEV actuel `v0.6.19-cta-tracking-dev`. Procedure : editer manifest -> revenir v0.6.19 + commit + push + apply.

INTERDIT : kubectl set image / git reset --hard / git clean.

## GAPS

1. Aucun. Build clean, OCI conformes, isolation DEV stricte, nouveaux markers PH-20.8 LIVE, baseline 100% preserve, 0 fake event delta.
2. QA navigateur Ludovic mobile + desktop recommandee post-APPLY DEV : tester viewports 360px/414px/768px/1024px+ pour valider hero visible mobile + buttons accessibles + Accepter/Refuser equilibres.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD WEBSITE CMP MOBILE POLISH DEV READY PH-SAAS-T8.12AS.20.8 |
| Bastion | install-v3 46.62.171.61 |
| Source commit Website | bb49798 |
| Tag image cible | v0.6.20-cmp-mobile-polish-dev |
| Image ID local | sha256:5bd890c7544819243f40fad8499bbe3713880d2460d010ba77d47c212ef4aea8 |
| Image size | 214 MB |
| OCI labels KEY-308 | 5/5 OK |
| KEY-263 isolation DEV | OK (api-dev=2, api-prod=0) |
| Baseline marketing IDs preserves | GA=18, SGTM=39, LinkedIn=18, Clarity=0 (baseline) |
| CMP elements preserves | Nous respectons=2, Accepter=1, Refuser=2, politique cookies=2, politique confidentialite=7 |
| PH-20.8 nouveaux markers | LIVE (max-h-[60vh]=2, sm:hidden=2, copy mobile=2) |
| Desktop copy preservee | Microsoft Clarity=16 |
| Tracking helpers preserves | marketing_cta_click=1, trackMarketingClick=15 |
| Fake events delta | 0 |
| GHCR collision tag DEV cible | LIBRE |
| Worktree | nettoyee |
| Runtime Website DEV+PROD | INCHANGES |
| Runtime Client+API+Admin | INCHANGES |
| Docker push | AUCUN |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.8-WEBSITE-CMP-MOBILE-POLISH-BUILD-DEV-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE WEBSITE CMP MOBILE POLISH DEV PH-SAAS-T8.12AS.20.8`

STOP.
