# PH143-G — Dashboard / Supervision / SLA Rebuild

> Phase : PH143-G-DASHBOARD-SUPERVISION-SLA-REBUILD-01
> Date : 2026-04-05
> Branches : rebuild/ph143-api / rebuild/ph143-client
> Tags : v3.5.200-ph143-dashboard-dev (API + Client)

---

## Objectif

Reconstruire completement le dashboard supervision, les statistiques agents, le SLA (badges + priorite) et le tri intelligent des conversations.

---

## Travail realise

### API (rebuild/ph143-api)

| Fichier | Action |
|---------|--------|
| `src/modules/dashboard/routes.ts` | Ajoute endpoint `GET /dashboard/supervision` |

L'endpoint retourne :
- **agents** : stats par agent (total, open, pending, resolved, SLA breached/atRisk/ok, avg response time)
- **slaGlobal** : ok, atRisk, breached, total
- **conversationsSummary** : total, open, pending, resolved, resolved24h

Commit : `86cde06`

### Client (rebuild/ph143-client)

| Fichier | Action |
|---------|--------|
| `app/api/dashboard/supervision/route.ts` | Cree BFF proxy vers API |
| `src/features/dashboard/components/SupervisionPanel.tsx` | Composant supervision avec KPIs et charge par agent |
| `src/features/dashboard/api/dashboard.service.ts` | Ajoute `fetchSupervisionData()` + types |
| `app/dashboard/page.tsx` | Integre SupervisionPanel dans le dashboard |

Commit : `5a19a23`

### Elements deja presents sur le rebuild (pas de modification necessaire)

| Element | Fichier | Status |
|---------|---------|--------|
| conversationPriority | `src/features/inbox/utils/conversationPriority.ts` | OK |
| PriorityBadge | `src/features/inbox/components/PriorityBadge.tsx` | OK |
| SLA mapping | `src/services/conversations.service.ts` | OK (sla_state → slaState, sla_due_at → slaDueAt) |
| Tri prioritaire | `app/inbox/InboxTripane.tsx` | OK (toggle + sortByPriority) |
| Badges dans la liste | `app/inbox/InboxTripane.tsx` | OK (PriorityBadge rendu inline) |

---

## Tests realises

### API (kubectl exec)

| Endpoint | Status | Donnees |
|----------|--------|---------|
| `GET /health` | 200 | `{"status":"ok"}` |
| `GET /dashboard/supervision?tenantId=ecomlg-001` | 200 | 333 convs, 259 SLA breached, agents stats |
| `GET /dashboard/summary?tenantId=ecomlg-001` | 200 | KPIs, channels, SLA |
| `GET /tenant-context/signature/ecomlg-001` | 200 | Config + preview |
| `GET /agents?tenantId=ecomlg-001` | 200 | Liste agents |
| `GET /billing/current?tenantId=ecomlg-001` | 200 | Plan actif |

### Navigateur (client-dev.keybuzz.io)

| Page | Validation |
|------|-----------|
| `/dashboard` | SupervisionPanel visible avec 6 KPIs (En file, Assignees, Escaladees, Urgentes, A surveiller, Resolues 24h) |
| `/dashboard` | KpiCards, ChannelSplit, SlaPanel, ActivityFeed OK |
| `/inbox` | Conversations avec badges Escalade visibles |
| `/inbox` | Filtres SAV actifs (1 SAV actif) |
| `/settings?tab=signature` | Deep-link + formulaire charge |
| `/billing` | Plan Pro, KBActions, historique visibles |

### Non-regression

| Feature | Status |
|---------|--------|
| Health API | OK |
| Billing | OK |
| Agents | OK |
| Signature | OK |
| Dashboard summary | OK |
| Inbox filtres | OK |

---

## Architecture SupervisionPanel

```
Dashboard page
  └─ fetchSupervisionData() → BFF /api/dashboard/supervision
      └─ API /dashboard/supervision (SQL aggregation)
          └─ agents stats (GROUP BY assigned_agent_id)
          └─ getSlaStats() (ok/atRisk/breached)
          └─ getOverviewStats() (conversations summary)
  └─ SupervisionPanel component
      └─ 6 KPI cells
      └─ Alert banners (SLA breached/at risk)
      └─ Agent workload list (Link → /inbox?assignedTo=)
```

---

## Verdict

**SUPERVISION CLEAR — SLA VISIBLE — PRIORITY WORKING**

- SupervisionPanel fonctionnel et integre dans le dashboard
- SLA mapping, conversationPriority, PriorityBadge actifs dans l'inbox
- Tri prioritaire disponible (toggle dans InboxTripane)
- Non-regression validee (billing, agents, signature, IA)

**GO pour PH143-H**
