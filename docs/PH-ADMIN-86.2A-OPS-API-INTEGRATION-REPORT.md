# PH-ADMIN-86.2A — Ops API Integration Foundation

**Date** : 13 mars 2026
**Statut** : TERMINE
**Environnement** : DEV + PROD

---

## 1. Architecture API

### Configuration runtime centralisee

| Fichier | Role |
|---|---|
| `src/config/api.ts` | Configuration API (baseUrl, timeout) |
| `src/config/endpoints.ts` | Registre central de tous les endpoints ops |
| `src/config/env.ts` | Variables d'environnement runtime |

La base URL API est injectee via `NEXT_PUBLIC_API_URL` au build time. Aucune URL hardcodee dans les composants.

### Registre endpoints

Tous les endpoints sont definis dans `src/config/endpoints.ts` :

```
ENDPOINTS.ops.dashboard          → /ai/ops-dashboard
ENDPOINTS.ops.pendingApprovals   → /ai/ops/pending-approvals
ENDPOINTS.ops.followups          → /ai/ops/followups
ENDPOINTS.ops.escalations        → /ai/ops/escalations
ENDPOINTS.ops.assign             → /ai/ops/assign
ENDPOINTS.ops.resolve            → /ai/ops/resolve
ENDPOINTS.ops.snooze             → /ai/ops/snooze
ENDPOINTS.queues.list            → /ai/human-approval-queue
ENDPOINTS.queues.detail(id)      → /ai/human-approval-queue/:id
ENDPOINTS.queues.updateStatus(id)→ /ai/human-approval-queue/:id/status
ENDPOINTS.followups.scheduler    → /ai/followup-scheduler
ENDPOINTS.followups.overdue      → /ai/followup-scheduler/overdue
ENDPOINTS.followups.priorities   → /ai/followup-scheduler/priorities
ENDPOINTS.controlCenter.overview → /ai/control-center
```

### Zero hardcodage

Aucun composant, aucune page ne contient d'URL ou d'endpoint en dur. Tout passe par :
1. `ENDPOINTS` (registre central)
2. `opsService` (couche service)
3. `apiClient` (client HTTP)

---

## 2. Client HTTP

### `src/lib/api-client.ts`

Client HTTP ameliore :

| Fonctionnalite | Implementation |
|---|---|
| Methodes | GET, POST, PUT, PATCH, DELETE |
| Query params | Support natif via `URL.searchParams` |
| Timeout | AbortController (15s configurable) |
| Erreurs HTTP | Parse du body JSON, fallback message |
| Session expiree | Detection HTTP 401, message specifique |
| Erreur reseau | Catch global, message utilisateur |
| Typage | Generic `ApiResponse<T>` |

---

## 3. Types stricts

### `src/features/ops/types.ts`

| Type | Description |
|---|---|
| `OpsDashboard` | Totals + queues + followups du dashboard |
| `ApprovalItem` | Cas en attente d'approbation |
| `PendingApprovalsResponse` | count + items[] |
| `FollowupItem` | Element follow-up avec urgence |
| `OpsFollowupsResponse` | count + items[] |
| `QueueEntry` | Element de queue (id, type, priority, status, tenant) |
| `SchedulerReport` | Totals + distributions + actions recommandees |
| `ApprovalStatus` | OPEN, IN_REVIEW, APPROVED, REJECTED, CLOSED |
| `PriorityLevel` | LOW, MEDIUM, HIGH, CRITICAL |
| `UrgencyLevel` | ON_TRACK, UPCOMING, DUE_SOON, OVERDUE, CRITICAL |

---

## 4. Couche services

### `src/features/ops/services/ops.service.ts`

| Methode | Endpoint | Description |
|---|---|---|
| `getDashboard()` | ops.dashboard | Dashboard ops agrege |
| `getPendingApprovals()` | ops.pendingApprovals | Approbations en attente |
| `getFollowups()` | ops.followups | Follow-ups ops |
| `getEscalations()` | ops.escalations | Escalations actives |
| `getQueueItems(params)` | queues.list | Queue avec filtres |
| `updateQueueStatus(id, status)` | queues.updateStatus | MAJ statut |
| `getSchedulerReport()` | followups.scheduler | Rapport scheduler |
| `getOverdueFollowups()` | followups.overdue | Follow-ups en retard |
| `assignCase(caseId, agentId)` | ops.assign | Assigner |
| `resolveCase(caseId)` | ops.resolve | Resoudre |
| `snoozeCase(caseId, durationHours)` | ops.snooze | Reporter |

---

## 5. Composants UI etats

### `src/components/ui/DataState.tsx`

| Composant | Usage |
|---|---|
| `LoadingState` | Spinner + message pendant chargement |
| `EmptyState` | Icone + message quand aucune donnee |
| `ErrorState` | Alerte + message + bouton reessayer |

### `src/hooks/useApiData.ts`

Hook generique de chargement API :
- Gestion loading / data / error
- Cleanup sur unmount
- Fonction `refetch` pour rechargement manuel

---

## 6. Pages connectees

### /ops — Dashboard ops

- 4 StatCards : cas en attente, follow-ups actifs, en retard, critiques
- Breakdown queues par type (REFUND_REVIEW, FRAUD_REVIEW, etc.)
- Breakdown follow-ups par type (WAITING_CUSTOMER, etc.)
- Liens vers /queues, /approvals, /followups
- Source : `GET /ai/ops-dashboard`

### /queues — File d'attente

- Stats derivees : en attente, en cours, urgentes, resolues
- Tableau complet : type, priorite, statut, tenant, date, action suggeree
- StatusBadge colores par priorite et statut
- Source : `GET /ai/human-approval-queue`

### /approvals — Approbations

- Stats : en attente, critiques, priorite haute
- Tableau : type, priorite, tenant, etape workflow, action suggeree
- Labels traduits pour types et actions
- Source : `GET /ai/ops/pending-approvals`

### /followups — Follow-ups

- 5 StatCards : ouverts, a venir, bientot dus, en retard, critiques
- Distribution par urgence et par type
- Actions recommandees (recontacter client, enquete transporteur, etc.)
- Source : `GET /ai/followup-scheduler`

---

## 7. Endpoints backend verifies

| Endpoint | HTTP | Statut | Donnees |
|---|---|---|---|
| `/ai/ops-dashboard` | 200 | OK | 1 cas humain, 1 LEGAL_REVIEW, 1 critique |
| `/ai/ops/pending-approvals` | 200 | OK | 1 item LEGAL_REVIEW CRITICAL |
| `/ai/ops/followups` | 200 | OK | 0 items |
| `/ai/human-approval-queue` | 200 | OK | 1 item IN_REVIEW |
| `/ai/followup-scheduler` | 200 | OK | 0 open followups |

Tous les endpoints retournent des donnees reelles, aucun mock.

---

## 8. Non-regression client

| Service | Avant | Apres |
|---|---|---|
| client-dev.keybuzz.io | HTTP 307 | HTTP 307 |
| client.keybuzz.io | HTTP 307 | HTTP 307 |

Zero regression constatee.

---

## 9. Docker tags

| Env | Tag |
|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.4.0-ph86.2a-ops-api-integration-dev` |
| PROD | `ghcr.io/keybuzzio/keybuzz-admin-v2:v0.4.0-ph86.2a-ops-api-integration-prod` |

---

## 10. Fichiers crees/modifies

| Fichier | Action |
|---|---|
| `src/config/api.ts` | Cree — configuration API centralisee |
| `src/config/endpoints.ts` | Cree — registre central endpoints |
| `src/lib/api-client.ts` | Modifie — timeout, query params, meilleure gestion erreurs |
| `src/features/ops/types.ts` | Cree — types stricts ops |
| `src/features/ops/services/ops.service.ts` | Cree — couche service ops |
| `src/hooks/useApiData.ts` | Cree — hook generique fetch |
| `src/components/ui/DataState.tsx` | Cree — composants loading/empty/error |
| `src/app/(admin)/ops/page.tsx` | Reecrit — dashboard ops connecte |
| `src/app/(admin)/queues/page.tsx` | Reecrit — queues connectees |
| `src/app/(admin)/approvals/page.tsx` | Reecrit — approbations connectees |
| `src/app/(admin)/followups/page.tsx` | Reecrit — follow-ups connectes |

---

## 11. Criteres de validation

| Critere | Statut |
|---|---|
| Integration API ops reelle | OK |
| /ops fonctionne | OK |
| /queues fonctionne | OK |
| /approvals fonctionne | OK |
| /followups fonctionne | OK |
| Aucune donnee mock | OK |
| Aucun hardcodage dans les composants | OK |
| Non-regression client | OK |
| DEV deploye | OK |
| PROD deploye | OK |
| GitOps (manifests MAJ) | OK |
