# PH-ADMIN-T8.8D.1 — Ad Accounts UI Hardening & Validation

**Phase** : PH-ADMIN-T8.8D.1-AD-ACCOUNTS-UI-HARDENING-VALIDATION-01
**Date** : 2026-04-23
**Environnement** : DEV uniquement
**Type** : Hardening UI + validation navigateur + correction rollback GitOps
**Priorité** : P0

---

## 1. PRÉFLIGHT

| Élément | Valeur |
|---|---|
| HEAD Admin | `0d3582e` (avant patch) |
| Branche Admin | `main` |
| Image Admin DEV | `v2.11.4-ad-accounts-meta-ads-ui-dev` |
| Image Admin PROD | `v2.11.3-metrics-tenant-scope-fix-prod` (inchangée) |
| API DEV | `v3.5.105-tenant-secret-store-ads-dev` |
| API PROD | `v3.5.103-ad-spend-global-import-lock-prod` (inchangée) |
| Repo Admin | clean |
| Repo Infra | clean |

---

## 2. MODIFICATIONS

### 2.1 Token Hardening — `src/app/(admin)/marketing/ad-accounts/page.tsx`

**Problème** : Le composant `TokenBadge` avait un fallback qui affichait `{tokenRef}` brut. Si l'API régresse et renvoie un token non-masqué, il serait visible dans l'UI. De même, `last_error` et les messages d'erreur API pouvaient contenir des tokens Meta (format `EAA...`).

**Corrections** :

1. **Import** `redactTokens` depuis `@/lib/sanitize-tokens`
2. **TokenBadge fallback** : remplacé `{tokenRef}` par texte fixe `Masked` — jamais de valeur brute
3. **last_error** : `redactTokens(acct.last_error?.substring(0, 80))` — filtre tout token dans les erreurs
4. **5 error handlers** (fetch, create, update, sync, delete) : `redactTokens(b.detail || b.error)` — filtre tout token dans les réponses API

### 2.2 Sidebar Icon Map — `src/components/layout/Sidebar.tsx`

**Problème** : Les icônes `Webhook`, `ScrollText`, `BookOpen` étaient importées mais absentes du `iconMap`. Les entrées Marketing utilisant ces icônes s'affichaient sans icône.

**Correction** : Ajout de `Webhook, ScrollText, BookOpen` dans l'objet `iconMap`.

### 2.3 Diff exact

```diff
--- a/src/app/(admin)/marketing/ad-accounts/page.tsx
+++ b/src/app/(admin)/marketing/ad-accounts/page.tsx
@@ -9,6 +9,7 @@
 import { RequireTenant } from '@/components/ui/RequireTenant';
 import { useCurrentTenant } from '@/contexts/TenantContext';
+import { redactTokens } from '@/lib/sanitize-tokens';

@@ -43,7 +44,7 @@ function TokenBadge({ tokenRef }: { tokenRef: string }) {
-  return <span ...>{tokenRef}</span>;
+  return <span ...>Masked</span>;

@@ -93,7 +94,7 @@ (fetchAccounts)
-  throw new Error(b.error || `Erreur ${res.status}`);
+  throw new Error(redactTokens(b.error) || `Erreur ${res.status}`);

@@ -130,7 +131,7 @@ (handleSave - update)
-  throw new Error(b.detail || b.error || `Erreur ${res.status}`);
+  throw new Error(redactTokens(b.detail || b.error) || `Erreur ${res.status}`);

@@ -139,7 +140,7 @@ (handleSave - create)
-  throw new Error(b.detail || b.error || `Erreur ${res.status}`);
+  throw new Error(redactTokens(b.detail || b.error) || `Erreur ${res.status}`);

@@ -156,7 +157,7 @@ (handleSync)
-  throw new Error(b.detail || b.error || `Erreur ${res.status}`);
+  throw new Error(redactTokens(b.detail || b.error) || `Erreur ${res.status}`);

@@ -169,7 +170,7 @@ (handleDelete)
-  throw new Error(b.detail || b.error || `Erreur ${res.status}`);
+  throw new Error(redactTokens(b.detail || b.error) || `Erreur ${res.status}`);

@@ -222,7 +223,7 @@ (last_error display)
-  {acct.last_error.substring(0, 80)}
+  {redactTokens(acct.last_error?.substring(0, 80))}

--- a/src/components/layout/Sidebar.tsx
+++ b/src/components/layout/Sidebar.tsx
@@ -18,7 +18,7 @@
-  BrainCircuit, ToggleRight, ShieldCheck, BarChart3, Bug, Cable, TrendingUp, Megaphone,
+  BrainCircuit, ToggleRight, ShieldCheck, BarChart3, Bug, Cable, TrendingUp, Megaphone, Webhook, ScrollText, BookOpen,
```

---

## 3. VALIDATION NAVIGATEUR RÉELLE — DEV

### 3.1 Tenant KeyBuzz Consulting

| Test | Résultat |
|---|---|
| Page `/marketing/ad-accounts` accessible | OK |
| Compte KBC visible | OK — "KeyBuzz Consulting (legacy migration)" |
| Token badge | "Encrypted" (badge vert) — aucun token brut |
| Création compte test dummy (999999999TEST) | OK — compte créé, badge "Encrypted" |
| Token badge du nouveau compte | "Encrypted" — pas de fuite |
| Suppression via modal | OK — modal "Delete Ad Account" → compte supprimé |
| Refresh après suppression | OK — compte test absent, seul KBC reste |
| Aucun résidu visuel | OK |

### 3.2 Tenant eComLG (isolation)

| Test | Résultat |
|---|---|
| Switch vers eComLG | OK |
| Comptes KBC visibles ? | NON — "No ad accounts" (empty state propre) |
| Aucun résidu KBC | OK |

### 3.3 Retour KeyBuzz Consulting

| Test | Résultat |
|---|---|
| Switch retour KBC | OK |
| Compte KBC réapparaît | OK — données correctes, badge "Encrypted" |
| Aucun résidu eComLG | OK |

### 3.4 États UI

| État | Résultat |
|---|---|
| Loading | OK — "Loading ad accounts..." affiché pendant le chargement |
| Empty | OK — "No ad accounts" pour eComLG |
| Success | OK — messages "Compte créé", "Compte supprimé" |
| Aucun NaN | OK |
| Aucun undefined | OK |
| Aucun mock | OK |

---

## 4. TOKEN SAFETY

| Vérification | Résultat |
|---|---|
| Token brut dans DOM | AUCUN — badge "Encrypted" ou "Masked", jamais de valeur |
| Token brut dans réponses proxy | AUCUN — `token_ref` retourné comme `(encrypted)` par l'API |
| Token brut dans erreurs UI | AUCUN — `redactTokens()` appliqué sur tous les handlers |
| Token brut dans logs navigateur | AUCUN — seuls des logs next-auth pré-existants |
| Token brut dans ce rapport | AUCUN |

---

## 5. SIDEBAR ICON MAP

| Icône | Avant | Après |
|---|---|---|
| `Webhook` | Importée mais pas dans iconMap | Dans iconMap |
| `ScrollText` | Importée mais pas dans iconMap | Dans iconMap |
| `BookOpen` | Importée mais pas dans iconMap | Dans iconMap |
| `Megaphone` | OK (déjà présente) | OK |

Toutes les entrées Marketing ont désormais une icône visible.

---

## 6. ROLLBACK GitOps (CORRECTION)

**Ancienne documentation** (incorrecte) : utilisait `kubectl set image`

**Rollback correct** :

1. Modifier `keybuzz-infra/k8s/keybuzz-admin-v2-dev/deployment.yaml`
2. Remettre l'image `v2.11.4-ad-accounts-meta-ads-ui-dev`
3. `git add` + `git commit` + `git push`
4. `kubectl apply -f k8s/keybuzz-admin-v2-dev/deployment.yaml`
5. `kubectl rollout status deployment/keybuzz-admin-v2 -n keybuzz-admin-v2-dev`

**AUCUN** `kubectl set image` — GitOps strict uniquement.

---

## 7. BUILD & DEPLOY DEV

| Élément | Valeur |
|---|---|
| Commit Admin | `1986a8e` — `PH-ADMIN-T8.8D.1: defense-in-depth redactTokens on ad-accounts + sidebar icon map fix` |
| Image DEV | `ghcr.io/keybuzzio/keybuzz-admin:v2.11.5-ad-accounts-ui-hardening-dev` |
| Digest | `sha256:6c0815664ed8dab2d14b956dcd11ce19d27f5a52320322e77579de369a76e0a9` |
| Build | `--no-cache`, from git, repo clean |
| Commit Infra | `016a2d8` — `PH-ADMIN-T8.8D.1: DEV Admin v2.11.5-ad-accounts-ui-hardening-dev` |
| Deploy | `kubectl apply --force` — rollout successful |
| Pod | `keybuzz-admin-v2-6d5dbc7d74-pvwt8` — Running, 0 restarts |
| Rollback image | `v2.11.4-ad-accounts-meta-ads-ui-dev` |

---

## 8. PROD

| Élément | Valeur |
|---|---|
| Image Admin PROD | `v2.11.3-metrics-tenant-scope-fix-prod` — **INCHANGÉE** |
| Image API PROD | `v3.5.103-ad-spend-global-import-lock-prod` — **INCHANGÉE** |
| Manifest PROD | Non modifié |
| DB PROD | Non modifiée |

---

## 9. VERDICT

**ADMIN ADS ACCOUNTS UI HARDENED AND REAL-BROWSER VALIDATED IN DEV — TOKEN SAFE — GITOPS ROLLBACK DOCUMENTED — PROD UNTOUCHED**

### Résumé des corrections :
1. Defense-in-depth `redactTokens` sur tous les chemins d'affichage token/erreur
2. `TokenBadge` fallback ne peut plus afficher de valeur brute
3. Sidebar `iconMap` complété (Webhook, ScrollText, BookOpen)
4. Rollback documenté en GitOps strict (pas de `kubectl set image`)
5. Validation navigateur complète : CRUD, isolation tenant, absence de résidu, token safety

### Recommandation :
Prêt pour promotion PROD en `v2.11.5-ad-accounts-ui-hardening-prod`.
