# PH-PROD-FTP-01.1B — FTP Durable via Vault (Aligné KeyBuzz)

**Date :** 2026-02-03  
**Statut :** ✅ **DÉPLOYÉ**  
**Périmètre :** Credentials FTP via Vault KV v2 (même pattern que keybuzz-backend)  
**Environnement :** seller-dev uniquement

---

## 1. Objectif atteint

| Critère | Statut |
|---------|--------|
| POST /api/products/imports → 201 | ✅ |
| Credentials écrits dans Vault KV v2 | ✅ |
| Lecture depuis Vault (browse FTP) | ✅ |
| Pattern aligné keybuzz-backend | ✅ |
| Aucun secret en clair | ✅ |

---

## 2. Architecture (alignée KeyBuzz)

```
┌────────────────┐     ┌─────────────────────────────────┐
│  seller-api    │────▶│  Vault (vault.keybuzz.io:8200)  │
│                │     │  KV v2: secret/data/keybuzz/... │
└────────────────┘     └─────────────────────────────────┘
        │
        │ VAULT_TOKEN injecté via K8S Secret
        │ (même pattern que keybuzz-backend)
        ▼
┌────────────────┐
│ K8S Secret     │
│ vault-token    │
└────────────────┘
```

---

## 3. Path Vault

```
secret/data/keybuzz/tenants/{tenant_id}/ftp/{import_id}
```

**Exemple :**
```
secret/data/keybuzz/tenants/ecomlg-test/ftp/4b2af8bc-72c6-40f9-b663-7186b2f8449e
```

---

## 4. Preuves

### 4.1 Création import (HTTP 201)

```bash
$ curl -X POST /api/products/imports -d '{"name":"Wortmann Produits",...}'
{"id":"4b2af8bc-72c6-40f9-b663-7186b2f8449e",...,"status":"configured"}
```

### 4.2 Write Vault OK

```
Vault: writing FTP credentials path=secret/.../tenants/ecomlg-t...
HTTP Request: POST .../v1/secret/data/keybuzz/tenants/ecomlg-test/ftp/... "HTTP/1.1 200 OK"
Vault: FTP credentials stored successfully
```

### 4.3 Read Vault OK (browse FTP)

```
Vault: reading FTP credentials
HTTP Request: GET .../v1/secret/data/keybuzz/tenants/ecomlg-test/ftp/... "HTTP/1.1 200 OK"
Vault: credentials retrieved host=ftp.wortmann.de
FTP browse (from Vault): ftp.wortmann.de path=/
```

### 4.4 Aucun secret en clair

- Logs : path tronqué, host affiché, **password jamais loggé**
- Code : `password: password  # Jamais loggue`

---

## 5. Différences avec PH-PROD-FTP-01.1

| Élément | PH-PROD-FTP-01.1 (rejeté) | PH-PROD-FTP-01.1B (validé) |
|---------|---------------------------|----------------------------|
| Stockage | K8S Secrets | Vault KV v2 |
| Auth | RBAC K8S | VAULT_TOKEN |
| Pattern | Custom | keybuzz-backend |
| Source de vérité | K8S | Vault |

---

## 6. Configuration déployée

### 6.1 Environment vars

```yaml
VAULT_ADDR: https://vault.keybuzz.io:8200
VAULT_TOKEN: <injecté depuis secret/vault-token>
```

### 6.2 ServiceAccount

```yaml
serviceAccountName: seller-api
# RBAC: seller-api-secrets (pour PushSecrets si besoin futur)
```

---

## 7. Images déployées

| Composant | Version | Digest |
|-----------|---------|--------|
| seller-api | `v2.0.4-ph-prod-ftp-01.1b` | `sha256:ee1232d0...` |

---

## 8. Commits GitOps

| Commit | Message |
|--------|---------|
| `ac9945c` | PH-PROD-FTP-01.1B: FTP via Vault KV v2 (pattern keybuzz-backend) |

---

## 9. Logging sécurisé

```python
# vault_ftp.py
logger.info(f"Vault: writing FTP credentials path={path[:20]}...")  # Tronqué
logger.info(f"Vault: credentials retrieved host={creds['host']}")   # Pas de password
```

---

## 10. Rollback

```bash
kubectl -n keybuzz-seller-dev set image deployment/seller-api \
  seller-api=ghcr.io/keybuzzio/seller-api:v2.0.2-ph-prod-ftp-01.1
```

---

## 11. Test end-to-end

```bash
# 1. Créer import
curl -X POST /api/products/imports \
  -H 'X-Tenant-Id: ecomlg-test' \
  -d '{"name":"Test","ftp":{...},"remote_path":"/test.csv"}'
# → 201 Created

# 2. Browse FTP (lit creds depuis Vault)
curl -X POST /api/products/imports/{id}/ftp/browse \
  -H 'X-Tenant-Id: ecomlg-test' \
  -d '{"path":"/"}'
# → Liste fichiers (ou erreur FTP si creds invalides)

# 3. Logs
kubectl logs deploy/seller-api | grep Vault
# → "Vault: FTP credentials stored successfully"
# → "Vault: credentials retrieved host=..."
```

---

## 12. Conformité

| Règle | Statut |
|-------|--------|
| ❌ K8S Secrets comme stockage primaire | ✅ Non utilisé |
| ❌ Password en DB | ✅ Non stocké |
| ❌ Root token / unseal | ✅ Non utilisé |
| ❌ Contourner Vault | ✅ Vault utilisé |
| ❌ Modèle différent keybuzz-backend | ✅ Même pattern |
