# PH-ADMIN-86.2B — Ops Actions & Case Navigation

## Objectif

Faire passer Admin v2 du mode **observation** au mode **action contrôlée** :
- Navigation depuis les listes ops vers un détail de cas
- Premières mutations ops réelles (assign, resolve, snooze, update status)
- Feedback UI propre (confirmations, toasts, refetch, protection double-clic)
- RBAC ops centralisé

## Audit des endpoints mutations

Tous les endpoints ont été testés sur `api-dev.keybuzz.io` avec un cas réel (`c1f7f14a-d1f7-42f9-b7bf-15eb846b24a9`).

| Endpoint | Méthode | Statut | Payload | Réponse |
|---|---|---|---|---|
| `/ai/human-approval-queue/:id` | GET | **200 STABLE** | — | Objet CaseDetail complet |
| `/ai/human-approval-queue/:id/status` | POST | **200 STABLE** | `{status}` | `{updated: boolean}` |
| `/ai/ops/assign` | POST | **200 STABLE** | `{caseId, agentId}` | `{updated: true}` → met à jour `recommended_owner` |
| `/ai/ops/resolve` | POST | **200 STABLE** | `{caseId}` | `{resolved: true}` |
| `/ai/ops/snooze` | POST | **200 STABLE** | `{caseId, durationHours}` | `{snoozed: true}` → ajoute `snoozedUntil` dans `decision_context` |

**Résultat** : 5/5 endpoints fonctionnels et stables. Aucune action UI simulée.

## Architecture service / mutations

### Registre central endpoints (`src/config/endpoints.ts`)

```
ENDPOINTS.ops.assign    → POST /ai/ops/assign
ENDPOINTS.ops.resolve   → POST /ai/ops/resolve
ENDPOINTS.ops.snooze    → POST /ai/ops/snooze
ENDPOINTS.queues.detail → GET  /ai/human-approval-queue/:id
ENDPOINTS.queues.updateStatus → POST /ai/human-approval-queue/:id/status
```

### Service centralisé (`src/features/ops/services/ops.service.ts`)

Méthodes ajoutées :
- `getCaseDetail(id)` — détail complet d'un cas
- `assignCase(caseId, agentId)` — assignation
- `resolveCase(caseId)` — résolution
- `snoozeCase(caseId, durationHours)` — report
- `updateQueueStatus(id, status)` — changement statut

### RBAC centralisé (`src/config/rbac.ts`)

| Rôle | view_cases | assign | resolve | snooze | update_status | manage_users |
|---|---|---|---|---|---|---|
| super_admin | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| ops_admin | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| account_manager | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| support_agent | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| viewer | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

## Routes UI ajoutées

| Route | Type | Description |
|---|---|---|
| `/cases/[id]` | **NOUVELLE** | Page détail de cas complète |
| `/queues` | MODIFIÉE | Lignes cliquables → `/cases/[id]` |
| `/approvals` | MODIFIÉE | Lignes cliquables → `/cases/[id]` |

### Page `/cases/[id]` — Détail de cas

Affiche :
- **Informations** : ID, type, statut, priorité, tenant, conversation, commande, raison
- **Dates** : création, mise à jour, reporté jusqu'à (si snoozé)
- **Analyse de risque** : abuseRisk, fraudRisk, escalationType, orderValueCategory
- **Recommandations** : action recommandée, assigné à
- **Actions sidebar** :
  - Assigner à moi
  - Résoudre
  - Reporter (sélection durée : 1h, 2h, 4h, 8h, 24h, 48h)
  - Changer le statut (OPEN, IN_REVIEW, APPROVED, REJECTED, CLOSED)
- **RBAC** : boutons désactivés si rôle insuffisant, bannière explicative
- **Navigation** : bouton retour, refresh

### Mutations UI

Chaque mutation :
1. Demande confirmation via `ConfirmDialog`
2. Affiche loading pendant requête
3. Bloque double-clic (bouton disabled pendant mutation)
4. Toast succès ou erreur
5. Refetch automatique des données

## Composants UI créés

| Composant | Fichier | Description |
|---|---|---|
| `ToastProvider` + `useToast` | `src/components/ui/Toast.tsx` | Système de notifications toast (succès/erreur, auto-dismiss 4s) |
| `ConfirmDialog` | `src/components/ui/ConfirmDialog.tsx` | Modal de confirmation avec variants (default/danger) |

## Types enrichis (`src/features/ops/types.ts`)

- Ajout interface `CaseDetail` (id, tenant_id, conversation_id, order_ref, queue_type, queue_status, priority, recommended_action, recommended_owner, reason, risk_summary, decision_context, created_at, updated_at)

## Fichiers modifiés / créés

### Créés
- `src/config/rbac.ts` — RBAC ops centralisé
- `src/components/ui/Toast.tsx` — Système toast
- `src/components/ui/ConfirmDialog.tsx` — Dialog de confirmation
- `src/app/(admin)/cases/[id]/page.tsx` — Page détail de cas

### Modifiés
- `src/features/ops/types.ts` — Ajout CaseDetail
- `src/features/ops/services/ops.service.ts` — Ajout getCaseDetail + import CaseDetail
- `src/config/endpoints.ts` — Inchangé (endpoints déjà présents depuis PH86.2A)
- `src/app/(admin)/queues/page.tsx` — Navigation cliquable vers /cases/[id]
- `src/app/(admin)/approvals/page.tsx` — Navigation cliquable + date + labels enrichis
- `src/app/layout.tsx` — Ajout ToastProvider
- `tailwind.config.ts` — Ajout animation slide-in-right

## Non-régression client

| URL | Statut | Impact |
|---|---|---|
| client-dev.keybuzz.io | **307** (normal) | ✅ Aucun impact |
| client.keybuzz.io | **307** (normal) | ✅ Aucun impact |
| admin-dev.keybuzz.io | **307** (normal) | ✅ Fonctionnel |
| admin.keybuzz.io | **307** (normal) | ✅ Fonctionnel |

## Déploiement

| Env | Image | Pod | Statut |
|---|---|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.7.0-ph86.2b-ops-actions-dev` | Running 1/1 | ✅ |
| PROD | `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.7.0-ph86.2b-ops-actions-prod` | Running 1/1 | ✅ |

## Limites

- **Followups** : La page `/followups` utilise un modèle de données différent (`SchedulerReport` avec distributions, pas d'items individuels cliquables). Navigation vers `/cases/[id]` non applicable car les followups ne sont pas des entries de `human-approval-queue`. La navigation sera ajoutée quand le backend exposera un endpoint détail followup ou quand des items individuels seront disponibles.
- **Assignation** : L'endpoint `/ai/ops/assign` accepte un `agentId` libre (string). L'UI assigne actuellement à l'email de l'admin connecté. Un sélecteur d'agents pourra être ajouté quand le modèle backend supportera une liste d'agents disponibles.

## Critères de validation

| Critère | Statut |
|---|---|
| Navigation vers un cas fonctionne | ✅ |
| Page détail de cas fonctionne | ✅ |
| Actions ops réellement disponibles branchées | ✅ (5/5) |
| Aucune action inexistante simulée | ✅ |
| RBAC fonctionne | ✅ |
| UX mutation propre (confirm, toast, refetch) | ✅ |
| Aucune régression client | ✅ |

## Rollback

```bash
# DEV
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin-v2:v0.6.0-ph86.1e-user-management-dev \
  -n keybuzz-admin-v2-dev

# PROD
kubectl set image deployment/keybuzz-admin-v2 \
  keybuzz-admin-v2=ghcr.io/keybuzzio/keybuzz-admin-v2:v0.6.0-ph86.1e-user-management-prod \
  -n keybuzz-admin-v2-prod
```
