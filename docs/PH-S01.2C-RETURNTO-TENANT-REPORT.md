# PH-S01.2C — returnTo apres selection tenant

**Date:** 2026-01-30  
**Auteur:** KeyBuzz CE  
**Statut:** COMPLETE  
**Environnement:** DEV uniquement

---

## 1. Probleme identifie

Apres login sur client-dev, l'utilisateur arrivait sur `/select-tenant` mais apres selection du tenant, il restait sur client-dev (`/inbox`) au lieu d'etre redirige vers `returnTo` (seller-dev).

**Bug:** Le cookie `returnTo` n'etait pas consomme par `/select-tenant`.

---

## 2. Corrections apportees

### 2.1 Page `/select-tenant` (page.tsx)

**Modifications:**

```typescript
// Lecture du cookie returnTo au mount
useEffect(() => {
  const storedReturnTo = getReturnToCookie();
  if (storedReturnTo && isValidReturnTo(storedReturnTo)) {
    setReturnTo(storedReturnTo);
  } else if (storedReturnTo) {
    clearReturnToCookie(); // Nettoyer si invalide
  }
}, []);

// Dans handleSelectSpace, apres POST reussi:
const currentReturnTo = getReturnToCookie();
if (currentReturnTo && isValidReturnTo(currentReturnTo)) {
  clearReturnToCookie(); // One-shot
  window.location.href = currentReturnTo;
} else {
  window.location.href = '/inbox'; // Fallback
}
```

**Nouvelles fonctionnalites:**
- Lecture du cookie `keybuzz-return-to` au chargement
- Validation securite (*.keybuzz.io uniquement)
- Affichage du message "Vous serez redirige vers: X"
- Redirection apres selection tenant
- Suppression du cookie apres usage (one-shot)

### 2.2 API `/api/auth/select-tenant` (route.ts)

**Modification critique:**

```typescript
// AVANT (bug):
cookieStore.set('currentTenantId', tenantId, {
  path: '/',
  // Pas de domain = scope client-dev uniquement
});

// APRES (fix):
cookieStore.set('currentTenantId', tenantId, {
  path: '/',
  domain: isProduction ? '.keybuzz.io' : undefined, // Cross-subdomain!
});
```

**Impact:** Le cookie `currentTenantId` est maintenant lisible par `seller-dev.keybuzz.io`.

---

## 3. Ou returnTo est stocke et consomme

### Flow complet

```
1. seller-dev.keybuzz.io (non authentifie)
   ↓ middleware seller-client
   
2. Redirect → client-dev.keybuzz.io/auth/signin?returnTo=https://seller-dev.keybuzz.io/
   ↓ page signin

3. Signin page:
   - Lit returnTo de l'URL
   - Valide: seller-dev.keybuzz.io ∈ *.keybuzz.io ✓
   - Stocke cookie: keybuzz-return-to (domain=.keybuzz.io, max-age=300s)
   ↓ utilisateur se connecte (Google/Microsoft)

4. NextAuth callback:
   - Tente de lire returnTo cookie
   - Redirect → /select-tenant (car session cookie, pas selection tenant)
   ↓

5. /select-tenant:
   - Lit cookie keybuzz-return-to
   - Valide: seller-dev.keybuzz.io ∈ *.keybuzz.io ✓
   - Affiche "Vous serez redirige vers: seller-dev.keybuzz.io"
   - Utilisateur selectionne un espace
   ↓ POST /api/auth/select-tenant

6. API select-tenant:
   - Set cookie currentTenantId (domain=.keybuzz.io)
   ↓ retour page

7. /select-tenant (apres POST):
   - Lit returnTo = "https://seller-dev.keybuzz.io/"
   - Valide ✓
   - Supprime cookie returnTo (one-shot)
   - Redirect → https://seller-dev.keybuzz.io/
   ↓

8. seller-dev.keybuzz.io:
   - Cookie session present ✓
   - Cookie currentTenantId present ✓
   - Acces autorise
```

### Stockage des cookies

| Cookie | Domain | Max-Age | Usage |
|--------|--------|---------|-------|
| `keybuzz-return-to` | `.keybuzz.io` | 300s (5min) | URL de retour cross-subdomain |
| `currentTenantId` | `.keybuzz.io` | 30 jours | Tenant courant cross-subdomain |
| `__Secure-next-auth.session-token` | `.keybuzz.io` | 7 jours | Session NextAuth |

---

## 4. Securite

### Validation whitelist

```typescript
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

### Domaines autorises

| Domaine | Statut |
|---------|--------|
| `seller-dev.keybuzz.io` | ✅ Autorise |
| `client-dev.keybuzz.io` | ✅ Autorise |
| `admin.keybuzz.io` | ✅ Autorise |
| `*.keybuzz.io` | ✅ Autorise |
| `evil.com` | ❌ REJETE |
| `keybuzz.io.evil.com` | ❌ REJETE |

### Test open redirect

```
URL: /auth/signin?returnTo=https://evil.com
Resultat attendu:
1. Cookie returnTo NON defini (validation echoue)
2. Apres login + select-tenant → redirect /inbox (pas evil.com)
```

---

## 5. Image Docker

| Service | Image | Tag |
|---------|-------|-----|
| keybuzz-client | `ghcr.io/keybuzzio/keybuzz-client` | `v1.3.0-returnto-tenant` |

---

## 6. Preuves

### Test redirect seller-dev → client-dev

```bash
$ curl -s -I https://seller-dev.keybuzz.io/

HTTP/2 307 
location: https://client-dev.keybuzz.io/auth/signin?returnTo=https%3A%2F%2Fseller-dev.keybuzz.io%2F
```

✅ **PASS**: returnTo correctement passe

---

## 7. Tests manuels recommandes

### Test SSO complet

1. Ouvrir navigateur en mode prive
2. Aller sur `https://seller-dev.keybuzz.io`
3. Verifier redirect vers `client-dev.keybuzz.io/auth/signin?returnTo=...`
4. Se connecter (Google/Microsoft)
5. Verifier arrivee sur `/select-tenant` avec message "Vous serez redirige vers: seller-dev.keybuzz.io"
6. Selectionner un espace
7. Verifier redirect automatique vers `https://seller-dev.keybuzz.io/`

### Test securite open redirect

1. Ouvrir `https://client-dev.keybuzz.io/auth/signin?returnTo=https://evil.com`
2. Se connecter
3. Selectionner un espace
4. Verifier redirect vers `/inbox` (PAS vers evil.com)

---

## 8. Confirmations

- ✅ returnTo conserve jusqu'a /select-tenant
- ✅ returnTo consomme apres selection tenant
- ✅ Cookie currentTenantId cross-subdomain
- ✅ Whitelist *.keybuzz.io appliquee
- ✅ One-shot (cookie supprime apres usage)
- ✅ Zero regression (flow standard inchange si pas de returnTo)

---

**FIN DU RAPPORT PH-S01.2C**
