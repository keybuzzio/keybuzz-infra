# KeyBuzz — Knowledge Transfer : Server-Side Tracking Pipeline

## Perspective Agent Admin V2 (Cursor Executor)

> **Document de transfert de connaissances complet**
> Ce document retrace l'intégralité de la feature de tracking server-side marketing de KeyBuzz,
> vue depuis l'agent Admin V2 (Cursor Executor), avec les interactions avec l'agent SaaS API.
>
> Objectif : permettre à un agent IA ayant déjà une connaissance de KeyBuzz de comprendre
> l'historique exhaustif, horodaté, de cette feature avec : les prompts d'origine, ce qui a été fait,
> pourquoi, comment, et quels documents ont été générés.
>
> Chaque rapport individuel référencé est accessible dans `keybuzz-infra/docs/`.
> Le document de base produit par l'agent SaaS est : `keybuzz-infra/docs/KNOWLEDGE-TRANSFER-SERVER-SIDE-TRACKING-COMPLETE.md`
>
> Dernière mise à jour : 22 avril 2026

---

## TABLE DES MATIÈRES

1. [Contexte général et architecture des agents](#1-contexte-général)
2. [Chronologie complète (28 phases)](#2-chronologie)
3. [Phases SaaS API — Backend marketing (résumé)](#3-phases-saas)
4. [Phase T8.3.1 — Metrics UI Basic (Admin V2)](#phase-t831)
5. [Phase T8.3.1B — No-Data UI Fix](#phase-t831b)
6. [Phase T8.3.1C — Currency Mapping Fix](#phase-t831c)
7. [Phase T8.3.1-PROD-PROMOTION-02 — Première promo PROD Metrics](#phase-t831-prod)
8. [Phase T8.3.1D — Trial/Paid Alignment](#phase-t831d)
9. [Phase T8.3.1D-PROD — PROD Promotion Metrics Final](#phase-t831d-prod)
10. [Phase T8.3.1E — Admin Internal API Fix](#phase-t831e)
11. [Phase T8.6B — Media Buyer Admin UI](#phase-t86b)
12. [Phase T8.6B-FIX — Marketing Proxy Fix](#phase-t86b-fix)
13. [Phase T8.6C Admin — PROD Promotion Marketing](#phase-t86c-admin)
14. [Fondation Multi-Tenant Admin V2](#fondation-multi-tenant)
15. [Coordination inter-agents](#coordination)
16. [Architecture technique finale](#architecture)
17. [Index complet des documents](#index-documents)
18. [État final et prochaines étapes](#etat-final)

---

## 1. Contexte général et architecture des agents {#1-contexte-général}

### Le pipeline server-side tracking

Le tracking server-side marketing de KeyBuzz est un pipeline complet permettant :

- **Collecter** les événements de conversion réels (StartTrial, Purchase) depuis les webhooks Stripe
- **Enrichir** ces événements avec l'attribution marketing (UTMs, click IDs) captée au signup
- **Émettre** ces événements vers des destinations webhook configurables par tenant
- **Mesurer** les métriques business (CAC, ROAS, MRR, trial/paid) via une API dédiée
- **Visualiser** le tout dans une UI Admin V2 dédiée aux media buyers
- **Sécuriser** le pipeline avec exclusion des comptes test, HMAC, RBAC, et isolation tenant

### Deux agents Cursor, deux repos

Le pipeline a été construit en ~28 phases sur 3 jours (20-22 avril 2026) par deux agents indépendants :

| Agent | Repo | Stack | Branche | Bastion |
|---|---|---|---|---|
| **Agent SaaS API** | `keybuzz-api` | Node.js / Fastify / TypeScript | `ph147.4/source-of-truth` | `/opt/keybuzz/keybuzz-api/` |
| **Agent Admin V2** | `keybuzz-admin-v2` | Next.js 14 / Metronic / TypeScript | `main` | `/opt/keybuzz/keybuzz-admin-v2/` |

### Comment les deux agents se coordonnent

Les deux agents ne communiquent **jamais directement**. La coordination passe par :

1. L'agent SaaS crée/modifie des endpoints API et documente le format du payload
2. L'utilisateur (Ludovic) transmet le contexte à l'agent Admin V2 : docs générés, format payload, endpoints disponibles
3. L'agent Admin V2 consomme ces endpoints via un proxy Next.js interne (`/api/admin/...` → backend SaaS)
4. Chaque agent documente son travail dans `keybuzz-infra/docs/` sur le bastion
5. Les rapports servent de contrat d'interface entre les deux agents

### Infrastructure commune

- **Bastion** : `46.62.171.61` (accès SSH)
- **Infra repo** : `keybuzz-infra` (GitHub: keybuzzio/keybuzz-infra)
- **K8s namespaces** :
  - SaaS DEV : `keybuzz-api-dev` / PROD : `keybuzz-api-prod`
  - Admin DEV : `keybuzz-admin-v2-dev` / PROD : `keybuzz-admin-v2-prod`
- **Registry** : `ghcr.io/keybuzzio/keybuzz-admin` et `ghcr.io/keybuzzio/keybuzz-api`
- **Build** : toujours `build-from-git` (clone propre, repo clean, commit pushé avant build)
- **Déploiement** : GitOps strict (manifests K8s dans `keybuzz-infra/k8s/`)

---

## 2. Chronologie complète {#2-chronologie}

| Date | Heure ~ | Phase | Agent | Env | Résumé | Document |
|------|---------|-------|-------|-----|--------|----------|
| 20 avr | matin | PH-T8.1-2 | SaaS | DEV | Data foundation + endpoint `/metrics/overview` | `PH-T8.1-2-DATA-FOUNDATION-AND-METRICS-01.md` |
| 20 avr | matin | PH-T8.2 | SaaS | DEV | Purge mock data, source de vérité réelle | `PH-T8.2-REAL-SPEND-TRUTH-01.md` |
| 20 avr | matin | PH-T8.2B | SaaS | DEV | Intégration Meta Graph API real spend | `PH-T8.2B-META-REAL-SPEND-01-REPORT.md` |
| 20 avr | midi | PH-T8.2C | SaaS | DEV | Normalisation devises EUR (fx ECB) | `PH-T8.2C-CURRENCY-NORMALIZATION-01.md` |
| 20 avr | midi | PH-T8.2D | SaaS | DEV | Distinction trial vs paid dans metrics | `PH-T8.2D-TRIAL-VS-PAID-METRICS-01.md` |
| 20 avr | AM | PH-T8.2E | SaaS | PROD | Promotion PROD de T8.2B/C/D | `PH-T8.2E-PROD-PROMOTION-METRICS-01.md` |
| 20 avr | AM | PH-T8.2Ebis | SaaS | DEV+PROD | Exclusion comptes test des metrics | `PH-T8.2Ebis-EXCLUDE-TEST-DATA-01.md` |
| 20 avr | AM | PH-T8.2F | SaaS | DEV+PROD | Système explicite `tenant_billing_exempt` | `PH-T8.2F-TEST-ACCOUNT-CONTROL-01.md` |
| 20 avr | AM | **PH-T8.3.1** | **Admin V2** | DEV | Page `/metrics` dans Admin V2 | `PH-T8.3.1-METRICS-UI-BASIC-REPORT.md` |
| 20 avr | AM | **PH-T8.3.1B** | **Admin V2** | DEV | Fix crash UI quand no data | `PH-T8.3.1B-METRICS-NO-DATA-UI-FIX-REPORT.md` |
| 20 avr | AM | **PH-T8.3.1C** | **Admin V2** | DEV | Fix mapping devises / spend_eur | `PH-T8.3.1C-METRICS-CURRENCY-MAPPING-FIX-REPORT.md` |
| 20 avr | PM | **PH-T8.3.1-PROD** | **Admin V2** | PROD | Première promotion PROD metrics | `PH-T8.3.1-PROD-PROMOTION-02-REPORT.md` |
| 20 avr | PM | **PH-T8.3.1D** | **Admin V2** | DEV | Alignement UI trial/paid + CAC/ROAS | `PH-T8.3.1D-METRICS-TRIAL-PAID-ALIGNMENT-REPORT.md` |
| 20 avr | soir | **PH-T8.3.1D-PROD** | **Admin V2** | PROD | Promotion PROD Admin metrics final | `PH-T8.3.1D-PROD-PROMOTION-REPORT.md` |
| 20 avr | soir | **PH-T8.3.1E** | **Admin V2** | PROD | Fix proxy interne port K8s 80 | `PH-T8.3.1E-ADMIN-INTERNAL-API-FIX-REPORT.md` |
| 21 avr | matin | PH-T8.4 | SaaS | DEV | Outbound conversions webhook (HMAC, idempotence) | `PH-T8.4-OUTBOUND-CONVERSIONS-WEBHOOK-01-REPORT.md` |
| 21 avr | matin | PH-T8.4.1 | SaaS | DEV | Valeur réelle Stripe (plus de PLAN_PRICES) | `PH-T8.4.1-STRIPE-REAL-VALUE-01.md` |
| 21 avr | midi | PH-T8.4.1-PROD | SaaS | PROD | Promotion PROD valeur Stripe | `PH-T8.4.1-STRIPE-REAL-VALUE-PROD-PROMOTION-01.md` |
| 21 avr | midi | PH-T8.5 | SaaS | — | Documentation agence / media buyer | `PH-T8.5-AGENCY-INTEGRATION-DOC-01.md` |
| 21 avr | AM | PH-T8.5.1 | SaaS | PROD | Test webhook.site temporaire en PROD | `PH-T8.5.1-WEBHOOK-SITE-PROD-TEST-01.md` |
| 21 avr | AM | PH-T8.6A | SaaS | DEV | API self-service destinations webhook | `PH-T8.6A-OUTBOUND-DESTINATIONS-API-01.md` |
| 21 avr | PM | **PH-T8.6B** | **Admin V2** | DEV | Rôle media_buyer + UI Marketing | `PH-T8.6B-MEDIA-BUYER-ADMIN-UI-01.md` |
| 21 avr | soir | **PH-T8.6B-FIX** | **Admin V2** | DEV | Fix proxy/RBAC marketing | `PH-T8.6B-MARKETING-PROXY-FIX-02.md` |
| 22 avr | matin | PH-T8.6C SaaS | SaaS | PROD | Promotion PROD API destinations | `PH-T8.6C-SAAS-PROD-PROMOTION-01.md` |
| 22 avr | matin | **PH-T8.6C Admin** | **Admin V2** | PROD | Promotion PROD Admin media buyer | `PH-T8.6C-ADMIN-PROD-PROMOTION-02.md` |
| 22 avr | midi | PH-T8.7A | SaaS | DEV | Fondation attribution tenant-native | `PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-01.md` |
| 4 mars | — | **TENANT-01** | **Admin V2** | DEV | Fondation multi-tenant Admin V2 | `PH-ADMIN-TENANT-FOUNDATION-01.md` |
| 22 avr | AM | **TENANT-02** | **Admin V2** | PROD | Promotion PROD fondation multi-tenant | `PH-ADMIN-TENANT-FOUNDATION-02-PROD-PROMOTION.md` |

---

## 3. Phases SaaS API — Résumé backend {#3-phases-saas}

Ces phases ont été exécutées par l'agent SaaS dans une conversation séparée. Le détail complet est dans :

**`keybuzz-infra/docs/KNOWLEDGE-TRANSFER-SERVER-SIDE-TRACKING-COMPLETE.md`**

### Résumé de ce que l'agent SaaS a construit

| Phase | Ce qui a été créé | Impact sur Admin V2 |
|---|---|---|
| T8.1-2 | Endpoint `GET /metrics/overview` + table `ad_spend` | Admin doit consommer cet endpoint |
| T8.2 | Purge mock data, mode strict (`spend=0`, `cac=null`) | Admin doit gérer les valeurs nulles |
| T8.2B | Import Meta Graph API → `ad_spend` réel | Admin reçoit du vrai spend |
| T8.2C | Normalisation EUR, champs `spend_eur`, `total_eur`, bloc `fx` | Admin doit mapper les nouveaux champs |
| T8.2D | Breakdown trial/paid, `conversion.trial_to_paid_rate` | Admin doit afficher trial vs paid |
| T8.2E | Promotion PROD metrics | Admin peut consommer en PROD |
| T8.2Ebis | Exclusion comptes test heuristique | Metrics plus fiables |
| T8.2F | Table `tenant_billing_exempt` explicite | Source de vérité test accounts |
| T8.4 | Outbound conversions webhook (HMAC, idempotence) | Fondation du pipeline outbound |
| T8.4.1 | Valeur réelle Stripe (pas de PLAN_PRICES) | Valeurs exactes dans events |
| T8.5 | Documentation agence / media buyer | Guide pour l'UI documentation |
| T8.6A | API CRUD destinations webhook self-service | Admin doit créer l'UI destinations |
| T8.7A | Metrics tenant-scoped + framework platform-native | Admin peut filtrer par tenant |

### Fichiers source clés côté SaaS API (sur le bastion)

| Fichier | Rôle |
|---|---|
| `/opt/keybuzz/keybuzz-api/src/modules/metrics/routes.ts` | Endpoint /metrics/overview + import Meta |
| `/opt/keybuzz/keybuzz-api/src/modules/outbound-conversions/emitter.ts` | Émission conversions multi-destination |
| `/opt/keybuzz/keybuzz-api/src/modules/outbound-conversions/routes.ts` | API destinations self-service |
| `/opt/keybuzz/keybuzz-api/src/modules/billing/routes.ts` | Webhooks Stripe → déclenchement conversions |

### Tables DB marketing

| Table | Rôle |
|---|---|
| `signup_attribution` | Attribution marketing au signup (UTMs, click IDs) |
| `conversion_events` | Suivi idempotent des événements émis |
| `outbound_conversion_destinations` | Destinations webhook par tenant |
| `outbound_conversion_delivery_logs` | Logs de livraison par destination |
| `tenant_billing_exempt` | Exclusion explicite comptes test |
| `ad_spend` | Spend publicitaire par canal et par jour |
| `billing_subscriptions` | État subscription Stripe par tenant |
| `billing_customers` | Lien Stripe customer ↔ tenant |

---

<a id="phase-t831"></a>
## 4. PH-T8.3.1 — Metrics UI Basic (Admin V2)

**Date** : 20 avril 2026
**Agent** : Admin V2
**Environnement** : DEV
**Image** : `v2.10.3-ph-t8-3-1-metrics-dev`

### Prompt d'origine (complet)

```
Prompt CE — PH-T8.3.1

Rôle : Cursor Executor (CE)
Projet : KeyBuzz Admin V2
Phase : PH-T8.3.1-METRICS-UI-BASIC-01
Environnements : DEV d'abord, PROD ensuite seulement si validé
Type : intégration UI business / marketing dans Admin V2

Objectif

Créer une page /metrics dans Admin V2 qui consomme proprement l'endpoint existant
GET /metrics/overview pour afficher les métriques business/marketing déjà calculées
côté API, sans modifier le backend SaaS et sans créer de nouvelle logique métrique.

Règles absolues
NE PAS toucher au backend SaaS
NE PAS modifier /metrics/overview
NE PAS recalculer la logique métier côté frontend
NE PAS casser Admin V2 existant
build-from-git obligatoire
repo clean obligatoire
GitOps strict obligatoire
rollback DEV et PROD obligatoires
aucun kubectl set image
aucun build dirty
aucun hardcoding
aucun mock
aucun faux graphique
aucune promotion PROD sans validation explicite
```

### Contexte inter-agents

L'agent SaaS venait de terminer T8.1-2, T8.2, T8.2B, T8.2C, T8.2D (toute la fondation metrics backend). L'utilisateur a transmis le format exact du payload `GET /metrics/overview` pour que l'agent Admin V2 puisse créer l'UI sans modifier le backend.

### Ce qui a été fait

1. **Audit initial** : vérification de la structure Admin V2, de l'endpoint proxy existant, du format payload
2. **Proxy Next.js** : route `/api/admin/metrics/overview` créée dans Admin V2, qui forward la requête vers le backend SaaS via `KEYBUZZ_API_INTERNAL_URL`
3. **Page `/metrics`** : création complète avec :
   - KPI cards : New Customers, MRR, CAC Blended, ROAS
   - Spend par canal (tableau avec devise)
   - Conversion rate (trial → paid)
   - Date picker pour filtrer par période
   - Indicateur data quality
4. **Build** : image `v2.10.3-ph-t8-3-1-metrics-dev` buildée et déployée en DEV
5. **Fichiers créés/modifiés** :
   - `src/app/(admin)/metrics/page.tsx` — page metrics complète
   - `src/app/api/admin/metrics/overview/route.ts` — proxy vers backend
   - Sidebar mise à jour pour inclure le lien `/metrics`

### Pourquoi

Admin V2 n'avait aucune capacité de visualisation marketing. Les données étaient calculées côté API mais inaccessibles depuis l'interface admin. Cette page est la première brique de l'UI marketing.

### Documents générés

- **`keybuzz-infra/docs/PH-T8.3.1-METRICS-UI-BASIC-AUDIT.md`** — audit pré-implémentation
- **`keybuzz-infra/docs/PH-T8.3.1-METRICS-UI-BASIC-REPORT.md`** — rapport complet

---

<a id="phase-t831b"></a>
## 5. PH-T8.3.1B — No-Data UI Fix

**Date** : 20 avril 2026
**Agent** : Admin V2
**Environnement** : DEV

### Prompt d'origine (complet)

```
Prompt CE — PH-T8.3.1B-METRICS-NO-DATA-UI-FIX-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz Admin V2
Phase : PH-T8.3.1B-METRICS-NO-DATA-UI-FIX-01
Environnements : DEV uniquement d'abord
Type : fix UI ciblé / robustesse no-data

Objectif

Corriger la page /metrics dans Admin V2 pour qu'elle supporte proprement
le mode strict introduit par PH-T8.2 :

spend.total = 0
spend.by_channel = []
cac = null
roas = null
spend.source = "no_data"
data_quality.spend_available = false

Comportement attendu :

aucune erreur client-side
aucune exception React
page /metrics affichée proprement
états "aucune donnée réelle de spend" honnêtes
aucune donnée fake réintroduite

Règles absolues
NE PAS toucher au backend SaaS
NE PAS modifier /metrics/overview
NE PAS réintroduire de mock
NE PAS recalculer du CAC/ROAS côté frontend
NE PAS casser Admin V2 existant
build-from-git obligatoire
repo clean obligatoire
```

### Contexte

Après T8.2 (purge mock), l'API retournait `cac=null`, `roas=null`, `spend.total=0`. L'UI crashait car elle tentait de formater ces valeurs nulles en nombres/pourcentages.

### Ce qui a été fait

1. Ajout de `safeNum()` helper : retourne `'N/A'` si la valeur est `null` ou `undefined`
2. Protection de tous les KPI cards contre les valeurs nulles
3. Message contextuel "Aucune donnée de spend réelle disponible" quand `spend.source === 'no_data'`
4. Tableau by_channel masqué si vide
5. Build + déploiement DEV

### Pourquoi

Quand l'API passe en mode strict (pas de mock), l'UI doit être résiliente aux données absentes sans crasher et sans réintroduire du fake.

### Document généré

- **`keybuzz-infra/docs/PH-T8.3.1B-METRICS-NO-DATA-UI-FIX-REPORT.md`**

---

<a id="phase-t831c"></a>
## 6. PH-T8.3.1C — Currency Mapping Fix

**Date** : 20 avril 2026
**Agent** : Admin V2
**Environnement** : DEV

### Prompt d'origine (complet)

```
🔥 PROMPT CE — PH-T8.3.1C-METRICS-CURRENCY-MAPPING-FIX-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz Admin V2
Phase : PH-T8.3.1C-METRICS-CURRENCY-MAPPING-FIX-01
Environnements : DEV uniquement
Type : fix UI — adaptation au nouveau payload metrics (PH-T8.2C)

🎯 OBJECTIF

Corriger les erreurs NaN € sur la page /metrics suite à l'évolution du payload API
introduite par :

PH-T8.2B → Meta spend réel
PH-T8.2C → normalisation EUR + nouveaux champs

👉 L'Admin doit maintenant :

consommer correctement le nouveau payload
ne jamais produire de NaN
rester 100% fidèle aux données backend
ne jamais recalculer de métriques métier

🔴 CONTEXTE TECHNIQUE (IMPORTANT)

Avant PH-T8.2C :
spend.total
spend.by_channel[].spend

Après PH-T8.2C :
spend.total_eur
spend.by_channel[].spend_eur
spend.by_channel[].spend_raw
spend.by_channel[].currency_raw
fx: { ... }
data_quality: { ... }

👉 Le frontend doit mapper sur les NOUVEAUX champs, pas les anciens.
```

### Contexte inter-agents

L'agent SaaS avait changé la structure du payload en T8.2C (normalisation EUR). Les anciens champs `spend.total` et `spend.by_channel[].spend` existaient encore par backward compat, mais en GBP brut. L'UI affichait du GBP étiqueté comme EUR → NaN ou montants faux.

### Ce qui a été fait

1. Remplacement `spend.total` → `spend.total_eur` partout dans la page metrics
2. Remplacement `channel.spend` → `channel.spend_eur` dans le tableau par canal
3. Ajout colonne `currency_raw` / `spend_raw` pour transparence
4. Ajout indicateur FX (taux de change, source ECB)
5. Utilisation systématique de `safeNum()` sur tous les champs numériques

### Pourquoi

C'est un cas classique de désynchronisation frontend/backend. L'API avait évolué (nouveaux champs EUR) mais le frontend consommait encore les anciens champs (montant brut GBP). Sans ce fix, les media buyers voyaient des CAC/ROAS en GBP étiquetés EUR.

### Document généré

- **`keybuzz-infra/docs/PH-T8.3.1C-METRICS-CURRENCY-MAPPING-FIX-REPORT.md`**

---

<a id="phase-t831-prod"></a>
## 7. PH-T8.3.1-PROD-PROMOTION-02 — Première promo PROD Metrics

**Date** : 20 avril 2026
**Agent** : Admin V2
**Environnement** : PROD
**Image** : `v2.10.5-ph-t8-3-1-metrics-prod` (approx)

### Prompt d'origine (complet)

```
Prompt CE — PH-T8.3.1-PROD-PROMOTION-02

Rôle : Cursor Executor (CE)
Projet : KeyBuzz Admin V2
Phase : PH-T8.3.1-PROD-PROMOTION-02
Environnement : PROD
Type : promotion PROD contrôlée de la page /metrics Admin V2

🎯 OBJECTIF

Promouvoir en PROD la feature /metrics d'Admin V2, incluant sans omission :

PH-T8.3.1 — Metrics UI Basic
PH-T8.3.1B — No-data UI fix
PH-T8.3.1C — Currency mapping / anti-NaN fix

Le backend SaaS PROD est désormais aligné et prêt :

spend Meta réel
normalisation EUR
trial vs paid
exclusion explicite des comptes test
backward compatibility maintenue sur new_customers, cac, roas

👉 Cette phase concerne Admin V2 uniquement.

🔴 RÈGLES ABSOLUES
GitOps strict obligatoire
build-from-git obligatoire
repo clean obligatoire
commit + push avant build
aucun kubectl set image
aucun hotfix bastion
aucun hardcode
aucun mock
aucun recalcul CAC/ROAS côté frontend
rollback documenté obligatoire
```

### Ce qui a été fait

1. Preflight : vérification branche, repo clean, HEAD = remote
2. Build PROD depuis clone propre
3. GitOps : manifest PROD mis à jour
4. Déploiement : rollout restart, pod running, image vérifiée
5. Validation : page /metrics accessible en PROD, KPI cards affichés

### Document généré

- **`keybuzz-infra/docs/PH-T8.3.1-PROD-PROMOTION-02-REPORT.md`**

---

<a id="phase-t831d"></a>
## 8. PH-T8.3.1D — Trial/Paid Alignment

**Date** : 20 avril 2026
**Agent** : Admin V2
**Environnement** : DEV

### Prompt d'origine (complet)

```
🔥 PROMPT CE — PH-T8.3.1D-METRICS-TRIAL-PAID-ALIGNMENT-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz Admin V2
Phase : PH-T8.3.1D-METRICS-TRIAL-PAID-ALIGNMENT-01
Environnement : DEV → puis PROD après validation
Type : amélioration UI business metrics (aucune modif backend)

🎯 OBJECTIF

Aligner la page /metrics avec la réalité business introduite par :

PH-T8.2B — Meta spend réel
PH-T8.2C — EUR normalization
PH-T8.2D — trial vs paid
PH-T8.2F — test account exclusion

👉 L'Admin doit maintenant afficher :

CAC réel (paid)
ROAS réel
Trial vs Paid
Qualité des données (test_data_excluded)

⚠️ Sans casser :

compatibilité existante
UI actuelle
backend
GitOps
stabilité PROD

🔴 RÈGLES ABSOLUES
❌ NE PAS toucher au backend SaaS
❌ NE PAS modifier /metrics/overview
❌ NE PAS recalculer CAC/ROAS côté frontend
❌ NE PAS casser l'UI actuelle
❌ NE PAS supprimer les KPI existants
❌ NE PAS introduire de mock
✅ afficher honnêtement
✅ trial vs paid séparés
✅ CAC paid = la vraie métrique
✅ data quality = qualité des données affichée
```

### Contexte inter-agents

L'agent SaaS avait enrichi le payload en T8.2D avec `customers.trial`, `customers.paid`, `customers.no_subscription`, `conversion.trial_to_paid_rate`, et `customers_by_plan`. L'UI devait être alignée pour afficher cette distinction critique.

### Ce qui a été fait

1. Section "Customers Breakdown" : cards séparées Trial / Paid / No Subscription
2. CAC affiché en deux variantes : Blended (tous) et Paid (payants uniquement)
3. Ajout ROAS détaillé avec période
4. Conversion rate trial→paid mis en évidence
5. Breakdown par plan (Starter / Pro / Autopilot)
6. Data quality badges : "Test data excluded", "Real spend (Meta)", etc.
7. Build DEV

### Pourquoi

Un media buyer ne peut pas piloter ses campagnes si le CAC mélange trial et paid. Un trial à 0€ pendant 14 jours fausse complètement le CAC. La distinction est la métrique la plus importante pour l'optimisation.

### Document généré

- **`keybuzz-infra/docs/PH-T8.3.1D-METRICS-TRIAL-PAID-ALIGNMENT-REPORT.md`**

---

<a id="phase-t831d-prod"></a>
## 9. PH-T8.3.1D-PROD — PROD Promotion Metrics Final

**Date** : 20 avril 2026 (soir)
**Agent** : Admin V2
**Environnement** : PROD
**Image** : `v2.10.6-ph-t8-3-1d-metrics-trial-paid-prod`

### Prompt d'origine (complet)

```
🔥 PROMPT CE — PH-T8.3.1D-PROD-PROMOTION-01 (SAFE)

Rôle : Cursor Executor (CE)
Projet : KeyBuzz Admin V2
Phase : PH-T8.3.1D-PROD-PROMOTION-01
Environnement : PROD
Type : Promotion contrôlée Admin V2 — Metrics Business (trial/paid)

🎯 OBJECTIF

Promouvoir en PROD la version Admin V2 :

v2.10.6-ph-t8-3-1d-metrics-trial-paid

incluant :

PH-T8.3.1 → Metrics UI
PH-T8.3.1B → No-data safe
PH-T8.3.1C → Currency mapping EUR
PH-T8.3.1D → Trial vs Paid + Data Quality

👉 Résultat attendu :

Dashboard Metrics = pilotage business réel (CAC paid, ROAS, trial/paid)

🔴 RÈGLES ABSOLUES
GIT / BUILD
build-from-git obligatoire
repo clean obligatoire (git status = clean)
commit + push AVANT build
AUCUN docker build depuis bastion dirty
image buildée = image déployée = version runtime

GITOPS
modification via manifest uniquement
commit + push infra obligatoire
AUCUN kubectl set image
AUCUN patch manuel
```

### Ce qui a été fait

1. Build PROD `v2.10.6-ph-t8-3-1d-metrics-trial-paid-prod`
2. GitOps PROD : manifest mis à jour, commit + push infra
3. Rollout PROD, pod Running, image vérifiée
4. Validation navigateur : page /metrics PROD fonctionnelle
5. Rollback documenté

### Document généré

- **`keybuzz-infra/docs/PH-T8.3.1D-PROD-PROMOTION-REPORT.md`**

---

<a id="phase-t831e"></a>
## 10. PH-T8.3.1E — Admin Internal API Fix

**Date** : 20 avril 2026 (soir)
**Agent** : Admin V2
**Environnement** : DEV + PROD

### Prompt d'origine (complet)

```
🔥 PROMPT CE — PH-T8.3.1E-ADMIN-INTERNAL-API-FIX-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz Admin V2
Phase : PH-T8.3.1E-ADMIN-INTERNAL-API-FIX-01
Environnement : DEV + PROD
Type : correction infra / routing interne Admin → API

🎯 OBJECTIF

Corriger et sécuriser définitivement :

KEYBUZZ_API_INTERNAL_URL

afin que :

Admin → API fonctionne en interne
aucun timeout
aucune dépendance fragile
comportement identique DEV / PROD

🔴 RÈGLES ABSOLUES
❌ NE PAS toucher au backend SaaS
❌ NE PAS modifier /metrics/overview
❌ NE PAS toucher au code métier API
❌ NE PAS patcher en live sans Git
❌ aucun kubectl set image
❌ aucun hotfix non commit
✅ GitOps obligatoire
✅ commit infra obligatoire
✅ rollback obligatoire
✅ validation inter-pod obligatoire
```

### Le problème

En PROD, le service K8s du backend SaaS écoute sur le port **80** (pas 3001 comme en DEV). Le proxy Admin V2 envoyait les requêtes metrics sur le mauvais port, causant des timeouts en PROD.

### Ce qui a été fait

1. Audit des services K8s : `kubectl get svc -n keybuzz-api-dev` et `keybuzz-api-prod`
2. Identification : DEV = port 3001, PROD = port 80
3. Correction : `KEYBUZZ_API_INTERNAL_URL` dans le ConfigMap PROD ajusté pour utiliser le port 80
4. Validation inter-pod : curl depuis le pod Admin vers le pod API en interne
5. GitOps : commit + push infra

### Pourquoi

C'est un problème d'infrastructure classique. La page /metrics PROD affichait une erreur de timeout car le proxy ne pouvait pas joindre le backend. La correction du port a résolu le problème immédiatement.

### Document généré

- **`keybuzz-infra/docs/PH-T8.3.1E-ADMIN-INTERNAL-API-FIX-REPORT.md`**

---

<a id="phase-t86b"></a>
## 11. PH-T8.6B — Media Buyer Admin UI

**Date** : 21 avril 2026
**Agent** : Admin V2
**Environnement** : DEV
**Image** : `v2.10.8-ph-t8-6b-media-buyer-dev`

### Prompt d'origine (complet)

```
🔥 PH-T8.6B-MEDIA-BUYER-ADMIN-UI-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz Admin V2
Phase : PH-T8.6B-MEDIA-BUYER-ADMIN-UI-01
Environnement : DEV uniquement
Type : rôle media_buyer + UI self-service marketing
Priorité : STRATÉGIQUE

🎯 OBJECTIF

Créer dans Admin V2 un rôle media_buyer permettant à une agence ou un media buyer
d'être 100% autonome pour :

consulter les métriques server-side
configurer une destination webhook
tester une intégration
consulter les logs de livraison
comprendre le système via une documentation intégrée

👉 Sans intervention de Ludovic
👉 Sans accès aux zones sensibles Admin

🔴 RÈGLES ABSOLUES
ENVIRONNEMENT
DEV ONLY
AUCUN impact PROD
STOP avant promotion

BUILD / SOURCE OF TRUTH
build-from-git obligatoire
repo clean obligatoire
commit + push AVANT build
AUCUN build depuis working dir bastion
image = code Git uniquement

GITOPS
manifest DEV uniquement
commit + push infra obligatoire
AUCUN kubectl set image
```

### Contexte inter-agents

L'agent SaaS venait de terminer T8.6A (API destinations webhook self-service). L'utilisateur a demandé à l'agent Admin V2 de créer l'UI complète correspondante, avec un rôle dédié `media_buyer`.

### Ce qui a été fait

1. **Nouveau rôle `media_buyer`** :
   - Ajouté dans `AdminRole` type
   - Configuré dans `rbac.ts` : permissions lecture metrics + gestion destinations
   - Hiérarchie RBAC : `super_admin > ops_admin > account_manager > media_buyer > agent > viewer`
   - Routes autorisées : `/metrics`, `/marketing/*`

2. **Nouvelle section Marketing dans la sidebar** :
   - Icône dédiée, accessible aux rôles `media_buyer` et supérieurs
   - 4 sous-pages :
     - `/marketing/destinations` — liste des destinations webhook
     - `/marketing/delivery-logs` — logs de livraison (succès/échec/retry)
     - `/marketing/integration-guide` — documentation embarquée
     - `/metrics` — page métriques (déjà existante, rendue accessible)

3. **Pages créées** :
   - `src/app/(admin)/marketing/destinations/page.tsx` — CRUD destinations
   - `src/app/(admin)/marketing/delivery-logs/page.tsx` — table paginée des logs
   - `src/app/(admin)/marketing/integration-guide/page.tsx` — guide intégré

4. **Proxy Next.js** :
   - `src/app/api/admin/marketing/destinations/route.ts` — proxy vers SaaS API `/outbound-conversions/destinations`
   - `src/app/api/admin/marketing/destinations/[id]/route.ts` — proxy PATCH/DELETE
   - `src/app/api/admin/marketing/destinations/[id]/test/route.ts` — proxy test destination
   - `src/app/api/admin/marketing/destinations/[id]/regenerate-secret/route.ts` — proxy regenerate
   - `src/app/api/admin/marketing/delivery-logs/route.ts` — proxy logs

5. **Build** : image `v2.10.8-ph-t8-6b-media-buyer-dev` déployée en DEV

### Pourquoi

C'est la pièce manquante pour l'autonomie des media buyers. Avant cette phase, configurer une destination webhook nécessitait une intervention infra (modifier les env vars K8s). Avec l'UI self-service, un media buyer peut :
- Ajouter une destination webhook (Meta CAPI, TikTok, sGTM, Zapier...)
- Tester la connexion (événement ConnectionTest)
- Consulter les logs de livraison
- Comprendre le système via la documentation intégrée

### Document généré

- **`keybuzz-infra/docs/PH-T8.6B-MEDIA-BUYER-ADMIN-UI-01.md`**

---

<a id="phase-t86b-fix"></a>
## 12. PH-T8.6B-FIX — Marketing Proxy Fix

**Date** : 21 avril 2026 (soir)
**Agent** : Admin V2 + SaaS (interaction)
**Environnement** : DEV

### Le problème (3 issues identifiées)

1. **Chemins API incorrects** : les routes proxy Admin ne correspondaient pas aux routes backend SaaS
2. **Headers auth manquants** : `x-user-email` et `x-tenant-id` n'étaient pas propagés vers le backend
3. **RBAC impossible** : les utilisateurs admin ne sont PAS dans la table `user_tenants` du SaaS → le checkAccess du backend renvoyait "Insufficient permissions"

### Interaction inter-agents remarquable

Ce fix a nécessité un **aller-retour entre les deux agents** :

1. L'agent Admin V2 a identifié le problème côté proxy (erreurs 403/404)
2. L'utilisateur a transmis le diagnostic à l'agent SaaS
3. **L'agent SaaS a ajouté un bypass admin** dans les routes destinations :
   - Commit `536d3340` : `fix(outbound): add admin bypass for internal proxy calls`
   - Si le header `x-admin-role` est `super_admin` ou `ops_admin`, le checkAccess est bypassé
4. L'agent Admin V2 a ensuite corrigé les chemins et ajouté les headers nécessaires :
   - `x-user-email` : email de session NextAuth
   - `x-tenant-id` : tenant sélectionné par le selector global
   - `x-admin-role` : rôle de l'utilisateur admin

### Ce qui a été fait (côté Admin V2)

1. Correction des chemins proxy : alignement avec les routes backend SaaS
2. Ajout propagation headers : `x-user-email`, `x-tenant-id`, `x-admin-role`
3. Tenant selector intégré dans les pages marketing (avant la fondation multi-tenant globale)
4. Build + déploiement DEV

### Pourquoi

Sans ce fix, toute la section Marketing était inutilisable : les requêtes du proxy échouaient systématiquement en 403 ou 404. C'est un exemple typique de la nécessité de coordination entre les deux agents.

### Document généré

- **`keybuzz-infra/docs/PH-T8.6B-MARKETING-PROXY-FIX-02.md`**

---

<a id="phase-t86c-admin"></a>
## 13. PH-T8.6C Admin — PROD Promotion Marketing

**Date** : 22 avril 2026
**Agent** : Admin V2
**Environnement** : PROD
**Image** : `v2.10.9-admin-access-fix-prod`

### Prompt d'origine (complet)

```
PROMPT CE — PH-T8.6C-ADMIN-PROD-PROMOTION-02

Rôle : Cursor Executor (CE)
Projet : KeyBuzz Admin V2
Phase : PH-T8.6C-ADMIN-PROD-PROMOTION-02
Environnement : PROD
Type : promotion PROD UI media_buyer + marketing self-service
Priorité : CRITIQUE

🎯 OBJECTIF

Promouvoir en PROD la couche Admin V2 self-service marketing validée en DEV, incluant :

rôle media_buyer
section Marketing
Marketing / Metrics
Marketing / Destinations
Marketing / Delivery Logs
Marketing / Integration Guide
proxy Admin aligné avec le backend SaaS PROD déjà promu
tenant selector marketing
support media_buyer dans l'accès aux métriques marketing

👉 Le backend SaaS PROD étant désormais prêt, cette phase concerne Admin V2 uniquement.

🔴 RÈGLES ABSOLUES
BUILD / SOURCE OF TRUTH
build-from-git obligatoire
repo clean obligatoire
commit + push AVANT build
aucun build depuis working dir dirty
image buildée = image déployée = version visible

GITOPS
GitOps strict obligatoire
manifests PROD uniquement
aucun kubectl set image
aucun patch live artisanal
```

### Prérequis

Le backend SaaS PROD avait été promu en T8.6C-SaaS avec l'image `v3.5.95-outbound-destinations-api-prod`, incluant l'API destinations et le bypass admin. L'Admin V2 pouvait maintenant consommer ces endpoints en PROD.

### Ce qui a été fait

1. Preflight complet (branche, repo clean, HEAD = remote)
2. Build PROD `v2.10.9-admin-access-fix-prod` (build-from-git, 0 erreurs TS)
3. GitOps PROD : manifest mis à jour, commit + push infra
4. Rollout PROD, pod Running
5. Validation :
   - Page `/metrics` PROD : KPI cards affichés
   - Page `/marketing/destinations` : liste vide (aucune destination configurée)
   - Page `/marketing/delivery-logs` : logs vides
   - Page `/marketing/integration-guide` : documentation affichée
   - RBAC : media_buyer voit uniquement la section Marketing
6. Rollback documenté

### Document généré

- **`keybuzz-infra/docs/PH-T8.6C-ADMIN-PROD-PROMOTION-02.md`**

---

<a id="fondation-multi-tenant"></a>
## 14. Fondation Multi-Tenant Admin V2

Ces phases ne font pas partie du tracking server-side à proprement parler, mais elles sont **prérequises** pour la phase T8.7A (metrics tenant-scoped) et essentielles à la compréhension du système.

### PH-ADMIN-TENANT-FOUNDATION-01 (DEV)

**Date** : 4 mars 2026 → reprise 22 avril 2026
**Agent** : Admin V2
**Image** : `v2.11.0-tenant-foundation-dev`
**Commit** : `0d581ab`

#### Prompt d'origine (résumé)

```
PH-ADMIN-TENANT-FOUNDATION-01 -- Refonte Fondation Multi-Tenant Admin

Objectif : Unifier les 4 patterns de tenant context incompatibles coexistant
dans Admin V2 en un système global cohérent.

Patterns identifiés :
- Pattern A (useTenantSelector) : ai-control, activation, policies, monitoring, debug
- Pattern B (URL params) : ai, connectors, incidents, billing
- Pattern C (marketing selector) : destinations, delivery-logs
- Pattern D (global) : metrics, ops, queues

Livrables :
- TenantProvider global
- useCurrentTenant() hook
- RequireTenant wrapper
- Tenant selector global dans Topbar
- Création de tenant via POST /api/admin/tenants
- Migration des 14 pages
- Suppression anciens patterns
```

#### Ce qui a été fait

1. **Fichiers créés** :
   - `src/contexts/TenantContext.tsx` — React Context + Provider global
   - `src/components/ui/RequireTenant.tsx` — wrapper d'accès tenant

2. **Fichiers modifiés** :
   - `src/features/users/types.ts` — interfaces `CreateTenantInput`, `CreateTenantResult`
   - `src/features/users/services/users.service.ts` — méthode `createTenant()` transactionnelle
   - `src/app/api/admin/tenants/route.ts` — GET role-aware + POST creation
   - `src/app/(admin)/layout.tsx` — wrapping `TenantProvider`
   - `src/components/layout/Topbar.tsx` — tenant selector dropdown
   - 14 pages migrées vers `useCurrentTenant()` + `RequireTenant`

3. **Fichiers supprimés** :
   - `src/hooks/useTenantSelector.ts` — remplacé par `useCurrentTenant()`
   - `src/app/api/admin/marketing/tenants/route.ts` — remplacé par GET `/api/admin/tenants` role-aware

#### Document généré

- **`keybuzz-infra/docs/PH-ADMIN-TENANT-FOUNDATION-01.md`**

### PH-ADMIN-TENANT-FOUNDATION-02-PROD-PROMOTION

**Date** : 22 avril 2026
**Agent** : Admin V2
**Image** : `v2.11.0-tenant-foundation-prod`
**Digest** : `sha256:b6c33e7754673c874b9a0eb10e3377fb30334dc8e83e3236c391b918bfd8a148`

#### Prompt d'origine (complet)

```
Prompt CE — PH-ADMIN-TENANT-FOUNDATION-02-PROD-PROMOTION

Rôle : Cursor Executor (CE)
Projet : KeyBuzz Admin V2
Phase : PH-ADMIN-TENANT-FOUNDATION-02-PROD-PROMOTION
Environnement : PROD
Type : promotion PROD fondation multi-tenant Admin
Priorité : CRITIQUE

🎯 OBJECTIF

Promouvoir en PROD la fondation multi-tenant Admin V2 validée en DEV, incluant :

TenantProvider global
selector global dans la topbar
useCurrentTenant()
RequireTenant
création de tenant via /api/admin/tenants
unification des pages tenant-scoped
migration de /metrics, /ai, /activation, /policies, etc.
suppression des anciens patterns incohérents

👉 Résultat attendu :

ADMIN MULTI-TENANT CONSISTENT — PROD READY — TENANT CREATION + GLOBAL SELECTOR LIVE

🔴 RÈGLES ABSOLUES
BUILD / SOURCE OF TRUTH
build-from-git obligatoire
repo clean obligatoire
commit + push AVANT build
aucun build depuis working dir dirty
image buildée = image déployée = version visible

GITOPS
GitOps strict obligatoire
manifests PROD uniquement
aucun kubectl set image
aucun patch live artisanal
```

#### Ce qui a été fait

1. Preflight : branche `main`, HEAD `0d581ab`, repo CLEAN
2. Vérification code complet (fondation, creation, 11 pages, nettoyage)
3. Build PROD `v2.11.0-tenant-foundation-prod` (build-from-git, 0 erreurs TS)
4. GitOps PROD : commit `42cd390`
5. Validation compilé : TenantProvider, kb-admin-tenant, RequireTenant, createTenant présents
6. RBAC vérifiée : 3 niveaux de rôles (ALL_TENANTS, LIST, CREATE)
7. Non-régression : 19/19 pages, 8/8 routes API
8. DEV inchangée

#### Document généré

- **`keybuzz-infra/docs/PH-ADMIN-TENANT-FOUNDATION-02-PROD-PROMOTION.md`**

---

## 15. Coordination inter-agents {#coordination}

### Schéma de coordination

```
┌─────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   Utilisateur    │     │  Agent SaaS API  │     │  Agent Admin V2  │
│   (Ludovic)      │     │  (Cursor CE)     │     │  (Cursor CE)     │
└────────┬────────┘     └────────┬─────────┘     └────────┬─────────┘
         │                       │                         │
         │  Prompt T8.1-2       │                         │
         │ ──────────────────►  │                         │
         │                      │ Crée /metrics/overview  │
         │                      │ Documente le payload    │
         │  Prompt T8.3.1      │                         │
         │ ────────────────────────────────────────────► │
         │  (transmet format   │                         │
         │   du payload API)   │                         │ Crée /metrics page
         │                     │                         │ Proxy → backend
         │                     │                         │
         │  T8.2B/C/D          │                         │
         │ ──────────────────► │                         │
         │                     │ Nouveau payload EUR     │
         │  Prompt T8.3.1C    │                         │
         │ ────────────────────────────────────────────► │
         │  (explique champs   │                         │ Fix mapping EUR
         │   spend_eur, fx)    │                         │
         │                     │                         │
         │  T8.6A              │                         │
         │ ──────────────────► │                         │
         │                     │ API destinations CRUD   │
         │  Prompt T8.6B      │                         │
         │ ────────────────────────────────────────────► │
         │  (endpoints dispo)  │                         │ UI Marketing
         │                     │                         │
         │  Bug proxy 403     │                         │
         │ ◄────────────────────────────────────────────│ Identifié
         │ ──────────────────► │                         │
         │                     │ Fix bypass admin        │
         │ ────────────────────────────────────────────► │ Fix proxy headers
         │                     │                         │
```

### Moments clés de coordination

| Moment | Problème | Agent source | Agent correcteur | Résultat |
|---|---|---|---|---|
| T8.3.1C | Payload EUR changé, UI affiche NaN | SaaS (T8.2C) | Admin V2 | Mapping spend_eur |
| T8.3.1B | API strict (null cac), UI crash | SaaS (T8.2) | Admin V2 | safeNum() helper |
| T8.3.1E | Port K8s PROD ≠ DEV | Infra | Admin V2 | Fix KEYBUZZ_API_INTERNAL_URL |
| T8.6B-FIX | Admin users pas dans user_tenants | Admin V2 (identifié) | SaaS + Admin V2 | Bypass admin + headers proxy |

---

## 16. Architecture technique finale {#architecture}

### Pipeline complet

```
┌──────────────────────────────────────────────────────────────────┐
│                        STRIPE WEBHOOKS                            │
│  checkout.session.completed → handleCheckoutCompleted()           │
│  customer.subscription.updated → handleSubscriptionChange()       │
└──────────────────────┬───────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│                   CONVERSION EVENTS EMITTER                       │
│  emitOutboundConversion(eventName, tenantId, subData, value)     │
│                                                                   │
│  ┌─ Check tenant_billing_exempt (skip test accounts)             │
│  ├─ Build payload: customer, subscription, attribution, value    │
│  ├─ Attribution from signup_attribution (UTMs, click IDs)        │
│  ├─ Idempotence via conversion_events table                      │
│  ├─ Get active destinations from DB (+ env var fallback)         │
│  └─ For each destination:                                        │
│     ├─ HMAC SHA256 signature                                     │
│     ├─ POST with retry (3x backoff: 0s, 5s, 15s)               │
│     └─ Log to outbound_conversion_delivery_logs                  │
└──────────────────────────────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│               DESTINATIONS (per tenant)                           │
│  webhook | meta_capi | tiktok_events | google_ads | linkedin_capi│
│  endpoint_url + secret + HMAC + active/inactive                  │
└──────────────────────────────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│                   EXTERNAL SYSTEMS                                │
│  Meta CAPI / TikTok Events / Google Enhanced / sGTM / Zapier    │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                    METRICS PIPELINE                                │
│  GET /metrics/overview?tenant_id=xxx                              │
│                                                                   │
│  ┌─ Customers: trial / paid / no_subscription (excl. test)       │
│  ├─ Revenue: MRR from active subscriptions only                  │
│  ├─ Spend: from ad_spend (Meta import), EUR normalized (ECB fx) │
│  ├─ CAC: blended + paid only                                    │
│  ├─ ROAS: revenue / spend                                        │
│  └─ Data quality: test_excluded, spend_source, fx info          │
└──────────────────────┬───────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│                    ADMIN V2 UI                                    │
│                                                                   │
│  ┌─ /metrics ─────────── KPI cards, spend/canal, trial/paid     │
│  ├─ /marketing/destinations ─── CRUD destinations webhook        │
│  ├─ /marketing/delivery-logs ── logs livraison paginés          │
│  ├─ /marketing/integration-guide ── doc media buyer             │
│  │                                                               │
│  ├─ TenantProvider global (kb-admin-tenant localStorage)        │
│  ├─ useCurrentTenant() → tenantId passé aux API calls           │
│  ├─ RequireTenant wrapper → blocage si pas de tenant            │
│  └─ Topbar tenant selector → dropdown avec plan badge           │
│                                                                   │
│  Proxy Next.js:                                                  │
│  /api/admin/metrics/overview → SaaS GET /metrics/overview        │
│  /api/admin/marketing/* → SaaS /outbound-conversions/*           │
│  Headers: x-user-email, x-tenant-id, x-admin-role               │
│                                                                   │
│  RBAC:                                                           │
│  super_admin/ops_admin → tout                                    │
│  account_manager → tenants assignés + création                   │
│  media_buyer → tenants assignés + lecture metrics + destinations │
│  agent → tenants assignés + lecture                              │
└──────────────────────────────────────────────────────────────────┘
```

---

## 17. Index complet des documents {#index-documents}

Tous les fichiers sont dans `keybuzz-infra/docs/` :

### Phases SaaS API (backend)

| Fichier | Phase | Date | Contenu |
|---|---|---|---|
| `PH-T8.1-2-DATA-FOUNDATION-AND-METRICS-01.md` | T8.1-2 | 20 avr | Data foundation + /metrics/overview |
| `PH-T8.2-REAL-SPEND-TRUTH-01.md` | T8.2 | 20 avr | Purge mock, mode strict |
| `PH-T8.2B-META-REAL-SPEND-01-REPORT.md` | T8.2B | 20 avr | Import Meta Graph API |
| `PH-T8.2C-CURRENCY-NORMALIZATION-01.md` | T8.2C | 20 avr | Normalisation EUR (ECB fx) |
| `PH-T8.2D-TRIAL-VS-PAID-METRICS-01.md` | T8.2D | 20 avr | Distinction trial/paid |
| `PH-T8.2E-PROD-PROMOTION-METRICS-01.md` | T8.2E | 20 avr | Promotion PROD metrics |
| `PH-T8.2Ebis-EXCLUDE-TEST-DATA-01.md` | T8.2Ebis | 20 avr | Exclusion comptes test |
| `PH-T8.2F-TEST-ACCOUNT-CONTROL-01.md` | T8.2F | 20 avr | Table tenant_billing_exempt |
| `PH-T8.4-OUTBOUND-CONVERSIONS-WEBHOOK-01-REPORT.md` | T8.4 | 21 avr | Outbound conversions (HMAC, retry) |
| `PH-T8.4.1-STRIPE-REAL-VALUE-01.md` | T8.4.1 | 21 avr | Valeur réelle Stripe |
| `PH-T8.4.1-STRIPE-REAL-VALUE-PROD-PROMOTION-01.md` | T8.4.1-PROD | 21 avr | Promo PROD Stripe value |
| `PH-T8.5-AGENCY-INTEGRATION-DOC-01.md` | T8.5 | 21 avr | Documentation media buyer |
| `PH-T8.5.1-WEBHOOK-SITE-PROD-TEST-01.md` | T8.5.1 | 21 avr | Test webhook.site PROD |
| `PH-T8.6A-OUTBOUND-DESTINATIONS-API-01.md` | T8.6A | 21 avr | API CRUD destinations |
| `PH-T8.6C-SAAS-PROD-PROMOTION-01.md` | T8.6C SaaS | 22 avr | Promo PROD API destinations |
| `PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-AUDIT.md` | T8.7A Audit | 22 avr | Audit tenant-native |
| `PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-01.md` | T8.7A | 22 avr | Fondation attribution tenant |

### Phases Admin V2 (frontend)

| Fichier | Phase | Date | Contenu |
|---|---|---|---|
| `PH-T8.3.1-METRICS-UI-BASIC-AUDIT.md` | T8.3.1 Audit | 20 avr | Audit pré-implémentation metrics |
| `PH-T8.3.1-METRICS-UI-BASIC-REPORT.md` | T8.3.1 | 20 avr | Page /metrics créée |
| `PH-T8.3.1B-METRICS-NO-DATA-UI-FIX-REPORT.md` | T8.3.1B | 20 avr | Fix crash UI no-data |
| `PH-T8.3.1C-METRICS-CURRENCY-MAPPING-FIX-REPORT.md` | T8.3.1C | 20 avr | Fix mapping devises EUR |
| `PH-T8.3.1-PROD-PROMOTION-02-REPORT.md` | T8.3.1-PROD | 20 avr | Première promo PROD metrics |
| `PH-T8.3.1D-METRICS-TRIAL-PAID-ALIGNMENT-REPORT.md` | T8.3.1D | 20 avr | Alignement trial/paid UI |
| `PH-T8.3.1D-PROD-PROMOTION-REPORT.md` | T8.3.1D-PROD | 20 avr | Promo PROD metrics final |
| `PH-T8.3.1E-ADMIN-INTERNAL-API-FIX-REPORT.md` | T8.3.1E | 20 avr | Fix proxy port K8s |
| `PH-T8.6B-MEDIA-BUYER-ADMIN-UI-01.md` | T8.6B | 21 avr | Rôle media_buyer + UI marketing |
| `PH-T8.6B-MARKETING-PROXY-FIX-02.md` | T8.6B-FIX | 21 avr | Fix proxy/RBAC marketing |
| `PH-T8.6C-ADMIN-PROD-PROMOTION-02.md` | T8.6C Admin | 22 avr | Promo PROD Admin marketing |

### Fondation multi-tenant

| Fichier | Phase | Date | Contenu |
|---|---|---|---|
| `PH-ADMIN-TENANT-FOUNDATION-01.md` | Tenant-01 | 4 mar/22 avr | Refonte multi-tenant Admin V2 |
| `PH-ADMIN-TENANT-FOUNDATION-02-PROD-PROMOTION.md` | Tenant-02 | 22 avr | Promo PROD fondation tenant |

### Document de synthèse SaaS

| Fichier | Contenu |
|---|---|
| `KNOWLEDGE-TRANSFER-SERVER-SIDE-TRACKING-COMPLETE.md` | Synthèse complète 28 phases (perspective SaaS) |

---

## 18. État final et prochaines étapes {#etat-final}

### État au 22 avril 2026

| Composant | DEV | PROD |
|---|---|---|
| API SaaS | `v3.5.97-marketing-tenant-foundation-dev` | `v3.5.95-outbound-destinations-api-prod` |
| Admin V2 | `v2.11.0-tenant-foundation-dev` | `v2.11.0-tenant-foundation-prod` |

### Ce qui est opérationnel en PROD

- **Metrics** : `/metrics` — CAC paid, ROAS, MRR, trial/paid, data quality, EUR normalized
- **Import Meta** : `POST /metrics/import/meta` — spend réel depuis Meta Graph API
- **Outbound conversions** : StartTrial + Purchase → webhook, HMAC, idempotence, retry
- **Valeur Stripe réelle** : montant exact du checkout/subscription
- **Destinations self-service** : CRUD, test, logs, multi-destination
- **Exclusion test** : `tenant_billing_exempt` explicite
- **RBAC** : owner/admin pour destinations, media_buyer pour lecture
- **Admin V2 UI** : `/metrics`, `/marketing/destinations`, `/marketing/delivery-logs`, `/marketing/integration-guide`
- **Multi-tenant Admin** : TenantProvider global, selector topbar, RequireTenant, création tenant

### En DEV uniquement (pas encore promu en PROD)

- **Metrics tenant-scoped** : `GET /metrics/overview?tenant_id=xxx`
- **Framework platform-native** : types + colonnes DB pour meta_capi, tiktok_events, google_ads, linkedin_capi

### Prochaines phases prévues

1. **PH-T8.7A-PROD** : promotion PROD metrics tenant-scoped + framework platform-native
2. **Connecteurs natifs Meta CAPI** : envoi direct à Meta sans webhook intermédiaire
3. **Connecteurs natifs TikTok Events API** : idem TikTok
4. **Connecteurs natifs Google Ads Enhanced Conversions** : idem Google
5. **Connecteurs natifs LinkedIn CAPI** : idem LinkedIn
6. **Ad spend par tenant** : ajouter `tenant_id` à `ad_spend` pour CAC par tenant
7. **Synchronisation Admin V2 metrics tenant** : passer `tenantId` via proxy vers /metrics/overview

---

## Annexe : Conventions et patterns récurrents

### Build-from-git (obligatoire pour TOUTE promotion)

```bash
# Script standard sur le bastion
bash /opt/keybuzz/keybuzz-infra/scripts/build-admin-from-git.sh [env] [tag] [branch]
# Exemple :
bash /opt/keybuzz/keybuzz-infra/scripts/build-admin-from-git.sh prod v2.11.0-tenant-foundation-prod main
```

Le script :
1. Clone propre depuis GitHub dans `/tmp/build-admin-*/repo/`
2. Vérifie que le working tree est CLEAN
3. Note le commit exact
4. Build Docker avec `NEXT_PUBLIC_API_URL` selon l'env
5. Push vers `ghcr.io/keybuzzio/keybuzz-admin`
6. Cleanup

### GitOps strict

```bash
cd /opt/keybuzz/keybuzz-infra
# Modifier UNIQUEMENT le manifest de l'env cible
sed -i 's/OLD_TAG/NEW_TAG/' k8s/keybuzz-admin-v2-prod/deployment.yaml
git add k8s/keybuzz-admin-v2-prod/deployment.yaml
git commit -m "GitOps: Admin V2 PROD -> NEW_TAG"
git push origin main
kubectl apply -f k8s/keybuzz-admin-v2-prod/deployment.yaml
kubectl rollout restart deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod
```

**JAMAIS** : `kubectl set image`, `docker build` depuis le bastion sans clone, modification live.

### Proxy Admin V2 → SaaS API

Pattern standard pour toutes les routes API dans Admin V2 :

```typescript
// src/app/api/admin/[resource]/route.ts
export async function GET(request: Request) {
  const session = await getServerSession(authOptions);
  if (!session?.user) return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });

  const apiUrl = process.env.KEYBUZZ_API_INTERNAL_URL;
  const response = await fetch(`${apiUrl}/[backend-path]`, {
    headers: {
      'x-user-email': session.user.email,
      'x-tenant-id': new URL(request.url).searchParams.get('tenantId') || '',
      'x-admin-role': session.user.role,
    },
  });
  const data = await response.json();
  return NextResponse.json(data);
}
```
