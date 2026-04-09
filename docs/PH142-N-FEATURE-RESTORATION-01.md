# PH142-N — Feature Restoration

> Date : 2026-04-04
> Env : DEV uniquement
> Image : `ghcr.io/keybuzzio/keybuzz-client:v3.5.191-restore-ph138-dev`
> Git SHA : `ccbbf27`
> Build : depuis Git clone propre (`build-from-git.sh`)

---

## Resume

Restauration ciblee des features client perdues, identifiees dans PH142-L/M.
Basee sur les phases PH138-B/D/E/F/G/H/I/K/L et PH141-E comme source de verite.

---

## Fichiers modifies

| Fichier | Features restaurees | Phase source |
|---|---|---|
| `AutopilotSection.tsx` | `upgradePlan()`, `activateAddon()`, addon gating, CTA cliquables, `div role="button"`, URL sync, banner addon, badge premium | PH138-B/D/E/F/G/I/K/L |
| `useCurrentPlan.tsx` | `hasAgentKeybuzzAddon` state + API read + context | PH138-H |
| `planCapabilities.ts` | `maxAgents`, `maxKeybuzzAgents` par plan | PH141-A/B |
| `settings/page.tsx` | `useSearchParams`, deep-links `?tab=xxx` | PH141-E |

---

## Detail des restaurations

### 1. AutopilotSection.tsx

**Avant** : Blocs verrouilles avec `<button disabled>`, CTA non cliquables (texte `<p>`), aucun concept d'addon, pas de `upgradePlan()`/`activateAddon()`.

**Apres** :
- `upgradePlan(targetPlan)` : appelle `/api/billing/change-plan` puis fallback `/api/billing/checkout-session`
- `activateAddon()` : appelle `/api/billing/checkout-agent-keybuzz` avec redirect `/settings?tab=ai&agent_keybuzz=activated`
- Blocs avec `div role="button"` au lieu de `<button disabled>` — permet les clics sur les CTA enfants
- `requiresAddon` sur escalation `keybuzz`/`both` et action `allow_auto_reply`
- Logique `lockedByPlan` vs `lockedByAddon` — CTA differencies (upgrade plan vs activer addon)
- Banner addon (Autopilot sans addon actif) avec CTA
- Badge "Agent KeyBuzz actif" (addon actif)
- URL sync : `?agent_keybuzz=activated` et `?stripe=success` avec auto-refetch

### 2. useCurrentPlan.tsx

- Ajout `hasAgentKeybuzzAddon: boolean` dans `CurrentPlanData`
- State `hasAgentKeybuzzAddon` avec setter
- Lecture depuis `data.hasAgentKeybuzzAddon` dans la reponse API `/billing/current`
- Expose dans le context et le fallback (default `false`)

### 3. planCapabilities.ts

- Ajout `maxAgents` et `maxKeybuzzAgents` dans `PlanCapabilities`
- Valeurs : Starter=1/0, Pro=2/0, Autopilot=3/1, Enterprise=Infinity/3

### 4. settings/page.tsx

- Import `useSearchParams` depuis `next/navigation`
- `useEffect` qui lit `?tab=xxx` et set `activeTab` si valide
- Array `validTabs` avec les 10 onglets possibles

---

## Routes BFF verifiees

Les 3 routes BFF addon existent (commitees dans le commit precedent) :
- `/api/billing/checkout-agent-keybuzz/route.ts` — POST proxy vers backend
- `/api/billing/agent-keybuzz-status/route.ts` — GET proxy vers backend
- `/api/billing/update-agent-keybuzz/route.ts` — POST proxy vers backend

---

## Workflow Git respecte

1. Commit etat pending PH139-PH142 : `c9cc286` (21 fichiers)
2. Commit API pending : `d20077c` (55 fichiers)
3. Commit restaurations PH138/PH141-E : `1a3e26e` → rebased → `ccbbf27`
4. Push `origin/main` : OK
5. Build `build-from-git.sh` depuis clone propre (SHA `ccbbf27`)
6. GitOps `deployment.yaml` mis a jour

---

## Verification dans le build

| Feature | Present | Chunk |
|---|---|---|
| `checkout-agent-keybuzz` | OUI | 1024 |
| `Agent KeyBuzz` (texte) | OUI | 6567, polyfills |
| `change-plan` | OUI | billing/plan, 1024 |
| `maxAgents` | OUI | layout, ai-journal |

---

## Rollback

```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.48-white-bg-dev -n keybuzz-client-dev
```

---

## Verdict

**FEATURES RESTORED — NO DRIFT — GIT ALIGNED**
