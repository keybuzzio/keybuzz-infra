# PH-SAAS-T8.12AS.20.8-WEBSITE-CMP-MOBILE-POLISH-BUILD-PROD-01

> Date : 2026-05-22
> Linear : KEY-344 (primary) ; KEY-337 (parent PH-20) ; KEY-338/KEY-340 (related tracking)
> Phase : PH-SAAS-T8.12AS.20.8 WEBSITE CMP MOBILE POLISH BUILD PROD
> Environnement : PROD build only (aucun docker push, aucun deploy)

## VERDICT

GO BUILD WEBSITE CMP MOBILE POLISH PROD READY PH-SAAS-T8.12AS.20.8

- Image Docker locale `ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-prod` build OK depuis worktree --detach commit `bb49798`.
- Image ID local : `sha256:e804b22e0b83a17f9773c6db687e880d07aaa28a441ab9b80566ee73bed5ca5e` size 214 MB.
- OCI labels KEY-308 : 5/5 OK (revision=bb49798).
- Build args PROD explicites tous fournis (9 args : SITE_MODE=production, CLIENT_APP_URL=https://client.keybuzz.io, GA=G-R3QQDYEBFG, SGTM=t.keybuzz.pro, LinkedIn=9969977, Clarity vide, Meta vide, TikTok vide, CONTACT_API=https://api.keybuzz.io/api/public/contact).
- **KEY-263 isolation PROD STRICT** : api-prod=2 preserve, api-dev=0 (aucun leak DEV en PROD).
- Baseline v0.6.19 PROD 100% preserve : GA=18, SGTM=39, LinkedIn=18, Clarity=0 (baseline website), client.keybuzz.io=31, client-dev=0, CMP CMP strings counts identiques.
- Tracking helpers preserves : marketing_cta_click=1, trackMarketingClick=15.
- PH-20.8 nouveaux markers PROD LIVE bundle :
  - `max-h-[60vh]` (mobile compact CSS) : 0 -> **2** (+2)
  - `sm:hidden` (mobile-only copy class) : 0 -> **2** (+2)
  - copy mobile "cookies necessaires" : 0 -> **2** (+2)
- CMP elements preserves : Nous respectons=2, Refuser=2, politique cookies=2, politique confidentialite=7, Microsoft Clarity desktop=16.
- isPreview baked = 0 (PROD mode confirme, pas de leak preview).
- contact api-prod endpoint = 2 (KEY-263 PROD URL preserve).
- 0 fake event delta vs baseline v0.6.19 PROD (Lead=3 preexistants = `leading-*` Tailwind faux positifs identiques).
- GHCR tag cible LIBRE (`manifest unknown`). Aucun docker push.
- Runtime Website DEV `v0.6.20-cmp-mobile-polish-dev` INCHANGE.
- Runtime Website PROD `v0.6.19-cta-tracking-prod` INCHANGE.
- Worktree nettoyee.

STOP avant docker push GHCR.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-22 |
| keybuzz-website HEAD | bb49798 (PH-20.8 source) |
| keybuzz-infra HEAD | f17e808 (post APPLY DEV PH-20.8 rapport) |
| Runtime Website DEV avant | v0.6.20-cmp-mobile-polish-dev (PH-20.8 APPLY DEV live) |
| Runtime Website PROD avant | v0.6.19-cta-tracking-prod |
| GHCR collision tag v0.6.20-cmp-mobile-polish-prod | manifest unknown (LIBRE) |

## E1 BASELINE PROD AUDIT v0.6.19-cta-tracking-prod

| Indicateur | Baseline PROD | Verdict |
|---|---|---|
| api.keybuzz.io (KEY-263 PROD URL) | 2 | reference |
| api-dev.keybuzz.io | 0 | reference isolation PROD |
| client.keybuzz.io | 31 | reference (URLs Client App PROD) |
| client-dev.keybuzz.io | 0 | reference pas de leak DEV |
| GA G-R3QQDYEBFG | 18 | reference |
| SGTM t.keybuzz.pro | 39 | reference |
| LinkedIn 9969977 | 18 | reference |
| Clarity wuk12h9i33 | 0 | reference (baseline website non-bake KEY-302 Client uniquement) |
| marketing_cta_click | 1 | reference PH-20.3 |
| trackMarketingClick | 15 | reference PH-20.3 |
| Nous respectons votre vie | 2 | reference CMP h2 |
| Refuser les cookies optionnels | 2 | reference CMP button |
| politique cookies | 2 | reference link |
| politique de confidentialit | 7 | reference link |
| Microsoft Clarity (desktop copy) | 16 | reference desktop copy |
| isPreview baked | 0 | reference PROD mode |
| contact api-prod endpoint | 2 | reference NEXT_PUBLIC_CONTACT_API_URL=https://api.keybuzz.io/api/public/contact |

## E2 WORKTREE BUILD-FROM-GIT

| Indicateur | Valeur |
|---|---|
| Worktree path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.8-PROD/keybuzz-website |
| Worktree detache sur | bb49798 |
| Worktree dirty | 0 |
| Source PH-20.8 worktree | max-h-[60vh] l.76, sm:hidden l.90, copy mobile present |

## E3 DOCKER BUILD PROD

| Item | Valeur |
|---|---|
| Build args explicites | 9 |
| - NEXT_PUBLIC_SITE_MODE | production |
| - NEXT_PUBLIC_CLIENT_APP_URL | https://client.keybuzz.io |
| - NEXT_PUBLIC_GA_ID | G-R3QQDYEBFG |
| - NEXT_PUBLIC_SGTM_URL | https://t.keybuzz.pro |
| - NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 |
| - NEXT_PUBLIC_CLARITY_PROJECT_ID | (empty, baseline 0 preserve) |
| - NEXT_PUBLIC_META_PIXEL_ID | (empty, baseline preserve) |
| - NEXT_PUBLIC_TIKTOK_PIXEL_ID | (empty, baseline preserve) |
| - NEXT_PUBLIC_CONTACT_API_URL | https://api.keybuzz.io/api/public/contact |
| Exit code | 0 |
| Image tag local | ghcr.io/keybuzzio/keybuzz-website:v0.6.20-cmp-mobile-polish-prod |
| Image ID | sha256:e804b22e0b83a17f9773c6db687e880d07aaa28a441ab9b80566ee73bed5ca5e |
| Image size | 214 MB |
| Created | 2026-05-22T09:02:55Z |

## E4 OCI LABELS KEY-308 (5/5)

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.revision | bb497984c53c45452cc96a58eed7e3a9dd3ad9f1 | OK commit PH-20.8 |
| org.opencontainers.image.created | 2026-05-22T09:02:18Z | OK |
| org.opencontainers.image.version | v0.6.20-cmp-mobile-polish-prod | OK |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-website | OK |
| org.opencontainers.image.title | keybuzz-website | OK |

KEY-309 tag immutable + suffixe `-prod` conforme.

## E5 BUNDLE AUDIT + BASELINE COMPARISON PROD v0.6.19 -> v0.6.20

### KEY-263 isolation PROD stricte

| Indicateur | v0.6.19 baseline | v0.6.20 PH-20.8 | Delta | Verdict |
|---|---|---|---|---|
| api.keybuzz.io (PROD URL) | 2 | 2 | 0 | **OK isolation PROD preservee** |
| api-dev.keybuzz.io | 0 | 0 | 0 | **OK pas de leak DEV en PROD** |
| client.keybuzz.io | 31 | 31 | 0 | OK preserve |
| client-dev.keybuzz.io | 0 | 0 | 0 | OK |

### Marketing IDs preserves

| Indicateur | v0.6.19 | v0.6.20 | Delta | Verdict |
|---|---|---|---|---|
| GA G-R3QQDYEBFG | 18 | 18 | 0 | OK preserve |
| SGTM t.keybuzz.pro | 39 | 39 | 0 | OK preserve |
| LinkedIn 9969977 | 18 | 18 | 0 | OK preserve |
| Clarity wuk12h9i33 | 0 | 0 | 0 | OK preserve baseline (Website non-bake KEY-302 Client) |

### Tracking helpers preserves PH-20.3

| Indicateur | v0.6.19 | v0.6.20 | Delta | Verdict |
|---|---|---|---|---|
| marketing_cta_click | 1 | 1 | 0 | OK preserve |
| trackMarketingClick | 15 | 15 | 0 | OK preserve |

### CMP elements preserves

| Indicateur | v0.6.19 | v0.6.20 | Delta | Verdict |
|---|---|---|---|---|
| "Nous respectons votre vie" (h2) | 2 | 2 | 0 | OK preserve |
| "Refuser les cookies optionnels" | 2 | 2 | 0 | OK preserve |
| "politique cookies" | 2 | 2 | 0 | OK preserve |
| "politique de confidentialit" | 7 | 7 | 0 | OK preserve |
| "Microsoft Clarity" (desktop copy preserve) | 16 | 16 | 0 | OK preserve |

### PH-20.8 nouveaux markers LIVE bundle PROD

| Indicateur | v0.6.19 | v0.6.20 | Delta | Verdict |
|---|---|---|---|---|
| **`max-h-[60vh]`** (mobile compact CSS) | 0 | **2** | **+2** | **OK LIVE PROD** |
| **`sm:hidden`** (mobile-only copy class) | 0 | **2** | **+2** | **OK LIVE PROD** |
| **copy mobile "cookies necessaires au service"** | 0 | **2** | **+2** | **OK LIVE PROD** |

### Mode PROD verify

| Indicateur | v0.6.19 | v0.6.20 | Verdict |
|---|---|---|---|
| isPreview baked | 0 | 0 | OK PROD mode confirme (SITE_MODE=production) |
| contact api-prod endpoint | 2 | 2 | OK PROD CONTACT_API URL preserve |

### No fake events delta

| Pattern | v0.6.19 | v0.6.20 | Delta | Verdict |
|---|---|---|---|---|
| Lead | 3 | 3 | 0 | OK preexistants (Tailwind `leading-*` faux positifs identiques) |
| Purchase | 0 | 0 | 0 | OK |
| StartTrial | 0 | 0 | 0 | OK |
| CompletePayment | 0 | 0 | 0 | OK |
| SubmitForm | 0 | 0 | 0 | OK |
| InitiateCheckout | 0 | 0 | 0 | OK |

Aucun fake event ajoute par PH-20.8 en PROD. Tous patterns preexistants identiques baseline.

## E6 GHCR COLLISION + RUNTIME PRESERVE

| Item | Valeur | Verdict |
|---|---|---|
| GHCR collision tag v0.6.20-cmp-mobile-polish-prod | manifest unknown | LIBRE (aucun push) |
| Runtime Website DEV | v0.6.20-cmp-mobile-polish-dev | INCHANGE |
| Runtime Website PROD | v0.6.19-cta-tracking-prod | INCHANGE |

## E7 CLEANUP WORKTREE

| Action | Resultat |
|---|---|
| `git worktree remove --force` | OK |
| `rm -rf /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.8-PROD/` | OK |
| Worktree present apres cleanup ? | NON |

## RUNTIME PRESERVE FINAL

| Service | Namespace | Image runtime | Verdict |
|---|---|---|---|
| keybuzz-website | keybuzz-website-dev | v0.6.20-cmp-mobile-polish-dev | INCHANGE |
| keybuzz-website | keybuzz-website-prod | v0.6.19-cta-tracking-prod | INCHANGE |
| keybuzz-client | keybuzz-client-dev/-prod | v3.5.210 / v3.5.201 | INCHANGES |
| keybuzz-api | keybuzz-api-dev/-prod | v3.5.252 / v3.5.251 | INCHANGES |
| keybuzz-admin-v2 | -dev/-prod | v2.12.2-* | INCHANGES |

Aucun deploy. Aucun kubectl apply. Aucun docker push.

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR (tag PROD cible LIBRE).
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source au-dela du commit bb49798.
- AUCUN secret / token affiche.
- AUCUNE mutation DB / Stripe.
- AUCUN faux register / checkout / lead.
- AUCUNE modification Client/API/Admin.
- AUCUN changement IDs analytics.
- AUCUN changement logique consentement tracking.
- AUCUN dark pattern.
- Bastion install-v3 (46.62.171.61) uniquement.

## NO FAKE METRICS / NO FAKE EVENTS

- Build container Docker uniquement.
- 0 fake event delta vs baseline v0.6.19 PROD.
- Aucun pixel touche.
- Aucun checkout reel.
- Aucune mutation DB.
- "Lead" detecte (=3) = faux positifs Tailwind `leading-*` (line-height utilities) identiques baseline et v0.6.20.

## ROLLBACK PLAN (anticipation phase PUSH IMAGE PROD)

Si push + apply PROD provoquent regression :
1. Rollback tag PROD actuel `v0.6.19-cta-tracking-prod`.
2. Procedure GitOps : editer `k8s/website-prod/deployment.yaml` -> revenir v0.6.19 + commit + push + apply.

INTERDIT : kubectl set image / git reset --hard / git clean.

## GAPS

1. Aucun. Build clean, OCI conformes, isolation PROD stricte (api.keybuzz.io PROD URL preserve, api-dev=0), nouveaux markers PH-20.8 PROD LIVE, baseline 100% preserve, 0 fake event delta.
2. QA navigateur Ludovic en PROD recommandee post-APPLY PROD (https://keybuzz.pro mobile + desktop) pour valider visuel CMP : hero visible sous le bandeau mobile, copy compacte LIVE, Accepter/Refuser equilibres, liens politiques accessibles.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD WEBSITE CMP MOBILE POLISH PROD READY PH-SAAS-T8.12AS.20.8 |
| Bastion | install-v3 46.62.171.61 |
| Source commit Website | bb49798 |
| Tag image cible PROD | v0.6.20-cmp-mobile-polish-prod |
| Image ID local | sha256:e804b22e0b83a17f9773c6db687e880d07aaa28a441ab9b80566ee73bed5ca5e |
| Image size | 214 MB |
| OCI labels KEY-308 | 5/5 OK |
| Build args PROD explicites | 9/9 OK |
| KEY-263 isolation PROD | OK (api-prod=2, api-dev=0) |
| Baseline marketing IDs preserves | GA=18, SGTM=39, LinkedIn=18, Clarity=0 (baseline) |
| CMP elements preserves | Nous respectons=2, Refuser=2, politique cookies=2, politique confidentialite=7, Microsoft Clarity=16 |
| PH-20.8 nouveaux markers PROD | LIVE (max-h-[60vh]=2, sm:hidden=2, copy mobile=2) |
| Tracking helpers preserves | marketing_cta_click=1, trackMarketingClick=15 |
| Mode PROD verify | isPreview=0 (production), contact api-prod endpoint=2 |
| Fake events delta | 0 |
| GHCR collision tag PROD cible | LIBRE |
| Worktree | nettoyee |
| Runtime Website DEV+PROD | INCHANGES |
| Runtime Client+API+Admin | INCHANGES |
| Docker push | AUCUN |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.8-WEBSITE-CMP-MOBILE-POLISH-BUILD-PROD-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE WEBSITE CMP MOBILE POLISH PROD PH-SAAS-T8.12AS.20.8`

STOP.
