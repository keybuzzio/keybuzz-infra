# PH-WEBSITE-T8.12AQ.1B - Paid Search Landing + Pricing PROD Promotion

> **Date** : 8 mai 2026
> **Type** : Promotion PROD depuis preview validée
> **Priorité** : P0 avant Ads
> **Verdict** : GO PROD

---

## Résumé

Promotion en PROD de la version Website preview validée par Ludovic, consolidant les phases AQ.1A à AQ.1A.5 :
- Homepage paid search renforcée (hero conversion, réassurance, motion design)
- Section Amazon SP-API trust restaurée
- Pricing aligné avec Autopilot recommandé
- Essai 14 jours visible
- Économie annuelle 20% explicitée
- UTM/promo forwarding préservé
- Tracking website préservé (GA4, sGTM, TikTok, Meta)
- Claims connecteurs honnêtes

---

## Preflight

| Service | Attendu | Observé | Verdict |
|---|---|---|---|
| Website HEAD | `b37fb3a` (AQ.1A.5) | `b37fb3a` | OK |
| Website DEV | `v0.6.16-annual-savings-explainer-preview-dev` | idem | OK |
| Website PROD (avant) | `v0.6.10-connector-claims-truth-prod` | idem | OK |
| Website PROD replicas | 2 | 2 | OK |
| API PROD | `v3.5.147-auto-assignment-after-reply-prod` | idem | OK |
| Client PROD | `v3.5.170-shopify-visible-disabled-channels-prod` | idem | OK |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | idem | OK |
| OW PROD | `v3.5.165-escalation-flow-prod` | idem | OK |
| Infra branch | main | main | OK |

---

## Source Lock (commit `b37fb3a`)

| Signal | Source | Verdict |
|---|---|---|
| H1 "Automatisez votre SAV marketplace" | 1 occurrence | OK |
| "14 jours" homepage | 3 occurrences | OK |
| Amazon SP-API trust section | 1 section | OK |
| Réassurance section | 2 occurrences | OK |
| Motion design (Reveal) | 57 occurrences | OK |
| Em dashes homepage | 0 | OK |
| Autopilot Recommandé | 1 | OK |
| "14 jours" pricing | 10 occurrences | OK |
| "-20%" badge | 1 | OK |
| "Passez en annuel" explainer | 1 | OK |
| "1 188" savings max | 1 | OK |
| "2 mois offerts" | 0 (absent - correct) | OK |
| "sans CB" | 0 (absent - correct) | OK |
| Em dashes pricing | 0 | OK |
| Savings formula correcte | `(monthlyPrice - getPrice(monthlyPrice)) * 12` | OK |
| trackViewPricing | Present | OK |
| trackSelectPlan | Present | OK |
| trackClickSignup | Present | OK |
| UTM/promo forwarding | Present | OK |

---

## Build PROD

- **Source commit** : `b37fb3a`
- **Tag** : `ghcr.io/keybuzzio/keybuzz-website:v0.6.11-paid-search-lp-pricing-prod`
- **Digest** : `sha256:77511cd3415b029e2cb52b23ae0bd5d251c334805ef34c37bb82e3c28c06ac8e`
- **Build** : `docker build --no-cache`
- **Next.js** : 16.1.4 (Turbopack)
- **Pages** : 18/18 statiques

### Build args

| Arg | Valeur |
|---|---|
| `NEXT_PUBLIC_SITE_MODE` | `production` |
| `NEXT_PUBLIC_CLIENT_APP_URL` | `https://client.keybuzz.io` |
| `NEXT_PUBLIC_GA_ID` | `G-R3QQDYEBFG` |
| `NEXT_PUBLIC_SGTM_URL` | `https://t.keybuzz.pro` |
| `NEXT_PUBLIC_TIKTOK_PIXEL_ID` | `D7PT12JC77U44OJIPC10` |
| `NEXT_PUBLIC_META_PIXEL_ID` | `1234164602194748` |

---

## Validation Image PROD Candidate

| Signal | Bundle | Verdict |
|---|---|---|
| GA4 G-R3QQDYEBFG | 1 fichier JS | OK |
| sGTM t.keybuzz.pro | 2 fichiers JS | OK |
| TikTok D7PT12JC77U44OJIPC10 | 1 fichier JS | OK |
| Meta 1234164602194748 | 1 fichier JS | OK |
| client.keybuzz.io | 2 fichiers JS | OK |
| DEV URLs (api-dev/client-dev) | 0 | OK |
| preview.keybuzz.pro | 1 fichier (PreviewBanner hostname check - attendu) | OK |

Note : la référence `preview.keybuzz.pro` dans le bundle est le composant `PreviewBanner` qui vérifie `window.location.hostname.includes("preview.keybuzz.pro")` pour masquer/afficher le banner preview. En PROD (`www.keybuzz.pro`), cette vérification retourne `false` - comportement attendu.

---

## GitOps PROD

- **Manifest** : `k8s/website-prod/deployment.yaml`
- **Image** : `ghcr.io/keybuzzio/keybuzz-website:v0.6.11-paid-search-lp-pricing-prod`
- **Commit** : `94fee8e` - `gitops(prod): website paid search lp pricing v0.6.11`
- **Repo** : `keybuzz-infra` branche `main`
- **Méthode** : `kubectl apply -f` (GitOps strict)
- **Rollout** : `deployment "keybuzz-website" successfully rolled out`
- **Replicas** : 2/2 ready

---

## Validation Runtime PROD

### Routes

| Route | HTTP | Verdict |
|---|---|---|
| `/` | 200 | OK |
| `/pricing` | 200 | OK |
| `/features` | 200 | OK |
| `/amazon` | 200 | OK |
| `/amazon/security` | 200 | OK |
| `/amazon/data-usage` | 200 | OK |
| `/contact` | 200 | OK |
| `/privacy` | 200 | OK |
| `/terms` | 200 | OK |

### Content Homepage

| Check | PROD runtime | Verdict |
|---|---|---|
| H1 "Automatisez votre SAV marketplace" | Present | OK |
| "14 jours" visible | 3x | OK |
| SP-API references | 4 | OK |
| Em dashes | 0 | OK |

### Content Pricing

| Check | PROD runtime | Verdict |
|---|---|---|
| "14 jours" visible | 8x | OK |
| Autopilot Recommandé | 1 | OK |
| "-20%" badge | 1 | OK |
| "Passez en annuel" explainer | 1 | OK |
| Em dashes | 0 | OK |

---

## Tracking / UTM / Promo PROD

| Signal | PROD | Verdict |
|---|---|---|
| GA4 G-R3QQDYEBFG (HTML) | 1 | OK |
| sGTM t.keybuzz.pro (HTML) | 1 | OK |
| TikTok D7PT12JC77U44OJIPC10 | JS-loaded (bundle verified) | OK |
| Meta 1234164602194748 | JS-loaded (bundle verified) | OK |
| DEV URLs in HTML | 0 | OK |
| "sans CB" | 0 | OK |
| eBay disponible | 0 | OK |
| UTM forwarding (source code) | Present | OK |
| Promo forwarding (source code) | Present | OK |

---

## Non-régression Services

| Surface | Avant | Après | Verdict |
|---|---|---|---|
| API PROD | `v3.5.147-auto-assignment-after-reply-prod` | idem | OK |
| Client PROD | `v3.5.170-shopify-visible-disabled-channels-prod` | idem | OK |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | idem | OK |
| OW PROD | `v3.5.165-escalation-flow-prod` | idem | OK |
| Admin PROD | N/A (non accessible) | - | OK |
| DB | Non mutée | - | OK |
| Stripe | Non touché | - | OK |
| CAPI | Non envoyé | - | OK |
| Emails | Non envoyés | - | OK |

---

## Rollback

Si nécessaire, rollback GitOps strict :

```bash
cd /opt/keybuzz/keybuzz-infra
# Modifier manifest :
sed -i 's|image: ghcr.io/keybuzzio/keybuzz-website:.*|image: ghcr.io/keybuzzio/keybuzz-website:v0.6.10-connector-claims-truth-prod|' k8s/website-prod/deployment.yaml
git add k8s/website-prod/deployment.yaml
git commit -m "rollback(prod): website to v0.6.10"
git push origin main
kubectl apply -f k8s/website-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-website -n keybuzz-website-prod
```

---

## Interdits Respectés

- [x] Aucune modification API/Client/Backend/Admin/OW
- [x] Aucune modification manifests non-Website
- [x] Aucune mutation DB
- [x] Aucun contact Stripe
- [x] Aucun checkout créé
- [x] Aucun email envoyé
- [x] Aucun CAPI envoyé
- [x] Aucun fake event tracking
- [x] Aucune modification pixels/tracking sans contrôle
- [x] UTM/promo forwarding préservé
- [x] eBay non disponible
- [x] Shopify en préparation
- [x] Fnac/Darty bientôt
- [x] Pas de "sans CB"
- [x] Pas de faux témoignages/chiffres/logos
- [x] Section Amazon SP-API trust présente
- [x] Liens /amazon, /amazon/security, /amazon/data-usage préservés
- [x] Pas de kubectl set image/edit/patch/set env
- [x] Pas de git reset --hard/clean
- [x] Build depuis commit b37fb3a uniquement
- [x] Tracking/UTM/promo vérifiés avant promotion

---

## Phases Consolidées dans cette Promotion

| Phase | Description |
|---|---|
| AQ.1A | Paid search landing page redesign |
| AQ.1A.1 | Amazon SP-API compliance copy + motion reconciliation |
| AQ.1A.2 | Conversion copy + social proof + CTA polish |
| AQ.1A.3 | Pricing conversion + Autopilot recommended |
| AQ.1A.4 | Trial savings + hyphen polish |
| AQ.1A.5 | Annual savings explainer toggle |

---

## Verdict

**GO PROD**

PAID SEARCH LANDING AND PRICING LIVE IN PROD - HOMEPAGE CONVERSION COPY / AMAZON SP-API TRUST / SOCIAL PROOF / MOTION POLISH PRESERVED - PRICING AUTOPILOT RECOMMENDED / 14 DAYS TRIAL / ANNUAL 20 PERCENT SAVINGS CLEAR - WEBSITE TRACKING AND UTM/PROMO FORWARDING PRESERVED - CONNECTOR CLAIMS HONEST - API/CLIENT/BACKEND/ADMIN/OW UNCHANGED - NO BILLING/TRACKING/CAPI DRIFT - GITOPS STRICT - READY FOR ADS FINAL CHECK
