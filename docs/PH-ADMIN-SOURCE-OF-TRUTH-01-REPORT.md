# PH-ADMIN-SOURCE-OF-TRUTH-01 — ADMIN REPRODUCIBILITY RECOVERY AUDIT

> Date : 2026-03-24
> Statut : AUDIT TERMINE — aucun build/deploy effectue
> Mode : LECTURE SEULE

---

## 1. Rules Cursor relues

| Fichier | Points retenus |
|---|---|
| `deployment-safety.mdc` (2026-03-24) | REGLE 1 : interdiction `docker build` direct — `build-from-git.sh` obligatoire |
| | REGLE 2 : Git = source unique — `pre-build-check.sh` avant build |
| | REGLE 4 : JAMAIS `kubectl set image` — passer par manifests GitOps |
| | REGLE 5 : Tags versiones obligatoires, pas de `:latest` |
| | REGLE 6 : DEV avant PROD |
| `keybuzz-v3-latest-state.mdc` | Admin v2 indique `v0.23.0-ph87.6b` — OBSOLETE (runtime = v2.10.1) |

**Constat : les builds admin PH-ADMIN-87.13 a 87.15 ont viole les REGLES 1 et 4.**

---

## 2. Inventaire runtime exact

| Env | Image | Tag | Restarts | Age | Status |
|---|---|---|---|---|---|
| DEV | `ghcr.io/keybuzzio/keybuzz-admin` | `v2.10.1-ph-admin-87-15b-dev` | 0 | 19h | Running |
| PROD | `ghcr.io/keybuzzio/keybuzz-admin` | `v2.10.1-ph-admin-87-15b-prod` | 0 | 19h | Running |

Version runtime visible UI : v2.10.0 (hardcode sidebar, pas le tag reel)

---

## 3. Verification fonctionnelle runtime

Verification effectuee dans cette conversation (navigateur PROD) :
- `/` (Control Center) : OK — KPIs, incidents, timeline, tenants, controles globaux
- `/tenants` : OK (via quick action incident)
- `/tenants/ecomlg-001` : OK — cockpit complet avec donnees reelles
- Features 87.13 (Control Center) : OK
- Features 87.14 (actions globales) : OK — toggles, scanner, broadcast, audit log
- Features 87.15 (RBAC + identite) : OK — email sidebar, menu filtre par role
- Sidebar v2.10.0 visible, `ludovic` + `ludovic@keybuzz.pro` affiches

**Runtime fonctionnel et sain.**

---

## 4. Audit repo admin source

| Element | Valeur |
|---|---|
| Branche | `main` |
| HEAD local | `06c0c79c7d5bb1a6be5e53709ca6af3de066f7d8` |
| HEAD remote | `06c0c79c7d5bb1a6be5e53709ca6af3de066f7d8` |
| Commits non pushes | 0 |
| Fichiers modifies | 0 |
| Fichiers untracked | 0 |
| Stash | 0 |

### 5 derniers commits
```
06c0c79 PH-ADMIN-87.15b: fix control-state fetch timing with session
ff1cacd PH-ADMIN-87.15: RBAC clean, agent focus, user identity, role-based navigation
fefa48a PH-ADMIN-87.14: actions automation control center
42ea337 PH-ADMIN-87.13: Global Control Center — dashboard, incidents, timeline, top tenants
9dabcf4 fix: use useSearchParams instead of useTenantSelector for tenant pages
```

**VERDICT REPO ADMIN : CLEAN — Git local = Git remote, 0 dirty, 0 untracked, 0 stash.**

Tous les fichiers critiques des phases 87.x sont commites et pushes :
- `src/config/rbac.ts`
- `src/config/navigation.ts`
- `src/components/layout/Sidebar.tsx`
- `src/app/(admin)/page.tsx`
- `src/app/api/admin/global/actions/*`
- `src/app/api/admin/global/control-state/route.ts`
- `src/middleware.ts`

---

## 5. Audit repo infra

| Element | Valeur |
|---|---|
| Branche | `main` |
| HEAD local | `bb14179fcc8d276fce8aedc374efbc78828fd6c4` |
| HEAD remote | `bb14179fcc8d276fce8aedc374efbc78828fd6c4` |
| Commits non pushes | 0 |
| Fichiers modifies | 0 |
| Fichiers untracked | 0 |

### DRIFT MANIFESTS / RUNTIME — CRITIQUE

| Env | Manifest image tag | Runtime image tag | DRIFT |
|---|---|---|---|
| DEV | `v2.1.4-ph112-ai-control-center` | `v2.10.1-ph-admin-87-15b-dev` | OUI — 8+ versions d'ecart |
| PROD | `v2.1.4-ph112-ai-control-center-prod` | `v2.10.1-ph-admin-87-15b-prod` | OUI — 8+ versions d'ecart |

**Cause** : tous les deploiements 87.12C a 87.15 ont utilise `kubectl set image` directement sans mettre a jour les manifests GitOps. Les manifests Git sont restes figes a ph112.

**Impact** : un `kubectl apply -f` depuis les manifests Git REDEPLOIERAIT l'ancienne version v2.1.4.

---

## 6. Audit API source

Non applicable — les routes admin sont dans `keybuzz-admin-v2` (Next.js app routes), pas dans `keybuzz-api`. Aucune route API backend dependante n'a ete modifiee.

---

## 7. Bastion contamination

### Dockerfile admin
```
COPY package*.json ./    (ligne 9)
COPY . .                 (ligne 11 — COPIE TOUT)
```

### Methode de build utilisee
Tous les builds admin ont ete faits via `docker build` direct dans `/opt/keybuzz/keybuzz-admin-v2/` — le working directory du bastion.

### Etat actuel du working dir
Le repo est CLEAN (0 dirty, 0 untracked). Les changements ont toujours ete commites AVANT le `docker build`.

### Risque de contamination
**FAIBLE mais non nul.** Raisons :
- Les scripts appliquaient des changements, les commitaient, puis buildaient dans la foulee
- Apres commit, le working dir etait clean → le `COPY . .` ne devrait inclure que le code commit
- Mais aucun `pre-build-check.sh` n'a ete execute avant build
- Des fichiers temporaires (`.js` des audits, `.sh` des scripts) auraient pu exister dans le working dir
- Le `.dockerignore` (s'il existe) peut les exclure, mais ce n'est pas garanti

### Un rebuild depuis Git propre reproduirait-il la meme image ?
**PROBABLEMENT OUI**, car le code est commit et le repo est clean. Mais pas garanti a 100% sans verification.

---

## 8. Pipeline safe

| Element | Existe ? | Utilise pour admin ? | Suffisant ? |
|---|---|---|---|
| `build-from-git.sh` | OUI | NON (client seulement) | NON — pas adapte admin |
| `build-admin-from-git.sh` | **NON** | N/A | N/A |
| `pre-build-check.sh` | OUI | NON | OUI si utilise |
| `build-api-from-git.sh` | OUI | NON (API seulement) | NON — pas adapte admin |

**Conclusion pipeline : AUCUN script de build safe n'existe pour l'admin. Tous les builds ont ete faits en violation de REGLE 1.**

---

## 9. VERDICT FINAL

### SOURCE OF TRUTH : PARTIAL

**Ce qui est OK :**
- Git admin reflette le runtime (tous les commits pushes, repo clean)
- Aucun fichier dirty ou untracked
- Le code des phases 87.13 a 87.15 est integralement dans GitHub
- Le runtime est sain et fonctionnel

**Ce qui est BROKEN :**
- Manifests GitOps admin (DEV + PROD) sont a 8+ versions d'ecart du runtime
- Aucun `build-admin-from-git.sh` n'existe
- Tous les builds ont viole REGLE 1 (`docker build` direct)
- Tous les deploiements ont viole REGLE 4 (`kubectl set image` direct)
- Un `kubectl apply` depuis Git redeploierait v2.1.4

**Risque :**
- Un ArgoCD sync ou `kubectl apply` involontaire casserait l'admin en revenant a v2.1.4
- Un rebuild admin n'a pas de pipeline safe

---

## 10. Plan minimal de reparation

**A executer dans cet ordre, apres validation Ludovic :**

### P1 — Mettre a jour les manifests GitOps (CRITIQUE)
1. Modifier `keybuzz-infra/k8s/keybuzz-admin-v2-dev/deployment.yaml` : image → `v2.10.1-ph-admin-87-15b-dev`
2. Modifier `keybuzz-infra/k8s/keybuzz-admin-v2-prod/deployment.yaml` : image → `v2.10.1-ph-admin-87-15b-prod`
3. `git add + commit + push`

### P2 — Creer `build-admin-from-git.sh`
- Clone temporaire de `keybuzz-admin-v2` depuis GitHub
- Build dans le clone (pas dans le working dir bastion)
- Verification working tree clean avant build
- Push image avec tag versionne

### P3 — Verifier rebuild reproductible
- Executer `build-admin-from-git.sh` avec le tag actuel
- Comparer l'image resultante au runtime
- Confirmer que les features 87.x fonctionnent

### P4 — Mettre a jour la rule `keybuzz-v3-latest-state.mdc`
- Admin v2 : `v2.10.1-ph-admin-87-15b` au lieu de `v0.23.0-ph87.6b`

---

## 11. Login slowness triage

### Symptome rapporte
- Clic "Se connecter" → page longue a afficher
- Refresh manuel → page OK

### Analyse du code auth (lecture seule)

**Flow login :**
1. `LoginForm` appelle `signIn('credentials', { redirect: false })`
2. NextAuth fait un POST vers `/api/auth/callback/credentials`
3. `authorize()` dans `auth.ts` :
   - `tryDbUser()` : query DB (`getUserByEmail`) + `bcrypt.compare()` — potentiellement lent
   - Si echec : `tryBootstrapUser()` : `bcrypt.compare()` sur le hash bootstrap
4. Si succes : `router.push(callbackUrl)` (navigation client-side)

**Causes probables :**

| Cause | Probabilite | Detail |
|---|---|---|
| bcrypt.compare() lent | HAUTE | bcrypt avec cost factor 12 peut prendre 200-500ms par comparaison, x2 si DB puis bootstrap |
| DB cold connection | MOYENNE | Premiere query DB apres inactivite peut etre lente (pool reconnection) |
| router.push() sans await | MOYENNE | La navigation client-side peut avoir un delai de rendering |
| Middleware redirect chain | FAIBLE | Le middleware redirige vers `/login` si pas de session, mais c'est rapide |
| Hydration mismatch | FAIBLE | `useSearchParams` dans Suspense est correct |

**Recommandation pour investigation future :**
1. Mesurer le temps de `signIn()` cote client (console.time)
2. Mesurer le temps de `bcrypt.compare()` cote serveur (log)
3. Verifier le pool DB (idle connections, reconnection time)
4. Tester avec bcrypt cost factor 10 au lieu de 12

**Aucun fix effectue — audit uniquement.**
