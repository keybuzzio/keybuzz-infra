# KeyBuzz — Knowledge Transfer : Server-Side Tracking Pipeline Complet

> **Document de transfert de connaissances**
> Destiné à un agent IA ayant déjà une connaissance complète de KeyBuzz.
> Objectif : historique exhaustif et horodaté de la feature de tracking server-side marketing,
> avec toutes les phases, les prompts d'origine, les documents générés, et les interactions
> entre l'agent SaaS API (Cursor Executor) et l'agent Admin V2 (Cursor Executor).
>
> Toutes les phases ont été exécutées sur la branche `ph147.4/source-of-truth` du repo `keybuzz-api`,
> sauf les phases Admin V2 qui utilisent la branche `main` du repo `keybuzz-admin-v2`.
>
> Dernière mise à jour : 22 avril 2026

---

## TABLE DES MATIÈRES

1. [Vue d'ensemble](#1-vue-densemble)
2. [Architecture des agents](#2-architecture-des-agents)
3. [Chronologie complète](#3-chronologie-complète)
4. [Phase T8.1-2 — Data Foundation + Metrics API](#phase-t81-2)
5. [Phase T8.2 — Real Spend Truth](#phase-t82)
6. [Phase T8.2B — Meta Real Spend](#phase-t82b)
7. [Phase T8.2C — Currency Normalization](#phase-t82c)
8. [Phase T8.2D — Trial vs Paid Metrics](#phase-t82d)
9. [Phase T8.2E — PROD Promotion Metrics](#phase-t82e)
10. [Phase T8.2Ebis — Exclude Test Data](#phase-t82ebis)
11. [Phase T8.2F — Test Account Control](#phase-t82f)
12. [Phase T8.3.1 — Metrics UI Basic (Admin V2)](#phase-t831)
13. [Phase T8.3.1B — Metrics No Data UI Fix](#phase-t831b)
14. [Phase T8.3.1C — Currency Mapping Fix](#phase-t831c)
15. [Phase T8.3.1D — Trial/Paid Alignment](#phase-t831d)
16. [Phase T8.3.1D-PROD — PROD Promotion Admin](#phase-t831d-prod)
17. [Phase T8.3.1E — Admin Internal API Fix](#phase-t831e)
18. [Phase T8.4 — Outbound Conversions Webhook](#phase-t84)
19. [Phase T8.4.1 — Stripe Real Value](#phase-t841)
20. [Phase T8.4.1-PROD — Stripe Real Value PROD](#phase-t841-prod)
21. [Phase T8.5 — Agency Integration Doc](#phase-t85)
22. [Phase T8.5.1 — Webhook Site PROD Test](#phase-t851)
23. [Phase T8.6A — Outbound Destinations API](#phase-t86a)
24. [Phase T8.6B — Media Buyer Admin UI (Admin V2)](#phase-t86b)
25. [Phase T8.6B-FIX — Marketing Proxy Fix (Admin V2)](#phase-t86b-fix)
26. [Phase T8.6C — SAAS PROD Promotion](#phase-t86c-saas)
27. [Phase T8.6C — Admin PROD Promotion (Admin V2)](#phase-t86c-admin)
28. [Phase T8.7A — Marketing Tenant Attribution Foundation](#phase-t87a)
29. [Fondation Multi-Tenant Admin (contexte)](#fondation-multi-tenant)
30. [État final et prochaines étapes](#etat-final)

---

## 1. Vue d'ensemble

Le tracking server-side marketing de KeyBuzz est un pipeline complet permettant :

- **Collecter** les événements de conversion réels (StartTrial, Purchase) depuis les webhooks Stripe
- **Enrichir** ces événements avec l'attribution marketing (UTMs, click IDs) captée au signup
- **Émettre** ces événements vers des destinations webhook configurables par tenant
- **Mesurer** les métriques business (CAC, ROAS, MRR, trial/paid) via une API dédiée
- **Visualiser** le tout dans une UI Admin V2 dédiée aux media buyers
- **Sécuriser** le pipeline avec exclusion des comptes test, HMAC, RBAC, et isolation tenant

Le pipeline a été construit progressivement en ~28 phases sur 3 jours (20-22 avril 2026), avec une coordination étroite entre deux agents Cursor :

- **Agent SaaS API** : modifie `keybuzz-api` (Fastify), gère le backend, les webhooks Stripe, l'emitter, les métriques
- **Agent Admin V2** : modifie `keybuzz-admin-v2` (Next.js Metronic), gère l'UI admin, le RBAC admin, le proxy

---

## 2. Architecture des agents

### Agent SaaS API (cette conversation)

- **Repo** : `keybuzz-api` (GitHub: keybuzzio/keybuzz-api)
- **Branche** : `ph147.4/source-of-truth`
- **Stack** : Node.js / Fastify / TypeScript
- **Déploiement** : K8s namespace `keybuzz-api-dev` et `keybuzz-api-prod`
- **Bastion** : `/opt/keybuzz/keybuzz-api/` sur `46.62.171.61`

### Agent Admin V2 (conversation séparée)

- **Repo** : `keybuzz-admin-v2` (GitHub: keybuzzio/keybuzz-admin-v2)
- **Branche** : `main`
- **Stack** : Next.js 14 / Metronic / TypeScript
- **Déploiement** : K8s namespace `keybuzz-admin-dev` et `keybuzz-admin`
- **Bastion** : `/opt/keybuzz/keybuzz-admin-v2/` sur `46.62.171.61`

### Interaction entre agents

Les deux agents ne communiquent pas directement. La coordination se fait par :

1. L'agent SaaS crée/modifie des endpoints API
2. L'utilisateur transmet le contexte à l'agent Admin V2 (docs générés, format payload, endpoints disponibles)
3. L'agent Admin V2 consomme ces endpoints via un proxy Next.js interne
4. Chaque agent documente son travail dans `keybuzz-infra/docs/`

---

## 3. Chronologie complète


| Date        | Phase           | Agent    | Env      | Résumé                                           |
| ----------- | --------------- | -------- | -------- | ------------------------------------------------ |
| 20 avr 2026 | PH-T8.1-2       | SaaS     | DEV      | Data foundation + endpoint `/metrics/overview`   |
| 20 avr 2026 | PH-T8.2         | SaaS     | DEV      | Purge mock data, source de vérité réelle         |
| 20 avr 2026 | PH-T8.2B        | SaaS     | DEV      | Intégration Meta Graph API real spend            |
| 20 avr 2026 | PH-T8.2C        | SaaS     | DEV      | Normalisation devises EUR (fx ECB)               |
| 20 avr 2026 | PH-T8.2D        | SaaS     | DEV      | Distinction trial vs paid dans metrics           |
| 20 avr 2026 | PH-T8.2E        | SaaS     | PROD     | Promotion PROD de T8.2B/C/D                      |
| 20 avr 2026 | PH-T8.2Ebis     | SaaS     | DEV+PROD | Exclusion comptes test des metrics               |
| 20 avr 2026 | PH-T8.2F        | SaaS     | DEV+PROD | Système explicite `tenant_billing_exempt`        |
| 20 avr 2026 | PH-T8.3.1       | Admin V2 | DEV      | Page `/metrics` dans Admin V2                    |
| 20 avr 2026 | PH-T8.3.1B      | Admin V2 | DEV      | Fix crash UI quand no data                       |
| 20 avr 2026 | PH-T8.3.1C      | Admin V2 | DEV      | Fix mapping devises / spend_eur                  |
| 20 avr 2026 | PH-T8.3.1D      | Admin V2 | DEV      | Alignement UI trial/paid + CAC/ROAS              |
| 20 avr 2026 | PH-T8.3.1D-PROD | Admin V2 | PROD     | Promotion PROD Admin metrics                     |
| 20 avr 2026 | PH-T8.3.1E      | Admin V2 | PROD     | Fix proxy interne port K8s 80                    |
| 21 avr 2026 | PH-T8.4         | SaaS     | DEV      | Outbound conversions webhook (HMAC, idempotence) |
| 21 avr 2026 | PH-T8.4.1       | SaaS     | DEV      | Valeur réelle Stripe (plus de PLAN_PRICES)       |
| 21 avr 2026 | PH-T8.4.1-PROD  | SaaS     | PROD     | Promotion PROD valeur Stripe                     |
| 21 avr 2026 | PH-T8.5         | SaaS     | —        | Documentation agence / media buyer               |
| 21 avr 2026 | PH-T8.5.1       | SaaS     | PROD     | Test webhook.site temporaire en PROD             |
| 21 avr 2026 | PH-T8.6A        | SaaS     | DEV      | API self-service destinations webhook            |
| 21 avr 2026 | PH-T8.6B        | Admin V2 | DEV      | Rôle media_buyer + UI Marketing                  |
| 21 avr 2026 | PH-T8.6B-FIX    | Admin V2 | DEV      | Fix proxy/RBAC marketing                         |
| 22 avr 2026 | PH-T8.6C        | SaaS     | PROD     | Promotion PROD API destinations                  |
| 22 avr 2026 | PH-T8.6C        | Admin V2 | PROD     | Promotion PROD Admin media buyer                 |
| 22 avr 2026 | PH-T8.7A        | SaaS     | DEV      | Fondation attribution tenant-native              |


---

## 4. PH-T8.1-2 — Data Foundation + Metrics API

**Date** : 20 avril 2026
**Agent** : SaaS API
**Environnement** : DEV
**Image** : première image metrics DEV

### Prompt d'origine (résumé)

```
Prompt CE — PH-T8.1-2-DATA-FOUNDATION-AND-METRICS-01

Objectif : Créer les métriques business clés (CAC blended, revenue, ROAS blended,
nouveaux clients). AUCUNE modification produit client. Lecture + SQL + endpoint uniquement.

Étapes :
- ÉTAPE 0 : Préflight — lister tables (signup_attribution, tenants, billing_subscriptions, billing_events)
- ÉTAPE 1 : Nouveaux clients — count(tenants.created_at) avec filtre date
- ÉTAPE 2 : Revenue — sum plans actifs
- ÉTAPE 3 : Spend — table ad_spend par canal
- ÉTAPE 4 : CAC — spend / new_customers
- ÉTAPE 5 : ROAS — revenue / spend
- ÉTAPE 6 : Endpoint GET /metrics/overview
- ÉTAPE 7 : Validation DEV
- ÉTAPE 8 : Build safe
- ÉTAPE 9 : Rapport
```

### Ce qui a été fait

1. Création de la table `ad_spend` (date, channel, spend, impressions, clicks)
2. Création de l'endpoint `GET /metrics/overview` dans `src/modules/metrics/routes.ts`
3. Calcul des métriques : new_customers, revenue (MRR), spend par canal, CAC blended, ROAS
4. Enregistrement dans `app.ts` sous le préfixe `/metrics`
5. Build + deploy DEV

### Pourquoi

Le SaaS n'avait aucune capacité de reporting marketing. Les données étaient éparpillées (Stripe, DB tenants, pas de spend). Il fallait centraliser les métriques business dans un endpoint unique consommable par l'Admin V2.

### Document généré

- `keybuzz-infra/docs/PH-T8.1-2-DATA-FOUNDATION-AND-METRICS-01.md`

---

## 5. PH-T8.2 — Real Spend Truth

**Date** : 20 avril 2026
**Agent** : SaaS API
**Environnement** : DEV

### Prompt d'origine (résumé)

```
Prompt CE — PH-T8.2-REAL-SPEND-TRUTH-01

Objectif : Corriger le système metrics pour qu'il ne retourne QUE des données réelles.
INTERDICTION ABSOLUE : données mock, données test, fallback fake, estimation inventée.

Étapes :
- ÉTAPE 1 : Audit ad_spend — contenu, origine, identifier lignes test
- ÉTAPE 2 : Suppression mock (DELETE FROM ad_spend WHERE channel = ... et lignes fake)
- ÉTAPE 3 : Adapter /metrics/overview pour retourner spend=0 si pas de données
- ÉTAPE 4 : Validation
- ÉTAPE 5 : Build + rapport
```

### Ce qui a été fait

1. Audit de `ad_spend` : toutes les données étaient mockées (seed initial)
2. Suppression de toutes les lignes mock
3. Adaptation de `/metrics/overview` pour retourner `spend.source: 'no_data'` quand vide
4. CAC et ROAS retournent `null` si pas de spend

### Pourquoi

L'endpoint retournait des données inventées (mock) qui auraient trompé les media buyers. La règle fondamentale est : **jamais de fake data en metrics business**.

### Document généré

- `keybuzz-infra/docs/PH-T8.2-REAL-SPEND-TRUTH-01.md`

---

## 6. PH-T8.2B — Meta Real Spend

**Date** : 20 avril 2026
**Agent** : SaaS API
**Environnement** : DEV

### Prompt d'origine (résumé)

```
Prompt CE — PH-T8.2B-META-REAL-SPEND-01 (SAFE)

Objectif : Remplacer définitivement les données test par une source réelle Meta Ads.

Règles : DEV ONLY, branche ph147.4/source-of-truth, build-from-git, repo clean,
INTERDICTION de mock, INTERDICTION d'estimation.

Étapes :
- ÉTAPE 1 : Vérifier la config Meta (META_AD_ACCOUNT_ID, META_ACCESS_TOKEN)
- ÉTAPE 2 : Créer endpoint POST /metrics/import/meta (fetch Meta Graph API v21.0)
- ÉTAPE 3 : Import réel spend Meta → table ad_spend
- ÉTAPE 4 : Validation
- ÉTAPE 5 : Build + rapport
```

### Ce qui a été fait

1. Ajout de `fetchMetaInsights()` — appel Meta Graph API v21.0 `act_{id}/insights`
2. Création endpoint `POST /metrics/import/meta` avec paramètres `since`/`until`
3. Upsert `ad_spend` avec `ON CONFLICT (date, channel) DO UPDATE`
4. Variables d'env `META_AD_ACCOUNT_ID` + `META_ACCESS_TOKEN` injectées via ConfigMap K8s

### Pourquoi

Les métriques de spend doivent provenir directement de Meta Graph API, pas de saisie manuelle ou de mock. Cet endpoint permet l'import automatique du spend réel Meta.

### Document généré

- `keybuzz-infra/docs/PH-T8.2B-META-REAL-SPEND-01-REPORT.md`

---

## 7. PH-T8.2C — Currency Normalization

**Date** : 20 avril 2026
**Agent** : SaaS API
**Environnement** : DEV

### Prompt d'origine (résumé)

```
Prompt CE — PH-T8.2C-CURRENCY-NORMALIZATION-01

Objectif : Garantir que toutes les métriques business (CAC, ROAS, spend) sont calculées
dans UNE devise unique : EUR.

Interdit : ne pas modifier la table ad_spend existante, ne pas écraser la devise originale,
ne pas hardcoder un taux fixe, ne pas convertir côté frontend.
```

### Ce qui a été fait

1. Ajout de `getGbpToEurRate()` — fetch taux ECB via API Frankfurter (cache 6h)
2. Mapping `CHANNEL_CURRENCIES` : meta=GBP, google/tiktok/linkedin=EUR
3. Calcul `spend_eur` par canal (conversion GBP→EUR pour Meta)
4. CAC et ROAS calculés sur `totalSpendEur`
5. Ajout bloc `fx` dans la réponse (taux, source, date)

### Pourquoi

Meta facture en GBP (compte UK). Sans normalisation, le CAC et ROAS mélangent GBP et EUR. La conversion est faite côté backend avec un taux ECB réel, pas côté frontend.

### Document généré

- `keybuzz-infra/docs/PH-T8.2C-CURRENCY-NORMALIZATION-01.md`

---

## 8. PH-T8.2D — Trial vs Paid Metrics

**Date** : 20 avril 2026
**Agent** : SaaS API
**Environnement** : DEV

### Prompt d'origine (résumé)

```
Prompt CE — PH-T8.2D-TRIAL-VS-PAID-METRICS-01

Objectif : Corriger la couche metrics pour distinguer clairement les clients en essai (trial)
des clients réellement payants (paid). Le pilotage acquisition ne doit pas se baser
sur une métrique optimiste.
```

### Ce qui a été fait

1. Ajout breakdown `customers.trial` / `customers.paid` / `customers.no_subscription` dans `/metrics/overview`
2. Ajout `conversion.trial_to_paid_rate` (snapshot all-time)
3. Revenue calculé uniquement sur `status = 'active'` (pas trialing)
4. CAC paid = spend / paid_customers
5. Ajout `customers_by_plan` breakdown

### Pourquoi

Avant ce fix, un client en trial était compté comme "client payant" dans le CAC, ce qui donnait un CAC artificiellement bas. La distinction est critique pour le pilotage marketing.

### Document généré

- `keybuzz-infra/docs/PH-T8.2D-TRIAL-VS-PAID-METRICS-01.md`

---

## 9. PH-T8.2E — PROD Promotion Metrics

**Date** : 20 avril 2026
**Agent** : SaaS API
**Environnement** : PROD

### Prompt d'origine (résumé)

```
Prompt CE — PH-T8.2E-PROD-PROMOTION-METRICS-01

Objectif : Promouvoir en PROD la chaîne metrics complète validée en DEV (T8.2B + T8.2C + T8.2D).
```

### Ce qui a été fait

1. Build PROD depuis même commit que DEV
2. Mise à jour `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml`
3. Déploiement GitOps `kubectl apply`
4. Validation endpoint PROD `/metrics/overview`

### Pourquoi

Les metrics étaient prêtes en DEV. L'Admin V2 en PROD devait pouvoir consommer l'endpoint réel.

### Document généré

- `keybuzz-infra/docs/PH-T8.2E-PROD-PROMOTION-METRICS-01.md`

---

## 10. PH-T8.2Ebis — Exclude Test Data

**Date** : 20 avril 2026
**Agent** : SaaS API
**Environnement** : DEV + PROD

### Prompt d'origine (résumé)

```
Prompt CE — PH-T8.2Ebis-EXCLUDE-TEST-DATA-01

Objectif : Exclure tous les comptes de test des métriques business (CAC, ROAS, conversion,
new_customers). Sans supprimer les données, mais en les filtrant proprement.
```

### Ce qui a été fait

1. Création heuristiques initiales pour identifier les comptes test (email, nom, prefix)
2. Ajout `data_quality.test_data_excluded` et `test_accounts_count` dans la réponse
3. Filtrage SQL `LEFT JOIN tenant_billing_exempt ... WHERE tbe.exempt IS NOT TRUE`

### Document généré

- `keybuzz-infra/docs/PH-T8.2Ebis-EXCLUDE-TEST-DATA-01.md`

---

## 11. PH-T8.2F — Test Account Control

**Date** : 20 avril 2026
**Agent** : SaaS API
**Environnement** : DEV + PROD

### Prompt d'origine (résumé)

```
Prompt CE — PH-T8.2F-TEST-ACCOUNT-CONTROL-01

Objectif : Remplacer le système basé sur heuristiques par un système EXPLICITE
de gestion des comptes test. Table dédiée, flag explicite, pas de devinette.
```

### Ce qui a été fait

1. Création de la table `tenant_billing_exempt` (tenant_id, exempt, reason)
2. Migration des heuristiques vers des flags explicites
3. Toutes les requêtes SQL metrics filtrent via cette table
4. Les comptes ecomlg-001, test-*, romrauis-* marqués explicitement

### Pourquoi

Les heuristiques (email domain, tenant name prefix) étaient fragiles et non maintenables. Un flag explicite dans une table dédiée est la seule source de vérité fiable pour l'exclusion test.

### Document généré

- `keybuzz-infra/docs/PH-T8.2F-TEST-ACCOUNT-CONTROL-01.md`

---

## 12. PH-T8.3.1 — Metrics UI Basic (Admin V2)

**Date** : 20 avril 2026
**Agent** : Admin V2
**Environnement** : DEV

### Contexte inter-agents

L'agent SaaS a créé l'endpoint `GET /metrics/overview` (phases T8.1-2 à T8.2F). L'utilisateur a ensuite transmis le format du payload à l'agent Admin V2 pour créer l'UI.

### Ce qui a été fait (par l'agent Admin V2)

1. Création page `/metrics` dans Admin V2
2. Proxy Next.js `/api/admin/metrics/overview` → backend API
3. Affichage : KPI cards (new_customers, MRR, CAC, ROAS), spend par canal, conversion rate
4. Date picker pour filtrer par période
5. Déploiement DEV image `v2.10.3-ph-t8-3-1-metrics-dev`

### Documents générés

- `keybuzz-infra/docs/PH-T8.3.1-METRICS-UI-BASIC-AUDIT.md`
- `keybuzz-infra/docs/PH-T8.3.1-METRICS-UI-BASIC-REPORT.md`

---

## 13. PH-T8.3.1B — Metrics No Data UI Fix

**Date** : 20 avril 2026
**Agent** : Admin V2
**Environnement** : DEV

### Ce qui a été fait

Fix du crash UI quand `cac` ou `roas` sont `null` (pas de spend data). Affichage "N/A" au lieu de crash.

### Document généré

- `keybuzz-infra/docs/PH-T8.3.1B-METRICS-NO-DATA-UI-FIX-REPORT.md`

---

## 14. PH-T8.3.1C — Currency Mapping Fix

**Date** : 20 avril 2026
**Agent** : Admin V2
**Environnement** : DEV

### Ce qui a été fait

Fix du mapping devises côté UI : utilisation de `spend_eur` et `total_eur` au lieu de `spend` brut. L'UI affichait le montant GBP comme EUR.

### Document généré

- `keybuzz-infra/docs/PH-T8.3.1C-METRICS-CURRENCY-MAPPING-FIX-REPORT.md`

---

## 15. PH-T8.3.1D — Trial/Paid Alignment

**Date** : 20 avril 2026
**Agent** : Admin V2
**Environnement** : DEV

### Ce qui a été fait

Alignement de l'UI sur le nouveau format trial/paid de l'API. Affichage séparé trial vs paid, CAC détail (blended vs paid), data quality badges.

### Document généré

- `keybuzz-infra/docs/PH-T8.3.1D-METRICS-TRIAL-PAID-ALIGNMENT-REPORT.md`

---

## 16. PH-T8.3.1D-PROD — PROD Promotion Admin Metrics

**Date** : 20 avril 2026
**Agent** : Admin V2
**Environnement** : PROD
**Image PROD** : `v2.10.6-ph-t8-3-1d-metrics-trial-paid-prod`

### Ce qui a été fait

Promotion PROD de l'Admin V2 avec toutes les corrections metrics (B, C, D).

### Document généré

- `keybuzz-infra/docs/PH-T8.3.1D-PROD-PROMOTION-REPORT.md`

---

## 17. PH-T8.3.1E — Admin Internal API Fix

**Date** : 20 avril 2026
**Agent** : Admin V2
**Environnement** : PROD

### Ce qui a été fait

Fix du proxy interne Admin V2 → API backend en PROD. Le service K8s PROD écoute sur le port 80 (pas 3001 comme en DEV). Le proxy envoyait les requêtes sur le mauvais port.

### Document généré

- `keybuzz-infra/docs/PH-T8.3.1E-ADMIN-INTERNAL-API-FIX-REPORT.md`

---

## 18. PH-T8.4 — Outbound Conversions Webhook

**Date** : 21 avril 2026
**Agent** : SaaS API
**Environnement** : DEV
**Image** : `v3.5.93-outbound-conversions-dev`

### Prompt d'origine (résumé)

```
Prompt CE — PH-T8.4-OUTBOUND-CONVERSIONS-WEBHOOK-01 (SAFE VERSION)

Objectif : Créer une brique serveur fiable pour exposer les conversions business réelles
(StartTrial, Purchase) vers des systèmes externes (webhook uniquement dans cette phase).

→ Permettre à une agence / media buyer d'exploiter les conversions backend
→ Sans dépendre du frontend
→ Sans fake data
→ Sans heuristique

Étapes :
- ÉTAPE 1 : Schéma conversion events (table conversion_events, event_id idempotent)
- ÉTAPE 2 : Module emitter (emitOutboundConversion) avec :
  - Payload structuré (event_name, customer, subscription, attribution, value, data_quality)
  - HMAC SHA256 signature
  - Retry avec exponential backoff (3 tentatives)
  - Exclusion comptes test (tenant_billing_exempt)
  - Attribution enrichie depuis signup_attribution
- ÉTAPE 3 : Intégration Stripe webhooks (checkout.session.completed → StartTrial,
  subscription.updated trialing→active → Purchase)
- ÉTAPE 4 : Validation DEV
- ÉTAPE 5 : Build + rapport
```

### Ce qui a été fait

1. Création `src/modules/outbound-conversions/emitter.ts` :
  - `emitOutboundConversion(eventName, tenantId, subscriptionData, stripeValue)`
  - Payload structuré avec `customer.tenant_id`, `subscription.*`, `attribution.*`, `value.*`, `data_quality.*`
  - HMAC SHA256 signature via `X-KeyBuzz-Signature`
  - Headers : `X-KeyBuzz-Event`, `X-KeyBuzz-Event-Id`
  - Idempotence via table `conversion_events` (event_id = `conv_{tenantId}_{eventName}_{subId}`)
  - 3 retries avec backoff (0s, 5s, 15s)
  - Exclusion test via `tenant_billing_exempt`
  - Attribution enrichie : UTMs, click IDs (gclid, fbclid, fbc, fbp, ttclid), email hash SHA256
2. Intégration dans `src/modules/billing/routes.ts` :
  - `handleCheckoutCompleted()` → `emitOutboundConversion('StartTrial', tenantId, ...)`
  - `handleSubscriptionChange()` → `emitOutboundConversion('Purchase', tenantId, ...)` quand `trialing → active`
3. Table `conversion_events` (id, event_id UNIQUE, tenant_id, event_name, payload JSONB, status, attempts)
4. Configuration via env vars : `OUTBOUND_CONVERSIONS_WEBHOOK_URL`, `OUTBOUND_CONVERSIONS_WEBHOOK_SECRET`

### Pourquoi

C'est la brique fondamentale du tracking server-side. Avant cette phase, aucun événement de conversion n'était émis vers l'extérieur. Les media buyers ne pouvaient pas optimiser leurs campagnes sur des données réelles.

### Document généré

- `keybuzz-infra/docs/PH-T8.4-OUTBOUND-CONVERSIONS-WEBHOOK-01-REPORT.md`

---

## 19. PH-T8.4.1 — Stripe Real Value

**Date** : 21 avril 2026
**Agent** : SaaS API
**Environnement** : DEV
**Image** : `v3.5.94-outbound-conversions-real-value-dev`

### Prompt d'origine (résumé)

```
Prompt CE — PH-T8.4.1-STRIPE-REAL-VALUE-01

Objectif : Remplacer la valeur approximative basée sur le plan par la valeur réelle
issue de Stripe dans les événements outbound conversions (StartTrial, Purchase).

Interdit : ne pas utiliser prix plan fixe comme fallback, ne pas inventer une valeur.
```

### Ce qui a été fait

1. Suppression de la map `PLAN_PRICES` (estimation par plan)
2. **StartTrial** : utilise `session.amount_total` (montant réel du checkout Stripe)
3. **Purchase** : utilise `subscription.items.data[].price.unit_amount * quantity` (montant réel de la subscription)
4. Devise lue depuis Stripe (`session.currency` / `item.price.currency`)

### Pourquoi

La valeur estimée par plan (PRO=297€, etc.) ne reflète pas la réalité : promos, coupons, période partielle, addons. La valeur Stripe est la seule source de vérité.

### Document généré

- `keybuzz-infra/docs/PH-T8.4.1-STRIPE-REAL-VALUE-01.md`

---

## 20. PH-T8.4.1-PROD — Stripe Real Value PROD

**Date** : 21 avril 2026
**Agent** : SaaS API
**Environnement** : PROD
**Image** : `v3.5.94-outbound-conversions-real-value-prod`

### Prompt d'origine (résumé)

```
Prompt CE — PH-T8.4.1-STRIPE-REAL-VALUE-PROD-PROMOTION-01

Objectif : Promouvoir en PROD le correctif valeur réelle Stripe.
Cette phase traite UNIQUEMENT la valeur réelle Stripe dans StartTrial et Purchase.
```

### Ce qui a été fait

1. Build PROD depuis même commit
2. Mise à jour manifest PROD
3. Déploiement GitOps
4. Validation PROD : health + outbound conversions fonctionnelles

### Document généré

- `keybuzz-infra/docs/PH-T8.4.1-STRIPE-REAL-VALUE-PROD-PROMOTION-01.md`

---

## 21. PH-T8.5 — Agency Integration Doc

**Date** : 21 avril 2026
**Agent** : SaaS API
**Environnement** : Documentation pure (aucun code)

### Prompt d'origine (résumé)

```
Prompt CE — PH-T8.5-AGENCY-INTEGRATION-DOC-01

Objectif : Créer une documentation claire, exploitable et professionnelle permettant à
une agence marketing / media buyer de se connecter aux conversions server-side KeyBuzz.

AUCUNE modification code. AUCUN build. AUCUN deploy.
```

### Ce qui a été fait

1. Rédaction d'un guide complet pour media buyers
2. Explication du payload, des headers, de la signature HMAC
3. Exemples de vérification signature en Python et Node.js
4. Mapping vers Meta CAPI, TikTok Events API, Google Ads Enhanced Conversions
5. **Réécriture conviviale** : à la demande de l'utilisateur, le document a été réécrit dans un ton informel (tutoiement) pour ses media buyers

### Pourquoi

Les media buyers ont besoin d'un guide opérationnel pour configurer la réception des webhooks dans leurs outils (sGTM, Zapier, scripts custom).

### Document généré

- `keybuzz-infra/docs/PH-T8.5-AGENCY-INTEGRATION-DOC-01.md`

---

## 22. PH-T8.5.1 — Webhook Site PROD Test

**Date** : 21 avril 2026
**Agent** : SaaS API
**Environnement** : PROD (temporaire)

### Prompt d'origine (résumé)

```
Prompt CE — PH-T8.5.1-WEBHOOK-SITE-PROD-TEST-01

Objectif : Activer TEMPORAIREMENT une destination externe webhook.site en PROD
pour valider de bout en bout les webhooks outbound conversions.
Sans modifier le code. Sans build. Sans toucher au client.
```

### Ce qui a été fait

1. Configuration env var `OUTBOUND_CONVERSIONS_WEBHOOK_URL` → `https://webhook.site/xxx`
2. Rollout restart du pod PROD
3. Vérification réception des events sur webhook.site
4. **Rollback** : env vars vidées après le test

### Pourquoi

Avant de donner la doc aux media buyers, il fallait prouver que le pipeline fonctionne de bout en bout en PROD avec un vrai signup Stripe.

### Résultat additionnel

L'utilisateur a constaté 2 comptes de test dans les metrics (son test + un compte "romrauis"). Il a demandé l'exclusion de ces comptes, ce qui a été fait immédiatement via `tenant_billing_exempt`.

### Document généré

- `keybuzz-infra/docs/PH-T8.5.1-WEBHOOK-SITE-PROD-TEST-01.md`

---

## 23. PH-T8.6A — Outbound Destinations API

**Date** : 21 avril 2026
**Agent** : SaaS API
**Environnement** : DEV
**Image** : `v3.5.95-outbound-destinations-api-dev`

### Prompt d'origine (résumé)

```
Prompt CE — PH-T8.6A-OUTBOUND-DESTINATIONS-API-01

Objectif : Créer la couche API permettant à des utilisateurs autorisés de gérer
eux-mêmes les destinations webhook des conversions server-side.

Préparer un usage autonome par account_manager / media_buyer pour connecter
Meta, TikTok, Google, LinkedIn, Zapier, Make, n8n, sGTM, custom webhook.

L'intégration reste générique (webhook) dans cette phase.

Étapes :
- Tables : outbound_conversion_destinations, outbound_conversion_delivery_logs
- RBAC : owner + admin = full access, agent = denied
- Routes REST :
  - GET /outbound-conversions/destinations (list, secrets masqués)
  - POST /outbound-conversions/destinations (create, HTTPS obligatoire)
  - PATCH /outbound-conversions/destinations/:id (update)
  - POST /outbound-conversions/destinations/:id/test (ConnectionTest event, HMAC, log)
  - GET /outbound-conversions/destinations/:id/logs (delivery logs paginés)
- Adapter emitter pour multi-destination (DB first, env var fallback)
- Idempotence et logging par destination
```

### Ce qui a été fait

1. **Tables créées** :
  - `outbound_conversion_destinations` : id, tenant_id, name, destination_type, endpoint_url, secret, is_active, created_by, updated_by, last_test_at, last_test_status
  - `outbound_conversion_delivery_logs` : id, destination_id, event_name, event_id, attempt, status, http_status, error_message
2. **Routes API** (`src/modules/outbound-conversions/routes.ts`) :
  - `checkAccess()` : RBAC via `user_tenants` (owner/admin uniquement)
  - `maskSecret()` : masquage des secrets dans les réponses (`te**********et`)
  - `isValidHttpsUrl()` : validation HTTPS obligatoire
  - 5 endpoints REST complets
3. **Emitter refactoré** (`src/modules/outbound-conversions/emitter.ts`) :
  - `getActiveDestinations(pool, tenantId)` : DB first, env var fallback
  - `sendToDestination()` : encapsule HMAC + fetch + retry + log
  - Boucle sur toutes les destinations actives
  - Status `sent` si au moins une destination OK, `failed` sinon
4. **ConnectionTest** : événement dédié pour tester sans polluer les vrais events

### Pourquoi

Avant cette phase, la configuration des destinations nécessitait une intervention infra (modifier les env vars K8s). L'API self-service permet aux media buyers de configurer eux-mêmes leurs destinations via l'UI Admin V2.

### Document généré

- `keybuzz-infra/docs/PH-T8.6A-OUTBOUND-DESTINATIONS-API-01.md`

---

## 24. PH-T8.6B — Media Buyer Admin UI (Admin V2)

**Date** : 21 avril 2026
**Agent** : Admin V2
**Environnement** : DEV
**Image** : `v2.10.8-ph-t8-6b-media-buyer-dev`

### Contexte inter-agents

L'agent SaaS a créé l'API destinations (T8.6A). L'utilisateur a ensuite demandé à l'agent Admin V2 de créer l'UI correspondante avec un rôle `media_buyer` dédié.

### Ce qui a été fait (par l'agent Admin V2)

1. **Rôle `media_buyer`** ajouté au RBAC Admin V2 :
  - Type `AdminRole` étendu
  - Configuration `rbac.ts` : permissions lecture metrics + gestion destinations
  - Hiérarchie : `super_admin > admin > media_buyer > viewer`
2. **Section Marketing** dans la sidebar :
  - `/metrics` : page métriques (déjà existante, rendue accessible)
  - `/marketing/destinations` : liste des destinations webhook
  - `/marketing/delivery-logs` : logs de livraison
  - `/marketing/documentation` : guide intégré
3. **Proxy Next.js** : routes `/api/admin/outbound-conversions/`* → backend API

### Documents générés

- `keybuzz-infra/docs/PH-T8.6B-MEDIA-BUYER-ADMIN-UI-01.md`

---

## 25. PH-T8.6B-FIX — Marketing Proxy Fix (Admin V2)

**Date** : 21 avril 2026
**Agent** : Admin V2
**Environnement** : DEV

### Ce qui a été fait

Correction de 3 problèmes dans le proxy marketing :

1. **Chemins API** : les routes proxy ne correspondaient pas aux routes backend
2. **Headers auth** : `x-user-email` et `x-tenant-id` n'étaient pas propagés
3. **RBAC bypass** : les utilisateurs admin ne sont pas dans `user_tenants` du SaaS → ajout d'un bypass admin dans le backend (commit `536d3340`)

### Note sur l'interaction agents

Ce fix a nécessité un aller-retour entre les deux agents :

- L'agent Admin V2 a identifié le problème côté proxy
- L'agent SaaS a ajouté le bypass admin dans les routes destinations (commit `536d3340 fix(outbound): add admin bypass for internal proxy calls`)
- L'agent Admin V2 a corrigé les chemins et headers du proxy

### Document généré

- `keybuzz-infra/docs/PH-T8.6B-MARKETING-PROXY-FIX-02.md`

---

## 26. PH-T8.6C — SAAS PROD Promotion

**Date** : 22 avril 2026
**Agent** : SaaS API
**Environnement** : PROD
**Image** : `v3.5.95-outbound-destinations-api-prod`

### Prompt d'origine (résumé)

```
Prompt CE — PH-T8.6C-SAAS-PROD-PROMOTION-01

Objectif : Promouvoir en PROD outbound conversions server-side (StartTrial, Purchase),
valeur réelle Stripe, module destinations webhook self-service, multi-destination.
```

### Ce qui a été fait

1. Build PROD depuis `ph147.4/source-of-truth` HEAD
2. Mise à jour manifest PROD
3. Déploiement GitOps
4. Validation PROD complète : health, destinations API, ConnectionTest, delivery logs, billing, Stripe

### Document généré

- `keybuzz-infra/docs/PH-T8.6C-SAAS-PROD-PROMOTION-01.md`

---

## 27. PH-T8.6C — Admin PROD Promotion (Admin V2)

**Date** : 22 avril 2026
**Agent** : Admin V2
**Environnement** : PROD
**Image** : `v2.10.9-admin-access-fix-prod`

### Ce qui a été fait (par l'agent Admin V2)

1. Build PROD Admin V2
2. Vérification compatibilité backend PROD (endpoints destinations disponibles)
3. Déploiement GitOps
4. Validation : page metrics, destinations, delivery logs, RBAC media_buyer

### Document généré

- `keybuzz-infra/docs/PH-T8.6C-ADMIN-PROD-PROMOTION-02.md`

---

## 28. PH-T8.7A — Marketing Tenant Attribution Foundation

**Date** : 22 avril 2026
**Agent** : SaaS API
**Environnement** : DEV
**Image** : `v3.5.97-marketing-tenant-foundation-dev`
**Commit** : `db14cb03`
**Digest** : `sha256:231bee30181eabe9fd84545160aa11a70c0cf3c3ec59c7857b3ed36d1c0a52a9`

### Prompt d'origine (résumé)

```
Prompt CE — PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-01

Objectif : Rendre le pipeline marketing server-side tenant-native de bout en bout.
Préparer : multi-tenant metrics, multi-tenant destinations, futurs connecteurs natifs
(Meta / TikTok / Google / LinkedIn).

Cette phase NE doit PAS implémenter les connecteurs plateforme natifs.
Elle doit verrouiller la source de vérité tenant marketing.

10 étapes : Préflight → Audit → Source de vérité → Aligner events → Aligner metrics →
Tenant safety destinations → Framework platform-native → Validation → Non-régression →
Build → Rapport
```

### Ce qui a été fait

#### Audit complet (ÉTAPE 1)


| Composant               | `tenant_id` présent ? | Source de vérité                             | Correctif ?  |
| ----------------------- | --------------------- | -------------------------------------------- | ------------ |
| `signup_attribution`    | OUI                   | Canonical tenant ID                          | NON          |
| StartTrial event        | OUI                   | `session.metadata.tenant_id`                 | NON          |
| Purchase event          | OUI                   | `subscription.metadata.tenant_id`            | NON          |
| Emitter payload         | OUI                   | Paramètre explicite                          | NON          |
| Destinations            | OUI                   | `outbound_conversion_destinations.tenant_id` | NON          |
| `**/metrics/overview**` | **NON**               | **N/A — global uniquement**                  | **OUI**      |
| `ad_spend`              | NON                   | Table globale                                | Phase future |


#### Source de vérité (ÉTAPE 2)

**La source de vérité tenant marketing officielle est le `tenant_id` canonical**, utilisé dans : signup_attribution, Stripe metadata, emitter, destinations, conversion_events, metrics.

#### Alignement events (ÉTAPE 3)

Aucun correctif nécessaire — les events étaient déjà tenant-native.

#### Alignement /metrics/overview (ÉTAPE 4)

**Fichier modifié** : `src/modules/metrics/routes.ts`

- Ajout query param optionnel `tenant_id`
- Filtre SQL conditionnel : `AND ($N::text IS NULL OR t.id = $N)`
- Champs ajoutés à la réponse : `scope` ("global" | "tenant"), `tenant_id`
- Backward compatible : sans `tenant_id` = comportement global identique

#### Tenant safety (ÉTAPE 5)

Vérifié sans correctif nécessaire :

- `getActiveDestinations()` filtre par `tenant_id`
- Idempotence key inclut `tenant_id`
- RBAC vérifie appartenance user/tenant
- Test T7 : "Insufficient permissions" pour un tenant étranger

#### Framework platform-native (ÉTAPE 6)

**Fichier modifié** : `src/modules/outbound-conversions/routes.ts`

- Ajout `DESTINATION_TYPES` : `webhook`, `meta_capi`, `tiktok_events`, `google_ads`, `linkedin_capi`
- Colonnes DB ajoutées : `platform_account_id`, `platform_pixel_id`, `platform_token_ref`, `mapping_strategy`
- `destination_type` dynamique à la création (plus hardcodé 'webhook')

### Pourquoi

La fondation multi-tenant est déjà live côté Admin V2 (tenant selector global, tenant creation, pages tenant-scoped). Il fallait aligner le backend marketing sur cette réalité pour que chaque metric, event, et destination soit rattachable sans ambiguïté à un tenant spécifique.

### Documents générés

- `keybuzz-infra/docs/PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-AUDIT.md`
- `keybuzz-infra/docs/PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-01.md`

---

## 29. Fondation Multi-Tenant Admin (contexte)

Ces phases ont été réalisées par l'agent Admin V2 et sont référencées comme prérequis de T8.7A :

### PH-ADMIN-TENANT-FOUNDATION-01

**Date** : 4 mars 2026 (antérieur au tracking)
**Agent** : Admin V2
**Environnement** : DEV
**Image** : `v2.11.0-tenant-foundation-dev`

Unification des 4 patterns incompatibles de tenant context dans Admin V2 en un système global cohérent, avec tenant selector et création de tenant.

**Document** : `keybuzz-infra/docs/PH-ADMIN-TENANT-FOUNDATION-01.md`

### PH-ADMIN-TENANT-FOUNDATION-02-PROD-PROMOTION

**Date** : 22 avril 2026
**Agent** : Admin V2
**Environnement** : PROD
**Image** : `v2.11.0-tenant-foundation-prod`

Promotion PROD de la fondation multi-tenant Admin V2.

**Document** : `keybuzz-infra/docs/PH-ADMIN-TENANT-FOUNDATION-02-PROD-PROMOTION.md`

---

## 30. État final et prochaines étapes

### État au 22 avril 2026


| Composant | DEV                                       | PROD                                     |
| --------- | ----------------------------------------- | ---------------------------------------- |
| API SaaS  | `v3.5.97-marketing-tenant-foundation-dev` | `v3.5.95-outbound-destinations-api-prod` |
| Admin V2  | `v2.11.0-tenant-foundation-dev`           | `v2.10.9-admin-access-fix-prod`          |


### Ce qui est opérationnel

- Endpoint `GET /metrics/overview` : CAC, ROAS, MRR, trial/paid, test exclusion, **tenant-scoped (DEV)**
- Import Meta spend : `POST /metrics/import/meta`
- Outbound conversions : StartTrial + Purchase, HMAC, idempotence, retry
- Valeur réelle Stripe (plus d'estimation par plan)
- Destinations self-service : CRUD, test, logs
- Multi-destination : DB first, env var fallback
- Exclusion test : `tenant_billing_exempt` explicite
- RBAC : owner/admin pour destinations, media_buyer pour lecture
- Admin V2 UI : `/metrics`, `/marketing/destinations`, `/marketing/delivery-logs`
- Framework platform-native : types + colonnes préparés (webhook, meta_capi, tiktok_events, google_ads, linkedin_capi)

### Prochaines phases prévues (PH-T8.7B+)

1. **Promotion PROD T8.7A** : tenant-scoped metrics + framework platform-native
2. **Connecteurs natifs Meta CAPI** : adapter pour envoyer directement à Meta sans webhook intermédiaire
3. **Connecteurs natifs TikTok Events API** : idem pour TikTok
4. **Connecteurs natifs Google Ads Enhanced Conversions** : idem pour Google
5. **Connecteurs natifs LinkedIn CAPI** : idem pour LinkedIn
6. **Ad spend par tenant** : ajouter `tenant_id` à `ad_spend` pour un CAC par tenant

### Fichiers source clés sur le bastion


| Fichier                                                                | Rôle                                        |
| ---------------------------------------------------------------------- | ------------------------------------------- |
| `/opt/keybuzz/keybuzz-api/src/modules/metrics/routes.ts`               | Endpoint /metrics/overview + import Meta    |
| `/opt/keybuzz/keybuzz-api/src/modules/outbound-conversions/emitter.ts` | Émission conversions multi-destination      |
| `/opt/keybuzz/keybuzz-api/src/modules/outbound-conversions/routes.ts`  | API destinations self-service               |
| `/opt/keybuzz/keybuzz-api/src/modules/billing/routes.ts`               | Webhooks Stripe → déclenchement conversions |


### Tables DB marketing


| Table                               | Rôle                                              |
| ----------------------------------- | ------------------------------------------------- |
| `signup_attribution`                | Attribution marketing au signup (UTMs, click IDs) |
| `conversion_events`                 | Suivi idempotent des événements émis              |
| `outbound_conversion_destinations`  | Destinations webhook par tenant                   |
| `outbound_conversion_delivery_logs` | Logs de livraison par destination                 |
| `tenant_billing_exempt`             | Exclusion explicite comptes test                  |
| `ad_spend`                          | Spend publicitaire par canal et par jour          |
| `billing_subscriptions`             | État subscription Stripe par tenant               |
| `billing_customers`                 | Lien Stripe customer ↔ tenant                     |


### Index de tous les documents générés


| Fichier                                                                        | Phase            | Date   |
| ------------------------------------------------------------------------------ | ---------------- | ------ |
| `keybuzz-infra/docs/PH-T8.1-2-DATA-FOUNDATION-AND-METRICS-01.md`               | T8.1-2           | 20 avr |
| `keybuzz-infra/docs/PH-T8.2-REAL-SPEND-TRUTH-01.md`                            | T8.2             | 20 avr |
| `keybuzz-infra/docs/PH-T8.2B-META-REAL-SPEND-01-REPORT.md`                     | T8.2B            | 20 avr |
| `keybuzz-infra/docs/PH-T8.2C-CURRENCY-NORMALIZATION-01.md`                     | T8.2C            | 20 avr |
| `keybuzz-infra/docs/PH-T8.2D-TRIAL-VS-PAID-METRICS-01.md`                      | T8.2D            | 20 avr |
| `keybuzz-infra/docs/PH-T8.2E-PROD-PROMOTION-METRICS-01.md`                     | T8.2E            | 20 avr |
| `keybuzz-infra/docs/PH-T8.2Ebis-EXCLUDE-TEST-DATA-01.md`                       | T8.2Ebis         | 20 avr |
| `keybuzz-infra/docs/PH-T8.2F-TEST-ACCOUNT-CONTROL-01.md`                       | T8.2F            | 20 avr |
| `keybuzz-infra/docs/PH-T8.3.1-METRICS-UI-BASIC-AUDIT.md`                       | T8.3.1           | 20 avr |
| `keybuzz-infra/docs/PH-T8.3.1-METRICS-UI-BASIC-REPORT.md`                      | T8.3.1           | 20 avr |
| `keybuzz-infra/docs/PH-T8.3.1-PROD-PROMOTION-02-REPORT.md`                     | T8.3.1 PROD      | 20 avr |
| `keybuzz-infra/docs/PH-T8.3.1B-METRICS-NO-DATA-UI-FIX-REPORT.md`               | T8.3.1B          | 20 avr |
| `keybuzz-infra/docs/PH-T8.3.1C-METRICS-CURRENCY-MAPPING-FIX-REPORT.md`         | T8.3.1C          | 20 avr |
| `keybuzz-infra/docs/PH-T8.3.1D-METRICS-TRIAL-PAID-ALIGNMENT-REPORT.md`         | T8.3.1D          | 20 avr |
| `keybuzz-infra/docs/PH-T8.3.1D-PROD-PROMOTION-REPORT.md`                       | T8.3.1D PROD     | 20 avr |
| `keybuzz-infra/docs/PH-T8.3.1E-ADMIN-INTERNAL-API-FIX-REPORT.md`               | T8.3.1E          | 20 avr |
| `keybuzz-infra/docs/PH-T8.4-OUTBOUND-CONVERSIONS-WEBHOOK-01-REPORT.md`         | T8.4             | 21 avr |
| `keybuzz-infra/docs/PH-T8.4.1-STRIPE-REAL-VALUE-01.md`                         | T8.4.1           | 21 avr |
| `keybuzz-infra/docs/PH-T8.4.1-STRIPE-REAL-VALUE-PROD-PROMOTION-01.md`          | T8.4.1 PROD      | 21 avr |
| `keybuzz-infra/docs/PH-T8.5-AGENCY-INTEGRATION-DOC-01.md`                      | T8.5             | 21 avr |
| `keybuzz-infra/docs/PH-T8.5.1-WEBHOOK-SITE-PROD-TEST-01.md`                    | T8.5.1           | 21 avr |
| `keybuzz-infra/docs/PH-T8.6A-OUTBOUND-DESTINATIONS-API-01.md`                  | T8.6A            | 21 avr |
| `keybuzz-infra/docs/PH-T8.6B-MEDIA-BUYER-ADMIN-UI-01.md`                       | T8.6B            | 21 avr |
| `keybuzz-infra/docs/PH-T8.6B-MARKETING-PROXY-FIX-02.md`                        | T8.6B-FIX        | 21 avr |
| `keybuzz-infra/docs/PH-T8.6C-SAAS-PROD-PROMOTION-01.md`                        | T8.6C SaaS       | 22 avr |
| `keybuzz-infra/docs/PH-T8.6C-ADMIN-PROD-PROMOTION-02.md`                       | T8.6C Admin      | 22 avr |
| `keybuzz-infra/docs/PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-AUDIT.md` | T8.7A Audit      | 22 avr |
| `keybuzz-infra/docs/PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-01.md`    | T8.7A            | 22 avr |
| `keybuzz-infra/docs/PH-ADMIN-TENANT-FOUNDATION-01.md`                          | Fondation tenant | 4 mar  |
| `keybuzz-infra/docs/PH-ADMIN-TENANT-FOUNDATION-02-PROD-PROMOTION.md`           | Fondation PROD   | 22 avr |


