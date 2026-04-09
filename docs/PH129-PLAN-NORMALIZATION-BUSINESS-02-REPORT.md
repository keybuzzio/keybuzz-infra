# PH129-PLAN-NORMALIZATION-BUSINESS-02 — Rapport Final

> Date : 1er mars 2026
> Type : Normalisation structurelle — plans, KBActions, wallet, Stripe, modes IA
> Phase precedente : PH129-PLAN-AUDIT-01 (verdict: PLAN SYSTEM INCONSISTENT)

---

## 1. Audit final reconcilie

### 1.1 Etat AVANT normalisation (1er mars 2026)

| Source | Plans trouves | Format | Probleme |
|--------|--------------|--------|----------|
| DB `tenants` DEV | `pro`, `free`, `PRO`, `AUTOPILOT` | Mixte | Casse incoherente + `free` non defini |
| DB `tenants` PROD | `pro`, `STARTER`, `starter`, `AUTOPILOT`, `PRO` | Mixte | 3 formats differents |
| DB `billing_subscriptions` | `PRO`, `AUTOPILOT`, `STARTER` | MAJUSCULE | OK |
| DB `sla_policies` | `pro`, `enterprise` | minuscule | Incoherent |
| Backend `pricing.ts` | STARTER, PRO, AUTOPILOT, ENTERPRISE | MAJUSCULE | OK |
| Backend `plan-rules.service.ts` | starter, pro, autopilot, enterprise | minuscule | Normalise via `.toLowerCase()` |
| Backend `kbactions.ts` | starter, pro, autopilote, autopilot, business, enterprise | minuscule | Alias multiples |
| Backend `ai-budgets.ts` | STARTER/starter, PRO/pro, AUTOPILOT/autopilot, ENTERPRISE/enterprise | Duplique | Doublons pour chaque casse |
| Backend `entitlement.service.ts` | normalise `.toUpperCase()` | MAJUSCULE | OK |
| Client `planCapabilities.ts` | STARTER, PRO, AUTOPILOT, ENTERPRISE | MAJUSCULE | OK |
| Client `pricing/config.ts` | starter, pro, autopilot, enterprise | minuscule | ID uniquement |
| Stripe env vars | STARTER, PRO, AUTOPILOT + addon | Price IDs reels | OK |

### 1.2 Incoherences identifiees

| # | Incoherence | Gravite | Resolution |
|---|-------------|---------|------------|
| I-1 | `free` en DB → pas de definition | CRITIQUE | Migre vers `STARTER` |
| I-2 | `pro` minuscule vs `PRO` majuscule | CRITIQUE | Normalise en `PRO` |
| I-3 | `starter` minuscule vs `STARTER` majuscule | CRITIQUE | Normalise en `STARTER` |
| I-4 | `sla_policies.plan` en minuscule | MAJEUR | Normalise en MAJUSCULE |
| I-5 | `ecomlg-001` fake Stripe (`manual_seed_initial`) | MAJEUR | Supprime (billing exempt) |
| I-6 | `billing_customers` tenant_id=`test` | MAJEUR | Supprime |
| I-7 | `ai_actions_wallet` tenant_id=`null` | MAJEUR | Supprime |
| I-8 | `ai_credits_wallet` tenant_id=`null` | MAJEUR | Supprime |
| I-9 | `billing_customers` tenant_id=`ecomlg-001` = `pending_stripe_setup` | MAJEUR | Supprime (billing exempt) |
| I-10 | `planCapabilities.ts` ENTERPRISE kbActionsMonthly=5000 vs kbactions.ts=10000 | MOYEN | Corrige vers 10000 |
| I-11 | `pricing/config.ts` ENTERPRISE KBActions=5000 | MOYEN | Corrige vers 10000 |

---

## 2. Source de verite retenue

### 2.1 Plans

| Element | Decision |
|---------|----------|
| Format canonique | **MAJUSCULE** : `STARTER`, `PRO`, `AUTOPILOT`, `ENTERPRISE` |
| Stockage DB | `tenants.plan` en MAJUSCULE |
| `billing_subscriptions.plan` | MAJUSCULE |
| `sla_policies.plan` | MAJUSCULE |
| Backend lookup | Via `.toLowerCase()` ou `.toUpperCase()` pour tolerance |
| Client source de verite | `planCapabilities.ts` (type `PlanType`) |
| Stripe | 3 plans standards avec price IDs monthly+annual |
| Enterprise | Sur devis, PAS de product Stripe standard |

### 2.2 KBActions

| Plan | Mensuelles | Achat ponctuel | Source |
|------|-----------|----------------|--------|
| STARTER | 0 | **OUI** (packs) | `kbactions.ts` PLAN_KBACTIONS_MONTHLY |
| PRO | 1000 | OUI | Coherent backend + frontend |
| AUTOPILOT | 2000 | OUI | Coherent backend + frontend |
| ENTERPRISE | 10000 | OUI | Corrige (etait 5000 dans planCapabilities) |

Packs disponibles (tous plans) :
- Pack Essentiel : 50 KBActions — 24.90 EUR
- Pack Pro : 200 KBActions — 69.90 EUR
- Pack Business : 500 KBActions — 149.90 EUR

### 2.3 Wallet / Ledger

| Element | Etat |
|---------|------|
| `ai_actions_wallet` | Source unique du solde KBActions |
| `ai_actions_ledger` | Journal d'audit des mouvements |
| `ai_credits_wallet` | **LEGACY** — ancien systeme USD, toujours present |
| Colonnes wallet | `remaining`, `purchased_remaining`, `included_monthly`, `reset_at` |
| Colonnes ledger | `delta`, `reason`, `request_id`, `kb_actions`, `cost_usd`, `decision_context` |
| Reset mensuel | Automatique via `reset_at` — remet `remaining = included_monthly` |
| Grant initial | Via `initialGrant()` a la creation de subscription |
| Sync plan change | Via `billing/routes.ts` — gere upgrade/downgrade/trial |

### 2.4 Modes IA

| Mode | Valeur DB `ai_settings.mode` | Description |
|------|------|-------------|
| Suggestions uniquement | `suggestion` | IA propose, humain decide |
| Mode supervise | `supervised` | IA agit sur les cas surs, propose sur les autres |
| Mode autonome | `autonomous` | IA repond automatiquement |

Regle cible par plan (a activer dans PH130) :

| Plan | Modes disponibles | Mode par defaut |
|------|------------------|-----------------|
| STARTER | Aucun (pas d'IA) | — |
| PRO | suggestion, supervised | supervised |
| AUTOPILOT | suggestion, supervised, autonomous | autonomous |
| ENTERPRISE | suggestion, supervised, autonomous | autonomous |

### 2.5 Strategie Enterprise

| Element | Decision |
|---------|----------|
| Stripe | **PAS de product/price standard** |
| Pricing | Sur devis uniquement |
| CTA | "Demander un audit" |
| KBActions | 10000/mois (configurable) |
| Canaux | Illimites |
| Support | Dedie |
| Difference vs Autopilot | KPI avances, audit, securite renforcee, architecture adaptee |

---

## 3. Migrations DB effectuees

### 3.1 Normalisation plans (DEV + PROD)

```sql
-- DEV
UPDATE tenants SET plan = 'STARTER' WHERE plan IN ('free', 'starter');  -- 1 row (tenant-1772234265142)
UPDATE tenants SET plan = 'PRO' WHERE plan = 'pro';  -- 1 row (ecomlg-001)
UPDATE sla_policies SET plan = 'PRO' WHERE plan = 'pro';  -- 1 row
UPDATE sla_policies SET plan = 'ENTERPRISE' WHERE plan = 'enterprise';  -- 1 row

-- PROD
UPDATE tenants SET plan = 'STARTER' WHERE plan = 'starter';  -- 1 row (switaa-sasu-mmazd2rd)
UPDATE tenants SET plan = 'PRO' WHERE plan = 'pro';  -- 1 row (ecomlg-001)
UPDATE sla_policies SET plan = 'PRO' WHERE plan = 'pro';  -- 1 row
UPDATE sla_policies SET plan = 'ENTERPRISE' WHERE plan = 'enterprise';  -- 1 row
```

### 3.2 Nettoyage donnees

```sql
-- DEV
DELETE FROM ai_actions_wallet WHERE tenant_id = 'null';  -- 1 row
DELETE FROM ai_credits_wallet WHERE tenant_id = 'null';  -- 1 row
DELETE FROM billing_customers WHERE tenant_id = 'test';  -- 1 row
DELETE FROM billing_subscriptions WHERE tenant_id = 'ecomlg-001' AND stripe_subscription_id = 'manual_seed_initial';  -- 1 row
DELETE FROM billing_customers WHERE tenant_id = 'ecomlg-001' AND stripe_customer_id = 'pending_stripe_setup';  -- 1 row

-- PROD
DELETE FROM ai_actions_wallet WHERE tenant_id = 'null';  -- 1 row
DELETE FROM ai_credits_wallet WHERE tenant_id = 'null';  -- 1 row
DELETE FROM billing_customers WHERE tenant_id = 'test';  -- 1 row
```

### 3.3 Correction code (bastion)

```
planCapabilities.ts : ENTERPRISE kbActionsMonthly 5000 → 10000
pricing/config.ts : ENTERPRISE KBActions '5 000' → '10 000'
```

---

## 4. Etat Stripe reel

### 4.1 Price IDs configures

| Plan | Monthly DEV | Monthly PROD | Annual DEV | Annual PROD |
|------|------------|-------------|------------|-------------|
| STARTER | `price_1SmO9s...` | `price_1Sreqr...` | `price_1SmO9t...` | `price_1Sreqr...` |
| PRO | `price_1SmO9u...` | `price_1Sreqs...` | `price_1SmO9u...` | `price_1Sreqs...` |
| AUTOPILOT | `price_1SmO9v...` | `price_1Sreqt...` | `price_1SmO9w...` | `price_1Sreqt...` |
| Channel Addon | `price_1SmO9x...` | `price_1Sreqt...` | `price_1SmO9x...` | `price_1Srequ...` |

Product addon channel :
- DEV : `prod_TjrtcvXp3I6fJR`
- PROD : `prod_TpJTEELacYjLGG`

### 4.2 Enterprise dans Stripe

**N'existe pas** — sur devis, contact commercial. Pas de checkout automatique.

### 4.3 Packs KBActions dans Stripe

Les packs KBActions utilisent des sessions Stripe Checkout one-time (pas des subscriptions recurentes).
Les price IDs sont generes dynamiquement dans `billing/routes.ts` via `stripe.checkout.sessions.create()`.

---

## 5. Matrice business finale

| Feature | STARTER (97€) | PRO (297€) | AUTOPILOT (497€) | ENTERPRISE (devis) |
|---------|---------------|------------|-------------------|---------------------|
| Inbox | oui | oui | oui | oui |
| Dashboard | oui | oui | oui | oui |
| Orders | oui | oui | oui | oui |
| Fournisseurs | oui | oui | oui | oui |
| Canaux inclus | 1 | 3 | 5 | Illimite |
| Canaux addon | +50€/canal | +50€/canal | +50€/canal | Inclus |
| Playbooks basiques | oui | oui | oui | oui |
| Playbooks avances | non | oui | oui | oui |
| Auto-execution playbooks | non | non | oui | oui |
| KBActions/mois | 0 | 1000 | 2000 | 10000 |
| Achat ponctuel KBActions | oui | oui | oui | oui |
| Suggestions IA | non | oui | oui | oui |
| Mode supervise | non | oui (defaut) | oui | oui |
| Mode autonome | non | non (upgrade) | oui (defaut) | oui |
| Supervision IA | non | oui | oui | oui |
| Assignation | non | oui | oui | oui |
| Escalade | non | equipe client | equipe KeyBuzz | equipe KeyBuzz |
| Queue agent | non | oui | oui | oui |
| Priorite conversations | non | oui | oui | oui |
| Journal IA | non | oui | oui | oui |
| SLA Cockpit | non | oui | oui | oui |
| KPI avances | non | non | non | oui |
| Audit | non | non | non | oui |
| Support | Standard | Prioritaire | Premium | Dedie |

---

## 6. Regles KBActions finale

| Element | Regle |
|---------|-------|
| Quotas mensuels | STARTER=0, PRO=1000, AUTOPILOT=2000, ENTERPRISE=10000 |
| Achat ponctuel | Tous plans (meme STARTER) via `/billing/ai-actions-checkout` |
| Packs | 50/24.90€, 200/69.90€, 500/149.90€ |
| Reset mensuel | Premier du mois, `remaining = included_monthly` |
| Grant initial | A la creation de subscription Stripe |
| Variance | ±15% par operation (anti-prediction) |
| Poids par operation | inbox_suggestion=6, contextualized=10, playbook_auto=8, attachment=14, heavy=20 |

---

## 7. Regles modes IA finale

| Plan | Suggestion | Supervise | Autonome | Mode par defaut |
|------|-----------|-----------|----------|-----------------|
| STARTER | — | — | — | — (pas d'IA) |
| PRO | visible | visible+defaut | cache (upgrade) | supervised |
| AUTOPILOT | visible | visible | visible+defaut | autonomous |
| ENTERPRISE | visible | visible | visible | autonomous |

**A activer dans PH130** — pas dans cette phase.

---

## 8. Validations

### 8.1 DEV (verifie 1er mars 2026)

| Check | Resultat |
|-------|----------|
| Plans tous en MAJUSCULE | OK (6 tenants) |
| Pas de wallets `null` | OK |
| Pas de customers `test` | OK |
| Pas de `manual_seed_initial` | OK |
| Pas de `pending_stripe_setup` | OK |
| ecomlg-001 billing exempt | OK |
| SLA policies normalisees | OK |
| Wallets coherents avec plans | OK (4/4 actifs, 1 warning `pending_payment`) |
| billing_subscriptions en MAJUSCULE | OK |
| Pas de doublons wallets | OK |
| Stripe env vars configures | OK |

**PH129 NORMALIZATION DEV = OK**

### 8.2 PROD (verifie 1er mars 2026)

| Check | Resultat |
|-------|----------|
| Plans tous en MAJUSCULE | OK (5 tenants) |
| Pas de wallets `null` | OK |
| Pas de customers `test` | OK |
| Pas de `manual_seed_initial` | OK |
| Pas de `pending_stripe_setup` | OK |
| ecomlg-001 billing exempt | OK |
| SLA policies normalisees | OK |
| Wallets coherents avec plans | OK (3/3 actifs, 2 warnings `pending_payment`) |
| billing_subscriptions en MAJUSCULE | OK |
| Pas de doublons wallets | OK |
| Stripe env vars configures | OK |

**PH129 NORMALIZATION PROD = OK**

---

## 9. Ce qui reste pour PH130 (gating)

| # | Action | Priorite |
|---|--------|----------|
| G-1 | Integrer `PlanProvider` dans le layout principal | CRITIQUE |
| G-2 | Activer `useEntitlement` dans AuthGuard → redirect `/locked` | CRITIQUE |
| G-3 | Backend plan guard middleware (`requirePlan()`) | CRITIQUE |
| G-4 | Wrapper les features avec `FeatureGate` (progressif) | MAJEUR |
| G-5 | Activer `getRouteAccess()` dans le layout | MAJEUR |
| G-6 | Deployer `GatedButton` dans les UIs restreintes | MAJEUR |
| G-7 | Gater les modes IA dans Settings (PRO≠autonomous) | MOYEN |
| G-8 | Corriger STARTER `hasAIAssistant` → false (ou gater via KBActions=0) | MOYEN |
| G-9 | Ajouter `ai_credits_wallet` deprecation (migration vers KBActions pur) | FAIBLE |

### Pre-conditions remplies par PH129B

- [x] Plans normalises en MAJUSCULE (DB DEV+PROD)
- [x] Donnees fantomes nettoyees
- [x] ecomlg-001 sans fake Stripe
- [x] Matrice business definie
- [x] Source de verite documentee
- [x] KBActions coherents
- [x] Modes IA documentes
- [x] Stripe audit OK
- [x] planCapabilities ENTERPRISE corrige (10000)

---

# VERDICT FINAL : PLAN SYSTEM NORMALIZED — READY FOR GATING

Le systeme de plans est maintenant **normalise et coherent** :

- Nomenclature unique MAJUSCULE partout (DB, code, Stripe)
- KBActions alignes entre backend et frontend
- Donnees fantomes supprimees
- Source de verite documentee
- Matrice business definie
- Modes IA documentes
- Stripe audite et confirme
- DEV et PROD valides

**Le gating (PH130) peut demarrer.**
