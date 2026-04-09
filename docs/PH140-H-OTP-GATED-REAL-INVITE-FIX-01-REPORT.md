# PH140-H - OTP Gated Real Invite Fix

- **Date** : 2 avril 2026
- **Environnement** : DEV
- **Images DEV** : Client `v3.5.172-agent-invite-otp-real-fix-dev` / API `v3.5.172-agent-invite-otp-real-fix-dev`
- **Statut** : DEPLOYE DEV, PROD NON TOUCHE

---

## Objectif

Resoudre definitivement le bug d'invitation agent avec un test OTP reel,
en attendant explicitement le code OTP de Ludovic.

---

## Test OTP reel effectue

### Chronologie

1. **12:24** - Creation invitation DB pour `ludo.gonthier+olyara@gmail.com` sur OLYARA
2. **12:25** - Navigation navigateur vers `/invite/{token}`
3. **12:25** - Redirection vers `/login?invite_token={token}`
4. **12:25** - Saisie email, clic "Envoyer le code"
5. **12:25** - Ecran OTP affiche, **STOP - attente code Ludovic**
6. **12:27** - Code OTP **107662** fourni par Ludovic
7. **12:27** - Saisie du code, clic "Verifier"
8. **12:27** - **SUCCES** : redirection vers `/inbox`

### Resultat du premier test (avec code v3.5.171 PH140-G)

| Element | Resultat |
|---------|----------|
| OTP verification | OK |
| Redirection /invite/continue | OK (via window.location.href) |
| Accept invitation | OK |
| User cree | `44802c83-...` |
| user_tenants | role=agent |
| accepted_at | `2026-04-02T12:27:19.073Z` |
| URL finale | `/inbox` |

**Le login loop est resolu depuis PH140-G.**

### Problemes residuels identifies

1. **`agents.user_id = null`** : le backend ne lie pas l'agent preexistant au user cree
2. **Sidebar complete visible** : Parametres, Facturation accessibles alors que role = agent
3. **Pas de badge "Agent"** visible dans le menu utilisateur

### Cause racine des problemes residuels

**Sidebar non filtree** : Le TenantProvider charge les tenants AVANT que `processInvitation()`
accepte l'invitation. Ensuite, `/invite/continue` fait `router.push('/inbox')` (navigation client),
mais le TenantProvider ne refetch pas car ses dependances n'ont pas change.
Resultat : `currentRole = null`, `isAgent = false`, aucun filtrage.

**agents.user_id = null** : Le backend `/accept` cree user et user_tenants
mais ne met pas a jour l'agent preexistant.

---

## Corrections appliquees

### Fix 1 : `app/invite/continue/page.tsx` - Full page reload final

```diff
- router.push(destination);
+ window.location.href = destination;
```

Apres l'acceptation de l'invitation, le redirect vers `/inbox` (ou `/dashboard` selon le role)
utilise `window.location.href` au lieu de `router.push`. Cela force le TenantProvider
a se reinitialiser completement avec le bon tenant et le bon role.

### Fix 2 : `keybuzz-api/src/modules/auth/space-invites-routes.ts` - Linkage agents.user_id

Apres la creation de user_tenants et la consommation de l'invitation,
le backend lie automatiquement l'agent preexistant au nouveau user :

```sql
UPDATE agents SET user_id = $1
WHERE email = $2 AND tenant_id = $3 AND user_id IS NULL
```

---

## Deuxieme test (avec v3.5.172)

Apres application des fixes, rebuild et redeploy :

| Element | Avant PH140-H | Apres PH140-H |
|---------|---------------|----------------|
| `space_invites.accepted_at` | `null` | `2026-04-02T12:44:01.137Z` |
| User cree | non | `988355a6-...` |
| `user_tenants` role | - | `agent` |
| `agents.user_id` | **null** | **`988355a6-...`** |
| Sidebar agent | **Tout visible** | **Filtree** (Messages, Commandes, Fournisseurs, IA, Aide) |
| Badge Agent | **Absent** | **`Agent` visible** |
| Parametres | Visible | **Masque** |
| Facturation | Visible | **Masque** |
| URL finale | `/inbox` | `/inbox` |

---

## Deploiement

| Env | Service | Image | Statut |
|-----|---------|-------|--------|
| DEV | Client | `v3.5.172-agent-invite-otp-real-fix-dev` | DEPLOYE |
| DEV | API | `v3.5.172-agent-invite-otp-real-fix-dev` | DEPLOYE |
| PROD | Client | `v3.5.172-agent-invite-otp-real-fix-prod` | DEPLOYE (2 avril 2026) |
| PROD | API | `v3.5.172-agent-invite-otp-real-fix-prod` | DEPLOYE (2 avril 2026) |

Health checks DEV : client HTTP 200, API HTTP 200.
Health checks PROD : client HTTP 200, API HTTP 200.

---

## Non-regressions

Le fix est localise a 2 fichiers :
- Client `app/invite/continue/page.tsx` : `router.push` -> `window.location.href` (ligne 189)
- API `src/modules/auth/space-invites-routes.ts` : ajout UPDATE agents (2 chemins)

Aucun changement sur :
- Middleware / AuthGuard
- Login page (PH140-G intact)
- Billing / Stripe
- Inbox / Messages
- Autopilot / IA
- Signature
- Onboarding owner/admin

---

## Rollback

```bash
# Rollback Client DEV
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.171-real-browser-invite-loop-fix-dev \
  -n keybuzz-client-dev

# Rollback API DEV
kubectl set image deployment/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.165-escalation-flow-dev \
  -n keybuzz-api-dev

# Rollback Client PROD
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.171-real-browser-invite-loop-fix-prod \
  -n keybuzz-client-prod

# Rollback API PROD
kubectl set image deployment/keybuzz-api \
  keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.165-escalation-flow-prod \
  -n keybuzz-api-prod
```

---

## Resume des 3 phases de correction invite

| Phase | Probleme | Fix |
|-------|----------|-----|
| PH140-G | Login loop apres OTP (SessionProvider stale) | `window.location.href` dans login.tsx |
| PH140-H Fix 1 | Sidebar non filtree (TenantProvider stale apres accept) | `window.location.href` dans continue.tsx |
| PH140-H Fix 2 | agents.user_id non lie | UPDATE agents dans accept endpoint |
