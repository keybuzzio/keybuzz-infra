# PH15-BACKEND-DEPLOY-01 — Rapport

**Date** : 7 janvier 2026  
**Objectif** : Déployer keybuzz-backend sur K8s DEV + exposer routes Amazon/Inbound

---

## 📋 RÉSUMÉ EXÉCUTIF

| Élément | Statut |
|---------|--------|
| Docker image keybuzz-backend | ✅ `ghcr.io/keybuzzio/keybuzz-backend:v0.1.0-dev` |
| Namespace K8s | ✅ `keybuzz-backend-dev` |
| Deployment/Service/Ingress | ✅ Déployés |
| Routes Amazon accessibles | ✅ Testées via IP |
| Client mis à jour | ✅ `v0.2.37-dev` |
| DNS backend-dev.keybuzz.io | ⚠️ À créer chez le fournisseur |

---

## 🔧 ACTIONS EFFECTUÉES

### 1. Correction syntaxe amazon.oauth.ts

Fichier corrompu corrigé :
- `generateAmazonOAuthUrl` : signature de fonction réparée
- Import `CompleteAmazonOAuthInput` supprimé (n'existait pas)
- Appels adaptés au nouveau format

### 2. Docker Image

```bash
# Build
docker build -t ghcr.io/keybuzzio/keybuzz-backend:v0.1.0-dev --no-cache .

# Push
docker push ghcr.io/keybuzzio/keybuzz-backend:v0.1.0-dev
```

**Image** : `ghcr.io/keybuzzio/keybuzz-backend:v0.1.0-dev`  
**Digest** : `sha256:97f06783fee4a61cb059c5a03d4958783b50e16ce062a4257b51231bc8a165cd`

### 3. Manifests K8s

Créés dans `keybuzz-infra/k8s/keybuzz-backend-dev/` :
- `namespace.yaml`
- `secret-db.yaml` (connexion keybuzz_backend sur 10.0.0.121)
- `deployment.yaml`
- `service.yaml`
- `ingress.yaml` (host: backend-dev.keybuzz.io)
- `kustomization.yaml`

### 4. Déploiement K8s

```bash
kubectl apply -k k8s/keybuzz-backend-dev/
kubectl rollout status deployment keybuzz-backend -n keybuzz-backend-dev
```

**Pod** : `keybuzz-backend-54d9988dc-z74pd` - Running

### 5. Client mis à jour

- Route OAuth modifiée pour utiliser le bon JWT
- Backend URL : `http://keybuzz-backend.keybuzz-backend-dev.svc.cluster.local:4000`
- Version : `0.2.37-dev`

---

## 🌐 ENDPOINTS DISPONIBLES

### Backend (keybuzz-backend)

| Route | Méthode | Description | Auth |
|-------|---------|-------------|------|
| `/health` | GET | Health check | Non |
| `/api/v1/marketplaces/amazon/status` | GET | Status connexion Amazon | JWT |
| `/api/v1/marketplaces/amazon/oauth/start` | POST | Démarrer OAuth Amazon | JWT |
| `/api/v1/marketplaces/amazon/oauth/callback` | GET | Callback OAuth Amazon | Non |
| `/api/v1/inbound-email/connections` | GET/POST | Gestion connexions inbound | JWT |

### Tests validés

```bash
# Health check
curl -sk https://49.13.42.76/health -H 'Host: backend-dev.keybuzz.io'
# => {"status":"ok","uptime":142.428,"version":"0.1.0","env":"production"}

# Amazon status (avec JWT valide)
curl -sk https://49.13.42.76/api/v1/marketplaces/amazon/status \
  -H 'Host: backend-dev.keybuzz.io' \
  -H 'Authorization: Bearer <JWT>'
# => {"connected":true,"status":"CONNECTED","displayName":"Amazon Seller..."}

# OAuth callback
curl -skL 'https://49.13.42.76/api/v1/marketplaces/amazon/oauth/callback?state=test' \
  -H 'Host: backend-dev.keybuzz.io'
# => Redirect to admin-dev avec erreur "Invalid or expired OAuth state"
```

---

## ⚠️ ACTION REQUISE : DNS

### Record à créer

| Type | Nom | Valeur | TTL |
|------|-----|--------|-----|
| A | backend-dev | 49.13.42.76 | 300 |
| A | backend-dev | 138.199.132.240 | 300 |

**Domaine** : keybuzz.io

### En attendant

Le backend est accessible via :
- IP directe avec header Host : `curl -H 'Host: backend-dev.keybuzz.io' https://49.13.42.76/...`
- DNS interne K8s : `keybuzz-backend.keybuzz-backend-dev.svc.cluster.local:4000`

---

## 📦 VERSIONS DÉPLOYÉES

| Service | Version | Namespace |
|---------|---------|-----------|
| keybuzz-backend | v0.1.0-dev | keybuzz-backend-dev |
| keybuzz-client | v0.2.37-dev | keybuzz-client-dev |

---

## 🔑 JWT CONFIGURATION

Le JWT utilisé par le client doit être signé avec :
- **Secret** : `keybuzz-dev-jwt-secret-2026`
- **Payload** : `{sub, tenantId, role, email}`
- **Expiration** : 30 jours

Token DEV actuel (expire le 7 février 2026) :
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyX2FkbWluX3Rlc3QiLCJ0ZW5hbnRJZCI6InRlbmFudF90ZXN0X2RldiIsInJvbGUiOiJzdXBlcl9hZG1pbiIsImVtYWlsIjoiYWRtaW5Aa2V5YnV6ei5pbyIsImlhdCI6MTc2NzgxMTI0MywiZXhwIjoxNzcwNDAzMjQzfQ.Wy8ixh-mMjFdTHf5mX8w9zzrV8SXkn1ia9seIKoNod8
```

---

## 📁 FICHIERS CRÉÉS/MODIFIÉS

### keybuzz-infra
- `k8s/keybuzz-backend-dev/namespace.yaml`
- `k8s/keybuzz-backend-dev/secret-db.yaml`
- `k8s/keybuzz-backend-dev/deployment.yaml`
- `k8s/keybuzz-backend-dev/service.yaml`
- `k8s/keybuzz-backend-dev/ingress.yaml`
- `k8s/keybuzz-backend-dev/kustomization.yaml`
- `docs/PH15-BACKEND-DEPLOY-01-REPORT.md`

### keybuzz-backend
- `Dockerfile` (amélioré avec Prisma, healthcheck)
- `src/modules/marketplaces/amazon/amazon.oauth.ts` (syntaxe corrigée)
- `src/modules/marketplaces/amazon/amazon.routes.ts` (appels corrigés)

### keybuzz-client
- `app/api/amazon/oauth/start/route.ts` (JWT + backend URL)
- `package.json` (version 0.2.37-dev)

---

## ✅ CHECKLIST

- [x] Docker image backend créée et pushée
- [x] Namespace keybuzz-backend-dev créé
- [x] Deployment, Service, Ingress déployés
- [x] Routes Amazon accessibles via IP
- [x] Client mis à jour pour appeler le backend
- [x] JWT synchronisé entre client et backend
- [ ] DNS backend-dev.keybuzz.io créé
- [ ] Test E2E wizard → OAuth Amazon

---

## 🔜 PROCHAINES ÉTAPES

1. **Créer DNS record** `backend-dev.keybuzz.io` pointant vers `49.13.42.76` et `138.199.132.240`
2. **Test E2E** : Lancer le wizard onboarding, cliquer "Connecter Amazon", vérifier redirection vers Seller Central
3. **Commiter** les changements dans les repos

---

## 📝 COMMITS À EFFECTUER

```bash
# keybuzz-backend
cd /opt/keybuzz/keybuzz-backend
git add -A
git commit -m "fix(PH15): Amazon OAuth syntax + Dockerfile multi-stage"
git push origin main

# keybuzz-client
cd /opt/keybuzz/keybuzz-client
git add -A
git commit -m "feat(PH15): real backend OAuth integration v0.2.37-dev"
git push origin main

# keybuzz-infra
cd /opt/keybuzz/keybuzz-infra
git add -A
git commit -m "feat(PH15): keybuzz-backend K8s deployment + report"
git push origin main
```
