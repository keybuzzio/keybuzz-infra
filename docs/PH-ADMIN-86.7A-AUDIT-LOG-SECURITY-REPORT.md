# PH-ADMIN-86.7A — Audit Log & Security Monitoring — Report

**Date** : 2026-03-14
**Image** : `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.13.0-ph86.7a-audit-log`
**Statut** : DEV + PROD deployes

---

## 1. Table audit_logs

### Migration SQL

```sql
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  actor_user_id UUID,
  actor_email TEXT NOT NULL,
  actor_role TEXT NOT NULL,
  action_type TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id TEXT,
  tenant_id TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  ip_address TEXT,
  user_agent TEXT
);
```

### Index

| Index | Colonne(s) |
|---|---|
| `idx_audit_logs_created` | `created_at DESC` |
| `idx_audit_logs_actor` | `actor_email` |
| `idx_audit_logs_action` | `action_type` |
| `idx_audit_logs_resource` | `resource_type, resource_id` |
| `idx_audit_logs_tenant` | `tenant_id` |

Table creee en **DEV** et **PROD**.

---

## 2. Registre des actions auditees

| Action | Code | Ressource | Description |
|---|---|---|---|
| Assignation cas | `ASSIGN_CASE` | case | Agent assigne un cas a un utilisateur |
| Resolution cas | `RESOLVE_CASE` | case | Agent resout un cas |
| Report cas | `SNOOZE_CASE` | case | Agent reporte un cas |
| Changement statut | `CHANGE_CASE_STATUS` | case | Modification du statut d'un cas |
| Creation utilisateur | `CREATE_USER` | user | Nouvel utilisateur admin cree |
| Modification role | `UPDATE_USER_ROLE` | user | Role d'un utilisateur modifie |
| Desactivation user | `DISABLE_USER` | user | Compte utilisateur desactive |
| Activation user | `ENABLE_USER` | user | Compte utilisateur reactive |
| Assignation tenant | `ASSIGN_TENANT` | user | Tenant assigne a un utilisateur |
| Retrait tenant | `REMOVE_TENANT` | user | Tenant retire d'un utilisateur |
| Reset mot de passe | `RESET_USER_PASSWORD` | user | Regeneration du lien de setup |
| Token activation | `GENERATE_SETUP_TOKEN` | user | Token d'activation genere |
| Connexion | `LOGIN` | session | Connexion admin |

---

## 3. Service audit

**Fichier** : `src/features/audit/audit.service.ts`

| Methode | Description |
|---|---|
| `log(entry)` | Insere un log dans audit_logs (avec sanitization metadata) |
| `list(filters)` | Liste paginee avec filtres (actor, action, resource, tenant) |
| `getStats()` | Statistiques globales (total, today, distribution actions) |

### Sanitization securite
Les cles contenant `password`, `token`, `secret`, `hash` dans metadata sont automatiquement remplacees par `[REDACTED]`.

---

## 4. Routes API

| Route | Methode | Description | RBAC |
|---|---|---|---|
| `/api/admin/audit-logs` | GET | Liste paginee + stats | super_admin, ops_admin |
| `/api/admin/audit-logs` | POST | Enregistrement log client-side (ops actions) | super_admin, ops_admin, account_manager |

### Parametres GET
- `?actor=email` — filtre par email (ILIKE)
- `?action=ACTION_TYPE` — filtre par action
- `?resource=type` — filtre par ressource
- `?tenant=id` — filtre par tenant
- `?limit=100&offset=0` — pagination

---

## 5. Integration mutations existantes

| Route API | Actions auditees |
|---|---|
| `POST /api/admin/users` | CREATE_USER |
| `PUT /api/admin/users/[id]` (role) | UPDATE_USER_ROLE |
| `PUT /api/admin/users/[id]` (active) | ENABLE_USER / DISABLE_USER |
| `POST /api/admin/users/[id]/tenants` | ASSIGN_TENANT |
| `DELETE /api/admin/users/[id]/tenants` | REMOVE_TENANT |
| `POST /api/admin/users/[id]/reset-password` | RESET_USER_PASSWORD |

### Actions ops (client-side)
Les actions ops (ASSIGN_CASE, RESOLVE_CASE, SNOOZE_CASE, CHANGE_CASE_STATUS) peuvent etre auditees via `POST /api/admin/audit-logs` depuis le composant CaseActionPanel.

---

## 6. Architecture UI

### Page : `/audit` (reecrite)

Layout :
1. **KPI** — 4 StatCards (Total logs, Aujourd'hui, Types d'actions, Action principale)
2. **Filtres** — Recherche email, filtre action, filtre ressource
3. **Compteur + Pagination** — Total resultats, navigation pages
4. **Tableau** — Logs avec colonnes expandables pour metadata

### Composants crees

| Composant | Fichier | Role |
|---|---|---|
| `AuditLogTable` | `src/features/audit/components/AuditLogTable.tsx` | Tableau expandable avec detail metadata |
| `AuditLogFilters` | `src/features/audit/components/AuditLogFilters.tsx` | Filtres email + action + ressource |

### Fonctionnalites
- Clic sur une ligne = expansion detail metadata
- Labels lisibles (CREATE_USER → "Creation utilisateur")
- Badges colores par type d'action (vert/rouge/jaune/bleu)
- Pagination (100 par page)
- Bouton Actualiser
- Etat vide gere

---

## 7. Securite

### Donnees NON exposees
- Passwords / hashes : sanitizes dans metadata (`[REDACTED]`)
- Tokens : sanitises dans metadata
- Secrets Vault : jamais captures

### Protection
- RBAC : seuls super_admin et ops_admin voient les logs
- Metadata filtree automatiquement par le service
- IP et user-agent captures mais non affiches en premier plan

---

## 8. RBAC

| Role | Lecture logs | Ecriture logs |
|---|---|---|
| super_admin | Oui | Oui |
| ops_admin | Oui | Oui |
| account_manager | Non | Oui (ops actions) |
| support_agent | Non | Non |
| viewer | Non | Non |

---

## 9. Non-regression client

| Service | Code | Statut |
|---|---|---|
| `client-dev.keybuzz.io` | 307 | OK |
| `client.keybuzz.io` | 307 | OK |

---

## 10. Deploiement

| Env | Image | Pod | Statut |
|---|---|---|---|
| DEV | `v0.13.0-ph86.7a-audit-log` | 1/1 Running | OK |
| PROD | `v0.13.0-ph86.7a-audit-log` | 1/1 Running | OK |

---

## 11. Limitations

| Limitation | Raison |
|---|---|
| Ops actions non encore auditees automatiquement | Necessitent integration dans CaseActionPanel (client-side POST) |
| Pas de retention automatique | Pas de cron pour purge des anciens logs |
| Pas d'export CSV | Fonctionnalite future |
| Pas d'alerte temps reel | Pas de websocket/SSE |

---

## 12. Fichiers crees / modifies

### Crees
- `src/features/audit/audit.service.ts` — Service audit + sanitization
- `src/app/api/admin/audit-logs/route.ts` — API GET + POST
- `src/features/audit/components/AuditLogTable.tsx` — Tableau expandable
- `src/features/audit/components/AuditLogFilters.tsx` — Filtres

### Modifies
- `src/app/(admin)/audit/page.tsx` — Page reecrite (placeholder → vrai dashboard)
- `src/app/api/admin/users/route.ts` — Audit CREATE_USER
- `src/app/api/admin/users/[id]/route.ts` — Audit UPDATE_ROLE, ENABLE/DISABLE
- `src/app/api/admin/users/[id]/tenants/route.ts` — Audit ASSIGN/REMOVE_TENANT
- `src/app/api/admin/users/[id]/reset-password/route.ts` — Audit RESET_PASSWORD

### Migration SQL
- Table `audit_logs` creee en DEV et PROD (5 index)
