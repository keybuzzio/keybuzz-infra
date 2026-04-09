# PH140-E — Agent Invite Auth Tenant Recovery

> Date : 2 avril 2026
> Statut : **DEPLOYE DEV + PROD**

## Objectif

Corriger le flow E2E d'invitation agent : un agent invite doit pouvoir cliquer le lien, s'authentifier, etre rattache au tenant, et arriver dans son workspace.

## Cause racine (3 maillons casses)

### Maillon 1 : Login page bloque les nouveaux utilisateurs invites

La page `/login` appelle `check-email` qui retourne `{ exists: false }` pour un nouvel utilisateur. Le login affiche "Aucun compte trouve" et redirige vers `/register` (flow owner avec plan/Stripe/company), **perdant completement le contexte d'invitation**.

Un agent invite ne doit PAS creer un tenant/plan/subscription. Il doit juste s'authentifier puis consommer l'invitation qui l'ajoute au tenant existant.

### Maillon 2 : `onLoginSuccess()` ignore le callbackUrl

Apres verification OTP reussie, `AuthGuard.onLoginSuccess()` redirige **toujours** vers `/select-tenant`, ignorant le `callbackUrl=/invite/continue?token={token}` present dans l'URL.

### Maillon 3 : Cookies tenant non initialises apres acceptation

`/invite/continue` posait `currentTenantId` mais PAS `currentTenantRole`, causant un etat RBAC indetermine entre l'acceptation et le chargement de TenantProvider.

## Corrections appliquees

### 1. Login bypass pour utilisateurs invites (`app/login/page.tsx`)

- Detection d'une invitation en attente via cookie `kb_invite_token` ou `callbackUrl` contenant `/invite/`
- Si invite detectee : skip du check `exists/hasTenants` → envoi OTP direct
- L'utilisateur peut s'authentifier meme s'il n'a pas encore de compte/tenant

### 2. Redirect post-OTP vers invite/continue (`app/login/page.tsx`)

- Apres verification OTP reussie, si invite en attente → redirect vers `/invite/continue?token={token}`
- Bypasse `onLoginSuccess()` qui irait vers `/select-tenant`

### 3. OAuth callbackUrl preserve (`app/login/page.tsx`)

- `signIn('google', { callbackUrl })` et `signIn('azure-ad', { callbackUrl })` preservent le callbackUrl d'invitation
- Si deja authentifie avec callbackUrl invite → redirect vers la destination

### 4. Auth callback OAuth detect invite (`app/auth/callback/page.tsx`)

- Avant le routing normal, verifie si un token invite existe (HTTP-only cookie ou client cookie)
- Si oui, redirige vers `/invite/continue?token={token}` au lieu du flow standard

### 5. Cookie currentTenantRole pose (`app/invite/continue/page.tsx`)

- Apres acceptation reussie, pose `currentTenantRole` en plus de `currentTenantId`
- Le middleware RBAC fonctionne immediatement sans attendre TenantProvider

### 6. Redirect "already member" corrige (`app/invite/continue/page.tsx`)

- Redirige vers `/inbox` (safe pour tous les roles) au lieu de `/dashboard` (admin-only)

### 7. Bouton erreur corrige (`app/invite/continue/page.tsx`)

- "Aller au dashboard" → "Aller a la boite de reception" (safe pour agents)

### 8. API invite publique (`src/lib/routeAccessGuard.ts`)

- `/api/invite` ajoute a `API_PUBLIC_PREFIXES`
- Permet au cookie HTTP-only d'etre pose avant authentification

## Fichiers modifies

| Fichier | Modifications |
|---------|--------------|
| `app/login/page.tsx` | Bypass check-email invite, callbackUrl respect, OAuth callbackUrl, post-OTP redirect |
| `app/invite/continue/page.tsx` | Cookie role, redirect "already member", bouton erreur |
| `app/auth/callback/page.tsx` | Detection invite token avant routing OAuth |
| `src/lib/routeAccessGuard.ts` | `/api/invite` dans API_PUBLIC_PREFIXES |

## Flow corrige E2E

```
1. Admin cree agent → invitation envoyee (PH140-D)
2. Agent clique /invite/{token}
3. Token stocke en cookie (client + HTTP-only)
4. Redirect vers /auth/signin?callbackUrl=/invite/continue?token={token}
5. /auth/signin → /login?callbackUrl=...

6a. OTP : email entre → bypass check-email (invite detectee)
    → OTP envoye → code verifie → redirect /invite/continue
6b. OAuth : signIn('google', { callbackUrl: '/invite/continue?token=...' })
    → Google auth → callback → detect invite → /invite/continue

7. /invite/continue :
   → session active
   → POST /api/space-invites/accept { token }
   → user_tenants cree
   → cookies currentTenantId + currentTenantRole poses
   → redirect /inbox (agent) ou /dashboard (admin)

8. Agent arrive dans son workspace avec bandeau mode agent (PH140-C)
```

## Non-regressions verifiees

- [x] Client DEV HTTP 200
- [x] API DEV health OK
- [x] Login owner/admin inchange (check-email fonctionne si pas d'invite)
- [x] OAuth callback preserve le flow standard sans invite
- [x] PH140-A escalade intacte
- [x] PH140-B workspace intacte
- [x] PH140-C role scoping intacte
- [x] PH140-D statut invitation intacte

## Versions

| Service | Tag | Env |
|---------|-----|-----|
| Client | `v3.5.169-agent-invite-tenant-recovery-dev` | DEV |
| Client | `v3.5.169-agent-invite-tenant-recovery-prod` | PROD |

## Rollback

```bash
# Rollback DEV
CONTAINER=$(kubectl get deploy keybuzz-client -n keybuzz-client-dev -o jsonpath='{.spec.template.spec.containers[0].name}')
kubectl set image deployment/keybuzz-client "$CONTAINER=ghcr.io/keybuzzio/keybuzz-client:v3.5.168-agent-invite-login-unified-dev" -n keybuzz-client-dev

# Rollback PROD
CONTAINER=$(kubectl get deploy keybuzz-client -n keybuzz-client-prod -o jsonpath='{.spec.template.spec.containers[0].name}')
kubectl set image deployment/keybuzz-client "$CONTAINER=ghcr.io/keybuzzio/keybuzz-client:v3.5.168-agent-invite-login-unified-prod" -n keybuzz-client-prod
```
