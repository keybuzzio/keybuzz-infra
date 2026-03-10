# PH-S04.0 — FTP Simple MVP

**Date :** 2026-02-03  
**Statut :** ✅ **DÉPLOYÉ**  
**Périmètre :** Wizard FTP simplifié + password uniquement dans body  
**Environnement :** seller-dev uniquement

---

## 1. Objectif MVP

### 1.1 Wizard simplifié

| Étape | Contenu |
|-------|---------|
| 1 | Nom + Type de source |
| 2 | Connexion FTP (host/port/user/password) |
| 3 | Browse + sélection fichier |
| 4 | Finalisation |

**Pas de mapping dans le wizard** - le mapping est dans l'onglet "Colonnes (CSV)" de la fiche source.

### 1.2 Supprimé du wizard

- ❌ Section "Connexion durable (recommandée)"
- ❌ Dropdown secret_refs
- ❌ Mention "le mot de passe sera stocké"
- ❌ Étape "Mapping des colonnes"

---

## 2. Architecture sécurité

### 2.1 Password

| Opération | Méthode | Stockage |
|-----------|---------|----------|
| Test connexion | POST body `temp_password` | Jamais |
| Browse FTP | POST body `temp_password` | Jamais |
| Sauvegarde source | DB | host/port/user uniquement |

### 2.2 Endpoints modifiés (PH-S03.9S)

```python
# AVANT (interdit - fuite dans logs)
GET /ftp/browse?path=/&password=xxx

# APRÈS (sécurisé)
POST /ftp/browse
{
  "path": "/",
  "temp_password": "xxx"
}
```

---

## 3. Images déployées

| Composant | Version | Digest |
|-----------|---------|--------|
| seller-api | `v1.0.9-ph-s03.9s-body` | `sha256:7e98315f7d0d6a611fa235aa6771e4ec11d049240531b35de8295f9fe47bd0f9` |
| seller-client | `v1.0.5-ph-s04.0-mvp` | `sha256:a1b97b2be0bd19702a4ece5c4fc2577e5b5278d5b0e3b7dcfb692eacdacf3d45` |

---

## 4. Commits GitOps

| Commit | Message |
|--------|---------|
| `2746011` | PH-S04.0: FTP Simple MVP - no secret_ref in wizard, password in body |

---

## 5. Flow utilisateur

### 5.1 Créer une source FTP

1. Cliquer "Nouvelle source"
2. Saisir nom + choisir type (ex: "Fichier CSV (FTP)")
3. Configurer FTP: host, port, user, password
4. Tester la connexion
5. Parcourir le serveur FTP
6. Sélectionner un fichier
7. Enregistrer

**Résultat :**
- Source créée avec host/port/user persistés
- Fichier sélectionné enregistré (remote_path)
- Password **NON stocké**

### 5.2 Configurer le mapping (post-wizard)

1. Ouvrir la fiche source
2. Onglet "Colonnes (CSV)"
3. Saisir le password pour détecter les en-têtes
4. Mapper les colonnes → champs produits
5. Sauvegarder le mapping

---

## 6. Endpoints API

### Wizard

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `POST /catalog-sources` | POST | Créer source |
| `POST /catalog-sources/{id}/ftp/connection` | POST | Enregistrer host/port/user |
| `POST /catalog-sources/{id}/ftp/test-connection` | POST | Tester avec `temp_password` |
| `POST /catalog-sources/{id}/ftp/browse` | POST | Parcourir avec `temp_password` |
| `POST /catalog-sources/{id}/ftp/select-file` | POST | Sélectionner fichier |

### Matching (post-wizard)

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `GET /catalog-sources/{id}/ftp/files` | GET | Liste fichiers sélectionnés |
| `POST /catalog-sources/{id}/column-mappings/detect-headers` | POST | Détecter en-têtes |
| `POST /catalog-sources/{id}/column-mappings/bulk` | POST | Sauvegarder mapping |

---

## 7. Vérification

### 7.1 Wizard sans "Connexion durable"

```bash
grep -c "Connexion durable" page.tsx
# 0
```

### 7.2 Password dans body uniquement

```bash
# Frontend - pas de password dans URL
grep -c "password=" FtpConnection.tsx
# 0

# Backend - password dans body
grep "temp_password" ftp.py
# class TempPasswordRequest(BaseModel):
#     temp_password: Optional[str]
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

## 9. Prochaines étapes

- [ ] Test end-to-end du wizard FTP
- [ ] Test du mapping dans onglet Colonnes
- [ ] Validation que les logs ne contiennent pas de password
