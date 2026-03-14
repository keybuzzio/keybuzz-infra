# PH-ADMIN-87.6A — Finance Dashboard & Finance Admin Role — RAPPORT

**Date** : 2026-03-14
**Image** : ghcr.io/keybuzzio/keybuzz-admin-v2:v0.22.0-ph87.6a-finance-dashboard
**Statut** : DEPLOYE DEV + PROD

---

## 1. Role finance_admin

Nouveau role ajoute dans le registre RBAC :

| Role | Permissions |
|---|---|
| super_admin | Tous les acces (y compris finance) |
| finance_admin | view_cases, view_finance, export_finance |

Le role `finance_admin` ne permet PAS :
- Modification utilisateurs
- Actions ops (assign, resolve, snooze)
- Feature flags
- Modification connecteurs

Fichiers modifies : `src/types/index.ts`, `src/config/rbac.ts`, `src/features/users/constants.ts`

---

## 2. Audit des tables financieres

| Table | Colonnes | Lignes | Donnees disponibles |
|---|---|---|---|
| billing_subscriptions | tenant_id, stripe_subscription_id, plan, billing_cycle, channels_included, channels_addon_qty, status, current_period_end, updated_at | 3 | Plans (PRO), statuts (active), cycles, canaux |
| billing_events | id, tenant_id, event_type, stripe_event_id, payload, processed, error_message, created_at | 61 | checkout.session.completed, invoice.*, customer.* |
| billing_customers | tenant_id, stripe_customer_id, email, created_at | 3 | Mapping tenant-Stripe |
| ai_actions_wallet | tenant_id, remaining, purchased_remaining, included_monthly, reset_at, updated_at | 3 | Solde KBA, inclusion mensuelle |
| ai_actions_ledger | id, tenant_id, delta, reason, request_id, conversation_id, created_at, kb_actions, cost_usd, decision_context | 275 | Historique consommation detaille |
| ai_budget_settings | tenant_id, monthly_cap_usd, alert_*_enabled, alert_*_sent_at, credits_enabled, updated_at | 3 | Caps budget, alertes |
| tenant_billing_exempt | tenant_id, exempt, reason, created_at | 1 | Tenants exemptes |

**Total** : 349 lignes de donnees reelles. Aucune donnee inventee.

---

## 3. Metriques calculees (reelles uniquement)

| Metrique | Source | Description |
|---|---|---|
| Abonnements actifs | billing_subscriptions WHERE status='active' | Nombre tenants avec abo actif |
| Abonnements trial | billing_subscriptions WHERE status='trialing' | Nombre tenants en essai |
| Tenants exempts | tenant_billing_exempt WHERE exempt=true | Tenants sans facturation |
| KBActions consommes | SUM(ABS(delta)) FROM ai_actions_ledger WHERE delta < 0 | Total consomme |
| KBActions restants | SUM(remaining + purchased_remaining) FROM ai_actions_wallet | Solde global |
| Billing events 7j | COUNT(*) FROM billing_events WHERE created_at > NOW()-7d | Activite recente |

**Note** : Aucun MRR/ARR calcule — les donnees ne contiennent pas de prix unitaire par plan. Seuls les metriques fiables sont affichees.

---

## 4. API Finance

| Route | Methode | Description | RBAC |
|---|---|---|---|
| /api/admin/finance/overview | GET | KPI + alertes finance | super_admin, finance_admin |
| /api/admin/finance/subscriptions | GET | Tableau abonnements (JOIN customers + exempt) | super_admin, finance_admin |
| /api/admin/finance/usage | GET | Usage KBActions par tenant (wallet + ledger + budget) | super_admin, finance_admin |
| /api/admin/finance/events | GET | 50 derniers billing events | super_admin, finance_admin |
| /api/admin/finance/export | GET | Export CSV ou JSON (subscriptions, usage, events) | super_admin, finance_admin |

---

## 5. Page /finance

### Onglet 1 — Vue globale
- 4 KPI : abonnements actifs, trials, exempts, tenants IA
- 3 KPI complementaires : KBA consommes, KBA restants, billing events 7j
- Panneau alertes finance (sans abo, KBA < 20%, periode expiree, exempt)

### Onglet 2 — Abonnements
- Tableau 7 colonnes avec recherche et tri
- Badges plan (PRO/STARTER/AUTOPILOT) et statut (active/trialing/canceled)
- Marquage EXEMPT visible

### Onglet 3 — Usage KBActions
- Carte par tenant avec : restant, inclus/mois, consomme total, consomme 30j
- Barre de progression coloree (vert < 50%, orange < 80%, rouge > 80%)
- Indicateurs cap budget et alertes

### Onglet 4 — Evenements
- Tableau 5 colonnes : tenant, type, statut (OK/Pending), erreur, date
- Limite 50 evenements

### Footer
- Mention explicite : "Toutes les metriques proviennent des tables reelles. Aucune donnee inventee."

---

## 6. Export

| Section | Formats | Colonnes |
|---|---|---|
| subscriptions | CSV, JSON | tenant_id, plan, status, billing_cycle, channels_included, channels_addon_qty, current_period_end, updated_at, stripe_customer_id, customer_email, is_exempt |
| usage | CSV, JSON | tenant_id, remaining, purchased_remaining, included_monthly, total_consumed, recent_consumed, monthly_cap_usd, budget_alerts_enabled |
| events | CSV, JSON | id, tenant_id, event_type, stripe_event_id, processed, error_message, created_at |

---

## 7. Non-regression client

| Service | Namespace | Statut |
|---|---|---|
| client-dev.keybuzz.io | keybuzz-client-dev | Running |
| client.keybuzz.io | keybuzz-client-prod | Running |
| api-dev | keybuzz-api-dev | Running |
| api-prod | keybuzz-api-prod | Running |
| admin-dev | keybuzz-admin-v2-dev | Running |
| admin-prod | keybuzz-admin-v2-prod | Running |

Aucun pod impacte. Aucune modification aux pipelines existants.

---

## 8. Fichiers crees ou modifies

| Fichier | Action |
|---|---|
| src/types/index.ts | MODIFIE — Ajout finance_admin dans AdminRole |
| src/config/rbac.ts | MODIFIE — Permissions view_finance, export_finance |
| src/features/users/constants.ts | MODIFIE — ROLE_HIERARCHY + ROLE_LABELS |
| src/features/finance/finance.service.ts | CREE — Service (overview, subscriptions, usage, events, alerts) |
| src/app/api/admin/finance/overview/route.ts | CREE |
| src/app/api/admin/finance/subscriptions/route.ts | CREE |
| src/app/api/admin/finance/usage/route.ts | CREE |
| src/app/api/admin/finance/events/route.ts | CREE |
| src/app/api/admin/finance/export/route.ts | CREE |
| src/app/(admin)/finance/page.tsx | CREE — Dashboard 4 tabs |
| src/config/navigation.ts | MODIFIE — Ajout Finance |
| src/components/layout/Sidebar.tsx | MODIFIE — Ajout TrendingUp |

---

## 9. Rollback

```bash
kubectl set image deployment/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin-v2:v0.21.0-ph87.5a-ai-evaluations -n keybuzz-admin-v2-dev
kubectl set image deployment/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin-v2:v0.21.0-ph87.5a-ai-evaluations -n keybuzz-admin-v2-prod
```
