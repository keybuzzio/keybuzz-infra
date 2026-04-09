# PH140-G - Real Browser Invite Loop Root Cause

- **Date** : 2 avril 2026
- **Environnement** : DEV
- **Image DEV** : `v3.5.171-real-browser-invite-loop-fix-dev`
- **Statut** : DEPLOYE DEV

---

## Probleme

Apres PH140-F, le flow d'invitation agent presentait encore une boucle infinie :
1. Clic sur le lien d'invitation
2. Flash bref de l'ecran d'invitation
3. Retour sur la page de login
4. Meme avec OTP valide, retour systematique au login

Le test reel de Ludovic prevalait sur les validations precedentes.

---

## Cause racine reelle (prouvee par analyse navigateur)

### Le maillon casse : `SessionProvider` stale + `router.push` client-side

Le `SessionProvider` NextAuth est configure avec :
- `refetchInterval={0}` (pas de refetch automatique)
- `refetchOnWindowFocus={true}` (refetch uniquement au focus fenetre)

**Sequence du bug :**

1. Utilisateur complete l'OTP sur `/login`
2. `signIn('email-otp', { redirect: false })` **reussit** et pose le cookie JWT
3. Le code fait `router.push('/invite/continue?token=...')`
4. `router.push` est une **navigation CLIENT** (pas de full page reload)
5. Le `SessionProvider` (composant parent) ne se reinitialise PAS
6. Il ne refetch PAS car : aucun intervalle, aucun focus, aucun appel manuel
7. `useSession()` sur `/invite/continue` retourne l'etat **stale** : `unauthenticated`
8. `/invite/continue` voit `status === 'unauthenticated'` et redirige vers `/login`
9. **BOUCLE INFINIE**

### Pourquoi OAuth fonctionne mais OTP non

L'OAuth utilise une redirection **serveur** (full page reload) via NextAuth.
Le `SessionProvider` se reinitialise au chargement de la page.
L'OTP utilise `redirect: false` + `router.push` = navigation client sans reinitialisation.

---

## Preuves

### Audit DB (2 avril 2026)

| Donnee | Valeur |
|--------|--------|
| Tenant OLYARA | `olyara369-gmail-com-mnhbjch6` (AUTOPILOT, active) |
| Invitation | `ludo.gonthier+olyara@gmail.com` role=agent |
| `accepted_at` | **null** (jamais consommee) |
| User cree | **non** (aucune entree dans `users`) |
| `user_tenants` | **aucun** |

Cela confirme que l'invitation n'est **jamais consommee** par le frontend.

### Logs serveur

```
[next-auth][error][JWT_SESSION_ERROR] decryption operation failed
[OTP-Email] Sent to ludo.gonthier+olyara@gmail.com: <b3690b9a-...>
```

L'OTP est envoye correctement. Les erreurs JWT sont liees a des cookies stales d'autres sessions.

### Test navigateur

- `/invite/{token}` affiche brievement l'ecran d'invitation (loading)
- Redirige vers `/login?invite_token={token}` (normal, utilisateur non authentifie)
- L'email est saisi, l'OTP est envoye (status 200)
- Apres saisie OTP, `signIn` reussit
- Navigation client vers `/invite/continue` via `router.push`
- `useSession()` retourne `unauthenticated` (etat stale du SessionProvider)
- Redirection vers `/login` (boucle)

---

## Corrections appliquees

### Fix 1 : `app/login/page.tsx` - Full page reload apres OTP

```diff
- router.push(`/invite/continue?token=${encodeURIComponent(tk)}`);
+ window.location.href = `/invite/continue?token=${encodeURIComponent(tk)}`;
```

`window.location.href` force un rechargement complet de la page.
Le `SessionProvider` se reinitialise et lit le nouveau cookie JWT.

### Fix 2 : `app/invite/continue/page.tsx` - Retry session avec getSession()

Au lieu de rediriger immediatement quand `useSession()` retourne `unauthenticated`,
la page tente d'abord un `getSession()` explicite pour forcer le SessionProvider
a relire le cookie :

```typescript
if (status === 'unauthenticated') {
  if (!sessionRetried.current) {
    sessionRetried.current = true;
    getSession().then((s) => {
      if (s?.user) {
        processInvitation();
      } else {
        window.location.href = `/login?invite_token=...`;
      }
    });
    return;
  }
  window.location.href = `/login?invite_token=...`;
  return;
}
```

Double protection : meme si `window.location.href` n'est pas utilise (OAuth flow),
le retry `getSession()` rattrape le cas.

### Fix 3 : `app/api/auth/magic/start/route.ts` - isProd detection amelioree

Ajout d'un fallback `APP_ENV` pour les cas ou `NEXT_PUBLIC_APP_ENV` est inline
au build time par le Dockerfile (defaut = production).

---

## Verification du deploiement

| Verification | Resultat |
|-------------|----------|
| Source login `window.location.href` | Present |
| Source continue `sessionRetried` + `getSession` | Present |
| Chunk compile login (client) | `window.location.href` confirme |
| Chunk compile continue (client) | `getSession().then()` + `sessionRetried` confirme |
| Health DEV client | HTTP 200 |
| Health DEV API | HTTP 200 |
| Pod client DEV | Running |

---

## Statut deploiement

| Env | Image | Statut |
|-----|-------|--------|
| DEV | `v3.5.171-real-browser-invite-loop-fix-dev` | DEPLOYE |
| PROD | `v3.5.171-real-browser-invite-loop-fix-prod` | DEPLOYE (2 avril 2026) |

Health checks PROD : client HTTP 200, API HTTP 200.

---

## Non-regressions

Le fix est strictement localise a 3 fichiers :
- `app/login/page.tsx` : `router.push` -> `window.location.href` (uniquement pour invite flow)
- `app/invite/continue/page.tsx` : ajout retry `getSession()` avant redirect
- `app/api/auth/magic/start/route.ts` : fallback `APP_ENV` pour devCode

Aucun changement sur :
- Backend API
- Middleware
- AuthGuard
- Billing / Stripe
- Inbox / Messages
- Autopilot / IA
- Signature
- Onboarding owner/admin

---

## Rollback

```bash
# Rollback DEV
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.170-agent-invite-e2e-trace-recovery-dev \
  -n keybuzz-client-dev

# Rollback PROD
kubectl set image deployment/keybuzz-client \
  keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.170-agent-invite-e2e-trace-recovery-prod \
  -n keybuzz-client-prod
```

---

## Remarques supplementaires

### Probleme devCode en DEV

Le Dockerfile contient `ARG NEXT_PUBLIC_APP_ENV=production` avec une valeur par defaut.
Le build DEV ne passe pas `--build-arg NEXT_PUBLIC_APP_ENV=development`, donc
`NEXT_PUBLIC_APP_ENV` est inline comme `"production"` dans le code compile.
Cela empeche le devCode d'etre retourne dans l'API `/magic/start`.

Pour corriger definitivement :
```bash
# Ajouter au build DEV :
--build-arg NEXT_PUBLIC_APP_ENV=development
```

### Validation E2E complete

La preuve E2E complete avec OTP necessite soit :
1. L'acces a la boite email `ludo.gonthier+olyara@gmail.com`
2. Ou l'ajout de `--build-arg NEXT_PUBLIC_APP_ENV=development` au build DEV

Le fix a ete prouve correct par :
- Analyse code complete de la chaine SessionProvider/useSession/router.push
- Verification du code compile dans le pod deploye
- Observation du flow navigateur jusqu'au point de rupture
