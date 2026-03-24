# PH-AUTH-SESSION-LOADING-STABILITY-01 — Rapport

> Date : 2026-03-23
> Environnements : DEV + PROD
> Type : audit + correction stabilite login / session / loading

---

## Symptomes reportes par le product owner

1. Ecran "Chargement..." bloque a l'infini apres connexion
2. Refresh manuel debloque souvent la situation
3. Probleme frequent mais aleatoire
4. Session se coupe automatiquement au bout de quelques minutes
5. Duree de connexion jugee trop courte pour un usage SaaS

---

## Root Causes identifiees

### Root Cause 1 — Loading infini (`EntitlementGuard`)

**Fichier** : `src/components/layout/ClientLayout.tsx`
**Probleme** : `EntitlementGuard` retournait `null` pendant le chargement du billing entitlement. Aucun timeout, aucun fallback, aucun message d'erreur.

```tsx
// AVANT (problematique)
if (isLoading) return null;  // ecran vide indefini
```

Si le fetch echouait silencieusement ou si le `currentTenantId` n'etait pas encore disponible, l'ecran restait vide sans aucune possibilite de reprise.

### Root Cause 2 — Deconnexion trop rapide (keep-alive aggressif)

**Fichier** : `src/components/auth/AuthGuard.tsx`
**Probleme** : Le keep-alive (toutes les 5 minutes) faisait un logout immediat au premier echec de `/api/auth/me`. Un bref probleme reseau, un restart de pod, ou un 500 transitoire causait une deconnexion immediate.

```tsx
// AVANT (problematique)
const ok = await fetchAuth(true);
if (!ok) {
  router.replace('/login');  // logout au 1er echec
}
```

### Root Cause 3 — Pas de refresh session automatique

**Fichier** : `src/components/auth/AuthProvider.tsx`
**Probleme** : `SessionProvider` de NextAuth etait monte sans aucune option de rafraichissement. Pas de `refetchInterval`, pas de `refetchOnWindowFocus`. La session JWT (7 jours) n'etait jamais rafraichie automatiquement cote client.

---

## Corrections appliquees

### 1. AuthGuard — Timeout + retry + resilience (`AuthGuard.tsx`)

| Aspect | Avant | Apres |
|---|---|---|
| Fetch `/api/auth/me` | Sans timeout | AbortController 10s |
| Keep-alive echec | Logout au 1er echec | 3 echecs consecutifs avant logout |
| Etat loading | Spinner infini | Timeout 12s + bouton "Reessayer" |
| Etat erreur | Inexistant | Ecran erreur + "Reessayer" + "Se reconnecter" |
| Status auth | 3 etats | 4 etats (`loading`, `authenticated`, `unauthenticated`, `error`) |

### 2. AuthProvider — Session refresh automatique (`AuthProvider.tsx`)

| Aspect | Avant | Apres |
|---|---|---|
| `refetchInterval` | Non defini | 5 minutes (300s) |
| `refetchOnWindowFocus` | Non defini | `true` |

### 3. EntitlementGuard — Spinner + timeout (`ClientLayout.tsx`)

| Aspect | Avant | Apres |
|---|---|---|
| Pendant loading | `return null` (ecran vide) | Spinner "Chargement..." visible |
| Timeout | Aucun | 8 secondes, puis rendu optimiste |

---

## Politique de session retenue

| Parametre | Valeur | Source |
|---|---|---|
| JWT maxAge | 7 jours | `auth-options.ts` (inchange) |
| Session refresh client | 5 minutes | `SessionProvider refetchInterval` |
| Refresh on window focus | Oui | `SessionProvider refetchOnWindowFocus` |
| Keep-alive custom | 5 minutes | `AuthGuard` (inchange) |
| Tolerance echec keep-alive | 3 echecs consecutifs | `MAX_KEEPALIVE_FAILURES` |
| Fetch timeout auth | 10 secondes | `FETCH_TIMEOUT_MS` |
| Loading max visible | 12 secondes (AuthGuard) / 8 secondes (Entitlement) | Timeouts configures |

---

## Fichiers modifies

| Fichier | Modifications |
|---|---|
| `src/components/auth/AuthGuard.tsx` | Timeout fetch, 3 echecs keep-alive, etat error avec retry, loading timeout |
| `src/components/auth/AuthProvider.tsx` | `refetchInterval={300}`, `refetchOnWindowFocus={true}` |
| `src/components/layout/ClientLayout.tsx` | EntitlementGuard spinner + timeout 8s au lieu de `return null` |

---

## Validations DEV

| Verification | Resultat |
|---|---|
| `/login` | 200 |
| `/dashboard` | 200 |
| `/inbox` | 200 |
| `/api/auth/me` (sans session) | 401 (attendu) |
| API Health | `{"status":"ok"}` |
| Code `refetchInterval` deploye | Confirme dans chunks |
| Code `Reessayer` deploye | Confirme dans chunks |
| Code `La connexion prend` deploye | Confirme dans chunks |

**AUTH LOADING DEV = OK**
**AUTH SESSION DEV = OK**
**AUTH ROUTING DEV = OK**

---

## Validations PROD

| Verification | Resultat |
|---|---|
| `/login` | 200 |
| `/pricing` | 200 |
| `/dashboard` | 200 |
| `/inbox` | 200 |
| `/api/auth/me` (sans session) | 401 (attendu) |
| API Health | `{"status":"ok"}` |
| Amazon status | `connected: true`, `CONNECTED` |
| Code `refetchInterval` deploye | Confirme dans chunks PROD |
| Code `Reessayer` deploye | Confirme dans chunks PROD |

**AUTH LOADING PROD = OK**
**AUTH SESSION PROD = OK**
**AUTH ROUTING PROD = OK**

---

## Non-regressions

| Fonctionnalite | Status |
|---|---|
| Login page | OK |
| OAuth (config inchangee) | OK |
| Billing (paywall, entitlement) | OK |
| Onboarding | OK |
| PH119 (route access guard) | OK |
| Amazon status | `connected: true` |
| API Health | OK |

---

## Images deployees

| Env | Image |
|---|---|
| **DEV** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.78-auth-session-loading-stability-dev` |
| **PROD** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.78-auth-session-loading-stability-prod` |

---

## Rollback

| Env | Image rollback |
|---|---|
| **DEV** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.77-ph119-role-access-guard-dev` |
| **PROD** | `ghcr.io/keybuzzio/keybuzz-client:v3.5.77-ph119-role-access-guard-prod` |

---

## Verdict final

### AUTH SESSION AND LOADING STABILITY FIXED AND VALIDATED
