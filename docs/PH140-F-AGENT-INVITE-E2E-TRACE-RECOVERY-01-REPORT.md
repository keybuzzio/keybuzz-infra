# PH140-F - Agent Invite E2E Trace Recovery

> Date : 2026-04-02
> Environnement : DEV + PROD
> Image DEV : `v3.5.170-agent-invite-e2e-trace-recovery-dev`
> Image PROD : `v3.5.170-agent-invite-e2e-trace-recovery-prod`

## Probleme observe

Ludovic a teste le flow d'invitation agent : apres le clic sur le lien d'invitation, traitement/flash, puis retour sur la page de login. L'invitation n'est jamais consommee.

## Audit DB reel (preuves)

- **5 invitations recentes** toutes avec `accepted_at = null`
- **Aucun `user_tenants`** cree pour les emails invites
- **Aucune trace dans les logs serveur** de l'endpoint `/api/space-invites/accept`
- **Backend fonctionne** : appel direct a l'API backend avec `X-User-Email` = OK (user cree, invite consommee, user_tenants cree)

## Causes racines identifiees

### 1. Middleware bloque `/api/space-invites/accept` (CRITIQUE)

`/api/space-invites` n'etait PAS dans `API_PUBLIC_PREFIXES`. Le middleware Next.js verifie le JWT pour toute route non-publique. Si le JWT cookie n'est pas encore disponible apres le `signIn` (timing), le middleware redirige vers `/auth/signin` — transformant la reponse fetch en HTML au lieu de JSON.

### 2. Flow trop fragile (chaine callbackUrl + cookies)

Le flow PH140-E dependait d'une chaine complexe :
1. `/invite/{token}` → cookie + callbackUrl encode
2. `/auth/signin?callbackUrl=...` → re-encode
3. `/login?callbackUrl=...` → decode
4. Apres OTP → `decodeURIComponent(callbackUrl)` → redirect

Toute rupture dans cette chaine (cookie perdu, URL mal encodee, timing session) ramenait au login via `onLoginSuccess()` → `/select-tenant`.

### 3. `credentials: 'include'` absent

Le `fetch` vers `/api/space-invites/accept` n'avait pas `credentials: 'include'`, ce qui peut empecher l'envoi des cookies dans certains cas.

## Corrections appliquees (6 fichiers)

### `src/lib/routeAccessGuard.ts`
- Ajout `/api/space-invites` dans `API_PUBLIC_PREFIXES`
- Le BFF verifie toujours la session via `getServerSession` (securite maintenue)

### `app/invite/[token]/page.tsx`
- Redirect direct vers `/login?invite_token={token}` au lieu de `/auth/signin?callbackUrl=...`
- Elimine la chaine de callbackUrl fragile

### `app/login/page.tsx`
- Nouveau parametre `invite_token` lu directement depuis l'URL
- `hasPendingInvite` = true si `invite_token` present OU cookie OU callbackUrl
- Apres OTP verify : redirect direct vers `/invite/continue?token={token}` via URL
- OAuth : `callbackUrl` + `sessionStorage` pour preserver le token

### `app/invite/continue/page.tsx`
- Ajout `credentials: 'include'` sur le fetch accept
- `sessionStorage` comme source de secours pour le token (post-OAuth)
- Redirect vers `/login?invite_token=` au lieu de `/auth/signin?callbackUrl=`

### `app/auth/callback/page.tsx`
- Verification `sessionStorage` pour le token invite (post-OAuth)
- `encodeURIComponent` sur le token dans l'URL de redirect

### `app/api/space-invites/accept/route.ts`
- Logging serveur complet (session, token, backend response)
- Utilise `API_URL_INTERNAL` pour le BFF-to-backend call

## Flow corrige

```
1. Email invite arrive avec lien /invite/{token}
2. /invite/{token} → stocke cookie + redirect /login?invite_token={token}
3. Login page → detecte invite_token → skip check-email → OTP
4. OTP verify → signIn OK → redirect /invite/continue?token={token}
5. /invite/continue → fetch /api/space-invites/accept (credentials: include)
6. BFF: getServerSession → X-User-Email → backend accept
7. Backend: user auto-cree + user_tenants + accepted_at
8. Frontend: cookies tenant/role → redirect /inbox
```

## Test backend valide

```bash
curl -X POST https://api-dev.keybuzz.io/space-invites/accept \
  -H 'X-User-Email: switaa26+ph140f@gmail.com' \
  -d '{"token":"81f64b..."}'
# → {"success":true,"tenantId":"switaa-sasu-mnc1x4eq","role":"agent"}
# → DB: accepted_at rempli, user cree, user_tenants cree
```

## Non-regressions

- Owner/admin login : inchange (pas de modification du flow standard)
- Onboarding tenant : inchange
- PH140-A escalade : inchange
- PH140-B workspace : inchange
- PH140-C role scoping : inchange
- PH140-D invitation bridge : renforce
- PH139 signature : inchange
- Billing Stripe : aucune modification

## Rollback

```bash
# Rollback DEV
CONTAINER=$(kubectl get deploy keybuzz-client -n keybuzz-client-dev -o jsonpath='{.spec.template.spec.containers[0].name}')
kubectl set image deployment/keybuzz-client "$CONTAINER=ghcr.io/keybuzzio/keybuzz-client:v3.5.169-agent-invite-tenant-recovery-dev" -n keybuzz-client-dev

# Rollback PROD
CONTAINER=$(kubectl get deploy keybuzz-client -n keybuzz-client-prod -o jsonpath='{.spec.template.spec.containers[0].name}')
kubectl set image deployment/keybuzz-client "$CONTAINER=ghcr.io/keybuzzio/keybuzz-client:v3.5.169-agent-invite-tenant-recovery-prod" -n keybuzz-client-prod
```

## Statut deploiement

| Env | Image | Status |
|-----|-------|--------|
| DEV | `v3.5.170-agent-invite-e2e-trace-recovery-dev` | DEPLOYE |
| PROD | `v3.5.170-agent-invite-e2e-trace-recovery-prod` | DEPLOYE |

## Validation PROD

- Client PROD : HTTP 200
- API PROD : HTTP 200
- Rollout : `successfully rolled out`
- GitOps : `deployment.yaml` PROD mis a jour
