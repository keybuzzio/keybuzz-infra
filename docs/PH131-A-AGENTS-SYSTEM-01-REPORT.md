# PH131-A-AGENTS-SYSTEM-01 — RAPPORT

> Date : 25 mars 2026
> Phase : PH131-A-AGENTS-SYSTEM-01
> Environnement : DEV uniquement
> Objectif : Création système agents + teams réel

---

## 1. Résumé

Création d'un système agents et teams réel, remplaçant le mock inexistant, permettant l'assignation réelle, la séparation agents client/keybuzz, et préparant l'escalade et l'autopilot.

---

## 2. Etat Avant (audit)

| Élément | État |
|---|---|
| Table `agents` | Existait, 10 colonnes, **0 lignes** |
| Table `teams` | Existait, 6 colonnes, **0 lignes** |
| Table `team_members` | **N'existait pas** |
| API `/agents` | GET / et GET /:id seulement (lecture) |
| API `/teams` | GET /, GET /:id, GET /:id/agents (lecture) |
| Client BFF | Aucun `/api/agents/` ni `/api/teams/` |
| Assignation | Hook fonctionnel mais utilisait `user.id`, pas un vrai agent |
| `conversations.assigned_agent_id` | Type `text`, nullable, 0 conversations assignées |
| `conversations.escalation_target` | **N'existait pas** |

---

## 3. Modifications DB (Patroni leader : db-postgres-03 / 10.0.0.122)

### 3.1 ALTER TABLE agents — 3 colonnes ajoutées

| Colonne | Type | Default | Usage |
|---|---|---|---|
| `user_id` | TEXT (nullable) | NULL | Lien vers table `users` |
| `type` | VARCHAR(20) NOT NULL | `'client'` | `client` ou `keybuzz` |
| `is_active` | BOOLEAN NOT NULL | `true` | Actif/inactif |

### 3.2 CREATE TABLE team_members

```sql
CREATE TABLE team_members (
  id SERIAL PRIMARY KEY,
  team_id VARCHAR NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  agent_id INTEGER NOT NULL REFERENCES agents(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(team_id, agent_id)
);
```

Permissions accordées à `keybuzz_api_dev`.

### 3.3 ALTER TABLE conversations — escalation_target

Colonne `escalation_target VARCHAR(20)` ajoutée pour préparer l'escalade (`client` | `keybuzz` | `both`).

### 3.4 Seeder DEV (ecomlg-001)

| ID | Nom | Email | Type | Rôle | user_id |
|---|---|---|---|---|---|
| 33 | Ludovic Gonthier | ludo.gonthier@gmail.com | client | admin | `0156d1ac-0863-431f-9717-216af804e7ef` |
| 34 | Test Agent | test-agent@keybuzz.io | client | agent | NULL |
| 35 | KeyBuzz Support | support@keybuzz.io | keybuzz | agent | NULL |

---

## 4. API Agents (Fastify, bastion)

### Routes ajoutées

| Method | Route | Description |
|---|---|---|
| GET | `/agents` | Liste agents (filtres : tenant_id, type, active_only) |
| GET | `/agents/:id` | Détail agent |
| POST | `/agents` | Création agent (validation email unique, type, role) |
| PATCH | `/agents/:id` | Mise à jour agent (champs partiels) |
| GET | `/agents/by-user/:userId` | Trouver agent par user_id (pour assignation) |

### Fichier : `src/modules/agents/routes.ts` — 218 lignes

---

## 5. API Teams (Fastify, bastion)

### Routes ajoutées

| Method | Route | Description |
|---|---|---|
| GET | `/teams` | Liste teams par tenant |
| GET | `/teams/:id` | Détail team |
| GET | `/teams/:id/agents` | Membres d'une team (via team_members) |
| POST | `/teams` | Création team |
| POST | `/teams/:id/members` | Ajouter un agent à une team |

### Fichier : `src/modules/teams/routes.ts` — 158 lignes

---

## 6. Client (Next.js)

### 6.1 BFF Routes créées

| Route | Fichier |
|---|---|
| GET/POST `/api/agents` | `app/api/agents/route.ts` |
| GET/PATCH `/api/agents/[id]` | `app/api/agents/[id]/route.ts` |
| GET/POST `/api/teams` | `app/api/teams/route.ts` |

### 6.2 Service agents

`src/services/agents.service.ts` — 89 lignes
- `fetchAgents(tenantId, type?)` — agents actifs
- `fetchAllAgents(tenantId)` — tous les agents
- `createAgent(payload)` — création
- `updateAgent(agentId, tenantId, updates)` — mise à jour partielle
- `getAgentDisplayName(agent)` — nom d'affichage
- `getAgentTypeBadge(type)` — badge visuel

### 6.3 Page UI Agents

`app/settings/agents/page.tsx` — 265 lignes
- Accès : `/settings/agents`
- Tableau avec colonnes : Agent, Email, Type (badge Client/KeyBuzz), Rôle, Statut (Actif/Inactif), Actions
- Bouton "Ajouter un agent" (owner/admin uniquement)
- Modal de création (prénom, nom, email, type, rôle)
- Toggle actif/inactif par agent
- Protection RBAC : accès réservé owner/admin

### 6.4 Permissions (RBAC)

`src/lib/roles.ts` — permission `canManageAgents` ajoutée :

| Rôle | canManageAgents |
|---|---|
| owner | ✅ |
| admin | ✅ |
| agent | ❌ |
| viewer | ❌ |

---

## 7. Validation DEV

### 7.1 API Agents

```json
GET /agents?tenantId=ecomlg-001 → 200 OK
[
  {"id":33,"first_name":"Ludovic","last_name":"Gonthier","type":"client","role":"admin"},
  {"id":34,"first_name":"Test","last_name":"Agent","type":"client","role":"agent"},
  {"id":35,"first_name":"KeyBuzz","last_name":"Support","type":"keybuzz","role":"agent"}
]
```

### 7.2 API Teams

```json
GET /teams?tenant_id=ecomlg-001 → 200 OK
[]
```
(Aucune team créée — attendu)

### 7.3 Pods DEV

| Service | Pod | Status | Restarts |
|---|---|---|---|
| API | keybuzz-api-f566959b8-l7nd5 | 1/1 Running | 0 |
| Client | keybuzz-client-6c845cb557-mmpbn | 1/1 Running | 0 |

### 7.4 Images déployées

| Service | Image |
|---|---|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.101-ph131-agents-dev` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.101-ph131-agents-dev` |

---

## 8. Commits

### keybuzz-client (GitHub)

| SHA | Message |
|---|---|
| `7d886f0` | PH131-A: agents system - BFF routes, service, UI page, permissions (canManageAgents) |

Base : `e20ded6` (PH131-FIX, baseline promue)

### keybuzz-infra (GitHub)

| SHA | Message |
|---|---|
| `c4f4fb2` | PH131-A: GitOps update - agents system DEV (API v3.5.101 + Client v3.5.101) |

### keybuzz-api (bastion)

Commit local sur bastion : `PH131-A: agents/teams CRUD routes (POST, PATCH, by-user)`

---

## 9. Ce qui N'A PAS été touché

- ❌ Aucun impact PROD
- ❌ Inbox non modifié
- ❌ Assignation PH122 préservée (hook inchangé)
- ❌ Billing non touché
- ❌ Auth non touché
- ❌ Gating PH130 non touché
- ❌ Escalade PH123 non touchée

---

## 10. Ce qui est prêt pour la suite

| Fonctionnalité | Statut |
|---|---|
| CRUD agents (API + UI) | ✅ Opérationnel |
| CRUD teams (API) | ✅ Opérationnel (UI non créée) |
| team_members (table) | ✅ Créée, endpoint POST /teams/:id/members |
| conversations.escalation_target | ✅ Colonne ajoutée, pas encore utilisée |
| Assignation réelle (by-user) | ✅ Endpoint GET /agents/by-user/:userId |
| Permission canManageAgents | ✅ owner/admin |
| Seeder DEV | ✅ 3 agents (1 client/admin, 1 client/agent, 1 keybuzz/agent) |

---

## 11. Limites explicites (STOP POINT)

- **Pas de routage automatique d'escalade** — structure préparée, pas de logique
- **Pas d'autopilot** — à implémenter dans une phase ultérieure
- **Pas de lien assignation ↔ agent** dans l'inbox — l'inbox continue d'utiliser `user.id` pour l'assignation, le mapping agent peut se faire via `/agents/by-user/:userId`
- **Pas d'UI teams** — uniquement l'API
- **Pas de PROD** — DEV uniquement

---

## 12. Note Patroni

Le leader Patroni a changé depuis la documentation initiale :
- **Ancien leader** : db-postgres-01 (10.0.0.120) → maintenant **replica**
- **Nouveau leader** : db-postgres-03 (10.0.0.122) → **primary**
- **db-postgres-02** (10.0.0.121) : réparé, streaming (était en `start failed`)

Le cluster Patroni est maintenant à 1 leader + 2 replicas (meilleur qu'avant).

---

## VERDICT

**PH131-A AGENTS SYSTEM READY**

Stop point. Ne pas implémenter autopilot. Ne pas automatiser. Ne pas router.
