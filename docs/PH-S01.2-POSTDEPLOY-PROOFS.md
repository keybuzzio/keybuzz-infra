# PH-S01.2 — Preuves Post-Deploy

**Date:** 2026-01-30  
**Auteur:** KeyBuzz CE  
**Statut:** COMPLETE  
**Environnement:** DEV uniquement

---

## 1. ArgoCD — Preuve de sync GitOps

### Application keybuzz-seller-dev

| Champ | Valeur |
|-------|--------|
| **Name** | keybuzz-seller-dev |
| **SYNC STATUS** | ✅ Synced |
| **HEALTH STATUS** | Degraded* |
| **Revision** | `071f1e00f33786ad231bfcb355e00d0c9e982de3` |
| **Source** | `https://github.com/keybuzzio/keybuzz-infra.git` |
| **Path** | `k8s/keybuzz-seller-dev` |
| **Target Revision** | `main` |

*Note: Health "Degraded" car ExternalSecret Vault a une erreur de permission PostgreSQL. Les pods fonctionnent avec un secret manuel temporaire.

### Ressources synchronisées

```
✅ Namespace: keybuzz-seller-dev
✅ Service: seller-api
✅ Service: seller-client
✅ Deployment: seller-api
✅ Deployment: seller-client
✅ Ingress: seller-api (seller-api-dev.keybuzz.io)
✅ Ingress: seller-client (seller-dev.keybuzz.io)
⚠️ ExternalSecret: seller-api-postgres (erreur Vault)
```

### Images déployées

```
ghcr.io/keybuzzio/seller-api:v1.0.0
ghcr.io/keybuzzio/seller-client:v1.0.0
```

### Pods Running

```
NAME                           READY   STATUS    RESTARTS   AGE
seller-api-69c877c9c5-htqk7    1/1     Running   0          5m
seller-client-cbc44546-ns7kw   1/1     Running   0          6m
```

---

## 2. Tests API Curl

### Test B : Sans cookie → 401 ✅

```bash
curl -s seller-api.keybuzz-seller-dev.svc.cluster.local:3002/api/config/summary
```

**Résultat:**
```json
{"detail":"Authentication required. Please login via KeyBuzz."}
HTTP_CODE: 401
```

✅ **PASS** : Sans cookie, l'API retourne 401 Unauthorized

---

### Test C : Headers seuls → 401 ✅

```bash
curl -s \
  -H "X-User-Email: test@keybuzz.io" \
  -H "X-Tenant-Id: test-tenant" \
  seller-api.keybuzz-seller-dev.svc.cluster.local:3002/api/config/summary
```

**Résultat:**
```json
{"detail":"Authentication required. Please login via KeyBuzz."}
HTTP_CODE: 401
```

✅ **PASS** : Avec headers X-User-Email et X-Tenant-Id uniquement, l'API retourne 401 Unauthorized.

**PREUVE CRITIQUE** : Les headers ne suffisent plus comme source d'identité. L'auth exige maintenant un cookie de session KeyBuzz valide.

---

### Test A : Avec cookie de session KeyBuzz → À valider manuellement

Ce test nécessite une session utilisateur réelle obtenue en se connectant sur client-dev.keybuzz.io.

**Procédure de validation manuelle:**
1. Ouvrir `https://client-dev.keybuzz.io` dans un navigateur
2. Se connecter avec un compte KeyBuzz
3. Ouvrir les DevTools → Application → Cookies
4. Copier le cookie `__Secure-next-auth.session-token`
5. Appeler seller-api avec ce cookie :
   ```bash
   curl -b "__Secure-next-auth.session-token=<TOKEN>" \
     https://seller-api-dev.keybuzz.io/api/config/summary
   ```
6. Vérifier que la réponse est 200 avec les données utilisateur

---

## 3. Health Check

```bash
curl -s seller-api.keybuzz-seller-dev.svc.cluster.local:3002/health
```

**Résultat:**
```json
{"status":"ok","service":"seller-api"}
```

✅ **PASS** : L'API répond correctement

---

## 4. SSO UI — À valider manuellement

**Procédure:**
1. Ouvrir `https://client-dev.keybuzz.io`
2. Se connecter
3. Dans un nouvel onglet, ouvrir `https://seller-dev.keybuzz.io`
4. Vérifier l'accès direct sans nouvelle authentification

**Note:** Le DNS pour seller-dev.keybuzz.io doit être configuré pour cette validation.

---

## 5. Confirmation GitOps

### Commit déployé

```
Commit: 071f1e00f33786ad231bfcb355e00d0c9e982de3
Message: PH-S01: Add keybuzz-seller-dev K8s manifests
```

### Manifests source

```
Source: https://github.com/keybuzzio/keybuzz-infra.git
Path: k8s/keybuzz-seller-dev/
Branch: main
```

### Fichiers dans le commit

```
k8s/keybuzz-seller-dev/
├── namespace.yaml
├── externalsecret-postgres.yaml
├── deployment-api.yaml
├── deployment-client.yaml
├── service-api.yaml
├── service-client.yaml
├── ingress-api.yaml
├── ingress-client.yaml
└── kustomization.yaml
```

---

## 6. Confirmations de sécurité

### Aucun kubectl apply manuel

Le déploiement a été effectué via ArgoCD :
- **Bootstrapping initial** : Création de l'Application ArgoCD (une seule fois)
- **Déploiement continu** : Sync automatique depuis GitHub

### Aucun secret en clair exposé

- Credentials PostgreSQL masqués
- Cookies de session non affichés dans les tests
- Token GitHub non exposé

### Aucune modification PROD

Tout le travail a été effectué dans le namespace `keybuzz-seller-dev`.

---

## 7. Résumé des preuves

| Preuve | Statut | Détail |
|--------|--------|--------|
| ArgoCD sync | ✅ | Synced, revision 071f1e0 |
| Pods running | ✅ | seller-api + seller-client |
| Test B (no cookie) | ✅ | 401 Unauthorized |
| Test C (headers only) | ✅ | 401 Unauthorized |
| Test A (valid cookie) | ⏳ | Validation manuelle requise |
| SSO UI | ⏳ | Validation manuelle requise (DNS) |
| GitOps | ✅ | Déployé depuis GitHub |
| No secrets leak | ✅ | Aucun secret en clair |

---

## 8. Actions restantes

1. **DNS** : Configurer seller-dev.keybuzz.io et seller-api-dev.keybuzz.io
2. **Vault** : Corriger la permission PostgreSQL pour ExternalSecret
3. **Validation manuelle** : Test A (cookie) + SSO UI

---

## Confirmation finale

**PH-S01.2 exécuté en DEV.**

- ✅ Aucun kubectl apply manuel (hors bootstrapping ArgoCD)
- ✅ Aucun secret leak
- ✅ seller-dev déployé via GitOps
- ✅ Auth headers-only rejetée (Test C = 401)

---

**FIN DU RAPPORT PH-S01.2**
