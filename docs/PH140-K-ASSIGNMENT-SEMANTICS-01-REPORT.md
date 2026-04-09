# PH140-K — Assignment Semantics

> **Date** : 2 mars 2026
> **Environnement** : DEV uniquement
> **Tag** : `v3.5.175-assignment-semantics-dev`
> **Statut** : DEPLOYE DEV + PROD

---

## Objectif

Rendre le systeme d'assignation et de responsabilite des conversations clair, coherent et comprehensible par un utilisateur non technique.

---

## Problemes identifies (audit)

| Composant | Probleme | Impact |
|---|---|---|
| `ConversationActionBar` | Bouton "Liberer" | Ambigu, ne dit pas ou va la conversation |
| `AssignmentPanel` | Bouton "Relacher" (different de "Liberer" !) | Incoherence terminologique |
| `AssignmentPanel` | Bouton "Prendre" (tronque) | Ambigu, action floue |
| `TreatmentStatusPanel` | "Mode : Humain / IA" | Jargon technique incomprehensible |
| `TreatmentStatusPanel` | Double info "Mode" + "Assignation" | Redondant et confus |
| `AssignmentBadge` | Badge "IA" dans la liste | Non-technique ne comprend pas |
| Filtres `AgentWorkbenchBar` | "A traiter" pour "non assignees" | Semantique imprecise |
| Filtres `AgentWorkbenchBar` | "Assigne a moi" | Jargon technique |
| Hook `useConversationAssignment` | `canTakeOver` bloque si assigne a un humain | Empeche de reprendre une conversation d'un autre agent |
| Tooltips | "Relacher vers l'IA" | Implique faussement que l'IA reprend |

---

## Regles semantiques definies

### Prendre en charge
- `assigned_agent_id` = utilisateur courant
- Bouton visible si conversation non assignee a l'utilisateur
- Tooltip : "Vous devenez responsable de cette conversation"

### Remettre en file
- `assigned_agent_id` = null
- Conversation redevient disponible pour tous les agents
- Tooltip : "La conversation redevient disponible pour tous les agents"

### Marquer resolu
- `status` = resolved
- `assigned_agent_id` conserve (historique)
- Tooltip : "Clore cette conversation"

### Escalader / Retirer escalade
- Inchange (fonctionnel, semantique claire)

---

## Modifications appliquees

### Avant / Apres

| Element | Avant | Apres |
|---|---|---|
| Bouton desassigner (ActionBar) | "Liberer" | **"Remettre en file"** |
| Bouton desassigner (Panel) | "Relacher" | **"Remettre en file"** |
| Bouton assigner (Panel) | "Prendre" | **"Prendre en charge"** |
| Badge assigne (ActionBar) | "Assigne a vous" | **"Vous etes responsable"** |
| Badge assigne (Panel) | "Assigne" | **"Responsable"** |
| Badge non-assigne (liste) | "IA" | **"File"** |
| Header conversation | "Mode : Humain / IA" + "Assignation : ..." | **"Responsable : File d'attente / Vous / Autre agent"** |
| Filtre workbench | "A traiter" | **"Non assignees"** |
| Filtre workbench | "Assigne a moi" | **"Mes conversations"** |
| Résumé workbench | "X assignee(s)" | **"X a moi"** |
| Résumé workbench | "X a traiter" | **"X en file"** |
| Badge liste conversation | "Assigne a moi" | **"Vous"** |
| Tooltip assigner | "Prendre la main sur cette conversation" | **"Vous devenez responsable de cette conversation"** |
| Tooltip desassigner | "Relacher vers l'IA" | **"Remettre la conversation en file d'attente"** |
| Tooltip resoudre | _(aucun)_ | **"Clore cette conversation"** |
| Hook `canTakeOver` | Bloque si `assignedType === 'ai'` | **Permet toujours (sauf si deja a moi)** |

---

## Fichiers modifies

| Fichier | Modification |
|---|---|
| `src/features/inbox/components/ConversationActionBar.tsx` | Labels, tooltips, badge |
| `src/features/inbox/components/AssignmentPanel.tsx` | Labels, tooltips, badge "Responsable" + "File" |
| `src/features/inbox/components/TreatmentStatusPanel.tsx` | Reecrit : "Responsable : [nom]" unique + icone |
| `src/features/inbox/components/AgentWorkbenchBar.tsx` | Labels filtres + resume |
| `src/features/inbox/hooks/useConversationAssignment.ts` | `canTakeOver` sans restriction `assignedType` |
| `app/inbox/InboxTripane.tsx` | Badge "Vous" (remplace "Assigne a moi") |

---

## Tests realises (navigateur reel DEV)

- Filtres workbench : "Tous 322" / "Non assignees 251" / "Escalade" / "Mes conversations" — **OK**
- Resume : "Mon travail : 251 en file" — **OK**
- Badge liste : "File" visible sur conversations non assignees — **OK**
- Detail conversation : "Responsable : File d'attente" visible — **OK**
- Boutons : "Prendre en charge" / "Marquer resolu" — **OK**
- Sidebar et navigation owner — **OK**

---

## Non-regressions

- PH140-J (agent lockdown) : non impacte (pas de modification middleware/layout)
- PH140-I (invite UX) : non impacte
- Billing : non touche
- Onboarding : non impacte

---

## Rollback

```bash
# DEV
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.174-agent-hard-access-lockdown-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev

# PROD
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.174-agent-hard-access-lockdown-prod -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod
```

---

## Deploiement PROD

- **Image** : `ghcr.io/keybuzzio/keybuzz-client:v3.5.175-assignment-semantics-prod`
- **Build args** : `NEXT_PUBLIC_API_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io`, `NEXT_PUBLIC_APP_ENV=production`
- **Rollout** : `deployment "keybuzz-client" successfully rolled out`
- **Health** : `HTTP 200` en 0.52s
- **Pod** : `1/1 Running`, 0 restarts, worker-02
