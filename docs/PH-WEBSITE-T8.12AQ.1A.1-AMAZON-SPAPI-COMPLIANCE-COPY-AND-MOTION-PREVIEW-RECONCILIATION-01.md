# PH-WEBSITE-T8.12AQ.1A.1 — Amazon SP-API Compliance Copy & Motion Preview Reconciliation

> **Date** : 2026-05-08
> **Scope** : Website DEV / preview uniquement — zéro PROD
> **Ticket** : KEY-277
> **Objectif** : Réconcilier la LP paid search AQ.1A avec le copywriting Amazon SP-API/sécurité retiré + motion design léger
> **Verdict** : `GO DEV PREVIEW READY`

---

## 1. PREFLIGHT

| Surface | Attendu | Observé | Verdict |
|---|---|---|---|
| Website DEV | `v0.6.11-paid-search-lp-preview-dev` | idem | ✅ |
| Website PROD | `v0.6.10-connector-claims-truth-prod` | idem | ✅ |
| API PROD | `v3.5.147-auto-assignment-after-reply-prod` | idem | ✅ |
| Client PROD | `v3.5.170-shopify-visible-disabled-channels-prod` | idem | ✅ |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | idem | ✅ |
| OW PROD | `v3.5.165-escalation-flow-prod` | idem | ✅ |
| Website HEAD | `f18fb00` (AQ.1A) | idem | ✅ |

---

## 2. DIFF f155bfa → f18fb00 — INVENTAIRE COPY TECHNIQUE RETIRÉ

| Bloc retiré dans AQ.1A | Sujet | Utilité Amazon/SP-API | Décision |
|---|---|---|---|
| "KeyBuzz c'est un système" (5 features dark) | Méthode/règles | Faible | `KEEP_REMOVED` |
| "Ce qui nous différencie" (4 cards) | Conformité/IA/trace | Moyenne | `KEEP_REMOVED` |
| **"Amazon Expertise" (4 cards)** | **SP-API/terrain/conformité** | **Haute** | **`RESTORE_HOME_COMPACT`** |
| "Cas Concrets" (3 use cases) | Retour MFN/livraison/litiges | Moyenne | `KEEP_REMOVED` |
| "Core Offerings" (6 features) | Centralisation/IA/conformité | Moyenne | `KEEP_REMOVED` |
| "Bénéfices" (6 checkmarks) | Résultats vendeur | Faible | `KEEP_REMOVED` |
| **"Sécurité & Confiance" (7 items)** | **OAuth/TLS/RBAC/audit/incidents** | **Haute** | **`RESTORE_HOME_COMPACT`** |

### Justification
Les sections Amazon Expertise et Sécurité & Confiance sont critiques pour :
1. L'acceptation Amazon App Review / demande PII
2. La crédibilité technique auprès des vendeurs marketplace
3. La surface publique prouvant la conformité SP-API

La page `/amazon` (208 lignes) existe déjà avec du contenu SP-API détaillé mais n'est pas liée depuis la homepage.

---

## 3. STRATÉGIE DE RÉINTÉGRATION

### Nouvelle section compacte : "Sécurité & Conformité Amazon SP-API"
- Fusionner les 2 blocs retirés en 1 section dark compacte (4 items)
- Position : entre Bénéfices et Marketplaces
- 4 bullets ciblés :
  1. **Connexion Amazon SP-API officielle** — OAuth 2.0, autorisation vendeur, révocable
  2. **Moindre privilège, lecture seule** — Aucune modification commandes/prix/listings
  3. **Données limitées au support client** — Messages/commandes/suivi, jamais données financières
  4. **Contrôle d'accès et journaux d'audit** — RBAC, TLS, traçabilité, procédure incident 24h
- Lien vers `/amazon` pour le détail
- Section sobre, dark background (cohérent charte), non-redondante avec bénéfices

---

## 4. MOTION DESIGN

### Implémentation
- Composant `Reveal` existant réutilisé (IntersectionObserver + CSS transitions)
- `prefers-reduced-motion` respecté nativement par le composant
- 3 variantes : `default` (fade-up), `left` (slide-left), `scale`
- Stagger delays 1-6 pour l'apparition séquentielle

### Sections animées
| Section | Animation |
|---|---|
| Hero (badge, H1, H2, CTA, badges) | Stagger delay 1-4 |
| Pain Points (titre + 4 cards) | Stagger delay 1-4 |
| Comment ça marche (titre + 3 steps) | Stagger delay 1-3 |
| Bénéfices (titre + 6 cards) | Stagger par row |
| Sécurité Amazon (titre + 4 items + lien) | Stagger delay 1-3 |
| Marketplaces (titre + marquee + note) | Stagger delay 1-2 |
| À propos (photo left-slide + texte + badges) | left + stagger |
| FAQ (titre + 6 items) | Stagger delay 1-6 |
| CTA final (titre + buttons + note) | Stagger delay 1-2 |

### Aucune dépendance ajoutée
Le composant `Reveal` utilise uniquement React + IntersectionObserver natif.

---

## 5. FICHIERS MODIFIÉS

| Fichier | Action | Lignes |
|---|---|---|
| `src/app/page.tsx` | Mis à jour (AQ.1A → AQ.1A.1) | 401 → 519 |

### Composants préservés (non touchés)
Analytics.tsx, Navbar.tsx, Footer.tsx, MarketplaceMarquee.tsx, BackgroundBubbles.tsx, FeatureIcon.tsx, CookieConsent.tsx, IntroSplash.tsx, PreviewBanner.tsx, Reveal.tsx, pricing/page.tsx, features/page.tsx, amazon/page.tsx

---

## 6. VALIDATION AMAZON / SP-API / PII

| Exigence Amazon / PII | Surface publique | Présent ? | Verdict |
|---|---|---|---|
| Mentionne Amazon SP-API | Homepage section sécurité | ✅ "Conformité Amazon SP-API" | OK |
| Explique connexion OAuth | Homepage section sécurité | ✅ "OAuth 2.0 sécurisé, autorisation explicite du vendeur" | OK |
| Explique données utilisées | Homepage section sécurité | ✅ "Messages, commandes et suivi uniquement" | OK |
| Explique permissions limitées | Homepage section sécurité | ✅ "Moindre privilège, lecture seule" | OK |
| Pas d'accès excessif revendiqué | Homepage section sécurité | ✅ "Jamais vos données financières ou bancaires" | OK |
| Pas de scraping revendiqué | Toutes pages | ✅ Absent | OK |
| Pas de contournement Amazon | Toutes pages | ✅ Absent | OK |
| OAuth Amazon ≠ inbound email | Homepage | ✅ Pas de confusion | OK |
| Validation humaine mentionnée | FAQ "IA répond..." | ✅ | OK |
| Privacy policy accessible | Footer | ✅ `/privacy` | OK |
| Terms accessible | Footer | ✅ `/terms` | OK |
| Page dédiée Amazon | `/amazon` (208 lignes) | ✅ Liée depuis homepage | OK |
| Page data-usage Amazon | `/amazon/data-usage` | ✅ HTTP 200 | OK |
| Page security Amazon | `/amazon/security` | ✅ HTTP 200 | OK |

---

## 7. VALIDATION TRACKING

| Signal | Avant AQ.1A | Après AQ.1A.1 DEV | Verdict |
|---|---|---|---|
| GA4 `G-R3QQDYEBFG` | 1 (bundle) | 1 (bundle) | ✅ |
| sGTM `t.keybuzz.pro` | 2 (bundle) | 2 (bundle) | ✅ |
| TikTok `D7PT12JC77U44OJIPC10` | 1 (bundle) | 1 (bundle) | ✅ |
| Meta `1234164602194748` | 1 (bundle) | 1 (bundle) | ✅ |
| UTM forwarding (pricing) | 1 bloc | 1 bloc (inchangé) | ✅ |
| Purchase/CompletePayment browser | Absent | Absent | ✅ |
| Liens CTA vers PROD depuis DEV | Absent | Absent | ✅ |

---

## 8. VALIDATION CLAIMS

| Claim | Page | Verdict |
|---|---|---|
| eBay | homepage | 0 mentions ✅ |
| Shopify | homepage FAQ | "en préparation" ✅ |
| Fnac | features (non touché) | "Bientôt" ✅ |
| Amazon | homepage | connecteur principal ✅ |
| Cdiscount | homepage | wording prudent ✅ |
| "sans CB" | homepage | absent ✅ |
| "Sans engagement" | CTA final | vrai ✅ |
| Chiffres inventés | homepage | absents ✅ |
| Témoignages inventés | homepage | absents ✅ |
| Logos clients non autorisés | homepage | absents ✅ |
| Équipe humaine KeyBuzz | homepage | non revendiquée ✅ |

---

## 9. VALIDATION ROUTING

| Route | Status |
|---|---|
| `/` | 200 ✅ |
| `/pricing` | 200 ✅ |
| `/features` | 200 ✅ |
| `/amazon` | 200 ✅ |
| `/amazon/security` | 200 ✅ |
| `/amazon/data-usage` | 200 ✅ |
| `/contact` | 200 ✅ |

---

## 10. BUILD & DEPLOY

### Tag DEV
`ghcr.io/keybuzzio/keybuzz-website:v0.6.12-paid-search-spapi-trust-motion-preview-dev`

Digest : `sha256:8d6baf44e433082ddd190ed5b871375cf2679ccd997d4c27cc23c1ed4dfc5529`

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
| `keybuzz-website` | `3a66064` | `feat(website): reconcile paid search lp with amazon spapi trust copy (AQ.1A.1)` |
| `keybuzz-infra` | `2feb637` | `gitops(dev): website spapi trust preview v0.6.12 (AQ.1A.1)` |

### PROD inchangée
`v0.6.10-connector-claims-truth-prod` — non touchée, non déployée.

### Rollback DEV
```bash
kubectl set image deploy/keybuzz-website keybuzz-website=ghcr.io/keybuzzio/keybuzz-website:v0.6.11-paid-search-lp-preview-dev -n keybuzz-website-dev
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
| Tracking préservé | ✅ |
| UTM/promo forwarding préservé | ✅ |
| Pas de dépendance animation lourde | ✅ (Reveal = CSS natif) |
| `prefers-reduced-motion` respecté | ✅ |
| GitOps strict | ✅ |

---

## 12. RISQUES RÉSIDUELS

| Risque | Sévérité | Mitigation |
|---|---|---|
| Basic auth preview bloque QA browser automatisée | Faible | QA directe par Ludovic |
| Photo Ludovic dépend de `/images/ludovic.jpg` existant | Faible | Vérifier dans public/ |
| Figma agence non accessible | Info | Travail basé sur recommandations écrites + capture LP SaaS |

---

## 13. LINEAR

- KEY-277 : AQ.1A.1 DEV preview reconciled — SP-API trust copy restored, motion design added
- KEY-253 : LP preview reconciled with Amazon SP-API compliance

---

## VERDICT

**`GO DEV PREVIEW READY`**

PAID SEARCH LANDING PAGE RECONCILED IN DEV — AMAZON SP-API TRUST COPY RESTORED AS COMPACT HOME SECTION — PII/SECURITY/PERMISSIONS PUBLIC SURFACE PRESERVED — MOTION DESIGN LIGHTLY ADDED VIA EXISTING REVEAL COMPONENT — KEYBUZZ MARKETING STRUCTURE PRESERVED — WEBSITE TRACKING AND UTM/PROMO FORWARDING PRESERVED — CONNECTOR CLAIMS HONEST — NO PROD TOUCH — READY FOR LUDOVIC VISUAL QA BEFORE PROD PROMOTION
