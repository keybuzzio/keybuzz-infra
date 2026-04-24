# KeyBuzz — Knowledge Transfer Unifié : Server-Side Tracking Pipeline Complet

> **Document de transfert de connaissances unifié**
> Fusionné à partir des perspectives Agent SaaS API et Agent Admin V2.
> Destiné à un agent IA ayant déjà une connaissance complète de KeyBuzz.
>
> Objectif : historique exhaustif et horodaté de la feature de tracking server-side marketing,
> avec les prompts d'origine **complets**, les documents générés, et les interactions
> entre les deux agents Cursor Executor.
>
> Branche SaaS : `ph147.4/source-of-truth` (repo `keybuzz-api`)
> Branche Admin V2 : `main` (repo `keybuzz-admin-v2`)
>
> Dernière mise à jour : 22 avril 2026 (prompts Admin V2 complétés le 4 mars 2026)

---

## 1. Vue d'ensemble

Le tracking server-side marketing de KeyBuzz est un pipeline complet permettant :

- **Collecter** les événements de conversion réels (StartTrial, Purchase) depuis les webhooks Stripe
- **Enrichir** ces événements avec l'attribution marketing (UTMs, click IDs) captée au signup
- **Émettre** ces événements vers des destinations webhook configurables par tenant
- **Mesurer** les métriques business (CAC, ROAS, MRR, trial/paid) via une API dédiée
- **Visualiser** le tout dans une UI Admin V2 dédiée aux media buyers
- **Sécuriser** le pipeline avec exclusion des comptes test, HMAC, RBAC, et isolation tenant

Le pipeline a été construit progressivement en ~30 phases sur 3 jours (20-22 avril 2026), avec une coordination étroite entre deux agents Cursor indépendants.

---

## 2. Architecture des agents


| Agent              | Repo               | Stack                              | Branche                   | Bastion                          |
| ------------------ | ------------------ | ---------------------------------- | ------------------------- | -------------------------------- |
| **Agent SaaS API** | `keybuzz-api`      | Node.js / Fastify / TypeScript     | `ph147.4/source-of-truth` | `/opt/keybuzz/keybuzz-api/`      |
| **Agent Admin V2** | `keybuzz-admin-v2` | Next.js 14 / Metronic / TypeScript | `main`                    | `/opt/keybuzz/keybuzz-admin-v2/` |


**Coordination** : les deux agents ne communiquent jamais directement. L'utilisateur (Ludovic) transmet le contexte entre eux : docs générés, format payload, endpoints disponibles. Les rapports dans `keybuzz-infra/docs/` servent de contrat d'interface.

**Infrastructure commune** :

- Bastion : `46.62.171.61` (SSH)
- K8s : `keybuzz-api-dev/prod`, `keybuzz-admin-v2-dev/prod`
- Registry : `ghcr.io/keybuzzio/`
- Build : toujours `build-from-git` (clone propre, repo clean, commit pushé avant build)
- Déploiement : GitOps strict (manifests K8s dans `keybuzz-infra/k8s/`)

---

## 3. Chronologie complète


| #   | Date         | Moment | Phase           | Agent      | Env      | Résumé                                    | Document                                                 |
| --- | ------------ | ------ | --------------- | ---------- | -------- | ----------------------------------------- | -------------------------------------------------------- |
| 1   | 20 avr       | matin  | PH-T8.1-2       | SaaS       | DEV      | Data foundation + `/metrics/overview`     | `PH-T8.1-2-DATA-FOUNDATION-AND-METRICS-01.md`            |
| 2   | 20 avr       | matin  | PH-T8.2         | SaaS       | DEV      | Purge mock data, source de vérité réelle  | `PH-T8.2-REAL-SPEND-TRUTH-01.md`                         |
| 3   | 20 avr       | matin  | PH-T8.2B        | SaaS       | DEV      | Intégration Meta Graph API real spend     | `PH-T8.2B-META-REAL-SPEND-01-REPORT.md`                  |
| 4   | 20 avr       | midi   | PH-T8.2C        | SaaS       | DEV      | Normalisation devises EUR (fx ECB)        | `PH-T8.2C-CURRENCY-NORMALIZATION-01.md`                  |
| 5   | 20 avr       | midi   | PH-T8.2D        | SaaS       | DEV      | Distinction trial vs paid dans metrics    | `PH-T8.2D-TRIAL-VS-PAID-METRICS-01.md`                   |
| 6   | 20 avr       | AM     | PH-T8.2E        | SaaS       | PROD     | Promotion PROD de T8.2B/C/D               | `PH-T8.2E-PROD-PROMOTION-METRICS-01.md`                  |
| 7   | 20 avr       | AM     | PH-T8.2Ebis     | SaaS       | DEV+PROD | Exclusion comptes test des metrics        | `PH-T8.2Ebis-EXCLUDE-TEST-DATA-01.md`                    |
| 8   | 20 avr       | AM     | PH-T8.2F        | SaaS       | DEV+PROD | Système explicite `tenant_billing_exempt` | `PH-T8.2F-TEST-ACCOUNT-CONTROL-01.md`                    |
| 9   | 20 avr       | AM     | PH-T8.3.1       | Admin V2   | DEV      | Page `/metrics` dans Admin V2             | `PH-T8.3.1-METRICS-UI-BASIC-REPORT.md`                   |
| 10  | 20 avr       | AM     | PH-T8.3.1B      | Admin V2   | DEV      | Fix crash UI quand no data                | `PH-T8.3.1B-METRICS-NO-DATA-UI-FIX-REPORT.md`            |
| 11  | 20 avr       | AM     | PH-T8.3.1C      | Admin V2   | DEV      | Fix mapping devises / spend_eur           | `PH-T8.3.1C-METRICS-CURRENCY-MAPPING-FIX-REPORT.md`      |
| 12  | 20 avr       | PM     | PH-T8.3.1-PROD  | Admin V2   | PROD     | Première promotion PROD metrics           | `PH-T8.3.1-PROD-PROMOTION-02-REPORT.md`                  |
| 13  | 20 avr       | PM     | PH-T8.3.1D      | Admin V2   | DEV      | Alignement UI trial/paid + CAC/ROAS       | `PH-T8.3.1D-METRICS-TRIAL-PAID-ALIGNMENT-REPORT.md`      |
| 14  | 20 avr       | soir   | PH-T8.3.1D-PROD | Admin V2   | PROD     | Promotion PROD Admin metrics final        | `PH-T8.3.1D-PROD-PROMOTION-REPORT.md`                    |
| 15  | 20 avr       | soir   | PH-T8.3.1E      | Admin V2   | PROD     | Fix proxy interne port K8s 80             | `PH-T8.3.1E-ADMIN-INTERNAL-API-FIX-REPORT.md`            |
| 16  | 21 avr       | matin  | PH-T8.4         | SaaS       | DEV      | Outbound conversions webhook (HMAC)       | `PH-T8.4-OUTBOUND-CONVERSIONS-WEBHOOK-01-REPORT.md`      |
| 17  | 21 avr       | matin  | PH-T8.4.1       | SaaS       | DEV      | Valeur réelle Stripe                      | `PH-T8.4.1-STRIPE-REAL-VALUE-01.md`                      |
| 18  | 21 avr       | midi   | PH-T8.4.1-PROD  | SaaS       | PROD     | Promotion PROD valeur Stripe              | `PH-T8.4.1-STRIPE-REAL-VALUE-PROD-PROMOTION-01.md`       |
| 19  | 21 avr       | midi   | PH-T8.5         | SaaS       | —        | Documentation agence / media buyer        | `PH-T8.5-AGENCY-INTEGRATION-DOC-01.md`                   |
| 20  | 21 avr       | AM     | PH-T8.5.1       | SaaS       | PROD     | Test webhook.site temporaire PROD         | `PH-T8.5.1-WEBHOOK-SITE-PROD-TEST-01.md`                 |
| 21  | 21 avr       | AM     | PH-T8.6A        | SaaS       | DEV      | API self-service destinations webhook     | `PH-T8.6A-OUTBOUND-DESTINATIONS-API-01.md`               |
| 22  | 21 avr       | PM     | PH-T8.6B        | Admin V2   | DEV      | Rôle media_buyer + UI Marketing           | `PH-T8.6B-MEDIA-BUYER-ADMIN-UI-01.md`                    |
| 23  | 21 avr       | soir   | PH-T8.6B-FIX    | Admin+SaaS | DEV      | Fix proxy/RBAC marketing                  | `PH-T8.6B-MARKETING-PROXY-FIX-02.md`                     |
| 24  | 22 avr       | matin  | PH-T8.6C SaaS   | SaaS       | PROD     | Promotion PROD API destinations           | `PH-T8.6C-SAAS-PROD-PROMOTION-01.md`                     |
| 25  | 22 avr       | matin  | PH-T8.6C Admin  | Admin V2   | PROD     | Promotion PROD Admin media buyer          | `PH-T8.6C-ADMIN-PROD-PROMOTION-02.md`                    |
| 26  | 4 mar→22 avr | —      | TENANT-01       | Admin V2   | DEV      | Fondation multi-tenant Admin V2           | `PH-ADMIN-TENANT-FOUNDATION-01.md`                       |
| 27  | 22 avr       | AM     | TENANT-02       | Admin V2   | PROD     | Promotion PROD fondation tenant           | `PH-ADMIN-TENANT-FOUNDATION-02-PROD-PROMOTION.md`        |
| 28  | 22 avr       | midi   | PH-T8.7A        | SaaS       | DEV      | Fondation attribution tenant-native       | `PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-01.md` |


---

## PHASE 1 — PH-T8.1-2 — Data Foundation + Metrics API

**Date** : 20 avril 2026 — matin
**Agent** : SaaS API
**Environnement** : DEV

### Prompt d'origine complet

```
Prompt CE — PH-T8.1-2-DATA-FOUNDATION-AND-METRICS-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz SaaS
Phase : PH-T8.1-2-DATA-FOUNDATION-AND-METRICS-01
Environnement : DEV uniquement
Type : data layer + metrics
Priorité : STRATÉGIQUE

---

# 🎯 OBJECTIF

Créer les métriques business clés :

- CAC blended
- revenue
- ROAS blended
- nouveaux clients

AUCUNE modification produit client
AUCUN impact SaaS
lecture + SQL + endpoint uniquement

---

# 🔴 RÈGLES ABSOLUES

- DEV ONLY
- AUCUN build client
- AUCUN impact UI existante
- AUCUNE modification tracking
- rollback simple
- rapport obligatoire

---

# 🧱 ÉTAPE 0 — PRÉFLIGHT

Lister tables :

- signup_attribution
- tenants
- billing_subscriptions
- billing_events

Créer mapping :

| Table | Utilisation |
|---|---|

---

# 🧱 ÉTAPE 1 — NOUVEAUX CLIENTS

Définir :

new_customers = count(tenants.created_at)

Filtrable par date.

# 🧱 ÉTAPE 2 — REVENUE

Utiliser :

billing_subscriptions
ou valeur estimée (PRO = 297 etc)

# 🧱 ÉTAPE 3 — SPEND

Créer table simple DEV :

ad_spend (
  date,
  channel,
  spend
)

Insérer données test (Meta, Google, TikTok).

# 🧱 ÉTAPE 4 — CAC BLENDED

CAC = SUM(spend) / COUNT(new_customers)

# 🧱 ÉTAPE 5 — ROAS BLENDED

ROAS = revenue / SUM(spend)

# 🧱 ÉTAPE 6 — API

Créer endpoint :

GET /metrics/overview

Retour :

{
  "cac": ...,
  "roas": ...,
  "revenue": ...,
  "new_customers": ...
}

# 🧱 ÉTAPE 7 — VALIDATION

cohérence chiffres
aucun impact SaaS
requêtes rapides

# 🧱 ÉTAPE 8 — RAPPORT

Créer :

PH-T8.1-2-DATA-FOUNDATION-AND-METRICS-01.md

🎯 VERDICT

BUSINESS METRICS OPERATIONAL

STOP
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

## PHASE 2 — PH-T8.2 — Real Spend Truth

**Date** : 20 avril 2026 — matin
**Agent** : SaaS API
**Environnement** : DEV

### Prompt d'origine complet

```
Prompt CE — PH-T8.2-REAL-SPEND-TRUTH-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz SaaS
Phase : PH-T8.2-REAL-SPEND-TRUTH-01
Environnement : DEV uniquement
Type : correction source de vérité metrics
Priorité : CRITIQUE

---

# 🎯 OBJECTIF

Corriger le système metrics pour qu'il ne retourne QUE des données réelles.

INTERDICTION ABSOLUE :

- données mock
- données test
- fallback fake
- estimation inventée

---

# 🔴 RÈGLES ABSOLUES

- DEV ONLY
- build-from-git obligatoire
- repo clean
- rollback prêt
- AUCUN impact client
- AUCUN impact tracking

---

# 🚫 INTERDIT

- ne pas garder ad_spend mock
- ne pas remplir par défaut
- ne pas estimer
- ne pas inventer spend

---

# 🧱 ÉTAPE 1 — AUDIT ad_spend

Vérifier :

- contenu table ad_spend
- origine des données
- identifier lignes test

---

# 🧱 ÉTAPE 2 — SUPPRESSION MOCK

Supprimer :

DELETE FROM ad_spend;

OU marquer clairement :

WHERE source = 'test'

# 🧱 ÉTAPE 3 — MODE STRICT

Modifier logique metrics :

SI PAS DE DATA RÉELLE :

spend.total = 0
spend.by_channel = []
cac = null
roas = null

# 🧱 ÉTAPE 4 — ADAPTER API

GET /metrics/overview doit :

être honnête
ne jamais simuler

# 🧱 ÉTAPE 5 — VALIDATION

Cas 1 : pas de spend réel

champ    attendu
spend    0
cac      null
roas     null

Cas 2 : spend réel partiel

champ           attendu
spend           réel
autres canaux   absents

# 🧱 ÉTAPE 6 — NON-RÉGRESSION

tracking OK
signup OK
Stripe OK
API OK

# 🧱 ÉTAPE 7 — BUILD DEV

Créer :

v3.5.83-metrics-real-dev

# 🧱 ÉTAPE 8 — RAPPORT

Créer :

PH-T8.2-REAL-SPEND-TRUTH-01.md

🎯 VERDICT

METRICS DATA SOURCE CLEAN — NO FAKE DATA

STOP
```

### Ce qui a été fait

1. Audit de `ad_spend` : toutes les données étaient mockées (seed initial)
2. Suppression de toutes les lignes mock
3. Adaptation de `/metrics/overview` pour retourner `spend.source: 'no_data'` quand vide
4. CAC et ROAS retournent `null` si pas de spend

### Pourquoi

L'endpoint retournait des données inventées (mock) qui auraient trompé les media buyers. Règle fondamentale : **jamais de fake data en metrics business**.

### Document généré

- `keybuzz-infra/docs/PH-T8.2-REAL-SPEND-TRUTH-01.md`

---

## PHASE 3 — PH-T8.2B — Meta Real Spend

**Date** : 20 avril 2026 — matin
**Agent** : SaaS API
**Environnement** : DEV

### Prompt d'origine complet

```
Prompt CE — PH-T8.2B-META-REAL-SPEND-01 (SAFE)

Rôle : Cursor Executor (CE)
Projet : KeyBuzz SaaS / API
Phase : PH-T8.2B-META-REAL-SPEND-01
Environnement : DEV ONLY
Type : intégration source de vérité spend Meta réel

---

# 🎯 OBJECTIF

Remplacer définitivement les données test par une source réelle Meta Ads.

---

# 🔴 RÈGLES ABSOLUES

## ENVIRONNEMENT
- DEV ONLY
- AUCUN impact PROD
- STOP avant toute promotion

## BRANCHES (OBLIGATOIRES)
- API = `ph147.4/source-of-truth`
- AUCUNE autre branche autorisée
- AUCUN `ph152.*`
- AUCUN commit hors branche validée

## BUILD
- build-from-git obligatoire
- repo clean obligatoire (`git status = clean`)
- AUCUN docker build depuis working dir bastion
- AUCUN fichier non commit dans l'image

## GITOPS
- commit + push AVANT build
- manifests DEV uniquement
- AUCUN `kubectl set image`

## DATA
- INTERDICTION ABSOLUE de mock
- INTERDICTION de fallback inventé
- INTERDICTION de simulation

---

# 🚫 INTERDIT

- ne pas modifier Admin V2
- ne pas modifier tracking existant
- ne pas toucher Stripe
- ne pas inventer spend
- ne pas brancher autres canaux (Google/TikTok/LinkedIn)

---

# 📚 DOCUMENTS À LIRE

- PH-T8.1-2-DATA-FOUNDATION-AND-METRICS-01.md
- PH-T8.2-REAL-SPEND-TRUTH-01.md
- PH-T7.2.4-GA4-MP-CONFIG-PROD-FINAL-01.md

---

# 🧱 ÉTAPE 0 — PRÉFLIGHT

Afficher :

git branch --show-current
git log --oneline -5
git status

Confirmer :

branche correcte
repo clean

# 🧱 ÉTAPE 1 — AUDIT META

Identifier :

Meta Access Token
Ad Account ID
API disponible
permissions OK

SI MANQUANT :
👉 STOP + rapport

# 🧱 ÉTAPE 2 — STRATÉGIE

Décider :

import simple
pas de sur-ingénierie
table ad_spend = source unique

# 🧱 ÉTAPE 3 — IMPORT META

Implémenter :

fetch Meta Ads Insights
agrégation par jour
channel = 'meta'
upsert sécurisé

Champs :

date
spend
impressions
clicks

# 🧱 ÉTAPE 4 — CLEAN DATA

Supprimer définitivement :

DELETE FROM ad_spend;

ou filtrer uniquement données réelles

# 🧱 ÉTAPE 5 — API METRICS

Adapter /metrics/overview :

CAS A (data existante) :

spend réel
cac calculé
roas calculé

CAS B (pas de data) :

spend = 0
cac = null
roas = null

# 🧱 ÉTAPE 6 — VALIDATION DEV

Tester :

import réel
DB remplie
API correcte
aucun fallback fake

# 🧱 ÉTAPE 7 — PREUVE

Fournir :

lignes SQL réelles
payload API
cohérence CAC / ROAS

# 🧱 ÉTAPE 8 — BUILD DEV

Tag :

v3.5.84-meta-real-spend-dev

Obligatoire :

build-from-git
commit présent

# 🧱 ÉTAPE 9 — ROLLBACK

Documenter :

image AVANT
image APRES
commande rollback

# 🧱 ÉTAPE 10 — RAPPORT

Créer :

PH-T8.2B-META-REAL-SPEND-01-REPORT.md

🎯 VERDICT

META REAL SPEND OPERATIONAL — NO FAKE DATA — SAFE BUILD — DEV ONLY

STOP
```

### Ce qui a été fait

1. Ajout de `fetchMetaInsights()` — appel Meta Graph API v21.0 `act_{id}/insights`
2. Création endpoint `POST /metrics/import/meta` avec paramètres `since`/`until`
3. Upsert `ad_spend` avec `ON CONFLICT (date, channel) DO UPDATE`
4. Variables d'env `META_AD_ACCOUNT_ID` + `META_ACCESS_TOKEN` injectées via ConfigMap K8s

### Pourquoi

Les métriques de spend doivent provenir directement de Meta Graph API, pas de saisie manuelle ou de mock.

### Document généré

- `keybuzz-infra/docs/PH-T8.2B-META-REAL-SPEND-01-REPORT.md`

---

## PHASE 4 — PH-T8.2C — Currency Normalization

**Date** : 20 avril 2026 — midi
**Agent** : SaaS API
**Environnement** : DEV

### Prompt d'origine complet

```
Prompt CE — PH-T8.2C-CURRENCY-NORMALIZATION-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz SaaS / API
Phase : PH-T8.2C-CURRENCY-NORMALIZATION-01
Environnement : DEV uniquement
Type : normalisation devise metrics
Priorité : CRITIQUE

---

# 🎯 OBJECTIF

Garantir que toutes les métriques business (CAC, ROAS, spend)
sont calculées dans UNE devise unique : EUR.

---

# 🔴 RÈGLES ABSOLUES

- DEV ONLY
- AUCUN impact PROD
- build-from-git obligatoire
- repo clean obligatoire
- AUCUNE modification tracking
- AUCUNE modification Admin V2
- AUCUNE suppression de données
- rollback obligatoire

---

# 🚫 INTERDIT

- ne pas modifier la table ad_spend existante
- ne pas écraser la devise originale
- ne pas hardcoder un taux fixe
- ne pas convertir côté frontend
- ne pas casser /metrics/overview

---

# 📚 DOCUMENTS À LIRE

- PH-T8.2B-META-REAL-SPEND-01-REPORT.md
- PH-T8.1-2-DATA-FOUNDATION-AND-METRICS-01.md

---

# 🧱 ÉTAPE 1 — AUDIT DEVISES

Identifier :

- devise revenue (EUR)
- devise spend (GBP)
- autres canaux futurs

Créer tableau :

| source | devise |
|--------|--------|
| revenue | EUR |
| meta spend | GBP |

---

# 🧱 ÉTAPE 2 — STRATÉGIE

Décider :

- devise de référence = EUR
- conversion au moment du calcul metrics
- conservation des données brutes

---

# 🧱 ÉTAPE 3 — SOURCE TAUX DE CHANGE

Implémenter :

- source fiable :
  - ECB (Banque Centrale Européenne)
  - ou API FX (ex: exchangerate.host)

Règles :

- taux journalier
- fallback sécurisé
- aucune valeur inventée

---

# 🧱 ÉTAPE 4 — CONVERSION

GBP → EUR

avant calcul :

CAC = spend_eur / new_customers
ROAS = revenue_eur / spend_eur

# 🧱 ÉTAPE 5 — API METRICS

Modifier /metrics/overview :

Ajouter :

"currency": "EUR",
"fx": {
  "base": "GBP",
  "rate": 1.17,
  "source": "ECB",
  "date": "2026-04-20"
}

# 🧱 ÉTAPE 6 — VALIDATION

CAS A :

spend GBP → converti EUR
CAC cohérent
ROAS cohérent

CAS B :

pas de spend → comportement inchangé

# 🧱 ÉTAPE 7 — NON-RÉGRESSION

tracking OK
signup OK
Stripe OK
API OK

# 🧱 ÉTAPE 8 — BUILD DEV

Créer :

v3.5.85-currency-normalized-dev

# 🧱 ÉTAPE 9 — ROLLBACK

Documenter :

image AVANT
image APRES

# 🧱 ÉTAPE 10 — RAPPORT

Créer :

PH-T8.2C-CURRENCY-NORMALIZATION-01.md

🎯 VERDICT

CURRENCY NORMALIZED — METRICS COHERENT — SAFE BUILD

STOP
```

### Ce qui a été fait

1. Ajout de `getGbpToEurRate()` — fetch taux ECB via API Frankfurter (cache 6h)
2. Mapping `CHANNEL_CURRENCIES` : meta=GBP, google/tiktok/linkedin=EUR
3. Calcul `spend_eur` par canal (conversion GBP→EUR pour Meta)
4. CAC et ROAS calculés sur `totalSpendEur`
5. Ajout bloc `fx` dans la réponse (taux, source, date)

### Pourquoi

Meta facture en GBP (compte UK). Sans normalisation, le CAC et ROAS mélangent GBP et EUR. La conversion est faite côté backend avec un taux ECB réel.

### Document généré

- `keybuzz-infra/docs/PH-T8.2C-CURRENCY-NORMALIZATION-01.md`

---

## PHASE 5 — PH-T8.2D — Trial vs Paid Metrics

**Date** : 20 avril 2026 — midi
**Agent** : SaaS API
**Environnement** : DEV

### Prompt d'origine complet

```
Prompt CE — PH-T8.2D-TRIAL-VS-PAID-METRICS-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz SaaS / API
Phase : PH-T8.2D-TRIAL-VS-PAID-METRICS-01
Environnement : DEV uniquement
Type : correction métriques business — séparation trial vs paid
Priorité : CRITIQUE

---

## OBJECTIF

Corriger la couche metrics pour distinguer clairement :

- les clients en essai (trial)
- les clients réellement payants (paid)

afin que le pilotage acquisition ne se base plus sur une métrique optimiste.

Cette phase doit permettre à `/metrics/overview` de retourner des données métier honnêtes
sans casser l'existant.

---

## RÈGLES ABSOLUES

- DEV ONLY
- build-from-git obligatoire
- repo clean obligatoire
- branche obligatoire : `ph147.4/source-of-truth`
- AUCUNE autre branche
- AUCUN impact Admin V2
- AUCUNE modification tracking
- AUCUNE modification Stripe webhook existant sauf si strictement nécessaire pour lecture métier
- AUCUN mock
- AUCUNE donnée fake
- rollback obligatoire
- AUCUN `kubectl set image`
- GitOps strict

---

## INTERDIT

- ne pas modifier la logique d'inscription trial
- ne pas toucher au pricing
- ne pas changer les plans
- ne pas supprimer les métriques existantes sans remplacement explicite
- ne pas inventer une notion de "paid" non supportée par les données réelles

---

## DOCUMENTS À LIRE

- `PH-T8.1-2-DATA-FOUNDATION-AND-METRICS-01.md`
- `PH-T8.2B-META-REAL-SPEND-01-REPORT.md`
- `PH-T8.2C-CURRENCY-NORMALIZATION-01.md`
- tous documents `keybuzz-infra/docs` relatifs à billing / subscriptions / Stripe / metrics

---

## CONTEXTE DE VÉRITÉ

Aujourd'hui :

- spend réel Meta = intégré
- métriques = normalisées en EUR
- l'API metrics reste business-biaisée car elle compte encore des trials dans la lecture acquisition
- les essais durent 14 jours
- un utilisateur peut entrer sa CB, démarrer un trial, puis annuler avant conversion payante

Le problème à résoudre :

- ne plus piloter le CAC "réel" comme si un trial = un client payé

---

## ÉTAPE 0 — PRÉFLIGHT

Confirmer : branche correcte, repo clean, image API DEV avant phase

## ÉTAPE 1 — AUDIT MÉTIER DES STATUTS

Identifier dans la base et le code :
comment est représenté un trial, un abonnement actif/payant,
quels statuts Stripe / billing_subscriptions existent réellement,
à quel moment un client devient "paid".

## ÉTAPE 2 — DÉFINITION MÉTRIQUES

Définir : trial_customers, paid_customers, trial_to_paid_rate, cac_trial, cac_paid

## ÉTAPE 3 — IMPLÉMENTATION API

Modifier /metrics/overview pour ajouter breakdown customers, conversion, cac détaillé.

## ÉTAPE 4 — VÉRIFICATION SQL / DONNÉES RÉELLES

## ÉTAPE 5 — VALIDATION DEV

## ÉTAPE 6 — NON-RÉGRESSION

## ÉTAPE 7 — BUILD SAFE DEV : v3.5.86-trial-vs-paid-metrics-dev

## ÉTAPE 8 — ROLLBACK

## ÉTAPE 9 — RAPPORT FINAL

VERDICT ATTENDU

TRIAL VS PAID METRICS OPERATIONAL — CAC BUSINESS SAFER — DEV ONLY — ROLLBACK READY

STOP
```

### Ce qui a été fait

1. Ajout breakdown `customers.trial` / `customers.paid` / `customers.no_subscription`
2. Ajout `conversion.trial_to_paid_rate` (snapshot all-time)
3. Revenue calculé uniquement sur `status = 'active'` (pas trialing)
4. CAC paid = spend / paid_customers
5. Ajout `customers_by_plan` breakdown

### Pourquoi

Avant ce fix, un client en trial était compté comme "client payant" dans le CAC, ce qui donnait un CAC artificiellement bas.

### Document généré

- `keybuzz-infra/docs/PH-T8.2D-TRIAL-VS-PAID-METRICS-01.md`

---

## PHASE 6 — PH-T8.2E — PROD Promotion Metrics

**Date** : 20 avril 2026 — après-midi
**Agent** : SaaS API
**Environnement** : PROD

### Prompt d'origine complet

```
Prompt CE — PH-T8.2E-PROD-PROMOTION-METRICS-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz SaaS / API
Phase : PH-T8.2E-PROD-PROMOTION-METRICS-01
Environnement : PROD
Type : promotion PROD des métriques business réelles
Priorité : CRITIQUE

## OBJECTIF

Promouvoir en PROD la chaîne metrics complète déjà validée en DEV :

- PH-T8.2B : Meta real spend
- PH-T8.2C : currency normalization EUR
- PH-T8.2D : trial vs paid metrics

afin que l'endpoint PROD `/metrics/overview` soit aligné avec l'Admin V2 metrics.

---

## RÈGLES ABSOLUES

- PROD uniquement pour cette phase
- build-from-git obligatoire
- repo clean obligatoire
- branche obligatoire : `ph147.4/source-of-truth`
- AUCUNE autre branche
- GitOps strict
- AUCUN `kubectl set image`
- manifests PROD uniquement
- rollback PROD documenté
- aucun impact client/front SaaS
- aucun impact tracking
- aucun mock
- aucune donnée fake

---

## INTERDIT

- ne pas toucher Admin V2
- ne pas modifier le client SaaS
- ne pas toucher PROD avant préflight complet
- ne pas réintroduire spend fake

---

## ÉTAPE 0 — PRÉFLIGHT

Documenter : image PROD actuelle, image DEV validée, commit source exact, repo clean.

## ÉTAPE 1 — VÉRIFICATION FONCTIONNELLE DU CODE SOURCE

## ÉTAPE 2 — BUILD SAFE PROD : v3.5.86-trial-vs-paid-metrics-prod

## ÉTAPE 3 — CONFIG PROD (META_AD_ACCOUNT_ID, META_ACCESS_TOKEN)

## ÉTAPE 4 — GITOPS PROD

## ÉTAPE 5 — DEPLOY PROD

## ÉTAPE 6 — VALIDATION PROD

## ÉTAPE 7 — PREUVES

## ÉTAPE 8 — ROLLBACK PROD

## ÉTAPE 9 — RAPPORT FINAL

VERDICT ATTENDU

METRICS PROD ALIGNED — REAL SPEND + EUR + TRIAL/PAID OPERATIONAL — ADMIN READY

STOP
```

### Ce qui a été fait

1. Build PROD depuis même commit que DEV
2. Mise à jour `keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml`
3. Déploiement GitOps
4. Validation endpoint PROD `/metrics/overview`

### Document généré

- `keybuzz-infra/docs/PH-T8.2E-PROD-PROMOTION-METRICS-01.md`

---

## PHASE 7 — PH-T8.2Ebis — Exclude Test Data

**Date** : 20 avril 2026 — après-midi
**Agent** : SaaS API
**Environnement** : DEV + PROD

### Prompt d'origine complet

```
Prompt CE — PH-T8.2Ebis-EXCLUDE-TEST-DATA-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz SaaS / API
Phase : PH-T8.2Ebis-EXCLUDE-TEST-DATA-01
Environnement : DEV + PROD
Type : correction dataset metrics (exclusion comptes test)
Priorité : CRITIQUE

---

# 🎯 OBJECTIF

Exclure tous les comptes de test des métriques business :

- CAC
- ROAS
- conversion
- new_customers

Sans supprimer les données,
mais en les filtrant proprement.

---

# 🔴 RÈGLES ABSOLUES

- AUCUNE suppression DB
- AUCUN impact tracking
- AUCUNE modification Stripe
- AUCUNE perte data
- build-from-git obligatoire
- GitOps strict
- rollback obligatoire

---

# 🚫 INTERDIT

- ne pas DELETE tenants
- ne pas modifier billing_subscriptions
- ne pas casser métriques existantes
- ne pas inventer flag

---

# 🧱 ÉTAPE 1 — IDENTIFIER TEST DATA

Exemples :

- emails internes (ecomlg, switaa, etc.)
- domaines email connus
- tenants créés manuellement
- flag metadata si existant

# 🧱 ÉTAPE 2 — STRATÉGIE

Ajouter filtre global : is_test_account = true/false
NON destructif, réversible, explicite

# 🧱 ÉTAPE 3 — FILTRAGE METRICS

# 🧱 ÉTAPE 4 — TRANSPARENCE

Ajouter : data_quality: { test_data_excluded: true, test_accounts_count: X }

# 🧱 ÉTAPE 5 — VALIDATION

# 🧱 ÉTAPE 6 — NON-RÉGRESSION

# 🧱 ÉTAPE 7 — BUILD : v3.5.87-exclude-test-data

# 🧱 ÉTAPE 8 — RAPPORT

🎯 VERDICT

METRICS CLEAN — TEST DATA EXCLUDED — BUSINESS SAFE

STOP
```

### Ce qui a été fait

1. Création heuristiques initiales pour identifier les comptes test
2. Ajout `data_quality.test_data_excluded` et `test_accounts_count`
3. Filtrage SQL `LEFT JOIN tenant_billing_exempt`

### Document généré

- `keybuzz-infra/docs/PH-T8.2Ebis-EXCLUDE-TEST-DATA-01.md`

---

## PHASE 8 — PH-T8.2F — Test Account Control

**Date** : 20 avril 2026 — après-midi
**Agent** : SaaS API
**Environnement** : DEV + PROD

### Prompt d'origine complet

```
Prompt CE — PH-T8.2F-TEST-ACCOUNT-CONTROL-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz SaaS / API
Phase : PH-T8.2F-TEST-ACCOUNT-CONTROL-01
Environnement : DEV + PROD
Type : sécurisation exclusion comptes test
Priorité : CRITIQUE

---

# 🎯 OBJECTIF

Remplacer le système actuel basé sur heuristiques par un système explicite de gestion des comptes test.

---

# 🔴 RÈGLES ABSOLUES

- AUCUNE suppression DB
- AUCUNE modification tracking
- AUCUNE régression metrics
- build-from-git obligatoire
- GitOps strict
- rollback obligatoire

---

# 🚫 INTERDIT

- ne pas utiliser email/domain rules
- ne pas utiliser heuristiques automatiques
- ne pas exclure un compte sans flag explicite

---

# 🧱 ÉTAPE 1 — AUDIT ACTUEL

Identifier toutes les règles heuristiques utilisées.

# 🧱 ÉTAPE 2 — STRATÉGIE CIBLE

Se baser uniquement sur :

tenant_billing_exempt.reason = 'test_account'

# 🧱 ÉTAPE 3 — SUPPRESSION HEURISTIQUES

Ne garder QUE :

WHERE tbe.exempt = true AND reason = 'test_account'

# 🧱 ÉTAPE 4 — DATA FIX

Documenter et vérifier les tenants marqués test.

# 🧱 ÉTAPE 5 — API METRICS

# 🧱 ÉTAPE 6 — TRANSPARENCE

# 🧱 ÉTAPE 7 — VALIDATION

# 🧱 ÉTAPE 8 — BUILD : v3.5.88-test-control-safe

# 🧱 ÉTAPE 9 — RAPPORT

🎯 VERDICT

TEST ACCOUNT CONTROL SAFE — NO FALSE POSITIVE

STOP
```

### Ce qui a été fait

1. Création de la table `tenant_billing_exempt` (tenant_id, exempt, reason)
2. Migration des heuristiques vers des flags explicites
3. Toutes les requêtes SQL metrics filtrent via cette table
4. Les comptes ecomlg-001, test-*, romrauis-* marqués explicitement

### Pourquoi

Les heuristiques étaient fragiles. Un flag explicite dans une table dédiée est la seule source de vérité fiable.

### Document généré

- `keybuzz-infra/docs/PH-T8.2F-TEST-ACCOUNT-CONTROL-01.md`

---

## PHASE 9 — PH-T8.3.1 — Metrics UI Basic (Admin V2)

**Date** : 20 avril 2026 — après-midi
**Agent** : Admin V2
**Environnement** : DEV
**Image** : `v2.10.3-ph-t8-3-1-metrics-dev`

### Contexte inter-agents

L'agent SaaS venait de terminer T8.1-2 à T8.2F (toute la fondation metrics backend). L'utilisateur a transmis le format exact du payload `GET /metrics/overview` à l'agent Admin V2.

### Prompt d'origine complet

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
aucune promotion PROD sans validation explicite de Ludovic
STOP après validation DEV tant que Ludovic n'a pas écrit : "Tu peux push PROD"

Documents à lire obligatoirement

PH-T8.1-2-DATA-FOUNDATION-AND-METRICS-01.md
PH-T7.2.4-GA4-MP-CONFIG-PROD-FINAL-01.md
PH-T7.2.3-SAAS-API-TIKTOK-PROD-PROMOTION-01.md
PH-T7.3.2-REPLAY-LINKEDIN-ON-VALID-BRANCHES-DEV-01.md
PH-ADMIN-SOURCE-OF-TRUTH-02-RECOVERY.md
PH-ADMIN-87.16-LOGIN-SLOWNESS-FIX.md

Étape 1 — Audit de vérité API
Auditer GET /metrics/overview : structure payload, paramètres from/to, champs disponibles.
Confirmer : period, new_customers, customers_by_plan, revenue.mrr, spend.total, spend.by_channel, cac, roas, computed_at.
Créer : keybuzz-infra/docs/PH-T8.3.1-METRICS-UI-BASIC-AUDIT.md

Étape 2 — RBAC
Page /metrics accessible uniquement à : super_admin, account_manager.
Menu masqué pour les autres rôles, route protégée, aucune ouverture via URL directe.

Étape 3 — Route et navigation
Créer route /metrics, entrée sidebar zone business/management.

Étape 4 — UI minimale propre
Header (titre, filtre période, bouton refresh, computed_at)
KPI cards (Spend total, New customers, MRR, CAC, ROAS)
Bloc Customers by Plan (Starter, Pro, Autopilot)
Graph Revenue vs Spend (pas de faux historique)
Table Spend by Channel (Channel, Spend, Impressions, Clicks)

Étape 5 — UX / états
loading state, error state, empty state, refresh state.
Wording business simple, lisible pour fondateur et media buyer.

Étape 6 — Validation DEV
Tester : /metrics, RBAC, sidebar, refresh, période, non-régression.

Étape 7 — Build safe DEV
build-from-git, repo clean, tag v2.10.3-ph-t8-3-1-metrics-dev, digest exact.

Étape 8 — STOP avant PROD

Étape 9 — Rapport final
Créer : keybuzz-infra/docs/PH-T8.3.1-METRICS-UI-BASIC-REPORT.md

Verdict : METRICS UI BASIC READY — ADMIN V2 SAFE — BUILD SAFE — ROLLBACK READY
```

### Ce qui a été fait

1. Audit complet du payload `/metrics/overview` (structure, champs, paramètres)
2. Proxy Next.js : `/api/admin/metrics/overview` → backend SaaS via `KEYBUZZ_API_INTERNAL_URL`
3. Page `/metrics` : KPI cards (New Customers, MRR, CAC Blended, ROAS), spend par canal, conversion rate, date picker, indicateur data quality
4. RBAC super_admin + account_manager
5. Build + déploiement DEV `v2.10.3-ph-t8-3-1-metrics-dev`
6. Fichiers : `src/app/(admin)/metrics/page.tsx`, `src/app/api/admin/metrics/overview/route.ts`

### Documents générés

- `keybuzz-infra/docs/PH-T8.3.1-METRICS-UI-BASIC-AUDIT.md`
- `keybuzz-infra/docs/PH-T8.3.1-METRICS-UI-BASIC-REPORT.md`

---

## PHASE 10 — PH-T8.3.1B — No-Data UI Fix (Admin V2)

**Date** : 20 avril 2026 — après-midi
**Agent** : Admin V2
**Environnement** : DEV

### Prompt d'origine complet

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
GitOps strict obligatoire
rollback obligatoire
aucun kubectl set image
patch minimal uniquement

Documents à relire obligatoirement
PH-T8.3.1-METRICS-UI-BASIC-AUDIT.md
PH-T8.3.1-METRICS-UI-BASIC-REPORT.md
PH-T8.2-REAL-SPEND-TRUTH-01.md
PH-ADMIN-SOURCE-OF-TRUTH-02-RECOVERY.md

Étape 1 — Reproduire l'erreur
Ouvrir /metrics en DEV, capturer erreur console, identifier composant fautif.

Étape 2 — Auditer le composant /metrics
Zones sensibles : KPI cards (cac, roas), Revenue vs Spend, Spend by Channel (table vide),
Customers by Plan, computed_at formatage.

Étape 3 — Corriger le rendu no-data
Cas A (spend absent) : spend.total=0, by_channel=[], source="no_data"
Cas B (métriques null) : cac=null, roas=null
Cas C (data_quality) : spend_available=false
→ pas d'exception, pas de NaN, pas de Infinity, pas de barre cassée

Étape 4 — UX honnête
Afficher : "Aucune donnée réelle de spend disponible"
Conserver : new_customers, MRR, customers_by_plan (données réelles disponibles)

Étape 5 — Zéro donnée fake
Pas de spend par défaut, pas de canal dummy, pas de CAC/ROAS calculé localement si API null.

Étape 6 — Validation DEV
Cas 1 : no data (page charge, KPI réels, spend vide géré)
Cas 2 : RBAC (super_admin OK, account_manager OK, autres refusés)
Cas 3 : non-régression admin

Étape 7 — Build safe DEV : v2.10.4-ph-t8-3-1b-metrics-no-data-fix-dev
Étape 8 — STOP avant PROD
Étape 9 — Rapport : PH-T8.3.1B-METRICS-NO-DATA-UI-FIX-REPORT.md

Verdict : METRICS NO-DATA UI SAFE — NO FAKE DATA — ADMIN V2 STABLE — ROLLBACK READY
```

### Ce qui a été fait

1. Ajout de `safeNum()` helper : retourne `'N/A'` si `null`/`undefined`
2. Protection de tous les KPI cards contre les valeurs nulles
3. Message contextuel quand `spend.source === 'no_data'`
4. Tableau by_channel masqué si vide
5. Données réelles (new_customers, MRR) toujours affichées

### Document généré

- `keybuzz-infra/docs/PH-T8.3.1B-METRICS-NO-DATA-UI-FIX-REPORT.md`

---

## PHASE 11 — PH-T8.3.1C — Currency Mapping Fix (Admin V2)

**Date** : 20 avril 2026 — après-midi
**Agent** : Admin V2
**Environnement** : DEV

### Contexte inter-agents

L'agent SaaS avait changé la structure du payload en T8.2C (normalisation EUR). Les anciens champs `spend.total` existaient encore en backward compat mais en GBP brut. L'UI affichait du GBP étiqueté EUR → NaN.

### Prompt d'origine complet

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

Documents à relire
PH-T8.3.1-METRICS-UI-BASIC-REPORT.md
PH-T8.2B-META-REAL-SPEND-01-REPORT.md
PH-T8.2C-CURRENCY-NORMALIZATION-01.md

Étape 1 — Audit : identifier tous les accès à spend.total, spend.by_channel[].spend
Étape 2 — Mapper : spend.total → spend.total_eur, channel.spend → channel.spend_eur
Étape 3 — Helpers : safeNumber(), safeFormatEur() pour éviter NaN
Étape 4 — FX : afficher bloc fx (taux, source, date)
Étape 5 — Transparence : colonne currency_raw + spend_raw pour audit
Étape 6 — Validation DEV
Étape 7 — Build DEV
Étape 8 — Rapport : PH-T8.3.1C-METRICS-CURRENCY-MAPPING-FIX-REPORT.md

Verdict : METRICS CURRENCY SAFE — NO NAN — EUR NORMALIZED — ADMIN V2 STABLE
```

### Ce qui a été fait

1. Remplacement `spend.total` → `spend.total_eur` partout
2. Remplacement `channel.spend` → `channel.spend_eur`
3. Ajout colonne `currency_raw` / `spend_raw` pour transparence
4. Ajout indicateur FX (taux ECB, source, date)
5. Utilisation systématique de `safeNum()` sur tous les champs numériques

### Document généré

- `keybuzz-infra/docs/PH-T8.3.1C-METRICS-CURRENCY-MAPPING-FIX-REPORT.md`

---

## PHASE 12 — PH-T8.3.1-PROD-PROMOTION-02 — Première promo PROD Metrics (Admin V2)

**Date** : 20 avril 2026 — après-midi
**Agent** : Admin V2
**Environnement** : PROD

### Prompt d'origine complet

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

Documents à relire
PH-T8.3.1-METRICS-UI-BASIC-REPORT.md
PH-T8.3.1B-METRICS-NO-DATA-UI-FIX-REPORT.md
PH-T8.3.1C-METRICS-CURRENCY-MAPPING-FIX-REPORT.md
PH-T8.2E-PROD-PROMOTION-METRICS-01.md
PH-ADMIN-SOURCE-OF-TRUTH-02-RECOVERY.md

Étape 0 — Préflight (branche, repo clean, HEAD = remote, image PROD actuelle, image DEV validée)
Étape 1 — Vérification code source (toutes les corrections T8.3.1/B/C présentes)
Étape 2 — Build SAFE PROD (build-from-git, clone propre)
Étape 3 — GitOps PROD (manifest, commit + push infra)
Étape 4 — Validation navigateur PROD (/metrics chargement, KPI cards, spend, pas de NaN)
Étape 5 — Non-régression (login, session, sidebar, pages existantes)
Étape 6 — Rollback documenté
Étape 7 — Rapport : PH-T8.3.1-PROD-PROMOTION-02-REPORT.md

Verdict : ADMIN METRICS PROD OPERATIONAL — NO NAN — REAL SPEND — EUR NORMALIZED — GITOPS SAFE
```

### Ce qui a été fait

1. Preflight complet (branche, repo clean, images)
2. Build PROD depuis clone propre
3. GitOps : manifest PROD mis à jour, commit + push infra
4. Déploiement : rollout restart, pod running, image vérifiée
5. Validation navigateur : page `/metrics` PROD accessible, KPI cards affichés
6. Rollback documenté

### Document généré

- `keybuzz-infra/docs/PH-T8.3.1-PROD-PROMOTION-02-REPORT.md`

---

## PHASE 13 — PH-T8.3.1D — Trial/Paid Alignment (Admin V2)

**Date** : 20 avril 2026 — après-midi
**Agent** : Admin V2
**Environnement** : DEV

### Prompt d'origine complet

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

Documents à relire
PH-T8.3.1-METRICS-UI-BASIC-REPORT.md
PH-T8.2D-TRIAL-VS-PAID-METRICS-01.md
PH-T8.2F-TEST-ACCOUNT-CONTROL-01.md

Étape 1 — Audit payload trial/paid (customers.trial, customers.paid, conversion.trial_to_paid_rate, cac_detail, roas_detail)
Étape 2 — Section Customers Breakdown (cards séparées Trial / Paid / No Subscription)
Étape 3 — CAC détail (blended vs paid only)
Étape 4 — ROAS détaillé
Étape 5 — Conversion rate trial→paid
Étape 6 — Breakdown par plan (Starter / Pro / Autopilot)
Étape 7 — Data quality badges (test_data_excluded, spend_source)
Étape 8 — Validation DEV
Étape 9 — Build DEV : v2.10.6-ph-t8-3-1d-metrics-trial-paid-dev
Étape 10 — Rapport : PH-T8.3.1D-METRICS-TRIAL-PAID-ALIGNMENT-REPORT.md

Verdict : METRICS TRIAL/PAID ALIGNED — CAC PAID VISIBLE — DATA QUALITY — ADMIN V2 STABLE
```

### Ce qui a été fait

1. Section "Customers Breakdown" : cards séparées Trial / Paid / No Subscription
2. CAC en deux variantes : Blended (tous) et Paid (payants uniquement)
3. ROAS détaillé avec période
4. Conversion rate trial→paid mis en évidence
5. Breakdown par plan (Starter / Pro / Autopilot)
6. Data quality badges : "Test data excluded", "Real spend (Meta)", etc.

### Document généré

- `keybuzz-infra/docs/PH-T8.3.1D-METRICS-TRIAL-PAID-ALIGNMENT-REPORT.md`

---

## PHASE 14 — PH-T8.3.1D-PROD — Promotion PROD Metrics Final (Admin V2)

**Date** : 20 avril 2026 — soir
**Agent** : Admin V2
**Environnement** : PROD
**Image** : `v2.10.6-ph-t8-3-1d-metrics-trial-paid-prod`

### Prompt d'origine complet

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

PÉRIMÈTRE
ne pas modifier le backend SaaS
ne pas modifier billing
ne pas modifier Stripe
ne pas toucher au client SaaS

SÉCURITÉ
rollback PROD obligatoire
ne pas casser les pages existantes

Documents à relire
PH-T8.3.1D-METRICS-TRIAL-PAID-ALIGNMENT-REPORT.md
PH-T8.3.1-PROD-PROMOTION-02-REPORT.md
PH-ADMIN-SOURCE-OF-TRUTH-02-RECOVERY.md

Étape 0 — Préflight (branche, repo clean, HEAD = remote, image PROD, image DEV)
Étape 1 — Vérification code (T8.3.1 + B + C + D toutes présentes)
Étape 2 — Build SAFE PROD : v2.10.6-ph-t8-3-1d-metrics-trial-paid-prod
Étape 3 — GitOps PROD
Étape 4 — Validation navigateur PROD
Étape 5 — Non-régression
Étape 6 — Rollback documenté
Étape 7 — Rapport : PH-T8.3.1D-PROD-PROMOTION-REPORT.md

Verdict : ADMIN METRICS PROD — BUSINESS READY — CAC PAID — TRIAL/PAID — NO NAN — GITOPS SAFE
```

### Ce qui a été fait

1. Preflight complet, vérification code toutes corrections incluses
2. Build PROD `v2.10.6-ph-t8-3-1d-metrics-trial-paid-prod` (build-from-git, 0 erreurs)
3. GitOps PROD : manifest mis à jour, commit + push infra
4. Rollout PROD, pod Running, image vérifiée
5. Validation navigateur : page /metrics PROD fonctionnelle avec trial/paid
6. Rollback documenté

### Document généré

- `keybuzz-infra/docs/PH-T8.3.1D-PROD-PROMOTION-REPORT.md`

---

## PHASE 15 — PH-T8.3.1E — Admin Internal API Fix (Admin V2)

**Date** : 20 avril 2026 — soir
**Agent** : Admin V2
**Environnement** : DEV + PROD

### Prompt d'origine complet

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

🧱 ÉTAPE 1 — AUDIT COMPLET
Variable actuelle : KEYBUZZ_API_INTERNAL_URL
Valeur actuelle DEV / PROD
Service K8s réel : kubectl get svc -n keybuzz-api-prod
Identifier : port exposé, targetPort, DNS interne

🧱 ÉTAPE 2 — STANDARDISATION
Règle unique : TOUJOURS utiliser le Service K8s, JAMAIS le port container direct
→ http://keybuzz-api.keybuzz-api-prod.svc.cluster.local (pas :3001)

🧱 ÉTAPE 3 — CORRECTION MANIFESTS
k8s/keybuzz-admin-v2-dev/deployment.yaml
k8s/keybuzz-admin-v2-prod/deployment.yaml
Remplacer :3001 par rien (port 80 par défaut du Service)

🧱 ÉTAPE 4 — ALIGNEMENT DEV + PROD

🧱 ÉTAPE 5 — VALIDATION INTER-POD
Depuis pod Admin : wget http://keybuzz-api.keybuzz-api-prod.svc.cluster.local/metrics/overview
→ 200 OK < 1s

🧱 ÉTAPE 6 — VALIDATION NODE FETCH
🧱 ÉTAPE 7 — VALIDATION UI (/metrics chargement instantané)
🧱 ÉTAPE 8 — BUILD & DEPLOY (commit, push, rollout DEV, rollout PROD)
🧱 ÉTAPE 9 — ROLLBACK (ancienne URL, nouvelle URL, commit exact)
🧱 ÉTAPE 10 — RAPPORT : PH-T8.3.1E-ADMIN-INTERNAL-API-FIX-REPORT.md

Verdict : aucun fetch timeout, Admin stable, config unifiée DEV/PROD, GitOps respecté
```

### Le problème

En PROD, le service K8s du backend SaaS écoute sur le port **80** (pas 3001 comme en DEV). Le proxy Admin V2 envoyait les requêtes sur le mauvais port → timeouts en PROD. La variable `KEYBUZZ_API_INTERNAL_URL` pointait vers `:3001` qui est le port du container, pas le port du Service K8s.

### Ce qui a été fait

1. Audit : identification du port réel du Service K8s (80 → targetPort 3001)
2. Correction : `KEYBUZZ_API_INTERNAL_URL` dans les manifests DEV et PROD ajusté pour utiliser le DNS Service sans port explicite (port 80 par défaut)
3. Validation inter-pod : curl depuis le pod Admin vers le pod API → 200 OK < 1s
4. Config unifiée DEV = PROD

### Document généré

- `keybuzz-infra/docs/PH-T8.3.1E-ADMIN-INTERNAL-API-FIX-REPORT.md`

---

## PHASE 16 — PH-T8.4 — Outbound Conversions Webhook

**Date** : 21 avril 2026 — matin
**Agent** : SaaS API
**Environnement** : DEV
**Image** : `v3.5.93-outbound-conversions-dev`

### Prompt d'origine complet

```
Prompt CE — PH-T8.4-OUTBOUND-CONVERSIONS-WEBHOOK-01 (SAFE VERSION)

Rôle : Cursor Executor (CE)
Projet : KeyBuzz SaaS / API
Phase : PH-T8.4-OUTBOUND-CONVERSIONS-WEBHOOK-01
Environnement : DEV UNIQUEMENT (strict)
Type : émission server-side des conversions business réelles
Priorité : STRATÉGIQUE

---

# 🎯 OBJECTIF

Créer une brique serveur fiable pour exposer les conversions business réelles
(StartTrial, Purchase) vers des systèmes externes (webhook uniquement dans cette phase).

Objectif réel :
→ Permettre à une agence / media buyer d'exploiter les conversions backend
→ Sans dépendre du frontend
→ Sans fake data
→ Sans heuristique

---

# 🔴 RÈGLES ABSOLUES

## ENV
- DEV ONLY
- STOP avant PROD

## BUILD
- build-from-git obligatoire
- repo clean obligatoire
- commit + push AVANT build
- aucune dérive bastion

## GITOPS
- manifests DEV uniquement
- aucun kubectl set image
- rollback DEV obligatoire

## DATA
- SERVER SIDE ONLY
- zéro mock
- zéro fallback inventé
- zéro événement frontend

## INTÉGRITÉ
- ne pas casser : Stripe webhook, metrics, trial vs paid, exclusion test, autopilot, inbound pipeline

---

# 🚫 INTERDIT

- ne pas émettre d'événement depuis le frontend
- ne pas utiliser signup simple comme conversion
- ne pas envoyer de conversion sans preuve Stripe
- ne pas bypass tenant_billing_exempt
- ne pas dupliquer la logique metrics

---

# 🧠 CONTEXTE MÉTIER

Conversions officielles :

StartTrial =
- signup terminé
- CB validée
- trial actif

Purchase =
- paiement réel Stripe validé
- abonnement réellement actif (paid)

⚠️ Important :
- trial ≠ paid
- metrics existantes = source de vérité
- webhook doit être aligné avec metrics

---

# 🧱 ÉTAPES

0. PRÉFLIGHT
1. IDENTIFIER LES TRIGGERS RÉELS (StartTrial, Purchase)
2. AUDIT DATA DISPONIBLE
3. DÉFINIR LE PAYLOAD (event_name, event_id, customer, subscription, attribution, data_quality)
4. SIGNATURE (HMAC SHA256, header, secret via ENV)
5. DESTINATION (OUTBOUND_CONVERSIONS_WEBHOOK_URL, OUTBOUND_CONVERSIONS_WEBHOOK_SECRET)
6. IDÉMPOTENCE (event_id unique, log en DB)
7. RETRY (1 tentative, 2 retries max, timeout, logs)
8. EXCLUSION TEST (tenant_billing_exempt.exempt = true)
9. VALIDATION DEV
10. BUILD DEV : v3.5.92-outbound-conversions-dev
11. RAPPORT

🎯 VERDICT ATTENDU

OUTBOUND CONVERSIONS SERVER-SIDE READY — REAL DATA ONLY — DEV SAFE

STOP
```

### Ce qui a été fait

1. Création `src/modules/outbound-conversions/emitter.ts` :
  - `emitOutboundConversion(eventName, tenantId, subscriptionData, stripeValue)`
  - Payload structuré avec `customer.tenant_id`, `subscription.*`, `attribution.*`, `value.*`, `data_quality.*`
  - HMAC SHA256 signature via `X-KeyBuzz-Signature`
  - Idempotence via table `conversion_events` (event_id = `conv_{tenantId}_{eventName}_{subId}`)
  - 3 retries avec backoff (0s, 5s, 15s)
  - Exclusion test via `tenant_billing_exempt`
  - Attribution enrichie : UTMs, click IDs (gclid, fbclid, fbc, fbp, ttclid), email hash SHA256
2. Intégration dans `src/modules/billing/routes.ts` :
  - `handleCheckoutCompleted()` → `emitOutboundConversion('StartTrial', ...)`
  - `handleSubscriptionChange()` → `emitOutboundConversion('Purchase', ...)` quand `trialing → active`
3. Table `conversion_events` (id, event_id UNIQUE, tenant_id, event_name, payload JSONB, status, attempts)

### Pourquoi

C'est la brique fondamentale du tracking server-side. Avant, aucun événement de conversion n'était émis vers l'extérieur.

### Document généré

- `keybuzz-infra/docs/PH-T8.4-OUTBOUND-CONVERSIONS-WEBHOOK-01-REPORT.md`

---

## PHASE 17 — PH-T8.4.1 — Stripe Real Value

**Date** : 21 avril 2026 — matin
**Agent** : SaaS API
**Environnement** : DEV
**Image** : `v3.5.94-outbound-conversions-real-value-dev`

### Prompt d'origine complet

```
Prompt CE — PH-T8.4.1-STRIPE-REAL-VALUE-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz SaaS / API
Phase : PH-T8.4.1-STRIPE-REAL-VALUE-01
Environnement : DEV uniquement
Type : correction valeur réelle des conversions
Priorité : CRITIQUE

---

# 🎯 OBJECTIF

Remplacer la valeur approximative basée sur le plan par la valeur réelle issue de Stripe
dans les événements outbound conversions :

- StartTrial
- Purchase

---

# 🔴 RÈGLES ABSOLUES

- DEV ONLY
- build-from-git obligatoire
- repo clean obligatoire
- GitOps strict
- rollback obligatoire
- patch minimal
- AUCUN impact PROD
- AUCUN changement de structure payload (compatibilité)
- AUCUN impact metrics existantes

---

# 🚫 INTERDIT

- ne pas utiliser prix plan fixe comme fallback
- ne pas inventer une valeur
- ne pas modifier l'idempotence
- ne pas modifier l'exclusion test
- ne pas modifier l'attribution

---

# 🧱 ÉTAPES

0. PRÉFLIGHT
1. AUDIT SOURCE STRIPE (checkout.session.completed → amount_total, subscription.updated → items price)
2. STRATÉGIE (StartTrial = session.amount_total, Purchase = items sum)
3. IMPLÉMENTATION (modifier emitter.ts)
4. NORMALISATION (centimes → euros, currency Stripe)
5. VALIDATION DEV
6. NON-RÉGRESSION
7. BUILD DEV : v3.5.94-outbound-conversions-real-value-dev
8. RAPPORT

🎯 VERDICT ATTENDU

REAL VALUE FROM STRIPE — NO ESTIMATION — DEV SAFE

STOP
```

### Ce qui a été fait

1. Suppression de la map `PLAN_PRICES`
2. **StartTrial** : `session.amount_total / 100`
3. **Purchase** : `subscription.items.data[].price.unit_amount * quantity / 100`
4. Devise lue depuis Stripe

### Document généré

- `keybuzz-infra/docs/PH-T8.4.1-STRIPE-REAL-VALUE-01.md`

---

## PHASE 18 — PH-T8.4.1-PROD — Stripe Real Value PROD

**Date** : 21 avril 2026 — midi
**Agent** : SaaS API
**Environnement** : PROD
**Image** : `v3.5.94-outbound-conversions-real-value-prod`

### Prompt d'origine complet

```
Prompt CE — PH-T8.4.1-STRIPE-REAL-VALUE-PROD-PROMOTION-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz SaaS / API
Phase : PH-T8.4.1-STRIPE-REAL-VALUE-PROD-PROMOTION-01
Environnement : PROD
Type : promotion PROD correction valeur réelle Stripe
Priorité : CRITIQUE

## OBJECTIF

Promouvoir en PROD le correctif déjà validé en DEV pour que les événements outbound conversions
utilisent la valeur réelle Stripe au lieu d'une estimation par plan.

Cette phase traite UNIQUEMENT :
- la valeur réelle Stripe dans StartTrial et Purchase

Cette phase ne traite PAS :
- multi-destination
- doc agence
- mapping direct Meta/TikTok/Google/LinkedIn

---

## CONTEXTE IMPOSÉ

Source de vérité obligatoire :
- `PH-T8.4-OUTBOUND-CONVERSIONS-WEBHOOK-01-REPORT.md`
- `PH-T8.4.1-STRIPE-REAL-VALUE-01.md`

Le fix DEV validé est :
- branche : `ph147.4/source-of-truth`
- commit : `c47af816`
- image DEV : `v3.5.94-outbound-conversions-real-value-dev`

Le rapport DEV établit :
- `PLAN_PRICES` supprimé
- StartTrial = `session.amount_total / 100`
- Purchase = somme des `subscription.items[*].price.unit_amount * quantity / 100`
- currency issue de Stripe
- structure payload inchangée
- idempotence inchangée
- exclusion test inchangée

---

## RÈGLES ABSOLUES

- PROD uniquement pour cette phase
- build-from-git obligatoire
- repo clean obligatoire
- branche obligatoire : `ph147.4/source-of-truth`
- AUCUN `kubectl set image`
- GitOps strict
- rollback PROD documenté
- ne pas toucher Admin / client SaaS / tracking / metrics

---

## ÉTAPES

0. PRÉFLIGHT (image PROD actuelle, DEV validée, commit source)
1. VÉRIFICATION SOURCE
2. BUILD SAFE PROD
3. GITOPS PROD
4. DEPLOY PROD
5. VALIDATION PROD RÉELLE (StartTrial, Purchase, tenant test, non-régression)
6. PREUVES
7. ROLLBACK PROD
8. RAPPORT FINAL

VERDICT ATTENDU

REAL VALUE FROM STRIPE RESTORED IN PROD — NO ESTIMATION — NON REGRESSION OK

STOP
```

### Ce qui a été fait

1. Build PROD, mise à jour manifest, déploiement GitOps, validation complète

### Document généré

- `keybuzz-infra/docs/PH-T8.4.1-STRIPE-REAL-VALUE-PROD-PROMOTION-01.md`

---

## PHASE 19 — PH-T8.5 — Agency Integration Doc

**Date** : 21 avril 2026 — midi
**Agent** : SaaS API
**Environnement** : Documentation pure (aucun code)

### Prompt d'origine complet

```
Prompt CE — PH-T8.5-AGENCY-INTEGRATION-DOC-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz SaaS / API
Phase : PH-T8.5-AGENCY-INTEGRATION-DOC-01
Environnement : PROD uniquement (lecture + documentation)
Type : documentation technique + onboarding agence / media buyer
Priorité : STRATÉGIQUE

---

# 🎯 OBJECTIF

Créer une documentation claire, exploitable et professionnelle permettant à :

- une agence marketing
- un media buyer

de se connecter aux conversions server-side KeyBuzz et de les utiliser
dans leurs outils (Meta, TikTok, Google, sGTM, Zapier, etc.)

---

# 🔴 RÈGLES ABSOLUES

- PROD ONLY (pas DEV)
- AUCUNE modification code
- AUCUN build
- AUCUN deploy
- AUCUNE modification API
- AUCUNE modification webhook
- AUCUNE donnée fake

---

# 🧱 ÉTAPES

1. EXPLIQUER LE SYSTÈME (User → Stripe → Backend → Webhook → Agence)
2. DOCUMENTER LES ÉVÉNEMENTS (StartTrial, Purchase)
3. PAYLOAD COMPLET (structure JSON, champs, types, exemples)
4. SIGNATURE (HMAC SHA256, vérification Node.js/Python)
5. COMMENT SE CONNECTER (guide agence)
6. EXEMPLES D'INTÉGRATION (Zapier, Make, sGTM)
7. MAPPING PUBLICITÉ (Meta, TikTok, Google Ads)
8. QUALITÉ DATA (exclusion test, trial/paid, currency, idempotence)
9. LIMITES
10. QUICK START
11. FICHIER FINAL

🎯 VERDICT ATTENDU

AGENCY INTEGRATION READY — CLEAR DOC — ZERO AMBIGUITY

STOP
```

### Ce qui a été fait

1. Guide complet pour media buyers
2. Explication payload, headers, signature HMAC
3. Exemples vérification signature en Python et Node.js
4. Mapping vers Meta CAPI, TikTok Events API, Google Ads
5. **Réécriture conviviale** : à la demande de l'utilisateur, le document a été réécrit en ton informel (tutoiement) pour ses media buyers

### Document généré

- `keybuzz-infra/docs/PH-T8.5-AGENCY-INTEGRATION-DOC-01.md`

---

## PHASE 20 — PH-T8.5.1 — Webhook Site PROD Test

**Date** : 21 avril 2026 — après-midi
**Agent** : SaaS API
**Environnement** : PROD (temporaire)

### Prompt d'origine complet

```
Prompt CE — PH-T8.5.1-WEBHOOK-SITE-PROD-TEST-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz SaaS / API
Phase : PH-T8.5.1-WEBHOOK-SITE-PROD-TEST-01
Environnement : PROD
Type : activation temporaire d'une destination webhook externe de test
Priorité : ÉLEVÉE

## OBJECTIF

Activer TEMPORAIREMENT une destination externe de test `webhook.site` en PROD pour valider
de bout en bout les webhooks outbound conversions server-side :

- StartTrial
- Purchase

Sans modifier le code.
Sans build.
Sans toucher au client.
Sans toucher à Admin.

Le but est uniquement :
- renseigner une URL de test externe en PROD
- vérifier la réception des événements
- documenter le rollback immédiat

---

## CONTEXTE IMPOSÉ

Les outbound conversions server-side sont déjà déployées et validées en PROD :
- module outbound conversions actif
- valeur réelle Stripe active
- test accounts exclus
- structure payload stable
- signature HMAC en place

Mais les env vars PROD actuelles sont vides :
- `OUTBOUND_CONVERSIONS_WEBHOOK_URL=""`
- `OUTBOUND_CONVERSIONS_WEBHOOK_SECRET=""`

---

## RÈGLES ABSOLUES

- PROD uniquement
- AUCUN build
- AUCUN deploy d'image
- AUCUNE modification de code
- AUCUN `kubectl set env`
- GitOps strict uniquement
- changement strictement temporaire et documenté

---

## INPUT ATTENDU

Utiliser la valeur fournie par Ludovic :

- `https://webhook.site/a6e85482-1ec8-4709-9bd3-ad484c2255f4`
- `k4Ay459iJ6cTTe`

---

## ÉTAPES

0. PRÉFLIGHT
1. MODIFICATION GITOPS STRICTE (2 env vars uniquement)
2. COMMIT INFRA
3. APPLY / ROLLOUT
4. VALIDATION TECHNIQUE
5. STOP ET ATTENTE TEST EXTERNE (Ludovic vérifie dans webhook.site)
6. ROLLBACK PRÊT

VERDICT ATTENDU

WEBHOOK.SITE PROD TEST ACTIVATED — TEMPORARY — GITOPS SAFE — ROLLBACK READY

STOP
```

### Ce qui a été fait

1. Configuration env vars → `https://webhook.site/xxx`
2. Rollout restart du pod PROD
3. Vérification réception des events sur webhook.site
4. **Rollback** : env vars vidées après le test

### Résultat additionnel

L'utilisateur a constaté 2 comptes de test dans les metrics (son test + "romrauis"). Exclusion demandée et faite immédiatement via `tenant_billing_exempt`.

### Document généré

- `keybuzz-infra/docs/PH-T8.5.1-WEBHOOK-SITE-PROD-TEST-01.md`

---

## PHASE 21 — PH-T8.6A — Outbound Destinations API

**Date** : 21 avril 2026 — après-midi
**Agent** : SaaS API
**Environnement** : DEV
**Image** : `v3.5.95-outbound-destinations-api-dev`

### Prompt d'origine complet

```
Prompt CE — PH-T8.6A-OUTBOUND-DESTINATIONS-API-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz SaaS / API
Phase : PH-T8.6A-OUTBOUND-DESTINATIONS-API-01
Environnement : DEV uniquement
Type : API self-service destinations outbound conversions
Priorité : STRATÉGIQUE

## OBJECTIF

Créer la couche API permettant à des utilisateurs autorisés de gérer eux-mêmes
les destinations webhook des conversions server-side (StartTrial, Purchase)
sans intervention manuelle infra.

Cette phase doit préparer un usage autonome par :
- account_manager
- media_buyer

pour connecter :
- Meta / Facebook / Instagram
- TikTok
- Google / YouTube
- LinkedIn
- Zapier / Make / n8n / sGTM / custom webhook

⚠️ L'intégration reste générique : on gère des destinations webhook signées,
pas des connecteurs spécifiques par plateforme dans cette phase.

---

## RÈGLES ABSOLUES

- DEV ONLY
- build-from-git obligatoire
- repo clean obligatoire
- branche obligatoire : `ph147.4/source-of-truth`
- GitOps strict
- AUCUN `kubectl set image`
- rollback obligatoire

---

## ÉTAPES

0. PRÉFLIGHT
1. MODÈLE DE DONNÉES (outbound_conversion_destinations, outbound_conversion_delivery_logs)
2. RBAC API (super_admin : tout, account_manager : tout marketing, media_buyer : lecture + create/update/test)
3. API ROUTES (GET, POST, PATCH, POST test, GET logs)
4. INTÉGRATION AU MODULE EXISTANT (multi-destination, idempotence par destination, logs)
5. SECRET / SÉCURITÉ (jamais renvoyé en clair, audit log)
6. TEST DELIVERY (événement "ConnectionTest")
7. VALIDATION DEV
8. BUILD DEV : v3.5.95-outbound-destinations-api-dev
9. RAPPORT FINAL

VERDICT ATTENDU

OUTBOUND DESTINATIONS API READY — MEDIA BUYER SELF-SERVICE BACKEND — DEV SAFE

STOP
```

### Ce qui a été fait

1. **Tables** : `outbound_conversion_destinations`, `outbound_conversion_delivery_logs`
2. **Routes API** (`src/modules/outbound-conversions/routes.ts`) : 5 endpoints REST + `checkAccess()`, `maskSecret()`, `isValidHttpsUrl()`
3. **Emitter refactoré** : `getActiveDestinations()` (DB first, env var fallback), boucle multi-destination
4. **ConnectionTest** : événement dédié pour test

### Document généré

- `keybuzz-infra/docs/PH-T8.6A-OUTBOUND-DESTINATIONS-API-01.md`

---

## PHASE 22 — PH-T8.6B — Media Buyer Admin UI (Admin V2)

**Date** : 21 avril 2026 — après-midi
**Agent** : Admin V2
**Environnement** : DEV
**Image** : `v2.10.8-ph-t8-6b-media-buyer-dev`

### Contexte inter-agents

L'agent SaaS venait de terminer T8.6A (API destinations). L'utilisateur a demandé à l'agent Admin V2 de créer l'UI correspondante avec un rôle dédié `media_buyer`.

### Prompt d'origine complet

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

PÉRIMÈTRE
ne pas modifier le backend SaaS/API
ne pas modifier billing SaaS
ne pas modifier Stripe
ne pas toucher au website
ne pas toucher au frontend client SaaS

SÉCURITÉ
aucun accès cross-tenant
aucune fuite de données
media_buyer ne voit que ses tenants assignés
aucun accès aux zones Admin sensibles

Documents à relire obligatoirement
PH-T8.6A-OUTBOUND-DESTINATIONS-API-01.md
PH-T8.5-AGENCY-INTEGRATION-DOC-01.md
PH-T8.3.1D-PROD-PROMOTION-REPORT.md
PH-ADMIN-SOURCE-OF-TRUTH-02-RECOVERY.md

CONTEXTE IMPOSÉ
L'API SaaS expose déjà en DEV :
GET /outbound-conversions/destinations
POST /outbound-conversions/destinations
PATCH /outbound-conversions/destinations/:id
POST /outbound-conversions/destinations/:id/test
GET /outbound-conversions/destinations/:id/logs

🧱 ÉTAPE 0 — PRÉFLIGHT
🧱 ÉTAPE 1 — RÔLE MEDIA_BUYER
AdminRole type, rbac.ts, hiérarchie (sous account_manager)
middleware route protection
accès pages Marketing uniquement

🧱 ÉTAPE 2 — NAVIGATION SIDEBAR
Section "Marketing" avec 4 sous-pages :
- Metrics (réutilise /metrics existant)
- Destinations
- Delivery Logs
- Integration Guide

🧱 ÉTAPE 3 — PAGE DESTINATIONS
CRUD UI : liste, création, édition, test, toggle active/inactive
Secret masqué (maskSecret)
Actions : Test Connection, Toggle, Delete

🧱 ÉTAPE 4 — PAGE DELIVERY LOGS
Tableau paginé : destination, event, status, timestamp, response_code
Filtrage par destination et par événement

🧱 ÉTAPE 5 — PAGE INTEGRATION GUIDE
Documentation intégrée pour media buyers (payload, HMAC, exemples)

🧱 ÉTAPE 6 — PROXY NEXT.JS ADMIN → API
5 routes proxy vers SaaS API /outbound-conversions/*
Headers propagés : x-user-email, x-tenant-id, x-admin-role

🧱 ÉTAPE 7 — TENANT SCOPE
Media buyer ne voit que ses tenants assignés
Tenant selector marketing

🧱 ÉTAPE 8 — VALIDATION DEV
🧱 ÉTAPE 9 — BUILD DEV : v2.10.7-media-buyer-marketing-dev (ou tag adjacent)
🧱 ÉTAPE 10 — RAPPORT : PH-T8.6B-MEDIA-BUYER-ADMIN-UI-01.md

Verdict : MEDIA BUYER SELF-SERVICE READY — SECURE — MULTI-TENANT SAFE — NO DATA LEAK — DEV SAFE
```

### Ce qui a été fait

1. **Rôle `media_buyer`** : ajouté dans AdminRole type, rbac.ts, hiérarchie RBAC (sous account_manager)
2. **Section Marketing sidebar** : 4 sous-pages (destinations, delivery-logs, integration-guide, metrics)
3. **Pages créées** : `marketing/destinations` (CRUD complet), `marketing/delivery-logs` (tableau paginé), `marketing/integration-guide` (doc intégrée)
4. **Proxy Next.js** : 5 routes proxy vers SaaS API `/outbound-conversions/`* avec headers `x-user-email`, `x-tenant-id`, `x-admin-role`
5. **RBAC** : media_buyer accès Marketing uniquement, tenant-scoped
6. **Build DEV** : `v2.10.8-ph-t8-6b-media-buyer-dev`

### Document généré

- `keybuzz-infra/docs/PH-T8.6B-MEDIA-BUYER-ADMIN-UI-01.md`

---

## PHASE 23 — PH-T8.6B-FIX — Marketing Proxy Fix (Admin V2 + SaaS)

**Date** : 21 avril 2026 — soir
**Agent** : Admin V2 + SaaS (interaction collaborative)
**Environnement** : DEV

> **Note** : Cette phase n'a pas de prompt formel unique. Elle résulte d'un debugging interactif
> déclenché par l'utilisateur signalant des erreurs 404/403 en DEV sur les pages Marketing.
> L'utilisateur a transmis les captures d'écran montrant les erreurs entre les deux agents.

### Le problème (3 issues distinctes)

1. **Chemins API incorrects** : les routes proxy Admin V2 (`/api/admin/marketing/destinations`) ne matchaient pas les routes backend SaaS (`/outbound-conversions/destinations`). Le mapping entre les deux était incorrect dans les 5 fichiers `route.ts` du proxy.
2. **Headers auth manquants** : les headers `x-user-email` et `x-tenant-id` n'étaient pas propagés dans les requêtes proxy, empêchant le backend de valider l'identité et le scope tenant.
3. **RBAC impossible** : les administrateurs Admin V2 (`super_admin`, `ops_admin`) ne sont pas dans la table `user_tenants` côté SaaS (ils accèdent à tous les tenants par design). Le `checkAccess()` côté backend retournait "Insufficient permissions" car il cherchait l'admin dans `user_tenants`.

### Interaction inter-agents remarquable

Cette phase illustre parfaitement la coordination entre les deux agents via l'utilisateur :

1. **Agent Admin V2** identifie les erreurs 403/404, documente les chemins API incorrects et les headers manquants
2. **L'utilisateur transmet** le diagnostic complet (erreurs console, logs réseau) à **l'agent SaaS**
3. **L'agent SaaS** corrige le backend : commit `536d3340` — ajout d'un bypass admin dans `checkAccess()` : si header `x-admin-role` = `super_admin` ou `ops_admin`, le check `user_tenants` est bypassé, tout en maintenant le scope `tenant_id` pour l'isolation des données
4. **L'agent Admin V2** corrige les chemins proxy (5 fichiers `route.ts`) et ajoute les headers `x-user-email`, `x-tenant-id`, `x-admin-role` dans toutes les requêtes proxy marketing

### Fichiers modifiés (Admin V2)

- `src/app/api/admin/marketing/destinations/route.ts` — fix path + headers
- `src/app/api/admin/marketing/destinations/[id]/route.ts` — fix path + headers
- `src/app/api/admin/marketing/destinations/[id]/test/route.ts` — fix path + headers
- `src/app/api/admin/marketing/destinations/[id]/logs/route.ts` — fix path + headers
- `src/app/api/admin/marketing/delivery-logs/route.ts` — fix path + headers

### Fichiers modifiés (SaaS API)

- `src/modules/outbound-conversions/routes.ts` — ajout bypass admin dans `checkAccess()`

### Document généré

- `keybuzz-infra/docs/PH-T8.6B-MARKETING-PROXY-FIX-02.md`

---

## PHASE 24 — PH-T8.6C SaaS — PROD Promotion API Destinations

**Date** : 22 avril 2026 — matin
**Agent** : SaaS API
**Environnement** : PROD
**Image** : `v3.5.95-outbound-destinations-api-prod`

### Prompt d'origine complet

```
Prompt CE — PH-T8.6C-SAAS-PROD-PROMOTION-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz SaaS / API
Phase : PH-T8.6C-SAAS-PROD-PROMOTION-01
Environnement : PROD
Type : promotion PROD API outbound destinations + webhook conversions
Priorité : CRITIQUE

---

# 🎯 OBJECTIF

Promouvoir en PROD :

- outbound conversions server-side (StartTrial, Purchase)
- valeur réelle Stripe
- module destinations webhook self-service
- multi-destination (DB + fallback ENV)

---

# 🔴 RÈGLES ABSOLUES

- build-from-git obligatoire
- repo clean obligatoire
- branche = ph147.4/source-of-truth
- GitOps strict
- AUCUN kubectl set image
- rollback obligatoire
- aucun changement client / Admin / tracking / metrics

---

# 🧱 ÉTAPES

0. PRÉFLIGHT (image PROD actuelle, image DEV validée, commit source b0b2f898)
1. VÉRIFICATION SOURCE (routes.ts, emitter, fallback, RBAC, logs)
2. BUILD PROD : v3.5.95-outbound-destinations-api-prod
3. GITOPS PROD
4. DEPLOY
5. VALIDATION PROD (destinations, conversions, ConnectionTest, payload, HMAC, idempotence)
6. NON-RÉGRESSION
7. ROLLBACK
8. RAPPORT

🎯 VERDICT

OUTBOUND DESTINATIONS PROD READY — WEBHOOK SELF-SERVICE LIVE — SAFE BUILD

STOP
```

### Ce qui a été fait

1. Build PROD, mise à jour manifest, déploiement GitOps, validation complète

### Document généré

- `keybuzz-infra/docs/PH-T8.6C-SAAS-PROD-PROMOTION-01.md`

---

## PHASE 25 — PH-T8.6C Admin — PROD Promotion Marketing (Admin V2)

**Date** : 22 avril 2026 — matin
**Agent** : Admin V2
**Environnement** : PROD
**Image** : `v2.10.9-admin-access-fix-prod`

### Prompt d'origine complet

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

PÉRIMÈTRE
ne pas modifier le backend SaaS/API dans cette phase
ne pas modifier billing SaaS
ne pas modifier Stripe
ne pas toucher au website
ne pas toucher au frontend client SaaS

SÉCURITÉ
rollback PROD obligatoire
ne pas casser RBAC existant
ne pas ouvrir d'accès cross-tenant
ne pas casser les pages existantes

Documents à relire obligatoirement
PH-T8.6B-MEDIA-BUYER-ADMIN-UI-01.md
PH-T8.6B-MARKETING-PROXY-FIX-02.md
PH-T8.6C-SAAS-PROD-PROMOTION-01.md
PH-T8.3.1D-PROD-PROMOTION-REPORT.md
PH-ADMIN-SOURCE-OF-TRUTH-02-RECOVERY.md

🧱 ÉTAPE 0 — PRÉFLIGHT (branche, repo clean, image PROD actuelle, image DEV validée)
🧱 ÉTAPE 1 — VÉRIFICATION CODE
A. Rôle media_buyer (AdminRole, rbac.ts, middleware)
B. Section Marketing (4 pages, navigation, sidebar)
C. Proxy (5 routes, headers, chemins corrigés)
D. Tenant selector marketing

🧱 ÉTAPE 2 — BUILD SAFE PROD : v2.10.9-admin-access-fix-prod
🧱 ÉTAPE 3 — GITOPS PROD (manifest, commit, push, rollout)

🧱 ÉTAPE 4 — VALIDATION NAVIGATEUR PROD
A. /metrics (KPI, trial/paid, spend)
B. /marketing/destinations (CRUD, test connection)
C. /marketing/delivery-logs (pagination, statuts)
D. /marketing/integration-guide (documentation)

🧱 ÉTAPE 5 — SÉCURITÉ
media_buyer ne voit que tenants assignés
super_admin accès complet
aucune fuite cross-tenant

🧱 ÉTAPE 6 — NON-RÉGRESSION
🧱 ÉTAPE 7 — ROLLBACK PROD documenté
🧱 ÉTAPE 8 — RAPPORT : PH-T8.6C-ADMIN-PROD-PROMOTION-02.md

Verdict : MEDIA BUYER SELF-SERVICE LIVE — DESTINATIONS + LOGS + DOC — RBAC — GITOPS SAFE
```

### Ce qui a été fait

1. Preflight complet (branche, repo clean, images DEV/PROD)
2. Vérification code : rôle media_buyer, section Marketing, proxy corrigé, headers
3. Build PROD `v2.10.9-admin-access-fix-prod` (build-from-git, 0 erreurs)
4. GitOps PROD : manifest mis à jour, commit + push infra, rollout
5. Validation navigateur PROD : `/metrics`, `/marketing/destinations`, `/marketing/delivery-logs`, `/marketing/integration-guide`
6. RBAC vérifié : super_admin tout, media_buyer tenants assignés
7. Non-régression : pages existantes intactes
8. Rollback documenté

### Document généré

- `keybuzz-infra/docs/PH-T8.6C-ADMIN-PROD-PROMOTION-02.md`

---

## PHASE 26 — PH-ADMIN-TENANT-FOUNDATION-01 — Fondation Multi-Tenant Admin V2

**Date** : 4 mars 2026 → reprise 22 avril 2026
**Agent** : Admin V2
**Environnement** : DEV
**Image** : `v2.11.0-tenant-foundation-dev`
**Commit** : `0d581ab`

> Cette phase est prérequise pour T8.7A (metrics tenant-scoped).

### Prompt d'origine complet

```
PH-ADMIN-TENANT-FOUNDATION-01 -- Refonte Fondation Multi-Tenant Admin

Rôle : Cursor Executor (CE)
Projet : KeyBuzz Admin V2
Phase : PH-ADMIN-TENANT-FOUNDATION-01
Environnement : DEV
Type : refonte fondation multi-tenant Admin V2
Priorité : CRITIQUE

🎯 OBJECTIF

Unifier les 4 patterns de tenant context incompatibles coexistant dans Admin V2
en un système global cohérent :

Pattern A (useTenantSelector) : ai-control, activation, policies, monitoring, debug
Pattern B (URL params) : ai, connectors, incidents, billing
Pattern C (marketing selector) : destinations, delivery-logs
Pattern D (global) : metrics, ops, queues

👉 Résultat attendu :
Un seul système de tenant context, global, persisté, accessible partout.

🔴 RÈGLES ABSOLUES
BUILD / SOURCE OF TRUTH
build-from-git obligatoire
repo clean obligatoire
commit + push AVANT build
AUCUN build depuis working dir dirty

GITOPS
manifest DEV uniquement
commit + push infra obligatoire
AUCUN kubectl set image

PÉRIMÈTRE
ne pas modifier le backend SaaS/API
ne pas modifier billing SaaS
ne pas modifier Stripe
ne pas toucher au website
ne pas toucher au frontend client SaaS

SÉCURITÉ
ne pas casser RBAC existant
ne pas ouvrir d'accès cross-tenant
ne pas casser les pages globales
ne pas réintroduire les anciens patterns tenant

🧱 ÉTAPE 1 — AUDIT DES 4 PATTERNS
Documenter précisément chaque pattern, ses fichiers, son mécanisme.

🧱 ÉTAPE 2 — CONCEPTION DU SYSTÈME UNIFIÉ
TenantProvider : React Context global
useCurrentTenant() : hook unique de récupération du tenant
localStorage : clé unifiée kb-admin-tenant
Tenant selector : dropdown global dans la Topbar
RequireTenant : composant wrapper bloquant si aucun tenant sélectionné

🧱 ÉTAPE 3 — IMPLÉMENTATION TENANT CONTEXT
Créer src/contexts/TenantContext.tsx
Créer src/components/ui/RequireTenant.tsx
Modifier src/components/layout/Topbar.tsx
Wrapper dans src/app/(admin)/layout.tsx

🧱 ÉTAPE 4 — CRÉATION DE TENANT
POST /api/admin/tenants (transactionnel)
usersService.createTenant()
Tables : tenants, users, user_tenants, tenant_metadata, ai_actions_wallet
Rôles autorisés : super_admin, ops_admin, account_manager

🧱 ÉTAPE 5 — GET /api/admin/tenants ROLE-AWARE
super_admin/ops_admin : tous les tenants
account_manager/media_buyer/agent : tenants assignés uniquement

🧱 ÉTAPE 6 — MIGRATION DES 14 PAGES
Remplacer chaque pattern par useCurrentTenant() + RequireTenant :
/metrics, /ai, /ai-control/activation, /ai-control/policies, /ai-control/monitoring,
/ai-control/debug, /connectors, /incidents, /billing, /marketing/destinations,
/marketing/delivery-logs, /tenants (création), /users (listing)

🧱 ÉTAPE 7 — SUPPRESSION ANCIENS PATTERNS
Supprimer useTenantSelector.ts
Supprimer marketing/tenants/route.ts
Nettoyer les imports obsolètes

🧱 ÉTAPE 8 — VALIDATION DEV
Toutes les pages chargent sans erreur
Tenant selector visible et fonctionnel
RequireTenant bloque si aucun tenant
Création de tenant fonctionnelle
RBAC : super_admin tout, media_buyer tenants assignés
Non-régression pages globales

🧱 ÉTAPE 9 — BUILD SAFE DEV : v2.11.0-tenant-foundation-dev
build-from-git, repo clean, digest exact

🧱 ÉTAPE 10 — RAPPORT : PH-ADMIN-TENANT-FOUNDATION-01.md

Verdict : ADMIN MULTI-TENANT CONSISTENT — SINGLE CONTEXT — GLOBAL SELECTOR — SAFE
```

### Ce qui a été fait

1. **Audit complet** des 4 patterns incompatibles (A: useTenantSelector, B: URL params, C: marketing selector, D: global)
2. `src/contexts/TenantContext.tsx` — React Context + Provider global avec fetch role-aware, persistance localStorage `kb-admin-tenant`
3. `src/components/ui/RequireTenant.tsx` — wrapper d'accès tenant (message explicite si aucun tenant)
4. `src/app/api/admin/tenants/route.ts` — GET role-aware (super_admin=tous, autres=assignés) + POST création transactionnelle (5 tables en transaction)
5. `src/features/users/services/users.service.ts` — méthode `createTenant()` transactionnelle
6. Topbar tenant selector dropdown dans `src/components/layout/Topbar.tsx`
7. **14 pages migrées** vers `useCurrentTenant()` + `<RequireTenant>`
8. Suppression `useTenantSelector.ts` et routes `marketing/tenants/route.ts`
9. Build DEV `v2.11.0-tenant-foundation-dev`, commit `0d581ab`

### Document généré

- `keybuzz-infra/docs/PH-ADMIN-TENANT-FOUNDATION-01.md`

---

## PHASE 27 — PH-ADMIN-TENANT-FOUNDATION-02 — PROD Promotion Fondation Tenant (Admin V2)

**Date** : 22 avril 2026 — après-midi
**Agent** : Admin V2
**Environnement** : PROD
**Image** : `v2.11.0-tenant-foundation-prod`
**Digest** : `sha256:b6c33e7754673c874b9a0eb10e3377fb30334dc8e83e3236c391b918bfd8a148`

### Prompt d'origine complet

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

PÉRIMÈTRE
ne pas modifier le backend SaaS/API dans cette phase
ne pas modifier billing SaaS
ne pas modifier Stripe
ne pas toucher au website
ne pas toucher au frontend client SaaS

SÉCURITÉ
rollback PROD obligatoire
ne pas casser RBAC existant
ne pas ouvrir d'accès cross-tenant
ne pas casser les pages globales
ne pas réintroduire les anciens patterns tenant

📚 DOCUMENTS À RELIRE OBLIGATOIREMENT
PH-ADMIN-TENANT-FOUNDATION-01.md
PH-ADMIN-SOURCE-OF-TRUTH-02-RECOVERY.md
PH-ADMIN-87.16-LOGIN-SLOWNESS-FIX.md

🧱 ÉTAPE 0 — PRÉFLIGHT
git branch, git log, git status
Image Admin PROD actuelle, digest, version runtime
Image DEV validée : v2.11.0-tenant-foundation-dev
Manifest PROD actuel

🧱 ÉTAPE 1 — VÉRIFICATION DU CODE À PROMOUVOIR
A. Fondation globale : TenantProvider, useCurrentTenant(), kb-admin-tenant, selector Topbar, RequireTenant
B. Tenant creation : POST /api/admin/tenants, usersService.createTenant(), rôles autorisés
C. Pages migrées : /metrics, /ai, /ai-control/*, /connectors, /incidents, /billing, marketing/*
D. Nettoyage : useTenantSelector.ts absent, marketing/tenants/route.ts absent

🧱 ÉTAPE 2 — BUILD SAFE PROD : v2.11.0-tenant-foundation-prod
build-from-git, repo clean, commit pushé, digest exact

🧱 ÉTAPE 3 — GITOPS PROD
Manifest PROD uniquement, commit infra, push, rollout
Vérifier : pod mis à jour, bon digest, DEV inchangée

🧱 ÉTAPE 4 — VALIDATION NAVIGATEUR RÉELLE PROD
A. Tenant selector global (visible topbar, persisté, changement OK)
B. Création tenant (via /tenants, owner email, plan, trial, country)
C. Pages tenant-scoped (avec/sans tenant sélectionné)
D. Pages globales (/, /ops, /queues, /approvals, /followups, /tenants, /users, /settings, /system-health, /feature-flags, /audit)

🧱 ÉTAPE 5 — VALIDATION MULTI-TENANT / RBAC
A. Super admin : voit tous tenants, peut créer, peut changer
B. Media buyer / account manager : tenants assignés uniquement
C. Pas d'incohérence, pas de comportement hybride

🧱 ÉTAPE 6 — NON-RÉGRESSION
login, session, topbar, sidebar, pages marketing, pages metrics

🧱 ÉTAPE 7 — ROLLBACK PROD
Image précédente, digest, manifest, procédure GitOps complète

🧱 ÉTAPE 8 — RAPPORT : PH-ADMIN-TENANT-FOUNDATION-02-PROD-PROMOTION.md

Verdict : ADMIN MULTI-TENANT FOUNDATION LIVE IN PROD — TENANT CREATION — GLOBAL SELECTOR — SAFE — GITOPS READY
```

### Ce qui a été fait

1. Preflight complet : branche `main`, repo clean, image PROD relevée
2. Vérification code : TenantProvider, RequireTenant, createTenant, 14 pages migrées, patterns supprimés
3. Build PROD `v2.11.0-tenant-foundation-prod` (build-from-git, 0 erreurs)
4. GitOps PROD : manifest mis à jour, commit `42cd390`, push, rollout
5. Digest : `sha256:b6c33e7754673c874b9a0eb10e3377fb30334dc8e83e3236c391b918bfd8a148`
6. Validation navigateur PROD : TenantProvider, RequireTenant, createTenant, tenant selector
7. RBAC vérifié : super_admin tout, account_manager tenants assignés, media_buyer scope marketing
8. Non-régression : 19/19 pages OK, 8/8 routes API OK
9. Rollback documenté avec procédure GitOps complète

### Document généré

- `keybuzz-infra/docs/PH-ADMIN-TENANT-FOUNDATION-02-PROD-PROMOTION.md`

---

## PHASE 28 — PH-T8.7A — Marketing Tenant Attribution Foundation

**Date** : 22 avril 2026 — midi
**Agent** : SaaS API
**Environnement** : DEV
**Image** : `v3.5.97-marketing-tenant-foundation-dev`
**Commit** : `db14cb03`
**Digest** : `sha256:231bee30181eabe9fd84545160aa11a70c0cf3c3ec59c7857b3ed36d1c0a52a9`

### Prompt d'origine complet

```
Prompt CE — PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-01

Rôle : Cursor Executor (CE)
Projet : KeyBuzz SaaS / API
Phase : PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-01
Environnement : DEV uniquement
Type : fondation tenant-native du pipeline marketing server-side
Priorité : CRITIQUE

## OBJECTIF

Rendre le pipeline marketing server-side tenant-native de bout en bout afin de préparer proprement :

- l'usage multi-tenant des metrics marketing
- l'usage multi-tenant des destinations outbound
- les futurs connecteurs natifs par plateforme (Meta / TikTok / Google / LinkedIn)

Cette phase ne doit PAS encore implémenter les connecteurs plateforme natifs.
Elle doit d'abord verrouiller la source de vérité tenant marketing.

---

## CONTEXTE IMPOSÉ

Côté Admin V2, la fondation multi-tenant est déjà live :
- tenant selector global
- tenant creation
- pages tenant-scoped unifiées
- GET `/api/admin/tenants` role-aware
- `media_buyer` existe dans le modèle RBAC côté Admin

Références obligatoires :
- `PH-ADMIN-TENANT-FOUNDATION-01.md`
- `PH-ADMIN-TENANT-FOUNDATION-02-PROD-PROMOTION.md`

Le but côté SaaS est maintenant d'aligner la couche marketing avec cette réalité tenant-native,
sans ambiguïté sur : attribution, business events outbound, destinations, metrics.

---

## RÈGLES ABSOLUES

### ENVIRONNEMENT
- DEV ONLY
- AUCUN impact PROD
- STOP avant promotion

### BUILD / SOURCE OF TRUTH
- build-from-git obligatoire
- repo clean obligatoire
- branche obligatoire : `ph147.4/source-of-truth`
- AUCUNE autre branche
- commit + push AVANT build

### GITOPS
- manifests DEV uniquement
- aucun `kubectl set image`

### PÉRIMÈTRE
- ne pas modifier Admin V2
- ne pas casser Stripe, billing, trial vs paid, metrics, outbound destinations, exclusion test
- ne pas créer de connecteur natif dans cette phase

---

## DOCUMENTS À LIRE OBLIGATOIREMENT

- `PH-T8.2E-PROD-PROMOTION-METRICS-01.md`
- `PH-T8.2F-TEST-ACCOUNT-CONTROL-01.md`
- `PH-T8.4-OUTBOUND-CONVERSIONS-WEBHOOK-01-REPORT.md`
- `PH-T8.4.1-STRIPE-REAL-VALUE-PROD-PROMOTION-01.md`
- `PH-T8.5-AGENCY-INTEGRATION-DOC-01.md`
- `PH-T8.6A-OUTBOUND-DESTINATIONS-API-01.md`
- `PH-T8.6C-SAAS-PROD-PROMOTION-01.md`
- `PH-ADMIN-TENANT-FOUNDATION-01.md`
- `PH-ADMIN-TENANT-FOUNDATION-02-PROD-PROMOTION.md`

---

## ÉTAPES

0. PRÉFLIGHT
1. AUDIT COMPLET DU TENANT FLOW MARKETING
   - A. Attribution signup (tenant_id présent ?)
   - B. Events outbound (tenant_id injecté ?)
   - C. Metrics (/metrics/overview filtre par tenant ?)
   - D. Destinations outbound (cohérence tenant)
   → Créer : PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-AUDIT.md

2. DÉFINIR LA SOURCE DE VÉRITÉ TENANT MARKETING
   → une seule règle claire pour rattacher StartTrial, Purchase, metrics et destinations à un tenant

3. ALIGNER LES BUSINESS EVENTS AVEC LE TENANT
   → StartTrial et Purchase doivent porter un tenant marketing explicite, fiable, stable

4. ALIGNER /metrics/overview AVEC LE TENANT
   → permettre un mode réellement tenant-scoped côté backend
   → ajouter query param tenant_id si absent

5. TENANT SAFETY SUR DESTINATIONS
   → prouver qu'un event tenant A ne part jamais vers destination tenant B

6. PRÉPARER LE FRAMEWORK PLATFORM-NATIVE (SANS L'ACTIVER)
   → destination_type = webhook | meta_capi | tiktok_events | google_ads | linkedin_capi
   → schéma + types + enums uniquement

7. VALIDATION DEV RÉELLE

8. NON-RÉGRESSION

9. BUILD SAFE DEV : v3.5.97-marketing-tenant-foundation-dev

10. RAPPORT FINAL

VERDICT ATTENDU

MARKETING TENANT FOUNDATION READY — EVENTS + METRICS + DESTINATIONS ALIGNED — MULTI-TENANT SAFE — DEV ONLY

STOP
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

#### Alignement /metrics/overview (ÉTAPE 4)

**Fichier modifié** : `src/modules/metrics/routes.ts`

- Ajout query param optionnel `tenant_id`
- Filtre SQL conditionnel : `AND ($N::text IS NULL OR t.id = $N)`
- Champs ajoutés : `scope` ("global" | "tenant"), `tenant_id`
- Backward compatible

#### Framework platform-native (ÉTAPE 6)

**Fichier modifié** : `src/modules/outbound-conversions/routes.ts`

- Ajout `DESTINATION_TYPES` : `webhook`, `meta_capi`, `tiktok_events`, `google_ads`, `linkedin_capi`
- Colonnes DB ajoutées : `platform_account_id`, `platform_pixel_id`, `platform_token_ref`, `mapping_strategy`

### Documents générés

- `keybuzz-infra/docs/PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-AUDIT.md`
- `keybuzz-infra/docs/PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-01.md`

---

## Coordination inter-agents — Schéma

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


| Moment    | Problème                           | Agent source         | Agent correcteur | Résultat                     |
| --------- | ---------------------------------- | -------------------- | ---------------- | ---------------------------- |
| T8.3.1C   | Payload EUR changé, UI affiche NaN | SaaS (T8.2C)         | Admin V2         | Mapping spend_eur            |
| T8.3.1B   | API strict (null cac), UI crash    | SaaS (T8.2)          | Admin V2         | safeNum() helper             |
| T8.3.1E   | Port K8s PROD ≠ DEV                | Infra                | Admin V2         | Fix KEYBUZZ_API_INTERNAL_URL |
| T8.6B-FIX | Admin users pas dans user_tenants  | Admin V2 (identifié) | SaaS + Admin V2  | Bypass admin + headers proxy |


---

## Architecture technique finale

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
└──────────────────────┬───────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│               DESTINATIONS (per tenant)                           │
│  webhook | meta_capi | tiktok_events | google_ads | linkedin_capi│
│  endpoint_url + secret + HMAC + active/inactive                  │
└──────────────────────┬───────────────────────────────────────────┘
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

## Fichiers source clés


| Fichier                                                                         | Rôle                                        |
| ------------------------------------------------------------------------------- | ------------------------------------------- |
| `/opt/keybuzz/keybuzz-api/src/modules/metrics/routes.ts`                        | Endpoint /metrics/overview + import Meta    |
| `/opt/keybuzz/keybuzz-api/src/modules/outbound-conversions/emitter.ts`          | Émission conversions multi-destination      |
| `/opt/keybuzz/keybuzz-api/src/modules/outbound-conversions/routes.ts`           | API destinations self-service               |
| `/opt/keybuzz/keybuzz-api/src/modules/billing/routes.ts`                        | Webhooks Stripe → déclenchement conversions |
| `/opt/keybuzz/keybuzz-admin-v2/src/app/(admin)/metrics/page.tsx`                | Page metrics Admin V2                       |
| `/opt/keybuzz/keybuzz-admin-v2/src/app/(admin)/marketing/destinations/page.tsx` | Page destinations Admin V2                  |
| `/opt/keybuzz/keybuzz-admin-v2/src/contexts/TenantContext.tsx`                  | TenantProvider global Admin V2              |


---

## Tables DB marketing


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


---

## Index complet des documents

### Phases SaaS API (backend)


| Fichier                                                     | Phase       | Date   |
| ----------------------------------------------------------- | ----------- | ------ |
| `PH-T8.1-2-DATA-FOUNDATION-AND-METRICS-01.md`               | T8.1-2      | 20 avr |
| `PH-T8.2-REAL-SPEND-TRUTH-01.md`                            | T8.2        | 20 avr |
| `PH-T8.2B-META-REAL-SPEND-01-REPORT.md`                     | T8.2B       | 20 avr |
| `PH-T8.2C-CURRENCY-NORMALIZATION-01.md`                     | T8.2C       | 20 avr |
| `PH-T8.2D-TRIAL-VS-PAID-METRICS-01.md`                      | T8.2D       | 20 avr |
| `PH-T8.2E-PROD-PROMOTION-METRICS-01.md`                     | T8.2E       | 20 avr |
| `PH-T8.2Ebis-EXCLUDE-TEST-DATA-01.md`                       | T8.2Ebis    | 20 avr |
| `PH-T8.2F-TEST-ACCOUNT-CONTROL-01.md`                       | T8.2F       | 20 avr |
| `PH-T8.4-OUTBOUND-CONVERSIONS-WEBHOOK-01-REPORT.md`         | T8.4        | 21 avr |
| `PH-T8.4.1-STRIPE-REAL-VALUE-01.md`                         | T8.4.1      | 21 avr |
| `PH-T8.4.1-STRIPE-REAL-VALUE-PROD-PROMOTION-01.md`          | T8.4.1-PROD | 21 avr |
| `PH-T8.5-AGENCY-INTEGRATION-DOC-01.md`                      | T8.5        | 21 avr |
| `PH-T8.5.1-WEBHOOK-SITE-PROD-TEST-01.md`                    | T8.5.1      | 21 avr |
| `PH-T8.6A-OUTBOUND-DESTINATIONS-API-01.md`                  | T8.6A       | 21 avr |
| `PH-T8.6C-SAAS-PROD-PROMOTION-01.md`                        | T8.6C SaaS  | 22 avr |
| `PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-AUDIT.md` | T8.7A Audit | 22 avr |
| `PH-T8.7A-MARKETING-TENANT-ATTRIBUTION-FOUNDATION-01.md`    | T8.7A       | 22 avr |


### Phases Admin V2 (frontend)


| Fichier                                             | Phase        | Date   |
| --------------------------------------------------- | ------------ | ------ |
| `PH-T8.3.1-METRICS-UI-BASIC-AUDIT.md`               | T8.3.1 Audit | 20 avr |
| `PH-T8.3.1-METRICS-UI-BASIC-REPORT.md`              | T8.3.1       | 20 avr |
| `PH-T8.3.1B-METRICS-NO-DATA-UI-FIX-REPORT.md`       | T8.3.1B      | 20 avr |
| `PH-T8.3.1C-METRICS-CURRENCY-MAPPING-FIX-REPORT.md` | T8.3.1C      | 20 avr |
| `PH-T8.3.1-PROD-PROMOTION-02-REPORT.md`             | T8.3.1-PROD  | 20 avr |
| `PH-T8.3.1D-METRICS-TRIAL-PAID-ALIGNMENT-REPORT.md` | T8.3.1D      | 20 avr |
| `PH-T8.3.1D-PROD-PROMOTION-REPORT.md`               | T8.3.1D-PROD | 20 avr |
| `PH-T8.3.1E-ADMIN-INTERNAL-API-FIX-REPORT.md`       | T8.3.1E      | 20 avr |
| `PH-T8.6B-MEDIA-BUYER-ADMIN-UI-01.md`               | T8.6B        | 21 avr |
| `PH-T8.6B-MARKETING-PROXY-FIX-02.md`                | T8.6B-FIX    | 21 avr |
| `PH-T8.6C-ADMIN-PROD-PROMOTION-02.md`               | T8.6C Admin  | 22 avr |


### Fondation multi-tenant + Knowledge transfer


| Fichier                                               | Phase                  | Date           |
| ----------------------------------------------------- | ---------------------- | -------------- |
| `PH-ADMIN-TENANT-FOUNDATION-01.md`                    | Tenant-01              | 4 mar / 22 avr |
| `PH-ADMIN-TENANT-FOUNDATION-02-PROD-PROMOTION.md`     | Tenant-02              | 22 avr         |
| `KNOWLEDGE-TRANSFER-SERVER-SIDE-TRACKING-COMPLETE.md` | Synthèse SaaS          | 22 avr         |
| `KNOWLEDGE-TRANSFER-SERVER-SIDE-TRACKING-ADMIN-V2.md` | Synthèse Admin V2      | 22 avr         |
| `KNOWLEDGE-TRANSFER-SERVER-SIDE-TRACKING-UNIFIED.md`  | **CE DOCUMENT** Unifié | 22 avr         |


---

## État final au 22 avril 2026


| Composant | DEV                                       | PROD                                     |
| --------- | ----------------------------------------- | ---------------------------------------- |
| API SaaS  | `v3.5.97-marketing-tenant-foundation-dev` | `v3.5.95-outbound-destinations-api-prod` |
| Admin V2  | `v2.11.0-tenant-foundation-dev`           | `v2.11.0-tenant-foundation-prod`         |


### Opérationnel en PROD

- Endpoint `GET /metrics/overview` : CAC, ROAS, MRR, trial/paid, test exclusion, EUR normalized
- Import Meta spend : `POST /metrics/import/meta`
- Outbound conversions : StartTrial + Purchase, HMAC, idempotence, retry
- Valeur réelle Stripe
- Destinations self-service : CRUD, test, logs, multi-destination
- Exclusion test : `tenant_billing_exempt` explicite
- RBAC : owner/admin pour destinations, media_buyer pour lecture
- Admin V2 UI : `/metrics`, `/marketing/destinations`, `/marketing/delivery-logs`, `/marketing/integration-guide`
- Multi-tenant Admin : TenantProvider global, selector topbar, RequireTenant, création tenant

### En DEV uniquement (pas encore promu en PROD)

- Metrics tenant-scoped : `GET /metrics/overview?tenant_id=xxx`
- Framework platform-native : types + colonnes DB pour meta_capi, tiktok_events, google_ads, linkedin_capi

### Prochaines phases prévues

1. **PH-T8.7A-PROD** : promotion PROD metrics tenant-scoped + framework platform-native
2. **Connecteurs natifs Meta CAPI** : envoi direct à Meta sans webhook intermédiaire
3. **Connecteurs natifs TikTok Events API** : idem TikTok
4. **Connecteurs natifs Google Ads Enhanced Conversions** : idem Google
5. **Connecteurs natifs LinkedIn CAPI** : idem LinkedIn
6. **Ad spend par tenant** : ajouter `tenant_id` à `ad_spend` pour CAC par tenant
7. **Synchronisation Admin V2 metrics tenant** : passer `tenantId` via proxy vers /metrics/overview

