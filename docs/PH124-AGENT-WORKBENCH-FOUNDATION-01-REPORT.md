# PH124-AGENT-WORKBENCH-FOUNDATION-01 — Rapport

> Date : 24 mars 2026
> Phase : PH124-AGENT-WORKBENCH-FOUNDATION-01
> Type : Fondation workbench agent — visibilité, filtres, priorisation humaine
> Environnements : DEV + PROD

---

## 1. Objectif

Construire la première version exploitable du workbench agent dans l'inbox, en s'appuyant sur PH121 (rôles), PH122 (assignation) et PH123 (escalade).

Permettre à un agent humain de mieux voir et traiter ses conversations via des filtres rapides, une synthèse visuelle et un panneau de statut de traitement.

---

## 2. Vues et filtres retenus

### États agent définis

| État | Condition technique |
|------|-------------------|
| Assigné à moi | `assignedAgentId === user.id` |
| Assigné humain | `assignedType === 'human'` |
| Géré par IA | `assignedType !== 'human'` |
| Escaladée | `escalationStatus === 'escalated'` |
| Recommandée | `escalationStatus === 'recommended'` |
| Non assignée | `assignedAgentId === null` |

### Quick-filters workbench

| Filtre | Clé | Logique |
|--------|-----|---------|
| Tous | `all` | Aucun filtrage supplémentaire |
| À moi | `mine` | `assignedAgentId === currentUser.id` |
| Escaladées | `escalated` | `escalationStatus in ('escalated', 'recommended')` |
| Humain | `human` | `assignedType === 'human'` |
| IA | `ai` | `assignedType !== 'human'` |

---

## 3. Éléments UI ajoutés

### AgentWorkbenchBar
- **Emplacement** : entre le header "Conversations" et la liste de conversations
- **Rôle** : barre horizontale de filtres rapides avec compteurs
- **Comportement** : chaque filtre affiche le nombre de conversations correspondantes. Le filtre actif est mis en évidence par une couleur distincte. Compatible avec les filtres existants (statut, canal, SAV, type)

### TreatmentStatusPanel
- **Emplacement** : dans la vue détail conversation, avant AssignmentPanel et EscalationPanel
- **Rôle** : synthèse compacte en une ligne — Mode (IA/Humain), Assignation (à moi/autre/aucune), Escalade (si active, avec raison)
- **Comportement** : lecture seule, mise à jour automatique quand les données changent

### Badges existants (PH122 + PH123)
- `AssignmentBadge` : inchangé (IA/Humain)
- `EscalationBadge` : inchangé (Escaladée/Recommandée)
- Aucun badge supprimé ou remplacé

---

## 4. Fichiers modifiés

### Fichiers créés (2)

| Fichier | Taille | Rôle |
|---------|--------|------|
| `src/features/inbox/components/AgentWorkbenchBar.tsx` | ~80 lignes | Composant barre de filtres rapides |
| `src/features/inbox/components/TreatmentStatusPanel.tsx` | ~75 lignes | Composant statut de traitement |

### Fichiers modifiés (1)

| Fichier | Diff | Nature |
|---------|------|--------|
| `app/inbox/InboxTripane.tsx` | +27 lignes, -1 ligne modifiée | ADDITIF : imports, état, filtre, JSX |

### Détail des modifications InboxTripane.tsx

1. **+2 imports** : AgentWorkbenchBar, TreatmentStatusPanel
2. **+1 ligne** : `const { user: currentUser } = useTenant()` (contexte utilisateur)
3. **+1 ligne** : `const [agentFilter, setAgentFilter] = useState("all")` (état filtre)
4. **+5 lignes** : `matchesAgent` dans `filteredConversations` useMemo
5. **~1 ligne modifiée** : ajout `&& matchesAgent` au return du filtre
6. **+1 ligne** : `agentFilter, currentUser` dans les deps useMemo
7. **+7 lignes** : JSX `<AgentWorkbenchBar />` entre header et liste
8. **+7 lignes** : JSX `<TreatmentStatusPanel />` avant AssignmentPanel

### Fichiers NON modifiés (vérifiés intacts)

- `conversations.service.ts` : inchangé
- `AssignmentPanel.tsx` : inchangé
- `EscalationPanel.tsx` : inchangé
- `SupplierPanel.tsx` : inchangé
- `escalationReasons.ts` : inchangé
- `useConversationAssignment.ts` : inchangé
- `useConversationEscalation.ts` : inchangé

---

## 5. Permissions

- **owner/admin/agent** : voient les filtres workbench et le TreatmentStatusPanel. Peuvent filtrer par "À moi" pour voir leurs conversations assignées
- **viewer** : peut voir les filtres et les statuts mais ne peut pas agir (les actions d'assignation/escalade restent contrôlées par PH121/PH122/PH123)
- **keybuzz_agent** : accès complet

Aucun nouveau système de permissions créé. PH121 réutilisé intégralement.

---

## 6. Validations DEV

| Test | Résultat |
|------|----------|
| Pages core (9 routes) | Toutes 200 OK |
| Inbox charge | 11 343 bytes OK |
| PH123 ESCALATE | OK |
| PH123 DEESCALATE | OK |
| PH122 ASSIGN (self) | OK |
| PH122 UNASSIGN | OK |
| API Conversations | OK |
| API Health | OK |
| API Suppliers | OK |
| API Orders | OK |
| API Dashboard | OK |
| BFF /api/conversations/escalate | 401 (protégé) |
| BFF /api/conversations/deescalate | 401 (protégé) |
| BFF /api/conversations/assign | 401 (protégé) |
| BFF /api/conversations/unassign | 401 (protégé) |

### Verdicts DEV

- **PH124 WORKBENCH DEV = OK**
- **PH124 DEV PERMISSIONS = OK**
- **PH124 DEV NO REGRESSION = OK**

---

## 7. Validations PROD

| Test | Résultat |
|------|----------|
| Pages core (9 routes) | Toutes 200 OK |
| Inbox charge | 11 343 bytes OK |
| PH123 ESCALATE | OK |
| PH123 DEESCALATE | OK |
| PH122 ASSIGN | OK |
| PH122 UNASSIGN | OK |
| API Conversations | OK |
| API Health | OK |
| API Suppliers | OK |
| API Orders | OK |
| API Dashboard | OK |

### Verdicts PROD

- **PH124 WORKBENCH PROD = OK**
- **PH124 PROD PERMISSIONS = OK**
- **PH124 PROD NO REGRESSION = OK**

---

## 8. Images déployées

| Service | DEV | PROD |
|---------|-----|------|
| Client | `v3.5.92-ph124-agent-workbench-dev` | `v3.5.92-ph124-agent-workbench-prod` |
| API | `v3.5.50-ph123-escalation-foundation-dev` (inchangé) | `v3.5.50-ph123-escalation-foundation-prod` (inchangé) |

**Note** : l'API n'a pas été modifiée — PH124 est une phase client-only.

---

## 9. Rollback

### Client DEV
```
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.91-ph123-escalation-foundation-dev -n keybuzz-client-dev
```

### Client PROD
```
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.91-ph123-escalation-foundation-prod -n keybuzz-client-prod
```

API inchangée — aucun rollback API nécessaire.

---

## 10. Préparation PH125+

PH124 prépare le terrain pour :
- **File agent** : le filtre "À moi" est la base d'une work queue
- **Supervision IA** : le filtre "IA" isole les conversations gérées automatiquement
- **Vues "mes conversations"** : le `currentUser.id` est déjà intégré au système de filtrage
- **Priorisation avancée** : la hiérarchie escaladé > recommandé > assigné est en place

Structure extensible via l'`AgentFilterKey` type et les `AGENT_FILTERS` dans `AgentWorkbenchBar.tsx`.

---

## 11. Verdict final

## **PH124 AGENT WORKBENCH FOUNDATION READY**
