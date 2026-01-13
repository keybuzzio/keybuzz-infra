# PH18-COLLAB-INVITES-FLOW-FIX-02 — Rapport

**Date :** 2026-01-13  
**Statut :** ✅ SUCCÈS  
**Objectif :** Corriger le flux d'invitation E2E (cookie HTTP-only + consommation après auth)

---

## 🎯 Résumé

Le flux d'invitation a été entièrement corrigé. Les utilisateurs invités sont maintenant automatiquement rattachés à l'espace invité après authentification (Email OTP ou Google OAuth).

---

## 📋 Problème Initial

1. Le cookie `kb_invite_token` était défini côté client (`document.cookie`)
2. Le cookie était perdu après la redirection OAuth (Google)
3. L'utilisateur invité arrivait sur le sélecteur Acme/Tech au lieu de l'espace invité

---

## 🔧 Corrections Appliquées

### 1. Cookie HTTP-only Server-Side

**Nouveau fichier :** `keybuzz-client/app/api/invite/set-token/route.ts`

```typescript
// POST: Définit le cookie HTTP-only
cookies().set('kb_invite_token', token, {
  httpOnly: true,
  secure: true,
  sameSite: 'lax',
  path: '/',
  maxAge: 60 * 60 * 24 // 24h
});

// DELETE: Supprime le cookie après consommation
cookies().delete('kb_invite_token');
```

### 2. Page /invite/[token]

- Appelle `/api/invite/set-token` pour stocker le token en HTTP-only
- Redirige vers `/auth/signin?callbackUrl=/invite/continue`
- Compatible Email OTP et Google OAuth

### 3. Page /invite/continue

- Lit le cookie `kb_invite_token`
- Appelle `POST /api/space-invites/accept`
- Définit `currentTenantId` vers le tenant invité
- Supprime le cookie après consommation
- Redirige vers `/dashboard`

### 4. Backend: Token en Clair (DEV)

**Modification :** `keybuzz-api/src/modules/auth/space-invites-routes.ts`

```typescript
// En DEV, retourner le token pour tests E2E
if (process.env.NODE_ENV !== 'production') {
  return { ok: true, devToken: token };
}
return { ok: true };
```

---

## 🧪 Test E2E — Preuve Complète

### Étape 1: Création Invitation

```bash
# Invitation créée vers ecomlg-002 pour ludo.gonthier+invite2@gmail.com
POST /api/v1/space-invites/ecomlg-002/invite
Body: { "email": "ludo.gonthier+invite2@gmail.com", "role": "agent" }
Response: { "ok": true, "devToken": "Xn...85s" }
```

### Étape 2: Navigation vers /invite/[token]

```
URL: https://client-dev.keybuzz.io/invite/XnM...85s
→ Cookie HTTP-only `kb_invite_token` défini
→ Redirection vers /auth/signin?callbackUrl=/invite/continue
```

### Étape 3: Authentification Google OAuth

```
Login avec: ludo.gonthier@gmail.com
→ Callback OAuth vers /invite/continue
```

### Étape 4: Consommation Invitation

```
GET /invite/continue
→ Lecture cookie kb_invite_token
→ POST /api/space-invites/accept { token: "..." }
→ Response: { tenantId: "ecomlg-002", role: "agent" }
→ Cookie currentTenantId=ecomlg-002 défini
→ Redirection /dashboard
```

### Étape 5: Preuves DB

```sql
-- Membership créé
SELECT tenant_id, role, email FROM user_tenants ut 
JOIN users u ON ut.user_id = u.id 
WHERE ut.tenant_id = 'ecomlg-002';

 tenant_id  | role  |          email          
------------+-------+-------------------------
 ecomlg-002 | agent | ludo.gonthier@gmail.com
 ecomlg-002 | owner | ludovic@ecomlg.fr
(2 rows)

-- Invitation marquée acceptée
SELECT email, role, accepted_at FROM space_invites 
WHERE tenant_id = 'ecomlg-002' AND email LIKE '%invite2%';

              email              | role  |        accepted_at        
---------------------------------+-------+---------------------------
 ludo.gonthier+invite2@gmail.com | agent | 2026-01-13 15:11:46.35501
```

### Étape 6: Preuve UI

**Screenshot :** L'espace `eComLG (ecomlg-002)` apparaît dans le sélecteur avec le rôle `agent` et est sélectionné ✓

![Espace visible dans le sélecteur](invite-e2e-success-ecomlg-002-visible.png)

---

## 📁 Fichiers Modifiés

| Fichier | Modification |
|---------|-------------|
| `keybuzz-api/src/modules/auth/space-invites-routes.ts` | Retourne `devToken` en DEV |
| `keybuzz-client/app/api/invite/set-token/route.ts` | **Nouveau** - API HTTP-only cookie |
| `keybuzz-client/app/invite/[token]/page.tsx` | Utilise API pour cookie + redirection |
| `keybuzz-client/app/invite/continue/page.tsx` | Consomme token + définit tenant |
| `keybuzz-client/middleware.ts` | `/invite` en routes publiques |

---

## ✅ Compatibilité

| Méthode Auth | Statut |
|--------------|--------|
| Email OTP | ✅ Testé |
| Google OAuth | ✅ Testé E2E |
| Apple/Microsoft | ✅ Devrait fonctionner (même flux) |

---

## 🔐 Sécurité

- Cookie `httpOnly: true` → pas accessible via JavaScript
- Cookie `secure: true` → HTTPS uniquement
- Cookie `sameSite: lax` → protection CSRF
- Token consommé après acceptation → pas de réutilisation
- Token non exposé en production → `devToken` uniquement en DEV

---

## 📊 Versions Déployées

| Service | Version |
|---------|---------|
| keybuzz-api | 0.1.102-dev |
| keybuzz-client | 0.2.83-dev |

---

## 🚀 Conclusion

Le flux d'invitation est maintenant **100% fonctionnel** :

1. ✅ Token stocké en cookie HTTP-only (survit aux redirections OAuth)
2. ✅ Invitation consommée automatiquement après auth
3. ✅ Tenant invité sélectionné par défaut
4. ✅ Aucune action manuelle requise de l'utilisateur
5. ✅ Plus de page Acme/Tech pour les utilisateurs invités
