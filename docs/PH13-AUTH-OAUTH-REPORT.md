# PH13-AUTH-OAUTH — Rapport OAuth Login

**Date:** 2026-01-06  
**Environnement:** DEV uniquement  
**Version déployée:** v0.2.25-dev

---

## 1. Résumé

Implémentation de l'authentification OAuth réelle dans le Client UI :
- ✅ NextAuth.js configuré (Google + Microsoft/Azure AD)
- ✅ Middleware de protection des routes
- ✅ Page de connexion stylisée KeyBuzz
- ✅ Composant UserMenu (affichage user + logout)
- ✅ Hook `useTenantId` centralisé

---

## 2. Fichiers Créés

### Client UI (`keybuzz-client`)

| Fichier | Description |
|---------|-------------|
| `app/api/auth/[...nextauth]/route.ts` | Handler NextAuth |
| `app/api/auth/config/route.ts` | Endpoint de vérification providers |
| `app/auth/signin/page.tsx` | Page de connexion |
| `app/auth/error/page.tsx` | Page d'erreur auth |
| `middleware.ts` | Protection routes + redirect |
| `src/components/auth/AuthProvider.tsx` | Provider NextAuth |
| `src/components/auth/UserMenu.tsx` | Menu utilisateur |
| `src/features/tenant/useTenantId.ts` | Hook tenantId centralisé |
| `src/types/next-auth.d.ts` | Types étendus NextAuth |

### Infra (`keybuzz-infra`)

| Fichier | Description |
|---------|-------------|
| `k8s/keybuzz-client-dev/auth-secret.template.yaml` | Template secret (sans valeurs) |
| `k8s/keybuzz-client-dev/deployment.yaml` | Mis à jour avec env vars |

---

## 3. Routes

### Routes Publiques (sans auth)
- `/pricing`
- `/auth/*`
- `/api/auth/*`
- `/debug/version`
- `/login`, `/logout` (legacy)

### Routes Protégées (redirect → /auth/signin)
- Toutes les autres routes (`/inbox`, `/orders`, `/billing`, etc.)

---

## 4. Variables d'Environnement Requises

```yaml
# Core
NEXTAUTH_URL: https://client-dev.keybuzz.io
NEXTAUTH_SECRET: <openssl rand -base64 32>

# Google OAuth
GOOGLE_CLIENT_ID: <from Google Cloud Console>
GOOGLE_CLIENT_SECRET: <from Google Cloud Console>

# Microsoft Azure AD
AZURE_AD_CLIENT_ID: <from Azure Portal>
AZURE_AD_CLIENT_SECRET: <from Azure Portal>
AZURE_AD_TENANT_ID: common  # ou tenant spécifique
```

**Note:** Ces secrets doivent être créés dans un K8s Secret `keybuzz-auth` dans le namespace `keybuzz-client-dev`.

---

## 5. Tests E2E

| Test | Attendu | Résultat |
|------|---------|----------|
| GET /debug/version | 200 + v0.2.25-dev | ✅ |
| GET /api/auth/config | configured=false | ✅ (pas de secrets) |
| GET /pricing | 200 (public) | ✅ |
| GET /orders | 307 → /auth/signin | ✅ |
| GET /inbox | 307 → /auth/signin | ✅ |
| GET /billing | 307 → /auth/signin | ✅ |

---

## 6. Comportement Auth Non Configurée

Quand les secrets OAuth ne sont pas présents :
1. `/api/auth/config` retourne `configured: false`
2. La page `/auth/signin` affiche un warning clair
3. Les boutons de connexion ne sont pas affichés
4. Message : "Auth non configurée - Contactez l'administrateur"

---

## 7. TODO : PH13-TENANT-CONTEXT

Le tenantId est actuellement hardcodé `kbz-001` dans :
- `app/api/auth/[...nextauth]/route.ts` (session callback)
- `src/features/tenant/useTenantId.ts` (fallback)

La phase PH13-TENANT-CONTEXT implémentera :
- Association user → tenant en DB
- Multi-tenant selection
- tenantId dynamique dans session

---

## 8. Commits

| Repo | SHA | Message |
|------|-----|---------|
| keybuzz-client | f960763 | feat(PH13): OAuth login (Google+Microsoft) + route protection |
| keybuzz-infra | a148064 | chore(PH13): client auth secret template + env wiring v0.2.25-dev |

---

## 9. Image Docker

```
ghcr.io/keybuzzio/keybuzz-client:v0.2.25-dev
Digest: sha256:43aa89ae23fef61bd846446e99202e2ea3e9e71703a34a1421ba14b4c84469d6
```

---

## 10. Prochaines Étapes

1. **Configurer OAuth providers** :
   - Google: https://console.cloud.google.com/apis/credentials
   - Microsoft: https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps

2. **Créer le secret K8s** :
   ```bash
   cp auth-secret.template.yaml auth-secret.yaml
   # Remplir les valeurs
   kubectl apply -f auth-secret.yaml
   kubectl -n keybuzz-client-dev rollout restart deployment/keybuzz-client
   ```

3. **PH13-TENANT-CONTEXT** : tenantId dynamique

---

**Fin du rapport PH13-AUTH-OAUTH**
