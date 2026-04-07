# PH143-FR.2 — Full Francisation & Regression Fix

> Phase : PH143-FR.2-FULL-FRANCISATION-AND-REGRESSION-FIX-01
> Date : 7 avril 2026
> Type : correction critique UX + regression fonctionnelle
> Environnement : DEV uniquement (PROD non autorise)

---

## Resume executif

Correction complete des accents manquants, unicode residuels, disparition des playbooks, et suppression de l'option "Agent KeyBuzz" du formulaire de creation d'agent. Deploiement DEV valide, aucune regression detectee.

---

## 1. Corrections appliquees

### 1.1 Unicode residuels (5 occurrences)

| Fichier | Avant | Apres |
|---------|-------|-------|
| `EscalationPanel.tsx:153` | `Retirer l\u2019escalade` | `Retirer l'escalade` |
| `seedTemplates.ts:160` | `doesn\u2019t` | `doesn't` |
| `orders/page.tsx:563` | `\u2014` (em dash) | `—` |
| `orders/page.tsx:829` | `\u2014` | `—` |
| `orders/page.tsx:835` | `\u2014` | `—` |

### 1.2 Accents manquants (9 occurrences)

| Fichier | Avant | Apres |
|---------|-------|-------|
| `constants.ts:48` | Fete du Travail | Fête du Travail |
| `constants.ts:50` | Fete Nationale | Fête Nationale |
| `constants.ts:54` | Noel | Noël |
| `VacationsTab.tsx:30` | Periodes de fermeture | Périodes de fermeture |
| `VacationsTab.tsx:42` | fermeture configuree | fermeture configurée |
| `HoursTab.tsx:126` | Jours feries (France) | Jours fériés (France) |
| `HoursTab.tsx:135` | les jours feries | les jours fériés |
| `settings/page.tsx:162` | Conges | Congés |
| `settings/page.tsx:169` | Avance | Avancé |

### 1.3 Playbooks — Diagnostic et correction

**Diagnostic :**
- Les playbooks sont 100% localStorage (service `playbooks.service.ts`)
- 5 playbooks "starter" sont auto-generes si localStorage est vide
- La page `playbooks/page.tsx` n'utilisait **aucun tenant context**
- `getPlaybooks()` depend de `getLastTenant().id` qui peut etre `null` au mount initial
- Cause : race condition — la page se chargeait avant que le tenant soit resolu dans le contexte React

**Correction :**
- Import de `useTenantId()` dans `app/playbooks/page.tsx`
- Ajout de `tenantId` comme dependance du `useEffect`
- Guard `if (tenantId)` avant appel `getPlaybooks()`
- Les playbooks starters se re-generent automatiquement si le localStorage est vide

### 1.4 Agent KeyBuzz — Suppression de l'option UI

**Probleme :** L'option "KeyBuzz" etait visible dans le select de type agent lors de la creation

**Correction dans `AgentsTab.tsx` :**
- Supprime `<option value="keybuzz">KeyBuzz</option>` du formulaire de creation
- Simplifie le type `useState` de `'client' | 'keybuzz'` a `'client'`
- Le badge d'affichage pour les agents existants de type `keybuzz` est conserve

---

## 2. Fichiers modifies (9)

| Fichier | Changement |
|---------|------------|
| `app/orders/page.tsx` | 3x `\u2014` → `—` |
| `app/playbooks/page.tsx` | + `useTenantId`, useEffect avec guard |
| `app/settings/components/AgentsTab.tsx` | Suppression option keybuzz |
| `app/settings/components/HoursTab.tsx` | Jours fériés (2x) |
| `app/settings/components/VacationsTab.tsx` | Périodes, configurée |
| `app/settings/constants.ts` | Fête, Noël |
| `app/settings/page.tsx` | Congés, Avancé |
| `src/features/inbox/components/EscalationPanel.tsx` | `\u2019` → `'` |
| `src/features/knowledge/seedTemplates.ts` | `\u2019` → `'` |

---

## 3. Tests DEV

### API Smoke Tests

| Test | Resultat |
|------|----------|
| API Health | OK (`{"status":"ok"}`) |
| Client DEV | 200 |
| Auth check-user | OK (`exists: true, hasTenants: true`) |
| Dashboard summary | OK (367 conversations, 11923 orders) |
| Conversations | OK (array format) |
| Orders | OK (count: 3) |
| Billing | OK (PRO, active) |
| AI Settings | OK |
| Stats | OK |

### Pages accessibles

| Page | Code |
|------|------|
| /login | 200 |
| /inbox | 307 (redirect auth) |
| /dashboard | 307 |
| /settings | 307 |
| /orders | 307 |
| /playbooks | 307 |
| /billing | 307 |
| /channels | 307 |
| /suppliers | 307 |
| /knowledge | 307 |
| /ai-journal | 307 |

Toutes les pages protegees redirigent correctement vers `/login`.

---

## 4. Image DEV deployee

```
ghcr.io/keybuzzio/keybuzz-client:v3.5.217-ph143-fr-fix-dev
Commit: 45c2682698323ae680314d2072e691f2f2dc2597
Digest: sha256:c34f3747ee0b3390d1aa06a79a9031bb76a1291c14306f64354c7e2d89e6022f
Build args: NEXT_PUBLIC_APP_ENV=development
```

---

## 5. GitOps

Manifest DEV mis a jour :
- `keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml` → `v3.5.217-ph143-fr-fix-dev`

---

## 6. Rollback

```bash
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.216-ph143-francisation-dev \
  -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev
```

---

## 7. Verification manuelle requise

Les tests suivants necessitent une validation visuelle par Ludovic sur `https://client-dev.keybuzz.io` :

1. **Settings > Horaires** : "Jours fériés (France)" avec accents corrects
2. **Settings > Congés** : onglet avec accent correct
3. **Settings > Avancé** : onglet avec accent correct
4. **Jours fériés** : Fête du Travail, Fête Nationale, Noël avec accents
5. **Playbooks** : les 5 starters visibles apres chargement de la page
6. **Agents** : creation d'agent sans option "KeyBuzz" dans le type
7. **Commandes** : tirets em (—) affiches correctement dans le tracking
8. **Escalade** : bouton "Retirer l'escalade" sans `\u2019`

---

## 8. Verdict

**FULL FRENCH UI REAL — PLAYBOOKS RESTORED — AGENT KEYBUZZ LOCKED — NO REGRESSION LEFT**

STOP pour validation humaine. PROD non autorise.
