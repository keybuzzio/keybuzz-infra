# PH-ADMIN-87.13 — Global Control Center

**Date** : 2026-03-04
**Version** : v2.8.0
**Statut** : TERMINE

---

## 1. Resume executif

Le dashboard admin est transforme en **Control Center global temps reel**.
Il agrege les donnees de toutes les sources DB pour offrir une vue multi-tenant instantanee :
KPIs globaux, incidents, timeline, top tenants.

Le dashboard est desormais la page d'accueil admin — le "cerveau visuel" de KeyBuzz.

---

## 2. APIs creees

| Endpoint | Role | Donnees |
|---|---|---|
| `GET /api/admin/global/overview` | KPIs globaux | tenants, conversations, IA, queues, erreurs, billing, flags, incidents |
| `GET /api/admin/global/incidents` | Incidents actifs | emails fails, incidents IA, incidents DB, backlog queue |
| `GET /api/admin/global/timeline` | Timeline multi-sources | deliveries, ai_action_log, billing_events, audit_logs |

---

## 3. Sources DB agregees

| Source | Donnee |
|---|---|
| `tenants` | Total/actifs |
| `conversations` | Open count |
| `messages` | Last 24h count |
| `ai_action_log` | Actions 24h + total |
| `ai_actions_ledger` | Cout USD total ($0.87) |
| `ai_human_approval_queue` | Pending count |
| `outbound_deliveries` | Failed count + timeline |
| `billing_subscriptions` | Active count |
| `billing_events` | Total + timeline |
| `feature_flags` | Active/total |
| `incidents` | Active incidents |
| `ai_execution_incidents` | Incidents IA non resolus |
| `audit_logs` | Timeline audit |

---

## 4. Validation PROD

### KPIs affiches (11 StatCards)

| KPI | Valeur | Source DB |
|---|---|---|
| Tenants actifs | **3** | `tenants WHERE status='active'` |
| Conversations ouvertes | **136** | `conversations WHERE status='open'` |
| Actions IA (24h) | 0 | `ai_action_log WHERE created_at > now()-24h` |
| Messages (24h) | **1** | `messages WHERE created_at > now()-24h` |
| Abonnements actifs | **1** | `billing_subscriptions WHERE status='active'` |
| Emails echoues | **1** | `outbound_deliveries WHERE status='failed'` |
| Approbations en attente | **2** | `ai_human_approval_queue WHERE queue_status='OPEN'` |
| Incidents actifs | 0 | `incidents WHERE status IN ('open','investigating')` |
| Cout IA total | **$0.87** | `SUM(cost_usd) FROM ai_actions_ledger` |
| Feature flags actifs | **6/11** | `feature_flags` |
| Actions IA total | **48** | `COUNT(*) FROM ai_action_log` |

### Incidents & Alertes (1)

| Type | Message | Tenant | Severite |
|---|---|---|---|
| EMAIL_FAILED | Unknown provider: SMTP | ecomlg-001 | warning |

### Timeline (15 entrees)

- Livraisons amazon (delivered) — ecomlg-001
- Billing: customer.subscription.created, invoice.paid, checkout.session.completed
- IA: AI_DECISION_TRACE — completed — ecomlg-001

### Top Tenants (3)

| Tenant | Plan | Conv. ouvertes | Actions IA | Echecs |
|---|---|---|---|---|
| eComLG | pro | 136 | 48 | 1 |
| SWITAA SASU | STARTER | 0 | 0 | 0 |
| SWITAA SASU | starter | 0 | 0 | 0 |

---

## 5. Fichiers crees/modifies

| Fichier | Action |
|---|---|
| `src/app/(admin)/page.tsx` | Reecrit (Control Center complet) |
| `src/app/api/admin/global/overview/route.ts` | Nouveau |
| `src/app/api/admin/global/incidents/route.ts` | Nouveau |
| `src/app/api/admin/global/timeline/route.ts` | Nouveau |
| `src/features/users/services/users.service.ts` | 4 methodes ajoutees |
| `src/features/users/types.ts` | 4 types ajoutes |
| `src/config/navigation.ts` | Dashboard → Control Center |
| `src/components/layout/Sidebar.tsx` | Version v2.8.0 |

---

## 6. UI — Sections du Control Center

| Section | Contenu |
|---|---|
| KPIs globaux | 11 StatCards sur 3 rangees |
| Incidents & Alertes | Liste scrollable avec severite + lien tenant |
| Activite recente | Timeline 15 entrees avec badges type (Livraison/IA/Billing/Audit) |
| Tenants — Vue globale | Tableau avec nom, plan, conv. ouvertes, actions IA, echecs, lien cockpit |
| Actualiser | Bouton rafraichissement avec animation spin |

---

## 7. Deploiement

| Element | Valeur |
|---|---|
| Commit | `42ea337` |
| Tag DEV | `v2.8.0-ph-admin-87-13-dev` |
| Tag PROD | `v2.8.0-ph-admin-87-13-prod` |
| Digest DEV | `sha256:c33948ccba41433eafafbb3d6e5c6a854684e7a9ac39c65ef2ca4b7dca5b448d` |
| Digest PROD | `sha256:7ba16aa64cc712452ed301d824f56daf2278a371c70e2542087a7b244a12d80a` |
| Version runtime | v2.8.0 |

---

## 8. Rollback

### DEV
```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.7.3-ph-admin-87-12d-dev \
  -n keybuzz-admin-v2-dev
```

### PROD
```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.7.3-ph-admin-87-12d-prod \
  -n keybuzz-admin-v2-prod
```

---

## 9. Zero violations

- Zero mock : toutes les donnees viennent de PostgreSQL
- Zero hardcode : requetes parametrees
- Zero KPI fake : chaque chiffre correspond a une requete DB reelle
- Zero Failed to fetch : toutes les APIs repondent
- Multi-tenant : toutes les donnees agreges tous les tenants
- Timeline reelle : outbound_deliveries + ai_action_log + billing_events + audit_logs
- Incidents reels : emails failed + ai_execution_incidents + incidents DB
