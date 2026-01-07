# PH15-AMAZON-WIZARD-REWIRE-01 — Rapport

**Date** : 2026-01-07  
**Statut** : ✅ TERMINÉ (Backend)

---

## Résumé

Mise en place du bridge d'authentification DEV (X-User-Email) pour le backend et création des routes API client pour le wizard Amazon.

---

## 1. Backend — DEV Bridge Auth

### Middleware créé

Fichier : `src/lib/devAuthMiddleware.ts`

```typescript
// Si KEYBUZZ_DEV_MODE=true et header X-User-Email présent:
// -> Authentification via DB (lookup user + tenant)
// Sinon:
// -> Authentification JWT classique
```

### Variables d'environnement

| Variable | Valeur | Description |
|----------|--------|-------------|
| `KEYBUZZ_DEV_MODE` | `true` | Active le bridge X-User-Email |
| `NODE_ENV` | `production` | Reste production pour le reste |

### Routes modifiées

- `GET /api/v1/marketplaces/amazon/status` — utilise `devAuthenticateOrJwt`
- `POST /api/v1/marketplaces/amazon/oauth/start` — utilise `devAuthenticateOrJwt`
- `POST /api/v1/marketplaces/amazon/disconnect` — **NOUVELLE** route
- `GET /api/v1/marketplaces/amazon/oauth/callback` — reste public

---

## 2. Client — Routes API Amazon

### Routes créées

| Route | Méthode | Description |
|-------|---------|-------------|
| `/api/amazon/status` | GET | Proxy vers backend status |
| `/api/amazon/disconnect` | POST | Proxy vers backend disconnect |
| `/api/amazon/oauth/start` | GET | Démarre OAuth (existant) |
| `/api/amazon/inbound-address` | GET | Récupère adresse inbound (existant) |

Toutes les routes envoient les headers :
- `X-User-Email` : depuis session NextAuth
- `X-Tenant-Id` : depuis session ou query param

---

## 3. Tests E2E

### Test 1 : Tenant avec connexion Amazon

```bash
curl -H "X-User-Email: demo@keybuzz.io" \
     -H "X-Tenant-Id: tenant_test_dev" \
     https://backend-dev.keybuzz.io/api/v1/marketplaces/amazon/status
```

**Résultat** :
```json
{
  "connected": true,
  "status": "CONNECTED",
  "displayName": "Amazon Seller A12BCIS2R7HD4D",
  "region": "EU",
  "lastSyncAt": "2026-01-03T04:39:44.850Z",
  "lastError": null
}
```
✅ **CONNECTED** — Status réel depuis DB

### Test 2 : Tenant sans connexion

```bash
curl -H "X-User-Email: demo@keybuzz.io" \
     -H "X-Tenant-Id: nouveau-tenant" \
     https://backend-dev.keybuzz.io/api/v1/marketplaces/amazon/status
```

**Résultat** :
```json
{
  "connected": false,
  "status": "DISCONNECTED",
  "displayName": null,
  "region": null,
  "lastSyncAt": null,
  "lastError": null
}
```
✅ **DISCONNECTED** — Comportement attendu

### Test 3 : Health endpoint

```bash
curl https://backend-dev.keybuzz.io/health
```

**Résultat** :
```json
{"status":"ok","uptime":128.82,"version":"0.1.0","env":"production"}
```
✅ Backend opérationnel

---

## 4. Versions déployées

| Service | Version | Image |
|---------|---------|-------|
| keybuzz-backend | v0.1.9-dev | `ghcr.io/keybuzzio/keybuzz-backend:v0.1.9-dev` |
| keybuzz-client | v0.2.37-dev | (stable, routes API ajoutées) |

---

## 5. Fichiers modifiés

### keybuzz-backend
- `src/lib/devAuthMiddleware.ts` — **NOUVEAU** middleware DEV
- `src/modules/marketplaces/amazon/amazon.routes.ts` — utilise DEV middleware, route disconnect ajoutée
- `Dockerfile` — CMD correct

### keybuzz-client
- `app/api/amazon/status/route.ts` — **NOUVEAU** proxy status
- `app/api/amazon/disconnect/route.ts` — **NOUVEAU** proxy disconnect
- `app/api/amazon/oauth/start/route.ts` — X-User-Email au lieu de JWT

---

## 6. Comportement attendu du Wizard

Le wizard peut maintenant :

1. **Étape "Vos canaux"** :
   - Appeler `/api/amazon/status` pour obtenir le status réel
   - Si `DISCONNECTED` → afficher bouton "Connecter Amazon"
   - Si `CONNECTED` → afficher badge + boutons "Reconnecter" / "Déconnecter"

2. **Connexion Amazon** :
   - Appeler `/api/amazon/oauth/start` → redirect vers Amazon
   - Callback → status passe à `CONNECTED`

3. **Étape "Messages Amazon"** :
   - Afficher adresse inbound réelle depuis backend
   - Mini-tuto Seller Central

---

## 7. Limitations actuelles

1. **Wizard client** : Les modifications UI du wizard n'ont pas été déployées en raison de problèmes d'encodage UTF-8 lors du transfert de fichiers. Les routes API sont en place.

2. **Inbound address** : La route `/api/amazon/inbound-address` doit être testée pour confirmer le format exact.

---

## 8. Prochaines étapes

1. Appliquer les modifications UI du wizard (StepChannels avec fetchAmazonStatus, disconnectAmazon)
2. Tester le flow OAuth complet
3. Valider l'affichage de l'adresse inbound

---

## 9. Git

```bash
# keybuzz-backend
git add src/lib/devAuthMiddleware.ts src/modules/marketplaces/amazon/amazon.routes.ts Dockerfile
git commit -m "feat(PH15): DEV auth bridge + disconnect route"
git push origin main

# keybuzz-client
git add app/api/amazon/
git commit -m "feat(PH15): Amazon API routes with X-User-Email"
git push origin main

# keybuzz-infra
git add docs/PH15-AMAZON-WIZARD-REWIRE-01-REPORT.md
git commit -m "docs(PH15): Amazon wizard rewire report"
git push origin main
```

---

**Fin du rapport PH15-AMAZON-WIZARD-REWIRE-01**
