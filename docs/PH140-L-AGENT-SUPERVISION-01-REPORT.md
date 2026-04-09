# PH140-L — Agent Supervision Panel

**Date** : 2 avril 2026
**Status** : DEV OK — STOP (PROD apres validation explicite)
**Image DEV** : `ghcr.io/keybuzzio/keybuzz-client:v3.5.176-agent-supervision-dev`

---

## Objectif

Ajouter une vue simple de supervision pour owner/admin dans le Dashboard :
- Comprendre rapidement la charge (en file / assignees / escaladees)
- Detecter les blocages (escaladees sans responsable, conversations anciennes)
- Suivre les agents (workload par agent, lien vers filtre inbox)

---

## Donnees utilisees

Aucune nouvelle table creee. Exploitation des donnees existantes :
- `conversations.status` : pending, open, resolved
- `conversations.assigned_agent_id` : null = en file, non-null = assigne
- `conversations.escalation_status` : none, recommended, escalated
- `conversations.last_message_at` : pour detecter les conversations anciennes
- `agents` : table existante (first_name, last_name, email)

---

## Composants crees / modifies

### 1. `src/features/dashboard/components/SupervisionPanel.tsx` (CREE)

Composant React affichant :
- **4 KPIs** : En file, Assignees, Escaladees, Resolues (24h)
- **Alertes** : escaladees sans responsable + conversations >24h sans reponse
- **Workload par agent** : liste triee par charge, avec badge compte + escaladees
- **Interaction** : clic sur un agent → redirect `/inbox?assignedTo=<id>`

### 2. `app/api/dashboard/supervision/route.ts` (CREE)

Route BFF qui :
- Appelle `/messages/conversations?tenantId=xxx&limit=2000`
- Normalise les champs (camelCase/snake_case)
- Retourne la liste des conversations avec les donnees d'assignation

### 3. `app/dashboard/page.tsx` (MODIFIE)

- Import du `SupervisionPanel`
- Ajout d'un state `supervisionConvs` + fetch supervision data
- Rendu du panel entre SLA et Activite recente

---

## KPIs calcules

| KPI | Formule |
|---|---|
| En file | `assigned_agent_id IS NULL AND status != 'resolved'` |
| Assignees | `assigned_agent_id IS NOT NULL AND status != 'resolved'` |
| Escaladees | `escalation_status = 'escalated' AND status != 'resolved'` |
| Resolues (24h) | `status = 'resolved' AND resolved_at >= today 00:00` |

---

## Alertes

| Alerte | Condition | Couleur |
|---|---|---|
| Escaladees sans responsable | `escalation_status = 'escalated' AND assigned_agent_id IS NULL` | Rouge |
| Sans reponse +24h | `assigned_agent_id IS NULL AND last_message_at < now() - 24h` | Ambre |

---

## Tests DEV (verifies navigateur reel)

| Test | Resultat |
|---|---|
| Panel Supervision visible dans Dashboard | OK |
| KPIs affiches (En file 252, Assignees 0, Escaladees 0, Resolues 0) | OK |
| Alerte "243 conversations sans reponse depuis +24h" | OK |
| Badge "Attention requise" rouge | OK |
| "Aucun agent assigne" (car 0 assignees) | OK |
| Accents corrects (Assignees, Escaladees, Resolues, reponse) | OK |

### Non-regression

| Test | Resultat |
|---|---|
| Inbox owner | OK — filtres PH140-K preserves |
| Dashboard KPIs existants | OK — Total 323, Ouvertes 240, En attente 12 |
| Repartition par canal | OK |
| Etat des SLAs | OK |
| Activite recente | OK |
| Billing | Non touche |
| Agent access lockdown (PH140-J) | Non touche |
| Assignment semantics (PH140-K) | Non touche |

---

## Architecture

```
Dashboard page
├── KpiCards (existant)
├── ChannelSplit + SlaPanel (existant)
├── SupervisionPanel (NOUVEAU - PH140-L)
│   ├── 4 KPI cells (file/assignees/escaladees/resolues)
│   ├── Alertes (escaladees non assignees, anciennes)
│   └── Workload agents (clic → filtre inbox)
└── ActivityFeed (existant)
```

---

## Fichiers modifies

| Fichier | Action |
|---|---|
| `src/features/dashboard/components/SupervisionPanel.tsx` | Cree |
| `app/api/dashboard/supervision/route.ts` | Cree |
| `app/dashboard/page.tsx` | Modifie (import + state + render) |

---

## Rollback DEV

```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.175-assignment-semantics-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## PROD

**Deploye le 2 avril 2026.**

| Etape | Resultat |
|---|---|
| Build PROD (`--no-cache`, `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `APP_ENV=production`) | OK |
| Push GHCR | OK — `sha256:4aa5d61e...` |
| Deploy `keybuzz-client-prod` | OK — rollout reussi |
| Health check `client.keybuzz.io` | OK — HTTP 200, 0.78s |
| Pod | `1/1 Running`, 0 restarts |
| GitOps YAML DEV + PROD | Mis a jour |

**Image PROD** : `ghcr.io/keybuzzio/keybuzz-client:v3.5.176-agent-supervision-prod`

### Rollback PROD

```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.175-assignment-semantics-prod -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```
