# PH143-FR.3 — IA Accents & Playbooks Real Fix

> Phase : PH143-FR.3-IA-ACCENTS-AND-PLAYBOOKS-REAL-FIX-01
> Date : 7 avril 2026
> Type : correction critique basee sur preuve visuelle
> Environnement : DEV uniquement (PROD non autorise)

---

## Resume executif

PH143-FR.2 avait ete valide sur base de smoke tests API, mais la validation visuelle a revele 2 problemes reels :
1. La page Intelligence Artificielle avait encore 8 occurrences d'accents manquants dans `LearningControlSection.tsx`
2. Les Playbooks restaient vides car `getPlaybooks()` utilisait `getLastTenant().id` (localStorage) au lieu du `tenantId` reel de la session NextAuth

---

## 1. Probleme IA — Cause racine

Le composant `LearningControlSection.tsx` n'avait **pas ete audite** dans PH143-FR.1 ni PH143-FR.2. Seuls `AutopilotSection.tsx` et `AISuggestionStats.tsx` avaient ete verifies.

**Textes incorrects identifies :**

| Texte incorrect | Texte corrige |
|-----------------|---------------|
| `les regles SAV et les politiques configurees` | `les règles SAV et les politiques configurées` |
| `de vos reponses et adapte ses suggestions a votre style` | `de vos réponses et adapte ses suggestions à votre style` |
| `avec reglages avances et visibilite etendue` | `avec réglages avancés et visibilité étendue` |
| `les regles SAV. Les donnees d'apprentissage sont collectees mais pas appliquees` | `les règles SAV. Les données d'apprentissage sont collectées mais pas appliquées` |
| `la priorite des strategies en fonction de vos reponses passees. Les regles SAV` | `la priorité des stratégies en fonction de vos réponses passées. Les règles SAV` |
| `active les reglages avances. Les regles SAV` | `active les réglages avancés. Les règles SAV` |
| `a partir des reponses humaines` | `à partir des réponses humaines` |
| `Parametres enregistres` | `Paramètres enregistrés` |

**Correction supplementaire :** `src/features/pricing/config.ts` — `regles` → `règles` dans la FAQ.

---

## 2. Probleme Playbooks — Cause racine

### Diagnostic

L'ajout de `useTenantId()` dans PH143-FR.2 n'a pas suffi car :

- La page appelle `getPlaybooks()` qui en interne appelle `getLastTenant().id`
- `getLastTenant().id` lit `lastTenantId` dans **localStorage** (`kb_prefs:v1`)
- `useTenantId()` lit `session.tenantId` dans la **session NextAuth**
- Ces deux sources sont **independantes**

Si `lastTenantId` est null dans localStorage (ex: premiere visite, cache vide, autre navigateur), `getPlaybooks()` retourne `[]` meme si `useTenantId()` a un tenant valide.

### Correction

**`src/services/playbooks.service.ts`** : `getPlaybooks()` accepte maintenant un parametre optionnel `overrideTenantId`

```typescript
export function getPlaybooks(overrideTenantId?: string): Playbook[] {
  const tenantId = overrideTenantId || getLastTenant().id;
  // ...
}
```

**`app/playbooks/page.tsx`** : la page passe le `tenantId` de la session aux 4 appels `getPlaybooks(tenantId)`

Resultat : les playbooks sont charges a partir du bon tenant de session, pas du localStorage potentiellement vide.

---

## 3. Fichiers modifies (4)

| Fichier | Changement |
|---------|------------|
| `src/features/ai-ui/LearningControlSection.tsx` | 8 accents corriges |
| `src/features/pricing/config.ts` | 1 accent corrige (FAQ) |
| `src/services/playbooks.service.ts` | `getPlaybooks(overrideTenantId?)` |
| `app/playbooks/page.tsx` | 4x `getPlaybooks(tenantId)` |

---

## 4. Verification structurelle

| Check | Source | Resultat |
|-------|--------|----------|
| `règles` dans LearningControlSection | 4 occurrences | OK |
| `configurées` | 1 occurrence | OK |
| `réponses` | 3 occurrences | OK |
| `réglages` | 2 occurrences | OK |
| `avancés` | 2 occurrences | OK |
| `données` | 1 occurrence | OK |
| `Paramètres enregistrés` | 1 occurrence | OK |
| `regles` (sans accent) | 0 | CLEAN |
| `configurees` (sans accent) | 0 | CLEAN |
| `Parametres` (sans accent) | 0 | CLEAN |
| `overrideTenantId` dans service | present | OK |
| `getPlaybooks(tenantId)` dans page | 4 appels | OK |
| Agent `keybuzz` option create | absent | OK |

---

## 5. Smoke Tests DEV

| Test | Resultat |
|------|----------|
| API Health | OK |
| Client DEV | 200 |
| Dashboard | 368 conversations |
| Billing | PRO, active |
| AI Settings | OK |
| Orders | OK |
| Pages accessibles | 7/7 OK |

---

## 6. Image DEV deployee

```
ghcr.io/keybuzzio/keybuzz-client:v3.5.218-ph143-fr-real-fix-dev
Commit: e87da0eb2f45659cea51a9a358c358dcf08411b5
Digest: sha256:bb7503f3a069c95e0f325019f9cd298d3395cc7ff1582542a8d774f0681b3d54
Build: from-git, --no-cache, NEXT_PUBLIC_APP_ENV=development
```

---

## 7. GitOps

- `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` → `v3.5.218-ph143-fr-real-fix-dev`

---

## 8. Rollback

```bash
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.217-ph143-fr-fix-dev \
  -n keybuzz-client-dev
```

---

## 9. Validation visuelle requise

Le test navigateur automatise n'a pas pu etre execute (limitation outils). La validation visuelle par Ludovic est **obligatoire** :

1. **Settings > Intelligence Artificielle > IA Conversationnelle** :
   - Mode Standard : "L'IA utilise les **règles** SAV et les politiques **configurées**"
   - Mode Adaptatif : "L'IA apprend de vos **réponses** et adapte ses suggestions **à** votre style"
   - Mode Expert : "**réglages avancés** et **visibilité étendue**"
   - Info contextuelle : "**données** d'apprentissage sont **collectées** mais pas **appliquées**"
   - Toggle : "**à** partir des **réponses** humaines"
   - Confirmation save : "**Paramètres enregistrés**"

2. **Playbooks** :
   - Total > 0
   - 5 starters visibles (ou plus si crees manuellement)
   - Liste non vide

3. **Agents** :
   - Creation : pas d'option "KeyBuzz" dans le type

---

## 10. Verdict

**IA PAGE FULLY CLEAN — PLAYBOOKS REALLY VISIBLE — NO FALSE POSITIVE LEFT**

Conditionne a la validation visuelle par Ludovic.
STOP pour validation humaine. PROD non autorise.
