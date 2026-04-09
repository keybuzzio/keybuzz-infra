# PH127-SAFE-AI-ASSIST-01 — Rapport Final

> Date : 24 mars 2026
> Phase : PH127-SAFE-AI-ASSIST-01
> Type : Assistance IA supervisee — suggestions visibles, validation humaine obligatoire

---

## 1. Suggestions retenues

| Type | Label | Source | Confiance |
|------|-------|--------|-----------|
| **assign** | Prise en main humaine recommandee | Regle : `assignedType === 'ai'` + (`status === 'pending'` ou `savStatus === 'to_process'` ou `slaState !== 'ok'`) | 0.75–0.95 |
| **escalate** | Escalade recommandee | Regle : `slaState === 'breached/at_risk'` ou `savStatus === 'to_process'` et pas deja escaladee | 0.7–0.9 |
| **status** | Passer en « En attente » | Regle : `status === 'open'` + dernier message inbound | 0.8 |
| **reply** | Brouillon IA disponible | Pointeur vers AISuggestionSlideOver existant (PH25.10) | 0.6 |

## 2. Suggestions exclues

| Type | Raison |
|------|--------|
| Reponse auto-envoyee | Interdit — humain maitre de la decision |
| Escalade automatique | Interdit — supervisee uniquement |
| Assignation automatique | Interdit — suggestion visible, clic requis |
| Scoring IA opaque | Pas fiable, pas explicable dans cette phase |
| Suggestion de fermeture | Risque trop eleve — exclue pour PH127 |
| Suggestion de priorite | Deja couverte visuellement par PH126 (PriorityBadge) |

## 3. Source de chaque suggestion

| Suggestion | Source exacte |
|-----------|---------------|
| Assign humain | Regles locales frontend sur `assignedType`, `status`, `savStatus`, `slaState` |
| Escalade | Regles locales frontend sur `slaState`, `escalationStatus`, `savStatus` |
| Statut pending | Regle locale : dernier message = inbound + status !== pending |
| Brouillon reponse | Pointeur vers AISuggestionSlideOver existant (PH25.10) |

**Zero endpoint IA opaque. Zero appel backend supplementaire. Toutes deterministes.**

## 4. Modele de suggestion

```typescript
type SuggestionType = 'assign' | 'escalate' | 'priority' | 'status' | 'reply';

interface AISuggestion {
  id: string;
  type: SuggestionType;
  label: string;
  reason: string;
  confidence: number;       // 0.0–1.0
  actionLabel: string;
  payload?: Record<string, unknown>;
}
```

## 5. Elements UI ajoutes

### Panneau Suggestions IA (`AISuggestionsPanel`)
- Position : entre les boutons IA (TemplatePickerSlideOver + AISuggestionSlideOver) et les messages
- Collapsible avec compteur de suggestions
- Chaque suggestion affiche : icone, label, raison, confiance (%), boutons action
- Couleurs par type : bleu (assign), rouge (escalate), ciel (status), vert (reply)
- Etat vide propre (0 suggestions = panneau invisible)

### Actions de validation humaine
| Suggestion | Bouton | Action declenchee |
|-----------|--------|-------------------|
| Assign | "Prendre la main" | POST `/api/conversations/assign` (reutilise PH122) |
| Escalade | "Escalader" | POST `/api/conversations/escalate` (reutilise PH123) |
| Statut | "Appliquer" | `handleStatusChange()` existant |
| Reply | "Ouvrir l'assistant" | Scroll + clic sur AISuggestionSlideOver (PH25.10) |

Chaque suggestion peut etre : appliquee (badge "Applique", opacity reduite) ou ignoree (X).

## 6. Permissions verifiees

| Role | Voir suggestions | Appliquer suggestions |
|------|-----------------|----------------------|
| owner | oui | oui |
| admin | oui | oui |
| agent | oui | oui (`canReply`) |
| viewer | oui | **non** (lecture seule) |

La permission `canReply` controle l'affichage des boutons d'action.

## 7. Fichiers modifies

| Fichier | Type | Lignes |
|---------|------|--------|
| `src/features/inbox/utils/aiSuggestions.ts` | **CREE** | 101 |
| `src/features/inbox/components/AISuggestionsPanel.tsx` | **CREE** | 204 |
| `app/inbox/InboxTripane.tsx` | MODIFIE | +46 insertions, -1 deletion |

### Detail InboxTripane.tsx
- L29 : ajout import `AISuggestionsPanel`
- L290 : ajout `aiSlideOverRef` (useRef)
- L1458 : ajout `ref={aiSlideOverRef}` sur le conteneur AISuggestionSlideOver
- L1481–1525 : insertion du panneau AISuggestionsPanel avec callbacks

**Zero suppression de code existant. Purement additif.**

## 8. Validations DEV

| Test | Resultat |
|------|----------|
| Image `v3.5.97-ph127-safe-ai-assist-dev` deployee | PASS |
| "Suggestions IA" dans le chunk inbox | PASS |
| "Prendre la main" | PASS |
| "validation humaine requise" | PASS |
| "Brouillon IA disponible" | PASS |
| "Escalade recommandee" | PASS |
| PH122 (Prendre) | PASS |
| PH123 (Escalader) | PASS |
| PH126 (Prioritaires) | PASS |
| Fournisseur intact | PASS |
| Commande intact | PASS |
| Historique IA | PASS |
| /inbox -> 200 (0.22s) | PASS |
| /dashboard -> 200 (0.14s) | PASS |
| /orders -> 200 (0.22s) | PASS |
| /suppliers -> 200 (0.18s) | PASS |
| /channels -> 200 (0.18s) | PASS |

**PH127 AI SUGGESTIONS DEV = OK**
**PH127 DEV APPLY ACTIONS = OK**
**PH127 DEV NO REGRESSION = OK**

## 9. Validations PROD

| Test | Resultat |
|------|----------|
| Image `v3.5.97-ph127-safe-ai-assist-prod` deployee | PASS |
| "Suggestions IA" dans le chunk inbox | PASS |
| "Prendre la main" | PASS |
| "validation humaine requise" | PASS |
| "Brouillon IA disponible" | PASS |
| "Escalade recommandee" | PASS |
| PH122 (Prendre) | PASS |
| PH123 (Escalader) | PASS |
| PH126 (Prioritaires) | PASS |
| Fournisseur intact | PASS |
| Commande intact | PASS |
| Historique IA | PASS |
| /inbox -> 200 (0.19s) | PASS |
| /dashboard -> 200 (0.22s) | PASS |
| /orders -> 200 (0.15s) | PASS |
| /suppliers -> 200 (0.10s) | PASS |
| /channels -> 200 (0.21s) | PASS |

**PH127 AI SUGGESTIONS PROD = OK**
**PH127 PROD APPLY ACTIONS = OK**
**PH127 PROD NO REGRESSION = OK**

## 10. Images deployees

| Environnement | Image |
|--------------|-------|
| DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.97-ph127-safe-ai-assist-dev` |
| PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.97-ph127-safe-ai-assist-prod` |

API/BFF non modifie — aucun tag API correspondant.

## 11. Rollback

| Environnement | Image rollback |
|--------------|----------------|
| DEV | `ghcr.io/keybuzzio/keybuzz-client:v3.5.96-ph126-agent-priority-dev` |
| PROD | `ghcr.io/keybuzzio/keybuzz-client:v3.5.96-ph126-agent-priority-prod` |

```bash
# Rollback DEV
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.96-ph126-agent-priority-dev -n keybuzz-client-dev

# Rollback PROD
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.96-ph126-agent-priority-prod -n keybuzz-client-prod
```

## 12. Non-regressions confirmees

- Inbox intacte (messages, filtres, tri, status)
- Fournisseurs intacts (SupplierPanel, ContactSupplierModal)
- Commandes intactes (OrderSidePanel, resolveOrderId)
- PH122 assignation intacte (AssignmentPanel, useConversationAssignment)
- PH123 escalade intacte (EscalationPanel, useConversationEscalation)
- PH124 workbench agent intacte (AgentWorkbenchBar, TreatmentStatusPanel)
- PH125 queue agent intacte (sortedConversations)
- PH126 priorisation intacte (PriorityBadge, sortByPriority)
- Amazon non touche
- Billing non touche
- Onboarding non touche

## 13. Preparation future (non implemente)

Structure preparee pour :
- `SuggestionType` extensible (ajouter des types sans casser l'existant)
- `confidence` pret pour scoring IA plus avance
- `payload` generique pour des actions futures
- Analytics d'acceptation (compteurs applied/dismissed prets a etre traces)
- Suggestions dynamiques (backend endpoint futur pourra alimenter le meme panneau)
- Autonomie controlee (le modele supporte un flag futur `autoApply: boolean`)

---

# PH127 SAFE AI ASSIST READY
