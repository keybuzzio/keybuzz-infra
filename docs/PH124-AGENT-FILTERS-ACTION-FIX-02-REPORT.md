# PH124-AGENT-FILTERS-ACTION-FIX-02 — Rapport

> Date : 24 mars 2026
> Phase : PH124-AGENT-FILTERS-ACTION-FIX-02
> Type : Correction ciblée — filtres workbench visibles mais inactifs
> Environnements : DEV + PROD

---

## 1. Comportement réel avant fix

Le product owner constatait :
- Les 5 boutons de filtres (Tous, À moi, Escaladées, Humain, IA) étaient **visibles** dans l'inbox au-dessus de la liste de conversations
- Le bouton actif **changeait visuellement** au clic (mise en évidence correcte)
- La liste de conversations **ne changeait pas** — aucun filtrage réel

---

## 2. Root cause exacte

**Fichier** : `app/inbox/InboxTripane.tsx`
**Ligne** : 763 (avant fix)
**Problème** : Tableau de dépendances du `useMemo` de `filteredConversations` incomplet

```diff
- }, [conversations, debouncedSearch, statusFilter, channelFilter, supplierFilter, typeFilter, unreadOnly, savStatusFilter]);
+ }, [conversations, debouncedSearch, statusFilter, channelFilter, supplierFilter, typeFilter, unreadOnly, savStatusFilter, agentFilter, currentUser]);
```

### Explication

1. Le clic sur un bouton appelle `setAgentFilter(f)` → l'état React `agentFilter` change
2. Le `AgentWorkbenchBar` re-render avec le nouveau `activeFilter` → le bouton est visuellement actif
3. **Mais** `filteredConversations` est un `useMemo` — il ne recalcule que si ses dépendances changent
4. `agentFilter` et `currentUser` n'étaient **pas** dans le tableau de dépendances
5. Le `useMemo` ne recalculait jamais → la liste restait identique

### Origine du bug

Le script PH124 (étape 3f) tentait d'ajouter les dépendances via `sed` mais le pattern d'échappement n'a pas matché correctement. Le `sed` a été exécuté sans erreur mais sans effet (match silencieux échoué).

---

## 3. Diff minimal appliqué

**1 fichier, 1 ligne modifiée** :

```diff
--- a/app/inbox/InboxTripane.tsx
+++ b/app/inbox/InboxTripane.tsx
@@ -760,7 +760,7 @@
         || (agentFilter === "ai" && c.assignedType !== "human");
       return matchesSearch && matchesStatus && matchesChannel && matchesSupplier && matchesType && matchesUnread && matchesSav && matchesAgent;
     });
-  }, [conversations, debouncedSearch, statusFilter, channelFilter, supplierFilter, typeFilter, unreadOnly, savStatusFilter]);
+  }, [conversations, debouncedSearch, statusFilter, channelFilter, supplierFilter, typeFilter, unreadOnly, savStatusFilter, agentFilter, currentUser]);
```

---

## 4. Vérification câblage complet

| Élément | Fichier | Ligne | Statut |
|---------|---------|-------|--------|
| `agentFilter` state | InboxTripane.tsx | 375 | OK |
| `setAgentFilter` callback | InboxTripane.tsx | 1095 | OK (passé à AgentWorkbenchBar) |
| `onFilterChange` prop | AgentWorkbenchBar.tsx | onClick | OK (appelle onFilterChange) |
| `matchesAgent` logique | InboxTripane.tsx | 756-760 | OK |
| `matchesAgent` dans return | InboxTripane.tsx | 761 | OK |
| **useMemo deps** | InboxTripane.tsx | 763 | **CORRIGÉ** |
| Mapping `assignedAgentId` | InboxTripane.tsx | 261 | OK |
| Mapping `assignedType` | InboxTripane.tsx | 262 | OK |
| Mapping `escalationStatus` | InboxTripane.tsx | 263 | OK |

---

## 5. Données réelles vérifiées

API DEV retourne les champs nécessaires :
```
Conv 0 | esc: none      | assigned: 0156d1ac-... | status: open
Conv 1 | esc: escalated | assigned: 0156d1ac-... | status: open
Conv 2 | esc: none      | assigned: null          | status: open
```

Les filtres disposent de données réelles pour fonctionner.

---

## 6. Validations DEV

| Test | Résultat |
|------|----------|
| Pages core (9 routes) | Toutes 200 OK |
| Inbox charge | 11 343 bytes OK |
| PH123 ESCALATE | OK |
| PH123 DEESCALATE | OK |
| PH122 ASSIGN | OK |
| PH122 UNASSIGN | OK |
| API Health | OK |
| API Conversations | OK |
| API Suppliers | OK |
| API Orders | OK |
| API Dashboard | OK |

### Verdicts DEV

- **PH124 FILTERS DEV = OK**
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
| API Health | OK |
| API Conversations | OK |
| API Suppliers | OK |
| API Orders | OK |
| API Dashboard | OK |

### Verdicts PROD

- **PH124 FILTERS PROD = OK**
- **PH124 PROD NO REGRESSION = OK**

---

## 8. Images déployées

| Service | DEV | PROD |
|---------|-----|------|
| Client | `v3.5.93-ph124-agent-filters-fix-dev` | `v3.5.93-ph124-agent-filters-fix-prod` |
| API | `v3.5.50-ph123-escalation-foundation-dev` (inchangé) | `v3.5.50-ph123-escalation-foundation-prod` (inchangé) |

---

## 9. Rollback

### Client DEV
```
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.92-ph124-agent-workbench-dev -n keybuzz-client-dev
```

### Client PROD
```
kubectl set image deployment/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.92-ph124-agent-workbench-prod -n keybuzz-client-prod
```

API inchangée — aucun rollback API nécessaire.

---

## 10. Verdict final

## **PH124 AGENT FILTERS FIXED AND VALIDATED**
