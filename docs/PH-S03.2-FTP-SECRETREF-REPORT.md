# PH-S03.2 — FTP durable via secret_ref (Vault/ESO) + mot de passe temporaire

**Date :** 2026-01-30  
**Périmètre :** seller-dev uniquement. Aucune ingestion, aucun run, aucune logique Amazon.  
**Référence :** PH-S02, PH-S02.1, PH-S03.1.

---

## 1. Objectifs

1. Autoriser un mot de passe FTP **temporaire** pour tester/browse (non stocké).
2. Rendre la connexion FTP **persistante** uniquement si un **secret_ref** (Vault) est attaché.
3. Garantir qu’après création, browse/select-file/detect-headers fonctionnent sans ressaisie grâce au secret_ref.
4. Zéro secret en clair en DB/logs.

---

## 2. Modèle de données (migration additive)

**Fichier :** `keybuzz-seller/migrations/006_ph_s03_2_ftp_auth_mode.sql`

- **Enums ajoutés :**
  - `seller.FtpAuthMode` : `temp_password` | `vault_secret_ref`
  - `seller.FtpLastTestStatus` : `ok` | `error` | `never`

- **Colonnes ajoutées à `seller.catalog_source_connections` :**
  - `auth_mode` : `seller.FtpAuthMode` NOT NULL DEFAULT `vault_secret_ref`
  - `last_test_at` : TIMESTAMP(3) NULL
  - `last_test_status` : `seller.FtpLastTestStatus` NOT NULL DEFAULT `never`
  - `last_test_error` : TEXT NULL

**Règles :**
- `secret_ref_id` peut rester NULL pour un usage “test ponctuel” (temp_password) côté UI ; pour une **connexion enregistrée**, `secret_ref_id` est obligatoire.
- Aucun champ `password` en base (jamais ajouté).

---

## 3. Schéma DB (extrait)

```
seller.catalog_source_connections
├── id, tenant_id, source_id
├── protocol, host, port, username
├── secret_ref_id (FK → seller.secret_refs.id) — OBLIGATOIRE pour connexion persistante
├── auth_mode (temp_password | vault_secret_ref)
├── last_test_at, last_test_status, last_test_error
└── created_at, updated_at
```

---

## 4. Backend (seller-api)

### 4.1 Vault client

- **Fichier :** `keybuzz-seller/seller-api/src/vault_client.py`
- **Fonction :** `get_secret_value(vault_path, key)` → lit Vault KV v2, retourne la valeur ou `None`.
- **Env :** `VAULT_ADDR`, `VAULT_TOKEN` (injection ESO attendue).
- Aucun log de valeur secrète. En cas d’échec : message générique côté appelant (“Secret inaccessible, vérifier configuration”).

### 4.2 Endpoints

| Endpoint | Méthode | Rôle |
|----------|---------|------|
| `POST /api/catalog-sources/{source_id}/ftp/connection` | POST | Créer/mettre à jour connexion **persistante**. Body : `protocol`, `host`, `port`, `username`, **`secret_ref_id`** (obligatoire). **Jamais** de `password`. 400 si `secret_ref_id` manquant. |
| `POST /api/catalog-sources/{source_id}/ftp/test-connection` | POST | Body : `mode: "temp_password"` (credentials dans le body, non stockés) ou `mode: "vault_secret_ref"` (connexion persistante + Vault). Met à jour `last_test_*` uniquement en mode vault_secret_ref. |
| `POST /api/catalog-sources/{source_id}/ftp/browse` | POST | Body : `mode: "temp_password"` (credentials + `path`) ou `mode: "vault_secret_ref"` (`path` seul). Ne télécharge aucun fichier. |
| `POST /api/catalog-sources/{source_id}/ftp/select-file` | POST | **Exige** une connexion durable (`secret_ref_id` non null). 400 sinon. |

### 4.3 Résolution du secret

- `secret_ref_id` → `seller.secret_refs` (tenant-scopé) → `vaultPath`, `vaultKeys`.
- Lecture Vault à la volée via `vault_client.get_secret_value(vault_path, key)` (ex. clé `password`).
- En cas d’échec Vault : statut erreur + message générique, aucun secret en log.

---

## 5. UI seller-client

### 5.1 Onglet Connexion FTP (fiche source)

- **Bloc 1 — Test rapide (temporaire)**  
  Host, port, utilisateur, mot de passe. Boutons “Tester” et “Parcourir”.  
  Message : *“Le mot de passe n’est pas sauvegardé.”*

- **Bloc 2 — Connexion durable (recommandée)**  
  Sélecteur “Secret (Vault)” (liste des secret_refs type FTP_CREDENTIALS), host, port, utilisateur.  
  Bouton “Enregistrer la connexion”.  
  Une fois enregistrée : “Tester la connexion enregistrée” et “Parcourir” sans ressaisie de mot de passe.  
  Si pas de secret_ref : message *“Ajoutez un secret pour rendre la source durable.”*

### 5.2 Règles d’état

- **Sélection de fichier :** possible uniquement si connexion durable (secret_ref). Sinon message : *“Enregistrez une connexion durable pour selectionner”.*
- **Source “Prête” (wizard) :** pour une source FTP, il faut en plus une connexion durable (secret_ref) ; sinon statut “À compléter”.

### 5.3 Wizard création de source

- En étape 3 (FTP), option **“Connexion durable”** : choix optionnel d’un secret existant.
- Si un secret est choisi : à la création, `POST /ftp/connection` avec `secret_ref_id` + host/port/username, puis `POST /ftp/select-file` pour chaque fichier.
- Si aucun secret : pas d’appel à `POST /ftp/connection` ni `POST /ftp/select-file` ; la source reste “À compléter”, à finaliser depuis la fiche source.

---

## 6. Preuves attendues (validation)

**Preuves post-déploiement (procédures + emplacements) :** voir l’addendum **[PH-S03.2B-POSTDEPLOY-PROOFS.md](./PH-S03.2B-POSTDEPLOY-PROOFS.md)** — prérequis (ESO, secret_ref), tests A→E, garde-fous API, DB, logs (sans secret).

| Cas | Attendu | Preuve |
|-----|---------|--------|
| **A) Temp password** | Test connexion OK, browse OK. Recharger la page : browse nécessite ressaisie du mot de passe. | UI + screenshots (addendum A). |
| **B) Persistant (secret_ref)** | Créer/choisir secret_ref, enregistrer connexion durable. Tester connexion OK sans mot de passe. Browse OK. Select-file OK. Recharger : browse fonctionne toujours. | UI + screenshots (addendum B). |
| **C) Garde-fous API** | /select-file sans connexion durable → 400 ; /connection sans secret_ref_id → 400/422. | Extraits réponse API masqués (addendum C). |
| **D) No secrets in DB** | `SELECT` sur `seller.catalog_source_connections` : host, port, username, secret_ref_id ; aucun champ password. | Extrait SELECT (addendum D). |
| **E) No secrets in logs** | Grep logs seller-api : 0 fuite (password, VAULT_TOKEN, etc.). | Compteur ou extrait (addendum E). |

---

## 7. Rollback

- **Tag image** immuable avant/après.
- **Revert PR** (seller-api + seller-client + infra).
- **Migration 006** : additive uniquement (nouvelles colonnes, valeurs par défaut). Pas de downgrade obligatoire ; en cas de revert code, les colonnes restent sans impact fonctionnel si l’ancien code ne les lit pas.

---

## 8. Fichiers modifiés / ajoutés

| Dépôt / chemin | Fichier | Rôle |
|----------------|---------|------|
| keybuzz-seller/migrations | `006_ph_s03_2_ftp_auth_mode.sql` | Enums + colonnes auth_mode, last_test_* |
| keybuzz-seller/seller-api/src | `vault_client.py` | Lecture Vault KV v2 (get_secret_value) |
| keybuzz-seller/seller-api/src/routes | `ftp.py` | POST connection (secret_ref only), POST test-connection (body mode), POST browse (body mode), select-file 400 si pas secret_ref |
| keybuzz-seller/seller-api/src/schemas | `ftp_connection.py` | FtpConnectionCreate (secret_ref_id requis, pas de password), FtpTestConnectionBody, FtpBrowseBody |
| keybuzz-seller/seller-client | `FtpConnection.tsx` | Deux blocs Test rapide + Connexion durable, POST test/browse avec body |
| keybuzz-seller/seller-client | `page.tsx` (wizard) | secretRefId optionnel, POST /connection uniquement si secretRefId, statut ready avec hasDurableFtp |

---

## 9. Confirmation

- Aucun secret en clair en DB ni dans les logs.
- Aucun champ password en base (même chiffré).
- Aucune modification SSH / config bastion.
- Aucune action PROD.
- DEV uniquement (seller-dev). GitOps uniquement.
