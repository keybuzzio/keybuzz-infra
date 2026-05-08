# PH-WEBSITE-T8.12AQ.2 - Ads Final Check PROD Read-Only

> **Date** : 8 mai 2026
> **Type** : Contrôle final Ads read-only
> **Priorité** : P0
> **Ticket** : KEY-280 (parent KEY-253)
> **Verdict** : GO ADS READY

---

## Résumé

Contrôle final PROD avant lancement Ads, après la promotion AQ.1B. Vérifie le site public, le funnel, les CTA, les liens register/pricing, le forwarding UTM/promo, le tracking website, les claims connecteurs, la conformité Amazon SP-API et le responsive.

**Phase strictement read-only : 0 code, 0 build, 0 deploy, 0 mutation.**

---

## Preflight

| Repo | Branche | HEAD | Dirty | Verdict |
|---|---|---|---|---|
| keybuzz-website | main | `b37fb3a` | Non | OK |
| keybuzz-infra | main | `d940ea2` | Non | OK |

| Service | Image PROD attendue | Image runtime | Match |
|---|---|---|---|
| Website | `v0.6.11-paid-search-lp-pricing-prod` | idem | OK |
| API | `v3.5.147-auto-assignment-after-reply-prod` | idem | OK |
| Client | `v3.5.170-shopify-visible-disabled-channels-prod` | idem | OK |
| Backend | `v1.0.47-cross-env-guard-fix-prod` | idem | OK |
| OW | `v3.5.165-escalation-flow-prod` | idem | OK |
| Website replicas | 2/2 | 2/2 | OK |
| Manifest | `v0.6.11` | Cohérent | OK |
| Digest | `sha256:77511cd3415b029e2cb52b23ae0bd5d251c334805ef34c37bb82e3c28c06ac8e` | - | OK |

---

## ÉTAPE 1 - Routes publiques PROD

| URL | Attendu | Résultat | Verdict |
|---|---|---|---|
| `/` | 200 | 200 | OK |
| `/pricing` | 200 | 200 | OK |
| `/features` | 200 | 200 | OK |
| `/amazon` | 200 | 200 | OK |
| `/amazon/security` | 200 | 200 | OK |
| `/amazon/data-usage` | 200 | 200 | OK |
| `/contact` | 200 | 200 | OK |
| `/privacy` | 200 | 200 | OK |
| `/terms` | 200 | 200 | OK |
| `/about` | 200 | 200 | OK |
| `/legal` | 200 | 200 | OK |
| `/cookies` | 200 | 200 | OK |
| `/sla` | 200 | 200 | OK |

Aucune redirect DEV, aucune erreur 5xx.

---

## ÉTAPE 2 - Homepage conversion

| Section | Attendu | Résultat | Verdict |
|---|---|---|---|
| H1 | "Automatisez votre SAV marketplace sans perdre le contrôle" | Present | OK |
| Sous-titre | IA trie, priorise, prépare | Present | OK |
| CTA principal | "Essayer 14 jours gratuitement" | Present | OK |
| CTA secondaire | "Voir comment ça marche" | Present | OK |
| 14 jours badge | "14 jours d'essai gratuit" + "sur vos vrais messages" | Present (3x) | OK |
| Trust badges | Amazon 2 min, IA + validation, Sans engagement | Present | OK |
| "sans CB" | Absent | 0 occurrences | OK |
| Em dashes | Absent | 0 | OK |
| Problème/douleurs | 4 items (boîte mail, client mauvaise foi, A-Z, SLA) | Present | OK |
| Solution/mécanisme | 3 étapes (Centraliser, Analyser, Agir) | Present | OK |
| Bénéfices | 6 items (contexte auto, IA contrôle, règles, conformité, traçabilité, répétitif) | Present | OK |
| Réassurance | "Ce que KeyBuzz évite" (4 situations réelles) | Present | OK |
| Amazon SP-API trust | Section sécurité (OAuth, moindre privilège, données, audit) | Present | OK |
| Marketplaces & Intégrations | Logos (Amazon, Fnac, Darty, Cdiscount, Shopify, WooCommerce) | Present | OK |
| Qui est derrière | Ludovic, fondateur | Present | OK |
| FAQ | 6 questions | Present | OK |
| CTA final | "Démarrer l'essai gratuit" + "Découvrir les fonctionnalités" | Present | OK |
| Tarif affiché | "Dès 97€/mois - Sans engagement - Annulation en 1 clic" | Present | OK |
| DEV leak | Absent | 0 | OK |

---

## ÉTAPE 3 - Amazon SP-API trust public

| Claim SP-API | Surface | Résultat | Verdict |
|---|---|---|---|
| OAuth / connexion officielle | Homepage + /amazon | "OAuth 2.0 sécurisé, autorisation explicite" | OK |
| Permissions moindre privilège | Homepage + /amazon | "Accès limité au strict nécessaire" | OK |
| Données support client | Homepage + /amazon | "Messages, commandes et suivi uniquement" | OK |
| Pas de modification prix/commandes | /amazon | "Aucune modification de vos commandes, prix ou listings" | OK |
| Sécurité / audit | Homepage + /amazon | "RBAC, chiffrement TLS, traçabilité complète" | OK |
| Lien page dédiée | Homepage | "Voir notre politique de conformité Amazon" (lien /amazon) | OK |
| /amazon/security | Page dédiée | Contenu sécurité présent (HTTP 200) | OK |
| /amazon/data-usage | Page dédiée | Contenu usage données présent (HTTP 200) | OK |
| Promesses excessives | Toutes surfaces | Aucune | OK |

---

## ÉTAPE 4 - Pricing PROD

| Élément pricing | Attendu | Résultat | Verdict |
|---|---|---|---|
| Autopilot Recommandé | Badge vert "Recommandé" | Present (vérifié visuellement) | OK |
| Starter sans IA gratuite | "IA disponible via packs KBActions en option" | Present | OK |
| Pro IA assistée | "1 000 KBActions IA / mois incluses" | Present | OK |
| Autopilot automatisation | "3 500 KBActions IA / mois", "IA autonome sous garde-fous" | Present | OK |
| Enterprise | "Sur devis", "Parler à un expert" | Present | OK |
| 14 jours très visible | "14 jours d'essai gratuit" | 8x occurrences | OK |
| Toggle mensuel/annuel | Boutons Mensuel/Annuel | Present et fonctionnel | OK |
| -20% badge | Badge vert "-20% annuel" | Present | OK |
| Explainer annuel (mensuel) | "Passez en annuel et économisez 20% sur tous les plans." | Present | OK |
| Explainer annuel (annuel) | "Vous économisez 20% - soit jusqu'à 1 188 € par an." | Present dans source | OK |
| Savings par plan | Formule `(monthlyPrice - getPrice(monthlyPrice)) * 12` | Correcte (source vérifié) | OK |
| "sans CB" | Absent | 0 occurrences | OK |
| Em dashes | Absent | 0 | OK |
| "2 mois offerts" | Absent (math non exacte) | 0 | OK |
| FAQ | 10 questions | Present | OK |
| CTA final | "Commencer l'essai Autopilot" | Present | OK |
| Sécurité section | OAuth, moindre privilège, journaux, conformité | Present | OK |

---

## ÉTAPE 5 - CTA et forwarding UTM/promo

| CTA | URL destination | UTM forwarding | Promo forwarding | Verdict |
|---|---|---|---|---|
| Pricing Starter | `client.keybuzz.io/register?plan=starter&cycle=monthly` | JS-forwarded | JS-forwarded | OK |
| Pricing Pro | `client.keybuzz.io/register?plan=pro&cycle=monthly` | JS-forwarded | JS-forwarded | OK |
| Pricing Autopilot | `client.keybuzz.io/register?plan=autopilot&cycle=monthly` | JS-forwarded | JS-forwarded | OK |
| CTA final Autopilot | `client.keybuzz.io/register?plan=autopilot&cycle=monthly` | JS-forwarded | JS-forwarded | OK |

### UTM forwarding code vérifié (source `pricing/page.tsx` ligne 287-288)

```javascript
const params = new URLSearchParams(window.location.search);
const utmKeys = ["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
                  "gclid", "fbclid", "ttclid", "marketing_owner_tenant_id", "li_fat_id", "_gl", "promo"];
```

Tous les paramètres Ads sont couverts : utm_source, utm_medium, utm_campaign, utm_term, utm_content, gclid, fbclid, ttclid, li_fat_id, _gl, promo.

### Bundle JS vérifié

| Paramètre | Dans bundle | Verdict |
|---|---|---|
| utm_source | 1 fichier JS | OK |
| promo | 1 fichier JS | OK |
| searchParams | Dans source | OK |

Aucune redirection vers client-dev ou preview.

---

## ÉTAPE 6 - Tracking website

### HTML rendu PROD

| Signal | Homepage | Pricing | Verdict |
|---|---|---|---|
| GA4 G-R3QQDYEBFG | 1 | 1 | OK |
| sGTM t.keybuzz.pro | 1 | 1 | OK |
| TikTok D7PT12JC77U44OJIPC10 | 0 (JS-loaded) | 0 (JS-loaded) | OK |
| Meta 1234164602194748 | 0 (JS-loaded) | 0 (JS-loaded) | OK |

### Bundle JS PROD (deep check)

| Signal | Fichiers JS | Verdict |
|---|---|---|
| GA4 G-R3QQDYEBFG | 1 | OK |
| sGTM t.keybuzz.pro | 2 | OK |
| TikTok D7PT12JC77U44OJIPC10 | 1 | OK |
| Meta 1234164602194748 | 1 | OK |
| LinkedIn 9969977 | **0** | **GAP** (voir ci-dessous) |
| trackViewPricing | 2 | OK |
| trackSelectPlan | 2 | OK |
| trackClickSignup | 2 | OK |

### Sécurité tracking

| Signal | Résultat | Verdict |
|---|---|---|
| Purchase browser event | 0 | OK |
| CompletePayment event | 0 | OK |
| api-dev leak | 0 | OK |
| client-dev leak | 0 | OK |
| preview.keybuzz.pro leak | 1 (PreviewBanner hostname check - attendu) | OK |
| sk_live | 0 | OK |
| sk_test | 0 | OK |
| NEXTAUTH_SECRET | 0 | OK |

### Gap LinkedIn

LinkedIn Insight Tag (9969977) n'est **pas implémenté côté website**. Aucun code LinkedIn n'a jamais été présent dans `keybuzz-website/src/`. Ce pixel peut exister via sGTM server-side. **Non bloquant pour Ads** - GA4, Meta, TikTok sont les canaux paid principaux.

---

## ÉTAPE 7 - Claims connecteurs

| Connecteur | Claim attendu | Claim observé | Verdict |
|---|---|---|---|
| Amazon | Disponible, connecteur principal | "Connexion sécurisée via API officielle" | OK |
| Email | Disponible | "La connexion e-mail est également disponible" | OK |
| Cdiscount/Octopia | Honnête | "Cdiscount via Octopia" | OK |
| Shopify | En préparation, pas connectable | "en préparation" (HP FAQ), "Bientôt" (pricing) | OK |
| Fnac/Darty | Bientôt | "en préparation" (HP FAQ) | OK |
| eBay | Non disponible | "Pas encore" (pricing FAQ uniquement) | OK |
| "toutes marketplaces" | Non claim | "toutes **vos** marketplaces" (description contextuelle) | OK |

Aucun claim trompeur.

---

## ÉTAPE 8 - QA visuelle desktop/mobile

QA effectuée via navigateur intégré.

### Homepage (`/`)

| Page | Viewport | Résultat visuel | Verdict |
|---|---|---|---|
| `/` | Mobile (viewport browser) | H1 lisible, CTAs visibles, 14 jours badge visible, trust badges, design propre | OK |
| `/` | DOM complet | 129 refs, toutes sections présentes, Reveal animations fonctionnelles au scroll | OK |

### Pricing (`/pricing`)

| Page | Viewport | Résultat visuel | Verdict |
|---|---|---|---|
| `/pricing` | Mobile | H1 visible, toggle visible, -20% badge vert, Starter 97€ visible | OK |
| `/pricing` | Scroll Starter | Features, "IA via packs KBActions en option", CTA "Démarrer simplement" | OK |
| `/pricing` | Scroll Pro | Features, 3 marketplaces, CTA "Essayer Pro" | OK |
| `/pricing` | Scroll Autopilot | Badge "Recommandé" **clairement visible en vert**, 497€/mois, features, CTA "Essayer Autopilot" | OK |
| `/pricing` | Scroll Enterprise | Features, CTA "Parler à un expert" | OK |

### Motion design

Le composant `Reveal` utilise `IntersectionObserver` pour animer l'apparition des sections au scroll. Le contenu est server-rendu dans le DOM (confirmé par ARIA snapshot), puis affiché avec une transition fade-in au scroll. Le `prefers-reduced-motion` est respecté par le composant.

Note : le navigateur automatisé peut montrer des zones vides entre les sections avant que le scroll ne déclenche l'animation - c'est le comportement attendu.

---

## ÉTAPE 9 - Performance / SEO light

| Point | Attendu | Résultat | Verdict |
|---|---|---|---|
| Title homepage | Présent et cohérent | "KeyBuzz - Support Client Marketplace Structuré" | OK |
| Meta description HP | Présente | "KeyBuzz structure, priorise et traite vos messages marketplace..." | OK |
| Title pricing | Présent | Identique à homepage (SEO minor) | OK (minor) |
| H1 homepage | Unique | "Automatisez votre SAV marketplace sans perdre le contrôle" | OK |
| H1 pricing | Unique | "Choisissez le niveau d'automatisation adapté à votre SAV" | OK |
| robots.txt | Allow / | "User-Agent: * Allow: / Disallow: /api/ /_next/" | OK |
| Sitemap | Présent | "Sitemap: https://www.keybuzz.pro/sitemap.xml" | OK |
| Favicon | Présent | 2 refs | OK |
| Erreur console | Aucune critique | Non observée | OK |
| 404 assets | Aucun | Non observé | OK |

Gap SEO mineur : la page `/pricing` utilise le même `<title>` que la homepage. Non bloquant Ads.

---

## ÉTAPE 10 - Non-régression services

| Service | Image attendue | Image runtime | Match | Verdict |
|---|---|---|---|---|
| API PROD | `v3.5.147-auto-assignment-after-reply-prod` | idem | Oui | OK |
| Client PROD | `v3.5.170-shopify-visible-disabled-channels-prod` | idem | Oui | OK |
| Backend PROD | `v1.0.47-cross-env-guard-fix-prod` | idem | Oui | OK |
| OW PROD | `v3.5.165-escalation-flow-prod` | idem | Oui | OK |
| DB | Non mutée | - | - | OK |
| Stripe | Non touché | - | - | OK |
| CAPI | Non envoyé | - | - | OK |
| Emails | Non envoyés | - | - | OK |

---

## ÉTAPE 12 - Gaps restants

| Gap | Ticket | Bloquant Ads ? | Action |
|---|---|---|---|
| LinkedIn 9969977 non implémenté côté website | - | Non (sGTM peut gérer) | Phase future si LinkedIn Ads prévu |
| Pricing `<title>` identique à homepage | - | Non | SEO cleanup futur |
| Shopify activation réelle | KEY-273 | Non | Activation post-App Approval |
| 17TRACK raw body signature | KEY-275 | Non | Hardening futur |
| Notification proactive escalade | KEY-263 | Non | Phase dédiée |

---

## Confirmation 0 impact

- 0 code modifié
- 0 build créé
- 0 image poussée
- 0 tag créé
- 0 deploy exécuté
- 0 rollback exécuté
- 0 mutation DB
- 0 mutation Stripe
- 0 checkout créé
- 0 paiement
- 0 fake event (GA4, Meta, TikTok, LinkedIn, CAPI)
- 0 modification tracking
- 0 modification Client/API/Backend/Admin/OW
- 0 secret exposé
- 0 PII dans le rapport

---

## Verdict

**GO ADS READY**

ADS FINAL CHECK PASSED - PAID SEARCH LANDING AND PRICING PROD VERIFIED - HOMEPAGE CONVERSION COPY / AMAZON SP-API TRUST / PRICING AUTOPILOT / 14 DAYS TRIAL / ANNUAL SAVINGS / CONNECTOR CLAIMS / UTM PROMO FORWARDING / TRACKING ALL CONFIRMED - NO FAKE EVENTS - NO CHECKOUT - NO PAYMENT - NO CODE - NO BUILD - NO DEPLOY - NO MUTATION - READY FOR ADS LAUNCH
