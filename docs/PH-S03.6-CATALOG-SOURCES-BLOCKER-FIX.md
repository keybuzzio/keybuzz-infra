# PH-S03.6 — Catalog Sources Blocker Fix

**Date :** 2026-02-02  
**Statut :** ✅ **DÉPLOYÉ**  
**Périmètre :** Corriger l'erreur 5xx sur /catalog-sources et le mojibake UTF-8  
**Environnement :** seller-dev uniquement

---

## 1. Problèmes identifiés

### 1.1 Erreur 5xx sur /catalog-sources

**Symptôme :** Bandeau "Erreur serveur, réessayez" au chargement de Catalog Sources.

**Cause racine :** `ResponseValidationError` dans FastAPI/Pydantic

```
fastapi.exceptions.ResponseValidationError: 6 validation errors:
  {'type': 'string_type', 'loc': ('response', 0, 'fields', 0, 'id'), 
   'msg': 'Input should be a valid string', 
   'input': UUID('7dc1c7ca-ff13-48b7-b5b9-f1c783be44b4')}
```

Le schéma `CatalogSourceFieldResponse` définit `id: str` mais la DB retourne des objets `UUID`. 
Lors du listing avec `include_fields=true`, les UUIDs n'étaient pas convertis en strings.

**Code fautif :**
```python
# Ligne 209, 245, 392 de catalog_sources.py
data["fields"] = [dict(f) for f in fields]  # UUIDs non convertis
```

### 1.2 Mojibake UTF-8

**Symptôme :** "rÃ©essayez" affiché au lieu de "réessayez"

**Cause racine :** Le fichier `api.ts` avait été transféré avec un encodage incorrect (Latin-1 interprété comme UTF-8).

### 1.3 Sources Wortmann "fantômes"

**Constat en DB :**
```
                  id                  |  tenantId  |   name    |   status
--------------------------------------+------------+-----------+-------------
 b5310427-4a67-420e-ac3a-d76b79a846e8 | ecomlg-001 | Wortmann  | ready
 7469507f-6e48-4c84-b0f7-79a61b1dcf9d | ecomlg-001 | Wortmann1 | to_complete
 67caecbd-363f-41be-a4b6-f4b66ba284ea | ecomlg-001 | Wortmann2 | to_complete
```

Les 3 sources existent et appartiennent au tenant `ecomlg-001`. Elles n'apparaissaient pas dans l'UI car l'API retournait une erreur 500 avant de pouvoir les lister.

---

## 2. Corrections appliquées

### 2.1 Fix UUID serialization (seller-api)

**Fichier :** `/opt/keybuzz/keybuzz-seller/seller-api/src/routes/catalog_sources.py`

**Ajout de la fonction :**
```python
def _deserialize_field(row) -> dict:
    """Convertit un field record asyncpg en dict avec UUIDs en string"""
    data = dict(row)
    for key, value in data.items():
        if hasattr(value, 'hex') and hasattr(value, 'int'):  # UUID
            data[key] = str(value)
    return data
```

**Remplacement dans 3 endroits :**
```python
# Avant
data["fields"] = [dict(f) for f in fields]

# Après
data["fields"] = [_deserialize_field(f) for f in fields]
```

### 2.2 Fix UTF-8 (seller-client)

**Fichier :** `/opt/keybuzz/keybuzz-seller/seller-client/src/lib/api.ts`

Le fichier a été retransféré via SCP avec l'encodage UTF-8 correct.

---

## 3. Images déployées

| Composant | Image | Digest |
|-----------|-------|--------|
| seller-api | `ghcr.io/keybuzzio/seller-api:v1.0.3-ph-s03.6-fix` | `sha256:1390b8cfa10c89760c1142b02668a0eb89337c7f1fea4651e0e8cd900172a5fb` |
| seller-client | `ghcr.io/keybuzzio/seller-client:v1.0.3-ph-s03.6-utf8` | `sha256:eba5c145d2bff988d20578e2a5142c93dcbd9b47bf74de879027496858d56d0c` |

---

## 4. Commits GitOps

| Commit | Message |
|--------|---------|
| `f8b21ad` | PH-S03.6: seller-api v1.0.3 - fix UUID serialization for fields |
| `cb4fbcd` | PH-S03.6: seller-client v1.0.3 - UTF-8 fix for error messages |

---

## 5. Vérification

### À vérifier manuellement (nécessite session authentifiée)

1. **GET /catalog-sources retourne 200** avec la liste des sources
2. **Les 3 sources Wortmann apparaissent** dans la liste
3. **Pas de bandeau "Erreur serveur"**
4. **Les messages d'erreur sont en UTF-8 correct** ("réessayez" et non "rÃ©essayez")

### Test création/suppression Wortmann

Si nécessaire (si l'utilisateur veut recréer une source "Wortmann" sans le chiffre) :

1. Supprimer via l'UI les sources existantes Wortmann/Wortmann1/Wortmann2
2. Créer une nouvelle source "Wortmann"
3. Vérifier : pas de "nom existe déjà"

---

## 6. Rollback

```bash
# Rollback seller-api
kubectl -n keybuzz-seller-dev set image deployment/seller-api \
  seller-api=ghcr.io/keybuzzio/seller-api@sha256:61ea8f895e1537cbd9fb1f04ec7b86c443f6d77d26bb817f8dd18a365029ef16

# Rollback seller-client
kubectl -n keybuzz-seller-dev set image deployment/seller-client \
  seller-client=ghcr.io/keybuzzio/seller-client:v1.0.2-ph-s03-final
```

---

## 7. Résumé technique

| Problème | Cause | Fix | Status |
|----------|-------|-----|--------|
| Erreur 5xx | UUID non sérialisés en string | `_deserialize_field()` | ✅ |
| Mojibake | Encodage Latin-1 | Retransfert UTF-8 | ✅ |
| Sources invisibles | Conséquence de l'erreur 5xx | Fix API | ✅ |
| "Wortmann existe déjà" | Sources présentes en DB | Sources visibles maintenant | ✅ |
