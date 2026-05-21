# PH-SAAS-T8.12AS.20.3-WEBSITE-CTA-TRACKING-BUILD-DEV-01

> Date : 2026-05-21
> Linear : KEY-340 (primary) ; KEY-337 (parent) ; KEY-338, KEY-339, KEY-341 (related)
> Phase : PH-SAAS-T8.12AS.20.3 WEBSITE CTA TRACKING BUILD DEV
> Environnement : DEV build only / aucun docker push / aucun deploy

## VERDICT

GO BUILD WEBSITE CTA TRACKING DEV READY PH-SAAS-T8.12AS.20.3

- Image Docker locale construite depuis worktree detache propre sur commit `6af74a2`.
- Tag : `ghcr.io/keybuzzio/keybuzz-website:v0.6.19-cta-tracking-dev`.
- Image ID : `sha256:9802b2602e5dba7549f84c9b5900abe8bcea859769f469b5e25df9ea7c17c4dc`.
- Build args DEV iso baseline v0.6.18 : NEXT_PUBLIC_SITE_MODE=preview, GA_ID=G-R3QQDYEBFG, SGTM=t.keybuzz.pro, META=1234164602194748, TIKTOK=D7PT12JC77U44OJIPC10, LINKEDIN=9969977, CONTACT_API=api-dev.keybuzz.io.
- OCI labels KEY-308 5/5 OK.
- Bundle DEV : KEY-263 isolation respectee (api-dev=2, api.keybuzz.io seul=0).
- Bundle DEV : marketing IDs preserves iso baseline (delta 0 sur G-R3QQDYEBFG, t.keybuzz.pro, Meta, TikTok, LinkedIn).
- Bundle DEV : +14 occurrences `trackMarketingClick` (26 -> 40, refletant 11 callsites + import statements).
- Bundle DEV : 7 nouveaux cta_id PH-20.3 presents (about x3 + home amazon + features amazon + footer templates x2).
- Bundle DEV : MarketingCTA wrapper preserve (36/36).
- Bundle DEV : 0 nouveau fake event (Lead, Purchase, StartTrial, CompletePayment, SubmitForm, InitiateCheckout, AW- tous 0).
- Runtime Website DEV `v0.6.18-ga4-cleanup-dev` INCHANGE.
- Runtime Website PROD `v0.6.18-ga4-cleanup-prod` INCHANGE.
- Runtime Client DEV/PROD INCHANGES.

STOP avant docker push GHCR.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-21 14:35:56 |
| keybuzz-website branch | main |
| keybuzz-website HEAD | 6af74a2 feat(website): track marketing CTA |
| keybuzz-website local==origin | OK 6af74a24be372a54319e1e65722841bbfda4d234 |
| keybuzz-website dirty | 0 |
| keybuzz-infra HEAD | aac3720 (rapport PH-20.3 source) |
| GHCR collision tag v0.6.19-cta-tracking-dev | manifest unknown (LIBRE OK) |

### Runtime avant build

| Service | Namespace | Image runtime |
|---|---|---|
| keybuzz-website | keybuzz-website-dev | v0.6.18-ga4-cleanup-dev |
| keybuzz-website | keybuzz-website-prod | v0.6.18-ga4-cleanup-prod |
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod |

## E1 WORKTREE GIT --DETACH

| Item | Valeur |
|---|---|
| Path | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.3/keybuzz-website |
| HEAD | 6af74a24be372a54319e1e65722841bbfda4d234 |
| Dirty | 0 |
| Source patch verification | trackMarketingClick 27 callsites (source) + MarketingCTA 34 (wrapper + ses occurrences) |

## E2 DOCKER BUILD DEV

### Build args iso baseline v0.6.18

| Build arg | Valeur | Source |
|---|---|---|
| NEXT_PUBLIC_SITE_MODE | preview | manifest k8s/website-dev override |
| NEXT_PUBLIC_CLIENT_APP_URL | https://client-dev.keybuzz.io | manifest env override |
| NEXT_PUBLIC_GA_ID | G-R3QQDYEBFG | baseline (18 occurrences bundle v0.6.18) |
| NEXT_PUBLIC_SGTM_URL | https://t.keybuzz.pro | baseline (54 occurrences) |
| NEXT_PUBLIC_META_PIXEL_ID | 1234164602194748 | baseline (2 occurrences) |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | D7PT12JC77U44OJIPC10 | baseline (2 occurrences) |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 | baseline (2 occurrences) |
| NEXT_PUBLIC_CONTACT_API_URL | https://api-dev.keybuzz.io/api/public/contact | baseline DEV |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | (omis, default vide) | baseline DEV PAS Clarity Website |
| GIT_COMMIT_SHA | 6af74a24be372a54319e1e65722841bbfda4d234 | source commit |
| BUILD_TIME | 2026-05-21T14:53:07Z | UTC ISO |

### Build result

| Item | Valeur |
|---|---|
| Build exit code | 0 |
| Image tag local | ghcr.io/keybuzzio/keybuzz-website:v0.6.19-cta-tracking-dev |
| Image ID | sha256:9802b2602e5dba7549f84c9b5900abe8bcea859769f469b5e25df9ea7c17c4dc |
| Image size | 213 668 626 bytes (204 MiB) |
| Worktree cleanup post-build | OK |

### OCI labels KEY-308

| OCI label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.revision | 6af74a24be372a54319e1e65722841bbfda4d234 | OK |
| org.opencontainers.image.created | 2026-05-21T14:53:07Z | OK |
| org.opencontainers.image.version | v0.6.19-cta-tracking-dev | OK |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-website | OK |
| org.opencontainers.image.title | keybuzz-website | OK |

5/5 OK.

## E3 BUNDLE VERIFY DEV

### Comparaison baseline v0.6.18 vs v0.6.19

| Pattern | v0.6.18 baseline | v0.6.19 new | Delta | Verdict |
|---|---|---|---|---|
| api-dev.keybuzz.io | 2 | 2 | 0 | OK KEY-263 isolation DEV |
| api.keybuzz.io seul (NOT api-dev) | 0 | 0 | 0 | OK |
| G-R3QQDYEBFG (GA4) | 18 | 18 | 0 | OK marketing IDs preserves |
| t.keybuzz.pro (SGTM) | 54 | 54 | 0 | OK |
| 1234164602194748 (Meta Pixel) | 2 | 2 | 0 | OK |
| D7PT12JC77U44OJIPC10 (TikTok) | 2 | 2 | 0 | OK |
| 9969977 (LinkedIn partner) | 2 | 2 | 0 | OK |
| wrff07upjx (Clarity Website) | 0 | 0 | 0 | OK iso DEV pas de Clarity Website |
| marketing_cta_click (event name) | 1 | 1 | 0 | OK helper source unique |
| trackMarketingClick (callsite) | 26 | **40** | **+14** | OK refletant 11 callsites + import statements |
| MarketingCTA (wrapper) | 36 | 36 | 0 | OK preserve home 8/8 + features 8/8 + composant declaration |
| about_hero_secondary_features | 0 | **2** | **+2** | OK nouveau cta_id |
| about_final_primary_features | 0 | **2** | **+2** | OK nouveau cta_id |
| about_final_secondary_pricing | 0 | **2** | **+2** | OK nouveau cta_id |
| homepage_reassurance_amazon_link | 0 | **2** | **+2** | OK nouveau cta_id |
| features_marketplaces_amazon_link | 0 | **2** | **+2** | OK nouveau cta_id |
| footer_product_ template | 0 | **2** | **+2** | OK template dynamique footer product map |
| footer_amazon_ template | 0 | **2** | **+2** | OK template dynamique footer amazon map |

Note : chaque cta_id apparait 2 fois dans le bundle (server + client chunks Next.js).

### No fake events delta

| Event | v0.6.18 baseline | v0.6.19 new | Delta | Verdict |
|---|---|---|---|---|
| `"Lead"` | 0 | 0 | 0 | OK |
| `"Purchase"` | 0 | 0 | 0 | OK |
| `"StartTrial"` | 0 | 0 | 0 | OK |
| `"CompletePayment"` | 0 | 0 | 0 | OK |
| `"SubmitForm"` | 0 | 0 | 0 | OK |
| `"InitiateCheckout"` | 0 | 0 | 0 | OK |
| AW- direct | 0 | 0 | 0 | OK |

DELTA STRICT vs baseline v0.6.18 = uniquement +14 trackMarketingClick + 7 nouveaux cta_id (5 ID hard-coded + 2 templates dynamiques). AUCUN nouvel evenement marketing fabrique. AUCUNE regression Marketing IDs. AUCUNE regression PH-19.x/Clarity Website.

## E4 RUNTIME PRESERVE

| Service | Image runtime apres build | Verdict |
|---|---|---|
| keybuzz-website-dev | v0.6.18-ga4-cleanup-dev | INCHANGE (build local seulement) |
| keybuzz-website-prod | v0.6.18-ga4-cleanup-prod | INCHANGE |
| keybuzz-client-dev | v3.5.206-clarity-register-dev | INCHANGE |
| keybuzz-client-prod | v3.5.200-clarity-register-prod | INCHANGE |
| keybuzz-api-dev | v3.5.251-register-cro-dev | INCHANGE |
| keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | INCHANGE |
| keybuzz-admin-v2 dev/prod | v2.12.2-media-buyer-lp-domain-qa-* | INCHANGE |

Aucun docker push. Aucun deploy. Aucun kubectl apply.

## E5 SIGNAL TABLE

| Signal | Type | Source | Destination | Statut bundle DEV v0.6.19 |
|---|---|---|---|---|
| marketing_cta_click | client GA4 | trackMarketingClick helper (consent-aware) | GA4 G-R3QQDYEBFG via SGTM t.keybuzz.pro | ACTIF, couverture +11 callsites vs v0.6.18 |
| GA4 pageview | client GA4 | gtag init via Analytics.tsx | GA4 + SGTM | INCHANGE |
| Meta Pixel ViewContent | client Meta | fbq init via Analytics.tsx (NEXT_PUBLIC_META_PIXEL_ID=1234164602194748) | Meta business | INCHANGE iso baseline |
| TikTok ttq | client TikTok | ttq.load (D7PT12JC77U44OJIPC10) | TikTok Events API client-side | INCHANGE |
| LinkedIn Insight | client LinkedIn | _linkedin_partner_id=9969977 | LinkedIn | INCHANGE |
| Clarity Website | UX analytics | aucun (Clarity Website non active DEV par decision) | aucun | INACTIF iso baseline DEV |
| Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- | conversion publicitaire | aucun ajout cote Website | aucun | INACTIF, INCHANGE |

## CONFIRMATIONS SECURITE

- AUCUN docker push GHCR.
- AUCUN deploy DEV ou PROD.
- AUCUN kubectl apply / set / patch / edit.
- AUCUN manifest GitOps modifie.
- AUCUN patch source (deja commit dans PH-20.3 source).
- AUCUN secret / token affiche.
- AUCUN `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/` ouvert.
- AUCUN evenement test envoye vers GA4/Meta/TikTok/LinkedIn/Google Ads.
- AUCUN faux Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout ajoute.
- AUCUN Linear ticket cree, ferme, ou statut modifie automatiquement.
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK PLAN

Build local seulement, aucun rollback runtime necessaire.

Rollback de la phase build :

1. Suppression image locale : `docker rmi ghcr.io/keybuzzio/keybuzz-website:v0.6.19-cta-tracking-dev`.

Pour les phases ulterieures (apres APPLY DEV) :

- Rollback tag DEV runtime actuel : `v0.6.18-ga4-cleanup-dev` (digest GHCR `sha256:63882ba57960726fe8689784e0d3325be327019acc466e8239635588fb47baec`).

## GAPS

1. Lint baseline 63 erreurs preexistantes (apostrophes francaises content original) maintenues. Hors scope PH-20.3 (cleanup possible en phase ulterieure de polish lint).
2. Marketing IDs reproduisent baseline DEV (Meta/TikTok/LinkedIn pixels ACTIFS DEV iso v0.6.18). Si Ludovic veut desactiver Meta/TikTok/LinkedIn DEV en phase ulterieure, ouvrir un PH distinct.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO BUILD WEBSITE CTA TRACKING DEV READY PH-SAAS-T8.12AS.20.3 |
| Bastion | install-v3 46.62.171.61 |
| Source commit Website | 6af74a2 |
| Tag image cible | v0.6.19-cta-tracking-dev |
| Image ID local | sha256:9802b2602e5dba7549f84c9b5900abe8bcea859769f469b5e25df9ea7c17c4dc |
| Image size | 214 MB |
| OCI labels | 5/5 OK |
| KEY-263 isolation DEV | api-dev=2 / api.keybuzz.io seul=0 |
| Marketing IDs preserves (delta 0 vs v0.6.18) | GA4 18, SGTM 54, Meta 2, TikTok 2, LinkedIn 2 |
| Delta trackMarketingClick | +14 (26 -> 40) |
| Nouveaux cta_id PH-20.3 | 7 (about x3 + home amazon + features amazon + footer templates x2) |
| MarketingCTA wrapper | 36 preserves |
| No fake events delta | 0 nouveau Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- |
| Runtime Website DEV | v0.6.18-ga4-cleanup-dev INCHANGE |
| Runtime Website PROD | v0.6.18-ga4-cleanup-prod INCHANGE |
| Runtime Client DEV/PROD | INCHANGES |
| Worktree cleanup | OK |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.3-WEBSITE-CTA-TRACKING-BUILD-DEV-01.md` |

### Prochaine phrase GO attendue

`GO PUSH IMAGE WEBSITE CTA TRACKING DEV PH-SAAS-T8.12AS.20.3`

STOP.
