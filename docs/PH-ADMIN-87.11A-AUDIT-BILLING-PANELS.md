# PH-ADMIN-87.11A — Audit & Billing Real Panels

## 1. Resume executif

### Ce qui a ete ajoute
| Composant | Description |
|---|---|
| `GET /api/admin/tenants/[id]/audit` | Endpoint agrege : actions admin + evenements IA + execution audits + notifications |
| `GET /api/admin/tenants/[id]/billing` | Endpoint agrege : subscription, wallet KBA, credits USD, ledger, events |
| Page `/audit` reelle | Actions admin, evenements IA, timeline chronologique, tenant-aware |
| Page `/billing` reelle | Abonnement, wallet KBA, credits USD, historique consommation, tenant-aware |
| Liens cockpit | "Audit du tenant" et "Facturation du tenant" dans les acces rapides |

### Ce qui est visible depuis le cockpit
- Lien "Audit du tenant" → `/audit?tenantId=<id>` avec donnees reelles
- Lien "Facturation du tenant" → `/billing?tenantId=<id>` avec donnees reelles
- `TenantFilterBanner` avec "Retour au cockpit tenant" sur chaque page

### Ce qui reste non branche
- `billing_events.tenant_id` est toujours null en DB → events Stripe non filtrables par tenant
- `notifications` table existe mais 0 donnees en PROD
- `incident_*` tables existent mais non exploitees (pas de donnees significatives)

---

## 2. Cartographie des sources reelles

| Domaine | Table | Tenant-scope | Donnees PROD | Utilisable |
|---|---|---|---|---|
| Admin actions | `admin_actions_log` | Oui | 14 lignes | Oui |
| IA actions | `ai_action_log` | Oui | 48 (ecomlg-001) | Oui |
| IA execution | `ai_execution_audit` | Oui | 7 (ecomlg-001) | Oui |
| Notifications | `notifications` | Oui | 0 (vide) | Empty state |
| Incidents | `incident_events/incidents` | A verifier | Non exploite | Non |
| KBA Wallet | `ai_actions_wallet` | Oui | 3 tenants | Oui |
| KBA Ledger | `ai_actions_ledger` | Oui | 68 (ecomlg-001), 7 (switaa) | Oui |
| Credits USD | `ai_credits_wallet` | Oui | 2 tenants | Oui |
| Subscriptions | `billing_subscriptions` | Oui | 3 tenants | Oui |
| Billing events | `billing_events` | Non (tenant_id=null) | 82 events | Non filtrable |

---

## 3. Endpoints operations

### GET /api/admin/tenants/[id]/audit
```json
{
  "data": {
    "admin_actions": [...],
    "admin_actions_total": 0,
    "ai_events": [...],
    "ai_events_total": 48,
    "execution_audits_total": 7,
    "notifications_total": 0
  }
}
```

### GET /api/admin/tenants/[id]/billing
```json
{
  "data": {
    "subscription": { "plan": "PRO", "status": "active", ... },
    "wallet": { "remaining": 451, "included_monthly": 1000, ... },
    "credits": { "balance_usd": 116.00, ... },
    "ledger": { "total_entries": 68, "total_kba": 653.8, "total_cost_usd": 0.86, "recent": [...] },
    "events_total": 0
  }
}
```

---

## 4. UI cockpit

### Page /audit
- **StatCards** : Actions admin, Evenements IA, Execution audits, Notifications
- **Section Actions admin** : Table avec action, acteur, details metadata, date
- **Section Evenements IA** : Table avec type, statut, resume, score confiance, date
- **Section Chronologie** : Timeline fusionnee admin+IA triee par date
- **Empty states** : "Aucune action admin" / "Aucun evenement IA" / "Aucune activite enregistree"
- **Sans tenantId** : "Selectionnez un tenant"

### Page /billing
- **StatCards** : Plan, KBA restants, KBA consommes, Cout total IA
- **Section Abonnement** : Plan, statut, cycle, channels, Stripe ID, fin de periode
- **Section Wallet KBActions** : Restants/Inclus/Achetes, barre de progression, reset date, credits USD
- **Section Historique consommation** : Table avec date, raison, KBA, cout USD, conversation
- **Empty states** : "Pas d'abonnement" / "Pas de wallet" / "Aucune consommation"

### Navigation tenant-aware (cockpit)
- `/audit?tenantId=<id>` — "Audit du tenant"
- `/billing?tenantId=<id>` — "Facturation du tenant"
- `/queues?tenantId=<id>` — deja existant
- `/approvals?tenantId=<id>` — deja existant
- `/users?tenantId=<id>` — deja existant

---

## 5. Preuve DB → API → UI → Navigation

### PROD — ecomlg-001 (tenant riche)

| Section | Donnees reelles |
|---|---|
| Audit - Actions admin | 0 (pas d'actions directes sur ce tenant) |
| Audit - Evenements IA | 48 |
| Audit - Execution audits | 7 |
| Billing - Plan | — (pas d'abonnement Stripe pour ce tenant en PROD) |
| Billing - KBA restants | 451 |
| Billing - KBA consommes | 654 |
| Billing - Cout total IA | $0.86 |
| Billing - Historique | 68 entrees, 653.8 KBA |
| Billing - Wallet | 451/1000 restants |
| Navigation | TenantFilterBanner avec "Retour au cockpit tenant" |

### PROD — switaa-sasu-mmazd2rd (tenant avec peu d'activite)

| Section | Donnees reelles |
|---|---|
| Audit - Actions admin | 0 — "Aucune action admin" |
| Audit - Evenements IA | 0 — "Aucun evenement IA" |
| Audit - Chronologie | "Aucune activite enregistree" |
| Billing - Plan | PRO |
| Billing - Statut | canceled |
| Billing - KBA restants | 1000 |
| Billing - KBA consommes | 0 |
| Billing - Cout total IA | $0.00 |
| Billing - Historique | 7 entrees (plan_change_trial, subscription_canceled) |
| Navigation | TenantFilterBanner fonctionnel |

---

## 6. Deploiement

| Element | Valeur |
|---|---|
| Commit SHA feat | `de3d0b8deea20fc185957ced6fc9cc52a35330ac` |
| Commit SHA fix1 | `362518944254881b4fcfd89c0c44a0c9d74cacef` |
| Commit SHA fix2 | `468dc4ca4ff0ac89e907f9ffc6243358418cbb75` |
| Tag DEV | `v2.5.0-ph-admin-87-11a-fix2-dev` |
| Tag PROD | `v2.5.0-ph-admin-87-11a-fix2-prod` |
| Digest | `sha256:e22bde68efc617e9e16e84e8548a535247b57f2ad782a981ca85b30fbb182542` |
| Version runtime | v2.5.0 |
| Fichiers modifies | 8 fichiers, 2 nouveaux (routes API) |

---

## 7. Rollback

### DEV
```bash
kubectl set image deployment/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.4.0-ph-admin-87-10d-dev -n keybuzz-admin-v2-dev
kubectl rollout restart deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-dev
```

### PROD
```bash
kubectl set image deployment/keybuzz-admin-v2 keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.4.0-ph-admin-87-10d-prod -n keybuzz-admin-v2-prod
kubectl rollout restart deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod
```

---

## 8. Dettes restantes

| ID | Description | Priorite |
|---|---|---|
| D1 | `billing_events.tenant_id` toujours null — webhook Stripe ne propage pas le tenant | Haute |
| D2 | `notifications` table vide — systeme de notifications pas encore alimente | Moyenne |
| D3 | `incident_*` tables non exploitees — pas assez de donnees pour un panneau utile | Basse |
| D4 | Historique consommation KBA avec entrees `plan_change_trial` (kb_actions=null) — entries administratives melangees aux consommations reelles | Basse |
| D5 | Page `/audit` sans tenantId affiche "Selectionnez un tenant" — pourrait afficher un audit global cross-tenant | Moyenne |
