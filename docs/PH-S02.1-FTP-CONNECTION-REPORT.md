# PH-S02.1 - Connexion FTP & Sélection de fichiers (EXPLORATION PASSIVE)

**Date**: 2026-01-31  
**Statut**: ✅ COMPLÉTÉ  
**Environnement**: DEV uniquement (seller-dev.keybuzz.io)

---

## 📋 Résumé Exécutif

PH-S02.1 ajoute la capacité de se connecter à un serveur FTP/SFTP, d'explorer l'arborescence distante et de sélectionner des fichiers pour utilisation ultérieure.

### ⚠️ CONFIRMATION EXPLICITE

> **"PH-S02.1 permet uniquement une exploration passive du FTP.**  
> **Aucun fichier n'est téléchargé, lu ou traité."**

---

## 🔒 Interdictions Respectées

| Interdiction | Statut |
|--------------|--------|
| ❌ Ne pas télécharger de fichier | ✅ Respecté |
| ❌ Ne pas lire le contenu | ✅ Respecté |
| ❌ Ne pas parser CSV/XML | ✅ Respecté |
| ❌ Ne pas stocker de données produits | ✅ Respecté |
| ❌ Ne pas créer de worker / cron | ✅ Respecté |
| ❌ Ne pas déclencher de run | ✅ Respecté |

---

## ✅ Fonctionnalités Implémentées

| Fonctionnalité | Statut |
|----------------|--------|
| Se connecter à un FTP déclaré | ✅ |
| Tester la connexion (valid/invalid) | ✅ |
| Lister les répertoires et fichiers | ✅ |
| Naviguer dans l'arborescence | ✅ |
| Sélectionner un ou plusieurs fichiers | ✅ |
| Stocker le chemin des fichiers sélectionnés | ✅ |

---

## 📁 Fichiers Créés/Modifiés

### Migration SQL
- `keybuzz-seller/migrations/004_ph_s02_1_ftp_connection.sql`

### API Backend (Python/FastAPI)
- `keybuzz-seller/seller-api/src/schemas/ftp_connection.py` (nouveau)
- `keybuzz-seller/seller-api/src/routes/ftp.py` (nouveau)
- `keybuzz-seller/seller-api/src/routes/__init__.py` (modifié)
- `keybuzz-seller/seller-api/src/main.py` (modifié)
- `keybuzz-seller/seller-api/src/schemas/catalog_source.py` (modifié)
- `keybuzz-seller/seller-api/src/routes/catalog_sources.py` (modifié)
- `keybuzz-seller/seller-api/requirements.txt` (ajout paramiko)

### UI Frontend (Next.js/React)
- `keybuzz-seller/seller-client/app/(dashboard)/catalog-sources/FtpConnection.tsx` (nouveau)
- `keybuzz-seller/seller-client/app/(dashboard)/catalog-sources/page.tsx` (modifié)
- `keybuzz-seller/seller-client/src/lib/api.ts` (modifié)

---

## 🗄️ DDL - Tables Créées/Modifiées

### Nouveaux ENUMs

```sql
CREATE TYPE seller."ConnectionType" AS ENUM ('ftp', 'sftp');
CREATE TYPE seller."ConnectionStatus" AS ENUM ('not_configured', 'connected', 'error');
```

### Extension de `seller.catalog_sources`

```sql
ALTER TABLE seller.catalog_sources ADD COLUMN "connection_type" seller."ConnectionType";
ALTER TABLE seller.catalog_sources ADD COLUMN "connection_status" seller."ConnectionStatus" DEFAULT 'not_configured';
ALTER TABLE seller.catalog_sources ADD COLUMN "last_connection_check_at" TIMESTAMP(3);
ALTER TABLE seller.catalog_sources ADD COLUMN "last_connection_error" TEXT;
```

### Nouvelle table `seller.catalog_source_connections`

```sql
CREATE TABLE seller.catalog_source_connections (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" TEXT NOT NULL,
    "source_id" TEXT NOT NULL,
    "protocol" seller."ConnectionType" NOT NULL DEFAULT 'ftp',
    "host" TEXT NOT NULL,
    "port" INTEGER NOT NULL DEFAULT 21,
    "username" TEXT,
    "secret_ref_id" TEXT,  -- Référence Vault, JAMAIS de password en clair
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "seller_catalog_source_connections_pkey" PRIMARY KEY ("id")
);
```

### Nouvelle table `seller.catalog_source_files`

```sql
CREATE TABLE seller.catalog_source_files (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" TEXT NOT NULL,
    "source_id" TEXT NOT NULL,
    "remote_path" TEXT NOT NULL,      -- /france/productcatalog.csv
    "filename" TEXT NOT NULL,         -- productcatalog.csv
    "selected" BOOLEAN NOT NULL DEFAULT true,
    "file_size" BIGINT,
    "last_modified" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "seller_catalog_source_files_pkey" PRIMARY KEY ("id")
);

-- Contrainte d'unicité
CREATE UNIQUE INDEX "seller_catalog_source_files_source_path_key" 
    ON seller.catalog_source_files("source_id", "remote_path");
```

---

## 📡 API Endpoints

### Connexion FTP

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/catalog-sources/{id}/ftp/connection` | Récupérer config connexion |
| POST | `/api/catalog-sources/{id}/ftp/connection` | Créer config connexion |
| PATCH | `/api/catalog-sources/{id}/ftp/connection` | Modifier config connexion |
| DELETE | `/api/catalog-sources/{id}/ftp/connection` | Supprimer config connexion |

### Opérations FTP (PASSIVES)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/catalog-sources/{id}/ftp/test-connection` | Tester la connexion |
| GET | `/api/catalog-sources/{id}/ftp/browse?path=/` | Parcourir l'arborescence |

### Sélection de fichiers

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/catalog-sources/{id}/ftp/files` | Liste des fichiers sélectionnés |
| POST | `/api/catalog-sources/{id}/ftp/select-file` | Sélectionner/désélectionner un fichier |
| DELETE | `/api/catalog-sources/{id}/ftp/files/{file_id}` | Retirer un fichier |

---

## 📦 Exemples JSON

### Configuration de connexion FTP

**Request:**
```json
POST /api/catalog-sources/{source_id}/ftp/connection
{
  "protocol": "ftp",
  "host": "ftp.supplier.com",
  "port": 21,
  "username": "keybuzz",
  "password": "secret123"
}
```

**Response:**
```json
{
  "id": "conn-123-456-789",
  "tenant_id": "tenant-abc",
  "source_id": "source-xyz",
  "protocol": "ftp",
  "host": "ftp.supplier.com",
  "port": 21,
  "username": "keybuzz",
  "secret_ref_id": null,
  "created_at": "2026-01-31T14:00:00.000Z",
  "updated_at": "2026-01-31T14:00:00.000Z"
}
```

### Test de connexion

**Request:**
```json
POST /api/catalog-sources/{source_id}/ftp/test-connection?password=secret123
```

**Response:**
```json
{
  "success": true,
  "status": "connected",
  "message": "Connexion réussie",
  "checked_at": "2026-01-31T14:05:00.000Z"
}
```

### Navigation FTP

**Request:**
```
GET /api/catalog-sources/{source_id}/ftp/browse?path=/products&password=secret123
```

**Response:**
```json
{
  "current_path": "/products",
  "parent_path": "/",
  "items": [
    {
      "name": "france",
      "path": "/products/france",
      "type": "directory",
      "size": null,
      "modified": null
    },
    {
      "name": "catalog_2026.csv",
      "path": "/products/catalog_2026.csv",
      "type": "file",
      "size": 1548320,
      "modified": "2026-01-30T08:30:00.000Z"
    }
  ]
}
```

### Sélection de fichier

**Request:**
```json
POST /api/catalog-sources/{source_id}/ftp/select-file
{
  "remote_path": "/products/france/catalog.csv",
  "selected": true
}
```

**Response:**
```json
{
  "id": "file-111-222-333",
  "tenant_id": "tenant-abc",
  "source_id": "source-xyz",
  "remote_path": "/products/france/catalog.csv",
  "filename": "catalog.csv",
  "selected": true,
  "file_size": null,
  "last_modified": null,
  "created_at": "2026-01-31T14:10:00.000Z",
  "updated_at": "2026-01-31T14:10:00.000Z"
}
```

---

## 🖥️ UI - Fonctionnalités

### Liste des sources
- Badge de statut connexion FTP (🟢 Connecté / 🔴 Erreur / ⚪ Non configuré)
- Nombre de fichiers sélectionnés affiché

### Fiche Source - Onglet "Connexion FTP"

**Section 1 — Configuration connexion**
- Champs : Protocole (FTP/SFTP), Serveur, Port, Utilisateur, Mot de passe
- Bouton "Tester la connexion"
- Badge statut : 🟢 Connecté / 🔴 Erreur / ⚪ Non configuré

**Section 2 — Parcourir les fichiers**
- Explorateur type arborescence
- Navigation dans les dossiers (clic pour entrer)
- Icônes : 📁 dossier / 📄 fichier
- Bouton "Sélectionner" sur chaque fichier

**Section 3 — Fichiers sélectionnés**
- Liste des fichiers avec chemin complet
- Bouton "Retirer" pour chaque fichier
- Message UX : "Les fichiers sélectionnés seront utilisés ultérieurement pour importer vos produits."

---

## 🔐 Sécurité

| Aspect | Implémentation |
|--------|----------------|
| Credentials en DB | ❌ Jamais de password en clair |
| Référence Vault | ✅ `secret_ref_id` pour les secrets |
| Logs | ✅ Aucun password dans les logs |
| Contenu fichier | ✅ Jamais lu ni loggé |

---

## 🚀 Images Déployées

| Image | Tag |
|-------|-----|
| `ghcr.io/keybuzzio/seller-api` | `v1.3.0-ph-s02.1` |
| `ghcr.io/keybuzzio/seller-client` | `v1.6.0-ph-s02.1` |

---

## ✅ Critères de Validation

| Critère | Statut |
|---------|--------|
| Migration SQL idempotente | ✅ |
| Tables isolées dans schéma `seller` | ✅ |
| Aucun secret stocké en DB | ✅ |
| API CRUD connexion | ✅ |
| API test connexion | ✅ |
| API navigation FTP | ✅ |
| API sélection fichiers | ✅ |
| UI onglet Connexion FTP | ✅ |
| UI explorateur arborescence | ✅ |
| UI liste fichiers sélectionnés | ✅ |
| Aucun fichier téléchargé | ✅ |
| Aucun fichier lu | ✅ |
| Aucun parsing | ✅ |

---

## 🧩 Concept UX (Vendeur-Friendly)

Dans l'UI, le vendeur voit :
- 🟢 **FTP connecté**
- 📁 **2 fichiers sélectionnés**
- 🟡 **À vérifier** (si aucun fichier sélectionné)

Et **PAS** :
- "FTP credentials valid"
- "Remote path OK"
- "Listing succeeded"

---

## 📊 Métriques

- **Lignes de code SQL**: ~280
- **Lignes de code Python**: ~450
- **Lignes de code TypeScript**: ~600
- **Tables créées**: 2 (catalog_source_connections, catalog_source_files)
- **Colonnes ajoutées**: 4
- **ENUMs créés**: 2
- **Endpoints API**: 8
- **Dépendances ajoutées**: 1 (paramiko pour SFTP)

---

**Rapport généré le**: 2026-01-31  
**Auteur**: KeyBuzz CE
