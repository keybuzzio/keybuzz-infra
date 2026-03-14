# PH-ADMIN-86.9A — Billing & Usage Control — Rapport

**Date** : 2026-03-14
**Image** : `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.15.0-ph86.9a-billing-usage`
**Statut** : DEV + PROD deploye

---

## 1. Audit des sources billing/usage

### Tables exploitees (9 tables)

| Table | Lignes | Exploitation |
|---|---|---|
| `tenants` | 6 | Plan, statut, identite |
| `billing_customers` | 3 | Clients Stripe |
| `billing_subscriptions` | 3 | Souscriptions (plan, cycle, channels, statut) |
| `billing_events` | 61 | Evenements Stripe webhooks |
| `ai_actions_wallet` | 3 | Solde KBActions (remaining, included, reset) |
| `ai_actions_ledger` | 275 | Journal de consommation KBActions |
| `tenant_billing_exempt` | 1 | Tenants exemptes de facturation |
| `ai_budget_settings` | 3 | Caps mensuels et alertes budget |
| `ai_budget_alerts` | 3 | Alertes budgetaires declenchees |

### Donnees reelles en DEV

- 6 tenants (4 PRO, 1 pro, 1 free)
- 3 souscriptions (1 active, 2 trialing)
- 3 wallets KBActions (ecomlg-001: 6.43 restants / 1000 inclus)
- 61 events billing (Stripe webhooks)
- 275 lignes ledger KBActions
- 1 tenant exempt (ecomlg-001, raison: internal_admin)
- 3 budget settings (ecomlg-001 cap $50/mois)

### Non disponible

- MRR / ARR (pas de table dediee)
- Revenue par tenant (pas de table)
- Historique factures (pas de table)
- Metriques Stripe avancees (pas d'API Stripe depuis admin)

---

## 2. Service backend

**Fichier** : `src/features/billing/billing.service.ts`

### 5 methodes

| Methode | Description | Tables |
|---|---|---|
| `getOverview()` | 8 KPI globaux | tenants, billing_subscriptions, billing_events, ai_actions_ledger, tenant_billing_exempt |
| `getTenantsBilling()` | Donnees billing par tenant | tenants, billing_subscriptions, ai_actions_wallet, tenant_billing_exempt, ai_actions_ledger, billing_events |
| `getRecentEvents(limit)` | Derniers events billing | billing_events, tenants |
| `getUsageSummary()` | Usage KBActions par tenant | ai_actions_wallet, tenants, ai_budget_settings, ai_actions_ledger |
| `getAlerts(tenants)` | Detection anomalies/alertes | Calcule depuis getTenantsBilling |

### Alertes detectees automatiquement

- Plan non-free sans souscription active (hors exempt)
- KBActions usage >= 90% (danger)
- KBActions usage >= 70% (warning)
- Tenant exempt (info)

### Resilience

- `safeQuery()` wrapper pour tables manquantes
- Chaque requete independante, echec isole

---

## 3. Route API

**Route** : `GET /api/admin/billing`

**RBAC** : `super_admin`, `ops_admin`, `account_manager`

**Reponse** :
```json
{
  "data": {
    "overview": { "totalTenants", "withSubscription", "activeSubscriptions", "trialSubscriptions", "exemptTenants", "totalBillingEvents", "recentEventsCount", "totalKbaConsumed" },
    "tenants": [{ "tenant_id", "tenant_name", "plan", "subscription_status", "kba_remaining", "kba_included", "kba_consumed", "exempt", "last_billing_event", ... }],
    "events": [{ "id", "tenant_id", "tenant_name", "event_type", "processed", "has_error", "created_at" }],
    "usage": [{ "tenant_id", "tenant_name", "kba_remaining", "kba_included", "kba_consumed", "usage_percent", "monthly_cap_usd", "credits_enabled" }],
    "alerts": [{ "type", "message", "tenant_id", "tenant_name" }]
  }
}
```

---

## 4. Page `/billing`

### Layout — 4 sections

1. **KPI** — 4 StatCards :
   - Tenants (total)
   - Souscriptions actives (+ essai en trend)
   - Events billing 7j (+ total en trend)
   - KBActions consommes (+ exempt en trend)

2. **Alertes billing** — `BillingAlertsPanel`
   - Alertes danger (usage critique)
   - Alertes warning (plan sans souscription, usage eleve)
   - Alertes info (tenant exempt)
   - Aucune alerte = badge vert

3. **Usage KBActions** — `UsageSummaryPanel`
   - Cartes par tenant avec barre de progression
   - Pourcentage d'usage colore (vert/amber/rouge)
   - Remaining / included / consumed
   - Cap mensuel + credits si configures

4. **Billing par tenant** — `BillingTenantTable`
   - Tableau complet avec recherche et filtre plan
   - Plan, souscription, KBActions, channels, dernier event
   - Barre de progression KBActions
   - Badge exempt
   - Navigation vers `/tenants/[id]`

5. **Events billing recents** — `BillingEventList`
   - 50 derniers events avec labels lisibles
   - Statut traite/en attente
   - Tenant lie
   - Icone succes/erreur

---

## 5. Composants UI crees

| Composant | Description |
|---|---|
| `BillingTenantTable` | Tableau billing par tenant avec recherche, filtre, barres |
| `BillingEventList` | Liste events billing avec labels et statut |
| `UsageSummaryPanel` | Cartes usage KBActions avec progression |
| `BillingAlertsPanel` | Panneau alertes avec 3 niveaux (danger/warning/info) |

---

## 6. Navigation

Entree existante dans la sidebar : **"Facturation"** (`/billing`, icone `CreditCard`), section Supervision.

---

## 7. RBAC

| Role | Acces |
|---|---|
| `super_admin` | Complet |
| `ops_admin` | Complet |
| `account_manager` | Complet |
| Autres roles | Bloque (403) |

---

## 8. Non-regression

| Verification | Resultat |
|---|---|
| `client-dev.keybuzz.io` | 307 OK |
| `client.keybuzz.io` | 307 OK |
| Aucune modification backend API | Confirme |
| Aucune modification Stripe | Confirme |

---

## 9. Deploiement

| Env | Image | Statut |
|---|---|---|
| DEV | `v0.15.0-ph86.9a-billing-usage` | 1/1 Running |
| PROD | `v0.15.0-ph86.9a-billing-usage` | 1/1 Running |

---

## 10. Limitations

- Pas de MRR/ARR (pas de table dediee)
- Pas d'historique factures (pas de table)
- Pas d'API Stripe directe depuis admin
- Les billing_events n'ont pas toujours un tenant_id renseigne
- Pas de graphe timeline billing (pas assez de donnees temporelles structurees)
