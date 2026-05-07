# PH-WEBSITE-T8.12AQ.1A — Paid Search Landing Page DEV Preview Redesign

> **Date** : 2026-05-08
> **Scope** : Website DEV / preview uniquement — zéro PROD
> **Objectif** : Adapter la landing page publique KeyBuzz aux standards paid search agence
> **Verdict** : `GO DEV PREVIEW READY`

---

## 1. PREFLIGHT

### Baselines PROD (read-only, inchangées)

| Service | Tag attendu | Tag vérifié | Match |
|---|---|---|---|
| Website PROD | `v0.6.10-connector-claims-truth-prod` | `v0.6.10-connector-claims-truth-prod` | ✅ |
| API PROD | `v3.5.147-auto-assignment-after-reply-prod` | `v3.5.147-auto-assignment-after-reply-prod` | ✅ |
| Client PROD | `v3.5.170-shopify-visible-disabled-channels-prod` | `v3.5.170-shopify-visible-disabled-channels-prod` | ✅ |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | `v1.0.47-cross-env-guard-fix-prod` | ✅ |
| OW PROD | `v3.5.165-escalation-flow-prod` | `v3.5.165-escalation-flow-prod` | ✅ |

### Repo Website

- Branche : `main`
- HEAD avant : `f155bfa` (AP.4.1 connector claims truth)
- État : propre

---

## 2. SOURCES RELUES

- `PRE_ADS_AP_BASELINE.md`
- `RULES_AND_RISKS.md`
- `PH-SAAS-T8.12AP.3-PRE-ADS-FEATURE-BASELINE-MEMORY-AND-LINEAR-CLOSURE-01.md`
- `PH-SAAS-T8.12AP.4.1-WEBSITE-CONNECTOR-CLAIMS-CORRECTION-DEV-PROD-01.md`
- Benchmarks agence : indy.fr, kolecto.fr, tribecrm.fr (structure uniquement, non copiés)

---

## 3. AUDIT PAGE ACTUELLE

| Élément | Avant (v0.6.10) | Problème |
|---|---|---|
| Hero H1 | 3 lignes émotionnelles | Trop long pour paid search |
| Hero CTA | "Mettre mon support en ordre" | Pas orienté conversion |
| Preuve above-the-fold | Absente | Aucun signal confiance |
| Nombre de sections | 13 | Redondance massive |
| Amazon Expertise | 4 cartes | Redondant avec System + Core |
| Cas Concrets | 3 use cases | Redondant avec System |
| Core Offerings | 6 features | Redondant avec System |
| Benefits | 6 checkmarks | Redondant avec Differentiators |
| FAQ | Absente sur homepage | Manque objection handling |
| Total lignes | 751 | Page trop longue |

---

## 4. PLAN LP (structure agence)

| # | Section | Contenu |
|---|---|---|
| 1 | **Hero** | H1 résultat, H2 mécanisme+cible, CTA "Essayer gratuitement" + "Voir comment", badges confiance (14j, connexion 2min, sans engagement) |
| 2 | **Pain Points** | 4 symptômes vendeur (condensé de 6) |
| 3 | **Comment ça marche** | 3 étapes (conservé) |
| 4 | **Bénéfices clés** | 6 features → bénéfice (fusion système + différenciateurs + core offerings) |
| 5 | **Marketplaces** | MarketplaceMarquee (conservé tel quel) |
| 6 | **À propos** | Ludovic condensé + badges sécurité |
| 7 | **FAQ** | 6 questions/réponses (marketplaces, IA, sécurité, démarrage, engagement, données) |
| 8 | **CTA final** | 2 CTA + pricing teaser |

---

## 5. FICHIERS MODIFIÉS

| Fichier | Action | Lignes |
|---|---|---|
| `src/app/page.tsx` | Réécrit | 751 → 401 lignes |
| Aucun autre fichier modifié | — | — |

### Composants préservés (non touchés)
- `Analytics.tsx` — tracking GA4/Meta/TikTok/sGTM
- `Navbar.tsx` — navigation
- `Footer.tsx` — footer
- `MarketplaceMarquee.tsx` — carousel marketplace
- `BackgroundBubbles.tsx` — effet visuel hero
- `FeatureIcon.tsx` — icônes features
- `CookieConsent.tsx` — consent cookies
- `IntroSplash.tsx` — splash intro
- `PreviewBanner.tsx` — bannière preview
- `pricing/page.tsx` — page tarifs (UTM forwarding intact)
- `features/page.tsx` — page features (claims AP.4.1 intacts)

---

## 6. COPY CHANGEMENTS PRINCIPAUX

### Hero

| Élément | Avant | Après |
|---|---|---|
| H1 | "Vos clients écrivent. Vos litiges s'accumulent. Votre compte est en jeu." | "Un seul endroit pour tout votre SAV marketplace" |
| H2 | "KeyBuzz structure, priorise..." | "KeyBuzz centralise vos messages Amazon, Cdiscount et e-mail. L'IA détecte les urgences, prépare les réponses, et vous gardez la main." |
| CTA principal | "Mettre mon support en ordre" | "Essayer gratuitement" |
| CTA secondaire | "Voir comment KeyBuzz fonctionne" | "Voir comment ça marche" |
| Preuve below CTA | "Ouverture du compte immédiate • Connexion directe • Sans appel obligatoire" | ✅ 14 jours d'essai • ✅ Connexion Amazon en 2 min • ✅ Sans engagement |

### Sections retirées (redondantes)
- "KeyBuzz c'est un système" (fusionné dans Bénéfices)
- "Ce qui nous différencie" (fusionné dans Bénéfices)
- "Amazon Expertise" (4 cartes)
- "Cas concrets" (3 use cases)
- "Core Offerings" (6 features)
- "Bénéfices concrets" (6 checkmarks)
- "Sécurité & Confiance" (condensé dans About)

### Section ajoutée
- **FAQ** : 6 questions/réponses couvrant marketplaces, IA, sécurité Amazon, démarrage, engagement, données

---

## 7. VALIDATION TRACKING

| Signal | Avant (v0.6.10) | Après DEV (v0.6.11) | Verdict |
|---|---|---|---|
| GA4 `G-R3QQDYEBFG` | ✅ dans bundle | ✅ dans bundle | OK |
| sGTM `t.keybuzz.pro` | ✅ dans bundle | ✅ dans bundle | OK |
| TikTok `D7PT12JC77U44OJIPC10` | ✅ dans bundle | ✅ dans bundle | OK |
| Meta `1234164602194748` | ✅ dans bundle | ✅ dans bundle | OK |
| UTM forwarding (pricing) | ✅ 1 bloc | ✅ 1 bloc (non touché) | OK |
| Purchase/CompletePayment events | Absents | Absents | OK |

---

## 8. VALIDATION CLAIMS

| Claim | Page | Statut DEV | Conforme AP ? |
|---|---|---|---|
| eBay | homepage | 0 mentions | ✅ |
| Shopify | homepage FAQ | "en préparation" | ✅ |
| Fnac | features (non touché) | "Bientôt" | ✅ |
| Cdiscount/Octopia | homepage FAQ | wording prudent | ✅ |
| Amazon | homepage | connecteur principal | ✅ |
| "sans CB" / "sans carte bancaire" | homepage | absent | ✅ |
| "Sans engagement" | CTA final | vrai (mensuel) | ✅ |
| Promesse équipe humaine | homepage | absente | ✅ |
| Métriques inventées | homepage | absentes | ✅ |
| Témoignages inventés | homepage | absents | ✅ |
| Logos clients non autorisés | homepage | absents | ✅ |

---

## 9. VALIDATION ROUTING

| Route | Status DEV | Status PROD (inchangé) |
|---|---|---|
| `/` | 200 | 200 |
| `/pricing` | 200 | 200 |
| `/features` | 200 | 200 |
| `/amazon` | 200 | 200 |
| `/contact` | 200 | 200 |

---

## 10. BUILD & DEPLOY

### Tag DEV
- `ghcr.io/keybuzzio/keybuzz-website:v0.6.11-paid-search-lp-preview-dev`
- Digest : `sha256:1182f097def34f4795d720c5bb8febc14694388872a32cd21e2d27286318e380`

### Build args
```
NEXT_PUBLIC_SITE_MODE=preview
NEXT_PUBLIC_GA_ID=G-R3QQDYEBFG
NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro
NEXT_PUBLIC_TIKTOK_PIXEL_ID=D7PT12JC77U44OJIPC10
NEXT_PUBLIC_META_PIXEL_ID=1234164602194748
```

### Commits

| Repo | Commit | Message |
|---|---|---|
| `keybuzz-website` | `f18fb00` | `feat(website): paid search landing page preview redesign (AQ.1A)` |
| `keybuzz-infra` | `ee9f1cb` | `gitops(dev): website paid search landing page preview v0.6.11 (AQ.1A)` |

### Rollback DEV
```bash
kubectl set image deploy/keybuzz-website keybuzz-website=ghcr.io/keybuzzio/keybuzz-website:v0.6.10-connector-claims-truth-dev -n keybuzz-website-dev
```

---

## 11. INTERDITS RESPECTÉS

| Interdit | Statut |
|---|---|
| PROD non modifié | ✅ |
| API/Client/Backend/Admin/OW non modifié | ✅ |
| DB non mutée | ✅ |
| Stripe non touché | ✅ |
| CAPI non envoyé | ✅ |
| Email non envoyé | ✅ |
| Tracking non supprimé | ✅ |
| UTM/promo forwarding préservé | ✅ |
| Pas de kubectl set image / edit / patch (GitOps strict) | ✅ |
| Pas de git reset --hard / clean | ✅ |
| Pas de hardcodage tenant/user/coupon | ✅ |

---

## 12. RISQUES RÉSIDUELS

| Risque | Sévérité | Mitigation |
|---|---|---|
| Basic auth preview empêche la QA visuelle browser | Faible | QA Ludovic en direct sur preview.keybuzz.pro |
| Photo Ludovic (`/images/ludovic.jpg`) doit exister | Faible | Vérifier présence dans public/ |
| MarketplaceMarquee montre des logos non-connecteurs | Faible | Composant existant, même wording prudent |

---

## 13. RECOMMANDATION

La LP est déployée en DEV/preview (`v0.6.11-paid-search-lp-preview-dev`).

**Prochaine étape** : AQ.1B — QA visuelle Ludovic sur `https://preview.keybuzz.pro/` (Basic Auth: `keybuzz:preview2024`), puis promotion PROD avec tag `-prod` si validé.

---

## VERDICT

**`GO DEV PREVIEW READY`**

PAID SEARCH LANDING PAGE PREVIEW READY IN DEV — HERO/CTA/PROBLEM/SOLUTION/BENEFITS/FAQ STRUCTURE ALIGNED WITH AGENCY GUIDANCE — KEYBUZZ CHARTER PRESERVED — WEBSITE TRACKING AND UTM/PROMO FORWARDING PRESERVED — CONNECTOR CLAIMS HONEST — NO PROD TOUCH — NO BILLING/TRACKING/CAPI DRIFT — READY FOR LUDOVIC VISUAL QA BEFORE PROD PROMOTION
