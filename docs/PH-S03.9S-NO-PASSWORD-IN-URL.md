# PH-S03.9S — Security Hotfix: No Password in URL

**Date :** 2026-02-02  
**Statut :** ✅ **DÉPLOYÉ**  
**Périmètre :** Suppression password dans query params  
**Environnement :** seller-dev uniquement

---

## 1. Vulnérabilité corrigée

### 1.1 Problème

Le password FTP était passé en **query parameter** :

```
GET /ftp/browse?path=/&password=SECRET
POST /ftp/test-connection?password=SECRET
```

**Risques :**
- Fuite dans les logs serveur (nginx, ingress)
- Fuite via HTTP Referer
- Visible dans l'historique navigateur
- Stocké dans les proxy caches

### 1.2 Solution

Password **exclusivement dans le body JSON** :

```json
POST /ftp/browse
{
  "path": "/",
  "temp_password": "SECRET"
}
```

---

## 2. Modifications

### 2.1 Backend (`ftp.py`)

**Avant :**
```python
@router.get("/browse")
async def browse_ftp(
    password: Optional[str] = Query(None)  # ❌ En URL
):
```

**Après :**
```python
class BrowseRequest(BaseModel):
    path: str = "/"
    temp_password: Optional[str] = None  # ✅ Dans body

@router.post("/browse")  # GET → POST
async def browse_ftp(
    body: BrowseRequest
):
```

### 2.2 Frontend (`FtpConnection.tsx`)

**Avant :**
```typescript
const passwordParam = formData.password ? `?password=${encodeURIComponent(formData.password)}` : '';
const result = await api.get(`/ftp/browse?path=${path}${passwordParam}`);  // ❌ En URL
```

**Après :**
```typescript
const result = await api.post(`/ftp/browse`, {
  path: path,
  temp_password: formData.password || null  // ✅ Dans body
});
```

### 2.3 Endpoints modifiés

| Endpoint | Méthode | Password |
|----------|---------|----------|
| `/ftp/browse` | GET → **POST** | Body: `temp_password` |
| `/ftp/test-connection` | POST | Body: `temp_password` |

---

## 3. Images déployées

| Composant | Version | Digest |
|-----------|---------|--------|
| seller-api | `v1.0.9-ph-s03.9s-body` | `sha256:7e98315f7d0d6a611fa235aa6771e4ec11d049240531b35de8295f9fe47bd0f9` |
| seller-client | `v1.0.5-ph-s03.9s-body` | `sha256:26f0856f924da772b239e74cb1d525441878d73964ffa5b4dd4842d2d9da3d27` |

---

## 4. Commits GitOps

| Commit | Message |
|--------|---------|
| `7db285e` | PH-S03.9S: Security fix - password in body only, never in URL |

---

## 5. Vérification sécurité

### 5.1 Code frontend (pas de password en URL)

```bash
grep -n 'password=' FtpConnection.tsx
# (aucun résultat)
```

### 5.2 Code backend (pas de Query param)

```bash
grep -n 'password.*Query' ftp.py
# (aucun résultat)
```

### 5.3 Logs (pas de password)

```bash
# Vérifier les logs ingress
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller | grep -i 'password=' | wc -l
# Attendu: 0

# Vérifier les logs API
kubectl logs -n keybuzz-seller-dev deployment/seller-api | grep -i 'password=' | wc -l
# Attendu: 0
```

---

## 6. Payload exemple

### Browse FTP

```bash
curl -X POST "https://seller-dev.keybuzz.io/api/catalog-sources/{id}/ftp/browse" \
  -H "Content-Type: application/json" \
  -H "Cookie: ..." \
  -d '{
    "path": "/",
    "temp_password": "xxx"
  }'
```

### Test connexion

```bash
curl -X POST "https://seller-dev.keybuzz.io/api/catalog-sources/{id}/ftp/test-connection" \
  -H "Content-Type: application/json" \
  -H "Cookie: ..." \
  -d '{
    "temp_password": "xxx"
  }'
```

---

## 7. Message d'erreur (si pas de password)

```json
{
  "detail": "FTP password missing. Provide temp_password in request body or configure secret_ref_id."
}
```

---

## 8. Rollback

```bash
# Rollback seller-api
kubectl -n keybuzz-seller-dev set image deployment/seller-api \
  seller-api=ghcr.io/keybuzzio/seller-api:v1.0.8-ph-s03.9r-no-pwd

# Rollback seller-client
kubectl -n keybuzz-seller-dev set image deployment/seller-client \
  seller-client=ghcr.io/keybuzzio/seller-client:v1.0.4-ph-s03.8b-status
```

---

## 9. Bonnes pratiques appliquées

- ✅ Password **jamais en URL** (query string)
- ✅ Password **uniquement en body** (JSON)
- ✅ Méthode **POST** pour les opérations avec credentials
- ✅ Password **jamais loggé** (ni côté serveur, ni côté client)
- ✅ Password **jamais stocké** en DB
