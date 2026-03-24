# PH122-DIFF-AUDIT-RECOVERY-02 — Rapport d'audit différentiel

> Date : 1 mars 2026
> Phase : PH122-DIFF-AUDIT-RECOVERY-02
> Objectif : identifier la root cause des régressions PH122
> Méthode : diff git 57eee5f (PH121) vs 68d4026 (PH122)
> Status : **ANALYSE UNIQUEMENT — aucune modification effectuée**

---

## 1. Diff analysé

```
git diff 57eee5f..68d4026 --stat
```

| Fichier | Insertions | Suppressions | Type |
|---|---|---|---|
| `app/inbox/InboxTripane.tsx` | +392 | -319 | **REWRITE** |
| `src/services/conversations.service.ts` | +35 | -35 | Signatures modifiées |
| `app/api/conversations/assign/route.ts` | +50 | 0 | NOUVEAU |
| `app/api/conversations/unassign/route.ts` | +50 | 0 | NOUVEAU |
| `src/features/inbox/components/AssignmentPanel.tsx` | +88 | 0 | NOUVEAU |
| `src/features/inbox/hooks/useConversationAssignment.ts` | +85 | 0 | NOUVEAU |
| `src/lib/roles.ts` | +11 | 0 | Additif (OK) |
| `src/lib/routeAccessGuard.ts` | +1 | 0 | Additif (OK) |
| **TOTAL** | **+393** | **-319** | |

Les 4 fichiers NOUVEAUX et les 2 ajouts additifs (`roles.ts`, `routeAccessGuard.ts`) sont **sains**.

**Le problème est entièrement dans les 2 fichiers MODIFIÉS** : `InboxTripane.tsx` et `conversations.service.ts`.

---

## 2. ROOT CAUSE

### Root cause unique : InboxTripane.tsx a été RÉÉCRIT au lieu d'être chirurgicalement modifié

PH122 a produit un fichier `InboxTripane.tsx` basé sur une version **obsolète/incomplète** du composant, et non sur la version PH121 réelle. Le résultat est un fichier qui :

- **AJOUTE** correctement les features d'assignation (AssignmentPanel, AssignmentBadge)
- **SUPPRIME** massivement des features existantes non liées à PH122

Le même problème affecte `conversations.service.ts` où les signatures de fonctions ont été "nettoyées" (suppression du paramètre `tenantId`) sans justification fonctionnelle.

---

## 3. Les 10 régressions identifiées

### REGRESSION 1 — tenantId supprimé des appels API (CRITIQUE MAJEURE)

**Fichier** : `src/services/conversations.service.ts`
**Lignes** : signatures de 5 fonctions

```
PH121 : fetchConversationDetail(id, tenantIdRef.current || undefined)
PH122 : fetchConversationDetail(id)                     ← tenantId SUPPRIMÉ

PH121 : sendReply(selectedId, content, visibility, attachmentIds, currentTenantId || undefined)
PH122 : sendReply(selectedId, content, visibility, attachmentIds)  ← tenantId SUPPRIMÉ

PH121 : updateConversationStatus(conv.id, newStatus, currentTenantId || undefined)
PH122 : updateConversationStatus(conv.id, newStatus)               ← tenantId SUPPRIMÉ

PH121 : updateConversationSavStatus(conv.id, newSavStatus, currentTenantId || undefined)
PH122 : updateConversationSavStatus(conv.id, newSavStatus)         ← tenantId SUPPRIMÉ

PH121 : updateConversationAssignee(conv.id, agentId, currentTenantId || undefined)
PH122 : updateConversationAssignee(conv.id, agentId)               ← tenantId SUPPRIMÉ
```

**Impact** : Les fonctions dans `conversations.service.ts` appellent `API_ENDPOINTS.conversationDetail(id)` au lieu de `API_ENDPOINTS.conversationDetail(id, tenantId)`. L'URL générée passe de :
```
/messages/conversations/{id}?tenantId=ecomlg-001
```
à :
```
/messages/conversations/{id}
```

Le `tenantGuard` Fastify utilise `?tenantId=` pour identifier le tenant. Sans ce paramètre, l'API peut rejeter la requête ou retourner des données vides.

**Symptôme** : "messages non affichés" — le détail de conversation ne charge pas.

### REGRESSION 2 — SupplierPanel entièrement supprimé

**Fichier** : `app/inbox/InboxTripane.tsx`

```diff
- import { SupplierPanel } from "@/src/features/inbox/components/SupplierPanel";
- import { ContactSupplierModal } from "@/src/features/inbox/components/ContactSupplierModal";
+ import { AssignmentPanel, AssignmentBadge } from "@/src/features/inbox/components/AssignmentPanel";
```

Le `SupplierPanel` dans le panneau latéral droit (à l'intérieur du `OrderSidePanel`) et le `ContactSupplierModal` sont **entièrement supprimés**.

```diff
- <OrderSidePanel ...>
-   <SupplierPanel
-     tenantId={currentTenantId || ""}
-     conversationId={selectedConversation?.id || null}
-     ...
-   />
- </OrderSidePanel>
- {contactSupplierData && (
-   <ContactSupplierModal ... />
- )}
+ <OrderSidePanel ... />
```

**Symptôme** : "features fournisseurs disparues"

### REGRESSION 3 — Badges cas SAV fournisseurs supprimés

**Fichier** : `app/inbox/InboxTripane.tsx`, liste conversations

```diff
- {conv.supplierCaseStatus && conv.supplierCaseStatus !== 'closed' && (
-   <span className="...">
-     {conv.supplierCaseStatus === 'pending_supplier' ? 'Fourn.' : ...}
-   </span>
- )}
+ <AssignmentBadge assignedType={conv.assignedType || 'ai'} />
```

Les badges "Fourn.", "Client", "En cours" sont **remplacés** par l'AssignmentBadge.

### REGRESSION 4 — Types message source tronqués

**Fichier** : `app/inbox/InboxTripane.tsx`, interface `LocalMessage`

```diff
- messageSource?: 'HUMAN' | 'AI' | 'SYSTEM' | 'TEMPLATE' | 'SUPPLIER_CONTACT' | 'SUPPLIER_INBOUND';
+ messageSource?: 'HUMAN' | 'AI' | 'SYSTEM' | 'TEMPLATE';
```

Et **tout le rendu conditionnel** pour les messages fournisseur est supprimé :
- Alignement (SUPPLIER_INBOUND = gauche, SUPPLIER_CONTACT = droite)
- Couleurs (indigo pour envoi, orange pour réception)
- Badges "Envoi fournisseur" / "Fournisseur"
- Couleurs de texte et timestamps

### REGRESSION 5 — isReplyable supprimé (PH63B)

**Fichier** : `app/inbox/InboxTripane.tsx`, interface `LocalConversation`

```diff
- isReplyable?: boolean;  // PH63B: Amazon non-replyable guard
+ assignedAgentId?: string | null;
+ assignedType?: 'ai' | 'human';
```

Le warning pour conversations Amazon non-répondables est **supprimé** :
```diff
- {selectedConversation?.isReplyable === false && (
-   <div className="px-4 pt-3 pb-1 bg-amber-50 ...">
-     <p>Conversation issue d'une notification Amazon — ...</p>
-   </div>
- )}
```

### REGRESSION 6 — Stats server-side supprimées (PH34)

**Fichier** : `app/inbox/InboxTripane.tsx`

- State `serverStats` supprimé
- Fetch `/api/stats/conversations?tenantId=...` supprimé (~15 lignes)
- State `activeKpi` supprimé (PH36.4 click-to-filter KPI)

### REGRESSION 7 — Canal Octopia supprimé du filtre

**Fichier** : `app/inbox/InboxTripane.tsx`, array `CHANNELS`

```diff
  { id: "cdiscount", label: "Cdiscount", icon: Package },
- { id: "octopia", label: "Octopia", icon: Package },
  { id: "email", label: "Email", icon: Mail },
```

### REGRESSION 8 — Couleurs SAV dégradées

**Fichier** : `app/inbox/InboxTripane.tsx`, dropdown SAV

```diff
- selectedConversation.savStatus === 'to_process' ? 'bg-red-50 ...' :
- selectedConversation.savStatus === 'waiting' ? 'bg-orange-50 ...' :
- selectedConversation.savStatus === 'in_progress' ? 'bg-blue-50 ...' :
- selectedConversation.savStatus === 'closed' ? 'bg-green-50 ...' :
+ selectedConversation.savStatus 
+   ? 'bg-red-50 dark:bg-red-900/20 ...' 
+   : 'hover:bg-gray-100 ...'
```

### REGRESSION 9 — Bouton toggle panneau commande supprimé

**Fichier** : `app/inbox/InboxTripane.tsx`

```diff
- {!orderPanelOpen && (
-   <button onClick={() => setOrderPanelOpen(true)} className="...">
-     <Package className="h-4 w-4" />
-     Commande
-   </button>
- )}
```

### REGRESSION 10 — tenantIdRef supprimé

**Fichier** : `app/inbox/InboxTripane.tsx`

```diff
- const tenantIdRef = useRef(currentTenantId);
- tenantIdRef.current = currentTenantId;
```

Ce ref protégeait contre les stale closures dans les callbacks async. Supprimé sans remplacement.

---

## 4. Corrélation symptômes ↔ régressions

| Symptôme observé | Régression(s) responsable(s) |
|---|---|
| **Messages non affichés** | REGRESSION 1 (tenantId supprimé → API rejet/vide) |
| **Features fournisseurs disparues** | REGRESSIONS 2, 3, 4 (SupplierPanel, badges, types message) |
| **Perte de fonctionnalités** | REGRESSIONS 5-10 (isReplyable, stats, Octopia, couleurs, commande) |

### La REGRESSION 1 est le point unique qui casse le plus

Sans `tenantId` dans les appels API, le `fetchConversationDetail` ne retourne probablement rien. Les messages d'une conversation ne s'affichent pas. Les actions (reply, status, SAV) échouent aussi silencieusement.

### Les REGRESSIONS 2-4 sont un bloc de suppression

L'ensemble du code fournisseur (PH32, PH32.1, PH32.3) a été supprimé en bloc lors du rewrite de InboxTripane.tsx.

### Point de cascade

Il n'y a **pas un seul point** qui casse tout. Il y a **2 problèmes indépendants** :
1. `tenantId` supprimé des services → messages cassés
2. Code fournisseur supprimé de InboxTripane → features fournisseurs disparues

---

## 5. Fichiers PH122 sans problème

Les 6 fichiers suivants sont **sains et réutilisables** tel quel :

| Fichier | Verdict |
|---|---|
| `app/api/conversations/assign/route.ts` | OK — BFF propre, utilise backend existant |
| `app/api/conversations/unassign/route.ts` | OK — BFF propre |
| `src/features/inbox/components/AssignmentPanel.tsx` | OK — composant isolé |
| `src/features/inbox/hooks/useConversationAssignment.ts` | OK — hook isolé |
| `src/lib/roles.ts` (+EscalationRecord) | OK — ajout purement additif |
| `src/lib/routeAccessGuard.ts` (+/api/conversations) | OK — ajout purement additif |

---

## 6. Plan de fix minimal (pour futur rebuild)

### Principe : ADDITIF UNIQUEMENT — zéro suppression

Le rebuild PH122 doit être un **diff purement additif** sur la base PH121.

### conversations.service.ts — 2 ajouts, 0 suppressions

```diff
  interface Conversation {
    ...
    savStatus?: string | null;
    savUpdatedAt?: string | null;
+   assignedAgentId?: string | null;
+   assignedType: 'ai' | 'human';
    createdAt: string;
  }
```

```diff
  function mapApiConversation(c: any): Conversation {
    ...
    savStatus: c.sav_status || c.savStatus || null,
    savUpdatedAt: c.sav_updated_at || c.savUpdatedAt || null,
+   assignedAgentId: c.assigned_agent_id || c.assignedAgentId || null,
+   assignedType: (c.assigned_agent_id || c.assignedAgentId) ? 'human' : 'ai',
    createdAt: c.created_at || c.createdAt || new Date().toISOString(),
  }
```

**NE PAS toucher aux signatures de fonctions. NE PAS supprimer tenantId.**

### InboxTripane.tsx — 5 ajouts chirurgicaux, 0 suppressions

1. **Ajouter import** (après les imports existants, sans supprimer SupplierPanel ni ContactSupplierModal) :
```diff
+ import { AssignmentPanel, AssignmentBadge } from "@/src/features/inbox/components/AssignmentPanel";
```

2. **Ajouter champs** dans `LocalConversation` (APRÈS isReplyable, sans rien supprimer) :
```diff
  isReplyable?: boolean;
+ assignedAgentId?: string | null;
+ assignedType?: 'ai' | 'human';
```

3. **Ajouter mapping** dans `mapApiToLocal` (APRÈS isReplyable, sans rien supprimer) :
```diff
  isReplyable: (conv as any).isReplyable !== undefined ? (conv as any).isReplyable : true,
+ assignedAgentId: (conv as any).assignedAgentId || null,
+ assignedType: (conv as any).assignedType || 'ai',
```

4. **Ajouter AssignmentPanel** après le SAV dropdown (sans rien supprimer) :
```diff
  </div>
+ {/* PH122: Assignment Panel */}
+ <AssignmentPanel
+   conversationId={selectedConversation.id}
+   assignedAgentId={selectedConversation.assignedAgentId || null}
+   onUpdate={(agentId, type) => {
+     setSelectedConversation(prev => prev ? { ...prev, assignedAgentId: agentId, assignedType: type } : prev);
+   }}
+ />
  <span className={`text-xs px-2 py-0.5 rounded ${getChannelBadge(selectedConversation.channel)}`}>
```

5. **Ajouter AssignmentBadge** dans la liste conversations (APRÈS le badge supplier existant, sans rien supprimer) :
```diff
  )}
+ <AssignmentBadge assignedType={conv.assignedType || 'ai'} />
  </div>
```

### Fichiers nouveaux — garder tel quel

Les 4 fichiers nouveaux de PH122 sont réutilisables sans modification :
- `app/api/conversations/assign/route.ts`
- `app/api/conversations/unassign/route.ts`
- `src/features/inbox/components/AssignmentPanel.tsx`
- `src/features/inbox/hooks/useConversationAssignment.ts`

### Ajouts additifs — garder tel quel

- `src/lib/roles.ts` — ajout `EscalationRecord`
- `src/lib/routeAccessGuard.ts` — ajout `/api/conversations`

### Diff estimé du rebuild sain

```
conversations.service.ts : +4 lignes, -0 lignes
InboxTripane.tsx         : +15 lignes, -0 lignes
4 fichiers nouveaux      : identiques
2 fichiers additifs      : identiques
```

**Total : ~20 lignes ajoutées dans les 2 fichiers modifiés, 0 suppressions.**

Contre PH122 original : +393/-319 lignes.

---

## 7. Verdict final

```
╔══════════════════════════════════════════════════════════════════╗
║  PH122 ROOT CAUSE IDENTIFIED — READY FOR SAFE REBUILD          ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  Root cause : InboxTripane.tsx RÉÉCRIT au lieu d'être modifié    ║
║               conversations.service.ts signatures cassées        ║
║                                                                  ║
║  Type : REWRITE MASSIF introduisant 10 régressions               ║
║                                                                  ║
║  Fix : diff purement ADDITIF (~20 lignes ajoutées, 0 supprimé)  ║
║                                                                  ║
║  Risque rebuild : FAIBLE si le principe ADDITIF est respecté     ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 8. Checklist pré-rebuild

Avant de relancer PH122, vérifier que :

- [ ] InboxTripane.tsx de départ est EXACTEMENT celui de PH121 (commit 57eee5f)
- [ ] conversations.service.ts de départ est EXACTEMENT celui de PH121
- [ ] Le diff final ne contient AUCUNE suppression de ligne existante
- [ ] Les imports SupplierPanel, ContactSupplierModal sont TOUJOURS présents
- [ ] Les types SUPPLIER_CONTACT, SUPPLIER_INBOUND sont TOUJOURS dans messageSource
- [ ] Le champ isReplyable est TOUJOURS dans LocalConversation
- [ ] Le paramètre tenantId est TOUJOURS dans toutes les signatures de service
- [ ] La ref tenantIdRef est TOUJOURS présente
- [ ] Le canal Octopia est TOUJOURS dans CHANNELS
- [ ] Les couleurs SAV détaillées sont TOUJOURS en place
- [ ] Le bouton toggle panneau commande est TOUJOURS présent
- [ ] Les stats server-side (PH34) sont TOUJOURS présentes
