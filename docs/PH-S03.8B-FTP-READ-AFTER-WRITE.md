# PH-S03.8B — FTP Read-After-Write Fix

**Date :** 2026-02-02  
**Statut :** ✅ **DÉPLOYÉ**  
**Périmètre :** Fix "Non configuré" après save FTP  
**Environnement :** seller-dev uniquement

---

## 1. Problème identifié

### 1.1 Symptôme

- Connexion FTP sauvegardée en DB (preuve PH-S03.8)
- Mais l'UI affiche encore "Non configuré" après save
- Les champs affichent les placeholders (ftp.example.com, username)
- Après refresh, toujours "Non configuré"

### 1.2 Cause racine

Dans `FtpConnection.tsx`, la fonction `loadConnection()` :

**AVANT (bugué) :**
```typescript
const loadConnection = useCallback(async () => {
  const data = await api.get<FtpConnection | null>(`/api/.../ftp/connection`);
  setConnection(data);  // ✅ Met à jour les données
  
  if (data) {
    setFormData({ ... });  // ✅ Remplit le formulaire
    // ❌ Ne met PAS à jour connectionStatus !
  }
}, [sourceId]);
```

**Problème :**
- `connectionStatus` est initialisé avec la prop `initialStatus` (passée par le parent)
- Après save, `loadConnection()` recharge les données mais ne met pas à jour `connectionStatus`
- Le statut reste "not_configured" même si les données sont présentes

---

## 2. Solution implémentée

### 2.1 Fix frontend (`FtpConnection.tsx`)

**APRÈS (corrigé) :**
```typescript
const loadConnection = useCallback(async () => {
  const data = await api.get<FtpConnection | null>(`/api/.../ftp/connection`);
  setConnection(data);
  
  if (data) {
    // PH-S03.8B: Mettre à jour le statut ET les données du formulaire
    setConnectionStatus('connected');  // ✅ AJOUTÉ
    setFormData({ ... });
  } else {
    // Pas de connexion configurée
    setConnectionStatus('not_configured');  // ✅ AJOUTÉ
  }
}, [sourceId]);
```

### 2.2 Logging backend (`ftp.py`)

Ajout de logs pour diagnostiquer les futurs problèmes de tenant mismatch :

```python
@router.get("/connection")
async def get_ftp_connection(source_id, user):
    logger.info(f"GET /ftp/connection - source_id={source_id}, tenant_id={user.tenant_id}")
    # ...
    logger.info(f"GET /ftp/connection - config found: {config is not None}")
```

---

## 3. Images déployées

| Composant | Version | Digest |
|-----------|---------|--------|
| seller-api | `v1.0.6-ph-s03.8b-log` | `sha256:dd2128c806e32e42eb7e8c750b932ec537e4d5a536fd55fdb51ba184510c9f41` |
| seller-client | `v1.0.4-ph-s03.8b-status` | `sha256:32823ae150b0075bc9348cd61be33b9ce3cd07a35c5f8b63e96ce2fe1b88f178` |

---

## 4. Commits GitOps

| Commit | Message |
|--------|---------|
| `eb9d194` | PH-S03.8B: FTP read-after-write fix - status update in UI |

---

## 5. Flow corrigé

```
1. Utilisateur remplit host/port/username/password
2. Clic "Enregistrer"
3. POST /ftp/connection → 201 Created
4. loadConnection() appelé
5. GET /ftp/connection → 200 avec données
6. setConnection(data) ✅
7. setConnectionStatus('connected') ✅ (NOUVEAU)
8. setFormData({ host, port, username }) ✅
9. UI affiche "Connecté" + données pré-remplies
```

---

## 6. Vérification manuelle

1. Ouvrir une source FTP sur seller-dev
2. Onglet "Connexion FTP"
3. Remplir host/port/username/password
4. Cliquer "Enregistrer"
5. **Attendu :**
   - Statut passe à "Connecté" (badge vert)
   - host/port/username restent remplis
   - password vide (normal)
6. Refresh la page
7. **Attendu :** Toujours "Connecté" avec les données

---

## 7. Preuve DB (référence)

```sql
SELECT source_id, tenant_id, host, username 
FROM seller.catalog_source_connections;
```

```
source_id                            | tenant_id        | host            | username     
-------------------------------------+------------------+-----------------+--------------
b5310427-4a67-420e-ac3a-d76b79a846e8 | ecomlg-001       | ftp.wortmann.de | PRLST_113789 
805c4889-9499-4c99-a5fd-b0a3f2ed6380 | ludovic-ml5koskd | ftp.wortmann.de | PRLST_113789 
```

---

## 8. Architecture tenant

### Points de vérification

1. **Header X-Tenant-Id** : Envoyé par le frontend depuis le contexte utilisateur
2. **Middleware auth** : Extrait le tenant_id du header
3. **Routes FTP** : Utilisent `user.tenant_id` pour filtrer
4. **DB** : `catalog_source_connections.tenant_id` doit matcher

### Logs de diagnostic

Si problème futur :
```bash
kubectl -n keybuzz-seller-dev logs deployment/seller-api | grep "ftp/connection"
```

Exemple de sortie :
```
GET /ftp/connection - source_id=xxx, tenant_id=ecomlg-001
GET /ftp/connection - config found: True
```

---

## 9. Rollback

```bash
# Rollback seller-client
kubectl -n keybuzz-seller-dev set image deployment/seller-client \
  seller-client=ghcr.io/keybuzzio/seller-client:v1.0.3-ph-s03.6-utf8

# Rollback seller-api
kubectl -n keybuzz-seller-dev set image deployment/seller-api \
  seller-api=ghcr.io/keybuzzio/seller-api:v1.0.5-ph-s03.8-ftp
```
