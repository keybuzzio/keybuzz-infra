# PH-S03.7 — Tenant Binding + Wizard Minimal

**Date :** 2026-02-02  
**Statut :** ✅ **DÉPLOYÉ**  
**Périmètre :** Fix "Tenant not configured in seller" + Wizard FTP minimal  
**Environnement :** seller-dev uniquement

---

## 1. Problème identifié

### 1.1 Erreur "Tenant not configured in seller"

**Symptôme :** Lors de la création d'une source, erreur 400 "Tenant not configured in seller"

**Cause racine :** 
- L'UI utilise le tenant KeyBuzz actif (ex: `ecomlg-ml5hgxky` ou `ludovic-ml5koskd`)
- Ce tenant n'existait pas dans `seller.tenants`
- Le code vérifiait l'existence et retournait une erreur si absent

**État initial de seller.tenants :**
```
 tenantId   | identity_ref | createdAt
------------+--------------+-----------
 ecomlg-001 |              | 2026-01-30
```

### 1.2 Mismatch tenant

Le tenant affiché dans l'UI KeyBuzz (ex: `ludovic-ml5koskd`) ne correspondait pas au tenant `ecomlg-001` en DB seller.

---

## 2. Solution implémentée

### 2.1 Auto-provisioning des tenants

**Nouveau helper :** `src/helpers/tenant.py`

```python
async def ensure_tenant_exists(conn, tenant_id: str) -> bool:
    """
    Vérifie si le tenant existe dans seller.tenants.
    Si non, le crée automatiquement (auto-provisioning).
    """
    exists = await conn.fetchval("""
        SELECT EXISTS(SELECT 1 FROM seller.tenants WHERE "tenantId" = $1)
    """, tenant_id)
    
    if exists:
        return True
    
    # Auto-provisioning
    await conn.execute("""
        INSERT INTO seller.tenants (
            "tenantId", "sellerDisplayName", "defaultCurrency", "timezone",
            "catalogEnabled", "multiMarketplaceEnabled", "identity_ref"
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)
        ON CONFLICT ("tenantId") DO NOTHING
    """, tenant_id, "", "EUR", "Europe/Paris", True, True, tenant_id)
    
    return True
```

### 2.2 Fichiers modifiés

| Fichier | Modification |
|---------|-------------|
| `src/helpers/tenant.py` | Nouveau - helper auto-provisioning |
| `src/helpers/__init__.py` | Nouveau - export ensure_tenant_exists |
| `src/routes/catalog_sources.py` | Remplacé vérification par auto-provisioning |
| `src/routes/config.py` | Remplacé vérification par auto-provisioning |
| `src/routes/secret_refs.py` | Remplacé vérification par auto-provisioning |
| `src/routes/marketplaces.py` | Remplacé vérification par auto-provisioning |

### 2.3 Wizard FTP minimal

La section "Champs produits attendus" (checkboxes) avait déjà été supprimée du wizard dans PH-S03.4.

Le wizard demande uniquement :
1. Origine (Fournisseur, Boutique, etc.)
2. Type (Fichier CSV, API, etc.)
3. Connexion FTP (host, port, credentials)
4. Sélection fichier(s)
5. Finalisation (nom + priorité)

---

## 3. Images déployées

| Composant | Version | Digest |
|-----------|---------|--------|
| seller-api | `v1.0.4-ph-s03.7-tenant` | `sha256:35b35dbbbeef4d...` |

---

## 4. Commits GitOps

| Commit | Message |
|--------|---------|
| `32a74ee` | PH-S03.7: seller-api v1.0.4 - tenant auto-provisioning |

---

## 5. Preuves

### 5.1 Tenant auto-provisionné

**Après fix :**
```
     tenantId     |   identity_ref   |        createdAt        
------------------+------------------+-------------------------
 ecomlg-001       |                  | 2026-01-30 22:03:21.364
 ludovic-ml5koskd | ludovic-ml5koskd | 2026-02-02 20:06:29.238
```

Le tenant `ludovic-ml5koskd` a été auto-provisionné avec `identity_ref` = lui-même.

### 5.2 Multi-tenant

Chaque tenant a ses propres sources :
- Les sources de `ecomlg-001` (Wortmann, Wortmann1, Wortmann2) ne sont visibles que par ce tenant
- Un nouveau tenant `ludovic-ml5koskd` commence avec une liste vide

---

## 6. Vérification manuelle

Avec une session authentifiée sur seller-dev :

1. Le tenant affiché en haut à droite correspond à l'identity_ref en DB
2. Création d'une source FTP fonctionne (201)
3. Plus de message "Tenant not configured in seller"
4. Wizard FTP : pas de section "Champs produits attendus"

---

## 7. Rollback

```bash
# Rollback seller-api
kubectl -n keybuzz-seller-dev set image deployment/seller-api \
  seller-api=ghcr.io/keybuzzio/seller-api:v1.0.3-ph-s03.6-fix

# Supprimer tenant auto-provisionné (si nécessaire)
PGPASSWORD=... psql -h 10.0.0.10 -U keybuzz_api_dev -d keybuzz \
  -c "DELETE FROM seller.tenants WHERE identity_ref IS NOT NULL AND \"tenantId\" != 'ecomlg-001';"
```

---

## 8. Design multi-tenant

### Principes appliqués

1. **Pas de hardcode tenant** : aucun tenant spécial (pas de `ecomlg-001` en dur)
2. **Auto-provisioning idempotent** : `ON CONFLICT DO NOTHING`
3. **Identity_ref = tenant_id KeyBuzz** : traçabilité
4. **Isolation tenant** : chaque tenant ne voit que ses propres données
5. **Session source of truth** : le tenant vient de la session KeyBuzz, pas de header spoofable

### Flow d'une requête

```
1. Request → seller-client (cookie session)
2. seller-client → Header X-Tenant-Id (depuis contexte utilisateur)
3. seller-api → Valide session via introspection KeyBuzz
4. seller-api → ensure_tenant_exists(tenant_id)
5. seller-api → Opération scopée par tenant_id
```
