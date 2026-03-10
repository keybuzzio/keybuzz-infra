# PH58 — Fix filtre inbox "Non lues" (et tous les KPI filters)

> Date : 2026-03-10
> Statut : **DEPLOYE EN DEV, TESTE ET VALIDE**
> Image : `v3.5.76-ph58-filter-fix-dev`
> Rollback : `v3.5.75-journal-enriched-dev`

---

## 1. BUG CONSTATE

**URL** : `https://client-dev.keybuzz.io/inbox`
**Compte test** : eComLG (`ludo.gonthier@gmail.com`)

### Symptome
Cliquer sur un filtre KPI (ex: "Non lues", "SAV actif", "En attente") provoque :
1. Un **flash** : la liste filtree apparait brievement (correct)
2. Puis un **reset immediat** : tous les filtres reviennent a "all", la liste complete reapparait

Le filtre ne tient jamais. La page "clignote" et revient a l'etat initial.

### Reproduction
1. Aller sur `client-dev.keybuzz.io/inbox` (compte eComLG)
2. Cliquer sur le badge "8 Non lues" (ou tout autre KPI)
3. Observer : flash + reset

### Confirmation
Bug confirme visuellement via le navigateur Cursor (screenshots + snapshots DOM) le 2026-03-10.
Le snapshot DOM immediatement apres le clic montre les 8 conversations filtrees + le bouton "Non lues" en etat `active`. Deux secondes plus tard, tout est reset.

---

## 2. CAUSE RACINE

**Fichier** : `keybuzz-client/app/inbox/InboxTripane.tsx`
**Zone** : `useEffect` lignes ~747-784

### Probleme
Le `useEffect` de selection automatique de conversation a une logique de "deep-link recovery" :
- Si l'URL contient `?id=XXX` et que cette conversation n'est pas dans la liste filtree
- Il reset TOUS les filtres pour retrouver la conversation

**Le probleme** : cette logique se declenche aussi quand l'utilisateur clique sur un filtre. Si la conversation actuellement selectionnee n'est pas dans le nouveau jeu filtre, le `useEffect` considere que c'est un deep-link rate et reset tout.

### Flux du bug
```
1. Utilisateur clique "Non lues"
2. filteredConversations = 8 conversations non lues
3. La conversation selectionnee (ex: Christophe) n'est PAS dans les 8
4. useEffect detecte selectedId absent de filteredConversations
5. useEffect reset TOUS les filtres (statusFilter, channelFilter, etc.)
6. filteredConversations revient a 174 → flash terminé
```

---

## 3. FIX APPLIQUE (code local uniquement)

### Principe
Utiliser un `useRef(isInitialDeepLink)` pour distinguer :
- **Deep-link initial** (`?id=XXX` au chargement) → reset filtres OK
- **Clic utilisateur sur un filtre** → NE PAS reset, auto-selectionner la premiere conversation filtree

### Code modifie

**Fichier** : `keybuzz-client/app/inbox/InboxTripane.tsx`
**Lignes** : 747-784

```typescript
// PH-CONV-TYPE-01-v5 + FIX-PH58: Auto-select conversation when filter changes.
// Only reset filters for deep-link arrival (?id=), not for user-initiated filter clicks.
const isInitialDeepLink = useRef(true);

useEffect(() => {
  if (isLoading) return;
  const isDeepLink = isInitialDeepLink.current;

  if (filteredConversations.length === 0) {
    if (selectedId && isDeepLink) {
      const existsUnfiltered = conversations.some((c) => c.id === selectedId);
      if (existsUnfiltered) {
        setStatusFilter("all");
        setChannelFilter("all");
        setSavStatusFilter("all");
        setTypeFilter("all");
        setUnreadOnly(false);
        setActiveKpi(null);
        isInitialDeepLink.current = false;
        return;
      }
    }
    setSelectedId(null);
    setSelectedConversation(null);
    router.replace('/inbox', { scroll: false });
    return;
  }

  isInitialDeepLink.current = false;

  const needsAutoSelect = !selectedId || !filteredConversations.some((c) => c.id === selectedId);
  if (needsAutoSelect) {
    const firstConv = filteredConversations[0];
    setSelectedId(firstConv.id);
    setSelectedConversation(firstConv);
    router.replace(`/inbox?id=${firstConv.id}`, { scroll: false });
  }
}, [filteredConversations, selectedId, router, isLoading, conversations]);
```

### Import requis
`useRef` doit etre importe depuis React (verifier qu'il est deja present dans les imports).

---

## 4. FICHIERS MODIFIES / CREES

| Fichier | Action | Detail |
|---|---|---|
| `keybuzz-client/app/inbox/InboxTripane.tsx` | **MODIFIE** | Fix useEffect lignes 747-784 (isInitialDeepLink useRef). Commentaire renomme de FIX-PH54 vers FIX-PH58. |
| `tmp-scripts/deploy-ph58-filter-fix.sh` | **CREE** | Script de deploiement complet (build Docker, push GHCR, update manifest GitOps, ArgoCD). A verifier/adapter par l'agent deploiement. |
| `keybuzz-infra/docs/PH58-INBOX-FILTER-FIX-REPORT.md` | **CREE** | Ce rapport. |

---

## 5. DEPLOIEMENT EFFECTUE (10 mars 2026)

- Build Docker : `v3.5.76-ph58-filter-fix-dev` (--no-cache)
- Push GHCR : OK
- Manifest k8s : `keybuzz-client-dev/deployment.yaml` mis a jour
- Git commit + push : `333fdf8` sur keybuzz-infra main
- ArgoCD sync : OK (rollout restart force)
- Tests navigateur :
  - "Non lues" (8 conversations) : PASS - filtre tient, pas de flash
  - "En attente" (8 conversations) : PASS - filtre tient
  - "SAV actif" (15 conversations) : PASS - filtre tient
  - Auto-selection premiere conversation filtree : PASS

---

## 6. ROLLBACK

```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.75-journal-enriched-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## 7. NOTE IMPORTANTE : RENOMMAGE PH54 → PH58

Ce fix a initialement ete cree sous le nom **PH54** dans une conversation precedente.
Il a ete **renomme PH58** car **PH54 est deja pris** par "Customer Intent Engine" (deploye en DEV+PROD par l'autre agent, documente dans `ai-engine-ph43-ph44.mdc`).

Toutes les references PH54 liees aux filtres inbox ont ete mises a jour vers PH58.
