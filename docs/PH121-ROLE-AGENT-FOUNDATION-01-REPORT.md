# PH121-ROLE-AGENT-FOUNDATION-01 — RAPPORT

> Date : 2026-03-24
> Phase : PH121-ROLE-AGENT-FOUNDATION-01
> Type : Fondation agents & rôles

---

## 1. OBJECTIF

Mettre en place un système de rôles, permissions et agents extensible dans KeyBuzz, servant de fondation pour l'escalade IA/humain à venir.

---

## 2. AUDIT DE L'EXISTANT

| Élément | État pré-PH121 |
|---|---|
| `user_tenants.role` | Existe : `owner`, `admin`, `agent` |
| `TenantProvider` RBAC | Existe : `currentRole`, `isAgent`, `isOwnerOrAdmin` |
| Middleware RBAC | Existe : cookie `currentTenantRole`, blocage agents sur routes admin |
| `routeAccessGuard.ts` | Existe : `ADMIN_ONLY_ROUTES` |
| Badge rôle | Existe : dans ClientLayout (anglais, sans couleurs cohérentes) |
| Permissions model | **Absent** |
| `useRole()` / `usePermissions()` | **Absent** |
| Endpoints `/api/roles/*` | **Absent** |
| Rôle `viewer` | **Absent** |
| Type `EscalationTarget` | **Absent** |
| `PermissionGate` component | **Absent** |

---

## 3. MODELE DE ROLES

```
Role = 'owner' | 'admin' | 'agent' | 'viewer'
SpecialRole = 'keybuzz_agent'
```

Hiérarchie de privilèges :
```
owner > admin > agent > viewer
```

---

## 4. MATRICE DE PERMISSIONS

| Permission | owner | admin | agent | viewer |
|---|---|---|---|---|
| canViewConversations | ✓ | ✓ | ✓ | ✓ |
| canReply | ✓ | ✓ | ✓ | ✗ |
| canAssign | ✓ | ✓ | ✗ | ✗ |
| canAccessSettings | ✓ | ✓ | ✗ | ✗ |
| canAccessAI | ✓ | ✓ | ✗ | ✗ |
| canManageBilling | ✓ | ✗ | ✗ | ✗ |
| canInviteUsers | ✓ | ✓ | ✗ | ✗ |
| canExportData | ✓ | ✓ | ✗ | ✗ |

Validée via `/api/roles/permissions` (endpoint fonctionnel en DEV et PROD).

---

## 5. MODELE AGENT

Types préparés dans `src/lib/roles.ts` :

```typescript
interface AgentProfile {
  id: string;
  userId: string;
  tenantId: string;
  role: AnyRole;
  isActive: boolean;
  displayName: string | null;
}
```

---

## 6. PREPARATION ESCALADE

Structure préparée (types uniquement, pas de logique métier) :

```typescript
interface EscalationTarget {
  assignedToAgentId: string | null;
  assignedType: 'ai' | 'human' | null;
}
```

Prête à être intégrée dans le modèle `conversations` lors d'une phase ultérieure.

---

## 7. FICHIERS CREES

| Fichier | Description |
|---|---|
| `src/lib/roles.ts` | Source de vérité : rôles, permissions, labels, couleurs, utilitaires |
| `src/features/roles/useRole.ts` | Hook `useRole()` — rôle courant + flags |
| `src/features/roles/usePermissions.ts` | Hook `usePermissions()` + `useHasPermission()` |
| `src/features/roles/PermissionGate.tsx` | Composant gate conditionnel basé sur permissions |
| `src/features/roles/RoleBadge.tsx` | Badge rôle réutilisable avec dot coloré |
| `src/features/roles/index.ts` | Barrel export |
| `app/api/roles/me/route.ts` | BFF : rôle + permissions de l'utilisateur courant |
| `app/api/roles/permissions/route.ts` | BFF : matrice complète rôles × permissions |

---

## 8. FICHIERS MODIFIES

| Fichier | Modification |
|---|---|
| `src/features/tenant/TenantProvider.tsx` | Ajout `viewer` dans le type `currentRole`, ajout `isViewer` |
| `src/features/tenant/index.ts` | Re-export des modules roles pour commodité |
| `src/lib/routeAccessGuard.ts` | Ajout `viewer` au blocage admin, ajout `/api/roles` aux prefixes API, ajout `ACTION_ROUTES` |
| `middleware.ts` | Blocage `viewer` sur routes admin (comme `agent`) |
| `src/components/layout/ClientLayout.tsx` | Badge rôle francisé avec dot coloré, support viewer |

---

## 9. BADGE ROLE AMELIORE

| Rôle | Avant | Après |
|---|---|---|
| owner | `Owner` (texte brut) | `● Propriétaire` (violet) |
| admin | `Admin` (texte brut) | `● Admin` (bleu) |
| agent | `Agent` (texte brut) | `● Agent` (émeraude) |
| viewer | — | `● Lecteur` (gris) |

---

## 10. ENDPOINTS BFF

### GET /api/roles/me
Retourne le rôle et les permissions de l'utilisateur courant pour le tenant actif.

### GET /api/roles/permissions
Retourne la matrice complète des 4 rôles × 8 permissions.

Validés en DEV et PROD.

---

## 11. VALIDATION DEV

| Test | Résultat |
|---|---|
| HTTP `/` | 200 ✓ |
| HTTP `/login` | 200 ✓ |
| HTTP `/dashboard` | 200 ✓ |
| HTTP `/inbox` | 200 ✓ |
| HTTP `/orders` | 200 ✓ |
| HTTP `/ai-dashboard` | 200 ✓ |
| `/api/roles/permissions` | JSON valide, 4 rôles, 8 permissions ✓ |
| Bundle `roles.ts` | Présent dans server chunks ✓ |
| Rollout | Zero-downtime ✓ |

**PH121 DEV = OK**

---

## 12. VALIDATION PROD

| Test | Résultat |
|---|---|
| HTTP `/` | 200 ✓ |
| HTTP `/login` | 200 ✓ |
| HTTP `/dashboard` | 200 ✓ |
| HTTP `/inbox` | 200 ✓ |
| HTTP `/orders` | 200 ✓ |
| HTTP `/ai-dashboard` | 200 ✓ |
| `/api/roles/permissions` | JSON valide, 4 rôles, 8 permissions ✓ |
| Bundle `roles.ts` | Présent dans server chunks ✓ |
| Rollout | Zero-downtime ✓ |

**PH121 PROD = OK**

---

## 13. IMAGES DEPLOYEES

| Env | Image |
|---|---|
| **DEV** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.87-ph121-role-agent-dev` |
| **PROD** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.87-ph121-role-agent-prod` |

---

## 14. ROLLBACK

| Env | Rollback vers |
|---|---|
| DEV | `v3.5.86-ph117-ai-dashboard-metronic-polish-dev` |
| PROD | `v3.5.86-ph117-ai-dashboard-metronic-polish-prod` |

---

## 15. CE QUI N'EST PAS FAIT (HORS SCOPE)

Conformément aux instructions, les éléments suivants sont préparés mais **non implémentés** :

- Logique d'escalade complète
- Assignation automatique IA → humain
- UI d'assignation d'agents
- Modification du système de conversations
- Table DB `agents` ou `user_roles`
- Gestion des permissions côté backend Fastify

---

## 16. VERDICT FINAL

**ROLE & AGENT FOUNDATION READY**

Le modèle de rôles (4 rôles + 1 spécial), la matrice de permissions (8 permissions), les hooks frontend (`useRole`, `usePermissions`), les composants UI (`PermissionGate`, `RoleBadge`), les endpoints BFF, et les types d'escalade sont en place. Le système est extensible et prêt pour les phases de gestion d'agents et d'escalade.
