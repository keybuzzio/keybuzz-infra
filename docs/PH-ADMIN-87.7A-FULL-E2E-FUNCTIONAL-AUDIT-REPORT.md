# PH-ADMIN-87.7A — Admin v2 Full E2E Functional Audit Report

**Date** : 18 mars 2026
**Auditeur** : Cursor Executor (CE)
**Methode** : Navigation navigateur reelle (browser-driven), scan code, verification console
**Environnements** : DEV (`admin-dev.keybuzz.io`) + PROD (`admin.keybuzz.io`)
**Version Admin** : v2.1.5 (sidebar) / v2.1.6-ph112-all-fix (image Docker)
**Version API** : v3.6.15-ph112-ops-fix

---

## A. Perimetre audite

### DEV (`admin-dev.keybuzz.io`)
- 18 pages naviguer via navigateur
- 9 URLs non-existantes testees (404)
- Scan hardcodage complet du code source
- Console navigateur surveillee
- Tenant selector teste

### PROD (`admin.keybuzz.io`)
- 17 pages naviguer via navigateur
- 3 URLs non-existantes testees (404)
- Console navigateur surveillee
- Comparaison avec DEV

### Modules testes
- Auth & session (login, logout, redirect, RBAC)
- Navigation globale (sidebar, breadcrumbs, liens)
- Tenant selector & multi-tenant
- Ops Center, Queues, Approbations, Follow-ups
- AI Control Center (5 sous-pages)
- Audit, Tenants, Facturation
- User Management (liste, creation, profil)
- Parametres

---

## B. Navigation reelle effectuee

### Parcours DEV
1. `/login` -> saisie credentials -> redirect `/`
2. Dashboard -> clic sidebar "Ops Center" -> `/ops`
3. Navigation directe vers chaque page de la sidebar
4. Test creation utilisateur (`/users/new`)
5. Test page set-password (`/set-password`)
6. Test 9 URLs non-existantes

### Parcours PROD
1. `/login` -> saisie credentials -> redirect `/`
2. Navigation directe vers chaque page
3. Verification des donnees reelles vs DEV
4. Test 3 URLs non-existantes

### Sidebar -- Inventaire complet (identique DEV/PROD)

| Section | Menu | Route |
|---------|------|-------|
| Principal | Dashboard | `/` |
| Operations | Ops Center | `/ops` |
| | Queues | `/queues` |
| | Approbations | `/approvals` |
| | Follow-ups | `/followups` |
| Intelligence IA | AI Control Center | `/ai-control` |
| | Activation | `/ai-control/activation` |
| | Policies | `/ai-control/policies` |
| | Monitoring | `/ai-control/monitoring` |
| | Debug IA | `/ai-control/debug` |
| Supervision | Audit | `/audit` |
| | Tenants | `/tenants` |
| | Facturation | `/billing` |
| Administration | Utilisateurs | `/users` |
| Systeme | Parametres | `/settings` |
| | Mon profil | `/settings/profile` |

**Total** : 16 entrees visibles + 2 sous-pages (`/users/new`, `/set-password`)

---

## C. Resultats par page

### Legende
- **FONCTIONNEL** : Donnees reelles chargees via API
- **PLACEHOLDER** : UI prete, donnees futures (texte explicatif visible)
- **WARNING** : Fonctionnel avec erreurs console non bloquantes
- **BUG** : Probleme identifie

### Pages -- DEV

| Page | Route | Statut | Donnees | Tenant Selector | Notes |
|------|-------|--------|---------|-----------------|-------|
| Dashboard | `/` | PLACEHOLDER | KPI = `--` | Non | "Connecte aux endpoints PH81-PH85" |
| Ops Center | `/ops` | FONCTIONNEL | 0 cas | Oui | KPI affiches, sections Queues + Follow-ups |
| Queues | `/queues` | FONCTIONNEL | 0 en file | Oui | Empty state "File vide" |
| Approbations | `/approvals` | FONCTIONNEL | 0 approb. | Oui | Empty state |
| Follow-ups | `/followups` | FONCTIONNEL | 0 relances | Oui | 5 KPI (ouverts, a venir, bientot dus, retard, critiques) |
| AI Control | `/ai-control` | FONCTIONNEL | NOMINAL | Oui | Gouvernance, autonomie, rollout, actions |
| Activation | `/ai-control/activation` | FONCTIONNEL | 0 actions | Oui | Empty state |
| Policies | `/ai-control/policies` | FONCTIONNEL | 0 policies | Oui | Boutons Ajouter + Actualiser |
| Monitoring | `/ai-control/monitoring` | FONCTIONNEL | N/A | Oui | Sante systeme + execution |
| Debug IA | `/ai-control/debug` | WARNING | 14 endpoints | Oui | **10x React #418, 1x #423** (hydratation SSR) |
| Audit | `/audit` | PLACEHOLDER | KPI = `--` | Oui | "Connecte au AI Actions Ledger" |
| Tenants | `/tenants` | PLACEHOLDER | KPI = `--` | Non | "Connecte aux tables tenants, subscriptions, wallets" |
| Facturation | `/billing` | PLACEHOLDER | KPI = `--` | Non | "Connecte aux tables subscriptions, wallets, Stripe" |
| Utilisateurs | `/users` | FONCTIONNEL | 1 user | Non | ludovic@keybuzz.pro, Super Admin, bouton "Nouvel utilisateur" |
| Nouvel user | `/users/new` | FONCTIONNEL | Formulaire | Non | 5 roles, **6 tenants reels** affiches |
| Parametres | `/settings` | PLACEHOLDER | 4 sections | Non | Securite, Notifications, Personnalisation, General |
| Mon profil | `/settings/profile` | FONCTIONNEL | Profil complet | Non | Email, role, session JWT 8h |
| Set password | `/set-password` | FONCTIONNEL | Erreur token | Non | Gestion erreur token expire OK |

### Pages -- PROD

| Page | Route | Statut | Donnees | Divergence vs DEV |
|------|-------|--------|---------|-------------------|
| Dashboard | `/` | PLACEHOLDER | KPI = `--` | Identique |
| Ops Center | `/ops` | FONCTIONNEL | **2 cas** | DEV=0, PROD=2 (donnees reelles) |
| Queues | `/queues` | FONCTIONNEL | **2 urgents** | DEV=0, PROD=2 |
| Approbations | `/approvals` | FONCTIONNEL | 0 approb. | Identique |
| Follow-ups | `/followups` | FONCTIONNEL | 0 relances | Identique |
| AI Control | `/ai-control` | FONCTIONNEL | NOMINAL | Identique |
| Activation | `/ai-control/activation` | FONCTIONNEL | 0 actions | Identique |
| Policies | `/ai-control/policies` | FONCTIONNEL | 0 policies | Identique |
| Monitoring | `/ai-control/monitoring` | FONCTIONNEL | N/A | Identique |
| Debug IA | `/ai-control/debug` | WARNING | 14 endpoints | **Memes erreurs React #418/#423** |
| Audit | `/audit` | PLACEHOLDER | KPI = `--` | Identique |
| Tenants | `/tenants` | PLACEHOLDER | KPI = `--` | Identique |
| Facturation | `/billing` | PLACEHOLDER | KPI = `--` | Identique |
| Utilisateurs | `/users` | FONCTIONNEL | 1 user | Identique (meme user) |
| Nouvel user | `/users/new` | FONCTIONNEL | Formulaire | **0 tenants** vs 6 en DEV |
| Parametres | `/settings` | PLACEHOLDER | 4 sections | Identique |
| Mon profil | `/settings/profile` | FONCTIONNEL | Profil | Identique |

### Gestion 404

| URL testee | DEV | PROD |
|-----------|-----|------|
| `/nonexistent` | 404 Next.js | 404 Next.js |
| `/finance` | 404 | 404 |
| `/incidents` | 404 | 404 |
| `/feature-flags` | 404 | - |
| `/ai-metrics` | 404 | - |
| `/connectors` | 404 | - |
| `/system-health` | 404 | - |
| `/queue-inspector` | 404 | - |
| `/ai-evaluations` | 404 | - |

**Resultat** : Toutes les pages non-existantes retournent une 404 Next.js standard. Aucun crash, aucune page blanche.

---

## D. Audit hardcodage

### Scan effectue sur `/opt/keybuzz/keybuzz-admin-v2/src/`

| Pattern recherche | Resultat | Criticite |
|-------------------|----------|-----------|
| `ecomlg` | **CLEAN** | - |
| `TENANT_ID` const | **CLEAN** | - |
| `localhost` | **CLEAN** | - |
| `api-dev.keybuzz.io` (hors env.ts) | **CLEAN** | - |
| `api.keybuzz.io` (hors env.ts/CSP) | **CLEAN** | - |
| `admin-dev.keybuzz.io` | 3 fichiers (fallback NEXTAUTH_URL) | Acceptable |
| `admin.keybuzz.io` | 1 fichier (placeholder email) | Acceptable |
| `v2.1.5` | Sidebar.tsx ligne 111 | Acceptable |
| `tenant_id` hardcode | 1 fichier (requete SQL DELETE) | Acceptable |

### Detail des resultats non-CLEAN

**1. Fallback `admin-dev.keybuzz.io`** (3 occurrences)
```
src/app/api/admin/users/[id]/reset-password/route.ts:21
src/app/api/admin/users/route.ts:55
src/app/api/admin/setup-token/route.ts:23
```
Usage : `process.env.NEXTAUTH_URL || 'https://admin-dev.keybuzz.io'`
**Verdict** : Acceptable -- PROD a `NEXTAUTH_URL=https://admin.keybuzz.io` en env var, le fallback n'est jamais utilise en PROD.

**2. Placeholder email** (1 occurrence)
```
src/app/(auth)/login/page.tsx:74 -- placeholder="admin@keybuzz.io"
```
**Verdict** : Cosmetique, OK.

**3. Version hardcodee** (1 occurrence)
```
src/components/layout/Sidebar.tsx:111 -- v2.1.5
```
**Verdict** : Temporairement acceptable. A automatiser via `process.env.npm_package_version` a terme.

**4. `env.ts` -- Configuration centralisee**
```typescript
export const env = {
  apiUrl: process.env.NEXT_PUBLIC_API_URL || 'https://api-dev.keybuzz.io',
  apiInternalUrl: process.env.KEYBUZZ_API_INTERNAL_URL || process.env.NEXT_PUBLIC_API_URL || 'https://api-dev.keybuzz.io',
  appEnv: process.env.NEXT_PUBLIC_APP_ENV || 'development',
  isProduction: process.env.NEXT_PUBLIC_APP_ENV === 'production',
} as const;
```
**Verdict** : Correct -- les fallbacks DEV sont la bonne pratique pour le dev local. PROD utilise les env vars.

---

## E. Erreurs navigateur / reseau

### Erreur recurrente (toutes pages, DEV + PROD)

**Type** : `[next-auth][error][CLIENT_FETCH_ERROR] Failed to fetch`
**Niveau** : `debug` (pas `error`)
**Frequence** : Sur chaque changement de page (~5-8s apres navigation)
**Source** : `117-df66b62dc5c90d89.js` (chunk NextAuth)
**Impact** : **NON BLOQUANT** -- l'authentification fonctionne, la session persiste.
**Cause probable** : Polling NextAuth session qui echoue temporairement (reseau, timeout, ou endpoint lent).
**Action** : Amelioration -- verifier la configuration `NEXTAUTH_URL` et l'accessibilite de `/api/auth/session`.

### Erreurs React (page Debug IA uniquement, DEV + PROD)

**Type** : `Minified React error #418` (x10) + `#423` (x1)
**URL** : `/ai-control/debug`
**Source** : `fd9d1056-d0f277ea6c17fc29.js` (chunk React)
**Impact** : **VISUELLEMENT NON BLOQUANT** -- la page s'affiche et les 14 endpoints sont visibles.
**Cause** : Erreur #418 = Mismatch hydratation SSR/client. Erreur #423 = Hydratation text content mismatch.
**Cause probable** : Le composant Debug IA utilise `Date.now()` ou du contenu dynamique cote client qui differe du rendu serveur.
**Action** : Important -- ajouter `'use client'` en haut de la page si ce n'est pas fait, ou utiliser `suppressHydrationWarning` sur les elements dynamiques.

### Aucune autre erreur

- 0 erreur 401/403 inattendue
- 0 erreur 500
- 0 erreur CORS
- 0 erreur de route manquante
- 0 race condition detectee (depuis le fix PH112)

---

## F. Coherence globale

### Coherence UX
| Critere | Resultat |
|---------|----------|
| Libelles coherents | OK -- francais partout sauf noms techniques (Ops, AI, Debug) |
| Badges coherents | OK -- codes couleur uniformes |
| Actions coherentes avec RBAC | OK -- Super Admin a acces complet |
| Navigation homogene | OK -- sidebar + breadcrumbs fonctionnels |
| Sections sidebar coherentes | OK -- regroupement logique (Operations, IA, Supervision, Admin, Systeme) |
| Dead ends | AUCUN -- toutes les pages ont un retour possible |

### Coherence produit
| Critere | Resultat |
|---------|----------|
| Placeholders documentes | OK -- 5 pages avec texte explicatif |
| Donnees mock vs reelles | OK -- aucune donnee mock presentee comme reelle |
| Multi-tenant | OK -- tenant selector present sur les pages pertinentes |
| Version affichee | OK -- `v2.1.5` coherent DEV/PROD |

### Coherence RBAC
| Critere | Resultat |
|---------|----------|
| Pages protegees | OK -- redirect `/login` sans session |
| Role affiche | OK -- "Super Admin" visible dans profil et sidebar |
| Permissions coherentes | OK -- acces total pour super_admin |
| Filtres roles dans `/users/new` | OK -- 5 roles proposes |

### Coherence multi-tenant
| Critere | Resultat |
|---------|----------|
| Tenant selector DEV | OK -- charge dynamiquement, 6 tenants reels |
| Tenant selector PROD | PARTIEL -- present mais 0 tenants dans `/users/new` |
| Persistance selection | OK -- localStorage utilise |
| Changement tenant | OK -- rafraichissement des donnees |
| Hardcodage tenant | CLEAN -- aucun `ecomlg-001` residuel |

---

## G. Actions recommandees

### CRITIQUE (a corriger)

**Aucune action critique bloquante.**

### IMPORTANT (a planifier)

| # | Description | Pages | Effort |
|---|-------------|-------|--------|
| 1 | Corriger erreurs React hydratation sur `/ai-control/debug` | Debug IA | Faible -- ajouter `suppressHydrationWarning` ou corriger le rendu dynamique |
| 2 | Investiguer 0 tenants dans `/users/new` en PROD (vs 6 en DEV) | Users/new PROD | Faible -- verifier la table `tenants` en DB PROD |
| 3 | Investiguer `CLIENT_FETCH_ERROR` NextAuth recurrent | Toutes pages | Moyen -- verifier config session |

### AMELIORATION (a terme)

| # | Description | Pages | Effort |
|---|-------------|-------|--------|
| 4 | Connecter Dashboard aux endpoints PH81-PH85 | Dashboard | Moyen |
| 5 | Connecter Audit au AI Actions Ledger | Audit | Moyen |
| 6 | Connecter Tenants aux tables tenants/subscriptions/wallets | Tenants | Moyen |
| 7 | Connecter Facturation a Stripe et tables billing | Billing | Moyen |
| 8 | Completer les 4 sections de `/settings` | Parametres | Moyen |
| 9 | Automatiser la version sidebar via env var | Sidebar | Faible |
| 10 | Ajouter page 404 personnalisee (logo KeyBuzz, lien retour) | Global | Faible |

---

## H. Stop/go PROD

### Conclusion : ADMIN SAIN AVEC RESERVES

L'Admin v2 est **fonctionnel et stable** en DEV et PROD.

**Points forts :**
- 12 pages sur 17 sont fonctionnelles avec donnees reelles
- Zero hardcodage critique (ecomlg, TENANT_ID, URLs)
- Authentication robuste (NextAuth JWT, redirect, session 8h)
- RBAC en place (Super Admin, 5 roles)
- Navigation fluide, aucun crash, aucun dead end
- Gestion 404 correcte
- Coherence visuelle DEV/PROD
- Multi-tenant dynamique (tenant selector)
- Ops Center et AI Control Center pleinement operationnels

**Reserves :**
- Erreurs React hydratation sur la page Debug IA (#418/#423) -- non bloquant visuellement mais a corriger
- `CLIENT_FETCH_ERROR` NextAuth recurrent sur toutes les pages -- non bloquant mais a investiguer
- 5 pages placeholder (Dashboard, Audit, Tenants, Facturation, Parametres) -- volontaire, endpoints backend a connecter
- 0 tenants disponibles dans `/users/new` en PROD (vs 6 en DEV)

**Verdict final :** PROD est **operationnel**. Les reserves identifiees sont mineures et aucune ne constitue un bloqueur pour l'utilisation courante de l'Admin v2.

---

## Annexe : Images Docker deployes

| Composant | DEV | PROD |
|-----------|-----|------|
| API | `ghcr.io/keybuzzio/keybuzz-api:v3.6.15-ph112-ops-fix-dev` | `ghcr.io/keybuzzio/keybuzz-api:v3.6.15-ph112-ops-fix-prod` |
| Admin | `ghcr.io/keybuzzio/keybuzz-admin:v2.1.6-ph112-all-fix` | `ghcr.io/keybuzzio/keybuzz-admin:v2.1.6-ph112-all-fix-prod` |

## Annexe : Fichiers source identifies

20 pages (`page.tsx`) :
```
src/app/(admin)/ai-control/activation/page.tsx
src/app/(admin)/ai-control/debug/page.tsx
src/app/(admin)/ai-control/monitoring/page.tsx
src/app/(admin)/ai-control/page.tsx
src/app/(admin)/ai-control/policies/page.tsx
src/app/(admin)/approvals/page.tsx
src/app/(admin)/audit/page.tsx
src/app/(admin)/billing/page.tsx
src/app/(admin)/followups/page.tsx
src/app/(admin)/ops/page.tsx
src/app/(admin)/page.tsx
src/app/(admin)/queues/page.tsx
src/app/(admin)/settings/page.tsx
src/app/(admin)/settings/profile/page.tsx
src/app/(admin)/tenants/page.tsx
src/app/(admin)/users/[id]/page.tsx
src/app/(admin)/users/new/page.tsx
src/app/(admin)/users/page.tsx
src/app/(auth)/login/page.tsx
src/app/(auth)/set-password/page.tsx
```

8 routes API :
```
src/app/api/admin/set-password/route.ts
src/app/api/admin/setup-token/route.ts
src/app/api/admin/tenants/route.ts
src/app/api/admin/users/[id]/reset-password/route.ts
src/app/api/admin/users/[id]/route.ts
src/app/api/admin/users/[id]/tenants/route.ts
src/app/api/admin/users/route.ts
src/app/api/auth/[...nextauth]/route.ts
```
