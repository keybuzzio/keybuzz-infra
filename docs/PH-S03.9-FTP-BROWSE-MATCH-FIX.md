# PH-S03.9 — FTP Browse Match Fix

**Date :** 2026-02-02  
**Statut :** ✅ **DÉPLOYÉ** (action utilisateur requise)  
**Périmètre :** Fix browse FTP retournant mauvais listing  
**Environnement :** seller-dev uniquement

---

## 1. Problème identifié

### 1.1 Symptôme

- Browse "/" dans seller affiche des dossiers génériques allemands (Achtung/FTP-client/…)
- FileZilla avec les mêmes credentials montre: Preisliste, Produktbilder
- Le listing ne correspond pas

### 1.2 Cause racine

**La fonction `get_ftp_password()` avait un TODO non implémenté:**

```python
async def get_ftp_password(secret_ref_id, temp_password=None):
    if temp_password:
        return temp_password
    
    if secret_ref_id:
        # TODO: vault.read(ref["vaultPath"])["password"]
        pass  # <-- NE FAIT RIEN!
    
    return None  # <-- RETOURNE TOUJOURS NULL!
```

**Conséquence :**
- Sans `temp_password` fourni en query param, le password était `None`
- La connexion FTP se faisait en mode **anonyme**
- Le serveur FTP Wortmann renvoyait le listing anonyme (dossiers allemands génériques)
- FileZilla utilisait les vrais credentials → listing correct

---

## 2. Solution implémentée

### 2.1 Nouvelle colonne DB (DEV only)

```sql
ALTER TABLE seller.catalog_source_connections 
ADD COLUMN password_encrypted TEXT DEFAULT NULL;
```

**Note :** En DEV, le password est stocké en base64 (pas sécurisé). En PROD, utiliser Vault.

### 2.2 Stockage du password (create/update)

```python
# Dans create_ftp_connection et update_ftp_connection
if data.password:
    password_encrypted = base64.b64encode(data.password.encode('utf-8')).decode('utf-8')
    # Stocké en DB
```

### 2.3 Récupération du password (browse/test)

```python
async def get_ftp_password(secret_ref_id, temp_password=None, source_id=None, tenant_id=None):
    # 1. Priorité au temp_password (test rapide)
    if temp_password:
        return temp_password
    
    # 2. Récupérer depuis DB (DEV mode)
    if source_id and tenant_id:
        row = await conn.fetchrow("""
            SELECT password_encrypted FROM seller.catalog_source_connections
            WHERE source_id = $1 AND tenant_id = $2
        """, source_id, tenant_id)
        if row and row["password_encrypted"]:
            return base64.b64decode(row["password_encrypted"]).decode('utf-8')
    
    # 3. TODO: Vault pour PROD
    return None
```

---

## 3. Images déployées

| Composant | Version | Digest |
|-----------|---------|--------|
| seller-api | `v1.0.7-ph-s03.9-ftp-pwd` | `sha256:67ea29eedbed5065a3585aa74e0e2e5323e51e21633eabffe325dd8f664f2a5f` |

---

## 4. Action utilisateur requise

**Les connexions FTP existantes n'ont pas de password stocké.**

Pour que le browse fonctionne correctement :

1. Ouvrir la source FTP dans seller-dev
2. Onglet "Connexion FTP"
3. Re-saisir le password
4. Cliquer "Enregistrer"
5. Le password sera stocké (base64)
6. Cliquer "Parcourir les fichiers"
7. **Attendu :** Listing correct (Preisliste, Produktbilder)

---

## 5. Sécurité (DEV vs PROD)

### DEV (actuel)

- Password stocké en base64 dans `password_encrypted`
- **NON SÉCURISÉ** - acceptable uniquement pour DEV
- Logs indiquent "DEV mode, base64"

### PROD (à implémenter)

- Password stocké dans Vault via `secret_ref_id`
- Jamais de password en DB
- `get_ftp_password()` doit appeler Vault API

---

## 6. Flow corrigé

```
1. Utilisateur configure FTP (host, port, user, password)
2. Clic "Enregistrer"
3. POST /ftp/connection → password encodé base64 → DB
4. Clic "Parcourir les fichiers"
5. GET /ftp/browse?path=/
6. get_ftp_password() → récupère password depuis DB
7. connect_ftp() avec vrais credentials
8. Listing FTP correct (Preisliste, Produktbilder)
```

---

## 7. Vérification

### Logs attendus

```
INFO: FTP password: using stored password (DEV mode)
INFO: GET /ftp/browse - source_id=xxx, tenant_id=yyy
```

### DB preuve

```sql
SELECT source_id, host, username, 
       CASE WHEN password_encrypted IS NOT NULL THEN 'SET' ELSE 'NULL' END as pwd
FROM seller.catalog_source_connections;
```

---

## 8. Rollback

```bash
# Rollback seller-api
kubectl -n keybuzz-seller-dev set image deployment/seller-api \
  seller-api=ghcr.io/keybuzzio/seller-api:v1.0.6-ph-s03.8b-log

# Supprimer colonne (optionnel)
PGPASSWORD=... psql -h 10.0.0.10 -U keybuzz_api_dev -d keybuzz \
  -c "ALTER TABLE seller.catalog_source_connections DROP COLUMN IF EXISTS password_encrypted;"
```

---

## 9. TODO pour PROD

- [ ] Implémenter `get_ftp_password()` avec appel Vault API
- [ ] Supprimer stockage base64 en DB
- [ ] Migration des passwords existants vers Vault
- [ ] Audit sécurité avant mise en PROD
