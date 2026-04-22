# PH-T8.8-BUSINESS-EVENTS-INBOUND-SOURCES-ARCHITECTURE-01

> **Chemin complet** : `C:\DEV\KeyBuzz\V3\keybuzz-infra\docs\PH-T8.8-BUSINESS-EVENTS-INBOUND-SOURCES-ARCHITECTURE-01.md`
> **Date** : 2026-04-22
> **Type** : Audit architecture — Business Events Inbound tenant-native
> **Environnement** : DEV + PROD (lecture seule)
> **Aucune modification** effectuée

---

## 0. PRÉFLIGHT

| Repo | Branche | HEAD | Clean |
|------|---------|------|-------|
| keybuzz-api | `ph147.4/source-of-truth` | `df4a2c5e` | OUI |
| keybuzz-infra | `main` | `257b0b5` | OUI |

### Images déployées

| Service | DEV | PROD |
|---------|-----|------|
| API | `v3.5.101-outbound-destinations-delete-route-dev` | `v3.5.101-outbound-destinations-delete-route-prod` |
| Admin V2 | `v2.11.2-meta-capi-ui-hardening-dev` | `v2.11.2-meta-capi-ui-hardening-prod` |

DEV et PROD sont alignés sur le même codebase API (v3.5.101).

---

## 1. HYGIÈNE OUTBOUND DESTINATIONS

### DEV — Destinations actives (non soft-deleted)

**Aucune destination active en DEV.** Toutes les destinations ont été soft-deleted lors des validations des phases PH-T8.7B.4 et PH-ADMIN-T8.7C.

| Total destinations | Actives | Soft-deleted |
|--------------------|---------|--------------|
| 6 | 0 | 6 |

### PROD — Destinations non soft-deleted

3 destinations existent en PROD sans `deleted_at`, mais TOUTES sont `is_active = false` :

| ID (abrégé) | Tenant | Nom | Type | is_active | deleted_at | Risque |
|-------------|--------|-----|------|-----------|------------|--------|
| `7464753d` | ecomlg-001 | prod-sanitization-test | meta_capi | **false** | NULL | Résidu test PH-T8.7B.3 |
| `28cbc2be` | ecomlg-001 | PROD-Validation-Meta-CAPI | meta_capi | **false** | NULL | Résidu test PH-T8.7B.1 |
| `291a5797` | ecomlg-001 | PROD-Validation-Meta-CAPI | meta_capi | **false** | NULL | Résidu test PH-T8.7B.1 |

**Verdict hygiène** :
- Aucune destination test **active** restante (DEV ni PROD)
- 3 destinations PROD sont `is_active=false` sans `deleted_at` — résidus de tests, inoffensives mais impropres
- Les tokens sont masqués, aucun ne peut émettre (inactive)
- Aucune destination DEV avec vrais credentials Meta actifs
- **KeyBuzz Consulting** (PROD `keybuzz-consulting-mo9zndlk`) : 2 destinations, toutes soft-deleted — prêt pour une future destination réelle
- Aucun flux actif involontaire

**Recommandation** : les 3 destinations PROD `is_active=false` sans `deleted_at` devraient être soft-deleted via Admin V2 pour propreté. **Aucune action prise** — validation Ludovic requise.

### Delivery Logs et Conversion Events

| Env | delivery_logs | conversion_events |
|-----|---------------|-------------------|
| DEV | 3 | 0 |
| PROD | 3 | 0 |

Les logs sont des résidus de tests (endpoints test). Aucune conversion réelle encore émise via le pipeline outbound.

---

## 2. VÉRITÉ INBOUND ACTUELLE

### 2.1 Réponses noir sur blanc

| # | Question | Réponse | Preuve |
|---|----------|---------|--------|
| 1 | Le spend Meta actuel est-il global ou tenant-scoped ? | **GLOBAL** | Table `ad_spend` n'a PAS de colonne `tenant_id`. Requête SQL : `SELECT FROM ad_spend` sans filtre tenant. |
| 2 | Les credentials Meta Ads pour le spend sont-ils KeyBuzz-only ? | **OUI — KeyBuzz-only** | `META_AD_ACCOUNT_ID=1485150039295668` (= act KeyBuzz Consulting LLP). Token = User Access Token scope `ads_read`. Présent en DEV **et PROD** via env vars deployment. |
| 3 | Un tenant peut-il voir des KPIs basés sur les spend KeyBuzz ? | **OUI — via `/metrics/overview`** | L'endpoint retourne le spend global même avec `?tenant_id=X`. Le filtre `tenant_id` s'applique aux customers/revenue mais PAS au spend. Un tenant verrait donc le CAC/ROAS calculé avec le spend KeyBuzz. |
| 4 | `/metrics/overview?tenant_id` isole-t-il tout ? | **NON** | Customers, revenue, conversion rate : filtré par `tenant_id`. **Spend, CAC, ROAS** : PAS filtré (global). |
| 5 | Existe-t-il un endpoint inbound events tenant-native ? | **NON** | Aucun endpoint `POST /events` ou `/inbound/events` n'existe. Pas de table `business_events_inbound`. |
| 6 | Existe-t-il un pixel/snippet KeyBuzz tenant-native ? | **NON** | Aucun script pixel, aucun composant Snippet, aucune table pixel_config. Le tracking est côté website (GA4 + Meta Pixel), pas côté SaaS. |
| 7 | Addingwell est-il codé comme dépendance ? | **NON — seulement mentionné dans la doc** | Aucun import, aucune référence code, aucune env var Addingwell. Addingwell est prévu comme option dans `PH-TRACKING-SAAS-ARCHITECTURE-AND-PLAN-01.md` mais pas implémenté. |

### 2.2 Tableau des composants

| Composant | Global | Tenant-scoped | Risque | Preuve |
|-----------|--------|---------------|--------|--------|
| `signup_attribution` | — | **OUI** (tenant_id FK) | Aucun | Schema vérifié, chaque row a un `tenant_id` |
| `ad_spend` | **OUI** | NON (pas de `tenant_id`) | **CRITIQUE** | Schema : `id, date, channel, spend, impressions, clicks, created_at` — aucun tenant_id |
| `conversion_events` | — | **OUI** (tenant_id) | Aucun | Idempotence key = `conv_${tenantId}_...` |
| `outbound_conversion_destinations` | — | **OUI** (tenant_id) | Aucun | Toutes les requêtes filtrent par `tenant_id` |
| `outbound_conversion_delivery_logs` | — | **OUI** (via FK destination) | Aucun | Logs liés à une destination tenant-scoped |
| `tracking_events` | — | **OUI** (tenant_id) | Aucun | 32K events, scope order tracking (colis), PAS marketing |
| `/metrics/overview` | **PARTIEL** | Customers/Revenue oui, **Spend NON** | **CRITIQUE** | Requête ad_spend sans filtre tenant_id |
| `/metrics/import/meta` | **GLOBAL** | NON | **CRITIQUE** | `INSERT INTO ad_spend (date, channel, spend...)` — pas de tenant_id |
| Meta Marketing API credentials | **GLOBAL** | NON | **CRITIQUE** | `META_AD_ACCOUNT_ID` = KeyBuzz Consulting ad account, env var partagée |
| Pixel/Snippet client | N/A | N/A | N/A | Inexistant côté SaaS |
| Addingwell | N/A | N/A | N/A | Non implémenté, mentionné comme option |

### 2.3 Résumé des risques

**RISQUE CRITIQUE** : Le pipeline `ad_spend` → `/metrics/overview` → `CAC/ROAS` est **100% global**. Si KeyBuzz est ouvert en multi-tenant, les credentials Meta (ad account KeyBuzz Consulting) et les données spend seraient exposées à tous les tenants via l'endpoint metrics.

**Note** : `tracking_events` (32 316 rows, tenant `ecomlg-001`) est une table de tracking **colis/livraison** (carrier UPS, 17track), PAS de tracking marketing. Nom trompeur mais sans impact.

---

## 3. ARCHITECTURE CIBLE INBOUND SOURCES

### 3.1 Table `business_event_sources`

```sql
CREATE TABLE business_event_sources (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id),
  source_type TEXT NOT NULL,
  -- Types: keybuzz_pixel, server_events_api, addingwell_webhook,
  --        meta_ads_read, google_ads_read, tiktok_ads_read, linkedin_ads_read
  name TEXT NOT NULL,
  domain TEXT,
  public_key TEXT,
  secret_ref TEXT,
  token_ref TEXT,
  platform_account_id TEXT,
  platform_pixel_id TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  -- Status: pending, active, error, disabled
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_event_at TIMESTAMPTZ,
  last_error TEXT,
  created_by TEXT NOT NULL,
  updated_by TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_bes_tenant ON business_event_sources(tenant_id);
CREATE INDEX idx_bes_type ON business_event_sources(source_type);
CREATE INDEX idx_bes_active ON business_event_sources(tenant_id, is_active) WHERE deleted_at IS NULL;
```

### 3.2 Table `business_events_inbound`

```sql
CREATE TABLE business_events_inbound (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  source_id UUID NOT NULL REFERENCES business_event_sources(id),
  event_name TEXT NOT NULL,
  event_id TEXT NOT NULL,
  event_time TIMESTAMPTZ NOT NULL,
  url TEXT,
  referrer TEXT,
  session_id TEXT,
  visitor_id TEXT,
  email_hash TEXT,
  phone_hash TEXT,
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  utm_term TEXT,
  utm_content TEXT,
  fbclid TEXT,
  fbc TEXT,
  fbp TEXT,
  gclid TEXT,
  gbraid TEXT,
  wbraid TEXT,
  ttclid TEXT,
  li_fat_id TEXT,
  value_amount NUMERIC(12,2),
  value_currency TEXT DEFAULT 'EUR',
  raw_payload_json JSONB,
  normalized_payload_json JSONB,
  consent_state TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_bei_dedup ON business_events_inbound(tenant_id, event_id);
CREATE INDEX idx_bei_tenant_time ON business_events_inbound(tenant_id, event_time DESC);
CREATE INDEX idx_bei_source ON business_events_inbound(source_id);
CREATE INDEX idx_bei_event_name ON business_events_inbound(tenant_id, event_name);
```

### 3.3 Table `ad_platform_accounts`

```sql
CREATE TABLE ad_platform_accounts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES tenants(id),
  platform TEXT NOT NULL,
  -- Platforms: meta, google, tiktok, linkedin
  account_id TEXT NOT NULL,
  account_name TEXT,
  currency TEXT NOT NULL DEFAULT 'EUR',
  timezone TEXT DEFAULT 'Europe/Paris',
  token_ref TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  last_sync_at TIMESTAMPTZ,
  last_error TEXT,
  created_by TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX idx_apa_tenant_platform_account
  ON ad_platform_accounts(tenant_id, platform, account_id) WHERE deleted_at IS NULL;
```

### 3.4 Table `ad_spend_tenant` (remplacement de `ad_spend`)

```sql
CREATE TABLE ad_spend_tenant (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  account_id UUID NOT NULL REFERENCES ad_platform_accounts(id),
  platform TEXT NOT NULL,
  campaign_id TEXT,
  campaign_name TEXT,
  adset_id TEXT,
  adset_name TEXT,
  date DATE NOT NULL,
  spend NUMERIC(12,4) NOT NULL,
  spend_currency TEXT NOT NULL,
  impressions INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  conversions INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_ast_dedup
  ON ad_spend_tenant(tenant_id, platform, campaign_id, date);
CREATE INDEX idx_ast_tenant_date ON ad_spend_tenant(tenant_id, date DESC);
CREATE INDEX idx_ast_account ON ad_spend_tenant(account_id);
```

### 3.5 Endpoints proposés

#### Inbound Sources Registry

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/business-sources` | Liste des sources du tenant |
| POST | `/business-sources` | Créer une source inbound |
| PATCH | `/business-sources/:id` | Modifier une source |
| DELETE | `/business-sources/:id` | Soft delete une source |
| POST | `/business-sources/:id/test` | Tester la connexion |

#### Business Events Collector

| Method | Route | Description |
|--------|-------|-------------|
| POST | `/business-events/collect` | Recevoir un event (pixel/API/webhook) |
| GET | `/business-events` | Liste des events (filtré par tenant) |
| GET | `/business-events/stats` | Stats events agrégées |

#### Ad Spend Tenant-Scoped

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/ad-accounts` | Liste des comptes ads du tenant |
| POST | `/ad-accounts` | Connecter un compte ads |
| DELETE | `/ad-accounts/:id` | Soft delete un compte |
| POST | `/ad-accounts/:id/sync` | Sync manuelle du spend |
| GET | `/ad-spend` | Spend tenant-scoped (remplacement metrics.ad_spend) |

#### Pixel / Snippet

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/business-sources/pixel/snippet` | Générer le snippet JS pour un tenant |

---

## 4. DÉDUPLICATION ET SOURCE OF TRUTH

### 4.1 Règles anti-doublon

1. **event_id canonical** : chaque business event a un `event_id` unique. L'index `UNIQUE(tenant_id, event_id)` garantit le dédoublonnage.

2. **Pixel + CAPI coexistence** : un event browser (Pixel) et un event server (CAPI) peuvent coexister UNIQUEMENT si ils partagent le même `event_id`. Meta utilise ce champ pour la déduplication native.

3. **Addingwell + KeyBuzz CAPI** : si un tenant utilise Addingwell ET KeyBuzz CAPI, ils NE doivent PAS envoyer le même event avec deux event_id différents. Règle : un seul "owner" par event_name par tenant.

4. **Source owner** : la table `business_event_sources` définit quelle source est autorisée pour quel event via un champ de configuration.

5. **Events de test** : isolés par un flag `is_test` ou un tenant_id de test. Les events de test NE sont JAMAIS comptés dans les métriques réelles.

### 4.2 Matrice déduplication

| Event | Source owner recommandée | Peut passer par Addingwell ? | Peut passer par KeyBuzz CAPI ? | Dédup requise |
|-------|--------------------------|------------------------------|--------------------------------|---------------|
| PageView | Pixel (browser) | OUI (server-side proxy) | NON (redondant) | event_id |
| ViewContent | Pixel (browser) | OUI | NON | event_id |
| Lead | Pixel (browser) | OUI | NON | event_id |
| InitiateCheckout | Pixel (browser) | OUI | NON | event_id |
| CompleteRegistration | **KeyBuzz CAPI** (server) | OUI (si configuré) | OUI | event_id |
| StartTrial | **KeyBuzz CAPI** (server) | NON (pas de pixel) | OUI (owner) | event_id |
| Purchase | **KeyBuzz CAPI** (server) | NON (pas de pixel) | OUI (owner) | event_id |

### 4.3 Stratégie source par event

```
Browser events (navigation) → Pixel owner + Addingwell relay optionnel
Server events (conversion)  → KeyBuzz CAPI owner exclusif
                              Addingwell ne doit PAS relayer les events server
```

**Règle d'or** : un event a **un seul owner**. Si Addingwell est configuré comme relay pour les events browser, KeyBuzz CAPI ne doit PAS envoyer les mêmes events browser. Si KeyBuzz CAPI est owner des events conversion, Addingwell ne doit PAS envoyer ces events.

---

## 5. SCOPE SAAS VS ADMIN

### CE SaaS / API

| Domaine | Détail |
|---------|--------|
| DB schema `business_event_sources` | Création table + migrations |
| DB schema `business_events_inbound` | Création table + migrations |
| DB schema `ad_platform_accounts` | Création table + migrations |
| DB schema `ad_spend_tenant` | Remplacement progressif de `ad_spend` |
| Endpoints CRUD sources | GET/POST/PATCH/DELETE `/business-sources` |
| Endpoint collect events | POST `/business-events/collect` |
| Normalization pipeline | Normalisation des payloads bruts |
| Déduplication | Index UNIQUE + vérification event_id |
| Metrics tenant-scoped spend | Refactoring `/metrics/overview` pour lire `ad_spend_tenant` |
| Secrets/token safety | Tokens jamais exposés, masquage systématique |
| Pixel snippet generator | Endpoint `/business-sources/pixel/snippet` |

### CE Admin V2

| Domaine | Détail |
|---------|--------|
| UI Sources inbound | Page de gestion des sources par tenant |
| UI Destinations outbound | Existante (PH-T8.7C) |
| Snippet pixel tenant | Affichage + copie du snippet JS |
| Formulaire Addingwell webhook | Config URL webhook Addingwell |
| Formulaire Ads account credentials | Connexion Meta/Google/TikTok/LinkedIn |
| Validation navigateur | Test de la source depuis l'Admin |
| Dashboard spend tenant | Visualisation du spend par tenant |

### Tableau phases futures

| Phase future | Agent | Scope | Risque |
|--------------|-------|-------|--------|
| PH-T8.8A — Inbound Sources Registry API | CE SaaS | DB + API CRUD sources | Faible (additif) |
| PH-T8.8B — Business Events Collector API | CE SaaS | API collect + normalization + dedup | Modéré (nouveau pipeline) |
| PH-T8.8C — KeyBuzz Pixel / Snippet tenant | CE SaaS + CE Admin | API snippet + UI snippet | Faible (additif) |
| PH-T8.8D — Ad Spend Connectors tenant-scoped | CE SaaS + CE Admin | DB + API + Meta/Google connectors | **Élevé** (credentials multi-tenant, refactoring metrics) |
| PH-ADMIN-T8.8E — Admin Sources UI | CE Admin | UI gestion sources | Faible (consomme API) |
| PH-T8.8F — KeyBuzz Consulting pilot real data | CE SaaS | Premier tenant avec sources réelles | Modéré (premier test réel) |
| PH-T8.8G — Documentation Integration Guide | CE SaaS | Doc technique pour les tenants | Aucun |

---

## 6. PLAN RECOMMANDÉ

### PH-T8.8A — Inbound Sources Registry API

| Élément | Détail |
|---------|--------|
| **Objectif** | Créer le registre des sources inbound tenant-native |
| **Agent** | CE SaaS |
| **Env** | DEV d'abord, PROD ensuite |
| **Contenu** | Table `business_event_sources`, endpoints CRUD, soft delete, RBAC |
| **Validations** | CRUD complet, tenant isolation, soft delete, tokens masqués |
| **Rollback** | DROP TABLE + revert code |
| **Dettes à éviter** | Pas de hardcodage source_type, pas de global scope |

### PH-T8.8B — Business Events Collector API

| Élément | Détail |
|---------|--------|
| **Objectif** | Endpoint de collecte d'events inbound avec normalisation et dédup |
| **Agent** | CE SaaS |
| **Env** | DEV d'abord, PROD ensuite |
| **Contenu** | Table `business_events_inbound`, endpoint POST `/business-events/collect`, normalisation UTM/click IDs, dédup event_id, validation source_id |
| **Validations** | Dédup prouvée, tenant isolation, payload normalisé, consent_state |
| **Rollback** | DROP TABLE + revert code |
| **Dettes à éviter** | Pas de collect sans source_id validée, pas de bypass dédup |

### PH-T8.8C — KeyBuzz Pixel / Snippet tenant

| Élément | Détail |
|---------|--------|
| **Objectif** | Générer un snippet JS tenant-natif qui envoie les events au collector |
| **Agent** | CE SaaS (API snippet) + CE Admin (UI copie/affichage) |
| **Env** | DEV d'abord, PROD ensuite |
| **Contenu** | Endpoint `/business-sources/pixel/snippet`, script JS minimal (< 2KB), event_id auto-généré, consent-aware |
| **Validations** | Snippet fonctionnel sur page test, events reçus dans business_events_inbound, tenant isolé |
| **Rollback** | Suppression source pixel, snippet inactif |
| **Dettes à éviter** | Pas de dépendance à un CDN externe, pas de cookie tiers |

### PH-T8.8D — Ad Spend Connectors tenant-scoped

| Élément | Détail |
|---------|--------|
| **Objectif** | Chaque tenant connecte SES comptes Meta/Google/TikTok pour SON spend |
| **Agent** | CE SaaS (API + connectors) + CE Admin (UI connexion) |
| **Env** | DEV d'abord, PROD ensuite |
| **Contenu** | Tables `ad_platform_accounts` + `ad_spend_tenant`, connecteurs Meta Marketing API / Google Ads API / TikTok Marketing API tenant-scoped, refactoring `/metrics/overview` pour lire `ad_spend_tenant` au lieu de `ad_spend` |
| **Validations** | Spend isolé par tenant, credentials tenant-scoped, CAC/ROAS tenant-scoped, aucune fuite cross-tenant du spend |
| **Rollback** | Fallback sur `ad_spend` global si `ad_spend_tenant` vide |
| **Dettes à éviter** | **Critique** : ne PAS laisser l'ancien `ad_spend` global accessible sans migration. Supprimer ou archiver après migration complète. Ne PAS exposer les credentials Meta globales KeyBuzz aux tenants. |

### PH-ADMIN-T8.8E — Admin Sources UI

| Élément | Détail |
|---------|--------|
| **Objectif** | Interface Admin V2 pour gérer les sources inbound par tenant |
| **Agent** | CE Admin |
| **Env** | DEV d'abord, PROD ensuite |
| **Contenu** | Page Sources (liste, détail, créer, soft-delete), formulaires par type (pixel, Addingwell, Meta Ads, etc.), affichage snippet pixel, indicateurs last_event_at / last_error |
| **Validations** | CRUD via UI, tenant-scoped, tokens masqués dans l'UI, snippet copiable |
| **Rollback** | Revert frontend, API inchangée |
| **Dettes à éviter** | Pas de logic métier dans le frontend, consommer l'API SaaS uniquement |

### PH-T8.8F — KeyBuzz Consulting pilot real data

| Élément | Détail |
|---------|--------|
| **Objectif** | Premier tenant (KeyBuzz Consulting) avec sources réelles et spend réel |
| **Agent** | CE SaaS |
| **Env** | PROD |
| **Contenu** | Création source Meta CAPI réelle pour KeyBuzz Consulting, connexion ad account Meta réel, import spend réel, validation métriques end-to-end |
| **Validations** | Events réels émis et reçus, spend réel importé, CAC/ROAS calculé avec données tenant, aucune fuite vers d'autres tenants |
| **Rollback** | Désactiver sources, fallback metrics global |
| **Dettes à éviter** | Ne pas utiliser les credentials globales KeyBuzz, créer des credentials dédiées au tenant |

### PH-T8.8G — Tenant documentation / Integration Guide

| Élément | Détail |
|---------|--------|
| **Objectif** | Documentation pour les tenants : comment connecter leurs sources |
| **Agent** | CE SaaS |
| **Env** | N/A (document) |
| **Contenu** | Guide : installer le pixel, configurer Addingwell, connecter Meta Ads, interpréter les métriques |
| **Validations** | Document relu et testé par un utilisateur non-technique |
| **Rollback** | N/A |
| **Dettes à éviter** | Ne pas exposer d'exemples avec des vrais tokens |

### Séquence recommandée

```
PH-T8.8A (Sources Registry)
    ├──→ PH-T8.8B (Events Collector)
    │       └──→ PH-T8.8C (Pixel/Snippet)
    ├──→ PH-T8.8D (Ad Spend Connectors)
    └──→ PH-ADMIN-T8.8E (Admin Sources UI)

PH-T8.8F (Pilot) nécessite A + B + D + E
PH-T8.8G (Documentation) en parallèle dès PH-T8.8A
```

---

## 7. MIGRATION AD_SPEND GLOBAL → TENANT-SCOPED

### État actuel `ad_spend`

```
Schema : id (int), date, channel, spend (numeric), impressions, clicks, created_at
Données : 16 rows, canal 'meta', total 445.20 GBP
Pas de tenant_id
Credentials : META_AD_ACCOUNT_ID=act_148..., META_ACCESS_TOKEN=EAA... (KeyBuzz Consulting)
Disponible en DEV ET PROD
```

### Plan de migration

1. **PH-T8.8D** crée `ad_spend_tenant` et `ad_platform_accounts`
2. Les données actuelles de `ad_spend` (16 rows meta) sont migrées vers `ad_spend_tenant` avec `tenant_id = 'keybuzz-consulting-mo9zndlk'` (PROD) / `'keybuzz-consulting-mo9y479d'` (DEV)
3. `/metrics/overview` est refactoré pour lire `ad_spend_tenant` d'abord, fallback `ad_spend` si vide
4. `/metrics/import/meta` est remplacé par `/ad-accounts/:id/sync` tenant-scoped
5. Les env vars globales `META_AD_ACCOUNT_ID` / `META_ACCESS_TOKEN` sont supprimées une fois le tenant KeyBuzz Consulting migré vers `ad_platform_accounts`
6. `ad_spend` est archivée puis supprimée

---

## 8. RISQUES DE DOUBLON ADDINGWELL / PIXEL / KEYBUZZ CAPI

### Scénario actuel (pas de risque)

Aucun doublon possible aujourd'hui :
- Pas de pixel SaaS
- Pas d'Addingwell configuré
- KeyBuzz CAPI outbound envoie StartTrial/Purchase uniquement

### Scénarios futurs à risque

| Scénario | Risque | Mitigation |
|----------|--------|------------|
| Tenant installe pixel + active KeyBuzz CAPI sur Purchase | **Doublon Purchase** si les deux envoient | event_id unique partagé entre pixel et CAPI |
| Tenant configure Addingwell + KeyBuzz CAPI sur le même event | **Doublon** si les deux envoient le même event avec des event_id différents | Source owner unique par event_name par tenant |
| Addingwell relaye les events pixel ET KeyBuzz envoie les mêmes en CAPI | **Doublon** | Addingwell configuré en mode "relay pixel only", KeyBuzz CAPI en mode "server events only" |
| Migration de l'ancien `ad_spend` global non complétée | **Spend global pollue les métriques tenant** | Fallback avec warning, pas de merge silencieux |

### Recommandation anti-doublon

La configuration de chaque source dans `business_event_sources` doit inclure un champ `allowed_events` (array de noms d'events). Le collector refuse un event si la source n'est pas autorisée pour cet event_name. Cela empêche structurellement les doublons multi-sources.

---

## 9. AUCUNE MODIFICATION EFFECTUÉE

| Action | Effectuée ? |
|--------|-------------|
| Modification code | NON |
| Modification DB | NON |
| Build | NON |
| Deploy | NON |
| kubectl set image/env/edit/patch | NON |
| Suppression de destination | NON |
| Exposition de token complet | NON |

---

## VERDICT FINAL

```
BUSINESS EVENTS INBOUND SOURCES ARCHITECTURE ESTABLISHED
— TENANT-NATIVE MODEL READY
— NO DUPLICATE TRACKING STRATEGY DEFINED
```

### Résumé des découvertes critiques

1. **`ad_spend` est GLOBAL** — pas de `tenant_id`, credentials Meta KeyBuzz partagées en env vars DEV et PROD
2. **`/metrics/overview` expose le spend global** même avec `?tenant_id=X` — fuite potentielle en multi-tenant
3. **3 destinations PROD** sont `is_active=false` sans `deleted_at` — résidus de tests, inoffensives mais à nettoyer
4. **Aucun pipeline inbound** n'existe — pas de pixel, pas de collector, pas d'Addingwell
5. **L'outbound fonctionne** — destinations, emitter, delivery logs, soft delete, token sanitization sont tenant-native

### Architecture cible définie

- 4 nouvelles tables : `business_event_sources`, `business_events_inbound`, `ad_platform_accounts`, `ad_spend_tenant`
- 7 phases (A→G) avec séquence et dépendances
- Déduplication par `event_id` unique + source owner par event_name
- Migration progressive `ad_spend` global → `ad_spend_tenant`
- Séparation claire CE SaaS / CE Admin
