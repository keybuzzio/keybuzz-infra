# PH15-BACKEND-AUTH-FIX-01 — Rapport

**Date** : 7 janvier 2026  
**Objectif** : Corriger auth backend-dev + status Amazon réel + supprimer JWT DEV

---

## 📋 RÉSUMÉ EXÉCUTIF

| Élément | Statut |
|---------|--------|
| Analyse status CONNECTED | ✅ Identifié (données seeded en DB) |
| Code middleware X-User-Email | ✅ Créé |
| Build backend avec middleware | ⛔ Bloqué (schema Prisma corrompu) |
| Client sans JWT hardcodé | ✅ Code créé |
| Déploiement | ⚠️ Rollback v0.1.0-dev |

---

## 🔍 ANALYSE : Pourquoi status=CONNECTED ?

### Données seeded en DB

```sql
SELECT id, "tenantId", type, status, "displayName" 
FROM "MarketplaceConnection";

-- Résultat:
             id             |    tenantId     |  type  |  status   
----------------------------+-----------------+--------+-----------
 mpc_amazon_tenant_test_dev | tenant_test_dev | AMAZON | CONNECTED 
 cmjecdiqj0000p0fvgljq171d  | kbz_test        | AMAZON | CONNECTED 
```

**Cause** : Ces entrées ont été créées lors de tests précédents et ont le status `CONNECTED`.

### Comportement attendu

La route `/api/v1/marketplaces/amazon/status` lit la DB :
- Si connexion existe → retourne son status
- Si pas de connexion → retourne 404 avec `connected: false`

Un tenant sans entrée en DB aura bien `DISCONNECTED`.

---

## 🔧 CODE CRÉÉ (non déployé)

### 1. Middleware DEV Auth (`src/lib/authDevMiddleware.ts`)

Support double authentification :
- JWT Bearer token (production)
- X-User-Email header (DEV bridge)

```typescript
export async function devAuthMiddleware(request, reply) {
  // 1. Try JWT first
  if (authHeader?.startsWith("Bearer ")) {
    await request.jwtVerify();
    return;
  }
  
  // 2. DEV mode: X-User-Email header
  if (DEV_MODE) {
    const email = request.headers["x-user-email"];
    const tenantId = request.headers["x-tenant-id"];
    // Lookup user in DB, set request.user
  }
}
```

### 2. Client OAuth sans JWT hardcodé

Route `app/api/amazon/oauth/start/route.ts` modifiée pour :
- Utiliser session NextAuth
- Envoyer `X-User-Email` et `X-Tenant-Id` au backend

---

## ⛔ BLOCAGE : Schema Prisma corrompu

Le build du backend échoue avec :

```
error: Error validating model "OAuthState": 
  - tenantId defined twice
  - expiresAt missing
  - type missing in ExternalMessage
  
Validation Error Count: 19
```

**Cause probable** : Modifications multiples non synchronisées entre le repo local et le repo distant.

**Solution requise** :
1. Auditer et corriger `prisma/schema.prisma`
2. Valider avec `npx prisma validate`
3. Synchroniser avec la DB

---

## 📦 VERSIONS ACTUELLES

| Service | Version | Notes |
|---------|---------|-------|
| keybuzz-backend | v0.1.0-dev | Version stable, sans X-User-Email |
| keybuzz-client | v0.2.38-dev | Code X-User-Email (ne fonctionne pas avec backend actuel) |

---

## ✅ CE QUI FONCTIONNE

1. **Backend v0.1.0-dev** : 
   - Routes Amazon accessibles avec JWT valide
   - Status lit la DB correctement
   - Callback OAuth fonctionne

2. **Routes API** :
   - `/health` → OK
   - `/api/v1/marketplaces/amazon/status` → Lit DB
   - `/api/v1/marketplaces/amazon/oauth/start` → Crée state et redirige
   - `/api/v1/marketplaces/amazon/oauth/callback` → Gère retour Amazon

---

## 🔜 ACTIONS REQUISES

### Priorité 1 : Corriger schema Prisma

1. Récupérer le schema valide depuis une migration ou snapshot
2. Corriger les duplications et champs manquants
3. Valider avec `npx prisma validate`
4. Commit et push

### Priorité 2 : Déployer middleware auth

Une fois le schema corrigé :
1. Ajouter `src/lib/authDevMiddleware.ts`
2. Configurer hook dans `main.ts`
3. Build et deploy

### Priorité 3 : Rollback client

Le client v0.2.38-dev utilise X-User-Email qui n'est pas supporté par le backend actuel.

Option A : Rollback client à v0.2.37-dev
Option B : Attendre déploiement backend avec middleware

---

## 📝 COMMITS EFFECTUÉS

```
keybuzz-client: feat(PH15): OAuth route with session-based auth v0.2.38-dev
```

---

## 🚫 TOKENS

Conformément aux règles, **aucun token n'est inclus dans ce rapport**.

Pour générer un token de test :
```bash
cd /opt/keybuzz/keybuzz-backend
node -e "const jwt=require('jsonwebtoken'); console.log(jwt.sign({...}, process.env.JWT_SECRET));"
```

---

## 📊 CONCLUSION

L'objectif de supprimer les JWT hardcodés est partiellement atteint :
- ✅ Code middleware créé
- ✅ Code client mis à jour
- ⛔ Déploiement bloqué par schema Prisma corrompu

**Prochaine étape** : Corriger le schema Prisma dans un prompt dédié.
