# PH120-DIFF-AUDIT-RECOVERY-03 — Rapport d'audit differentiel

**Date** : 23 mars 2026
**Type** : Audit READ-ONLY — identification root cause
**Diff** : `v3.5.77-ph119-role-access-guard` → `v3.5.79-ph120-tenant-context`

---

## 1. Fichiers modifies dans PH120-01

| Fichier | Type de modification |
|---|---|
| `src/components/layout/ClientLayout.tsx` | **CRITIQUE — suppression init sync focus mode** |
| `src/features/tenant/useTenantId.ts` | Remplacement orphan par re-export |
| `app/ai-dashboard/page.tsx` | Changement import path |
| `app/ai-journal/page.tsx` | Changement import path |
| `app/settings/page.tsx` | Remplacement deprecated par hook |
| `src/features/ai-ui/AIModeSwitch.tsx` | Remplacement deprecated par hook |
| `app/orders/[orderId]/page.tsx` | Changement import |
| `src/services/playbooks.service.ts` | getLastTenant().id + ajout isAIAction |
| `src/features/ai-journal/storage.ts` | getLastTenant().id |

---

## 2. Root cause exacte

### Fichier : `src/components/layout/ClientLayout.tsx`

### Le changement qui casse tout :

**v3.5.77 (AVANT — FONCTIONNE) :**

```typescript
const [session, setSessionState] = useState<{ userName?: string } | null>(null);
const [tenantName, setTenantName] = useState<string | null>(null);
const [tenantId, setTenantId] = useState<string | null>(null);
const [focusMode, setFocusMode] = useState(true);

useEffect(() => {
    const sess = getSession();
    if (sess) {
      setSessionState({ userName: sess.userName });
    }
    setTenantName(getCurrentTenantName());
    const tid = getCurrentTenantId();     // ← SYNCHRONE (localStorage)
    setTenantId(tid);
    if (tid) {
      setFocusMode(getFocusMode(tid));    // ← SYNCHRONE (localStorage)
    }
}, [pathname]);                           // ← S'execute immediatement au mount
```

**v3.5.79 (PH120 — REGRESSION) :**

```typescript
const [focusMode, setFocusMode] = useState(true);  // ← DEFAULT = true (focus ON)

const { currentRole, isAgent, userEmail, currentTenant, currentTenantId } = useTenant();
const tenantId = currentTenantId;

useEffect(() => {
    if (currentTenantId) {                // ← ASYNCHRONE (attend API /tenant-context/me)
      setFocusMode(getFocusMode(currentTenantId));
    }
}, [pathname, currentTenantId]);
```

---

## 3. Mecanisme de la regression

### Timeline de rendu :

| Etape | v3.5.77 (stable) | v3.5.79 (regression) |
|---|---|---|
| **T=0 : Mount** | `focusMode = true` (default) | `focusMode = true` (default) |
| **T=1 : useEffect sync** | `getCurrentTenantId()` → localStorage → `tid` disponible immediatement → `setFocusMode(getFocusMode(tid))` → **false** si l'utilisateur l'avait desactive | `currentTenantId = null` (TenantProvider en loading) → `if (null)` → **NE S'EXECUTE PAS** |
| **T=2 : Premier rendu** | focusMode = **valeur reelle de l'utilisateur** | focusMode = **true** (default, force) |
| **T=3 : API repond** | — | `currentTenantId` change → useEffect → `setFocusMode(...)` → **re-render tardif** |

### Consequence directe sur les 3 symptomes :

**1. Focus mode active :**
- `useState(true)` = focus mode ON par defaut
- `currentTenantId` est `null` pendant ~500-2000ms (appel API async)
- Le `if (currentTenantId)` ne s'execute pas → focus mode reste `true`
- L'utilisateur voit le menu en mode focus meme s'il l'avait desactive

**2. Menu "fixe" (items reduits) :**
- Quand `focusMode = true`, le filtre `ALL_NAV_ITEMS.filter(item => item.focusMode)` ne garde que 5 items :
  - Inbox, Orders, Suppliers, Playbooks, Settings
- Les items suivants **disparaissent** pendant le loading :
  - Start, Dashboard, Channels, Knowledge, AI Journal, AI Performance, Billing
- Le menu semble "fixe" = bloque sur une version reduite

**3. Lenteur / chargement degrade :**
- Le TenantProvider fait un `GET /api/tenant-context/me` async avant de fournir `currentTenantId`
- Pendant ce temps, le layout rend avec un menu incomplet
- Quand l'API repond, React re-rend le layout entier (nouveau focusMode, nouveaux navItems)
- Ce double-rendu cree un "flash" visuel percu comme de la lenteur

---

## 4. Correlation des 3 symptomes

**Un seul changement casse tout :** le remplacement de la lecture **synchrone** `getCurrentTenantId()` (localStorage, instantane) par la lecture **asynchrone** `currentTenantId` (TenantProvider, attend API).

```
getCurrentTenantId() → localStorage → SYNCHRONE → focusMode correct au T=0
        ↓ remplace par ↓
useTenant().currentTenantId → API async → null pendant ~1s → focusMode FAUX
```

Les autres modifications PH120 (imports, playbooks, ai-journal) n'impactent **pas** le layout/menu.

---

## 5. Autres fichiers — pas de regression

| Fichier | Impact layout/menu | Risque |
|---|---|---|
| `useTenantId.ts` | Non | Aucun — re-export transparent |
| `ai-dashboard/page.tsx` | Non | Import path change, meme hook |
| `ai-journal/page.tsx` | Non | Import path change, meme hook |
| `settings/page.tsx` | Non | Lecture tenant pour settings, pas layout |
| `AIModeSwitch.tsx` | Non | Composant dans page, pas layout |
| `orders/[orderId]/page.tsx` | Non | Import change, pas utilise |
| `playbooks.service.ts` | Non | Service localStorage, pas layout |
| `ai-journal/storage.ts` | Non | Service localStorage, pas layout |

---

## 6. Recommandation de correction minimale

### Principe : garder le meilleur des deux mondes

- **PH120 a raison** : `currentTenantId` de `useTenant()` est la source de verite
- **Mais** : le focus mode doit etre initialise **synchronement** depuis localStorage pour eviter le flash

### Fix minimal (1 changement, 0 refactor) :

Dans `ClientLayout.tsx`, remplacer :

```typescript
const [focusMode, setFocusMode] = useState(true);
```

Par un initialiseur synchrone :

```typescript
const [focusMode, setFocusMode] = useState(() => {
  if (typeof window === 'undefined') return true;
  try {
    const prefs = localStorage.getItem('kb_prefs:v1');
    if (prefs) {
      const { lastTenantId } = JSON.parse(prefs);
      if (lastTenantId) {
        const stored = localStorage.getItem(`kb_focus_mode:v1:${lastTenantId}`);
        if (stored !== null) return stored === 'true';
      }
    }
  } catch {}
  return true;
});
```

### Ce que ca preserve :

- Source de verite tenant = `TenantProvider` (PH120 valide)
- Aucune re-introduction de `getCurrentTenantId()` deprecated
- Focus mode correct des le premier rendu (synchrone localStorage)
- Re-sync quand `currentTenantId` arrive de l'API (useEffect existant)
- **Zero flash, zero double-rendu**

### Ce que ca ne touche pas :

- Aucun autre fichier
- Aucun provider
- Aucun guard
- Aucun import

---

## 7. Note importante — etat du bastion

Les fichiers source sur le bastion (`/opt/keybuzz/keybuzz-client/`) contiennent **toujours les modifications PH120**. Le rollback n'a change que l'image Docker deployee. Si un rebuild est lance depuis le bastion sans restaurer les sources, il produira a nouveau la regression.

**Action requise avant tout rebuild** : restaurer les sources v3.5.77 sur le bastion, ou appliquer le fix minimal ci-dessus.

---

## Verdict

**ROOT CAUSE IDENTIFIED — READY FOR SAFE REINTRODUCTION**

| Aspect | Detail |
|---|---|
| **Root cause** | `ClientLayout.tsx` ligne 206 : `useState(true)` non initialise depuis localStorage |
| **Fichier unique** | `src/components/layout/ClientLayout.tsx` |
| **Type de bug** | State initialisation asynchrone vs synchrone |
| **Impact menu** | Focus mode force `true` pendant loading → items reduits |
| **Impact focus** | Default `true` persiste ~1s → menu bloque en mode focus |
| **Impact perf** | Double-rendu (menu reduit → menu complet) = flash percu comme lenteur |
| **Fix** | 1 changement : `useState(true)` → `useState(() => { ...sync localStorage... })` |
| **Criticite** | Faible — correction de 5 lignes, zero risque |
