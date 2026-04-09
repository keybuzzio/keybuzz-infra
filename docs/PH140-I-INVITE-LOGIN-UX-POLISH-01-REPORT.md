# PH140-I — Invite Login UX Polish

> Date : 2 avril 2026
> Statut : **DEV + PROD DEPLOYES ET VALIDES**
> Tag DEV : `v3.5.173-invite-login-ux-polish-dev`
> Tag PROD : `v3.5.173-invite-login-ux-polish-prod`

---

## Objectif

Rendre le flow d'invitation agent clair et fluide :
- Email prerempli automatiquement depuis le token d'invitation
- UI dediee avec contexte d'invitation visible
- OTP envoye automatiquement (zero clic supplementaire)
- Aucune confusion avec le login generique

---

## Avant / Apres

| Aspect | AVANT (PH140-H) | APRES (PH140-I) |
|--------|------------------|------------------|
| Email | Champ vide, l'agent doit taper son email | Pre-rempli + read-only |
| Titre | "Connexion" (generique) | "Connexion a votre invitation" |
| Contexte | Aucune indication d'invitation | Bandeau "Vous rejoignez l'espace [nom]" |
| OTP | L'agent doit cliquer "Envoyer le code" | Envoi automatique a l'arrivee |
| Experience | 4 etapes manuelles | 1 seule etape (saisir le code) |

---

## Modifications techniques

### 1. Backend API — Nouveau endpoint `GET /space-invites/resolve`

**Fichier** : `keybuzz-api/src/modules/auth/space-invites-routes.ts`

Resout un token d'invitation sans le consommer. Retourne email, role et nom du tenant.
- Pas d'authentification requise (utilise avant le login)
- Verifie que l'invitation est valide et non expiree
- Utilise `hashToken()` pour lookup securise

### 2. BFF — Route proxy `GET /api/space-invites/resolve`

**Fichier** : `keybuzz-client/app/api/space-invites/resolve/route.ts`

Proxy vers le backend API. Accessible sans session.

### 3. Page Invite — Resolution avant redirect

**Fichier** : `keybuzz-client/app/invite/[token]/page.tsx`

- Appelle `/api/space-invites/resolve?token=xxx` au chargement
- Attend la reponse (state `resolveComplete`) avant de rediriger
- Passe `invite_email` et `invite_tenant` en URL params vers `/login`

### 4. Page Login — UI dediee invitation + auto-OTP

**Fichier** : `keybuzz-client/app/login/page.tsx`

- Lit `invite_email`, `invite_tenant` depuis les searchParams
- Pre-remplit l'email en read-only si invite flow
- Affiche bandeau bleu "Vous rejoignez l'espace [nom]"
- Titre specifique "Connexion a votre invitation"
- Auto-soumission du formulaire email apres 500ms (envoi OTP automatique)
- Login owner/admin non affecte (aucun changement sans `invite_token`)

---

## Test E2E DEV — Resultat

### Flow teste
1. Invitation creee pour `ludo.gonthier+olyara@gmail.com` sur tenant OLYARA
2. Clic sur le lien d'invitation
3. Page intermediaire affiche "Invitation KeyBuzz" + nom tenant
4. Redirect vers `/login` avec email + tenant dans l'URL
5. Email pre-rempli, OTP envoye automatiquement
6. Code OTP saisi manuellement (726578)
7. Arrivee sur `/inbox` — sidebar agent filtree — badge "Agent" visible

### Verification DB
- `users` : user cree
- `user_tenants` : role `agent` sur `olyara369-gmail-com-mnhbjch6`
- `agents.user_id` : lie au user
- `user_preferences.current_tenant_id` : correct
- `space_invites.accepted_at` : rempli

### Non-regressions
- Login owner generique (`/login` sans invite) : titre "Connexion", email vide, pas de bandeau — OK
- Health check API : 200
- Health check Client : 200

---

## Images deployees

| Service | Namespace | Image |
|---------|-----------|-------|
| API DEV | keybuzz-api-dev | `v3.5.173-invite-login-ux-polish-dev` |
| Client DEV | keybuzz-client-dev | `v3.5.173-invite-login-ux-polish-dev` |
| API PROD | keybuzz-api-prod | `v3.5.173-invite-login-ux-polish-prod` |
| Client PROD | keybuzz-client-prod | `v3.5.173-invite-login-ux-polish-prod` |

---

## Rollback

### DEV
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.172-agent-invite-otp-real-fix-dev -n keybuzz-client-dev
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.172-agent-invite-otp-real-fix-dev -n keybuzz-api-dev
```

### PROD
```bash
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.172-agent-invite-otp-real-fix-prod -n keybuzz-client-prod
kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.172-agent-invite-otp-real-fix-prod -n keybuzz-api-prod
```

---

## Limites

- Le bandeau d'invitation montre le `tenant.name` tel quel en DB (ex: `olyara369@gmail.com`). Si un nom plus lisible est configure dans le tenant, il sera utilise automatiquement.
- L'auto-envoi OTP utilise `requestSubmit()` avec un delai de 500ms. Si le navigateur est tres lent, le formulaire peut ne pas etre soumis automatiquement. L'utilisateur peut toujours cliquer manuellement.

---

## PROD — Deploye le 2 avril 2026

- Build `--no-cache` avec `NEXT_PUBLIC_APP_ENV=production`
- Push vers `ghcr.io`
- Rollout confirme OK
- Health checks : API `https://api.keybuzz.io/health` = 200, Client `https://client.keybuzz.io/login` = 200
- GitOps mis a jour (deployment.yaml DEV + PROD)
