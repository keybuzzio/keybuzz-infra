# PH-S03.5 — Fix « Unknown error » global sur toutes les pages seller-dev

**Date :** 2026-01-30  
**Périmètre :** Supprimer le bandeau « Unknown error » sur Dashboard, Tenants, Marketplaces, Catalog Sources, Secret Refs ; messages d’erreur explicites ; bannière toujours dismissable.  
**Environnement :** seller-dev uniquement.

**Règles :** DEV only, GitOps only, pas de kubectl apply/set image, ne pas toucher auth KeyBuzz côté client-dev, aucun secret en clair.

---

## 1. Contexte et objectifs

- **Problème :** Seller-dev affiche un bandeau « Unknown error » sur Dashboard, Tenants, Marketplaces, Catalog Sources, Secret Refs. Sur certaines pages le bandeau est dismissable (croix), sur Dashboard/Tenants non → blocage UX.
- **Objectifs :**
  1. Plus de « Unknown error » global.
  2. Si erreur API : message explicite et actionnable (401/403/5xx/422).
  3. Dashboard et Tenants doivent charger sans bannière bloquante (ou avec bannière dismissable).
  4. Toute erreur non bloquante doit être dismissable partout.

---

## 2. Cause racine (identification)

### Requête susceptible de déclencher la bannière

- **Appels communs au chargement :**
  - **Dashboard :** `GET /api/config/summary` (premier appel au chargement).
  - **Tenants :** `GET /api/tenants`.
  - **Marketplaces :** `GET /api/marketplaces` + `GET /api/marketplaces/tenant/{tenantId}`.
  - **Catalog Sources :** `GET /api/catalog-sources`.
  - **Secret Refs :** `GET /api/secret-refs`.

- **Origine de « Unknown error » :**
  1. **Backend** renvoie une réponse d’erreur dont le **corps n’est pas JSON** (ex. page HTML 401/500) → ancien fallback dans `api.ts` retournait `detail: 'Unknown error'`.
  2. **Backend** renvoie du JSON avec `detail: "Unknown error"` ou `message: "Unknown error"` → affiché tel quel.
  3. **Pages** affichent `err.message` sans normalisation → tout message générique (ex. « Auth error ») reste affiché.

- **Bannière non dismissable :** Dashboard et Tenants n’avaient **pas de bouton de fermeture** sur le bandeau d’erreur → UX bloquante.

---

## 3. Corrections réalisées

### A) api.ts — Messages explicites et normalisation

**Fichier :** `keybuzz-seller/seller-client/src/lib/api.ts`

1. **Fallback par status (PH-S03.5) :**
   - **401** → « Connexion expirée, reconnectez-vous. »
   - **403** → « Accès refusé. »
   - **404** → « Ressource introuvable. »
   - **422** → « Champs invalides. »
   - **5xx** → « Erreur serveur, réessayez. »
   - Autres → `Erreur ${status}.`

2. **Normalisation de « Unknown error » côté API :**
   - Si `error.detail` (string) ou `error.message` est vide, `"Unknown error"` ou `"Auth error"` (insensible à la casse) → on utilise `fallbackMessage(response.status)` à la place.
   - Ainsi, même si le backend renvoie `detail: "Unknown error"`, l’UI reçoit un message explicite selon le status.

3. **Helper d’affichage exporté :**
   - `getDisplayErrorMessage(err: unknown): string`
   - Règles : « Unknown error » / « Auth error » / vide → « Erreur inattendue. Réessayez ou reconnectez-vous. » ; messages réseau → « Erreur réseau. Vérifiez votre connexion. » ; sinon retourne le message tel quel (déjà explicite si venant de api.ts).

### B) Bannière toujours dismissable

- **Dashboard** (`app/(dashboard)/page.tsx`) : bouton **X** ajouté sur le bandeau d’erreur (`onClick={() => setError(null)}`).
- **Tenants** (`app/(dashboard)/tenants/page.tsx`) : bouton **X** ajouté sur le bandeau d’erreur.
- **Tenants détail** (`app/(dashboard)/tenants/[tenantId]/page.tsx`) : bouton **X** ajouté.
- **Marketplaces / Secret Refs / Catalog Sources** : avaient déjà un bouton de fermeture (✕ ou `setError(null)`) ; inchangé côté structure, uniquement utilisation de `getDisplayErrorMessage` pour le texte.

### C) Utilisation de getDisplayErrorMessage sur toutes les pages

- **Dashboard :** `setError(getDisplayErrorMessage(err))` au lieu de `err.message` / « Erreur de chargement ».
- **Tenants :** idem pour loadTenants et createTenant.
- **Tenants/[tenantId] :** idem pour loadTenant et saveTenant.
- **Marketplaces :** idem pour loadData et toggleMarketplace.
- **Secret Refs :** idem pour loadSecrets, createSecret, validateSecret, deleteSecret.
- **Catalog Sources :** idem pour loadSources, deleteSource, updateSourceStatus, et pour les erreurs dans SourceColumnMappingTab (detect / save mapping).

Résultat : plus aucun affichage direct de « Unknown error » ou « Auth error » ; soit le message vient déjà explicite de api.ts, soit il est normalisé par `getDisplayErrorMessage`.

---

## 4. Fichiers modifiés

| Fichier | Modification |
|--------|---------------|
| `keybuzz-seller/seller-client/src/lib/api.ts` | Fallback 403/404 ; normalisation `detail`/`message` « Unknown error » → fallbackMessage(status) ; export `getDisplayErrorMessage(err)`. |
| `keybuzz-seller/seller-client/app/(dashboard)/page.tsx` | Import `getDisplayErrorMessage` + X ; `setError(getDisplayErrorMessage(err))` ; bannière avec bouton Fermer. |
| `keybuzz-seller/seller-client/app/(dashboard)/tenants/page.tsx` | Import `getDisplayErrorMessage` + X ; `setError(getDisplayErrorMessage(err))` ; bannière avec bouton Fermer. |
| `keybuzz-seller/seller-client/app/(dashboard)/tenants/[tenantId]/page.tsx` | Import `getDisplayErrorMessage` + X ; `setError(getDisplayErrorMessage(err))` ; bannière avec bouton Fermer. |
| `keybuzz-seller/seller-client/app/(dashboard)/marketplaces/page.tsx` | Import `getDisplayErrorMessage` ; `setError(getDisplayErrorMessage(err))` (déjà dismissable). |
| `keybuzz-seller/seller-client/app/(dashboard)/secret-refs/page.tsx` | Import `getDisplayErrorMessage` ; `setError(getDisplayErrorMessage(err))` (déjà dismissable). |
| `keybuzz-seller/seller-client/app/(dashboard)/catalog-sources/page.tsx` | Import `getDisplayErrorMessage` ; `setError(getDisplayErrorMessage(err))` pour toutes les erreurs affichées. |
| `keybuzz-infra/docs/PH-S03.5-UNKNOWN-ERROR-GLOBAL-FIX.md` | Ce rapport. |

---

## 5. Preuves à collecter (validation obligatoire)

### A) Version seller-client déployée

- **ArgoCD :** révision + image tag + commit du repo pour keybuzz-seller-dev (seller-client).
- **Vérifier** que le build déployé contient les changements api.ts (fallback 403/404, normalisation « Unknown error », `getDisplayErrorMessage`).

### B) Requête fautive (avant fix)

- **DevTools Network** au chargement de Dashboard puis Tenants :
  - Première requête en échec : **URL**, **status**, **content-type** (json/html), **body** (masqué).
  - Si status 401/500 et body HTML → cause cohérente avec ancien « Unknown error » (réponse non JSON ou detail générique).

### C) Après fix

1. **Screenshots :**
   - Dashboard **sans** bannière « Unknown error » (ou avec message explicite + croix pour fermer).
   - Tenants **sans** bannière « Unknown error » (idem).
   - Marketplaces / Catalog Sources / Secret Refs **sans** « Unknown error » (ou message explicite + dismissable).

2. **Network :**
   - Même requête qu’avant : soit **200** (plus d’erreur), soit **401/403/404/5xx** avec **message d’erreur explicite** dans l’UI (et bannière dismissable).

3. **Comportement :**
   - En cas d’erreur API réelle (ex. 401) : message « Connexion expirée, reconnectez-vous » (ou redirection SSO).
   - En cas d’erreur 403 : « Accès refusé ».
   - En cas d’erreur 5xx : « Erreur serveur, réessayez ».
   - Bannière **toujours** fermable par l’utilisateur (sauf redirection 401).

---

## 6. Rollback

- **Revert des commits** sur seller-client (api.ts + pages dashboard, tenants, marketplaces, secret-refs, catalog-sources).
- **Pas de changement** côté client-dev auth, pas de changement PROD.
- Après revert : redéploiement seller-client via GitOps (ArgoCD sync) pour revenir à l’état précédent.

---

## 7. Récapitulatif

| Élément | Avant | Après |
|--------|--------|--------|
| Message « Unknown error » | Affiché tel quel | Remplacé par message selon status (401/403/404/422/5xx) ou « Erreur inattendue… » |
| Bannière Dashboard/Tenants | Non dismissable | Toujours dismissable (bouton X) |
| Erreurs API | Parfois génériques | Explicites et actionnables |
| Helper affichage | Aucun | `getDisplayErrorMessage(err)` utilisé partout |

**Statut :** Corrections appliquées côté seller-client. Preuves (screenshots, Network, version déployée) à collecter après déploiement et tests manuels sur seller-dev.
