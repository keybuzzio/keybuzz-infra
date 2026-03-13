# PH-ADMIN-86.4A — Tenant Cockpit — Report

**Date** : 2026-03-04
**Phase** : PH-ADMIN-86.4A
**Objectif** : Créer un Tenant Cockpit permettant de visualiser l'état global d'un tenant

---

## 1. Audit des données tenant réellement disponibles

### Sources de données exploitées

| Source | Table / Endpoint | Champs utilisés | Stabilité |
|---|---|---|---|
| PostgreSQL direct | `tenants` | id, name, plan, status, domain, created_at, updated_at | Stable DEV/PROD |
| PostgreSQL direct | `admin_user_tenants` + `admin_users` | user_id, tenant_id, email, role, is_active, last_login_at | Stable DEV/PROD |
| PostgreSQL direct | `human_approval_queue` | tenant_id, queue_status, priority, queue_type, reason, created_at | Stable DEV/PROD |

### Données NON disponibles

| Donnée attendue | Statut | Commentaire |
|---|---|---|
| Canaux / Connecteurs | Non disponible | Pas de table channels accessible depuis admin |
| MRR / Billing | Non disponible | Pas de données facturation exploitables |
| Métriques usage | Non disponible | Pas d'agrégats usage par tenant |
| Historique de plan | Non disponible | Seul le plan actuel est stocké |

**Règle appliquée** : aucune donnée inventée, message explicite "non disponible" pour les sections manquantes.

---

## 2. API Routes créées

| Route | Méthode | Description | RBAC |
|---|---|---|---|
| `/api/admin/tenants` | GET | Liste enrichie (avec count users admin + count cas actifs) | super_admin, ops_admin, account_manager |
| `/api/admin/tenants/[id]` | GET | Détail tenant + compteurs cas (total, open, critical) | super_admin, ops_admin, account_manager |
| `/api/admin/tenants/[id]/users` | GET | Utilisateurs admin assignés à ce tenant | super_admin, ops_admin, account_manager |
| `/api/admin/tenants/[id]/cases` | GET | 10 derniers cas du tenant | super_admin, ops_admin, account_manager |

### Requête enrichie liste tenants

```sql
SELECT t.id, t.name, t.plan, t.status, t.domain, t.created_at,
  COALESCE(au.cnt, 0)::int AS admin_user_count,
  COALESCE(hq.cnt, 0)::int AS active_cases_count
FROM tenants t
LEFT JOIN (SELECT tenant_id, COUNT(*)::int AS cnt FROM admin_user_tenants GROUP BY tenant_id) au ON au.tenant_id = t.id
LEFT JOIN (SELECT tenant_id, COUNT(*)::int AS cnt FROM human_approval_queue WHERE queue_status NOT IN ('APPROVED','REJECTED','CLOSED') GROUP BY tenant_id) hq ON hq.tenant_id = t.id
ORDER BY t.name ASC
```

---

## 3. Architecture UI

### Page /tenants (liste)

- Tableau complet avec colonnes : Nom, Plan, Statut, Admins, Cas actifs, Créé le
- Recherche par nom, ID ou domaine
- Filtres dynamiques : plan, statut (valeurs extraites des données réelles)
- Tri multi-colonne
- Stats en haut : tenants actifs, admins assignés, cas actifs
- Navigation cliquable vers `/tenants/[id]`

### Page /tenants/[id] (Tenant Cockpit)

Layout desktop-first deux colonnes :

**Colonne principale :**
- Header tenant (breadcrumb, nom, plan, statut, ID)
- Résumé (bloc texte construit à partir des champs réels)
- Identité tenant (nom, ID, plan, statut, domaine, dates)
- Cas récents (10 derniers, avec type, statut, priorité, lien vers /cases/[id])
- Canaux/Connecteurs (placeholder "non disponible")

**Sidebar :**
- Ops Snapshot (total, ouverts, critiques, résolus)
- Utilisateurs admin (email, rôle, statut, dernière connexion, lien vers /users/[id])
- Métadonnées techniques (repliable)

---

## 4. Composants créés

| Composant | Fichier | Description |
|---|---|---|
| TenantHeader | `features/tenants/components/TenantHeader.tsx` | Breadcrumb, icône, nom, badges plan/statut, ID, bouton refresh |
| TenantIdentityPanel | `features/tenants/components/TenantIdentityPanel.tsx` | Champs identité structurés (nom, ID, plan, statut, domaine, dates) |
| TenantUsersPanel | `features/tenants/components/TenantUsersPanel.tsx` | Liste admin users assignés, loading/empty states, navigation vers /users/[id] |
| TenantOpsSnapshot | `features/tenants/components/TenantOpsSnapshot.tsx` | 4 indicateurs : total, ouverts, critiques, résolus |
| TenantRecentCases | `features/tenants/components/TenantRecentCases.tsx` | 10 derniers cas, badges type/statut/priorité, navigation vers /cases/[id] |
| TenantMetadataPanel | `features/tenants/components/TenantMetadataPanel.tsx` | Panneau technique repliable (IDs, timestamps, statut brut) |

---

## 5. Service backend enrichi

Méthodes ajoutées à `usersService` :

| Méthode | Description |
|---|---|
| `listTenantsEnriched()` | Liste tenants avec LEFT JOIN admin_user_tenants et human_approval_queue |
| `getTenantById(id)` | Détail tenant complet (id, name, plan, status, domain, created_at, updated_at) |
| `getTenantAdminUsers(tenantId)` | Admin users assignés via JOIN admin_user_tenants |
| `getTenantCasesCount(tenantId)` | Compteurs cas : total, open, critical |
| `getTenantRecentCases(tenantId, limit)` | N derniers cas ordonnés par date |

Types ajoutés : `TenantDetailRecord`, `TenantListItem`

---

## 6. RBAC

| Rôle | /tenants (liste) | /tenants/[id] (cockpit) | Donnée |
|---|---|---|---|
| super_admin | ✅ | ✅ | Complète |
| ops_admin | ✅ | ✅ | Complète |
| account_manager | ✅ | ✅ | Complète |
| support_agent | ❌ (403) | ❌ (403) | — |
| viewer | ❌ (403) | ❌ (403) | — |

Les rôles ne sont pas hardcodés dans les composants.

---

## 7. États UI gérés

| État | Page /tenants | Page /tenants/[id] |
|---|---|---|
| Loading | Spinner centré | Spinner centré |
| Error | Message d'erreur + icône | Message + texte |
| Empty (aucun tenant) | "Aucun tenant trouvé" | — |
| Tenant introuvable | — | "Tenant introuvable" + message |
| Aucun user admin | — | "Aucun utilisateur admin assigné" |
| Aucun cas | — | "Aucun cas pour ce tenant" |
| Channels non disponibles | — | "Non disponible dans cette phase" |

---

## 8. Non-régression

- `client-dev.keybuzz.io` : HTTP 307 — fonctionnel
- `client.keybuzz.io` : HTTP 307 — fonctionnel
- Aucune modification backend Fastify
- Aucun impact sur les namespaces client

---

## 9. Déploiement

| Environnement | Image | Statut |
|---|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.10.0-ph86.4a-tenant-cockpit` | ✅ Running 1/1 |
| PROD | `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.10.0-ph86.4a-tenant-cockpit` | ✅ Running 1/1 |

---

## 10. Limitations documentées

| Limitation | Impact | Phase future |
|---|---|---|
| Pas de données channels/connecteurs | Placeholder "non disponible" | Backend enrichment |
| Pas de MRR / billing | Stat MRR absente | Intégration Stripe |
| Pas de métriques usage | Pas de graphiques activité | Analytics futur |
| Pas d'historique plan | Seul le plan actuel affiché | Migration tracking |
| Snapshot ops = requête directe DB | Pas d'endpoint backend dédié | Backend ops tenant-scoped |

---

## 11. Résumé validation

| Critère | Résultat |
|---|---|
| /tenants exploitable | ✅ |
| /tenants/[id] cockpit lisible | ✅ |
| Données affichées réelles | ✅ |
| Aucune donnée inventée | ✅ |
| Users admin liés visibles | ✅ |
| Signaux ops propres | ✅ |
| Navigation vers /cases/[id] | ✅ |
| Navigation vers /users/[id] | ✅ |
| Channels = "non disponible" (pas simulé) | ✅ |
| RBAC respecté | ✅ |
| Non-régression client | ✅ |
| Build OK | ✅ |
| Deploy DEV + PROD OK | ✅ |

**PH-ADMIN-86.4A : VALIDÉE**
