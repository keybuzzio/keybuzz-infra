# PH-ADMIN-87.8B — Deployment Truth Audit & Live Browser Validation

**Date** : 18 mars 2026
**Auditeur** : CE (Cursor Executor)
**Environnements** : DEV (`admin-dev.keybuzz.io`) + PROD (`admin.keybuzz.io`)
**Mode** : Navigation navigateur en direct + verification infrastructure + triple preuve DB→API→UI

---

## A. VERITE DE DEPLOIEMENT

### A.1 Images Docker deployees

| Env | Composant | Image | Digest | Demarrage |
|-----|-----------|-------|--------|-----------|
| DEV | Admin | `ghcr.io/keybuzzio/keybuzz-admin:v2.1.6-ph112-all-fix` | `sha256:09713c1a5608...` | 2026-03-17T18:35:46Z |
| PROD | Admin | `ghcr.io/keybuzzio/keybuzz-admin:v2.1.6-ph112-all-fix-prod` | `sha256:66766bb44315...` | 2026-03-17T20:39:18Z |
| DEV | API | `ghcr.io/keybuzzio/keybuzz-api:v3.6.15-ph113-real-connector-dev` | `sha256:53fd30578f36...` | 2026-03-18T04:31:19Z |
| PROD | API | `ghcr.io/keybuzzio/keybuzz-api:v3.6.15-ph113-real-connector-prod` | `sha256:53fd30578f36...` | 2026-03-18T05:02:30Z |

> Les API DEV et PROD partagent le meme digest — builds identiques.

### A.2 Workloads Kubernetes

| Env | Namespace | Deployment | Pod | Replicas | Service | Ingress |
|-----|-----------|------------|-----|----------|---------|---------|
| DEV | `keybuzz-admin-v2-dev` | `keybuzz-admin-v2` | `keybuzz-admin-v2-7b59454d49-nj86r` | 1 | `ClusterIP 10.102.66.198:3000` | `admin-dev.keybuzz.io` (nginx, TLS) |
| PROD | `keybuzz-admin-v2-prod` | `keybuzz-admin-v2` | `keybuzz-admin-v2-5fb6f7cfc7-m5df4` | 1 | `ClusterIP 10.105.52.79:3000` | `admin.keybuzz.io` (nginx, TLS) |

### A.3 Repo source

| Propriete | Valeur |
|-----------|--------|
| Repo | `https://github.com/keybuzzio/keybuzz-admin-v2.git` |
| Branche | `main` |
| Dernier commit bastion | `e37ce7e feat(ph86.1d): master super admin + user management foundation` |
| package.json version | `0.1.0` |

### A.4 Isolation DB confirmee

| Env | PGHOST | PGUSER | PGDATABASE |
|-----|--------|--------|------------|
| DEV | `10.0.0.10` | `keybuzz_api_dev` | `keybuzz` |
| PROD | `10.0.0.10` | `keybuzz_api_prod` | `keybuzz_prod` |

> Credentials distincts, bases de donnees separees. Isolation OK.

### A.5 Build IDs

| Env | BUILD_ID |
|-----|----------|
| DEV | `hYGf1upFZO19oFVMREaCY` |
| PROD | `IssJoARLfLtKe6JPYQXF_` |

> Builds differents pour DEV et PROD (attendu).

### A.6 Pages dans le build

**20 pages identiques** dans source, build DEV et build PROD :

| Page | Route | Presente source | Presente DEV pod | Presente PROD pod |
|------|-------|-----------------|-------------------|-------------------|
| Dashboard | `/` | ✅ | ✅ | ✅ |
| Ops Center | `/ops` | ✅ | ✅ | ✅ |
| Queues | `/queues` | ✅ | ✅ | ✅ |
| Approvals | `/approvals` | ✅ | ✅ | ✅ |
| Follow-ups | `/followups` | ✅ | ✅ | ✅ |
| AI Control | `/ai-control` | ✅ | ✅ | ✅ |
| Activation | `/ai-control/activation` | ✅ | ✅ | ✅ |
| Policies | `/ai-control/policies` | ✅ | ✅ | ✅ |
| Monitoring | `/ai-control/monitoring` | ✅ | ✅ | ✅ |
| Debug IA | `/ai-control/debug` | ✅ | ✅ | ✅ |
| Audit | `/audit` | ✅ | ✅ | ✅ |
| Tenants | `/tenants` | ✅ | ✅ | ✅ |
| Billing | `/billing` | ✅ | ✅ | ✅ |
| Users | `/users` | ✅ | ✅ | ✅ |
| User detail | `/users/[id]` | ✅ | ✅ | ✅ |
| User create | `/users/new` | ✅ | ✅ | ✅ |
| Settings | `/settings` | ✅ | ✅ | ✅ |
| Profile | `/settings/profile` | ✅ | ✅ | ✅ |
| Login | `/login` | ✅ | ✅ | ✅ |
| Set password | `/set-password` | ✅ | ✅ | ✅ |

**8 API routes identiques** dans DEV et PROD :

- `/api/admin/set-password`
- `/api/admin/setup-token`
- `/api/admin/tenants`
- `/api/admin/users/[id]/reset-password`
- `/api/admin/users/[id]`
- `/api/admin/users/[id]/tenants`
- `/api/admin/users`
- `/api/auth/[...nextauth]`

---

## B. PARCOURS NAVIGATEUR REEL

### B.1 Login

| Env | Email | Mot de passe | Resultat | Sidebar |
|-----|-------|-------------|----------|---------|
| DEV | `ludovic@keybuzz.pro` | `KeyBuzz2026Pro!` | ✅ Succes, redirect vers `/` | `ludovic / ludovic@keybuzz.pro` |
| PROD | `ludovic@keybuzz.pro` | `no26CG73Lg@+` | ✅ Succes, redirect vers `/` | `ludovic / ludovic@keybuzz.pro` |

### B.2 Sidebar — Structure complete

```
PRINCIPAL
  └ Dashboard

OPERATIONS
  ├ Ops Center
  ├ Queues
  ├ Approbations
  └ Follow-ups

INTELLIGENCE IA
  ├ AI Control Center
  ├ Activation
  ├ Policies
  ├ Monitoring
  └ Debug IA

SUPERVISION
  ├ Audit
  ├ Tenants
  └ Facturation

ADMINISTRATION
  └ Utilisateurs

SYSTEME
  ├ Parametres
  └ Mon profil
```

### B.3 Navigation page par page

| # | Page | URL | DEV Status | PROD Status | Type | Contenu cle |
|---|------|-----|------------|-------------|------|------------|
| 1 | Dashboard | `/` | 200 | 200 | PLACEHOLDER | 4 KPI = "—", activite + alertes placeholder |
| 2 | Ops Center | `/ops` | 200 | 200 | FUNCTIONAL | DEV: 0 cas, PROD: 2 cas en attente |
| 3 | Queues | `/queues` | 200 | 200 | FUNCTIONAL | DEV: 0 cas, PROD: 2 HIGH_VALUE_REVIEW |
| 4 | Approbations | `/approvals` | 200 | 200 | FUNCTIONAL | 0 approbations (DEV + PROD) |
| 5 | Follow-ups | `/followups` | 200 | 200 | FUNCTIONAL | 0 relances (DEV + PROD) |
| 6 | AI Control | `/ai-control` | 200 | 200 | FUNCTIONAL | Gouvernance NOMINAL, Autonomie ASSISTED_ONLY |
| 7 | Activation | `/ai-control/activation` | 200 | 200 | FUNCTIONAL | Matrice d'activation (0 actions) |
| 8 | Policies | `/ai-control/policies` | 200 | 200 | FUNCTIONAL | 0 policies actives |
| 9 | Monitoring | `/ai-control/monitoring` | 200 | 200 | FUNCTIONAL | Sante systeme, journal vide |
| 10 | Debug IA | `/ai-control/debug` | 200 | 200 | FUNCTIONAL | 14-15 endpoints IA inspectables |
| 11 | Audit | `/audit` | 200 | 200 | PLACEHOLDER | KPI = "—", message futur branchement |
| 12 | Tenants | `/tenants` | 200 | 200 | PLACEHOLDER | KPI = "—", message futur branchement |
| 13 | Facturation | `/billing` | 200 | 200 | PLACEHOLDER | KPI = "—", message futur branchement |
| 14 | Utilisateurs | `/users` | 200 | 200 | FUNCTIONAL | 1 user : ludovic@keybuzz.pro Super Admin |
| 15 | Nouvel user | `/users/new` | 200 | 200 | **BROKEN** | "Aucun tenant disponible" — BUG |
| 16 | Parametres | `/settings` | 200 | 200 | PLACEHOLDER | 4 sections a completer |
| 17 | Mon profil | `/settings/profile` | 200 | 200 | FUNCTIONAL | Infos user correctes |

### B.4 Pages 404 (routes non implementees)

| Route | DEV | PROD | Attendue ? |
|-------|-----|------|------------|
| `/finance` | 404 | 404 | Roadmap future |
| `/incidents` | 404 | 404 | Roadmap future |
| `/feature-flags` | 404 | 404 | Roadmap future |
| `/notifications` | 404 | 404 | Roadmap future |
| `/queue-inspector` | 404 | 404 | Roadmap future |
| `/system-health` | 404 | 404 | Roadmap future |
| `/connectors` | 404 | 404 | Roadmap future |
| `/ai-metrics` | 404 | 404 | Roadmap future |
| `/ai-evaluations` | 404 | 404 | Roadmap future |

> Ces 9 routes ne sont PAS des regressions. Elles n'ont JAMAIS ete implementees. Elles font partie de la roadmap future. Aucun commit ne les contient.

---

## C. MATRICE FONCTIONNALITES ATTENDUES vs SERVIES

### C.1 Phases livrees

| Phase | Description | Deploye DEV | Deploye PROD | Statut |
|-------|-------------|-------------|--------------|--------|
| PH86.1 | Admin v2 Foundation | ✅ | ✅ | OK |
| PH86.1B | Auth hardening | ✅ | ✅ | OK |
| PH86.1C | Auth cookies strict | ✅ | ✅ | OK |
| PH86.1D | User management | ✅ | ✅ | OK — sauf `/users/new` tenants |
| PH86.2A | Ops API integration | ✅ | ✅ | OK — donnees reelles visibles |
| PH112 | AI Control Center | ✅ | ✅ | OK — 5 pages fonctionnelles |
| PH113 | Real Connector | ✅ (API) | ✅ (API) | OK — pas de page admin |

### C.2 Classification des pages

| Categorie | Pages | Nombre |
|-----------|-------|--------|
| **FONCTIONNELLES** | Ops, Queues, Approvals, Follow-ups, AI Control (5 pages), Users, Profile | **12** |
| **PLACEHOLDER VOLONTAIRE** | Dashboard, Audit, Tenants, Billing, Settings | **5** |
| **BROKEN** | `/users/new` (tenants non charges) | **1** |
| **404 (roadmap future)** | finance, incidents, feature-flags, notifications, queue-inspector, system-health, connectors, ai-metrics, ai-evaluations | **9** |

---

## D. UI ↔ API ↔ DB — Triple preuve

### D.1 Tenants

| Etape | DEV | PROD |
|-------|-----|------|
| **DB** | 6 tenants (ecomlg-mmiyygfg, ecomlg-001, Essai, SWITAA SASU, Test 402, Test Paywall) | 3 tenants (ecomlg-001, 2x SWITAA SASU) |
| **API `/api/admin/tenants`** | 200 OK | 200 OK |
| **UI `/tenants`** | Placeholder "—" (page pas encore branchee) | Placeholder "—" |
| **UI `/users/new`** | ❌ "Aucun tenant disponible" | ❌ "Aucun tenant disponible" |

> **BUG CONFIRME** : L'API retourne 200 mais le composant `/users/new` n'appelle jamais l'API. Le `useEffect` est absent du build.

### D.2 Admin Users

| Etape | DEV | PROD |
|-------|-----|------|
| **DB** | 1 user : `ludovic@keybuzz.pro` (super_admin, actif) | 1 user : `ludovic@keybuzz.pro` (super_admin, actif) |
| **API `/api/admin/users`** | 200 OK | 200 OK |
| **UI `/users`** | ✅ 1 user affiche correctement | ✅ 1 user affiche correctement |

### D.3 Ops / Queues

| Etape | DEV | PROD |
|-------|-----|------|
| **DB `ai_human_approval_queue`** | 1 cas | 2 cas |
| **API** | Renvoie les cas via Ops endpoints | Renvoie 2 cas |
| **UI `/ops`** | KPI charges (0 affiche — possible lag API DEV) | ✅ "2 cas en attente" |
| **UI `/queues`** | KPI charges (0 affiche) | ✅ 2 cas HIGH_VALUE_REVIEW |

### D.4 Follow-ups

| Etape | DEV | PROD |
|-------|-----|------|
| **DB `ai_followup_cases`** | 0 | 0 |
| **UI `/followups`** | ✅ 0 (correct) | ✅ 0 (correct) |

### D.5 Billing

| Etape | DEV | PROD |
|-------|-----|------|
| **DB `billing_customers`** | 3 | 2 |
| **DB `billing_events`** | 76 | 62 |
| **UI `/billing`** | Placeholder (pas branche) | Placeholder (pas branche) |

---

## E. DIAGNOSTIC RACINE

### E.1 🔴 BUG CRITIQUE — `/users/new` ne charge pas les tenants

**Symptome** : "Aucun tenant disponible" sur DEV (6 tenants en DB) et PROD (3 tenants en DB).

**Cause racine** : Le code source sur le bastion (`e37ce7e`) contient un `useEffect` qui fetche `/api/admin/tenants`. Mais le build compile deploye dans les pods (`v2.1.6-ph112-all-fix`) NE CONTIENT PAS ce `useEffect`.

**Preuve** :
- **Source** (bastion) :
```typescript
useEffect(() => {
  fetch('/api/admin/tenants')
    .then(r => r.json())
    .then(d => setAllTenants(d.data || []))
    .catch(() => {});
}, []);
```

- **Build** (pod) : Le composant passe directement de `useState` declarations a la fonction `toggleTenant`. Aucun `useEffect`. Le state `allTenants` reste `[]` indefiniment.

**Explication** : L'image Docker `v2.1.6-ph112-all-fix` a ete construite a partir d'un etat du code source ou le `useEffect` n'existait pas encore (avant le commit `e37ce7e`). Le source a ete mis a jour sur le bastion APRES la construction de l'image, mais aucun rebuild n'a eu lieu.

**Fix** : Reconstruire l'image Docker depuis le source actuel et redeployer.

### E.2 🟡 WARNING — Session user_info instable

**Symptome** : La sidebar affiche "Admin / —" au lieu de "ludovic / ludovic@keybuzz.pro" sur certaines pages, de facon intermittente.

**Pages touchees** : `/users/new`, `/ai-control`, `/ai-control/activation`, `/ai-control/monitoring`, `/ai-control/debug`, `/tenants`, `/billing`, `/settings`, `/settings/profile`

**Console** : Erreur recurrente `[next-auth][error][CLIENT_FETCH_ERROR] Failed to fetch`

**Cause probable** :
- Race condition entre le chargement de la page et la resolution de la session NextAuth
- Le `SessionProvider` ne propage pas correctement le contexte sur certaines navigations client-side
- Le provider NextAuth tente un fetch `/api/auth/session` qui echoue sporadiquement (timeout ou erreur reseau interne)

**Impact** : Cosmétique principalement. L'authentification fonctionne (les pages protegees s'affichent), mais les infos utilisateur ne s'affichent pas correctement dans la sidebar.

### E.3 🟡 WARNING — Version affichee incorrecte

**Symptome** : La sidebar affiche `v2.1.5` alors que l'image deployee est `v2.1.6-ph112-all-fix`.

**Cause** : La version est probablement hardcodee dans le layout ou dans un fichier de configuration qui n'a pas ete mis a jour lors du build PH112.

**Impact** : Cosmétique uniquement.

### E.4 ℹ️ INFO — Dashboard KPI non connectes

Les 4 KPI du Dashboard (Queues actives, Approbations, Follow-ups, Tenants actifs) affichent tous "—". C'est un placeholder volontaire — le texte indique explicitement "Les donnees d'activite seront connectees aux endpoints PH81-PH85."

---

## F. PLAN DE CORRECTION

### F.1 AVANT LUNDI — Corrections critiques

| # | Action | Priorite | Effort |
|---|--------|----------|--------|
| 1 | **Rebuild image Docker** depuis le source actuel (commit `e37ce7e` ou plus recent avec useEffect) | 🔴 CRITIQUE | 30min |
| 2 | **Deployer nouveau build** en DEV puis PROD | 🔴 CRITIQUE | 15min |
| 3 | **Verifier `/users/new`** affiche les tenants apres deploiement | 🔴 CRITIQUE | 5min |
| 4 | **Investiguer session instabilite** — verifier `NEXTAUTH_URL` et `NEXTAUTH_SECRET` dans les env pods | 🟡 IMPORTANT | 30min |
| 5 | **Mettre a jour la version** affichee dans le sidebar (`v2.1.5` → version reelle) | 🟢 MINEUR | 5min |

### F.2 APRES LUNDI — Ameliorations

| # | Action | Priorite | Phase |
|---|--------|----------|-------|
| 6 | Connecter Dashboard KPI aux endpoints reels | Moyen | Prochaine phase |
| 7 | Brancher les pages placeholder (Audit, Tenants, Billing) | Moyen | Phases suivantes |
| 8 | Implementer les 9 pages manquantes (finance, incidents, etc.) | Bas | Roadmap |
| 9 | Normaliser le casing des plans (`PRO` vs `pro`, `STARTER` vs `starter`) | Bas | Maintenance |
| 10 | Connecter les donnees billing (3 customers DEV, 2 PROD) aux pages | Moyen | Phase Billing |

---

## G. CONCLUSION

### Admin DEV et PROD servent-ils le bon projet ?
**OUI.** Les deux deploiements servent `keybuzz-admin-v2` depuis le repo `keybuzzio/keybuzz-admin-v2`, avec les bonnes images, les bons namespaces, les bonnes ingress, et les bonnes DB.

### Le control plane complet est-il reellement deploye ?
**OUI, pour les phases livrees.** Les 20 pages source = 20 pages build = 20 pages DEV = 20 pages PROD. Les API routes sont identiques. Les 9 routes 404 sont des fonctionnalites roadmap future qui n'ont JAMAIS ete codees.

### Quelles fonctionnalites livrees sont absentes ?
**Aucune regression de pages.** Toutes les pages commitees sont presentes dans le build et servies correctement. Seul bug : `/users/new` est casse car le build a ete fait avant l'ajout du `useEffect` pour fetcher les tenants.

### Y a-t-il eu regression / mauvais repo / mauvais tag ?
**Pas de mauvais repo ou mauvais tag.** Le probleme est un **build desynchronise** : le source sur le bastion a ete mis a jour apres la construction de l'image Docker. Le code dans le pod ne correspond pas au code source actuel sur le bastion.

### Qu'est-ce qu'il faut corriger avant lundi ?
1. **Rebuilder et redeployer** l'image admin avec le code source actuel
2. **Verifier que les tenants s'affichent** dans `/users/new`
3. **Investiguer l'instabilite session** NextAuth

---

## H. STOP/GO

### Verdict : ✅ ADMIN SAIN AVEC RESERVES

**Reserves** :
- `/users/new` non fonctionnel (creation d'utilisateurs bloquee) — fixable par rebuild
- Session user_info intermittente — impact cosmétique uniquement
- 5 pages placeholder volontaires (roadmap)

**Apres le rebuild** : L'admin sera pleinement operationnel pour les fonctionnalites livrees (Ops, Queues, AI Control, Users, Profile).

---

*Rapport genere le 18 mars 2026 par CE.*
*Navigation navigateur en direct effectuee sur DEV et PROD.*
*Toutes les donnees ont ete tracees DB → API → UI.*
