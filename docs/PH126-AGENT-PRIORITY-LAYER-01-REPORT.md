# PH126-AGENT-PRIORITY-LAYER-01 — Rapport Final

> Date : 2026-03-24
> Phase : PH126-AGENT-PRIORITY-LAYER-01
> Dependances : PH121 (roles), PH122 (assignation), PH123 (escalade), PH124 (workbench), PH125 (queue)

---

## 1. Regles de priorite retenues

| Niveau | Condition | Score | Justification |
|--------|-----------|-------|---------------|
| **Haute** | SLA breached | 100 | Depassement SLA — urgence absolue |
| **Haute** | Escaladee (PH123) | 95 | Conversation escaladee explicitement |
| **Haute** | SAV `to_process` | 90 | Cas SAV critique non traite |
| **Haute** | SLA at_risk | 80 | Proche depassement SLA |
| **Haute** | Assignee a moi + pending | 70 | Client m'a reecrit — action requise |
| **Moyenne** | Escalade recommandee | 55 | Suggestion d'escalade non actee |
| **Moyenne** | Assignee a moi + open | 50 | En cours de traitement |
| **Moyenne** | Autre agent + pending | 45 | Reprise possible si agent absent |
| **Moyenne** | SAV waiting/in_progress | 40 | SAV en suivi |
| **Moyenne** | Non assigne + pending + unread | 35 | Nouveau message sans prise en charge |
| **Basse** | IA geree, pas urgente | 10 | L'IA gere |
| **Basse** | Resolue | 0 | Deja traitee |

**Ordre** : score decroissant, puis `lastMessageTime` decroissant a score egal.

---

## 2. Logique de calcul

Fichier : `src/features/inbox/utils/conversationPriority.ts`

Fonctions exposees :
- `getConversationPriority(conv, currentUserId)` → `{ level, score, label }`
- `sortByPriority(conversations, currentUserId)` → conversations triees
- `getPriorityStats(conversations, currentUserId)` → `{ high, medium, low, assignedToMeUrgent }`

Champs utilises (tous deja existants, zero nouveau champ backend) :
- `status`, `assignedAgentId`, `assignedType`, `savStatus`, `slaState`, `escalationStatus`, `unread`, `lastMessageTime`

---

## 3. Elements UI ajoutes

### 3.1 Badge de priorite (PriorityBadge)
- Fichier : `src/features/inbox/components/PriorityBadge.tsx`
- Affiche : icone + label pour les niveaux `high` (rouge) et `medium` (orange)
- Invisible pour le niveau `low` (zero surcharge visuelle)
- Position : apres le EscalationBadge dans chaque ligne de conversation

### 3.2 Synthese prioritaires
- Zone conditionnelle dans le panneau de filtres (gauche)
- Visible uniquement quand il y a des conversations haute priorite
- Affiche : nombre urgentes, nombre "a moi", nombre moyennes

### 3.3 Toggle tri prioritaire
- Bouton toggle "Prioritaires d'abord" dans le panneau de filtres
- Quand actif : remplace le tri PH125 (escalation-first) par le tri score-based
- Quand inactif : garde le tri PH125 original (non-regressif)
- Indicateur visuel : toggle rouge quand actif

---

## 4. Fichiers modifies

| Fichier | Action | Lignes |
|---------|--------|--------|
| `src/features/inbox/utils/conversationPriority.ts` | **CREE** | ~130 |
| `src/features/inbox/components/PriorityBadge.tsx` | **CREE** | ~65 |
| `app/inbox/InboxTripane.tsx` | MODIFIE (additif) | +90 lignes |

### Detail InboxTripane.tsx (diff additif uniquement)
- Import : PriorityBadge, conversationPriority, ArrowUp
- State : `prioritySort` (boolean, defaut false)
- Extraction : `user` de useTenant()
- `filteredConversations` : ajout branche `if (prioritySort) return sortByPriority(...)`
- `sortedConversations` : ajout branche `if (prioritySort) return sortByPriority(...)`
- `priorityStats` : nouveau useMemo
- UI synthese : bloc conditionnel apres stats
- UI toggle : "Prioritaires d'abord"
- UI badge : PriorityBadge apres EscalationBadge dans la liste

Zero suppression. Zero rewrite. Zero modification des fichiers core hors InboxTripane.

---

## 5. Coherence PH122-PH125

| Phase | Element | Impact PH126 | Statut |
|-------|---------|--------------|--------|
| PH121 | Roles/permissions | Aucun changement — lecture seule respectee pour viewer | OK |
| PH122 | Assignation | `assignedAgentId` utilise dans le calcul de priorite | OK |
| PH123 | Escalade | `escalationStatus` integre (escalated=95, recommended=55) | OK |
| PH124 | Workbench | AgentWorkbenchBar intact, non modifie | OK |
| PH125 | Queue "Mon travail" | Tri PH125 preserve quand toggle inactif | OK |

---

## 6. Validations DEV

| Check | Resultat |
|-------|----------|
| Image deployee | `v3.5.96-ph126-agent-priority-dev` |
| "Prioritaires" dans bundle | 1 chunk (inbox page) |
| "Prioritaires d'abord" dans bundle | Present |
| "urgente" dans bundle | Present |
| PH122-PH125 non-regression | assignedAgentId(1), escalationStatus(1), Mon travail(1), reprendre(3), Prendre(1) |
| Fournisseurs | SupplierPanel(1), ContactSupplier(1), OrderSidePanel(1) |
| TTFB /login | 265ms |
| TTFB /inbox | 209ms |

**PH126 PRIORITY DEV = OK**
**PH126 DEV UX = OK**
**PH126 DEV NO REGRESSION = OK**

---

## 7. Validations PROD

| Check | Resultat |
|-------|----------|
| Image deployee | `v3.5.96-ph126-agent-priority-prod` |
| "Prioritaires" dans bundle | 1 chunk (inbox page) |
| "Prioritaires d'abord" dans bundle | Present |
| PH122-PH125 non-regression | Escalad(11), Mon travail(1), reprendre(3) |
| Fournisseurs | SupplierPanel(1), ContactSupplier(1), OrderSidePanel(1) |
| TTFB /login | 497ms |
| TTFB /inbox | 376ms |

**PH126 PRIORITY PROD = OK**
**PH126 PROD UX = OK**
**PH126 PROD NO REGRESSION = OK**

---

## 8. Images deployees

| Env | Image |
|-----|-------|
| DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.96-ph126-agent-priority-dev` |
| PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.96-ph126-agent-priority-prod` |

API/BFF : non modifie (zero changement backend).

---

## 9. Rollback

### Client DEV
```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.95-auth-session-logout-stability-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

### Client PROD
```bash
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.95-auth-session-logout-stability-prod -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```

API : aucun rollback necessaire (non modifiee).

---

## 10. Preparation future (non implemente)

Cette couche est conçue pour etre etendue par les phases suivantes :

- **SLA scoring fin** : remplacer les seuils binaires par des scores continus bases sur le temps restant
- **Scoring multi-criteres** : poids configurables par tenant/plan
- **Routage intelligent** : utiliser le score pour assigner automatiquement aux agents
- **Files multi-agents** : filtrer par agent + priorite
- **Supervision manager** : dashboard de suivi des priorites par equipe

La structure `getConversationPriority()` est extensible sans casser l'existant.

---

## Verdict Final

# PH126 AGENT PRIORITY READY
