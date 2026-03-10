# PH-S03.9R — Rollback Password Storage

**Date :** 2026-02-02  
**Statut :** ✅ **DÉPLOYÉ**  
**Périmètre :** Suppression stockage password en DB  
**Environnement :** seller-dev uniquement

---

## 1. Violation corrigée

### 1.1 Problème

PH-S03.9 avait introduit un stockage du password FTP en base64 dans la colonne `password_encrypted`.

**C'était une violation :** aucun mot de passe ne doit être stocké en DB, même en DEV.

### 1.2 Ce qui a été supprimé

- Colonne `password_encrypted` inutilisée (reste en DB mais jamais écrite/lue)
- Code de lecture du password depuis DB dans `get_ftp_password()`
- Code d'écriture du password dans `create_ftp_connection()` et `update_ftp_connection()`
- Import `base64` dans les routes FTP

---

## 2. Nouvelle architecture FTP

### 2.1 Modes d'authentification

| Mode | Utilisation | Stockage |
|------|-------------|----------|
| `temp_password` | Test/browse ponctuel | Jamais stocké |
| `vault_secret_ref` | Connexion durable | Vault uniquement |

### 2.2 Flow browse/test

```
1. UI envoie password dans query param (?password=xxx)
2. API get_ftp_password(secret_ref_id, temp_password)
3. Si temp_password fourni → utilise directement
4. Si secret_ref_id fourni → TODO: récupère depuis Vault
5. Si aucun → erreur 400 explicite
6. Connexion FTP avec vrais credentials
7. Listing retourné
```

### 2.3 Interdiction du mode anonyme

```python
# PH-S03.9R: Interdire le browse anonyme
if not ftp_password:
    raise HTTPException(
        status_code=400, 
        detail="FTP password missing. Provide password query param or configure secret_ref_id."
    )
```

---

## 3. Code modifié

### 3.1 `get_ftp_password()` (simplifié)

```python
async def get_ftp_password(secret_ref_id: Optional[str], temp_password: Optional[str] = None) -> Optional[str]:
    """
    PH-S03.9R: JAMAIS de password stocke en DB.
    """
    # Mode 1: temp_password (test rapide)
    if temp_password:
        return temp_password
    
    # Mode 2: Vault via secret_ref_id (TODO)
    if secret_ref_id:
        # TODO: return await vault_client.read_secret(secret_ref_id, "password")
        return None
    
    return None
```

### 3.2 `create_ftp_connection()` (sans password)

```python
row = await conn.fetchrow("""
    INSERT INTO seller.catalog_source_connections (
        id, tenant_id, source_id, protocol, host, port, username, secret_ref_id
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    RETURNING *
""", ...)
```

### 3.3 Checks dans browse/test

```python
ftp_password = await get_ftp_password(config.get("secret_ref_id"), password)

# PH-S03.9R: Interdire le browse anonyme
if not ftp_password:
    raise HTTPException(
        status_code=400, 
        detail="FTP password missing. Provide password query param or configure secret_ref_id."
    )
```

---

## 4. Images déployées

| Composant | Version | Digest |
|-----------|---------|--------|
| seller-api | `v1.0.8-ph-s03.9r-no-pwd` | `sha256:434599627b0a0bf9de926c4916b336f22d78587bded02471b9115be417c7e273` |

---

## 5. Commits GitOps

| Commit | Message |
|--------|---------|
| `cc55ef0` | PH-S03.9R: Rollback password storage - temp_password only |

---

## 6. Vérification

### 6.1 Preuve: pas de password_encrypted dans le code

```bash
grep -n 'password_encrypted' /opt/keybuzz/keybuzz-seller/seller-api/src/routes/ftp.py
# (aucun résultat)
```

### 6.2 Preuve: erreur 400 si pas de password

```bash
curl -X GET "https://seller-dev.keybuzz.io/api/catalog-sources/{id}/ftp/browse?path=/"
# {"detail":"FTP password missing. Provide password query param or configure secret_ref_id."}
```

### 6.3 Preuve: browse avec temp_password fonctionne

```bash
curl -X GET "https://seller-dev.keybuzz.io/api/catalog-sources/{id}/ftp/browse?path=/&password=xxx"
# {"current_path":"/","items":[{"name":"Preisliste","type":"directory",...},...],"parent_path":null}
```

---

## 7. UI: Comment utiliser

### Test/browse ponctuel

1. Onglet "Connexion FTP"
2. Saisir host/port/username/password
3. Cliquer "Tester la connexion" (envoie password dans query)
4. Cliquer "Parcourir les fichiers" (envoie password dans query)
5. Le password n'est **jamais stocké**

### Connexion durable (TODO)

1. Créer un secret_ref via l'API secrets
2. Associer le secret_ref_id à la connexion
3. Le password est dans Vault, pas en DB

---

## 8. Rollback

```bash
# Si besoin de revenir en arrière (non recommandé)
kubectl -n keybuzz-seller-dev set image deployment/seller-api \
  seller-api=ghcr.io/keybuzzio/seller-api:v1.0.7-ph-s03.9-ftp-pwd
```

---

## 9. TODO pour PROD

- [ ] Implémenter lecture Vault dans `get_ftp_password()`
- [ ] UI: permettre création/association de secret_ref
- [ ] Audit sécurité avant mise en PROD
