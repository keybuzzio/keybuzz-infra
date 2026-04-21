# PH-AUTOPILOT-ESCALATION-CONSUME-DIAGNOSTIC-01 — TERMINE

**Verdict : ROOT CAUSE IDENTIFIED — NO GO (corrections requises)**

**Date** : 2026-04-21
**Environnement** : DEV + PROD (lecture seule)
**Type** : Diagnostic cible consume + handoff reel apres ESCALATION_DRAFT

---

## Preflight

| Element | Valeur |
|---|---|
| Branche | `ph147.4/source-of-truth` |
| HEAD | `1adbf73b` |
| Repo clean | OUI |
| Image DEV | `v3.5.90-autopilot-orderid-prompt-fix-dev` |
| Image PROD | `v3.5.90-autopilot-orderid-prompt-fix-prod` |
| DEV/PROD alignes | OUI |

---

## Reproduction

### Cas reproduit en PROD : `conv-4837f801` (tenant `switaa-sasu-mnc1ouqu`)

| Element | Valeur |
|---|---|
| Draft type | `ESCALATION_DRAFT:0.75` |
| Message envoye ? | **OUI** — outbound reply present |
| Escalade DB ? | **OUI** — `escalation_status = 'escalated'` |
| Handoff visible ? | **PARTIEL** — badge visible, mais pas de distinction onglet, pas d'assignation |

### Cas reproduit en DEV : `conv-35462218` (tenant `switaa-sasu-mnc1x4eq`)

| Element | Valeur |
|---|---|
| Draft type | `ESCALATION_DRAFT:0.75` |
| `draft_applied` cree | OUI — `escalated: true` |
| `consumedAt` ecrit | OUI — `2026-04-20 20:51:18.302057+00` |

### Chronologie precise (`conv-4837f801` PROD)

| Timestamp | Evenement | Status apres |
|---|---|---|
| 21:25:56.910Z | `autopilot_escalate` cree (status=skipped) | `pending` |
| 21:28:51.667Z | consume → `escalation_status='escalated'`, `status='escalated'` | `escalated` |
| 21:28:51.674Z | `message_events` : `autopilot_escalate` insere | `escalated` |
| 21:28:51.787Z | `first_response_at` pose (reply flow) | `escalated` |
| 21:28:51.817Z | **Reply flow** → `status = 'open'` (ecrase) | **`open`** |
| 21:28:51.821Z | `message_events` : `reply` insere | `open` |

**Preuve** : le `status = 'escalated'` est ecrase 150ms apres par le reply flow.

---

## Consume path

### Chemin complet trace

| Etape | Etat | Preuve |
|---|---|---|
| UI : `AISuggestionSlideOver.consumeDraft('applied')` | OK | `AISuggestionSlideOver.tsx` l.145-157 |
| BFF : `POST /api/autopilot/draft/consume` | OK — proxy transparent | `app/api/autopilot/draft/consume/route.ts` |
| API : `POST /autopilot/draft/consume` | OK — route presente | `autopilot/routes.ts` l.270-368 |
| Detection `wasEscalationDraft` | OK | `routes.ts` l.288-295 |
| Update `ai_action_log` | OK — `blocked_reason` → `DRAFT_APPLIED` | `routes.ts` l.298-311 |
| Ecriture `escalation_status='escalated'` | **OK** | `routes.ts` l.325-336 |
| Ecriture `status='escalated'` | **ECRASE** par reply flow | `messages/routes.ts` l.469-473 |
| Insert `message_events` | OK — `autopilot_escalate` | `routes.ts` l.338-343 |
| Log `draft_applied` | OK — `escalated: true` | `routes.ts` l.350-361 |
| Assignation agent | **ABSENT** | Aucun code |
| Notification | **ABSENT** | Aucun code |

---

## Code actuel vs ancien fix E.6/E.7

### Le fix PH143-E.6 EST porte sur `ph147.4/source-of-truth`

| Element | Present dans code actuel ? | Present dans ancien fix ? |
|---|---|---|
| Detection `wasEscalationDraft` (l.294) | **OUI** | OUI |
| `UPDATE conversations SET escalation_status` (l.325) | **OUI** | OUI |
| `INSERT message_events` autopilot_escalate (l.338) | **OUI** | OUI |
| `status = 'escalated'` (l.332) | **OUI** — mais ecrase | OUI (meme bug) |
| Log `draft_applied` avec `escalated: true` (l.358) | **OUI** | OUI |
| Assignation `assigned_agent_id` | **NON** | NON |
| Notification agent | **NON** | NON |

**Conclusion** : le fix E.6 a ete porte integralement. Le bug "status ecrase" et l'absence de handoff reel existaient deja dans le fix E.6 original.

---

## DB

### Schema `conversations` — colonnes escalade

| Colonne | Type | Nullable | Existe ? |
|---|---|---|---|
| `escalation_status` | text | YES | **OUI** |
| `escalation_reason` | text | YES | **OUI** |
| `escalated_at` | timestamptz | YES | **OUI** |
| `escalated_by_type` | text | YES | **OUI** |
| `escalation_target` | varchar | YES | **OUI** |

### Statuts valides du workflow

| Statut | Utilise ? |
|---|---|
| `pending` | OUI — En attente |
| `open` | OUI — Ouvert |
| `resolved` | OUI — Resolu |
| `escalated` | **NON** — aucune conversation avec ce statut |

Pas de CHECK constraint sur `status` — la valeur `escalated` est acceptee par la DB mais n'est pas reconnue par le workflow UI.

### Etat `conv-4837f801` apres consume (PROD)

| Champ | Avant | Apres |
|---|---|---|
| `status` | `pending` | **`open`** (ecrase par reply) |
| `escalation_status` | `null` | **`escalated`** |
| `escalation_reason` | `null` | **"Promesse d'action detectee: je vais m'assurer"** |
| `escalated_at` | `null` | **`2026-04-20T21:28:51.667Z`** |
| `escalated_by_type` | `null` | **`ai`** |
| `escalation_target` | `null` | **`client`** |
| `assigned_agent_id` | `null` | **`null`** (inchange) |

---

## UI / handoff

### Visibilite

| Element | Fonctionne ? | Code |
|---|---|---|
| `EscalationBadge` | **OUI** — lit `escalation_status` | `InboxTripane.tsx` l.1311 |
| Filtre "pickup" (a reprendre) | **OUI** — `escalationStatus === 'escalated' && !assignedAgentId` | `InboxTripane.tsx` l.840 |
| Tri prioritaire | **OUI** — escalated = priorite 0 | `conversationPriority.ts` l.47 |
| Onglet principal | **NON DISTINCT** — conversation dans "Ouvert" | `status = 'open'` (ecrase) |
| Notification agent | **ABSENTE** | Aucun code |
| Assignation automatique | **ABSENTE** | Aucun code |

### Le client LIT `escalation_status` correctement

`conversations.service.ts` l.110 :
```
escalationStatus: c.escalation_status || c.escalationStatus || "none"
```

Le mapping fonctionne. Le badge s'affiche. Mais la conversation reste dans l'onglet "Ouvert" standard sans distinction visuelle forte.

---

## Cause racine

**Le fix PH143-E.6 est present et fonctionnel. L'escalade DB se materialise. Mais le handoff reel ne se concretise pas pour TROIS raisons cumulees :**

### Raison 1 : Race condition `status` (ecrasement)

La route consume (l.332) pose `status = 'escalated'`, mais le flow de reply (`messages/routes.ts` l.473) remet immediatement `status = 'open'` (PH30.4 workflow). La valeur `'escalated'` n'est pas un statut valide du workflow.

**Fichier** : `src/modules/autopilot/routes.ts` l.332
```typescript
status = 'escalated'  // ← pose par consume
```

**Fichier** : `src/modules/messages/routes.ts` l.473
```typescript
"UPDATE conversations SET status = 'open', ..."  // ← ecrase ~150ms apres
```

### Raison 2 : Aucune assignation d'agent

Le code consume ne pose jamais `assigned_agent_id`. La conversation escaladee reste non-assignee. Le filtre "pickup" la montre, mais aucun agent n'est proactivement assigne.

### Raison 3 : Aucune notification

Aucun mecanisme de notification (email, in-app, WebSocket) n'alerte les agents humains qu'une conversation vient d'etre escaladee. L'escalade est silencieuse.

**En resume** : l'escalade existe en DB et le badge s'affiche, mais elle est invisible dans le workflow principal (onglet "Ouvert" standard), passive (aucun agent assigne), et silencieuse (aucune notification).

---

## Correction minimale recommandee

| Action | Scope | Description | Impact |
|---|---|---|---|
| **A (critique)** | `routes.ts` l.332 | Remplacer `status = 'escalated'` par `status = 'pending'` | La conversation remonte dans "En attente" avec badge escalade visible |
| **B (handoff reel)** | `routes.ts` consume | Ajouter `assigned_agent_id` = premier owner/admin du tenant | Agent proactivement assigne |
| **C (notification)** | `routes.ts` consume | Emettre notification in-app aux agents du tenant | Alerte visible |
| **D (UI optionnel)** | `InboxTripane.tsx` | Ajouter sous-filtre "Escaladees" dans les onglets | Distinction visuelle |

### Action A — Fix minimal propose

```typescript
// AVANT (ligne 332, routes.ts)
status = 'escalated',

// APRES
status = 'pending',
```

Ce changement garantit que la conversation remonte dans l'onglet "En attente" apres escalade, avec le badge `EscalationBadge` visible. Le reply flow (`status = 'open'`) ne l'ecrasera que SI l'agent repond effectivement — ce qui est le comportement attendu.

---

## Conclusion

- **Le fix PH143-E.6 est present** dans le code deploye (`ph147.4/source-of-truth`)
- **L'escalade DB fonctionne** (`escalation_status`, `escalation_reason`, `escalated_at` correctement ecrits)
- **Le handoff ne se materialise pas** a cause de : status ecrase, aucune assignation, aucune notification
- **Aucune modification effectuee** — diagnostic lecture seule
- **La correction minimale (Action A)** est un changement d'un seul mot dans une seule ligne

---

## VERDICT FINAL

**ESCALATION HANDOFF ROOT CAUSE IDENTIFIED**

STOP
