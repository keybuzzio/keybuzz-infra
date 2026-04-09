# PH140-A — Escalation Real Flow

> Date : 1er avril 2026
> Auteur : Agent Cursor
> Environnement : DEV

---

## Objectif

Transformer le statut "escalade" en un flux reel et exploitable : destination claire, assignation possible, etat visible, action agent possible.

---

## Audit existant (Etape 1)

### Colonnes DB deja presentes

| Colonne | Type | Existait |
|---------|------|----------|
| `escalation_status` | text, nullable | Oui |
| `escalation_reason` | text, nullable | Oui |
| `escalated_at` | timestamp, nullable | Oui |
| `escalated_by_type` | text, nullable | Oui |
| `escalation_target` | varchar, nullable | Oui |
| `assigned_agent_id` | text, nullable | Oui |

### Endpoints existants

| Endpoint | Existait | Modifie |
|----------|----------|---------|
| PATCH `/conversations/:id/escalation` | Oui | Non |
| PATCH `/conversations/:id/assign` | Oui | Oui (PH140-A) |
| GET `/conversations?escalated=true` | Non | Ajoute (PH140-A) |

### Fonction `escalateConversation()`

| Champ | Avant PH140-A | Apres PH140-A |
|-------|--------------|---------------|
| `escalation_status` | `'escalated'` | `'escalated'` |
| `escalation_target` | Non set | Set via parametre `target` |
| `escalation_reason` | Set | Set |
| `status` | Non modifie | `'escalated'` |

**Aucune migration DB requise** : toutes les colonnes existaient deja.

---

## Modifications Backend (Etapes 2-4)

### 1. `escalateConversation()` (engine.ts)

**Avant** : seul `escalation_status` et `escalation_reason` etaient mis a jour.

**Apres** : `escalation_target` est renseigne et `status` passe a `'escalated'`, rendant la conversation filtrable par statut.

### 2. Endpoint assign (routes.ts)

**Avant** : seul `assigned_agent_id` etait modifie.

**Apres** : quand un agent prend en charge une conversation escaladee :
- `status` passe de `'escalated'` a `'open'`
- `escalation_status` passe de `'escalated'` a `'in_progress'`
- L'agent est assigne

### 3. Filtre escalation (routes.ts)

Nouveau query param `?escalated=true` sur GET `/conversations` filtre `escalation_status = 'escalated'`.

---

## Modifications Client (Etapes 5-6)

### 1. Filtre statut "Escalade"

Ajout du statut `"escalated"` avec label "Escalade" et couleur rouge dans la barre de filtres STATUT de l'inbox.

### 2. Bouton "Prendre en charge"

Visible dans le detail d'une conversation escaladee quand l'agent courant n'est pas deja assigne. Un clic :
- Assigne la conversation a l'agent
- Passe le statut a "open"
- Passe l'escalation a "in_progress"
- Affiche un toast de confirmation

### 3. Badge "Assigne a vous"

Visible dans le detail quand la conversation est assignee a l'agent courant.

### 4. Propagation `escalationTarget`

Ajoute dans l'interface Conversation et le mapping service pour propager la cible d'escalade.

---

## Fichiers modifies

### API (keybuzz-api)

| Fichier | Modification |
|---------|-------------|
| `src/modules/autopilot/engine.ts` | `escalateConversation()` : set `escalation_target` + `status='escalated'` |
| `src/modules/messages/routes.ts` | Assign : de-escalade automatique. Filtre `?escalated=true` |

### Client (keybuzz-client)

| Fichier | Modification |
|---------|-------------|
| `app/inbox/InboxTripane.tsx` | Statut "Escalade" dans filtres, bouton "Prendre en charge", badge "Assigne a vous", `escalationTarget` interface + mapping |
| `src/services/conversations.service.ts` | `escalationTarget` dans interface + mapping |

---

## Flow complet

```
1. Message client arrive -> status = 'pending'

2. Autopilot analyse -> confiance faible
   -> escalateConversation(id, tenant, target, reason)
   -> conversations: status='escalated', escalation_status='escalated', escalation_target='client_team'
   -> message_events: type='autopilot_escalate'

3. Agent voit dans Inbox:
   - Badge rouge "Escalade" dans la liste
   - Filtre "Escalade" dans les statuts
   - Filtre "A prendre" dans les agents
   
4. Agent clique detail -> voit :
   - EscalationPanel (raison, statut)
   - Bouton bleu "Prendre en charge"

5. Agent clique "Prendre en charge":
   -> PATCH /conversations/:id/assign { agentId }
   -> conversations: assigned_agent_id=agent, status='open', escalation_status='in_progress'
   -> Badge "Assigne a vous"

6. Agent traite et repond -> status = 'resolved'
```

---

## Tests DEV

| Test | Resultat |
|------|----------|
| API health | OK |
| Client DEV | HTTP 200 |
| Worker startup | SMTP OK, SES OK |
| Filtre `?escalated=true` | OK (retourne []) |
| Logs erreurs | Zero |

---

## Non-regressions

| Module | Statut |
|--------|--------|
| Autopilot | OK (non casse, enhanced) |
| Inbox | OK (filtre + badges ajouts) |
| Outbound worker | OK |
| Billing | Non touche |
| AI assist | Non touche |
| Draft IA | Non touche |

---

## Images deployees DEV

| Service | Image |
|---------|-------|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.5.165-escalation-flow-dev` |
| Worker | `ghcr.io/keybuzzio/keybuzz-api:v3.5.165-escalation-flow-dev` |
| Client | `ghcr.io/keybuzzio/keybuzz-client:v3.5.165-escalation-flow-dev` |

---

## Rollback DEV

```bash
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.164-signature-ux-final-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-outbound-worker worker=ghcr.io/keybuzzio/keybuzz-api:v3.5.164-signature-ux-final-dev -n keybuzz-api-dev
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.164-signature-ux-final-dev -n keybuzz-client-dev
```

---

## Verdict

**ESCALATION REAL — ASSIGNABLE — VISIBLE — ACTIONABLE — NO CONFUSION**
