# PH-S03.4 — Suppression totale + mapping hors wizard (seller-dev)

**Date :** 2026-01-30  
**Périmètre :** Suppression totale (hard delete) d’une source et de toutes ses dépendances ; recréation immédiate possible avec le même nom ; wizard simplifié (sans matching) ; onglet « Colonnes (CSV) » en fiche source.  
**Environnement :** keybuzz-seller-dev (namespace keybuzz-seller-dev) uniquement.

**Règles :** DEV only, GitOps only, aucun secret en clair, pas de kubectl apply / set image.

---

## 1. Contexte et objectifs

- **Bug bloquant :** Après suppression d’une source, recréation impossible (« Une source avec le nom X existe déjà »).
- **UX :** Le matching CSV dans le wizard rendait le flux fragile.
- **Objectifs :**
  - **A)** Suppression totale (hard delete) d’une source et de toutes ses dépendances.
  - **B)** Recréation immédiate possible avec le même nom (201 Created, pas 409).
  - **C)** Wizard simplifié : ne fait plus le matching (FTP simple + sélection de fichiers + création).
  - **D)** Mapping accessible après création depuis la fiche source (onglet « Colonnes (CSV) »).

---

## 2. Partie 1 — Diagnostic (delete vs unique)

### Contrainte d’unicité

- **Table :** `seller.catalog_sources`
- **Contrainte :** `UNIQUE ("tenantId", "name")` (migration 001 : `seller_catalog_sources_tenantId_name_key`).
- Après suppression réelle de la ligne, la contrainte ne bloque plus la recréation avec le même nom.

### Comportement DELETE avant correctif

- **Endpoint :** `DELETE /api/catalog-sources/{id}` (seller-api).
- **Ordre des suppressions :** `catalog_source_files` → `catalog_source_connections` → `catalog_source_fields` → `catalog_sources`.
- **Manque :** Les tables `catalog_source_column_mappings` et `catalog_source_detected_headers` n’étaient pas supprimées explicitement ; elles dépendent de `catalog_sources` avec `ON DELETE CASCADE`. Pour un hard delete explicite et cohérent, elles sont incluses dans le flux de suppression.

### Preuves read-only (à exécuter en DB)

```sql
-- Avant delete (source "Wortmann" existe)
SELECT id, name, "tenantId" FROM seller.catalog_sources WHERE name = 'Wortmann';
SELECT COUNT(*) FROM seller.catalog_source_connections WHERE source_id = '<id>';
SELECT COUNT(*) FROM seller.catalog_source_files WHERE source_id = '<id>';
SELECT COUNT(*) FROM seller.catalog_source_column_mappings WHERE source_id = '<id>';

-- Après delete (même requêtes → 0 ligne pour catalog_sources, 0 pour les enfants)
```

---

## 3. Partie 2 — Fix « suppression totale »

### Choix : hard delete explicite + ordre enfants → parent

**Fichier modifié :** `keybuzz-seller/seller-api/src/routes/catalog_sources.py`

- **Ordre des DELETE :**
  1. `catalog_source_column_mappings` (source_id + tenant_id)
  2. `catalog_source_detected_headers` (source_id + tenant_id)
  3. `catalog_source_files`
  4. `catalog_source_connections`
  5. `catalog_source_fields`
  6. `catalog_sources`
- **Idempotence :** Si la source n’existe pas (déjà supprimée), réponse **404** (pas de 204 en double). Comportement déjà assuré par la vérification d’existence en début de handler.
- **UI :** Après delete, `loadSources()` est appelé et la liste est rafraîchie ; si la source supprimée était ouverte en détail, le panneau est fermé (`setShowDetail(false)`, `setSelectedSource(null)`).

### Critère de sortie DELETE (non négociable)

1. Créer une source « Wortmann ».
2. Supprimer la source « Wortmann ».
3. Recréer « Wortmann » immédiatement → **201 Created** (pas 409).

---

## 4. Partie 3 — Sortir le matching du wizard

### Wizard simplifié

- **Étapes avec FTP :** 1 = origine, 2 = type, 3 = connexion FTP, 4 = parcourir / sélectionner fichier(s), **5 = finalisation** (nom, description, priorité, champs produits, bouton Créer).
- **Étapes sans FTP :** 1 = origine, 2 = type, 3 = finalisation.
- **Supprimé du wizard :** L’étape « Mapping des colonnes » (détection des en-têtes + mapping colonne → champ produit). Plus d’appel à `detect-headers-direct` ni à `column-mappings/bulk` dans le wizard.

**Fichier modifié :** `keybuzz-seller/seller-client/app/(dashboard)/catalog-sources/page.tsx`

- `totalSteps` avec FTP : **5** (au lieu de 6).
- `getStepTitle` : étape 5 = « Finalisation ».
- `canProceed` : étape 5 = `!!data.name` (plus de condition sur les mappings).
- `handleNext` : plus d’appel à `detectHeaders()` en passant à l’étape suivante.
- `createSource()` : plus d’appel à `column-mappings/bulk` ; `isReady` pour le statut de la source = `hasFiles && hasDurableFtp` (mapping SKU fait après création dans la fiche source).

### Après création

- Redirection vers la fiche source (comportement existant en cas de succès partiel).
- Badge « À compléter » tant que le mapping SKU n’est pas fait (onglet « Colonnes (CSV) »).

---

## 5. Partie 4 — Onglet « Colonnes (CSV) » sur la fiche source

### Fiche source : onglets

- **Infos :** Statut, type, priorité, description, champs produits configurés (existant).
- **Connexion FTP :** Composant existant `FtpConnection` (connexion durable, parcours, sélection de fichiers).
- **Colonnes (CSV) :** Nouvel onglet (affiché uniquement si la source est de type FTP/CSV, ex. `ftp_csv`, `ftp_xml`, `http_file`).

### Contenu de l’onglet « Colonnes (CSV) »

1. **Liste des fichiers sélectionnés :** Appel `GET /api/catalog-sources/{source_id}/ftp/files` ; choix du fichier pour la détection (dropdown).
2. **Bouton « Détecter les colonnes » :** Appel `POST /api/catalog-sources/{source_id}/column-mappings/detect-headers` avec `{ file_path, encoding, has_header_row }`. Utilise la **connexion persistante** de la source (Vault). Lecture limitée (en-têtes / premières lignes, pas d’ingestion complète).
3. **Tableau mapping :** Colonne détectée → dropdown « Champ produit » (SKU obligatoire pour considérer le mapping valide).
4. **Bouton « Enregistrer le mapping » :** Appel `POST /api/catalog-sources/{source_id}/column-mappings/bulk` avec les mappings saisis. Vérification côté client : au moins un mapping dont le champ cible est SKU.

### Statut « Prête »

- La source est considérée **Prête** seulement si :
  - au moins un fichier sélectionné ;
  - connexion durable (secret_ref) si FTP ;
  - mapping SKU présent (onglet Colonnes (CSV)).
- Jusque-là, badge « À compléter » et statut `to_complete` ou équivalent.

### API : détection des en-têtes par source (connexion persistante)

**Fichier modifié :** `keybuzz-seller/seller-api/src/routes/column_mapping.py`

- **Nouvel endpoint :** `POST /api/catalog-sources/{source_id}/column-mappings/detect-headers`
- **Body :** `DetectHeadersRequest` (`file_path`, `encoding`, `delimiter`, `has_header_row`).
- **Comportement :** Vérification que la source existe et appartient au tenant ; récupération de la config de connexion FTP de la source (`get_connection_config`) ; mot de passe depuis Vault (`get_ftp_password`) ; connexion FTP (`connect_ftp`) ; lecture limitée des en-têtes via `read_csv_headers_from_ftp` ; réponse `DetectHeadersResponse` (headers, sample_values, encoding, delimiter). Aucune ingestion complète du CSV.

---

## 6. Fichiers modifiés

| Fichier | Modification |
|--------|----------------|
| `keybuzz-seller/seller-api/src/routes/catalog_sources.py` | DELETE : suppression explicite de `catalog_source_column_mappings` et `catalog_source_detected_headers` avant les autres tables ; commentaire PH-S03.4 + idempotence (404 si source absente). |
| `keybuzz-seller/seller-api/src/routes/column_mapping.py` | Import `get_connection_config`, `get_ftp_password`, `connect_ftp` depuis `ftp` ; `DetectHeadersRequest` ; nouveau `POST /detect-headers` sur `source_router` (détection via connexion persistante). |
| `keybuzz-seller/seller-client/app/(dashboard)/catalog-sources/page.tsx` | Wizard : totalSteps 5 avec FTP ; suppression étape mapping ; createSource sans bulk mapping ; DetailModal : onglets Infos / Connexion FTP / Colonnes (CSV) ; composant `SourceColumnMappingTab` (fichiers, détecter, tableau mapping, enregistrer). |
| `keybuzz-infra/docs/PH-S03.4-DELETE-AND-MAPPING-REWORK.md` | Ce rapport. |

---

## 7. Preuves obligatoires (à compléter après tests)

### A) Delete

- Screenshot liste avant delete (ex. « Wortmann » existe).
- Screenshot liste après delete (« Wortmann » disparu).
- Screenshot wizard recréation « Wortmann » → 201 OK.

### B) Wizard simplifié

- Screenshot du wizard sans étape « Mapping des colonnes » (5 étapes avec FTP : origine, type, connexion, fichiers, finalisation).

### C) Mapping post-création

- Screenshot onglet « Colonnes (CSV) » avec mapping SKU enregistré (et éventuellement « Enregistrer le mapping » utilisé).

### D) Network / HTTP

- `DELETE /api/catalog-sources/{id}` → **204**.
- `POST /api/catalog-sources` (recréation même nom) → **201** (pas 409).
- `POST /api/catalog-sources/{id}/column-mappings/detect-headers` → 200 (success) ou 400/404 selon cas.
- `POST /api/catalog-sources/{id}/column-mappings/bulk` → 201.

---

## 8. Rollback

- **API :** Revert des commits sur `catalog_sources.py` (DELETE sans column_mappings/detected_headers) et sur `column_mapping.py` (suppression du `POST /detect-headers`).
- **Client :** Revert des commits sur `page.tsx` (wizard 6 étapes avec mapping, DetailModal sans onglets / sans `SourceColumnMappingTab`).
- **DB :** Aucune migration ajoutée ; les tables et contraintes existantes sont inchangées. Aucune action manuelle DB requise pour annuler le correctif.

---

## 9. Stop conditions (non rencontrées)

- La suppression ne nécessite **pas** d’action manuelle DB : tout est fait par l’API dans l’ordre enfants → parent.
- Aucune contrainte unique n’est laissée dans un état empêchant la recréation : la ligne est bien supprimée, la contrainte `(tenantId, name)` permet de recréer avec le même nom.
- La détection des en-têtes (wizard supprimé, onglet Colonnes (CSV)) ne déclenche **pas** une ingestion complète du CSV : lecture limitée (en-têtes / premières lignes) uniquement.

**Statut :** Implémentation réalisée. Preuves A/B/C/D et screenshots à collecter lors des tests manuels sur seller-dev.
