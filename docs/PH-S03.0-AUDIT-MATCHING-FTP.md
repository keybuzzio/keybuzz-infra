# PH-S03.0 — Audit factuel Catalog Sources + FTP + Matching CSV (seller-dev)

**Date :** 2026-01-30  
**Périmètre :** Flow "Créer une source", Configurer FTP, Matching CSV — diagnostic sans modification.  
**Environnement :** seller-dev (lecture code + état DB/API décrit ; aucun déploiement, aucune action PROD).

---

## Schéma ASCII des flows

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  UI: /catalog-sources (wizard 6 étapes si type FTP)                              │
├─────────────────────────────────────────────────────────────────────────────────┤
│  Étape 1: kind (supplier|ecommerce_platform|marketplace|erp)                      │
│  Étape 2: type (ftp_csv|ftp_xml|...)                                             │
│  Étape 3: Connexion FTP → test-direct, browse-direct, select-file (en mémoire)   │
│  Étape 4: Fichiers sélectionnés (selectedFiles[])                                │
│  Étape 5: detect-headers-direct → colonnes détectées → columnMappings[] (UI)     │
│  Étape 6: name, description, priority, fields[] → Créer la source              │
└─────────────────────────────────────────────────────────────────────────────────┘
        │
        │  Clic "Créer la source"
        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│  API (seller-api)                                                                 │
│  POST /api/catalog-sources          → 201, body CatalogSourceResponse              │
│  PUT  /api/catalog-sources/{id}/fields  → 200, list fields                        │
│  POST /api/catalog-sources/{id}/ftp/connection  → 201 (host, port, username,     │
│        secret_ref_id; password non persisté si pas secret_ref_id)                │
│  POST /api/catalog-sources/{id}/ftp/select-file  → 201 (par fichier)             │
│  POST /api/catalog-sources/{id}/column-mappings/bulk  → 201                        │
└─────────────────────────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│  DB (schema seller)                                                               │
│  catalog_sources → catalog_source_fields → catalog_source_connections             │
│  → catalog_source_files → catalog_source_column_mappings                          │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## A) Cartographie du flow "Créer une source"

### A.1 UI

- **Page :** `app/(dashboard)/catalog-sources/page.tsx` — wizard "Nouvelle source de produits".
- **Champs envoyés au POST create :**
  - `name` (string, obligatoire)
  - `source_kind` (ex. `supplier`)
  - `source_type_ext` (ex. `ftp_csv`)
  - `priority` (number, défaut 100)
  - `description` (string | null)
  - `status` : `ready` si `wizardData.selectedFiles.length > 0`, sinon `to_complete`.
- **Payload exact (extrait code) :**
```json
{
  "name": "<Nom saisi>",
  "source_kind": "<kind étape 1>",
  "source_type_ext": "<type étape 2>",
  "priority": 100,
  "description": null,
  "status": "ready" | "to_complete"
}
```

### A.2 API

- **Endpoint :** `POST /api/catalog-sources` (prefix `/api` dans `main.py`).
- **Fichier :** `seller-api/src/routes/catalog_sources.py` — `create_catalog_source`.
- **Auth :** `require_auth_with_tenant` (X-User-Email, X-Tenant-Id).
- **Status attendu :** 201.
- **Réponse :** `CatalogSourceResponse` (id, tenantId, name, source_kind, source_type_ext, priority, status, etc. ; champs JSONB désérialisés ; tous les UUID en string via `_deserialize_source`).
- **Erreurs possibles :**
  - 400 si tenant non configuré dans seller.
  - 409 si contrainte unique `("tenantId", name)` violée — message "A catalog source with this name already exists".

### A.3 DB

- **Table :** `seller.catalog_sources`.
- **Colonnes clés (INSERT) :** id, "tenantId", name, "sourceType", source_kind, source_type_ext, priority, status, human_label, description, "ftpHost", "ftpPort", "ftpPath", "ftpSecure", "csvDelimiter", "csvEncoding", "csvHasHeader", "apiEndpoint", "apiMethod", "apiHeaders", "webhookPath", "fieldMapping", "secretRefId", isActive.
- **Contrainte :** UNIQUE ("tenantId", name) — source : `001_seller_schema.sql` + `003_ph_s02_catalog_sources_extended.sql`.

### A.4 Preuve (lecture seule)

- **Requête SELECT pour constater une source créée (sans secret) :**
```sql
SELECT id, "tenantId", name, "sourceType", source_kind, source_type_ext, priority, status
FROM seller.catalog_sources
WHERE "tenantId" = '<tenant_id_masqué>'
ORDER BY "createdAt" DESC
LIMIT 5;
```
- **Payload :** voir A.1 ; pas de secret dans le body du POST create.

---

## B) Cartographie du flow "Configurer FTP"

### B.1 Où l’utilisateur saisit host / port / user / secret

- **Wizard (création) :** étape 3 "Connexion au serveur" — champs : protocole (ftp/sftp), serveur (host), port, utilisateur, mot de passe (saisie libre). Aucun champ `secret_ref_id` dans le wizard ; le client envoie `password` en clair dans les appels **pendant** le wizard (test-direct, browse-direct, detect-headers-direct, puis à la création dans `POST ftp/connection` avec `password`).
- **Fiche source (après création) :** `FtpConnection.tsx` — formulaire avec host, port, username ; mot de passe soit via champ temporaire (query `?password=...` pour test/browse), soit via `secret_ref_id` (liste des secret refs).

### B.2 Utilisation de secret_ref_id

- **DB :** `catalog_source_connections.secret_ref_id` — référence vers `seller.secret_refs(id)`. Aucun mot de passe en clair en base (004_ph_s02_1_ftp_connection.sql).
- **API :** `get_ftp_password(secret_ref_id, temp_password)` dans `ftp.py` : si `temp_password` fourni, il est utilisé ; sinon si `secret_ref_id`, lookup Vault prévu mais **non implémenté** (TODO) — retourne None. Donc en l’état, seul un password temporaire (query param ou body) permet test/browse après création si pas de Vault.

### B.3 Endpoints test connexion / browse / select-file

| Action | Endpoint | Méthode | Contexte |
|--------|----------|---------|----------|
| Tester connexion (wizard) | `/api/ftp/test-direct` | POST | Sans source ; body: protocol, host, port, username, password. |
| Tester connexion (fiche source) | `/api/catalog-sources/{source_id}/ftp/test-connection` | POST | Avec source ; query `?password=xxx` optionnel si pas de secret_ref. |
| Browse (wizard) | `/api/ftp/browse-direct` | POST | Body: protocol, host, port, username, password, path. |
| Browse (fiche source) | `/api/catalog-sources/{source_id}/ftp/browse?path=...` | GET | + query `?password=xxx` si besoin. |
| Sélection fichier | `/api/catalog-sources/{source_id}/ftp/select-file` | POST | Body: remote_path, selected. |

- **Fichiers API :** `seller-api/src/routes/ftp.py` — `ftp_direct_router` (test-direct, browse-direct) et `router` sous `/catalog-sources/{source_id}/ftp` (connection, test-connection, browse, select-file, files).

### B.4 Comportement browse (aucun téléchargement de fichier)

- **Code :** `list_ftp_directory()` — utilise MLSD/NLST (FTP) ou `listdir_attr` (SFTP). Commentaire explicite : "NE TELECHARGE AUCUN FICHIER." Aucun `RETR` dans cette fonction.
- **Preuve :** `ftp.py` lignes 136–218 : uniquement `cwd`, `mlsd`, `nlst`, `cwd(name); cwd("..")` pour détecter répertoire.

### B.5 Structure JSON retournée par browse

- **Modèle :** `FtpBrowseResponse` — `current_path: str`, `items: List[FtpFileItem]`, `parent_path: Optional[str]`.
- **FtpFileItem :** name, path, type (file | directory), size (optionnel), modified (optionnel).
- **Exemple (masqué) :**
```json
{
  "current_path": "/",
  "parent_path": null,
  "items": [
    { "name": "france", "path": "/france", "type": "directory", "size": null, "modified": null },
    { "name": "productcatalog.csv", "path": "/productcatalog.csv", "type": "file", "size": 1234567, "modified": "2026-01-15T10:00:00" }
  ]
}
```

### B.6 Exemple select-file

- **Body :** `{ "remote_path": "/france/productcatalog.csv", "selected": true }`.
- **Table :** `seller.catalog_source_files` — colonnes id, tenant_id, source_id, remote_path, filename, selected, file_size, last_modified, created_at, updated_at.
- **Preuve (SELECT lecture seule) :**
```sql
SELECT id, source_id, remote_path, filename, selected
FROM seller.catalog_source_files
WHERE source_id = '<source_id_masqué>';
```

---

## C) Cartographie du flow "Matching CSV existant"

### C.1 Où il se trouve en UI

- **Page :** même wizard `catalog-sources/page.tsx`, **étape 5** "Mapping des colonnes" (si type FTP + fichiers sélectionnés).
- **Enchaînement :** l’utilisateur clique "Détecter les en-têtes" → appel `POST /api/column-mapping/detect-headers-direct` (host, port, username, password, file_path du premier fichier sélectionné) → affichage des colonnes détectées + liste déroulante "Champ produit" par colonne (sku, quantity, ean, price_buy, etc. via `GET /api/column-mapping/available-fields`). Les mappings sont gardés en state `columnMappings[]`. À l’étape 6, au clic "Créer la source", après création de la source et si `wizardData.columnMappings.length > 0`, appel `POST /api/catalog-sources/{id}/column-mappings/bulk`.

### C.2 Donnée stockée (tables + colonnes)

- **Table :** `seller.catalog_source_column_mappings` (005_ph_s02_2_column_mapping.sql).
- **Colonnes :** id, tenant_id, source_id, source_column, source_column_index, target_field (enum product_field), transform_rule, default_value, created_at, updated_at.
- **Contraintes :** UNIQUE (source_id, source_column), UNIQUE (source_id, target_field).

**DDL (extrait) :**
```sql
CREATE TABLE IF NOT EXISTS seller.catalog_source_column_mappings (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    tenant_id VARCHAR(50) NOT NULL,
    source_id TEXT NOT NULL REFERENCES seller.catalog_sources(id) ON DELETE CASCADE,
    source_column VARCHAR(255) NOT NULL,
    source_column_index INTEGER,
    target_field seller.product_field NOT NULL,
    transform_rule VARCHAR(50),
    default_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (source_id, source_column),
    UNIQUE (source_id, target_field)
);
```

- **Table cache en-têtes :** `seller.catalog_source_detected_headers` (headers JSONB, file_id, source_id, etc.) — utilisée pour cache ; le wizard actuel utilise surtout la réponse de `detect-headers-direct` en mémoire.

### C.3 Champs matchés

- **Cibles (ProductField) :** sku, ean, quantity, price_buy, price_sell, brand, product_name, description, weight, category, image_url, custom_1/2/3. Liste exposée par `GET /api/column-mapping/available-fields`.
- **Côté client :** les champs "champs produits attendus" (étape 6) utilisent des codes type `stock` (catalogue) ; à l’envoi bulk, le client envoie `target_field: "quantity"` quand le code UI est `stock` (normalisation dans page.tsx).

### C.4 Détermination "ready / incomplete"

- **Côté UI (wizard) :** `status` envoyé au POST create = `ready` si `wizardData.selectedFiles.length > 0`, sinon `to_complete`. Pas de critère explicite "mapping SKU présent" pour le statut dans le schéma de réponse (le champ status vient du body envoyé).
- **Validation étape 5 :** `canProceed()` exige au moins un mapping avec `targetField === 'sku'` pour passer à l’étape 6.

### C.5 Preuve — exemple de mapping enregistré (SELECT)

```sql
SELECT id, source_id, source_column, source_column_index, target_field, transform_rule
FROM seller.catalog_source_column_mappings
WHERE source_id = '<source_id_masqué>';
```

---

## D) Liste des erreurs rencontrées (factuelle)

D’après l’historique du module et la lecture du code, les erreurs suivantes ont été observées ou sont susceptibles de se produire.

### Erreur 1 — "Not Found" sur "Tester la connexion" (wizard)

- **Repro :** Étape 3 du wizard, remplir host/port/user/mot de passe, cliquer "Tester la connexion".
- **Endpoint appelé :** `POST /api/ftp/test-direct` (client : `api.post('/api/ftp/test-direct', { ... })`).
- **Cause identifiée :** Route absente si l’API déployée utilisait une ancienne image (ex. v1.0.0) sans `ftp_direct_router`. Vérification : curl interne au cluster renvoyait 404 tant que l’image n’incluait pas la route.
- **Status / body :** 404 Not Found (body non JSON ou générique).
- **Impact DB :** Aucun (appel sans source_id).

### Erreur 2 — "Failed to fetch" à la création de source

- **Repro :** Remplir le wizard jusqu’à l’étape 6, cliquer "Créer la source".
- **Endpoints en chaîne :** POST catalog-sources, PUT fields, POST ftp/connection, POST ftp/select-file (×N), POST column-mappings/bulk.
- **Causes possibles :** (1) Réponse API non reçue par le client (réseau/CORS/timeout) → fetch rejette "Failed to fetch". (2) Réponse 200/201 avec body contenant des UUID non sérialisés en string → erreur de validation côté client ou désérialisation. (3) Proxy client (Next.js) ou URL API incorrecte.
- **Status / body :** Côté client : exception "Failed to fetch" (pas de status HTTP si requête n’aboutit pas). Côté API : si requête reçue, 201 attendu pour POST create ; 422 si validation Pydantic échoue.
- **Impact DB :** Si le POST create a réussi avant la chute (ex. timeout sur une étape suivante), la source est créée ; la liste peut être rafraîchie pour la voir.

### Erreur 3 — "Field required" (×N) + message "La source X a bien été créée"

- **Repro :** Création avec champs produits cochés (étape 6), puis une des étapes suivantes échoue.
- **Endpoint en cause :** `PUT /api/catalog-sources/{id}/fields` — body attendu par l’API : liste d’objets `{ field_code, field_label, required }`. Le client envoyait auparavant `{ code, label, required }` → validation Pydantic "field required" pour chaque champ (field_code, field_label manquants).
- **Status / body :** 422 Unprocessable Entity ; body `detail: [ { "loc": ["body", ...], "msg": "field required", ... }, ... ]`.
- **Impact DB :** Source déjà créée (POST 201) ; champs non créés ou partiellement créés selon l’ordre des appels. Correction côté client : envoi de `field_code` / `field_label` au lieu de `code` / `label`.

### Erreur 4 — Conflit de nom "déjà existant" affiché à tort

- **Repro :** Création réussie (source créée), puis échec sur une étape suivante ; le message affiché disait "une source avec ce nom existe déjà".
- **Cause :** Le message "nom déjà existant" était déclenché pour toute erreur contenant "already exists" ou "Conflict", y compris quand l’erreur venait d’une autre étape (ex. 409 sur une autre ressource ou message générique). La logique a été restreinte pour n’afficher "nom déjà existant" que lorsque la création (POST catalog-sources) a échoué avec un conflit de nom.
- **Impact DB :** Source créée ; l’utilisateur croyait à un doublon alors que c’était une erreur ultérieure.

### Erreur 5 — Connexion FTP (fiche source) : test/browse impossibles après création

- **Repro :** Créer une source en envoyant host/port/username/password dans `POST ftp/connection` sans `secret_ref_id`. Plus tard, ouvrir la fiche source et cliquer "Tester la connexion" ou "Parcourir" sans ressaisir de mot de passe.
- **Cause :** L’API ne persiste pas le mot de passe ; elle n’enregistre que `secret_ref_id`. Si `secret_ref_id` est null et que le lookup Vault n’est pas implémenté, `get_ftp_password` retourne None → connexion FTP échoue (auth).
- **Endpoint :** POST test-connection ou GET browse avec source_id ; sans `?password=...` et sans secret_ref valide, échec côté FTP.
- **Impact DB :** Aucune donnée corrompue ; la connexion reste "not_configured" ou erreur tant qu’aucun secret n’est fourni au moment du test/browse.

---

## E) Hypothèses de causes (max 5, avec preuve)

1. **Route `/api/ftp/test-direct` absente sur l’image déployée**  
   **Preuve :** Déploiement observé avec image seller-api v1.0.0 ; la route est enregistrée dans `main.py` via `ftp_direct_router` ; curl vers `POST /api/ftp/test-direct` renvoyait 404 avec cette image. **Action :** Vérifier que l’image déployée en seller-dev contient bien `ftp_direct_router` et les routes test-direct / browse-direct.

2. **Payload PUT /fields avec mauvais noms de champs (code/label au lieu de field_code/field_label)**  
   **Preuve :** Code client (page.tsx) envoyait `wizardData.fields` (objets avec `code`, `label`, `required`) ; le schéma API `CatalogSourceFieldCreate` exige `field_code`, `field_label`, `required`. Correction déjà faite : mapping `field_code: f.code`, `field_label: f.label`. Si une ancienne version du client est encore servie, l’erreur 422 "Field required" réapparaît.

3. **Réponse 201 du POST create contenant des UUID non sérialisés en string**  
   **Preuve :** `_deserialize_source` dans catalog_sources.py convertit explicitement les types UUID en string pour éviter ResponseValidationError Pydantic. Si une ancienne version de l’API sans cette conversion est déployée, le client peut recevoir une 500 ou une réponse invalide → "Failed to fetch" ou erreur de parsing.

4. **Appels API en cross-origin sans proxy → "Failed to fetch"**  
   **Preuve :** Le client peut appeler directement l’URL de l’API (ex. seller-api-dev.keybuzz.io) ; en cas de CORS ou réseau défaillant, fetch rejette avec "Failed to fetch". Un proxy Next.js (`/api/seller/...`) a été ajouté pour passer en same-origin et limiter ce cas.

5. **Mot de passe FTP non persisté : wizard envoie `password`, API ne stocke que `secret_ref_id`**  
   **Preuve :** `create_ftp_connection` n’écrit que les colonnes de `catalog_source_connections` dont `secret_ref_id` ; le champ `password` du body n’est pas stocké (et ne doit pas l’être en clair). Il n’y a pas de création automatique d’un `secret_ref` + enregistrement Vault à partir du password saisi dans le wizard. Donc après création, test/browse depuis la fiche source nécessitent soit un secret_ref_id déjà renseigné (Vault implémenté), soit un mot de passe temporaire (query param). **Preuve code :** `ftp.py` create_ftp_connection n’utilise pas `data.password` pour créer un secret ; `get_ftp_password` retourne `temp_password` si fourni, sinon None si Vault non implémenté.

---

## F) Proposition de plan de correction (SANS CODER)

### F.1 Liste de corrections candidates

1. **Vérifier image seller-api déployée** — S’assurer que l’image utilisée en seller-dev inclut les routes `ftp_direct_router` (test-direct, browse-direct). Si non, déployer une image à jour (procédure de déploiement existante).
2. **Vérifier version client (payload PUT /fields)** — S’assurer que le client déployé envoie bien `field_code` et `field_label` pour les champs. Si l’erreur 422 "Field required" réapparaît, comparer le payload réel avec le schéma API.
3. **Vérifier sérialisation UUID (réponse POST create)** — S’assurer que la version déployée de catalog_sources.py contient la conversion UUID → string dans `_deserialize_source` pour toutes les réponses renvoyant une source.
4. **Usage du proxy API côté client** — S’assurer que le client en production utilise bien le proxy same-origin (ex. `/api/seller`) pour les appels à seller-api, afin de réduire les "Failed to fetch" liés au cross-origin.
5. **Documenter / traiter le flux secret FTP en création** — Soit : (a) en wizard, ne pas enregistrer de connexion FTP sans avoir créé un secret_ref (et guidé l’utilisateur vers la création d’un secret_ref), soit (b) prévoir un flux "créer secret_ref + enregistrer son id" lors de la première config FTP (avec stockage côté Vault, pas en clair). Ne pas stocker le mot de passe en clair.

### F.2 Ordre recommandé

1. Vérifier déploiement API (routes FTP direct) et client (payload fields + proxy).  
2. Vérifier sérialisation UUID (POST create).  
3. Traiter le flux secret_ref / password (design + éventuel PH dédié).

### F.3 Risques / garde-fous

- Toute évolution du flux secret doit rester "secret_ref_id + Vault" ; pas de persistance de mot de passe en clair.
- Les tests sur seller-dev doivent utiliser des credentials de test ; aucun secret réel dans les logs ou rapports.
- Vérifier que `detect-headers-direct` reste limité à la lecture des en-têtes (et éventuellement quelques lignes) pour le matching, sans ingestion de données produits (pas de trigger d’import automatique).

### F.4 Ce qui nécessite un PH séparé

- Implémentation complète du lookup Vault à partir de `secret_ref_id` (actuellement TODO dans `get_ftp_password`).
- Création d’un secret_ref (et enregistrement dans Vault) à partir de la saisie "mot de passe" du wizard, si on souhaite que la connexion FTP soit réutilisable sans ressaisir le mot de passe (UX + sécurité à cadrer dans un PH dédié).

---

## Requêtes SQL de lecture utilisées pour constater l’état

Toutes en SELECT uniquement, sans secret en clair.

```sql
-- Sources du tenant
SELECT id, "tenantId", name, "sourceType", source_kind, source_type_ext, priority, status
FROM seller.catalog_sources
WHERE "tenantId" = :tenant_id
ORDER BY "createdAt" DESC;

-- Champs produits d'une source
SELECT id, source_id, field_code, field_label, required
FROM seller.catalog_source_fields
WHERE source_id = :source_id;

-- Connexion FTP (pas de secret)
SELECT id, source_id, protocol, host, port, username, secret_ref_id
FROM seller.catalog_source_connections
WHERE source_id = :source_id;

-- Fichiers sélectionnés
SELECT id, source_id, remote_path, filename, selected
FROM seller.catalog_source_files
WHERE source_id = :source_id;

-- Mappings de colonnes
SELECT id, source_id, source_column, source_column_index, target_field, transform_rule
FROM seller.catalog_source_column_mappings
WHERE source_id = :source_id;
```

---

## Note sur detect-headers-direct (lecture fichier)

- **Browse FTP** : ne fait que lister répertoires/fichiers (MLSD/NLST/listdir_attr) ; **aucun téléchargement ni lecture de contenu**.
- **Detect-headers-direct** : lit les **premières lignes** du fichier CSV distant (via RETR / open) pour détecter les en-têtes et renvoyer des exemples de valeurs. C’est une **lecture limitée** pour le mapping des colonnes (PH-S02.2), pas une ingestion de données produits. Aucune donnée produit n’est stockée par cet endpoint.

---

## Confirmation obligatoire

- **Aucun fichier SSH modifié.**
- **Aucun secret exposé** (tous les exemples et requêtes sont masqués ou sans valeur réelle).
- **Aucune action PROD** (audit basé sur le code et la structure seller-dev ; pas de déploiement, pas de modification de config ou de base).
- **Aucune modification fonctionnelle effectuée** (diagnostic et rapport uniquement).
