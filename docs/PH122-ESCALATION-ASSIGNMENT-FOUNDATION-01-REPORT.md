# PH122-ESCALATION-ASSIGNMENT-FOUNDATION-01 — Rapport

**Date** : 24 mars 2026
**Phase** : PH122-ESCALATION-ASSIGNMENT-FOUNDATION-01
**Type** : Fondation escalade et assignation IA/humain
**Verdict** : ESCALATION FOUNDATION READY

---

## 1. Contexte

PH121 a mis en place la fondation roles/permissions/agents.
PH122 ajoute la couche d'assignation de conversation (IA vs humain) et prepare l'escalade.

## 2. Audit existant

| Couche | Existait avant PH122 | Etat |
|---|---|---|
| `assigned_agent_id` colonne DB | Oui | Colonne sur `conversations` |
| `PATCH /messages/conversations/:id/assign` | Oui | Backend Fastify fonctionnel |
| `updateConversationAssignee()` service | Oui | Import inutilise dans InboxTripane |
| `Conversation.assignedAgentId` interface | Non | Absent du mapping |
| `assignedType` (ai/human) | Non | Concept inexistant |
| BFF `/api/conversations/assign` | Non | Inexistant |
| UI assignation inbox | Non | Aucune UI |

## 3. Fichiers crees

| Fichier | Description |
|---|---|
| `app/api/conversations/assign/route.ts` | BFF assign — proxy vers PATCH backend |
| `app/api/conversations/unassign/route.ts` | BFF unassign — envoie agentId=null |
| `src/features/inbox/hooks/useConversationAssignment.ts` | Hook React — state + actions + permissions |
| `src/features/inbox/components/AssignmentPanel.tsx` | Panel + Badge — UI assignation + badge liste |

## 4. Fichiers modifies

| Fichier | Modification |
|---|---|
| `src/services/conversations.service.ts` | Ajout `assignedAgentId` et `assignedType` dans interface + mapping |
| `src/lib/roles.ts` | Ajout `EscalationRecord` interface |
| `src/lib/routeAccessGuard.ts` | Ajout `/api/conversations` aux prefixes publics API |
| `app/inbox/InboxTripane.tsx` | Import AssignmentPanel/Badge, champs dans LocalConversation, panel dans header, badge dans liste, fix getSuppliers(tenantId) |

## 5. Architecture assignation

### Modele derive (pas de modification DB)

```
assignedType = assigned_agent_id ? 'human' : 'ai'
```

- `assigned_agent_id = null` → **IA** gere la conversation
- `assigned_agent_id = userId` → **Humain** assigne

### Flux

```
Conversation ouverte → assignedType = 'ai' (defaut)
Agent clique "Prendre" → POST /api/conversations/assign → assignedType = 'human'
Agent clique "Relacher" → POST /api/conversations/unassign → assignedType = 'ai'
```

### Permissions par role

| Action | owner | admin | agent | viewer |
|---|---|---|---|---|
| Prendre la main | Oui | Oui | Oui | Non |
| Relacher | Oui (si assigne) | Oui (si assigne) | Oui (si assigne) | Non |
| Assigner a un autre | Oui | Oui | Non | Non |

## 6. UI

### Header conversation (InboxTripane)
- Badge **IA** (indigo) ou **Assigne** (emerald)
- Bouton **Prendre** (si IA active et permission canReply)
- Bouton **Relacher** (si assigne a soi-meme)
- Loader pendant la mise a jour

### Liste conversations
- Badge compact **IA** ou **Agent** sur chaque conversation

## 7. Structure escalade preparee

```typescript
interface EscalationRecord {
  id?: string;
  conversationId: string;
  fromAgentId: string | null;
  toAgentId: string | null;
  fromType: 'ai' | 'human';
  toType: 'ai' | 'human';
  reason?: string;
  createdAt?: string;
}
```

Pas de logique implementee — structure prete pour PH123.

## 8. Validations

### DEV

| Verification | Resultat |
|---|---|
| Pages HTTP (6/6) | 200 |
| BFF assign (no auth) | 401 (correct) |
| BFF unassign (no auth) | 401 (correct) |
| Bundle AssignmentPanel | Present (1 chunk statique) |
| Image | `v3.5.88-ph122-escalation-dev` |

### PROD

| Verification | Resultat |
|---|---|
| Pages HTTP (6/6) | 200 |
| Image | `v3.5.88-ph122-escalation-prod` |

## 9. Non-regressions

| Element | Statut |
|---|---|
| Login | OK |
| Dashboard | OK |
| Inbox | OK |
| Orders | OK |
| AI Dashboard | OK |
| Amazon status | Non touche (API inchangee) |
| Menu / focus mode | Non touche |
| Onboarding | Non touche |
| Billing | Non touche |

## 10. Images deployees

| Env | Image |
|---|---|
| **DEV** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.88-ph122-escalation-dev` |
| **PROD** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.88-ph122-escalation-prod` |

## 11. Rollback

| Env | Rollback vers |
|---|---|
| DEV | `v3.5.87-ph121-role-agent-dev` |
| PROD | `v3.5.87-ph121-role-agent-prod` |

## 12. Verdict

### ESCALATION FOUNDATION READY

La fondation assignation + escalade est en place :
- Assignation IA/humain fonctionnelle
- UI minimale dans l'inbox (panel + badges)
- Hook React avec gestion permissions
- BFF endpoints operationnels
- Structure escalade preparee pour PH123
- Zero regression

### Prochaines phases

- **PH123** : Escalade intelligente (logique automatique IA → humain)
- **PH124** : Workbench agent (interface agent dediee)
- **PH125** : Supervision IA (monitoring assignations)
