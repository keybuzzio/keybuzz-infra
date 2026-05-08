# PH-WEBSITE-T8.12AQ.3 - LinkedIn Insight Tag + SEO Pricing Hardening

> Phase : PH-WEBSITE-T8.12AQ.3-LINKEDIN-INSIGHT-TAG-SEO-HARDENING-DEV-PROD-01
> Date : 2026-05-08/09
> Ticket : KEY-281
> Parent : KEY-253
> Verdict : **GO PROD**

---

## Résumé

Fermeture des deux gaps non-bloquants identifiés en AQ.2 :
1. **LinkedIn Insight Tag** injecté directement côté Website public (partner ID `9969977`)
2. **SEO title `/pricing`** corrigé avec un titre distinct

Aucun service autre que le Website n'a été modifié.

---

## 1. Preflight

| Repo | Branche | HEAD avant | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-website | main | `b37fb3a` (AQ.1A.5) | Non | OK |
| keybuzz-infra | main | `9c703f2` (AQ.2) | Non | OK |

| Service | Image PROD attendue | Runtime | Match |
|---|---|---|---|
| Website PROD | `v0.6.11-paid-search-lp-pricing-prod` | `v0.6.11-paid-search-lp-pricing-prod` | ✅ |
| Website DEV | `v0.6.16-annual-savings-explainer-preview-dev` | `v0.6.16-annual-savings-explainer-preview-dev` | ✅ |
| API PROD | `v3.5.147-auto-assignment-after-reply-prod` | match | ✅ |
| Client PROD | `v3.5.170-shopify-visible-disabled-channels-prod` | match | ✅ |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | match | ✅ |
| OW PROD | `v3.5.165-escalation-flow-prod` | match | ✅ |

---

## 2. Audit tracking existant

| Tracking | Implémentation | Fichier | Statut |
|---|---|---|---|
| GA4 | `NEXT_PUBLIC_GA_ID` | Analytics.tsx | Présent |
| sGTM | `NEXT_PUBLIC_SGTM_URL` | Analytics.tsx | Présent |
| TikTok | `NEXT_PUBLIC_TIKTOK_PIXEL_ID` | Analytics.tsx | Présent |
| Meta | `NEXT_PUBLIC_META_PIXEL_ID` | Analytics.tsx | Présent |
| LinkedIn | **ABSENT** | - | Gap AQ.2 |
| li_fat_id forwarding | URL params | pricing/page.tsx L288 | Présent |
| CookieConsent | Composant dédié | CookieConsent.tsx + layout.tsx | Présent |

---

## 3. Audit docs LinkedIn

| Sujet | Doc officielle | Décision KeyBuzz |
|---|---|---|
| Insight Tag | Tag global JS pageview | Ajouté dans Analytics.tsx |
| Partner ID | `9969977` | Via env var `NEXT_PUBLIC_LINKEDIN_PARTNER_ID` |
| Placement | Global layout | Via composant Analytics centralisé |
| li_fat_id | Click ID utile conversions API | Déjà forwardé, inchangé |
| Conversion CAPI | Non implémenté | Hors scope AQ.3 |
| `lintrk('track', ...)` | Interdit | Absent du code |

---

## 4. Patch appliqué

| Fichier | Changement | Risque | Verdict |
|---|---|---|---|
| `src/components/Analytics.tsx` | +LinkedIn Insight Tag (env var, Script afterInteractive, noscript fallback) | Aucun (suit pattern existant) | ✅ |
| `Dockerfile` | +`NEXT_PUBLIC_LINKEDIN_PARTNER_ID` build arg | Aucun | ✅ |
| `src/app/pricing/layout.tsx` | Nouveau - metadata SEO distincte pour `/pricing` | Aucun (composant client, layout nécessaire) | ✅ |

### Détail Analytics.tsx
- Env var : `const LINKEDIN_PARTNER_ID = process.env.NEXT_PUBLIC_LINKEDIN_PARTNER_ID || ""`
- Null guard étendu pour inclure LinkedIn
- Script block : standard LinkedIn Insight Tag (pageview uniquement)
- Noscript : `<img src="https://px.ads.linkedin.com/collect/?pid=${LINKEDIN_PARTNER_ID}&fmt=gif" />`
- Aucun `lintrk('track', ...)` - aucune conversion
- Pas de useEffect LinkedIn (non nécessaire, le tag track automatiquement)

### Détail pricing/layout.tsx
```typescript
export const metadata: Metadata = {
  title: "Tarifs KeyBuzz - Choisissez votre niveau d'automatisation SAV",
  description: "Plans Starter, Pro et Autopilot pour automatiser votre support client marketplace. 14 jours d'essai gratuit. Dès 97€/mois.",
};
```
Le template layout global (`%s | KeyBuzz`) produit : `Tarifs KeyBuzz - Choisissez votre niveau d'automatisation SAV | KeyBuzz`

---

## 5. Tests source

| Signal | Attendu | Résultat |
|---|---|---|
| `LINKEDIN_PARTNER_ID` env var | Présent | L11 Analytics.tsx ✅ |
| Insight Tag standard | Pageview only | L107-131 ✅ |
| Noscript fallback | `px.ads.linkedin.com` | L131 ✅ |
| `lintrk('track', ...)` | Absent | Absent ✅ |
| `conversion_id` | Absent | Absent ✅ |
| `Purchase` | Absent | Absent ✅ |
| `CompletePayment` | Absent | Absent ✅ |
| `li_fat_id` forwarding | Préservé | pricing/page.tsx L288 ✅ |
| Pricing metadata | Layout créé | layout.tsx ✅ |
| Dockerfile build arg | Ajouté | ✅ |
| Secrets | Absent | Absent ✅ |

---

## 6. Build DEV

| Élément | Valeur |
|---|---|
| Commit Website | `5fc6f2b` |
| Tag | `ghcr.io/keybuzzio/keybuzz-website:v0.6.12-linkedin-insight-seo-dev` |
| Digest | `sha256:a1ea28f6deda4acc9c5c21605ea636b849329e74c86d0a534e8ea119d956f298` |
| Build-from-git | ✅ (commit pushed avant build) |
| Build args | GA4 + sGTM + TikTok + Meta + LinkedIn `9969977` + SITE_MODE=preview |

### Bundle DEV vérifié

| Signal | Fichiers trouvés |
|---|---|
| LinkedIn (`snap.licdn.com`) | 1 |
| GA4 (`R3QQDYEBFG`) | 1 |
| sGTM (`t.keybuzz.pro`) | 2 |
| TikTok (`D7PT12JC77U44OJIPC10`) | 1 |
| Meta (`1234164602194748`) | 1 |
| LinkedIn conversion | 0 ✅ |
| Secrets | 0 ✅ |

---

## 7. GitOps DEV

| Env | Manifest | Image avant | Image après | Commit infra |
|---|---|---|---|---|
| DEV | `k8s/website-dev/deployment.yaml` | `v0.6.16-annual-savings-explainer-preview-dev` | `v0.6.12-linkedin-insight-seo-dev` | `cf5c3a6` |

Rollout DEV : success, pod Running on k8s-worker-05.

---

## 8. Validation DEV

| Test | Résultat |
|---|---|
| Routes (5) | Toutes 200 |
| LinkedIn `9969977` homepage | Présent |
| LinkedIn `9969977` pricing | Présent |
| GA4 | Présent |
| sGTM | Présent |
| Pricing title | `Tarifs KeyBuzz - Choisissez votre niveau d'automatisation SAV \| KeyBuzz` |
| Homepage title | `KeyBuzz - Support Client Marketplace Structuré` |
| `lintrk track` | CLEAN |
| Purchase | CLEAN |

**Verdict DEV : GO**

---

## 9. Build PROD

| Élément | Valeur |
|---|---|
| Commit Website | `5fc6f2b` (même source que DEV) |
| Tag | `ghcr.io/keybuzzio/keybuzz-website:v0.6.12-linkedin-insight-seo-prod` |
| Digest | `sha256:22bd41d5fcc482a397b017c4d10d64ded9947d6f1bc5881994ed76668d38ff49` |
| Build-from-git | ✅ |
| Build args | GA4 + sGTM + TikTok + Meta + LinkedIn `9969977` (pas de SITE_MODE preview) |

---

## 10. GitOps PROD

| Env | Manifest | Image avant | Image après | Rollback | Commit infra |
|---|---|---|---|---|---|
| PROD | `k8s/website-prod/deployment.yaml` | `v0.6.11-paid-search-lp-pricing-prod` | `v0.6.12-linkedin-insight-seo-prod` | `v0.6.11-paid-search-lp-pricing-prod` | `13c9062` |

Rollout PROD : success, 2 pods Running.

---

## 11. Validation PROD

| Signal PROD | Résultat | Verdict |
|---|---|---|
| Routes (5) | Toutes 200 | ✅ |
| LinkedIn `9969977` homepage | Présent | ✅ |
| LinkedIn `9969977` pricing | Présent | ✅ |
| `px.ads.linkedin.com` noscript | Présent | ✅ |
| GA4 `R3QQDYEBFG` | Présent | ✅ |
| sGTM `t.keybuzz.pro` | Présent | ✅ |
| Meta/TikTok (bundle) | Confirmé | ✅ |
| `lintrk('track')` | CLEAN | ✅ |
| Purchase | CLEAN | ✅ |
| CompletePayment | CLEAN | ✅ |
| api-dev | CLEAN | ✅ |
| client-dev | CLEAN | ✅ |

---

## 12. SEO Pricing PROD

| Page | Title | Verdict |
|---|---|---|
| Homepage | `KeyBuzz - Support Client Marketplace Structuré` | ✅ Inchangé |
| Pricing | `Tarifs KeyBuzz - Choisissez votre niveau d'automatisation SAV \| KeyBuzz` | ✅ Distinct |

Pricing content préservé :
- Autopilot recommandé : ✅
- 14 jours d'essai : ✅
- eBay disponible (fausse claim) : CLEAN ✅

---

## 13. Non-régression services

| Service | Image attendue | Image runtime | Match |
|---|---|---|---|
| API PROD | `v3.5.147-auto-assignment-after-reply-prod` | match | ✅ |
| Client PROD | `v3.5.170-shopify-visible-disabled-channels-prod` | match | ✅ |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | match | ✅ |
| OW PROD | `v3.5.165-escalation-flow-prod` | match | ✅ |
| Admin PROD | `v2.12.1-promo-codes-foundation-prod` | match | ✅ |

---

## 14. Linear

### KEY-281
- Commit Website : `5fc6f2b`
- Image DEV : `v0.6.12-linkedin-insight-seo-dev`
- Image PROD : `v0.6.12-linkedin-insight-seo-prod`
- Digest DEV : `sha256:a1ea28f6deda4acc9c5c21605ea636b849329e74c86d0a534e8ea119d956f298`
- Digest PROD : `sha256:22bd41d5fcc482a397b017c4d10d64ded9947d6f1bc5881994ed76668d38ff49`
- LinkedIn `9969977` confirmé sur Website PROD
- Pricing SEO title corrigé
- Tracking GA4/sGTM/TikTok/Meta préservés
- Aucun fake event
- Status : **Done**

### KEY-253
- AQ.3 terminé
- LinkedIn direct tag confirmé PROD
- Pricing title corrigé
- Ads tracking hardened
- Commentaire synthèse ajouté

### KEY-282 (Dashboard Performance SAV)
- Non traité dans AQ.3
- Reste post-Ads

---

## 15. Gaps restants

| Gap | Ticket | Bloquant Ads ? | Action |
|---|---|---|---|
| Shopify activation réelle | KEY-273 | Non | Post-approval |
| 17TRACK raw body signature hardening | KEY-275 | Non | Post-Ads |
| Notification proactive escalade | KEY-263 | Non | Post-Ads |
| Dashboard Performance SAV | KEY-282 | Non | Future feature |

---

## 16. Rollback

En cas d'incident, rollback GitOps strict :
1. Modifier `k8s/website-prod/deployment.yaml` : image `v0.6.11-paid-search-lp-pricing-prod`
2. `git commit && git push`
3. `kubectl apply -f k8s/website-prod/deployment.yaml`
4. `kubectl rollout status deployment/keybuzz-website -n keybuzz-website-prod`

---

## 17. Confirmations finales

- ✅ 0 fake event LinkedIn
- ✅ 0 fake event GA4
- ✅ 0 fake event Meta
- ✅ 0 fake event TikTok
- ✅ 0 checkout
- ✅ 0 payment
- ✅ 0 mutation DB
- ✅ 0 mutation Stripe
- ✅ 0 mutation CAPI
- ✅ 0 secret dans bundle
- ✅ 0 DEV URL en PROD

---

## Verdict

**PH-WEBSITE-T8.12AQ.3 - TERMINÉ**

**Verdict : GO PROD**

**LINKEDIN INSIGHT TAG DIRECT LIVE IN PROD - PARTNER ID 9969977 CONFIRMED ON WEBSITE - PRICING SEO TITLE HARDENED - GA4 / SGTM / TIKTOK / META / UTM PROMO FORWARDING PRESERVED - NO LINKEDIN CONVERSION EVENT - NO FAKE PURCHASE - NO CHECKOUT - NO PAYMENT - NO DB / STRIPE / CAPI MUTATION - WEBSITE ADS TRACKING HARDENED - GITOPS STRICT**
