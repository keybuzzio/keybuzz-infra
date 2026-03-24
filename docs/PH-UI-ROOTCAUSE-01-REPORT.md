# PH-UI-ROOTCAUSE-01 — Audit racine UI client DEV/PROD

> Date : 2026-03-20
> Mode : AUDIT UNIQUEMENT (lecture seule)
> Environnements : DEV + PROD
> Client image : `v3.5.59-channels-stripe-sync` (identique DEV/PROD)

---

## 1. Fichiers responsables

| Responsabilite | Fichier | Utilise reellement |
|---|---|---|
| Layout principal | `app/layout.tsx` | OUI (wrapper root) |
| Layout authentifie | `src/components/layout/ClientLayout.tsx` | **OUI — FICHIER CENTRAL** |
| Sidebar / navigation | `ClientLayout.tsx` lignes 215-262 | OUI |
| Burger menu mobile | `ClientLayout.tsx` ligne 297 (`lg:hidden`) | OUI |
| Focus mode logique | `ClientLayout.tsx` lignes 80-93 + 165 | OUI |
| Focus mode toggle | `ClientLayout.tsx` lignes 266-279 | OUI |
| Onboarding page | `app/onboarding/page.tsx` | OUI |
| Onboarding hub | `src/features/onboarding/components/OnboardingHub.tsx` | OUI |
| Onboarding banner | `src/features/onboarding/components/OnboardingBanner.tsx` | OUI |
| Onboarding storage | `src/features/onboarding/storage.ts` | OUI |
| Auth guard | `src/components/auth/AuthGuard.tsx` | OUI |
| Middleware | `middleware.ts` | OUI |

Aucun fichier fantome, aucun doublon actif. Le `.bak` (`ClientLayout.tsx.bak`) est inactif.

---

## 2. Cause racine : MENU FIXE vs BURGER

### Architecture du menu dans ClientLayout.tsx

Le menu est une sidebar fixe (`aside`) avec ce comportement :

```
className={`fixed inset-y-0 left-0 z-50 w-60 ... lg:relative lg:translate-x-0
  ${sidebarOpen ? "translate-x-0" : "-translate-x-full"}`}
```

**Comportement par design :**

| Breakpoint | Comportement | Normal ? |
|---|---|---|
| `>= lg` (1024px) | Sidebar **toujours visible** (`lg:relative lg:translate-x-0`) | **OUI** |
| `< lg` | Sidebar cachee (`-translate-x-full`), activable via bouton burger (`lg:hidden`) | **OUI** |

Le bouton burger :

```tsx
<button onClick={() => setSidebarOpen(true)} className="lg:hidden ...">
  <Menu className="h-5 w-5" />
</button>
```

### VERDICT MENU

> **Le menu fixe sur desktop EST le comportement normal du code.**
> Il n'y a PAS de mode "burger-only". Le burger n'existe QUE pour les ecrans < 1024px.
> Sur desktop (>= 1024px), la sidebar est TOUJOURS visible. C'est voulu par le code.
>
> **Si l'utilisateur s'attend a un menu burger sur desktop, c'est une attente non implementee, PAS un bug.**

---

## 3. Cause racine : FOCUS MODE ACTIF PAR DEFAUT

### Logique dans le code (ClientLayout.tsx)

```typescript
// Ligne 84-88 : Lecture localStorage
function getFocusMode(tenantId: string): boolean {
  if (typeof window === "undefined") return true;  // SSR default = true
  const stored = localStorage.getItem(getFocusModeKey(tenantId));
  if (stored === null) return true;                 // PREMIERE VISITE = true
  return stored === "true";
}

// Ligne 165 : Etat initial React
const [focusMode, setFocusMode] = useState(true);  // DEFAULT = true
```

### Cle localStorage

```
kb_focus_mode:v1:{tenantId}
```

Exemple : `kb_focus_mode:v1:ecomlg-001`

### Effet du focus mode

Quand `focusMode === true` (defaut), seuls ces items sont affiches :

| Item | `focusMode: true` | Visible en focus ? |
|---|---|---|
| `/start` (Onboarding) | `false` | **NON** |
| `/dashboard` | `false` | **NON** |
| `/inbox` | `true` | OUI |
| `/orders` | `true` | OUI |
| `/channels` | `false` | **NON** |
| `/suppliers` | `true` | OUI |
| `/knowledge` | `false` | **NON** |
| `/playbooks` | `true` | OUI |
| `/ai-journal` | `false` | **NON** |
| `/ai-dashboard` | `false` | **NON** |
| `/settings` | `true` | OUI |
| `/billing` | `false` | **NON** |

### VERDICT FOCUS MODE

> **Le focus mode est `true` PAR DEFAUT dans le code.** C'est hardcode a la ligne 84 (`return true`) et a la ligne 165 (`useState(true)`).
>
> Consequence directe : un nouvel utilisateur ou un navigateur sans localStorage voit un menu reduit a 6 items (inbox, orders, suppliers, playbooks, settings). **Dashboard, channels, billing, onboarding, ai-journal, ai-dashboard sont caches.**
>
> Ce n'est PAS un bug d'etat navigateur. C'est un **choix de design dans le code** avec une valeur par defaut agressive.
>
> Le toggle focus mode est accessible en bas de la sidebar, mais il est peu visible (petit texte "Mode Focus" + toggle).

---

## 4. Cause racine : ONBOARDING "DISPARU"

### Flow d'onboarding

1. Route `/onboarding` → affiche `OnboardingHub`
2. Route `/start` → affiche aussi `OnboardingHub`
3. `OnboardingBanner` → affiche une banniere si `!state.completed`

### Conditions de visibilite

L'onboarding n'est **PAS route-guarde**. N'importe qui peut aller sur `/onboarding` directement.

Le probleme est que l'item de navigation `/start` (Onboarding) a `focusMode: false`. Donc :

> **Quand focus mode est ON (defaut), l'item "Onboarding" disparait du menu.**

L'utilisateur ne voit plus le lien dans la sidebar. La page existe toujours et est accessible via URL directe.

### OnboardingBanner

Le banner est affiche dans les pages (dashboard etc.) uniquement si `!state.completed`.
Mais si le dashboard est AUSSI cache par le focus mode, le banner n'est jamais vu.

### VERDICT ONBOARDING

> **L'onboarding n'est pas casse. Il est cache par le focus mode.**
> L'item `/start` a `focusMode: false` → invisible en mode focus (defaut).
> La page fonctionne si accedee directement via URL.
> Le banner n'est pas visible car il est affiche dans les pages cachees par le focus mode.

---

## 5. Audit etat navigateur

### Cles localStorage trouvees dans le code

| Cle | Usage | Scope tenant |
|---|---|---|
| `kb_focus_mode:v1:{tenantId}` | Focus mode ON/OFF | OUI |
| `kb_current_tenant` | Tenant courant | NON |
| `currentTenantId` | Tenant ID (legacy) | NON |
| `kb_locale` | Langue (FR/EN) | NON |
| `kb_client_onboarding:v1:{tenantId}` | Etat onboarding | OUI |

### Comportement selon contexte navigateur

| Contexte | Focus mode | Menu visible | Onboarding visible |
|---|---|---|---|
| **Profil vierge** (aucun localStorage) | `true` (defaut code) | 6 items | NON (cache par focus) |
| **Profil avec `kb_focus_mode:v1:xxx = false`** | `false` | 12 items | OUI |
| **Incognito** | `true` (defaut code) | 6 items | NON |

> **Le probleme ne disparait PAS sur profil vierge.** La valeur par defaut hardcodee `true` est la cause.

---

## 6. Audit bundle DEV/PROD

| Element | DEV bundle | PROD bundle | Identique |
|---|---|---|---|
| Route `/onboarding` | Presente | Presente | OUI |
| Route `/start` | Presente | Presente | OUI |
| CSS `lg:relative lg:translate-x-0` | Present (2 occurrences) | Present (2 occurrences) | OUI |
| CSS `lg:hidden` (burger) | Present | Present | OUI |
| Focus mode default `true` | Present | Present | OUI |
| API URLs | `api-dev.keybuzz.io` | `api.keybuzz.io` | Correct |

Les bundles DEV et PROD sont **fonctionnellement identiques** (meme codebase `v3.5.59`).

---

## 7. Audit runtime navigateur

### Erreurs console (DEV et PROD identiques)

| Type | Message | Impact |
|---|---|---|
| `error` | `[DEPRECATED] getSession() - Auth is now via cookie. Use useAuth() hook.` | Non bloquant |
| `error` | `[DEPRECATED] getCurrentTenantName() - Use useAuth() hook.` | Non bloquant |
| `error` | `[DEPRECATED] getCurrentTenantId() - Use useAuth() hook.` | **Indirect** |
| `warning` | `[AuthGuard] Public route, keeping status: loading` | Non bloquant |

### Impact des deprecations

`getCurrentTenantId()` retourne `null` si le cookie/session n'est pas configure selon le nouveau systeme. Quand le tenantId est `null`, la fonction `getFocusMode(tid)` (ligne 176) n'est PAS appelee, et l'etat reste a `true` (valeur initiale `useState(true)`).

> **Meme si l'utilisateur avait sauvegarde `focusMode = false`, la deprecation de `getCurrentTenantId()` peut empecher la lecture du localStorage scope tenant.**

---

## 8. Matrice cause racine

| Symptome | Couche en cause | Fichier / cle exacte | Preuve |
|---|---|---|---|
| **Menu fixe sur desktop** | **Code (design voulu)** | `ClientLayout.tsx` L221 : `lg:relative lg:translate-x-0` | CSS Tailwind : sidebar toujours visible >= 1024px |
| **Focus mode ON par defaut** | **Code (valeur par defaut)** | `ClientLayout.tsx` L84 `return true` + L165 `useState(true)` | Hardcode dans le code source |
| **Onboarding disparu** | **Code (focus mode cache l'item)** | `ClientLayout.tsx` L47 : `focusMode: false` sur `/start` | En focus mode, l'item est filtre par L184 |
| **Dashboard/channels/billing caches** | **Code (focus mode)** | L48-58 : items avec `focusMode: false` | Meme filtre L184 |
| **Focus mode non restaure** | **Code (deprecation tenant ID)** | L176 : `getFocusMode(tid)` jamais appele si `tid` est null | `getCurrentTenantId()` deprecated retourne null |

---

## 9. Verdict final

### Cause principale : **CAS E — Cause multiple, avec ordre de responsabilite**

#### Ordre de responsabilite

1. **Focus mode `true` par defaut** (ClientLayout.tsx L84 + L165) — c'est la cause racine primaire. Le code hardcode `true` comme valeur par defaut. Un nouvel utilisateur, un navigateur vierge, ou un incognito voit toujours un menu reduit.

2. **Items onboarding/dashboard/channels marques `focusMode: false`** — ces items sont invisibles quand le mode focus est actif (ce qui est le cas par defaut).

3. **`getCurrentTenantId()` deprecated** — meme si l'utilisateur avait desactive le focus mode, la lecture du localStorage scope tenant peut echouer car le tenant ID n'est pas disponible (session deprecee).

4. **Menu fixe desktop = comportement normal** — la sidebar fixe >= 1024px est le design implementé. Ce n'est pas un bug.

### Reponses aux 5 questions

**1. Pourquoi le menu est-il fixe ?**
→ C'est le design implementé. `lg:relative lg:translate-x-0` rend la sidebar toujours visible sur desktop. Le burger n'existe que pour mobile (`lg:hidden`). Ce n'est pas un bug.

**2. Pourquoi le focus mode est actif ?**
→ La valeur par defaut est `true` (hardcodee L84 + L165). Sans localStorage, c'est toujours ON. Meme avec localStorage, la deprecation de `getCurrentTenantId()` peut empecher la lecture du tenant scope.

**3. Pourquoi l'onboarding disparait ?**
→ L'item `/start` a `focusMode: false`. Quand le focus mode est ON (defaut), il est filtre et n'apparait plus dans le menu. La page existe toujours mais n'est plus accessible depuis la navigation.

**4. Est-ce un probleme DEV/PROD ou global client ?**
→ **Global client.** DEV et PROD utilisent le meme codebase (`v3.5.59`), ont le meme bundle, les memes valeurs par defaut. Le comportement est identique.

**5. Quelle correction minimale corrigera tout sans toucher l'API ?**
→ **Changer la valeur par defaut du focus mode de `true` a `false`** dans `ClientLayout.tsx` :
- L84 : `if (stored === null) return false;`
- L165 : `const [focusMode, setFocusMode] = useState(false);`

Cela affichera tous les items par defaut. L'utilisateur pourra ensuite activer le focus mode s'il le souhaite.

Optionnellement, corriger les deprecations `getSession()` / `getCurrentTenantId()` / `getCurrentTenantName()` pour utiliser les hooks modernes.

---

## 10. Plan de correction minimal (NON execute)

| Priorite | Action | Fichier | Impact |
|---|---|---|---|
| **P0** | Changer focus mode default de `true` a `false` | `ClientLayout.tsx` L84 + L165 | Menu complet par defaut |
| P1 | Ajouter `/start` avec `focusMode: true` | `ClientLayout.tsx` L47 | Onboarding visible meme en focus |
| P1 | Ajouter `/dashboard` avec `focusMode: true` | `ClientLayout.tsx` L48 | Dashboard visible meme en focus |
| P2 | Remplacer `getSession()`/`getCurrentTenantId()` deprecated | `ClientLayout.tsx` | Lecture focus mode fiable |
| P3 | Considerer un menu burger desktop (si souhaite) | `ClientLayout.tsx` CSS | Changement de design |

Aucune de ces corrections ne necessite de modifier l'API, la DB, ou l'infrastructure.
