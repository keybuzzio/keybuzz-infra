# PH-SAAS-T8.12AS.20.3-WEBSITE-CTA-TRACKING-TRAIN-PROD-01

> Date : 2026-05-21
> Linear : KEY-340 (primary) ; KEY-337 (parent) ; KEY-338, KEY-339, KEY-341 (related)
> Phase : PH-SAAS-T8.12AS.20.3 WEBSITE CTA TRACKING TRAIN PROD
> Environnement : PROD train integre (build + push + GitOps apply + smoke)

## VERDICT

GO TRAIN PROD WEBSITE CTA TRACKING READY PH-SAAS-T8.12AS.20.3

- Image PROD construite from-git commit `6af74a2` avec build args iso baseline v0.6.18 (Clarity wrff07upjx active Website seulement).
- Tag `ghcr.io/keybuzzio/keybuzz-website:v0.6.19-cta-tracking-prod` push GHCR.
- Manifest digest GHCR : `sha256:1e8d73bb7e713473dca3beafa6d1386e412de5f2f934da4ec43075fbdf0b3dfb`.
- Config digest match local==GHCR : `sha256:de63e0a4c2ef2d77272f4f3175fd19b753553e549aa88311fc3c42bbbd6623d7`.
- Bundle PROD audit : Marketing IDs preserves (GA4 18, SGTM 54, Meta 2, TikTok 2, LinkedIn 18, Clarity wrff07upjx 2, api.keybuzz.io 2, api-dev 0). +14 trackMarketingClick. 7 nouveaux cta_id PH-20.3. 0 fake event delta.
- keybuzz-infra HEAD apres train : `ff3a4d9` (ops manifest PROD).
- Pods PROD : `keybuzz-website-6cf454595c-n9bsg` + `keybuzz-website-6cf454595c-qf8bj` Ready 2/2.
- Runtime digest PROD : `sha256:1e8d73bb7e713473dca3beafa6d1386e412de5f2f934da4ec43075fbdf0b3dfb` MATCH GHCR push.
- Smoke Website PROD 5/5 HTTP 200 via www.keybuzz.pro (/, /pricing, /about, /features, /amazon).
- Bundle live PROD audit : 12 trackMarketingClick + 6 nouveaux cta_id PH-20.3 detectes chunks home + about.
- Runtime Website DEV `v0.6.19-cta-tracking-dev` INCHANGE.
- Runtime Client DEV/PROD INCHANGES.
- Runtime API DEV/PROD INCHANGES.
- Runtime Admin DEV/PROD INCHANGES.
- Reserve R2 PH-20.1 ADRESSEE en PROD.

## E0 PREFLIGHT

| Indicateur | Valeur |
|---|---|
| Bastion | install-v3 46.62.171.61 |
| Date UTC | 2026-05-21 15:59:58 |
| keybuzz-website branche | main |
| keybuzz-website HEAD | 6af74a2 feat(website): track marketing CTA |
| keybuzz-website local==origin | OK |
| keybuzz-website dirty | 0 |
| keybuzz-infra HEAD avant train | 8ee5b76 (rapport APPLY DEV) |
| GHCR collision tag v0.6.19-cta-tracking-prod | `manifest unknown` LIBRE OK |

## E1 BUILD WEBSITE PROD

### Build args (iso baseline v0.6.18 PROD)

| Build arg | Valeur | Verdict |
|---|---|---|
| NEXT_PUBLIC_SITE_MODE | production | OK |
| NEXT_PUBLIC_CLIENT_APP_URL | https://client.keybuzz.io | OK |
| NEXT_PUBLIC_GA_ID | G-R3QQDYEBFG | OK |
| NEXT_PUBLIC_SGTM_URL | https://t.keybuzz.pro | OK |
| NEXT_PUBLIC_META_PIXEL_ID | 1234164602194748 | OK |
| NEXT_PUBLIC_TIKTOK_PIXEL_ID | D7PT12JC77U44OJIPC10 | OK |
| NEXT_PUBLIC_LINKEDIN_PARTNER_ID | 9969977 | OK |
| NEXT_PUBLIC_CLARITY_PROJECT_ID | wrff07upjx | OK (Clarity Website active iso baseline) |
| NEXT_PUBLIC_CONTACT_API_URL | https://api.keybuzz.io/api/public/contact | OK |
| GIT_COMMIT_SHA | 6af74a24be372a54319e1e65722841bbfda4d234 | OK |
| BUILD_TIME | 2026-05-21T16:00:51Z | OK |

### Build result

| Item | Valeur |
|---|---|
| Build exit code | 0 |
| Image tag local | ghcr.io/keybuzzio/keybuzz-website:v0.6.19-cta-tracking-prod |
| Image ID | sha256:de63e0a4c2ef2d77272f4f3175fd19b753553e549aa88311fc3c42bbbd6623d7 |
| Image size | 214 MB |
| Worktree | /opt/keybuzz/build-worktrees/PH-SAAS-T8.12AS.20.3-PROD/keybuzz-website (cleanup post-train OK) |

### OCI labels KEY-308

| Label | Valeur | Verdict |
|---|---|---|
| org.opencontainers.image.revision | 6af74a24be372a54319e1e65722841bbfda4d234 | OK |
| org.opencontainers.image.created | 2026-05-21T16:00:51Z | OK |
| org.opencontainers.image.version | v0.6.19-cta-tracking-prod | OK |
| org.opencontainers.image.source | https://github.com/keybuzzio/keybuzz-website | OK |
| org.opencontainers.image.title | keybuzz-website | OK |

5/5 OK.

## E2 BUNDLE VERIFY PROD (comparison v0.6.18 baseline vs v0.6.19)

| Pattern | v0.6.18 PROD | v0.6.19 PROD | Delta | Verdict |
|---|---|---|---|---|
| api.keybuzz.io seul (PROD URL) | 2 | 2 | 0 | OK isolation PROD |
| api-dev.keybuzz.io | 0 | 0 | 0 | OK zero leak DEV |
| GA4 G-R3QQDYEBFG | 18 | 18 | 0 | OK marketing IDs preserves |
| SGTM t.keybuzz.pro | 54 | 54 | 0 | OK |
| Meta 1234164602194748 | 2 | 2 | 0 | OK |
| TikTok D7PT12JC77U44OJIPC10 | 2 | 2 | 0 | OK |
| LinkedIn 9969977 | 18 | 18 | 0 | OK |
| Clarity wrff07upjx | 2 | 2 | 0 | OK Clarity Website actif preserve |
| marketing_cta_click (event name) | 1 | 1 | 0 | OK helper source unique |
| trackMarketingClick (callsite) | 26 | **40** | **+14** | OK +11 callsites + import statements |
| MarketingCTA (wrapper) | 36 | 36 | 0 | OK home 8/8 + features 8/8 preserve |
| about_hero_secondary_features | 0 | **2** | **+2** | OK nouveau cta_id |
| about_final_primary_features | 0 | **2** | **+2** | OK |
| about_final_secondary_pricing | 0 | **2** | **+2** | OK |
| homepage_reassurance_amazon_link | 0 | **2** | **+2** | OK |
| features_marketplaces_amazon_link | 0 | **2** | **+2** | OK |
| footer_product_ template | 0 | **2** | **+2** | OK template dynamique |
| footer_amazon_ template | 0 | **2** | **+2** | OK template dynamique |
| pricing_toggle_monthly | 7 | 7 | 0 | OK pricing preserve |
| pricing_final_primary_autopilot | 5 | 5 | 0 | OK pricing preserve |
| pricing_enterprise_contact | 5 | 5 | 0 | OK pricing preserve |
| `"Lead"` | 0 | 0 | 0 | OK no fake event |
| `"Purchase"` | 0 | 0 | 0 | OK |
| `"StartTrial"` | 0 | 0 | 0 | OK |
| `"CompletePayment"` | 0 | 0 | 0 | OK |
| `"SubmitForm"` | 0 | 0 | 0 | OK |
| `"InitiateCheckout"` | 0 | 0 | 0 | OK |
| AW- direct | 0 | 0 | 0 | OK |

DELTA STRICT v0.6.19 vs v0.6.18 PROD = uniquement +14 trackMarketingClick + 7 nouveaux cta_id (5 hard-coded + 2 templates dynamiques). 0 nouvel evenement marketing fabrique. 0 regression Marketing IDs / Clarity / KEY-263 / Pricing.

## E3 PUSH GHCR PROD

```
v0.6.19-cta-tracking-prod: digest: sha256:1e8d73bb7e713473dca3beafa6d1386e412de5f2f934da4ec43075fbdf0b3dfb size: 2619
```

| Digest | Local | GHCR | Match |
|---|---|---|---|
| Config digest (image ID) | sha256:de63e0a4c2ef2d77272f4f3175fd19b753553e549aa88311fc3c42bbbd6623d7 | sha256:de63e0a4c2ef2d77272f4f3175fd19b753553e549aa88311fc3c42bbbd6623d7 | **OK** |
| Manifest digest | n/a | sha256:1e8d73bb7e713473dca3beafa6d1386e412de5f2f934da4ec43075fbdf0b3dfb | OK |
| Repo digest pulled-back | n/a | ghcr.io/keybuzzio/keybuzz-website@sha256:1e8d73bb7e713473dca3beafa6d1386e412de5f2f934da4ec43075fbdf0b3dfb | OK |
| Pull idempotence | n/a | `Image is up to date` | OK |
| Layers total | 9 (6 reused + 3 new) | n/a | OK |

## E4 GITOPS APPLY PROD

| Manifest | Avant | Apres | Commit | Verdict |
|---|---|---|---|---|
| k8s/website-prod/deployment.yaml | v0.6.18-ga4-cleanup-prod | v0.6.19-cta-tracking-prod | ff3a4d9 ops(website-prod): deploy v0.6.19-cta-tracking-prod | OK |

| Item | Valeur |
|---|---|
| Substitution Python regex | count = 1 |
| diff stat | 1 file changed, 1 insertion, 1 deletion |
| kubectl apply --dry-run=server | `deployment.apps/keybuzz-website configured (server dry run)` |
| Infra HEAD avant | 8ee5b76 |
| Infra commit + push | OK 8ee5b76..ff3a4d9 |
| Infra HEAD apres | ff3a4d904a927052fe8ae94781da4bfd6ea8d85c |
| kubectl apply | OK configured |
| Rollout PROD | `deployment "keybuzz-website" successfully rolled out` (2 replicas drained + 2 Ready) |
| Pods nouveaux PROD | keybuzz-website-6cf454595c-n9bsg + keybuzz-website-6cf454595c-qf8bj |
| Pod imageID | ghcr.io/keybuzzio/keybuzz-website@sha256:1e8d73bb7e713473dca3beafa6d1386e412de5f2f934da4ec43075fbdf0b3dfb |
| Match GHCR push digest | **OK** |
| Deployment status PROD | image=v0.6.19-cta-tracking-prod, readyReplicas=2, updatedReplicas=2, replicas=2 |

## E5 SMOKE PROD

| URL | HTTP | Bytes | Verdict |
|---|---|---|---|
| https://www.keybuzz.pro/ | 200 | 72 659 | OK |
| https://www.keybuzz.pro/pricing | 200 | 71 713 | OK |
| https://www.keybuzz.pro/about | 200 | 45 701 | OK |
| https://www.keybuzz.pro/features | 200 | 64 451 | OK |
| https://www.keybuzz.pro/amazon | 200 | 47 075 | OK |
| https://keybuzz.pro/ (alias) | 200 | 72 659 | OK |

### Bundle live PROD chunks audit (home + about)

| Runtime pattern | Attendu | Observe (chunks home + about) | Verdict |
|---|---|---|---|
| HTML home GA4 G-R3QQDYEBFG | >=1 | 1 | OK |
| HTML home SGTM t.keybuzz.pro | >=1 | 1 | OK |
| Total chunks scannes home + about | n/a | 14 | OK |
| trackMarketingClick chunks home+about | >=8 | 12 | OK |
| nouveaux cta_id PH-20.3 chunks home+about (about_*, homepage_reassurance_amazon_link, footer_product_, footer_amazon_) | >=4 | 6 | OK |
| pricing IDs (toggle_monthly, final_primary_autopilot, enterprise_contact) | 0 home+about (presents dans chunk pricing dedie) | 0 | OK normal (pricing chunks non scanne ici) |

Note : Clarity wrff07upjx et `clarity.ms/tag` ne sont pas visibles dans le HTML SSR brut (script inject conditionnel via consent banner localStorage), mais sont presents dans le chunk JS pour activation post-consent (confirme dans le bundle docker E2 = 2 occurrences).

## E6 RUNTIME PRESERVE

| Service | Namespace | Image runtime | Ready | Preserve |
|---|---|---|---|---|
| keybuzz-website | keybuzz-website-prod | **v0.6.19-cta-tracking-prod** | 2/2 | **NOUVEAU PROD** |
| keybuzz-website | keybuzz-website-dev | v0.6.19-cta-tracking-dev | 1/1 | INCHANGE |
| keybuzz-client | keybuzz-client-dev | v3.5.206-clarity-register-dev | 1/1 | INCHANGE |
| keybuzz-client | keybuzz-client-prod | v3.5.200-clarity-register-prod | 1/1 | INCHANGE |
| keybuzz-api | keybuzz-api-dev | v3.5.251-register-cro-dev | 1/1 | INCHANGE |
| keybuzz-api | keybuzz-api-prod | v3.5.250-ad-spend-sync-all-prod | 1/1 | INCHANGE |
| keybuzz-admin-v2 | keybuzz-admin-v2-dev / -prod | v2.12.2-media-buyer-lp-domain-qa-* | 1/1 | INCHANGE |

## E7 NO FAKE METRICS / NO FAKE EVENTS

- Helper marketing-tracking.ts inchange (consent-aware, presence flags only).
- 0 nouveau event Lead/Purchase/StartTrial/CompletePayment/SubmitForm/InitiateCheckout/AW- dans bundle PROD vs v0.6.18.
- 0 nouveau pixel Meta/TikTok/LinkedIn/Google Ads ajoute.
- 0 PII envoyee (cta_id, cta_label, cta_location, cta_destination, cta_variant, cta_intent, surface, cta_page, cta_section, plan, cycle uniquement).
- ATTRIBUTION_KEYS preserves : presence flags only (gclid_present, fbclid_present, ttclid_present, li_fat_id_present, cross_domain_gl_present, marketing_owner_tenant_id_present).

## E8 RESERVES PH-20.1 ETAT POST-TRAIN PROD

| Reserve | Etat avant PH-20.3 | Etat apres PH-20.3 PROD |
|---|---|---|
| R1 Clarity client absent | ADRESSEE (PH-20.2 PROD) | ADRESSEE |
| R2 CTA home + pages secondaires non trackes | OUVERT (audit PH-20.1 sous-estimait via MarketingCTA wrapper) | **ADRESSEE PROD - 11 callsites supplementaires live www.keybuzz.pro** |
| R3 Compte demo absent | OUVERT | OUVERT (PH-20.4) |
| R4 ad_spend Google bloque par token KO | OUVERT | OUVERT (KEY-322 hors PH-20) |
| R5 Pixels Meta/TikTok/LinkedIn ABSENTS Website (decision server-side) | EXPLICITER AGENCE | **NOTE : pixels Meta/TikTok/LinkedIn sont en realite PRESENTS Website PROD baseline (Meta=2, TikTok=2, LinkedIn=18, ViewContent events client-side), seul Client SaaS les omet par decision** |
| R6 Hardening post-incident hors scope | OUVERT | OUVERT (KEY-323) |

R2 PH-20.1 ADRESSEE en PROD. Le tracking Website complet (home + features + about + pricing + footer + Navbar) emet maintenant des events marketing_cta_click consent-aware sur 38+ callsites + 16 MarketingCTA wrapper = 54+ surfaces CTA trackees.

## CONFIRMATIONS SECURITE

- AUCUN docker build supplementaire apres E1 (build PROD unique).
- AUCUN PROD touche en dehors website (Client/API/Admin INCHANGES).
- AUCUN DEV change (Website DEV v0.6.19 INCHANGE).
- AUCUN `kubectl set image / set env / patch / edit` (GitOps strict via apply -f manifest).
- AUCUN secret / token affiche.
- AUCUN `/opt/keybuzz/credentials/` ou `/opt/keybuzz/secrets/` ouvert.
- AUCUN evenement test fake envoye.
- AUCUN ticket Linear cree, ferme, ou statut modifie automatiquement.
- Clarity wrff07upjx preserve (Website public, consent-banner gate).
- Bastion install-v3 (46.62.171.61) uniquement.

## ROLLBACK GitOps STRICT PROD

Si echec smoke/rollout (non observe ici) :

1. Editer `k8s/website-prod/deployment.yaml` -> image `v0.6.18-ga4-cleanup-prod` (digest `sha256:4a6785958f02bcfeadd6f5668e027d80d9fa9b475c4a78600b229688e9539af0`).
2. `git add + commit -m "ops(website-prod): ROLLBACK PH-20.3 to v0.6.18"`.
3. `git push origin main`.
4. `kubectl apply -f k8s/website-prod/deployment.yaml`.
5. `kubectl rollout status -n keybuzz-website-prod deploy/keybuzz-website --timeout=300s`.

INTERDIT : kubectl set image, git reset --hard, git clean.

## GAPS

1. Note correction PH-20.1 R5 : Meta/TikTok/LinkedIn pixels sont en realite **PRESENTS** sur Website PROD baseline (bundle v0.6.18 contient 2 Meta + 2 TikTok + 18 LinkedIn + 18 GA4). L'audit PH-20.1 disait "pixels ABSENTS Website (delegues server-side)" - en realite ils sont presents client-side ET server-side via CAPI. Decision strategique a clarifier avec agence : double tracking client+server actif. A documenter pour Antoine.
2. Lint baseline 63 erreurs preexistantes (apostrophes francaises content original). Hors scope.

## VERDICT FINAL

| Indicateur | Valeur |
|---|---|
| Verdict | GO TRAIN PROD WEBSITE CTA TRACKING READY PH-SAAS-T8.12AS.20.3 |
| Bastion | install-v3 46.62.171.61 |
| Source commit Website | 6af74a2 |
| Tag image PROD | v0.6.19-cta-tracking-prod |
| Image ID local | sha256:de63e0a4c2ef2d77272f4f3175fd19b753553e549aa88311fc3c42bbbd6623d7 |
| Manifest digest GHCR | sha256:1e8d73bb7e713473dca3beafa6d1386e412de5f2f934da4ec43075fbdf0b3dfb |
| Config digest match local==GHCR | OK |
| keybuzz-infra HEAD apres train | ff3a4d9 |
| Pod PROD | keybuzz-website-6cf454595c-n9bsg + qf8bj Ready 2/2 |
| Runtime digest PROD MATCH GHCR push | OK |
| Smoke www.keybuzz.pro | 5/5 HTTP 200 |
| Bundle live PROD chunks home+about | trackMarketingClick=12, nouveaux cta_id PH-20.3=6 |
| Marketing IDs preserves iso baseline | GA4 18, SGTM 54, Meta 2, TikTok 2, LinkedIn 18, Clarity wrff07upjx 2, api.keybuzz.io 2, api-dev 0 |
| Pricing preserves | toggle 7, autopilot 5, enterprise 5 |
| MarketingCTA wrapper | 36/36 |
| No fake events delta | 0 |
| Runtime Website DEV | v0.6.19-cta-tracking-dev INCHANGE |
| Runtime Client DEV/PROD | INCHANGES |
| Runtime API DEV/PROD | INCHANGES |
| Runtime Admin DEV/PROD | INCHANGES |
| Reserve R2 PH-20.1 | ADRESSEE PROD |
| Rapport infra | `keybuzz-infra/docs/PH-SAAS-T8.12AS.20.3-WEBSITE-CTA-TRACKING-TRAIN-PROD-01.md` |

### Prochaine phrase GO attendue

`GO QA WEBSITE CTA TRACKING PROD PH-SAAS-T8.12AS.20.3`

QA navigateur Ludovic recommandee :
- Ouvrir `https://www.keybuzz.pro/` + `/about` + `/features` + `/amazon` + `/pricing` dans navigateur.
- DevTools Network -> filtrer `collect` ou `marketing_cta_click` ou `t.keybuzz.pro`.
- Accepter cookie consent banner.
- Cliquer about (3 CTAs), home amazon bandeau, features amazon bandeau, footer product (3) + footer amazon (3) -> verifier 11 nouveaux events emis.
- Verifier pricing 7/7 + Navbar 5/5 + MarketingCTA home/features 16/16 emettent toujours.
- Verifier Clarity Website session capturee dans projet `wrff07upjx`.

Alternatives :
- `GO REGISTER FR ACCENTS AUDIT PH-SAAS-T8.12AS.20.X`
- `GO REGISTER BILLING ERROR READONLY PH-SAAS-T8.12AS.20.X`
- `GO WEBSITE CMP MOBILE AUDIT PH-SAAS-T8.12AS.20.X`
- `GO DEMO ACCOUNT DESIGN PH-SAAS-T8.12AS.20.4` (KEY-341 reserve R3)

STOP.
