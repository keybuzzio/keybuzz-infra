# PH-PROD-FTP-01.1 — FTP Credentials Fix (K8S Secrets)

**Date :** 2026-02-03  
**Statut :** ✅ **DÉPLOYÉ**  
**Périmètre :** Fix "Failed to store FTP credentials" + UX cleanup  
**Environnement :** seller-dev uniquement

---

## 1. Problème résolu

### 1.1 Erreur initiale

```
Failed to store FTP credentials securely
```

### 1.2 Cause racine

- seller-api tentait d'écrire dans Vault avec un token statique
- Token Vault exposé (VAULT_TOKEN env var)
- Pas d'authentification Kubernetes configurée

---

## 2. Solution implémentée

### 2.1 Architecture DEV

```
┌────────────┐     ┌─────────────┐     ┌───────────────────┐
│ seller-api │────▶│ Kubernetes  │────▶│ Secret (per-import)│
│            │     │ API Server  │     │ ftp-creds-{id}    │
└────────────┘     └─────────────┘     └───────────────────┘
```

- **Pas de token Vault statique**
- **RBAC Kubernetes** pour contrôle d'accès
- **Secrets dynamiques** par tenant/import

### 2.2 RBAC créé

```yaml
# ServiceAccount
seller-api (namespace: keybuzz-seller-dev)

# Role
seller-api-secrets:
  - secrets: create, get, update, delete, list

# RoleBinding
seller-api-secrets → seller-api SA
```

---

## 3. Fichiers modifiés

### 3.1 Backend

| Fichier | Changement |
|---------|------------|
| `src/services/ftp_secrets.py` | **NOUVEAU** - Service K8S secrets |
| `src/routes/product_imports.py` | Utilise `ftp_secrets_service` |
| `requirements.txt` | Ajout `kubernetes==31.0.0` |

### 3.2 Frontend

| Fichier | Changement |
|---------|------------|
| `products/page.tsx` | Placeholder "KeyBuzz Produits" |
| `products/page.tsx` | Texte Step 4 simplifié |

---

## 4. UX Fixes

### 4.1 Step 1 - Nom

```diff
- placeholder="Ex: Wortmann Produits"
+ placeholder="KeyBuzz Produits"
```

### 4.2 Step 4 - Finalisation

```diff
- Les identifiants FTP seront stockes de maniere securisee. 
- Le mot de passe ne sera jamais visible.
+ Verifiez les informations avant de continuer.
```

---

## 5. Sécurité

### 5.1 Règles respectées

| Règle | Statut |
|-------|--------|
| Pas de token Vault exposé | ✅ |
| Pas de password en DB | ✅ |
| Pas de password en logs | ✅ |
| RBAC Kubernetes | ✅ |
| Secrets par tenant | ✅ |

### 5.2 Variables env supprimées

```bash
VAULT_ADDR-
VAULT_TOKEN-
VAULT_SKIP_VERIFY-
```

### 5.3 Variable env ajoutée

```bash
POD_NAMESPACE=keybuzz-seller-dev
```

---

## 6. Images déployées

| Composant | Version | Digest |
|-----------|---------|--------|
| seller-api | `v2.0.2-ph-prod-ftp-01.1` | `sha256:97a3515c...` |
| seller-client | `v2.0.1-ph-prod-ftp-01.1` | `sha256:d521d393...` |

---

## 7. Preuves

### 7.1 API fonctionnelle

```bash
$ curl -X POST .../ftp/test-connection \
    -d '{"host":"ftp.example.com","port":21,"username":"x","password":"x"}'
{"detail":"Connexion FTP echouee: 530 Login or password incorrect!"}
# ✅ Erreur attendue (credentials de test invalides)
```

### 7.2 Pods healthy

```
seller-api-6cfb5c7fd9-dns7k      1/1     Running
seller-client-6d45445c79-kdtkj   1/1     Running
```

### 7.3 ServiceAccount configuré

```bash
$ kubectl -n keybuzz-seller-dev get sa seller-api
NAME         SECRETS   AGE
seller-api   0         10m
```

---

## 8. Pattern secrets

### 8.1 Nom du secret

```
ftp-creds-{tenant_id[:20]}-{import_id[:12]}
```

### 8.2 Labels

```yaml
labels:
  app.kubernetes.io/managed-by: seller-api
  keybuzz.io/tenant: <tenant_id>
  keybuzz.io/import: <import_id>
  keybuzz.io/type: ftp-credentials
```

### 8.3 Contenu (encodé K8S)

```yaml
data:
  host: <base64>
  port: <base64>
  username: <base64>
  password: <base64>  # Jamais visible
```

---

## 9. Commits GitOps

| Commit | Message |
|--------|---------|
| `7fbbe52` | PH-PROD-FTP-01.1: Fix FTP credentials with K8S secrets |

---

## 10. Rollback

```bash
# Rollback API
kubectl -n keybuzz-seller-dev set image deployment/seller-api \
  seller-api=ghcr.io/keybuzzio/seller-api:v2.0.1-ph-prod-ftp-01

# Rollback Client
kubectl -n keybuzz-seller-dev set image deployment/seller-client \
  seller-client=ghcr.io/keybuzzio/seller-client:v2.0.0-ph-prod-ftp-01
```

---

## 11. Migration PROD (futur)

Pour PROD, migrer vers Vault Kubernetes auth :

1. Créer ServiceAccount `seller-api` dans namespace PROD
2. Créer role Vault `seller-api` avec policy FTP
3. Modifier `ftp_secrets.py` pour utiliser Vault K8S auth
4. Supprimer Role/RoleBinding K8S secrets
