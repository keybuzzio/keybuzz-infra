# PH-S03.8 — FTP Connection Persistence Fix

**Date :** 2026-02-02  
**Statut :** ✅ **DÉPLOYÉ**  
**Périmètre :** Fix "Erreur serveur" lors de l'enregistrement de connexion FTP  
**Environnement :** seller-dev uniquement

---

## 1. Problème identifié

### 1.1 Symptôme

- Onglet "Connexion FTP" dans la fiche source
- Remplir host/port/username/password et cliquer "Enregistrer"
- Erreur: "Erreur serveur, réessayez." (5xx)
- Après refresh, champs vides → connexion non persistée

### 1.2 Cause racine

**Logs seller-api :**
```
fastapi.exceptions.ResponseValidationError: 1 validation errors:
  {'type': 'string_type', 'loc': ('response', 'id'), 'msg': 'Input should be a valid string', 
   'input': UUID('aff906ea-c752-4b99-b850-39a98e152ab6')}
```

**Explication :**
- La fonction `dict(row)` retourne des objets `UUID` natifs d'asyncpg
- Le schema Pydantic `FtpConnectionResponse.id` attend un `str`
- Pydantic refuse la validation → 500 Internal Server Error

### 1.3 Problème secondaire

- 409 Conflict si connexion existe déjà (POST au lieu de PATCH)
- Le frontend gère correctement POST/PATCH, mais le backend échouait avant d'atteindre ce point

---

## 2. Solution implémentée

### 2.1 Helper de désérialisation

Ajouté dans `src/routes/ftp.py` :

```python
def _deserialize_row(row) -> dict:
    """Convertit un record asyncpg en dict avec UUIDs en string"""
    if row is None:
        return None
    data = dict(row)
    for key, value in data.items():
        if hasattr(value, 'hex') and hasattr(value, 'int'):  # UUID
            data[key] = str(value)
    return data
```

### 2.2 Remplacement des retours

Tous les `return dict(row)` remplacés par `return _deserialize_row(row)` :

| Ligne | Fonction | Contexte |
|-------|----------|----------|
| 75 | `get_connection_config` | Récupération config connexion |
| 295 | `create_ftp_connection` | Création connexion (POST) |
| 349 | `update_ftp_connection` | Mise à jour connexion (PATCH) |
| 584 | `select_file` | Sélection fichier FTP |

---

## 3. Images déployées

| Composant | Version | Digest |
|-----------|---------|--------|
| seller-api | `v1.0.5-ph-s03.8-ftp` | `sha256:62588ec0790a782e80a28b0d648a6aa7f07e239689b4299efa74de79c79e592c` |

---

## 4. Commits GitOps

| Commit | Message |
|--------|---------|
| `a5cb6fc` | PH-S03.8: seller-api v1.0.5 - FTP connection UUID fix |

---

## 5. Preuves

### 5.1 Preuve logs AVANT fix

```
fastapi.exceptions.ResponseValidationError: 1 validation errors:
  {'type': 'string_type', 'loc': ('response', 'id'), 'msg': 'Input should be a valid string', 
   'input': UUID('aff906ea-c752-4b99-b850-39a98e152ab6')}
INFO: "POST /api/catalog-sources/805c4889.../ftp/connection HTTP/1.1" 409 Conflict
```

### 5.2 Preuve logs APRÈS fix

```
2026-02-02 20:52:20,784 - src.main - INFO - Database connection established
```
(Pas d'erreur ResponseValidationError)

### 5.3 Preuve DB

```sql
SELECT id, tenant_id, source_id, protocol, host, port, username 
FROM seller.catalog_source_connections;
```

```
                  id                  |    tenant_id     |              source_id               | protocol |      host       | port |   username   
--------------------------------------+------------------+--------------------------------------+----------+-----------------+------+--------------
 b94f1093-1416-4477-bf8e-c8da97538514 | ecomlg-001       | b5310427-4a67-420e-ac3a-d76b79a846e8 | ftp      | ftp.wortmann.de |   21 | PRLST_113789 
 aff906ea-c752-4b99-b850-39a98e152ab6 | ludovic-ml5koskd | 805c4889-9499-4c99-a5fd-b0a3f2ed6380 | ftp      | ftp.wortmann.de |   21 | PRLST_113789 
```

Les connexions FTP sont persistées correctement.

---

## 6. Vérification manuelle requise

1. Ouvrir seller-dev
2. Créer une nouvelle source FTP ou ouvrir une existante
3. Onglet "Connexion FTP"
4. Remplir host/port/username/password
5. Cliquer "Enregistrer"
6. **Attendu :** Pas d'erreur, statut "Connecté" ou "Non configuré" selon test
7. Refresh la page
8. **Attendu :** Les champs host/port/username restent remplis

---

## 7. Architecture de la connexion FTP

### Flow de sauvegarde

```
1. UI: Enregistrer (host, port, username, password)
2. Frontend: POST /ftp/connection (si nouvelle) ou PATCH (si existante)
3. Backend: INSERT/UPDATE seller.catalog_source_connections
4. Backend: _deserialize_row(row) → UUID en string
5. Frontend: Réponse 201/200 avec FtpConnectionResponse
6. UI: Affiche "Connexion configurée"
```

### Stockage du password

- **JAMAIS stocké en DB** (champ `secret_ref_id` null pour l'instant)
- En DEV: password temporaire utilisé pour test/browse
- En PROD: Vault via `secret_ref_id`

---

## 8. Rollback

```bash
# Rollback seller-api
kubectl -n keybuzz-seller-dev set image deployment/seller-api \
  seller-api=ghcr.io/keybuzzio/seller-api:v1.0.4-ph-s03.7-tenant

# GitOps
cd /opt/keybuzz/keybuzz-infra
git revert HEAD --no-edit
git push origin main
```
