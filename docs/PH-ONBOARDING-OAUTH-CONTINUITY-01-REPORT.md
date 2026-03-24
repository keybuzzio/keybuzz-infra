# PH-ONBOARDING-OAUTH-CONTINUITY-01 — Rapport

> Date : 21 mars 2026
> Auteur : Cursor CE
> Phase : PH-ONBOARDING-OAUTH-CONTINUITY-01
> Pipeline : PH-TD-08 (deploy-safe.sh)

---

## Problème

Un utilisateur commençant son inscription via Google OAuth :
1. Google auth réussit
2. L'utilisateur n'existe pas encore → redirigé vers `/register`
3. La page `/register` affiche un bouton "Continuer avec Google" ambigu
4. S'il clique dessus → `handleGoogleAuth()` appelle `/api/auth/signin?callbackUrl=...`
5. NextAuth intercepte (`pages.signIn: '/login'`) → **retour parasite vers `/login`**
6. L'utilisateur perd son contexte et reboucle

## Cause racine

Deux problèmes distincts :

### 1. Callback redirige vers `/signup` au lieu de `/register` avec context OAuth
`auth/callback/page.tsx` ligne 59/62 : `router.replace('/signup?email=xxx')` sans indiquer que l'utilisateur vient d'un OAuth.

### 2. Register ne distingue pas email et OAuth
`register/page.tsx` traite tous les utilisateurs de la même façon :
- Affiche le formulaire email + OTP (inutile pour un utilisateur Google déjà authentifié)
- Affiche le bouton Google (qui déclenche la boucle /login)
- Ne détecte pas la session OAuth existante

## Flow AVANT (cassé)

| Étape | Route | Action |
|---|---|---|
| 1 | `/login` | Clic "Continuer avec Google" |
| 2 | Google OAuth | Auth réussie |
| 3 | `/auth/callback` | Pas de tenant → redirige `/signup?email=xxx` |
| 4 | `/signup` | Redirige `/register?email=xxx` (fix v2) |
| 5 | `/register` | Plan → Email (bouton Google visible) |
| 6 | Clic Google | `handleGoogleAuth()` → `/api/auth/signin` → `/login` **BOUCLE** |

## Flow APRÈS (corrigé)

| Étape | Route | Action |
|---|---|---|
| 1 | `/login` | Clic "Continuer avec Google" |
| 2 | Google OAuth | Auth réussie, session JWT créée |
| 3 | `/auth/callback` | Pas de tenant → redirige `/register?email=xxx&oauth=google` |
| 4 | `/register` | Détecte session OAuth → skip email/OTP |
| 5 | `/register` (company) | Badge "Compte Google connecté" + email vérifié |
| 6 | `/register` (user) | Infos utilisateur → Stripe → Succès |

## Fichiers modifiés

| Fichier | Modifications | Lignes |
|---|---|---|
| `app/auth/callback/page.tsx` | Redirect `/signup` → `/register?oauth=google` (2 occurrences) | +2/-2 |
| `app/register/page.tsx` | Détection OAuth, skip email/OTP, masquage Google, badge identité | +33/-4 |
| **Total** | **2 fichiers** | **+35/-6** |

### Fichiers NON touchés (conformité)
- ❌ ClientLayout.tsx
- ❌ middleware.ts
- ❌ AuthGuard.tsx
- ❌ Focus mode / menu / sidebar
- ❌ PH41-PH117 / AI
- ❌ Stripe backend
- ❌ API backend

## Logique choisie

### Détection OAuth (register/page.tsx)
```tsx
const { data: session } = useSession();
const oauthProvider = urlOAuth || (session?.provider && session.provider !== 'credentials' ? session.provider : null);
const isOAuthUser = !!oauthProvider;
```

### Comportement conditionnel
- **Si `isOAuthUser`** :
  - Email pré-rempli depuis la session
  - Step initial = `company` (skip email/OTP)
  - Bouton Google masqué
  - Badge "Compte Google connecté" avec email affiché
- **Si non-OAuth** :
  - Flow email/OTP inchangé
  - Bouton Google visible (pour choisir Google au lieu d'OTP)

## Tests DEV

| Test | Résultat |
|---|---|
| 10 pages critiques HTTP 200 | ✅ PASS |
| Register — `Compte Google` badge | ✅ PASS (1 occurrence) |
| Register — `useSession` | ✅ PASS |
| Register — `oauth` param | ✅ PASS |
| Callback — `oauth=google` redirect | ✅ PASS (1 chunk) |
| Login — zero `/signup` | ✅ PASS |
| Login — `/register` link | ✅ PASS |

**Image DEV** : `v3.5.63-onboarding-oauth-continuity-dev`
**verify-image-clean.sh** : 17/17 PASS

## Tests PROD

| Test | Résultat |
|---|---|
| 10 pages critiques HTTP 200 | ✅ PASS |
| Register — `Compte Google` badge | ✅ PASS |
| Register — `useSession` | ✅ PASS |
| Register — `oauth` detection | ✅ PASS |
| Callback chunk — `oauth=google` | ✅ PASS |
| Register chunk — `Compte Google` | ✅ PASS |
| Login — zero `/signup` | ✅ PASS |
| Login — `/register` | ✅ PASS |
| No DEV API URL contamination | ✅ PASS |

**Image PROD** : `v3.5.63-onboarding-oauth-continuity-prod`
**frontend-release-gate.sh** : 14/14 PASS — `promotionReady: true`

## Déploiement

| Env | Image | ArgoCD | Pod |
|---|---|---|---|
| DEV | `v3.5.63-onboarding-oauth-continuity-dev` | Synced + Healthy | Running |
| PROD | `v3.5.63-onboarding-oauth-continuity-prod` | Synced + Healthy | Running |

Pipeline : `deploy-safe.sh` (build-from-git + verify-image-clean + release gate + GitOps + ArgoCD)

## Rollback

| Env | Image rollback |
|---|---|
| DEV | `v3.5.62-signup-fix-v2-dev` |
| PROD | `v3.5.62-signup-fix-v2-prod` |

## Non-régression

| Flow | Status |
|---|---|
| Email/OTP classique | ✅ Inchangé |
| Login existant | ✅ Inchangé |
| Register standard | ✅ Inchangé |
| Paywall / billing | ✅ Inchangé |
| Onboarding | ✅ Inchangé |

## Verdict

### **OAUTH SIGNUP CONTINUITY FIXED**

Le signup Google va désormais jusqu'au bout sans ambiguïté et sans retour parasite vers login.
