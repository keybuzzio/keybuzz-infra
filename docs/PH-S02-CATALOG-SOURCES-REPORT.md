# PH-S02 - Sources de Produits (Déclaratif, Multi-Tenant, UX Métier)

**Date**: 2026-01-31  
**Statut**: ✅ COMPLÉTÉ  
**Environnement**: DEV uniquement (seller-dev.keybuzz.io)

---

## 📋 Résumé Exécutif

PH-S02 implémente la gestion déclarative des sources de produits pour le SaaS multi-tenant `seller.keybuzz.io`.

### ⚠️ CONFIRMATION EXPLICITE

> **"PH-S02 est purement déclaratif.**  
> **Aucune donnée externe n'est lue.**  
> **Aucune logique métier n'est exécutée.**  
> **Aucune dépendance avec l'existant."**

---

## 🔒 Interdictions Respectées

| Interdiction | Statut |
|--------------|--------|
| ❌ Pas de FTP / CSV / XML appelés | ✅ Respecté |
| ❌ Pas d'API (Shopify, Amazon, SOAP, etc.) | ✅ Respecté |
| ❌ Pas de stock réel | ✅ Respecté |
| ❌ Pas de prix réel | ✅ Respecté |
| ❌ Pas de moteur, diff, run, apply | ✅ Respecté |
| ❌ Pas de cron, worker, queue | ✅ Respecté |
| ❌ Pas de PrestaShop (intégration active) | ✅ Respecté |
| ❌ Pas de hardcode fournisseur | ✅ Respecté |

---

## 📁 Fichiers Créés/Modifiés

### Migration SQL
- `keybuzz-seller/migrations/003_ph_s02_catalog_sources_extended.sql`

### API Backend (Python/FastAPI)
- `keybuzz-seller/seller-api/src/schemas/catalog_source.py` (modifié)
- `keybuzz-seller/seller-api/src/routes/catalog_sources.py` (modifié)
- `keybuzz-seller/seller-api/src/routes/catalog_source_fields.py` (nouveau)
- `keybuzz-seller/seller-api/src/routes/__init__.py` (modifié)
- `keybuzz-seller/seller-api/src/main.py` (modifié)

### UI Frontend (Next.js/React)
- `keybuzz-seller/seller-client/app/(dashboard)/catalog-sources/page.tsx` (remplacé)

---

## 🗄️ DDL - Tables Modifiées/Créées

### Extension de `seller.catalog_sources`

```sql
-- Nouveaux ENUMs
CREATE TYPE seller."SourceKind" AS ENUM (
    'supplier',           -- Fournisseur
    'ecommerce_platform', -- Boutique en ligne
    'marketplace',        -- Marketplace
    'erp'                 -- Autre système
);

CREATE TYPE seller."SourceTypeExtended" AS ENUM (
    'ftp_csv',              -- Fichier CSV via FTP/SFTP
    'ftp_xml',              -- Fichier XML via FTP/SFTP
    'http_file',            -- Fichier via HTTP/HTTPS
    'api_generic',          -- API générique
    'shopify',              -- Shopify API
    'prestashop',           -- PrestaShop Webservice
    'woocommerce',          -- WooCommerce REST API
    'marketplace_reference' -- Référence marketplace
);

CREATE TYPE seller."SourceStatus" AS ENUM (
    'ready',       -- Prête
    'to_complete', -- À compléter
    'error',       -- Erreur
    'disabled'     -- Désactivée
);

-- Nouvelles colonnes sur catalog_sources
ALTER TABLE seller.catalog_sources ADD COLUMN "source_kind" seller."SourceKind" DEFAULT 'supplier';
ALTER TABLE seller.catalog_sources ADD COLUMN "source_type_ext" seller."SourceTypeExtended" DEFAULT 'ftp_csv';
ALTER TABLE seller.catalog_sources ADD COLUMN "priority" INTEGER DEFAULT 100;
ALTER TABLE seller.catalog_sources ADD COLUMN "status" seller."SourceStatus" DEFAULT 'to_complete';
ALTER TABLE seller.catalog_sources ADD COLUMN "human_label" TEXT;
ALTER TABLE seller.catalog_sources ADD COLUMN "description" TEXT;
```

### Nouvelle table `seller.catalog_source_fields`

```sql
CREATE TABLE seller.catalog_source_fields (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "tenant_id" TEXT NOT NULL,
    "source_id" TEXT NOT NULL,
    "field_code" VARCHAR(50) NOT NULL,    -- sku, stock, ean, price_buy, price_sell, brand, product_name
    "field_label" TEXT NOT NULL,
    "required" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "seller_catalog_source_fields_pkey" PRIMARY KEY ("id")
);

-- Contrainte d'unicité
CREATE UNIQUE INDEX "seller_catalog_source_fields_source_field_key" 
    ON seller.catalog_source_fields("source_id", "field_code");

-- Foreign Keys
ALTER TABLE seller.catalog_source_fields 
    ADD CONSTRAINT "seller_catalog_source_fields_tenant_id_fkey" 
    FOREIGN KEY ("tenant_id") REFERENCES seller.tenants("tenantId") ON DELETE CASCADE;

ALTER TABLE seller.catalog_source_fields 
    ADD CONSTRAINT "seller_catalog_source_fields_source_id_fkey" 
    FOREIGN KEY ("source_id") REFERENCES seller.catalog_sources("id") ON DELETE CASCADE;
```

---

## 📡 API Endpoints

### CRUD Catalog Sources

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/catalog-sources` | Liste des sources (filtres: status, kind) |
| GET | `/api/catalog-sources/{id}` | Détail d'une source |
| POST | `/api/catalog-sources` | Créer une source |
| PATCH | `/api/catalog-sources/{id}` | Modifier une source |
| PATCH | `/api/catalog-sources/{id}/status` | Changer le statut |
| PATCH | `/api/catalog-sources/{id}/priority` | Changer la priorité |
| DELETE | `/api/catalog-sources/{id}` | Supprimer une source |

### CRUD Catalog Source Fields

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/catalog-sources/{source_id}/fields` | Liste des champs |
| GET | `/api/catalog-sources/{source_id}/fields/{id}` | Détail d'un champ |
| POST | `/api/catalog-sources/{source_id}/fields` | Ajouter un champ |
| PUT | `/api/catalog-sources/{source_id}/fields` | Remplacer tous les champs (bulk) |
| PATCH | `/api/catalog-sources/{source_id}/fields/{id}` | Modifier un champ |
| DELETE | `/api/catalog-sources/{source_id}/fields/{id}` | Supprimer un champ |

### Options pour UI

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/catalog-sources/options/kinds` | Options d'origine |
| GET | `/api/catalog-sources/options/types` | Options de type technique |
| GET | `/api/catalog-sources/options/fields` | Options de champs produits |

---

## 📦 Exemples JSON

### Création d'une source

**Request:**
```json
POST /api/catalog-sources
{
  "name": "Catalogue TechDistrib",
  "source_kind": "supplier",
  "source_type_ext": "ftp_csv",
  "priority": 50,
  "status": "to_complete",
  "human_label": "Catalogue TechDistrib",
  "description": "Fichier CSV quotidien du fournisseur TechDistrib"
}
```

**Response:**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "tenantId": "tenant-123",
  "name": "Catalogue TechDistrib",
  "source_kind": "supplier",
  "source_type_ext": "ftp_csv",
  "priority": 50,
  "status": "to_complete",
  "human_label": "Catalogue TechDistrib",
  "description": "Fichier CSV quotidien du fournisseur TechDistrib",
  "isActive": true,
  "fields_count": 0,
  "fields": [],
  "createdAt": "2026-01-31T12:00:00.000Z",
  "updatedAt": "2026-01-31T12:00:00.000Z"
}
```

### Configuration des champs produits

**Request:**
```json
PUT /api/catalog-sources/a1b2c3d4-e5f6-7890-abcd-ef1234567890/fields
[
  { "field_code": "sku", "field_label": "Référence produit (SKU)", "required": true },
  { "field_code": "stock", "field_label": "Quantité disponible", "required": false },
  { "field_code": "price_buy", "field_label": "Prix d'achat", "required": false },
  { "field_code": "brand", "field_label": "Marque", "required": false }
]
```

**Response:**
```json
[
  {
    "id": "f1e2d3c4-b5a6-7890-1234-567890abcdef",
    "tenant_id": "tenant-123",
    "source_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "field_code": "sku",
    "field_label": "Référence produit (SKU)",
    "required": true,
    "created_at": "2026-01-31T12:05:00.000Z",
    "updated_at": "2026-01-31T12:05:00.000Z"
  },
  ...
]
```

---

## 🖥️ UI - Captures d'écran attendues

### 1. Liste des Sources
- Affiche toutes les sources avec:
  - Icône selon l'origine (📦 Fournisseur, 🛒 Boutique, 🏪 Marketplace, 🧩 Autre)
  - Nom de la source
  - Badge de statut coloré (🟢 Prête, 🟡 À compléter, 🔴 Erreur, ⚪ Désactivée)
  - Priorité
  - Nombre de champs configurés

### 2. Wizard de Création (3 étapes)
- **Étape 1**: D'où viennent vos produits ?
  - 4 boutons visuels (Fournisseur, Boutique en ligne, Marketplace, Autre système)
- **Étape 2**: Type de source
  - Options filtrées selon l'origine choisie
- **Étape 3**: Informations générales + Champs produits
  - Nom, Description, Priorité
  - Sélection des champs avec checkbox "Obligatoire"

### 3. Fiche Source
- Informations générales
- Statut avec boutons Activer/Désactiver
- Liste des champs configurés
- Bouton de suppression

---

## ✅ Critères de Validation

| Critère | Statut |
|---------|--------|
| Migration SQL idempotente | ✅ |
| Schéma `seller` isolé | ✅ |
| Aucune FK vers `public.*` | ✅ |
| API CRUD complète | ✅ |
| Isolation tenant dans l'API | ✅ |
| UI avec langage e-commerçant | ✅ |
| Wizard de création | ✅ |
| Fiche source détaillée | ✅ |
| Aucun appel externe | ✅ |
| Aucune logique métier | ✅ |

---

## 🚀 Déploiement

### Étapes de déploiement sur DEV

1. **Appliquer la migration SQL**
```bash
ssh root@bastion
psql -h <postgres-host> -U keybuzz_api -d keybuzz \
  -f /opt/keybuzz/keybuzz-seller/migrations/003_ph_s02_catalog_sources_extended.sql
```

2. **Reconstruire seller-api**
```bash
cd /opt/keybuzz/keybuzz-seller/seller-api
docker build -t ghcr.io/ludovic/seller-api:v1.2.0-ph-s02 .
docker push ghcr.io/ludovic/seller-api:v1.2.0-ph-s02
```

3. **Reconstruire seller-client**
```bash
cd /opt/keybuzz/keybuzz-seller/seller-client
rm -rf .next node_modules && npm install && npm run build
docker build -t ghcr.io/ludovic/seller-client:v1.5.0-ph-s02 .
docker push ghcr.io/ludovic/seller-client:v1.5.0-ph-s02
```

4. **Mettre à jour les manifests K8s via GitOps**
- Modifier les tags d'image dans `keybuzz-infra/k8s/keybuzz-seller-dev/`
- Commit et push
- ArgoCD sync

---

## 📊 Métriques

- **Lignes de code SQL**: ~200
- **Lignes de code Python**: ~400
- **Lignes de code TypeScript**: ~700
- **Tables créées**: 1 (catalog_source_fields)
- **Colonnes ajoutées**: 6
- **ENUMs créés**: 3
- **Endpoints API**: 13

---

## 📝 Notes

1. **Pas d'exécution de synchronisation**: La phase PH-S02 est strictement déclarative. Les sources sont configurées mais aucune donnée n'est lue ou synchronisée.

2. **Champs produits**: Les codes de champs (`sku`, `stock`, `ean`, etc.) sont des conventions. Ils n'impliquent aucun mapping automatique avec des fichiers ou APIs externes.

3. **Priorité**: La priorité est un indicateur déclaratif. Elle sera utilisée dans des phases futures pour résoudre les conflits entre sources.

4. **Statuts**: Les statuts sont gérés manuellement par l'utilisateur. Aucune validation automatique n'est effectuée.

---

**Rapport généré le**: 2026-01-31  
**Auteur**: KeyBuzz CE
