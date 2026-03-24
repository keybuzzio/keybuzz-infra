# PH-ADMIN-87.10A — Tenant Cockpit Operational Data & Actions

**Date** : 4 mars 2026
**Auteur** : CE (Cursor Executor)
**Phase** : PH-ADMIN-87.10A
**Verdict** : **GO — ADMIN v2.1.9 VALIDÉ DEV + PROD**

---

## 1. Résumé exécutif

### Ce qui a été ajouté
- **Endpoint cockpit** : `GET /api/admin/tenants/[id]/cockpit` — agrège en une seule requête les données réelles du tenant
- **Page cockpit** : `/tenants/[id]` transformée d'une simple fiche d'identité en cockpit opérationnel complet
- **6 sections de données réelles** : Identité, Opérations, Intelligence IA, Utilisateurs admin, Abonnement, Accès rapides
- **4 KPI réels** en bandeau : Conversations, Ouvertes, Messages, Playbooks IA actifs/total
- **3 mini-KPI opérationnels** : Ouvertes, Résolues, En attente (breakdown conversation status)
- **5 accès rapides** : liens directs vers Ops Center, Queues, Utilisateurs, AI Control, Facturation

### Ce qui est maintenant pilotable par tenant
- Activité conversationnelle (total, statut, channels, dernière activité)
- Intelligence IA (playbooks, crédits, actions exécutées)
- Abonnement Stripe (plan, statut, cycle, channels inclus)
- Utilisateurs admin liés

### Ce qui reste non disponible (honnêtement)
- Connecteurs Amazon/inbound : tables pas dans la DB admin (DB API séparée)
- Agents/équipes : tables existent mais vides
- Notifications/audit_logs/incidents : tables existent mais vides
- AI evaluations : table existe mais vide
- Follow-ups : table existe mais vide

---

## 2. Audit des sources réelles

### Tables tenant-scopées identifiées : 72+

| Domaine | Table(s) | Données DEV | Données PROD | Exploité dans cockpit |
|---|---|---|---|---|
| Conversations | `conversations` | ecomlg: 261, switaa-sasu: 3 | ecomlg: 269 | **OUI** — total, status, channels, last_activity |
| Messages | `messages` | ecomlg: 830, switaa-sasu: 4 | ecomlg: 863 | **OUI** — total |
| AI Playbooks | `ai_rules` | 13 tenants × 15 rules (0 actives) | 8 tenants × 15 rules | **OUI** — total, actifs |
| Crédits IA | `ai_credits_wallet` | ecomlg: $116/$150, 9 tenants | Non disponible | **OUI** — balance, initial, updated_at |
| Actions IA | `ai_actions_ledger` | 282 entrées total | À vérifier | **OUI** — count, total_cost |
| Abonnement | `billing_subscriptions` | 6 tenants | 3 tenants | **OUI** — plan, status, cycle, channels, Stripe ID |
| Admin users | `admin_user_tenants` | 8 lignes | 0 lignes | **OUI** — liste, email, rôle, lien /users/[id] |
| Space invites | `space_invites` | ecomlg: 9 | — | Non (priorité basse) |
| Cancel reasons | `cancel_reasons` | ecomlg: 1 | — | Non (priorité basse) |
| Agents | `agents` | 0 rows | 0 rows | Non (vide) |
| Teams | `teams` | 0 rows | 0 rows | Non (vide) |
| Notifications | `notifications` | 0 rows | — | Non (vide) |
| Audit logs | `audit_logs` | 0 rows | — | Non (vide) |
| AI evaluations | `ai_evaluations` | 0 rows | — | Non (vide) |
| Followups | `ai_followup_cases` | 0 rows | — | Non (vide) |
| Inbound | `inbound_connections` | TABLE NOT FOUND | TABLE NOT FOUND | Non (DB séparée) |
| Integrations | `integrations` | TABLE NOT FOUND | TABLE NOT FOUND | Non (DB séparée) |

### Schema clés utilisés

**ai_credits_wallet** :
- `tenant_id` (PK), `balance_usd` (numeric), `lifetime_credits_usd` (numeric), `updated_at`

**billing_subscriptions** :
- `tenant_id` (PK), `plan` (STARTER/PRO/AUTOPILOT/ENTERPRISE), `status` (active/trialing/past_due/canceled/incomplete/incomplete_expired), `billing_cycle`, `channels_included`, `stripe_subscription_id`, `current_period_end`

---

## 3. API cockpit

### `GET /api/admin/tenants/[id]/cockpit`

Requiert `super_admin`. Retourne toutes les données agrégées en un appel.

**Payload réel (ecomlg-001 DEV)** :
```json
{
  "data": {
    "tenant": {
      "id": "ecomlg-001", "name": "eComLG", "plan": "pro",
      "status": "active", "admin_user_count": 0
    },
    "admins": [],
    "ops": {
      "conversations_total": 261,
      "conversations_open": 182,
      "conversations_resolved": 71,
      "conversations_pending": 8,
      "messages_total": 830,
      "channels": { "amazon": 259, "email": 2 },
      "last_activity_at": "2026-03-21 11:35:23+00"
    },
    "ai": {
      "playbooks_total": 15, "playbooks_active": 0,
      "credits_balance_usd": 116.0, "credits_lifetime_usd": 150.0,
      "ledger_actions_count": 282, "ledger_total_cost_usd": 0
    },
    "billing": {
      "subscription_plan": "PRO", "subscription_status": "active",
      "billing_cycle": "monthly", "channels_included": 1,
      "stripe_subscription_id": "manual_seed_initial"
    }
  }
}
```

### Sections exposées
| Section | Source | Données |
|---|---|---|
| `tenant` | `tenants` | Identité complète |
| `admins` | `admin_user_tenants` + `admin_users` | Liste admin users liés |
| `ops` | `conversations` + `messages` | KPI conversations + messages |
| `ai` | `ai_rules` + `ai_credits_wallet` + `ai_actions_ledger` | Playbooks + crédits + usage |
| `billing` | `billing_subscriptions` | Abonnement Stripe |

---

## 4. UI cockpit

### Structure de la page `/tenants/[id]`

**Header** :
- Bouton "Retour à la liste"
- Bouton "Actualiser"
- Nom du tenant (H1) + ID (mono) + badges Plan + Statut

**Bandeau KPI (4 StatCards)** :
- Conversations | Ouvertes | Messages | Playbooks IA (actifs/total)

**Grille 2 colonnes** :

| Colonne 1 | Colonne 2 |
|---|---|
| **Informations** — ID, nom, plan, statut, domaine, dates | **Utilisateurs admin (N)** — table email/rôle/date + lien /users/[id] |
| **Opérations** — 3 mini-KPI (open/resolved/pending), messages, channels badges, dernière activité | **Abonnement** — plan badge, statut badge, cycle, channels, Stripe ID |
| **Intelligence IA** — playbooks total/actifs, crédits IA balance/initial, actions exécutées | **Accès rapides** — 5 liens (Ops, Queues, Users, AI Control, Facturation) |

### Empty states honnêtes
- "Aucune conversation pour ce tenant"
- "Aucun portefeuille de crédits IA pour ce tenant"
- "Aucun utilisateur admin lié à ce tenant"
- "Aucun abonnement Stripe pour ce tenant"

### Zéro placeholder, zéro mock, zéro fake

---

## 5. Preuve DB → API → UI

### DEV — ecomlg-001

| Donnée | DB | API cockpit | UI visible |
|---|---|---|---|
| Conversations | 261 (182 open, 71 resolved, 8 pending) | `conversations_total: 261` | **261** Conversations, **182** Ouvertes |
| Messages | 830 | `messages_total: 830` | **830** Messages |
| Playbooks | 15 total, 0 actifs | `playbooks_total: 15, active: 0` | **0/15** Playbooks IA |
| Crédits IA | $116 / $150 | `credits_balance_usd: 116.0` | Affiché dans section IA |
| Abonnement | PRO, active | `subscription_plan: PRO` | Badge PRO, badge active |
| Admin users | 0 | `admins: []` | "Aucun utilisateur admin lié" |
| Channels | amazon: 259, email: 2 | `channels: {amazon: 259, email: 2}` | Badges amazon (259), email (2) |

### PROD — ecomlg-001

| Donnée | DB | API cockpit | UI visible |
|---|---|---|---|
| Conversations | 269 (135 open, 123 resolved, 11 pending) | `conversations_total: 269` | **269** Conversations, **135** Ouvertes |
| Messages | 863 | `messages_total: 863` | **863** Messages |
| Playbooks | 15 total, 0 actifs | `playbooks_total: 15, active: 0` | **0/15** Playbooks IA |
| Abonnement | Non présent | `billing: null` | "Aucun abonnement Stripe pour ce tenant" |
| Admin users | 0 | `admins: []` | "Aucun utilisateur admin lié" |

### PROD — encoreuntest-mmyuu5hf (second tenant)

| Donnée | DB | API cockpit | UI visible |
|---|---|---|---|
| Conversations | 0 | `conversations_total: 0` | **0** + "Aucune conversation" |
| Messages | 0 | `messages_total: 0` | **0** |
| Playbooks | 15 total, 0 actifs | `playbooks_total: 15, active: 0` | **0/15** |
| Abonnement | PRO, trialing | `subscription_plan: PRO, status: trialing` | Données billing affichées |
| Admin users | 0 | `admins: []` | "Aucun utilisateur admin lié" |

---

## 6. Déploiement

| | DEV | PROD |
|---|---|---|
| **Commit SHA** | `73666aef5e78203e394a10a50cdc384cd3c77151` | idem (même source) |
| **Image tag** | `v2.1.9-ph-admin-87-10a-dev` | `v2.1.9-ph-admin-87-10a-prod` |
| **Image digest** | `sha256:fe28c5fbe25f279d1fc3e67019dc99ce62f609aac3269f7c4991bcdae701a05f` | `sha256:fe28c5fbe25f279d1fc3e67019dc99ce62f609aac3269f7c4991bcdae701a05f` |
| **Pod** | `keybuzz-admin-v2-568d6c8959-hhlk2` | `keybuzz-admin-v2-6cbd9c7bc7-vx7dk` |
| **Namespace** | `keybuzz-admin-v2-dev` | `keybuzz-admin-v2-prod` |
| **Version sidebar** | v2.1.9 | v2.1.9 |
| **Image précédente** | `v2.1.8-ph-admin-87-9a-dev` | `v2.1.8-ph-admin-87-9a-prod` |

---

## 7. Rollback

### DEV
```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.1.8-ph-admin-87-9a-dev \
  -n keybuzz-admin-v2-dev
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-dev
```

### PROD
```bash
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin:v2.1.8-ph-admin-87-9a-prod \
  -n keybuzz-admin-v2-prod
kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-prod
```

---

## 8. Fichiers modifiés

| Fichier | Action |
|---|---|
| `src/features/users/types.ts` | Ajout types cockpit (TenantCockpitOps, AI, Billing, Data) |
| `src/features/users/services/users.service.ts` | Ajout méthodes cockpit (getTenantCockpitOps, AI, Billing) |
| `src/app/api/admin/tenants/[id]/cockpit/route.ts` | **Nouveau** — endpoint cockpit agrégé |
| `src/app/(admin)/tenants/[id]/page.tsx` | Réécrit — cockpit opérationnel complet |
| `src/components/layout/Sidebar.tsx` | Version v2.1.8 → v2.1.9 |

---

## 9. Dettes restantes

| ID | Description | Criticité | Phase |
|---|---|---|---|
| D1 | Connecteurs (inbound_connections, integrations) pas dans la DB admin — tables dans la DB API | Basse | À réévaluer quand module Connectors sera implémenté |
| D2 | Tables agents/teams vides — aucune donnée à afficher | Info | Se remplira quand la gestion agents sera utilisée |
| D3 | audit_logs, notifications, incidents vides — aucune donnée tenant-scopée | Info | Se remplira naturellement avec l'usage |
| D4 | ai_evaluations vides | Info | Se remplira avec l'usage IA |
| D5 | ai_credits_wallet absent en PROD | Moyen | Lié à l'absence de seed wallet pour les tenants PROD |
| D6 | ecomlg-001 en PROD n'a pas d'entrée billing_subscriptions | Moyen | Incohérence à investiguer |
| D7 | Accès rapides non filtrés par tenant (liens vers modules globaux) | Bas | Filtrage tenant nécessiterait des query params tenant-aware |
| D8 | Version hardcodée dans Sidebar.tsx au lieu de variable d'env | Bas | Tech debt existante |

---

## 10. Validation navigateur

### DEV (admin-dev.keybuzz.io)
- Login : OK (ludovic@keybuzz.pro)
- Version sidebar : **v2.1.9** ✓
- `/tenants/ecomlg-001` : Cockpit complet, 261 conversations, 830 messages, 0/15 playbooks, 182 ouvertes, 71 résolues, 8 en attente ✓
- Sections Informations, Opérations, Intelligence IA, Admin users, Abonnement (PRO/active), Accès rapides : toutes présentes ✓
- `/users/new` : 11 tenants réels (régression check) ✓

### PROD (admin.keybuzz.io)
- Login : OK (ludovic@keybuzz.pro)
- Version sidebar : **v2.1.9** ✓
- `/tenants/ecomlg-001` : 269 conversations, 863 messages, 0/15 playbooks, 135 ouvertes, 123 résolues, 11 en attente ✓
- Abonnement : "Aucun abonnement Stripe" (correct, pas dans billing_subscriptions) ✓
- `/tenants/encoreuntest-mmyuu5hf` : 0 conversations, 0/15 playbooks, abonnement PRO/trialing affiché ✓
- Empty states honnêtes : ✓

---

**VERDICT : GO — ADMIN v2.1.9 VALIDÉ DEV + PROD**

Le cockpit tenant est un vrai outil de pilotage, branché sur des données réelles, sans aucun placeholder ni mock.
