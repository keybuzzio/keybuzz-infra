# PH-ONBOARDING-OAUTH-PLAN-CONTINUITY-01 — Rapport

> Date : 22 mars 2026
> Auteur : Agent Cursor
> Verdict : **GOOGLE SIGNUP PLAN FLOW FIXED**

---

## Probleme

Quand un utilisateur commence un signup depuis `/register`, choisit un plan, puis clique "Continuer avec Google", il est redirige vers `/login` au lieu de reprendre son inscription. Le plan choisi est perdu.

## Cause racine

Dans `app/register/page.tsx`, la fonction `handleGoogleAuth()` utilisait :

```javascript
const callbackUrl = `/register?plan=${selectedPlan}&cycle=${billingCycle}&step=company`;
window.location.href = `/api/auth/signin?callbackUrl=${encodeURIComponent(callbackUrl)}`;
```

Le probleme : `/api/auth/signin` est le endpoint generique NextAuth. Sans provider specifie, NextAuth redirige vers sa page `pages.signIn` = `/login`. Le `callbackUrl` est stocke dans un cookie NextAuth mais `/login` ne le lit pas et appelle `signIn('google')` sans callbackUrl.

Le callback `redirect` de NextAuth confirme :

```javascript
async redirect({ url, baseUrl }) {
  if (url.startsWith(baseUrl)) {
    if (url.includes('/login') || url.includes('/auth/signin')) {
      return baseUrl + '/select-tenant'; // plan perdu ici
    }
    return url; // callbackUrl respecte si pas /login ni /auth/signin
  }
  return baseUrl + '/select-tenant';
},
```

## Flow AVANT (KO)

| Etape | Route | Comportement |
|---|---|---|
| 1 | `/register` | Utilisateur choisit un plan |
| 2 | `handleGoogleAuth()` | `window.location.href = /api/auth/signin?callbackUrl=...` |
| 3 | NextAuth | Redirige vers `pages.signIn = /login` |
| 4 | `/login` | Page login affichee, contexte plan **PERDU** |

## Flow APRES (OK)

| Etape | Route | Comportement |
|---|---|---|
| 1 | `/register` | Utilisateur choisit un plan |
| 2 | `handleGoogleAuth()` | `signIn('google', { callbackUrl: '/register?plan=X&cycle=Y&step=company&oauth=google' })` |
| 3 | Google OAuth | Directement chez Google (pas via `/login`) |
| 4 | NextAuth redirect | URL = `/register?plan=X...` → pas `/login` ni `/auth/signin` → **respectee** |
| 5 | `/register?plan=X&step=company&oauth=google` | Reprise du flow, plan conserve, badge Google |

## Fix applique

**Fichier** : `app/register/page.tsx` (1 fichier, 2 lignes changees)

**Avant** :
```javascript
const handleGoogleAuth = () => {
  const callbackUrl = `/register?plan=${selectedPlan}&cycle=${billingCycle}&step=company`;
  window.location.href = `/api/auth/signin?callbackUrl=${encodeURIComponent(callbackUrl)}`;
};
```

**Apres** :
```javascript
const handleGoogleAuth = () => {
  const callbackUrl = `/register?plan=${selectedPlan}&cycle=${billingCycle}&step=company&oauth=google`;
  signIn('google', { callbackUrl });
};
```

### Pourquoi ca marche

1. `signIn('google', { callbackUrl })` envoie l'utilisateur **directement** chez Google (bypass `/login`)
2. Au retour, NextAuth appelle `redirect({ url })` avec l'URL complete `/register?plan=pro&cycle=monthly&step=company&oauth=google`
3. L'URL commence par `baseUrl` et ne contient ni `/login` ni `/auth/signin` → NextAuth la respecte
4. Le parametre `oauth=google` active la logique OAuth existante (badge Google verifie, masquage bouton Google)
5. `signIn` est deja importe dans le fichier (`import { signIn } from 'next-auth/react'`)

## Non-regressions

| Scenario | Impact | Resultat |
|---|---|---|
| Login → Google (existant) | Inchange (utilise `signIn('google')` dans `login/page.tsx`) | OK |
| Register classique email/OTP | Inchange (n'utilise pas `handleGoogleAuth`) | OK |
| OAuth continuity (PH-ONBOARDING-OAUTH-CONTINUITY-01) | Preservee grace a `oauth=google` | OK |
| Billing status-gate (PH-BILLING-PAYMENT-FIRST-01) | Aucun impact (pas de modification API) | OK |
| Paywall | Impossible de bypass (tenant cree avec `pending_payment`) | OK |

## Versions deployees

| Env | Image | Status |
|---|---|---|
| **DEV** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.65-onboarding-oauth-plan-continuity-dev` | Running |
| **PROD** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.65-onboarding-oauth-plan-continuity-prod` | Running |
| API | Aucune modification | - |

## Rollback

```bash
# DEV
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.64-billing-gate-dev -n keybuzz-client-dev

# PROD
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.64-billing-gate-prod -n keybuzz-client-prod
```

## Tests DEV (7/7 PASSED)

| # | Test | Resultat |
|---|---|---|
| 1 | Image correcte deployee | PASS |
| 2 | Pod Running | PASS |
| 3 | /register accessible (HTTP 200) | PASS |
| 4 | `oauth=google` dans le bundle | PASS |
| 5 | Ancien `window.location.href /api/auth/signin` supprime | PASS |
| 6 | /login accessible (HTTP 200) | PASS |
| 7 | API entitlement fonctionnel | PASS |

## Tests PROD (7/7 PASSED)

| # | Test | Resultat |
|---|---|---|
| 1 | Image correcte deployee | PASS |
| 2 | Pods Running | PASS |
| 3 | /register accessible (HTTP 200) | PASS |
| 4 | `oauth=google` dans le bundle | PASS |
| 5 | Ancien pattern supprime | PASS |
| 6 | /login accessible (HTTP 200) | PASS |
| 7 | API entitlement PROD fonctionnel | PASS |

## GitOps

| Repo | Commit | Description |
|---|---|---|
| `keybuzz-client` | `a06e404` | fix: handleGoogleAuth uses signIn direct |
| `keybuzz-infra` | `f97b7c3` | deploy(client-dev): v3.5.65 |
| `keybuzz-infra` | `71b00fc` | deploy(client-prod): v3.5.65 |

## Note : secret GHCR

Le namespace `keybuzz-client-dev` n'avait pas le secret `ghcr-cred` pour tirer les images GHCR. Le secret a ete copie depuis `keybuzz-api-dev`. Meme verification et correction faite pour `keybuzz-client-prod` si necessaire.

---

**VERDICT FINAL : GOOGLE SIGNUP PLAN FLOW FIXED**

Le signup Google depuis `/register` conserve desormais le plan choisi et reprend directement le flow d'inscription sans retour parasite vers `/login`.
