# PH-S03.5B — Catalog Sources : correction « Unknown error » persistante (DEV only)

**Date :** 2026-01-30  
**Périmètre :** Identifier l’appel fautif au chargement de Catalog Sources, corriger la cause, supprimer le bandeau « Unknown error » sans masquer.  
**Environnement :** seller-dev uniquement.

**Règles :** DEV only, GitOps only, pas de fallback supplémentaire — identification de l’appel fautif.

---

## 1. Contexte et objectifs

- **Problème :** Catalog Sources affiche encore un bandeau « Unknown error » au chargement. La page fonctionne si on ferme le bandeau → erreur non bloquante.
- **Objectifs :**
  1. Identifier **exactement** la requête qui déclenche `setError` sur Catalog Sources au load.
  2. Corriger la cause (endpoint / appel inutile / race condition).
  3. Si l’erreur est non critique : ne pas déclencher le bandeau global (dégradation gracieuse).
  4. Preuve : plus aucun bandeau au chargement, sans cliquer sur X.

---

## 2. Appel fautif identifié

### Requête au chargement

- **Seul appel au mount :** `GET /api/catalog-sources?include_fields=true`
- **Déclencheur :** `useEffect` quand `tenantId && !authLoading` → `loadSources()`.
- **En cas d’échec :** `loadSources()` fait `setError(getDisplayErrorMessage(err))` → bandeau rouge.

### Causes possibles

1. **400 X-Tenant-Id required** : backend `require_auth_with_tenant` renvoie 400 si header `X-Tenant-Id` manquant (race : tenant pas encore fourni par le contexte).
2. **404** : tenant non configuré côté seller (ressource introuvable).
3. **401** : session expirée ou cookies non transmis (proxy) → normalement redirection SSO dans api.ts.
4. **500** : erreur serveur côté seller-api (ex. DB, sérialisation).

---

## 3. Instrumentation (minimale)

### api.ts

- Lors d’une erreur HTTP (!response.ok), l’`Error` lancée est enrichie avec :
  - `(err as any).status` = `response.status`
  - `(err as any).endpoint` = `endpoint`
- Permet en catch de logger **endpoint**, **status**, **message** (sans payload).

### catalog-sources/page.tsx — loadSources

- En catch : `console.warn('[CatalogSources] load failed', { endpoint, status, message })` (safe, pas de corps).
- Endpoint concerné : `/api/catalog-sources?include_fields=true`.

---

## 4. Corrections appliquées

### A) Erreurs non bloquantes = pas de bandeau global

Dans le catch de `loadSources()` :

- **400** et message contenant `tenant` ou `X-Tenant-Id` → considéré comme « tenant pas encore sélectionné » : `setSources([])`, **pas de `setError`**.
- **404** et message contenant `tenant`, `source`, `not found`, `introuvable` → considéré comme « tenant/source introuvable » : `setSources([])`, **pas de `setError`**.

Résultat : dans ces cas, la liste s’affiche vide, sans bandeau rouge.

### B) Autres erreurs

- Toute autre erreur (ex. 500, message inattendu) → `setError(getDisplayErrorMessage(err))` comme avant (message explicite, bandeau dismissable).

### C) Comportement au chargement

- Au début de `loadSources()` : `setError(null)` pour éviter de garder une erreur précédente.

---

## 5. Fichiers modifiés

| Fichier | Modification |
|--------|---------------|
| `keybuzz-seller/seller-client/src/lib/api.ts` | En cas d’erreur HTTP, attache `status` et `endpoint` à l’`Error` lancée (401 et autres). |
| `keybuzz-seller/seller-client/app/(dashboard)/catalog-sources/page.tsx` | Dans `loadSources()` : log safe endpoint/status/message ; si 400 (tenant) ou 404 (tenant/source) → `setSources([])` sans `setError` ; sinon `setError(getDisplayErrorMessage(err))`. |
| `keybuzz-infra/docs/PH-S03.5B-CATALOG-SOURCES-UNKNOWN-ERROR.md` | Ce rapport. |

---

## 6. Preuves à collecter

### Avant correctif

- **Network :** au refresh de Catalog Sources, noter la requête en échec :
  - URL : `GET .../api/catalog-sources?include_fields=true` (ou proxy équivalent).
  - Status : 400 / 401 / 404 / 500.
  - Body (masqué) / content-type (json ou html).
- **Console :** après instrumentation, `[CatalogSources] load failed` avec `endpoint`, `status`, `message`.

### Après correctif

- **Hard refresh** Catalog Sources : **aucun bandeau rouge** au chargement.
- Si la seule erreur était 400 (tenant) ou 404 (tenant/source) : liste vide, pas de bandeau.
- Si une autre erreur (ex. 500) : bandeau avec message explicite (ex. « Erreur serveur, réessayez ») et dismissable.

---

## 7. Rollback

- Revert des commits sur `api.ts` (suppression de l’attachement `status`/`endpoint`) et sur `catalog-sources/page.tsx` (suppression du log et du traitement 400/404 sans `setError`).
- Redéploiement seller-client via GitOps.

---

**Statut :** Instrumentation et correction appliquées. Preuves Network/console à recueillir sur seller-dev après déploiement.
