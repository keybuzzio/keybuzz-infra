# PH129-PLAN-AUDIT-01 — Rapport Final

> Date : 25 mars 2026
> Type : Audit read-only — aucun code modifie
> Verdict : **PLAN SYSTEM INCONSISTENT — FIX REQUIRED FIRST**

---

## 1. Inventaire des plans

### 1.1 Plans definis dans le code

| Source | Plans | Casse | Fichier |
|--------|-------|-------|---------|
| Frontend `planCapabilities.ts` | STARTER, PRO, AUTOPILOT, ENTERPRISE | MAJUSCULE | `src/features/billing/planCapabilities.ts` |
| Frontend `pricing/config.ts` | starter, pro, autopilot, enterprise | minuscule | `src/features/pricing/config.ts` |
| Backend `pricing.ts` | STARTER, PRO, AUTOPILOT, ENTERPRISE | MAJUSCULE | `src/modules/billing/pricing.ts` |
| Backend `plan-rules.service.ts` | starter, pro, autopilot, enterprise | minuscule | `src/services/plan-rules.service.ts` |
| Backend `entitlement.service.ts` | normalise avec `.toUpperCase()` | MAJUSCULE | `src/services/entitlement.service.ts` |

### 1.2 Plans stockes en DB (verifie 25 mars 2026)

```sql
SELECT DISTINCT plan FROM tenants;
-- Resultat : 'free', 'pro', 'PRO', 'AUTOPILOT'
```

| Tenant ID | Nom | Plan DB | Status |
|-----------|-----|---------|--------|
| ecomlg-001 | eComLG | `pro` (minuscule) | active |
| ecomlg-mmiyygfg | ecomlg | `PRO` | active |
| ecomlg-mn3rj8mg | eComLG | `AUTOPILOT` | active |
| switaa-sasu-mn27vxee | SWITAA SASU | `AUTOPILOT` | active |
| w3lg-mn2v3xyc | W3LG | `PRO` | pending_payment |
| tenant-1772234265142 | Essai | `free` | active |

**INCOHERENCE #1** : Le plan `free` existe en DB mais n'est defini dans AUCUN fichier de capabilities.
**INCOHERENCE #2** : `pro` minuscule vs `PRO` majuscule pour le meme plan.
**INCOHERENCE #3** : `STARTER` est defini dans le code mais n'existe dans AUCUN tenant.

### 1.3 Mapping Plan ↔ Stripe

| Tenant | Stripe Sub ID | Sub Plan | Sub Status | Stripe Customer |
|--------|--------------|----------|------------|-----------------|
| ecomlg-001 | `manual_seed_initial` | PRO | active | `pending_stripe_setup` |
| ecomlg-mmiyygfg | `sub_1T8zyY...` | PRO | active | `cus_U7EQfK42mwZde8` |
| switaa-sasu-mn27vxee | `sub_1TDsjz...` | AUTOPILOT | trialing | `cus_UCHIveTUw4sP89` |
| ecomlg-mn3rj8mg | `sub_1TEH3y...` | AUTOPILOT | trialing | `cus_UCgP3hIlG92vcT` |
| w3lg-mn2v3xyc | NULL | NULL | NULL | `cus_UCRmww3nn01PQM` |
| tenant-1772234265142 | NULL | NULL | NULL | NULL |

**INCOHERENCE #4** : ecomlg-001 a `stripe_subscription_id = 'manual_seed_initial'` et `stripe_customer_id = 'pending_stripe_setup'` — ce ne sont pas des IDs Stripe reels.

### 1.4 Billing Exempt

| Tenant | Exempt | Raison |
|--------|--------|--------|
| ecomlg-001 | true | internal_admin |

→ Le tenant pilote historique ne passe jamais par le paywall.

---

## 2. Audit Backend

### 2.1 Tables billing

| Table | Colonnes cles | Lignes |
|-------|---------------|--------|
| `billing_subscriptions` | tenant_id, stripe_subscription_id, plan, status, billing_cycle, channels_included, channels_addon_qty | 4 |
| `billing_customers` | tenant_id, stripe_customer_id, email | 6 |
| `billing_events` | id, event_type, stripe_event_id, processed | 10+ |
| `tenant_billing_exempt` | tenant_id, exempt, reason | 1 |

### 2.2 Endpoints billing (13 routes)

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/billing/current` | Plan actuel du tenant |
| POST | `/billing/checkout-session` | Creer session Stripe Checkout |
| POST | `/billing/ai-actions-checkout` | Checkout packs KBActions |
| GET | `/billing/invoices` | Historique factures |
| POST | `/billing/update-channels` | Modifier canaux addon |
| GET | `/billing/channel-proration-preview` | Preview prorata canaux |
| POST | `/billing/webhook` | Webhook Stripe |
| POST | `/billing/change-plan` | Changer de plan |
| POST | `/billing/cancel-reason` | Raison annulation |
| GET | `/billing/proration-preview` | Preview prorata plan |
| POST | `/billing/portal-session` | Stripe Customer Portal |
| GET | `/billing/debug-db` | Debug DB (DEV only) |
| GET | `/billing/status` | Statut global |

### 2.3 Entitlement Service

`src/services/entitlement.service.ts` — logique paywall :

- **Trial** : 14 jours depuis `created_at` si pas de subscription
- **Grace** : 3 jours apres expiration trial ou `past_due`
- **Locked si** : trial expire + grace expiree, canceled, incomplete, unpaid
- **Exempt** : `tenant_billing_exempt.exempt = true` → jamais locked

### 2.4 Plan Rules Service

`src/services/plan-rules.service.ts` — regles SLA par plan :

| Plan | SLA Target | At Risk | Escalation | Admin KPI | Agent Assignment |
|------|-----------|---------|------------|-----------|-----------------|
| starter | 48h | Non | Non | Non | Non |
| pro | 24h | 18h | Non | Oui | Oui |
| autopilot | 12h | 8h | Oui | Oui | Oui |
| enterprise | 24h | 18h | Oui | Oui | Oui |

### 2.5 Gating backend

**AUCUN garde-fou backend par plan sur les endpoints.**

Pas de middleware `requirePlan()`, pas de `planGuard`, pas de verification avant d'autoriser l'acces aux features. Les seuls endroits ou le plan est verifie :

1. `ai-credits.service.ts` : verifie si plan inclut l'IA (`pro`, `autopilot`, `enterprise`)
2. `playbook-engine.service.ts` : verifie `min_plan` sur les playbooks
3. `billing/routes.ts` : calcul du nombre de canaux inclus par plan
4. `entitlement.service.ts` : paywall (locked/unlocked), mais pas feature-level

---

## 3. Audit Frontend

### 3.1 Composants billing existants

| Composant | Fichier | Utilise dans |
|-----------|---------|-------------|
| `FeatureGate` | `components/FeatureGate.tsx` | `/billing/plan` uniquement (PlanBadge) |
| `GatedButton` | `components/FeatureGate.tsx` | **JAMAIS utilise** |
| `PlanBadge` | `components/FeatureGate.tsx` | `/billing/plan` |
| `PlanStatusCompact` | `components/PlanStatus.tsx` | Non verifie |
| `ChannelLimitBadge` | `components/PlanStatus.tsx` | Non verifie |
| `UpgradeBanner` | `components/PlanStatus.tsx` | Non verifie |
| `PlanInfoCard` | `components/PlanStatus.tsx` | Non verifie |
| `StripeStatusBanner` | `components/StripeStatusBanner.tsx` | Probablement billing pages |
| `useEntitlement` | `useEntitlement.tsx` | `/locked` page **UNIQUEMENT** |
| `useCurrentPlan` | `useCurrentPlan.tsx` | Via `PlanProvider` |
| `useCanAccessFeature` | `useCurrentPlan.tsx` | **JAMAIS utilise** |
| `PlanProvider` | `useCurrentPlan.tsx` | **PAS dans le layout principal** |

### 3.2 Middleware (Next.js)

Le middleware verifie :
- ✅ JWT / authentification
- ✅ Roles RBAC (agent/viewer redirige vers /inbox pour routes admin)
- ❌ **PAS de verification de plan**
- ❌ **PAS de verification billing locked**

### 3.3 AuthGuard

- ✅ Authentification (JWT via `/auth/me`)
- ❌ **PAS de verification entitlement/billing**
- ❌ **PAS de redirection vers `/locked`**

### 3.4 Route Access Guard

`routeAccessGuard.ts` definit `BILLING_EXEMPT_ROUTES` et `getRouteAccess()` avec `isBillingLocked` —
**mais cette fonction n'est appelee NULLE PART dans le code client.**

---

## 4. Features vs Plan — Matrice REELLE actuelle

| Feature | Accessible a... | Gating ? |
|---------|-----------------|----------|
| Inbox | TOUS les plans | ❌ Aucun |
| Dashboard | TOUS les plans | ❌ Middleware RBAC (admin only), pas plan |
| Commandes | TOUS les plans | ❌ Aucun |
| Fournisseurs | TOUS les plans | ❌ Aucun |
| Canaux | TOUS les plans | ❌ Aucun |
| Assignation (PH122) | TOUS les plans | ❌ Aucun |
| Escalade (PH123) | TOUS les plans | ❌ Aucun |
| Workbench (PH124) | TOUS les plans | ❌ Aucun |
| Agent Queue (PH125) | TOUS les plans | ❌ Aucun |
| Priorite (PH126) | TOUS les plans | ❌ Aucun |
| Suggestions IA (PH127) | TOUS les plans | ❌ Aucun |
| Supervision IA (PH128) | TOUS les plans | ❌ Permissions RBAC seulement |
| Journal IA | TOUS les plans | ❌ Aucun |
| Playbooks | TOUS les plans | ⚠️ Backend `min_plan` verifie |
| IA Assist | TOUS les plans | ⚠️ Backend verifie plan pour KBActions |
| Billing pages | TOUS les plans | ❌ RBAC (admin only) |
| Knowledge | TOUS les plans | ❌ Aucun |
| Settings | TOUS les plans | ❌ RBAC (admin only) |

**Conclusion** : Toutes les features sont accessibles a tous les plans. Le seul gating reel est RBAC (roles), pas plan.

---

## 5. Incoherences detectees

### CRITIQUE

| # | Incoherence | Impact |
|---|-------------|--------|
| I-1 | Plan `free` en DB mais pas de capabilities definies | Tenant "Essai" n'a aucune definition de features |
| I-2 | `STARTER` dans le code mais 0 tenants en DB | Plan fantome — jamais utilise |
| I-3 | Casse mixte `pro` vs `PRO` en DB | Risque de bug si comparaison sans normalisation |
| I-4 | `FeatureGate` existe mais n'est PAS utilise | Feature gating prepare mais jamais active |
| I-5 | `useEntitlement` uniquement sur `/locked` | Pas de redirection automatique vers paywall |
| I-6 | `PlanProvider` pas dans le layout principal | Plan context non disponible dans l'app |
| I-7 | `getRouteAccess()` avec `isBillingLocked` defini mais jamais appele | Dead code |

### MAJEUR

| # | Incoherence | Impact |
|---|-------------|--------|
| I-8 | Backend 0 guard par plan sur les endpoints | Tout le monde peut tout faire |
| I-9 | ecomlg-001 a un faux Stripe sub (`manual_seed_initial`) | Pas de vrais tests paywall |
| I-10 | `billing_customers` contient `test` (tenant fantome) | Pollution DB |
| I-11 | `ai_actions_wallet` contient `null` (tenant_id = "null") | Pollution DB |
| I-12 | `kbActionsMonthly` definit 2000 pour AUTOPILOT mais DB donne 2000 | Coherent mais `included_monthly` n'est pas derive du plan |

### MINEUR

| # | Incoherence | Impact |
|---|-------------|--------|
| I-13 | Stripe API version 2023-10-16 (ancienne) | Pas de nouvelles features |
| I-14 | SLA policies referent `enterprise` qui n'existe pas en DB | Regles jamais appliquees |
| I-15 | `BillingSourceBadge` affiche "Mock" en dev | Normal mais confus |

---

## 6. Audit Stripe

### 6.1 Variables d'env attendues

| Variable | Usage |
|----------|-------|
| `STRIPE_SECRET_KEY` | Cle secrete Stripe |
| `STRIPE_WEBHOOK_SECRET` | Verification webhooks |
| `STRIPE_PRICE_STARTER_MONTHLY` | Price ID Starter mensuel |
| `STRIPE_PRICE_STARTER_ANNUAL` | Price ID Starter annuel |
| `STRIPE_PRICE_PRO_MONTHLY` | Price ID Pro mensuel |
| `STRIPE_PRICE_PRO_ANNUAL` | Price ID Pro annuel |
| `STRIPE_PRICE_AUTOPILOT_MONTHLY` | Price ID Autopilot mensuel |
| `STRIPE_PRICE_AUTOPILOT_ANNUAL` | Price ID Autopilot annuel |
| `STRIPE_PRICE_ADDON_CHANNEL_MONTHLY` | Price ID canal addon mensuel |
| `STRIPE_PRICE_ADDON_CHANNEL_ANNUAL` | Price ID canal addon annuel |
| `STRIPE_PRODUCT_ADDON_CHANNEL` | Product ID canal addon (default: `prod_TpJTEELacYjLGG`) |

### 6.2 Webhooks traites

Le backend ecoute les evenements Stripe :
- `checkout.session.completed` → cree/update subscription en DB
- `customer.subscription.created` → insert `billing_subscriptions`
- `customer.subscription.updated` → update plan, status, channels
- `customer.subscription.deleted` → marque canceled

### 6.3 Subscriptions reelles

3 vrais abonnements Stripe actifs (hors `manual_seed_initial`) :
- `sub_1T8zyY...` (PRO, active, ecomlg-mmiyygfg)
- `sub_1TDsjz...` (AUTOPILOT, trialing, switaa-sasu-mn27vxee)
- `sub_1TEH3y...` (AUTOPILOT, trialing, ecomlg-mn3rj8mg)

---

## 7. Matrice cible recommandee

### 7.1 Simplification : supprimer `free`, aligner la casse

| Plan DB | Plan Code | Plan UI | Prix |
|---------|-----------|---------|------|
| `STARTER` | `STARTER` | Starter | 97 EUR |
| `PRO` | `PRO` | Pro | 297 EUR |
| `AUTOPILOT` | `AUTOPILOT` | Autopilot | 497 EUR |
| `ENTERPRISE` | `ENTERPRISE` | Entreprise | Sur devis |

→ Normaliser TOUS les plans en MAJUSCULE dans la DB.
→ Migrer `free` vers `STARTER` ou creer un plan `FREE` explicite.

### 7.2 Matrice Feature/Plan cible

| Feature | Starter | Pro | Autopilot | Enterprise |
|---------|---------|-----|-----------|------------|
| Inbox | ✅ | ✅ | ✅ | ✅ |
| Dashboard | ✅ | ✅ | ✅ | ✅ |
| Commandes | ✅ | ✅ | ✅ | ✅ |
| Canaux inclus | 1 | 3 | 5 | Illimite |
| Canaux addon | +50 EUR | +50 EUR | +50 EUR | Inclus |
| Playbooks basiques | ✅ | ✅ | ✅ | ✅ |
| Playbooks avances | ❌ | ✅ | ✅ | ✅ |
| Auto-execution playbooks | ❌ | ❌ | ✅ | ✅ |
| IA Assistant | ✅ (3/jour) | ✅ (illimite) | ✅ (illimite) | ✅ (illimite) |
| KBActions/mois | 0 | 1 000 | 2 000 | 5 000 |
| Journal IA | ❌ | ✅ | ✅ | ✅ |
| Suggestions IA (PH127) | ❌ | ✅ | ✅ | ✅ |
| Supervision IA (PH128) | ❌ | ✅ | ✅ | ✅ |
| Assignation agent | ❌ | ✅ | ✅ | ✅ |
| Escalade | ❌ | ✅ (equipe) | ✅ (KeyBuzz) | ✅ (KeyBuzz) |
| Agent Queue | ❌ | ✅ | ✅ | ✅ |
| Priorite conversations | ❌ | ✅ | ✅ | ✅ |
| Fournisseurs | ✅ | ✅ | ✅ | ✅ |
| SLA Cockpit | ❌ | ✅ | ✅ | ✅ |
| KPI avances | ❌ | ❌ | ❌ | ✅ |
| Audit | ❌ | ❌ | ❌ | ✅ |
| Support | Standard | Prioritaire | Premium | Dedie |

---

## 8. Ce qui manque pour un gating propre

### 8.1 Pre-requis (FIXES OBLIGATOIRES avant gating)

| # | Action | Priorite |
|---|--------|----------|
| F-1 | **Normaliser la casse** : UPDATE tous les `plan` en MAJUSCULE dans `tenants` | CRITIQUE |
| F-2 | **Migrer `free`** : decider si `free` = `STARTER` ou creer plan `FREE` | CRITIQUE |
| F-3 | **Nettoyer ecomlg-001** : remplacer `manual_seed_initial` par un vrai sub ou marquer exempt | CRITIQUE |
| F-4 | **Nettoyer DB** : supprimer `tenant_id='null'` de `ai_actions_wallet`, `tenant_id='test'` de `billing_customers` | MAJEUR |

### 8.2 Implementation gating (dans l'ordre)

| # | Action | Description |
|---|--------|-------------|
| G-1 | **Integrer `PlanProvider` dans le layout** | Rendre `useCurrentPlan()` disponible partout |
| G-2 | **Activer `useEntitlement` dans AuthGuard/Layout** | Redirect vers `/locked` si billing locked |
| G-3 | **Wrapper les features avec `FeatureGate`** | Un par un : Journal IA, Suggestions, etc. |
| G-4 | **Backend plan guard middleware** | Verifier le plan avant l'acces aux endpoints IA/escalade/etc. |
| G-5 | **Appeler `getRouteAccess()` dans le layout** | Activer la logique dead-code existante |
| G-6 | **Ajouter `GatedButton`** dans les UIs restreintes | Boutons desactives avec message upgrade |
| G-7 | **Sync `ai_actions_wallet.included_monthly` avec planCapabilities** | Deriver le quota du plan, pas hardcode |

### 8.3 Points d'attention

- **Ne PAS bloquer les tenants existants** : migration progressive, pas de lock surprise
- **Tester avec un vrai tenant Stripe** (pas ecomlg-001 qui est exempt)
- **Le gating frontend est insuffisant** : il faut aussi le backend guard
- **Le plan `STARTER` a 0 KBActions** : verifier si c'est voulu (VSL dit 1000)

---

## 9. Resume de l'etat

### Ce qui FONCTIONNE

- ✅ Stripe Checkout (vrais paiements)
- ✅ Stripe Webhooks (sync DB)
- ✅ Entitlement Service (trial/grace/locked)
- ✅ `planCapabilities.ts` (matrice feature/plan complete)
- ✅ `plan-rules.service.ts` (SLA par plan)
- ✅ Pricing page (UI complete)
- ✅ Billing pages (plan info, invoices, portal)

### Ce qui est PREPARE mais PAS ACTIVE

- ⚠️ `FeatureGate` composant (existe, pas utilise)
- ⚠️ `GatedButton` composant (existe, pas utilise)
- ⚠️ `useCanAccessFeature` hook (existe, pas utilise)
- ⚠️ `getRouteAccess()` avec billing (existe, pas appele)
- ⚠️ `BILLING_EXEMPT_ROUTES` (defini, pas utilise)

### Ce qui MANQUE

- ❌ Plan guard backend (middleware ou decorator)
- ❌ `PlanProvider` dans le layout principal
- ❌ Entitlement check dans AuthGuard
- ❌ Normalisation DB (casse, plan free)
- ❌ Nettoyage donnees fantomes

---

# VERDICT : PLAN SYSTEM INCONSISTENT — FIX REQUIRED FIRST

Le systeme de plans a ete **correctement architecte** (les composants existent)
mais il n'est **PAS active**. Aucune feature n'est reellement restreinte par plan.

**Avant d'implementer le gating (PH130+), il faut :**

1. Normaliser les plans en DB (casse + plan free)
2. Nettoyer les donnees fantomes
3. Integrer PlanProvider dans le layout
4. Activer l'entitlement check
5. Puis wrapper les features progressivement

Le gating peut etre implemente incrementalement grace aux composants existants.
Estimation : 2-3 phases pour un gating complet.
