# PH-SHOPIFY-01 — Audit d'Architecture et Plan d'Insertion Shopify

> **Date** : 1er mars 2026
> **Type** : Audit + Plan (AUCUNE implémentation)
> **Environnement** : Lecture seule — aucun build, aucun déploiement

---

## Étape 0 — Preflight de Vérité

### Versions actuellement déployées

| Service | DEV | PROD |
|---------|-----|------|
| **API** | `v3.5.48-ph143-agents-fix-dev` | `v3.5.224-ph143-agents-ia-prod` |
| **Outbound Worker** | `v3.5.165-escalation-flow-dev` | `v3.5.165-escalation-flow-prod` |
| **Client** | `v3.5.224-ph143-agents-otp-session-fix-dev` | `v3.5.224-ph143-agents-ia-prod` |
| **Backend** | `v1.0.42-ph-oauth-persist-dev` | `v1.0.42-ph-oauth-persist-prod` |
| **Amazon Workers** | `v1.0.40-amz-tracking-visibility-backfill-*` | Idem |
| **Backfill Scheduler** | `v1.0.42-td02-worker-resilience-*` | Idem |

### État des pods

- Tous pods Running, 0 restarts, CronJobs fonctionnels (outbound-tick, sla-evaluator)
- Aucun CrashLoopBackOff détecté

### Anomalie constatée

**API DEV est sur `v3.5.48` alors que PROD est sur `v3.5.224`.**
Cela signifie que le deployment API DEV pointe vers une image beaucoup plus ancienne que PROD. Le client DEV est sur v3.5.224 (aligné PROD). Le backend est aligné.

### Branche/release line

- Release line validée : `release/client-v3.5.220` (source de la dernière promotion PROD)
- Dernière phase PROD : PH143-P2-PROD-PROMOTION-AGENTS-IA-01

### Rollback disponible

- Client PROD : `v3.5.220-ph143-clean-release-prod` (précédente)
- API PROD : `v3.5.211-ph143-final-prod` (précédente)

### Dernières consignes de stabilisation

- PH143-P2 rapport : « STOP — Aucune nouvelle feature. Attendre validation de Ludovic. »
- GitOps strict, build-from-git uniquement, zéro `kubectl set image`

### Réponses obligatoires Étape 0

| Question | Réponse |
|----------|---------|
| DEV actuellement sain | **OUI** — tous pods Running, 0 restarts |
| PROD actuellement saine | **OUI** — tous pods Running, 0 restarts |
| Alignement DEV/PROD confirmé | **PARTIEL** — Client et Backend alignés. **API DEV divergente** (v3.5.48 vs v3.5.224 PROD) |
| Risque d'introduire Shopify maintenant | **FAIBLE** — phase audit uniquement, aucune modification de code |
| Recommandation | **CONTINUER** l'audit. Réaligner l'API DEV avant PH-SHOPIFY-02 |

---

## Étape 1 — Vérité Documentaire

### Sources consultées

| Document | Statut |
|----------|--------|
| `KeyBuzz v3 Architechture1.txt` | **Non trouvé** dans le workspace (référencé mais absent) |
| `KeyBuzz v3 Architechture2.txt` | **Non trouvé** dans le workspace (référencé mais absent) |
| `KeyBuzz SaaS.txt` | **Lu** — aucune mention de Shopify, patterns Amazon/Octopia documentés |
| `KeyBuzz_2026.txt` | **Lu** — **contient un bloc Shopify** (ll.47224–47474) avec recommandations produit |
| `RECAPITULATIF PHASES.md` | **Lu** — 695 lignes, 150+ phases documentées, aucune phase Shopify |
| `PROMPT-NOUVEL-AGENT.md` | **Lu** — règles CE, GitOps, multi-tenant, patches additifs |
| Contexte cursor rule `keybuzz-v3-context.mdc` | **Lu** — 45 sections, architecture complète |

### Vérité actuelle du SaaS

- 87 tables PostgreSQL, 0 table Shopify
- 2 canaux de conversation : `amazon` (415), `email` (8)
- 1 module marketplace implémenté : Octopia (8 fichiers)
- Catalogue channels : 19 entrées (16 Amazon, 1 Octopia, 1 Fnac coming_soon, 1 Darty coming_soon)
- Table `orders` : générique, 28 colonnes, actuellement 100% Amazon
- AI context (`shared-ai-context.ts`) : générique, utilise `orders.channel`

### Règles de non-régression pour Shopify

1. Ne JAMAIS modifier le comportement des canaux existants (Amazon, Octopia, email)
2. Ne JAMAIS casser l'injection de contexte IA existante
3. Ne JAMAIS modifier `orders` sans garantie de rétrocompatibilité
4. Ne JAMAIS introduire de dépendance Shopify dans le chemin critique inbox/conversation
5. Respecter l'isolation multi-tenant stricte
6. Respecter les limites de channels par plan (inclus + add-ons billing)
7. Ne JAMAIS hardcoder de shop/domain/token/tenant

### Points sensibles à ne pas recasser

- `shared-ai-context.ts` : source unique de vérité IA, consommée par Assist ET Autopilot
- `channelsService.ts` : `MARKETPLACE_CATALOG` et logique billing channels
- `orders/routes.ts` : import Amazon SP-API, sync state, Vault credentials
- `inbound/routes.ts` : pipeline email → conversation
- `tenant_channels` : registre canaux par tenant avec billing
- `oauth_states` : gestion états OAuth (Amazon LWA)

---

## Étape 2 — Cartographie Architecture Existante

### A. Backend / Data

| Brique | État actuel | Prêt pour Shopify ? |
|--------|-------------|---------------------|
| **Modèle `tenants`** | Complet, multi-tenant strict, plans tarifaires | **OUI** — aucune modification nécessaire |
| **Modèle `conversations`** | Générique, `channel` TEXT | **OUI** — ajouter `shopify` comme valeur channel |
| **Modèle `orders`** | Générique, 28 colonnes, `channel` TEXT | **PARTIEL** — manque `customer_id`, `refund_status`, `return_status` |
| **Modèle customers** | **N'EXISTE PAS** — `customer_name`/`customer_email` inline dans `orders` | **NON** — table dédiée nécessaire |
| **Logique channels/connectors** | `MARKETPLACE_CATALOG` dans `channelsService.ts`, `tenant_channels` table | **OUI** — ajouter Shopify au catalogue |
| **Logique tenant context** | `TenantProvider`, headers `X-Tenant-Id` | **OUI** — inchangé |
| **Logique credentials/secrets** | Vault + env vars (Amazon), Vault path `vaultPath` dans `marketplace_connections` | **OUI** — pattern réutilisable |
| **Logique webhooks/inbound** | POST `/inbound/email` pour email, webhook interne | **NON** — besoin d'un endpoint webhook Shopify dédié |
| **Matching conversation ↔ commande** | `conversations.order_ref` ↔ `orders.external_order_id` | **OUI** — même pattern pour Shopify |
| **Tracking / refunds / returns** | `orders.tracking_*`, `carrier_*`, `amazon_returns` | **PARTIEL** — tracking générique OK, refunds/returns Amazon-spécifique |

### B. Client / UI

| Brique | État actuel | Prêt pour Shopify ? |
|--------|-------------|---------------------|
| **Page Channels** | `app/channels/page.tsx`, catalogue + CRUD | **OUI** — ajouter entrée Shopify au catalogue |
| **Onboarding connecteurs** | Amazon OAuth + Octopia API key | **PARTIEL** — besoin d'un flow OAuth Shopify |
| **Orders cockpit** | `app/orders/page.tsx`, liste/détail | **OUI** — déjà générique |
| **Inbox détail conversation** | Panel latéral commande, contexte client | **OUI** — piloté par `channel` |
| **Settings/Integrations** | N'existe pas comme page dédiée | **N/A** — pas nécessaire en V1 |
| **Gardes agent/admin/owner** | RBAC via `currentTenantRole`, middleware | **OUI** — inchangé |

### C. IA / Moteur Produit

| Brique | État actuel | Prêt pour Shopify ? |
|--------|-------------|---------------------|
| **Injection contexte commande** | `loadEnrichedOrderContext()` depuis `orders` | **OUI** — si Shopify écrit dans `orders` |
| **Playbooks** | `ai_rules` table, moteur `playbook-engine.service.ts` | **OUI** — inchangé, utilisent `channel` |
| **Suggestions IA** | `ai-assist-routes.ts`, panel suggestions | **OUI** — enrichissement par contexte commande |
| **Autopilot** | `autopilot/engine.ts`, brouillons contextuels | **OUI** — consomme `shared-ai-context.ts` |
| **Journal IA** | `ai_action_log`, `ai_journal_events` | **OUI** — inchangé |
| **Policy Engine** | `tenant_ai_policies`, scénarios SAV | **OUI** — extensible par marketplace |
| **Marketplace Policy** (PH92) | `marketplacePolicyEngine.ts`, 5 profils | **À ÉTENDRE** — ajouter profil SHOPIFY |

### D. Infra / Sécurité

| Brique | État actuel | Impact Shopify |
|--------|-------------|----------------|
| **Vault** | DOWN depuis 7 jan 2026, secrets K8s cachés | **RISQUE** — stockage tokens Shopify via K8s secrets ou table chiffrée |
| **ESO** | Configuré mais Vault DOWN | Idem |
| **Manifests K8s** | Complets, GitOps | Aucun changement en PH-SHOPIFY-02 |
| **Workers/jobs** | Amazon workers, CronJobs | Shopify sync worker à créer ultérieurement |
| **Webhook ingress** | POST `/inbound/email` (email), Stripe webhooks | **Nouveau** endpoint webhook Shopify nécessaire |
| **Config multi-tenant** | `tenant_channels`, `tenant_settings` | **OUI** — pattern existant |

### Résumé Cartographie

- **Prêt** : tenant model, conversations, orders (structure), AI context injection, playbooks, autopilot, channels UI, RBAC
- **Partiel** : orders (manque refund/return colonnes), tracking (Amazon-spécifique), marketplace policy
- **Manquant** : table customers, endpoint webhook Shopify, OAuth Shopify flow, profil policy Shopify, tables connexion Shopify
- **Inchangé** : inbox, billing, onboarding, tenant context

---

## Étape 3 — Modèle Produit Shopify Cible

### A. Ce que Shopify est dans KeyBuzz

Shopify n'est **PAS** une inbox native. C'est une **source de vérité opérationnelle SAV** :

| Shopify est | Shopify n'est pas |
|-------------|-------------------|
| Source commandes | Clone de l'inbox Shopify |
| Source clients | Remplacement du support natif Shopify |
| Source fulfillments/tracking | Copie d'Amazon |
| Source refunds/returns | Connecteur conversationnel |
| Source webhooks temps réel | Pipeline SMTP |

**Positionnement** : KeyBuzz = copilote SAV omnicanal branché sur la vérité commande Shopify.

### B. Flux utilisateur cible

```
1. Aller dans Channels → cliquer « + Ajouter un canal »
2. Sélectionner « Shopify » dans le catalogue
3. Cliquer « Connecter Shopify »
4. OAuth Shopify → autorisation dans la boutique Shopify
5. Callback → boutique connectée automatiquement
6. Sync initiale des commandes récentes (30 jours)
7. Webhooks enregistrés pour mises à jour en temps réel
8. Canal visible dans la liste des Channels (actif)
9. Enrichissement immédiat des conversations existantes et futures
```

### C. Affichage cible dans une conversation liée Shopify

Dans le panel latéral d'une conversation liée à une commande Shopify :

- **Client Shopify** : nom, email, nombre de commandes, customer since
- **Numéro de commande** : #1234 (lien direct vers Shopify admin)
- **Statut paiement** : Paid / Partially refunded / Refunded
- **Statut fulfillment** : Fulfilled / Partially fulfilled / Unfulfilled
- **Tracking** : numéro + transporteur + URL + statut live
- **Retour ouvert** : oui/non + détails si existant
- **Remboursement** : montant, date, raison
- **Suggestions IA** :
  - Réponse informative avec contexte commande
  - Enquête transporteur si retard
  - Demande de photo/preuve si réclamation
  - Escalade SAV si complexité élevée
  - "Ne pas rembourser trop tôt" si signaux d'abus

### D. Ce qui NE doit PAS être fait en premier

1. **Pas d'inbox clone Shopify** — Shopify Inbox (chat) est une phase optionnelle future
2. **Pas de connecteur conversationnel partiel** — la v1 est orders + context, pas messaging
3. **Pas de logique mono-tenant** — multi-tenant dès le jour 1
4. **Pas de stockage brut non normalisé** — mapper vers le modèle `orders` existant
5. **Pas de creation/modification dans Shopify** — lecture seule en v1 (sauf refund via API dans une phase ultérieure)

---

## Étape 4 — Contrat Technique Shopify

### 1. Mode d'Authentification

| Aspect | Choix |
|--------|-------|
| **Protocole** | OAuth 2.0 Shopify (App Installation Flow) |
| **Scope** | `read_orders read_customers read_fulfillments read_returns` |
| **Portée** | Tenant-scoped (1 connexion = 1 boutique = 1 tenant) |
| **Multi-boutique** | 1 tenant peut connecter N boutiques (chacune = 1 `tenant_channel`) |
| **RBAC** | owner/admin uniquement (agents exclus) |
| **Stockage tokens** | Table `shopify_connections` avec `access_token` chiffré |
| **Refresh** | Shopify access tokens sont permanents (pas de refresh nécessaire, sauf offline → online mode) |
| **Rotation** | Sur app reinstall, nouveau token remplace l'ancien |

**Pourquoi pas Vault** : Vault est DOWN. Utiliser une table dédiée avec token chiffré (AES-256-GCM via clé d'env). Pattern fallback cohérent avec le state actuel.

### 2. API Source

**GraphQL Admin API** comme source principale.

Raisons :
- REST Admin API est legacy depuis avril 2025 pour les nouvelles apps publiques
- GraphQL permet des requêtes optimales (1 appel = orders + fulfillments + customer)
- Meilleur rate limiting (bucket par coût de requête, pas par nombre d'appels)
- Types forts, pagination cursor-based native

**Objets minimum nécessaires :**

| Objet GraphQL | Usage KeyBuzz |
|---------------|---------------|
| `Shop` | Nom boutique, domaine, devise, fuseau horaire |
| `Customer` | Nom, email, historique commandes, tags, note |
| `Order` | Numéro, statut, dates, montants, line items |
| `Fulfillment` | Statut expédition, tracking, transporteur |
| `FulfillmentOrder` | Orchestration fulfillment (3PL, etc.) |
| `Refund` | Montant, raison, line items, date |
| `Return` | Statut retour, motif, état |

### 3. Modèle de Persistance KeyBuzz

#### Tables à créer

**`shopify_connections`** (connexion tenant ↔ boutique)

| Colonne | Type | Description |
|---------|------|-------------|
| id | TEXT PK | UUID |
| tenant_id | TEXT NOT NULL | FK → tenants.id |
| shop_domain | TEXT NOT NULL | `myshop.myshopify.com` |
| shop_name | TEXT | Nom affiché |
| access_token_enc | TEXT NOT NULL | Token chiffré AES-256-GCM |
| scopes | TEXT | Scopes accordés |
| shopify_shop_id | TEXT | GID Shopify |
| currency | TEXT | Devise boutique |
| timezone | TEXT | Fuseau boutique |
| api_version | TEXT | Version API utilisée |
| status | TEXT NOT NULL | `active`, `disconnected`, `error` |
| last_sync_at | TIMESTAMPTZ | Dernière sync réussie |
| last_sync_error | TEXT | Dernière erreur |
| installed_at | TIMESTAMPTZ | Date installation app |
| created_at | TIMESTAMPTZ NOT NULL | |
| updated_at | TIMESTAMPTZ NOT NULL | |

**`shopify_webhook_events`** (log webhooks reçus, idempotence)

| Colonne | Type | Description |
|---------|------|-------------|
| id | TEXT PK | UUID |
| tenant_id | TEXT NOT NULL | |
| connection_id | TEXT NOT NULL | FK → shopify_connections.id |
| shopify_webhook_id | TEXT | Header `X-Shopify-Webhook-Id` |
| topic | TEXT NOT NULL | `orders/create`, `orders/updated`, etc. |
| payload_hash | TEXT | SHA-256 du payload (dédup) |
| processed | BOOLEAN DEFAULT false | |
| processed_at | TIMESTAMPTZ | |
| error | TEXT | |
| created_at | TIMESTAMPTZ NOT NULL | |

**Réutilisation de tables existantes :**

| Table existante | Réutilisation |
|-----------------|---------------|
| `orders` | **OUI** — insérer avec `channel = 'shopify'`, `external_order_id = shopify_order_name` |
| `conversations` | **OUI** — conversations liées via `order_ref` |
| `tenant_channels` | **OUI** — entrée `provider = 'shopify'`, `marketplace_key = 'shopify-{shop_domain}'` |
| `oauth_states` | **OUI** — réutiliser avec `marketplaceType = 'shopify'` |
| `tracking_events` | **OUI** — si enrichissement carrier live |

**Tables NON nécessaires en v1 :**

- `shopify_customers` → les infos client sont dénormalisées dans `orders` (comme Amazon)
- `shopify_orders` → les commandes vont dans `orders` existant (normalisation cross-channel)
- `shopify_sync_runs` → réutiliser `sync_states` existant

#### Stratégies

| Stratégie | Approche |
|-----------|----------|
| **Idempotence** | `X-Shopify-Webhook-Id` dans `shopify_webhook_events`, dédup avant traitement |
| **Mapping external_id** | `orders.external_order_id` = Shopify `order.name` (#1234), `orders.raw_data` = payload complet |
| **Normalisation cross-channel** | Même structure `orders` que Amazon, champ `channel = 'shopify'` |
| **Rollback logique** | DELETE sur `orders WHERE channel = 'shopify' AND tenant_id = ?` |

### 4. Webhooks

| Topic | Priorité | Usage |
|-------|----------|-------|
| `orders/create` | **P0** | Nouvelle commande → insert `orders` |
| `orders/updated` | **P0** | Mise à jour statut/fulfillment → update `orders` |
| `fulfillments/create` | **P1** | Nouveau fulfillment → update tracking |
| `fulfillments/update` | **P1** | Mise à jour tracking/statut |
| `refunds/create` | **P1** | Remboursement → update `orders` + alerte IA |
| `returns/update` | **P2** | Retour mis à jour |
| `app/uninstalled` | **P0** | Déconnexion → status `disconnected`, cleanup webhooks |
| `shop/update` | **P3** | Changement nom/devise boutique |

**Endpoint webhook cible** : `POST /webhooks/shopify` avec validation HMAC (shared secret).

### 5. Sync

| Aspect | Approche |
|--------|----------|
| **Sync initiale** | GraphQL `orders(first: 50, sortKey: CREATED_AT, reverse: true)` — 30 derniers jours |
| **Sync incrémentale** | Webhooks (temps réel) + cron de rattrapage (toutes les 6h, `updated_at > last_sync_at`) |
| **Retry** | Exponential backoff (1s, 2s, 4s, 8s, 16s) sur erreurs réseau |
| **Idempotence** | Upsert par `(tenant_id, external_order_id, channel)` |
| **Rate limiting** | Shopify GraphQL : bucket 1000 points, refill 50/s → respecter `cost` retourné |
| **Worker** | CronJob K8s `shopify-sync` (comme `amazon-orders-sync`) |
| **Logs** | `sync_states` table existante + logs structurés |
| **Audit trail** | `shopify_webhook_events` pour traçabilité complète |
| **Rollback logique** | Suppression par tenant/channel, pas de cascade destructive |

---

## Étape 5 — Vérification Multi-Tenant et SaaS

### Isolation par point

| Point | Isolation garantie | Comment |
|-------|-------------------|---------|
| **Données orders** | `WHERE tenant_id = ?` | Colonnes existantes, index existants |
| **Connexion Shopify** | `shopify_connections.tenant_id` | 1 connexion = 1 tenant |
| **Webhooks** | `connection_id → tenant_id` | Résolution tenant depuis le webhook |
| **Tokens** | Chiffrés par tenant dans `shopify_connections` | Pas de token partagé |
| **Conversations** | `conversations.tenant_id` | Isolation existante |
| **Sync state** | `sync_states.tenant_id` | Isolation existante |
| **Billing** | `tenant_channels` par tenant, plan limits | Isolation existante |

### Risques cross-tenant si on va trop vite

1. **Webhook mal routé** → un webhook sans validation `connection_id` pourrait écrire dans le mauvais tenant. **Mitigation** : valider HMAC + résoudre `tenant_id` depuis `shopify_connections` avant tout write.
2. **Token partagé** → si le chiffrement utilise une clé unique globale, la compromission d'un tenant expose tous. **Mitigation** : clé par tenant ou clé globale + isolation DB stricte.
3. **Sync initiale sans filtre** → un bug de sync pourrait importer les commandes d'un shop dans un autre tenant. **Mitigation** : requête GraphQL authentifiée par le token de la connexion spécifique.
4. **Cache token en mémoire** → si un cache in-memory ne scope pas par `tenant_id`, risque de fuite. **Mitigation** : clé de cache = `shopify:{tenant_id}:{connection_id}`.

### Garde-fous à imposer dès PH-SHOPIFY-02

- Tout accès DB filtré par `tenant_id` (pas d'exception)
- Webhook HMAC vérifié AVANT parsing du payload
- Token jamais en clair dans les logs
- Aucune dépendance à `ecomlg-001` dans le code
- Aucune hypothèse mono-boutique (1 tenant = N boutiques possibles)

---

## Étape 6 — Impact AI / SAV / Autopilot

### Données Shopify à injecter dans le contexte IA

Le fichier `shared-ai-context.ts` consomme déjà les données d'`orders` de façon générique :

```
loadEnrichedOrderContext(pool, orderRef, tenantId) → EnrichedOrderContext
```

**Colonnes déjà exploitées par l'IA** (depuis `orders`) :

| Colonne | Utilisée par l'IA | Disponible via Shopify |
|---------|-------------------|----------------------|
| `external_order_id` | OUI (orderNumber) | OUI → `order.name` |
| `channel` | OUI (canal marketplace) | OUI → `'shopify'` |
| `status` | OUI | OUI → mapping Shopify → statut normalisé |
| `carrier` | OUI | OUI → `fulfillment.tracking_company` |
| `tracking_code` | OUI | OUI → `fulfillment.tracking_number` |
| `tracking_url` | OUI | OUI → `fulfillment.tracking_url` |
| `delivery_status` | OUI | PARTIEL → à mapper depuis `fulfillment.status` |
| `order_date` | OUI | OUI → `order.created_at` |
| `fulfillment_channel` | OUI | OUI → `'shopify_fulfillment'` ou `'3pl'` |
| `total_amount` | OUI | OUI → `order.total_price` |
| `currency` | OUI | OUI → `order.currency` |
| `products` | OUI (JSONB) | OUI → `order.line_items` |
| `shipped_at` | OUI | OUI → `fulfillment.created_at` |
| `delivered_at` | OUI | PARTIEL → dépend du tracking |
| `estimated_delivery_at` | OUI | NON natif → estimation possible |
| `customer_name` | OUI | OUI → `order.customer.first_name + last_name` |
| `customer_email` | OUI | OUI → `order.customer.email` |

### Enrichissements spécifiques Shopify (non présents pour Amazon)

| Donnée | Impact IA | Phase |
|--------|-----------|-------|
| **Statut paiement** (`financial_status`) | Permet de détecter paiement partiel/refund | PH-SHOPIFY-03 |
| **Nombre de commandes client** | Signal réputation/fidélité | PH-SHOPIFY-04 |
| **Tags client Shopify** | Enrichissement contexte (VIP, etc.) | PH-SHOPIFY-04 |
| **Raison du retour** | Contexte SAV direct | PH-SHOPIFY-04 |
| **Montant refund** | Contexte financier pour décision | PH-SHOPIFY-03 |

### Comment éviter que l'IA devienne trop permissive

- Les règles SAV existantes (`getScenarioRules`, `getWritingRules`) s'appliquent par `channel`
- Ajouter un profil `SHOPIFY` dans `marketplacePolicyEngine.ts` (PH92) :
  - Politique de remboursement Shopify (pas les mêmes contraintes qu'Amazon)
  - Délais SAV Shopify (pas de A-Z Guarantee)
  - Règles anti-abus spécifiques (pas de metric vendeur Shopify comme Amazon ODR)
- L'autopilot respecte `safe_mode` — pas d'envoi automatique sans validation humaine

### Branchement avec les moteurs existants

| Moteur | Impact Shopify |
|--------|----------------|
| **SAV Policy Engine** (PH44) | Ajouter politique Shopify-spécifique dans `tenant_ai_policies` |
| **Playbooks** | Inchangés — déclenchement par `channel = 'shopify'` possible |
| **Autopilot** | Fonctionne tel quel via `shared-ai-context.ts` |
| **Orders cockpit** | Affiche déjà les commandes par `channel` |
| **Inbox details** | Panel latéral enrichi par `loadEnrichedOrderContext()` |
| **Marketplace Policy** (PH92) | **À ÉTENDRE** : nouveau profil `SHOPIFY` |

---

## Étape 7 — RBAC / Onboarding / UX de Connexion

### Qui peut connecter Shopify

| Rôle | Peut connecter | Raison |
|------|---------------|--------|
| **owner** | OUI | Propriétaire du compte |
| **admin** | OUI | Administrateur technique |
| **agent** | NON | Pas de modification d'intégration |

Même logique que les canaux actuels (Amazon, Octopia).

### Où vit la connexion Shopify

**Emplacement recommandé : page Channels** (`/channels`)

Raisons :
- Cohérence avec Amazon et Octopia (déjà dans Channels)
- Le catalogue `MARKETPLACE_CATALOG` centralise tous les connecteurs
- Le billing channels (add-on par canal) est déjà câblé
- L'onboarding redirige vers Channels pour le premier canal

**Alternative rejetée** : page Settings/Integrations — trop fragmenté, incohérent avec l'existant.

### Wording utilisateur recommandé

| Étape | Texte |
|-------|-------|
| **Catalogue** | « Shopify — Connectez votre boutique pour enrichir vos conversations avec vos commandes, clients et suivi de livraison. » |
| **Bouton** | « Connecter Shopify » |
| **OAuth** | Redirection Shopify standard (l'utilisateur autorise l'app) |
| **Succès** | « Boutique {nom} connectée ! Les commandes récentes sont en cours de synchronisation. » |
| **Erreur OAuth** | « La connexion à Shopify a échoué. Veuillez réessayer ou vérifier vos permissions. » |
| **Boutique déconnectée** | « Shopify déconnecté. Les données existantes sont conservées mais ne seront plus mises à jour. » |
| **App désinstallée** | Webhook `app/uninstalled` → statut `disconnected` automatiquement, badge « Déconnecté » dans Channels |

### Comportements edge-case

| Cas | Comportement |
|-----|-------------|
| App désinstallée côté Shopify | Webhook `app/uninstalled` → `status = 'disconnected'`, badge warning dans Channels |
| Token révoqué | Erreur 401 sur sync → `status = 'error'`, message « Reconnexion nécessaire » |
| Boutique fermée | Erreur API → `status = 'error'`, message explicite |
| Changement de plan (downgrade) | Si canal Shopify dépasse la limite du plan → warning billing, pas de suppression |

---

## Étape 8 — Plan de Phases

### PH-SHOPIFY-02 : Fondation OAuth + Connexion

**Objectif** : Permettre à un owner/admin de connecter sa boutique Shopify via OAuth et d'enregistrer les webhooks.

**Périmètre** :
- Table `shopify_connections` (migration SQL)
- Table `shopify_webhook_events` (migration SQL)
- Ajout `shopify` dans `MARKETPLACE_CATALOG` de `channelsService.ts`
- Ajout type `shopify` dans `oauth_states.marketplaceType`
- Routes API : `GET /shopify/status`, `POST /shopify/connect` (initie OAuth), `GET /shopify/callback` (callback OAuth), `POST /shopify/disconnect`
- Enregistrement webhooks Shopify post-connexion
- Validation HMAC webhook
- Routes BFF client : `/api/shopify/*`
- UI Channel page : entrée Shopify dans le catalogue, bouton connecter
- Aucune sync de données (juste connexion)

**Fichiers/modules probables** :
- `src/modules/marketplaces/shopify/` (nouveau dossier, ~6 fichiers)
- `src/modules/channels/channelsService.ts` (patch catalogue)
- `app/channels/page.tsx` (patch UI)
- `app/api/shopify/` (routes BFF)
- Migration SQL (2 tables)

**Risques** : OAuth callback redirect, Vault DOWN (fallback table chiffrée), scope trop large.
**Livrable** : Connexion Shopify fonctionnelle, webhook endpoint actif, 0 données importées.

---

### PH-SHOPIFY-03 : Sync Commandes + Normalisation Orders

**Objectif** : Importer les commandes Shopify dans `orders` et les rendre visibles dans le cockpit commandes.

**Périmètre** :
- Sync initiale (30 jours, GraphQL)
- Webhook processing (`orders/create`, `orders/updated`)
- Normalisation Shopify → `orders` (mapping champs)
- Fulfillment/tracking intégré dans `orders`
- Refund/return status dans `orders` (colonnes à ajouter si nécessaire)
- Idempotence upsert
- Page Orders : commandes Shopify visibles avec badge canal

**Risques** : Rate limiting GraphQL, mapping statuts Shopify ↔ statuts normalisés, volumétrie.
**Livrable** : Commandes Shopify dans le cockpit, sync temps réel via webhooks.

---

### PH-SHOPIFY-04 : Enrichissement IA + Contexte Conversation

**Objectif** : Injecter le contexte Shopify dans les suggestions IA et l'inbox.

**Périmètre** :
- `shared-ai-context.ts` : aucune modification si les commandes sont dans `orders`
- Profil `SHOPIFY` dans `marketplacePolicyEngine.ts`
- Panel latéral inbox : affichage enrichi (client, paiement, fulfillment, tracking, refund)
- Suggestions IA adaptées au contexte Shopify
- Autopilot compatible (via `shared-ai-context.ts`)
- Matching conversation ↔ commande Shopify (email client → `orders.customer_email`)

**Risques** : Matching conversation sans `order_ref` explicite (dépend du canal d'entrée de la conversation).
**Livrable** : Conversations enrichies Shopify, suggestions IA contextuelles.

---

### PH-SHOPIFY-05 : Sync Worker + CronJob

**Objectif** : Worker de synchronisation périodique et rattrapage.

**Périmètre** :
- CronJob K8s `shopify-orders-sync` (toutes les 6h)
- Delta sync (`updated_at > last_sync_at`)
- Gestion erreurs et retry
- Health monitoring
- Métriques (commandes sync, erreurs, latence)

**Risques** : Multi-tenant scaling, rate limiting par boutique, pod restart pendant sync.
**Livrable** : Sync robuste, rattrapage automatique, monitoring.

---

### PH-SHOPIFY-06 (optionnel) : Shopify Inbox / Chat Integration

**Objectif** : Intégrer les conversations Shopify Inbox comme canal conversationnel.

**Note** : Phase optionnelle, uniquement si le marchand utilise Shopify Inbox. Nécessite des webhooks supplémentaires et un modèle de threading différent.

---

### Recommandation d'enchaînement

```
PH-SHOPIFY-02 (OAuth + connexion)
    ↓
PH-SHOPIFY-03 (Sync commandes)
    ↓
PH-SHOPIFY-04 (IA + contexte)
    ↓
PH-SHOPIFY-05 (Worker + CronJob)
    ↓
[Optionnel] PH-SHOPIFY-06 (Inbox/Chat)
```

Chaque phase est :
- courte (~1-2 sessions agent),
- déployable indépendamment,
- rollback clair (table DROP / MARKETPLACE_CATALOG revert),
- validation DEV d'abord, PROD sur feu vert explicite.

---

## Étape 9 — Niveau de Risque

### Prérequis avant PH-SHOPIFY-02

| Prérequis | Statut | Action |
|-----------|--------|--------|
| API DEV réalignée avec PROD | **NON** — v3.5.48 vs v3.5.224 | Reconstruire/redéployer API DEV |
| App Shopify créée dans Partner Dashboard | **NON** | Ludovic doit créer l'app |
| Client ID + Client Secret Shopify | **NON** | Issu de la création de l'app |
| URL de callback OAuth définie | **NON** | `https://api-dev.keybuzz.io/shopify/callback` |
| Scopes Shopify validés | **NON** | Confirmer la liste avec Ludovic |
| Clé de chiffrement tokens définie | **NON** | Variable d'env `SHOPIFY_TOKEN_ENCRYPTION_KEY` |
| Logo Shopify dans `public/marketplaces/` | **NON** | SVG à préparer |

### GO / NOGO pour PH-SHOPIFY-02

**GO si** :
1. API DEV est réalignée avec PROD (même base de code)
2. App Shopify créée dans le Partner Dashboard avec les scopes définis
3. Client ID + Secret disponibles (en variable d'env ou secret K8s)
4. Logo Shopify SVG prêt
5. Ludovic confirme :
   - la liste de scopes
   - le positionnement dans Channels (pas Settings)
   - le wording utilisateur
   - le pricing (1 canal Shopify = 1 add-on channel standard à 50 EUR)

**NOGO si** :
1. API DEV toujours sur v3.5.48 (risque de divergence comportementale)
2. Pas d'app Shopify créée (impossible de tester OAuth)
3. Vault non restauré ET pas de stratégie de chiffrement tokens validée
4. Autre phase critique en cours (P0/P1 non résolue)

### Points à figer fonctionnellement avec Ludovic

1. **Multi-boutique** : un tenant peut-il connecter plusieurs boutiques Shopify ? (recommandation : oui, comme Amazon multi-marketplace)
2. **Pricing** : Shopify = 1 canal standard (50 EUR add-on) ou pricing différent ?
3. **Scopes** : lecture seule en v1 (`read_*`) ou écriture dès le départ (`write_orders` pour refund) ?
4. **Nom de l'app Shopify** : « KeyBuzz » ou « KeyBuzz SAV » ou autre ?
5. **Matching conversation** : comment une conversation email est-elle liée à une commande Shopify ? (par `customer_email` ? par `order_ref` saisi manuellement ?)

---

## Étape 10 — Verdict Final

### Résumé

| Dimension | État |
|-----------|------|
| Architecture existante | **Compatible** — orders/conversations/AI context sont génériques |
| Tables manquantes | 2 tables à créer (`shopify_connections`, `shopify_webhook_events`) |
| Tables existantes réutilisées | 5 (`orders`, `tenant_channels`, `oauth_states`, `sync_states`, `conversations`) |
| Code existant à modifier | 3 fichiers (catalogue channels, UI channels, marketplace policy) |
| Code nouveau | 1 module marketplace (`src/modules/marketplaces/shopify/`, ~8 fichiers) |
| Risques cross-tenant | Maîtrisés avec les garde-fous documentés |
| Impact IA | **Positif** — enrichissement contexte via `shared-ai-context.ts` sans modification |
| Impact billing | Minimal — réutilisation du système add-on channels existant |
| Blocage | API DEV non alignée (à corriger avant PH-SHOPIFY-02) |

### Rollback conceptuel

- PH-SHOPIFY-02 : `DROP TABLE shopify_connections, shopify_webhook_events` + revert MARKETPLACE_CATALOG
- PH-SHOPIFY-03 : `DELETE FROM orders WHERE channel = 'shopify'`
- PH-SHOPIFY-04 : revert profil policy + revert UI panel
- Chaque phase est indépendamment réversible

---

## VERDICT

# ✅ SHOPIFY INSERTION PLAN READY

L'architecture KeyBuzz est prête à accueillir un connecteur Shopify. Le modèle de données existant (`orders`, `conversations`, `tenant_channels`) est suffisamment générique pour intégrer Shopify sans refonte. Le moteur IA (`shared-ai-context.ts`) fonctionne déjà de façon channel-agnostique.

**Prérequis obligatoires avant PH-SHOPIFY-02 :**
1. Réaligner API DEV avec PROD
2. Création de l'app Shopify dans le Partner Dashboard
3. Validation des 5 points fonctionnels avec Ludovic

---

**STOP**
Aucune implémentation produit au-delà de ce rapport.
Aucune migration DB.
Aucun build.
Aucun déploiement.
Attendre validation de Ludovic avant PH-SHOPIFY-02.
