# PH143-AGENTS-R5 — Real OTP Session Completion

> Date : 2026-04-08
> Environnement : DEV uniquement
> Image : `v3.5.224-ph143-agents-otp-session-fix-dev`
> Client SHA : `2adbd40`

---

## 1. Objectif

Corriger le dernier bug du flow agent : apres validation OTP, l'utilisateur etait redirige vers `/login` au lieu de completer l'invitation via `/invite/continue`.

---

## 2. Cause racine

### Le probleme

```
1. Agent clique lien invitation → /invite/[token]
2. Redirect → /login?invite_token=xxx&callbackUrl=%2Finvite%2Fcontinue%3Ftoken%3Dxxx
3. OTP envoye et valide → signIn('email-otp', { redirect: false })
4. Cookie session NextAuth pose dans le navigateur
5. router.push(callbackUrl) → navigation CLIENT-SIDE vers /invite/continue
6. /invite/continue → useSession() → RETOURNE 'unauthenticated' ← BUG ICI
7. Redirect vers /auth/signin → retour login
```

### Pourquoi useSession() retourne 'unauthenticated'

Apres `signIn({ redirect: false })`, le cookie de session est pose par le navigateur. Cependant, `router.push()` effectue une **navigation client-side** (SPA). Le `SessionProvider` de NextAuth n'est **pas reinitialise** — il conserve l'ancien etat de session (`unauthenticated`) en memoire.

Comparaison avec le flow normal :
- `onLoginSuccess()` appelle `fetchAuth()` **avant** de naviguer → le contexte auth est rafraichi
- Le callbackUrl redirect utilisait `router.push()` **sans** rafraichir le contexte auth

### Pourquoi le flow normal fonctionnait

```typescript
// onLoginSuccess (flow standard) :
const onLoginSuccess = useCallback(() => {
  setStatus('loading');
  fetchAuth().then(() => {        // ← Rafraichit le contexte
    router.replace('/select-tenant');
  });
}, [fetchAuth, router]);
```

`fetchAuth()` force le `SessionProvider` a relire les cookies et mettre a jour l'etat interne.

---

## 3. Correction appliquee

### Avant (BUG)
```typescript
// app/login/page.tsx, ligne 74
const timer = setTimeout(() => { router.push(decodeURIComponent(callbackUrl)); }, 500);
```

### Apres (FIX)
```typescript
// app/login/page.tsx, ligne 74
const timer = setTimeout(() => { window.location.href = decodeURIComponent(callbackUrl); }, 500);
```

**Effet** : `window.location.href` force un **rechargement complet de page**. Le `SessionProvider` est reinitialise depuis zero, lit le cookie de session, et retourne `'authenticated'`. Le flow `/invite/continue` se deroule alors normalement.

---

## 4. Chainaze callbackUrl verifie

```
1. /invite/[token] construit :
   callbackUrl = encodeURIComponent(`/invite/continue?token=${token}`)
   → %2Finvite%2Fcontinue%3Ftoken%3D<token>

2. URL login :
   /login?invite_token=<token>&callbackUrl=%2Finvite%2Fcontinue%3Ftoken%3D<token>

3. searchParams.get('callbackUrl') :
   → /invite/continue?token=<token>  (decodage auto par URLSearchParams)

4. decodeURIComponent(callbackUrl) :
   → /invite/continue?token=<token>  (no-op, deja decode)

5. window.location.href = '/invite/continue?token=<token>'
   → rechargement complet → SessionProvider reinitialise → useSession() = 'authenticated'
```

Aucun probleme d'encodage/decodage. Le chainaze est correct de bout en bout.

---

## 5. Flow agent complet attendu (post-fix)

```
1. Owner cree un agent dans Settings > Agents > Ajouter
2. Agent recoit email d'invitation avec lien
3. Clic lien → /invite/[token] → redirect /login avec invite_token + callbackUrl
4. Agent saisit email → OTP envoye (check-email bypasse grace a invite_token)
5. Agent saisit OTP → signIn({ redirect: false }) → cookie session pose
6. Succes → window.location.href = /invite/continue?token=xxx  [FIX R5]
7. /invite/continue → useSession() = 'authenticated' → acceptInvite()
8. POST /api/space-invites/accept → user_tenants + agents.user_id crees
9. Redirect → /dashboard ou /inbox
10. Mode agent : bandeau, nav reduite, /settings bloque, /billing bloque
```

---

## 6. Validation

### Technique
| Test | Resultat |
|------|----------|
| Fix deploye | `window.location.href` present dans login/page.tsx |
| `router.push` absent du callbackUrl path | Confirme |
| Pages publiques : /login, /invite/*, /invite/continue | HTTP 200 |
| Pages auth : /inbox, /settings, /billing | HTTP 307 (redirect login) |
| Creation agent API | HTTP 201 |
| Envoi invitation API | HTTP 200 |
| Client SHA | `2adbd40` |

### Navigateur reel - Checklist Ludovic

A valider par Ludovic en navigation reelle :

- [ ] Creer ou reutiliser un agent invite
- [ ] Ouvrir le mail d'invitation
- [ ] Cliquer le lien → arrive sur /login avec invite_token
- [ ] Saisir l'email de l'agent
- [ ] Recevoir l'OTP (demander le code a Ludovic)
- [ ] Saisir le code OTP
- [ ] **Verifier : PAS de retour sur /login** → passage a /invite/continue
- [ ] **Verifier : invitation acceptee** (user_tenants cree)
- [ ] **Verifier : session agent active** (mode agent visible)
- [ ] Bandeau "Mode Agent" visible
- [ ] Navigation reduite visible
- [ ] /settings bloque ou cache
- [ ] /billing bloque ou cache
- [ ] /inbox accessible

---

## 7. Image DEV

```
Image  : ghcr.io/keybuzzio/keybuzz-client:v3.5.224-ph143-agents-otp-session-fix-dev
SHA    : sha256:8ed913eabd54dac4a572edcac0894679cc17e6fa4b980099a1508e9f5f3b346f
Client : 2adbd40
Base   : release/client-v3.5.220
```

---

## 8. Commits

| SHA | Message |
|-----|---------|
| `2adbd40` | PH143-AGENTS-R5: fix OTP session completion for invited agents |

---

## 9. Quota

Le quota n'a PAS ete modifie dans cette phase. La regle R4 reste en vigueur :
- Admin compte dans le total
- Affichage : `activeClientCount/maxAgents`

Si le quota est encore discutable, ce sera traite dans une phase separee.

---

## 10. Verdict

**REAL AGENT OTP FLOW COMPLETED** (au niveau code)

La cause racine (router.push vs window.location.href) est corrigee. Le flow technique est desormais :
- OTP valide → cookie pose → rechargement complet → session reconnue → invitation acceptee

**Validation navigateur reelle requise** par Ludovic (section 6 checklist).
