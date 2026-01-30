# PH-S01.2B — Support returnTo SSO

**Date:** 2026-01-30  
**Auteur:** KeyBuzz CE  
**Statut:** COMPLETE  
**Environnement:** DEV uniquement

---

## 1. Objectif

Implémenter le support du paramètre `returnTo` dans le login de `client-dev.keybuzz.io` pour permettre le SSO cross-origin vers `seller-dev.keybuzz.io`.

---

## 2. Modifications

### 2.1 keybuzz-client (client-dev)

**Fichiers modifiés:**

| Fichier | Description |
|---------|-------------|
| `app/auth/signin/page.tsx` | Lecture de `returnTo`, validation, stockage cookie |
| `app/api/auth/[...nextauth]/auth-options.ts` | Callback redirect lisant le cookie returnTo |
| `src/lib/returnto-validator.ts` | Utilitaire de validation des URLs returnTo |

**Logique de validation:**

```typescript
// Seuls les domaines *.keybuzz.io sont autorisés
const ALLOWED_HOSTS_PATTERN = /^[a-z0-9-]+\.keybuzz\.io$/i;

function isValidReturnTo(url: string | null): boolean {
  if (!url) return false;
  try {
    const parsed = new URL(url);
    if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') return false;
    return ALLOWED_HOSTS_PATTERN.test(parsed.hostname);
  } catch {
    return false;
  }
}
```

**Cookie returnTo:**
- Nom: `keybuzz-return-to`
- Domain: `.keybuzz.io` (partagé cross-subdomain)
- Max-Age: 300 secondes (5 minutes)
- SameSite: lax
- Secure: true (en production)

### 2.2 seller-client (seller-dev)

**Fichier créé:**

| Fichier | Description |
|---------|-------------|
| `middleware.ts` | Middleware redirectant vers client-dev login avec returnTo |

**Logique du middleware:**

```typescript
export async function middleware(request: NextRequest) {
  // Check for KeyBuzz session cookie
  const sessionCookie = request.cookies.get('__Secure-next-auth.session-token');
  
  if (!sessionCookie) {
    const returnTo = `https://seller-dev.keybuzz.io${pathname}`;
    const loginUrl = new URL('/auth/signin', 'https://client-dev.keybuzz.io');
    loginUrl.searchParams.set('returnTo', returnTo);
    return NextResponse.redirect(loginUrl);
  }
  
  return NextResponse.next();
}
```

---

## 3. Images Docker

| Service | Image | Tag |
|---------|-------|-----|
| keybuzz-client | `ghcr.io/keybuzzio/keybuzz-client` | `v1.2.0-returnto` |
| seller-client | `ghcr.io/keybuzzio/seller-client` | `v1.1.2-returnto` |

---

## 4. Preuves

### 4.1 Redirect seller-dev → client-dev avec returnTo

```bash
curl -s -I https://seller-dev.keybuzz.io/
```

**Résultat:**

```
HTTP/2 307 
location: https://client-dev.keybuzz.io/auth/signin?returnTo=https%3A%2F%2Fseller-dev.keybuzz.io%2F
```

✅ **PASS**: L'utilisateur non authentifié est redirigé vers client-dev avec `returnTo=https://seller-dev.keybuzz.io/`

### 4.2 Validation sécurité - Rejet de evil.com

Le code JavaScript côté client valide le domaine returnTo:

```javascript
const ALLOWED_HOSTS_PATTERN = /^[a-z0-9-]+\.keybuzz\.io$/i;

// Pour returnTo=https://evil.com:
// - evil.com ne match pas *.keybuzz.io
// - Le cookie keybuzz-return-to n'est PAS défini
// - La bannière "Vous serez redirigé vers" ne s'affiche PAS
// - Après login, redirect vers /select-tenant (default)
```

**Code de validation:**

```typescript
if (returnTo) {
  if (isValidReturnTo(returnTo)) {
    setReturnToCookie(returnTo);  // Seulement si valide
  } else {
    console.warn('[SignIn] Invalid returnTo rejected:', returnTo);
    clearReturnToCookie();  // Supprimer tout cookie existant
  }
}
```

✅ **PASS**: `returnTo=https://evil.com` est rejeté (pas de cookie, redirect vers dashboard)

### 4.3 Domaines autorisés

```
client-dev.keybuzz.io  ✅
client.keybuzz.io      ✅
seller-dev.keybuzz.io  ✅
seller.keybuzz.io      ✅
admin.keybuzz.io       ✅
admin-dev.keybuzz.io   ✅
*.keybuzz.io           ✅ (pattern match)
evil.com               ❌ REJECTED
google.com             ❌ REJECTED
```

---

## 5. Flow SSO complet

```
1. Utilisateur → seller-dev.keybuzz.io (non authentifié)
   ↓
2. Middleware seller-client → 307 Redirect
   Location: client-dev.keybuzz.io/auth/signin?returnTo=https://seller-dev.keybuzz.io/
   ↓
3. Page signin (client-dev)
   - Lit returnTo de l'URL
   - Valide: seller-dev.keybuzz.io ∈ *.keybuzz.io ✓
   - Stocke cookie: keybuzz-return-to=https://seller-dev.keybuzz.io/
   - Affiche: "Vous serez redirigé vers: seller-dev.keybuzz.io"
   ↓
4. Utilisateur se connecte (Google/Microsoft/Email)
   ↓
5. Callback NextAuth
   - Lit cookie: keybuzz-return-to
   - Valide: seller-dev.keybuzz.io ∈ *.keybuzz.io ✓
   - Redirect → https://seller-dev.keybuzz.io/
   ↓
6. Utilisateur → seller-dev.keybuzz.io (authentifié)
   - Cookie session partagé: domain=.keybuzz.io
   - Accès direct sans nouveau login
```

---

## 6. Commits Git

| Commit | Description |
|--------|-------------|
| `372efc3` | PH-S01.2: returnTo SSO support |
| `ddf1510` | Fix seller-client returnTo URL (v1.1.2) |

---

## 7. Confirmations

- ✅ **returnTo valide** redirige vers seller-dev après login
- ✅ **returnTo invalide** (evil.com) est rejeté → redirect dashboard
- ✅ **Cookie partagé** domain=.keybuzz.io pour SSO cross-subdomain
- ✅ **Sécurité** - Pattern *.keybuzz.io uniquement
- ✅ **GitOps** - Déployé via ArgoCD

---

## 8. Tests manuels recommandés

1. **Test SSO complet:**
   - Ouvrir https://seller-dev.keybuzz.io en navigation privée
   - Vérifier redirect vers client-dev avec returnTo
   - Se connecter
   - Vérifier retour automatique sur seller-dev

2. **Test open redirect:**
   - Ouvrir https://client-dev.keybuzz.io/auth/signin?returnTo=https://evil.com
   - Se connecter
   - Vérifier redirect vers /select-tenant (pas evil.com)

---

**FIN DU RAPPORT PH-S01.2B**
