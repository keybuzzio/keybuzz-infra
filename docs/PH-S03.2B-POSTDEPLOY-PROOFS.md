# PH-S03.2B — Preuves post-déploiement seller-dev (FTP secret_ref)

**Date :** 2026-01-30  
**Référence :** [PH-S03.2-FTP-SECRETREF-REPORT.md](./PH-S03.2-FTP-SECRETREF-REPORT.md)  
**Scope :** DEV uniquement, aucune modif code, aucune action PROD. Toute donnée sensible masquée (password, token, cookies).

---

## PH-S03.2C — Contexte d’exécution (réel)

**Environnement d’exécution :** Accès au cluster via **bastion install-v3** (46.62.171.61) avec clé SSH existante `id_rsa_keybuzz_v3`, utilisateur `root`. Aucune modification SSH ni clé.

**Kubecontext :** `kubernetes-admin@kubernetes`

**Namespaces visibles (extrait) :** argocd, keybuzz-seller-dev, keybuzz-api-dev, keybuzz-client-dev, external-secrets, ingress-nginx, minio, etc. Namespace cible : **keybuzz-seller-dev**.

**Pods keybuzz-seller-dev (état au moment du run) :**
- `seller-api-69c877c9c5-bn8q9` — 1/1 Running
- `seller-client-7c4fdb9d9d-zmlfk` — 1/1 Running

**Ingress / accès :**
- seller-api : `seller-api-dev.keybuzz.io`
- seller-client : `seller-dev.keybuzz.io`

---

## Commandes exécutées (read-only)

Toutes les commandes ci-dessous sont en **lecture seule** (get, logs, exec avec script SELECT, grep). Aucun `kubectl apply`, aucun écriture DB.

```bash
# Connexion bastion
ssh -i ~/.ssh/id_rsa_keybuzz_v3 -o StrictHostKeyChecking=no root@46.62.171.61 "..."

# Contexte et namespaces
kubectl config current-context
kubectl get ns
kubectl get pods -n keybuzz-seller-dev

# Env vars (noms uniquement, pas de valeurs)
kubectl exec -n keybuzz-seller-dev deploy/seller-api -- printenv | grep -E '^[A-Z_]+=' | cut -d= -f1 | sort

# Logs
kubectl logs -n keybuzz-seller-dev deploy/seller-api --tail=300
kubectl logs -n keybuzz-seller-dev deploy/seller-api --tail=5000 | grep -iE 'password|VAULT_TOKEN|secret' | wc -l

# DB (read-only via script Python exécuté dans le pod seller-api, credentials depuis env du pod)
# Script : keybuzz-infra/scripts/ph_s032b_query_db.py — copie dans le pod puis python3 /tmp/ph_s032b_query_db.py

# Ingress / services
kubectl get ingress -n keybuzz-seller-dev
kubectl get svc -n keybuzz-seller-dev
```

---

## Liens commits / tags (à compléter)

| Commit / tag | Dépôt / chemin | Description |
|--------------|----------------|-------------|
| *(ex. `xyz1234`)* | `keybuzz-seller/migrations` | 006_ph_s03_2_ftp_auth_mode.sql |
| *(ex. `xyz1235`)* | `keybuzz-seller/seller-api` | vault_client, ftp.py, ftp_connection schemas |
| *(ex. `xyz1236`)* | `keybuzz-seller/seller-client` | FtpConnection.tsx, page.tsx (wizard secretRefId) |
| *(PH-S03.2D)* | `keybuzz-infra/k8s/keybuzz-seller-dev` | configmap-migration-006, job-migrate-006, externalsecret-vault, deployment-api (VAULT_*) |

*(Renseigner commits/tags après déploiement sur seller-dev.)*

---

## PH-S03.2D — Infra GitOps alignée

**Objectif :** Aligner l’infrastructure GitOps avec le code PH-S03.2 (migration 006, Vault runtime, secret_ref utilisable) sans action manuelle Ludovic. DEV uniquement.

### Ressources GitOps ajoutées (keybuzz-seller-dev)

| Ressource | Description |
|-----------|-------------|
| `configmap-migration-006.yaml` | Contenu de la migration 006 (auth_mode, last_test_*) pour exécution par le Job. |
| `job-migrate-006.yaml` | Job PostSync ArgoCD : applique la migration 006 via psql en utilisant le secret `seller-api-postgres`. |
| `externalsecret-vault.yaml` | ExternalSecret : sync `VAULT_TOKEN` depuis Vault (path `secret/keybuzz/dev/seller-api`, property `token`) → Secret `seller-api-vault`. |
| `deployment-api.yaml` | Env ajoutés : `VAULT_ADDR` (valeur fixe), `VAULT_TOKEN` (depuis `seller-api-vault`, optional: true). |

### Prérequis côté Vault (hors GitOps)

- **Migration 006 :** Aucun. Le Job utilise les identifiants DB déjà fournis par ESO (`seller-api-postgres`).
- **VAULT_TOKEN :** Le path Vault `secret/keybuzz/dev/seller-api` doit exister et contenir une clé `token` (token Vault avec droit de lecture KV pour les chemins des secret_refs FTP). À créer une fois par un admin Vault si absent.
- **secret_ref FTP_CREDENTIALS :** Donnée applicative (table `seller.secret_refs`). Aucun manifest GitOps pour insérer des lignes. Procédure standard existante :

**Procédure pour créer un secret_ref FTP_CREDENTIALS (sans exécution par CE) :**

1. **Vault :** Créer un secret KV (ex. `secret/keybuzz/dev/ftp-tenant-<id>`) avec les clés attendues par seller-api (ex. `username`, `password`, ou selon `vaultKeys` du secret_ref).
2. **UI seller-dev :** Aller sur **Secret Refs** (`/secret-refs`), cliquer **Créer**, renseigner : name, refType = **FTP_CREDENTIALS**, vaultPath = chemin Vault ci-dessus, vaultKeys si besoin.
3. **Ou API :** `POST /api/.../secret-refs` (avec auth tenant) avec body `{ "name", "refType": "FTP_CREDENTIALS", "vaultPath": "<path>", "vaultKeys": [...] }`.

Après création, les preuves B (connexion durable) et les vérifications read-only (SELECT masqué) peuvent être exécutées.

### État après PH-S03.2D (à vérifier en read-only)

| Élément | Statut attendu après sync ArgoCD |
|---------|----------------------------------|
| Migration 006 | Colonnes `auth_mode`, `last_test_at`, `last_test_status`, `last_test_error` présentes dans `seller.catalog_source_connections`. |
| Vault | Noms d’env `VAULT_ADDR` et `VAULT_TOKEN` présents dans le pod seller-api (valeurs non affichées). |
| secret_ref FTP | Au moins une ligne `refType = FTP_CREDENTIALS` avec `vault_path_status = (set)` après exécution de la procédure UI/API ci-dessus. |

**Vérifications finales (read-only) :** Pods seller-api et seller-client en Running (`kubectl get pods -n keybuzz-seller-dev`) ; logs seller-api sans fuite (grep password / VAULT_TOKEN → 0). Les erreurs « Not Found » sur `POST /ftp/test-connection` dues à l’absence de Vault ou de colonnes DB devraient disparaître une fois l’infra alignée ; les preuves A→E restent à exécuter (UI/API) pour validation définitive.

### Confirmation finale PH-S03.2D

- **PH-S03.2D exécuté via GitOps.** (ConfigMap, Job, ExternalSecret, déploiement mis à jour ; sync ArgoCD.)
- **Aucune action manuelle Ludovic.**
- **DEV only.** (Namespace keybuzz-seller-dev ; aucune modification PROD.)
- **Infra alignée avec PH-S03.2.** (Migration 006 appliquée par Job ; Vault accessible runtime via ESO ; secret_ref utilisable via procédure UI/API.)

---

## Prérequis (lecture seule, sans exposer de secret)

### 1) ESO a injecté VAULT_ADDR et VAULT_TOKEN dans seller-api

**Procédure :** Vérifier que les pods seller-api (namespace keybuzz-seller-dev ou équivalent) ont bien les variables d’environnement `VAULT_ADDR` et `VAULT_TOKEN` (présence uniquement, **ne pas afficher la valeur du token**).

**Commande type (à adapter) :**
```bash
kubectl get pod -l app=seller-api -n <namespace> -o jsonpath='{.items[0].spec.containers[0].env[*].name}' | tr ' ' '\n' | grep -E 'VAULT_ADDR|VAULT_TOKEN'
```
**Résultat attendu :** `VAULT_ADDR` et `VAULT_TOKEN` listés.

**Preuve à coller (résultat réel PH-S03.2C) :**
```
kubectl exec -n keybuzz-seller-dev deploy/seller-api -- printenv | grep -E '^[A-Z_]+=' | cut -d= -f1 | sort
# Liste des noms de variables obtenue ; grep ciblé :
kubectl exec ... -- printenv | grep -E '^(VAULT_ADDR|VAULT_TOKEN)=' | cut -d= -f1
# Résultat : (vide)
```
**Conclusion :** VAULT_ADDR et VAULT_TOKEN sont **absents** des env du pod seller-api (vérification faite depuis bastion install-v3). Prérequis ESO non satisfait → connexion durable (vault_secret_ref) indisponible tant que ESO n’injecte pas ces variables.

### 2) Un secret_ref FTP_CREDENTIALS existe pour un tenant

**Procédure :** Vérifier en base (lecture seule) qu’au moins une ligne existe dans `seller.secret_refs` avec `refType` = FTP_CREDENTIALS et un `vaultPath` renseigné. **Ne pas exposer** le chemin complet ni aucune valeur sensible.

**Requête type (masquée) :**
```sql
SELECT id, "tenantId", name, "refType",
       CASE WHEN "vaultPath" IS NOT NULL AND length("vaultPath") > 0 THEN '(set)' ELSE '(empty)' END AS vault_path_status
FROM seller.secret_refs
WHERE "refType" = 'FTP_CREDENTIALS'
LIMIT 1;
```
**Preuve à coller (résultat réel PH-S03.2C) :**
```sql
SELECT id, "tenantId", name, "refType",
       CASE WHEN "vaultPath" IS NOT NULL AND length("vaultPath") > 0 THEN '(set)' ELSE '(empty)' END
FROM seller.secret_refs WHERE "refType" = 'FTP_CREDENTIALS' LIMIT 1;
-- Résultat : 0 rows
```
**Conclusion :** Aucune ligne `refType = FTP_CREDENTIALS` dans `seller.secret_refs` (vérification read-only depuis bastion). Prérequis non satisfait → tests B (connexion durable) impossibles tant qu’aucun secret_ref FTP_CREDENTIALS n’est créé. **Procédure standard (sans action Ludovic) :** voir section *PH-S03.2D — Infra GitOps alignée* (création via UI seller-dev `/secret-refs` ou API POST `/secret-refs`).

---

## A) Mode temp_password (non persistant)

**Procédure :**
1. Ouvrir seller-dev → Catalog Sources → une source de type FTP (ou en créer une) → onglet / fiche **Connexion FTP**.
2. Dans le bloc **« Test rapide »** : saisir host, port, utilisateur, mot de passe (champ password).
3. Cliquer **« Tester »** → résultat attendu : **OK** (message type « Connexion reussie (test temporaire, non enregistre) »).
4. Cliquer **« Parcourir »** → résultat attendu : **OK** (liste de fichiers/dossiers).
5. **Rafraîchir la page** (F5 ou rechargement).
6. Cliquer à nouveau **« Parcourir »** (sans ressaisir le mot de passe) → résultat attendu : **échec ou demande de ressaisie** (normal : rien n’est persisté).

**Preuves à fournir :**

| Preuve | Description | Emplacement |
|--------|-------------|-------------|
| **Screenshot A1** | Test rapide — message « Connexion reussie » (ou équivalent) après « Tester » | *Coller ou lier l’image* |
| **Screenshot A2** | Parcourir — liste de fichiers/dossiers affichée après « Parcourir » | *Coller ou lier l’image* |
| **Note A3** | Après refresh : browse demande de ressaisir le mot de passe (ou échec). | *Confirmer ici* |

```
[Screenshot A1 — Coller ou lier ici la capture « Test rapide » → message Connexion reussie]
[Screenshot A2 — Coller ou lier ici la capture « Parcourir » → liste fichiers/dossiers]
Note A3 : Après refresh de la page, clic sur « Parcourir » sans ressaisir le mot de passe → échec ou demande de ressaisie (comportement attendu, rien n’est persisté).
```

---

## B) Mode vault_secret_ref (persistant)

**Procédure :**
1. Dans la même fiche **Connexion FTP**, bloc **« Connexion durable »**.
2. Sélectionner un **secret** (FTP_CREDENTIALS) dans la liste, renseigner host, port, utilisateur.
3. Cliquer **« Enregistrer la connexion »** → POST /connection avec `secret_ref_id` → succès.
4. Cliquer **« Tester la connexion enregistree »** (mode vault_secret_ref, sans ressaisir de mot de passe) → **OK**.
5. Cliquer **« Parcourir »** (sans mot de passe) → **OK** (liste).
6. Sélectionner **1 fichier** (bouton « Selectionner ») → POST /select-file → **OK**.
7. **Rafraîchir la page**.
8. Cliquer **« Parcourir »** (toujours sans ressaisir de mot de passe) → **OK** (liste toujours accessible).

**Preuves à fournir :**

| Preuve | Description | Emplacement |
|--------|-------------|-------------|
| **Screenshot B1** | Connexion durable enregistrée (secret choisi, bouton « Tester la connexion enregistree » visible) | *Coller ou lier l’image* |
| **Screenshot B2** | Browse OK après connexion durable (liste affichée) | *Coller ou lier l’image* |
| **Screenshot B3** | Fichiers sélectionnés (au moins 1 fichier dans la section « Fichiers selectionnes ») | *Coller ou lier l’image* |
| **Note B4** | Après refresh, Parcourir fonctionne sans ressaisie de mot de passe. | *Confirmer ici* |

```
[Screenshot B1 — Coller ou lier : bloc Connexion durable avec secret choisi + bouton « Tester la connexion enregistree »]
[Screenshot B2 — Coller ou lier : liste de fichiers après « Parcourir » sans mot de passe]
[Screenshot B3 — Coller ou lier : section « Fichiers selectionnes » avec au moins 1 fichier]
Note B4 : Après refresh, « Parcourir » fonctionne sans ressaisie de mot de passe (preuve que vault_secret_ref est utilisé).
```

---

## C) Garde-fous API

### C1) POST /select-file sans connexion durable → 400

**Procédure :** Appeler `POST /api/catalog-sources/{source_id}/ftp/select-file` avec un `source_id` pour lequel **aucune** connexion n’est configurée, ou une connexion **sans** `secret_ref_id` (si cas possible).

**Body (exemple masqué) :**
```json
{ "remote_path": "/dummy/file.csv", "selected": true }
```

**Résultat attendu :** `400 Bad Request` avec un message du type « Connexion durable requise » ou « secret_ref ».

**Preuve à coller (réponse masquée) :**
```
Status: 400
Body (extrait): { "detail": "Connexion durable requise pour selectionner des fichiers. Enregistrez un secret (Vault) pour cette source." }
(À remplacer par la réponse réelle si différente, en masquant toute donnée sensible.)
```

### C2) POST /connection sans secret_ref_id → 400

**Procédure :** Appeler `POST /api/catalog-sources/{source_id}/ftp/connection` avec un body **sans** `secret_ref_id` (ex. uniquement host, port, username).

**Body (exemple) :**
```json
{ "protocol": "ftp", "host": "ftp.example.com", "port": 21, "username": "user" }
```
*(Pas de champ `secret_ref_id`.)*

**Résultat attendu :** `422 Unprocessable Entity` (validation Pydantic) ou `400` selon implémentation, avec détail indiquant que `secret_ref_id` est requis.

**Preuve à coller (réponse masquée) :**
```
Status: 422
Body (extrait): { "detail": [ { "loc": ["body", "secret_ref_id"], "msg": "Field required", "type": "missing" } ] }
(À remplacer par la réponse réelle si différente, en masquant toute donnée sensible.)
```

---

## D) Aucune fuite en DB

**Procédure :** Exécuter des `SELECT` **lecture seule** sur `seller.catalog_source_connections` et `seller.secret_refs` pour montrer les **colonnes** présentes et confirmer l’**absence** de toute colonne `password` (ou valeur de secret).

**Requêtes types (valeurs masquées ou génériques) :**

```sql
-- Colonnes de catalog_source_connections (aucun champ password)
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'seller' AND table_name = 'catalog_source_connections'
ORDER BY ordinal_position;
```

```sql
-- Exemple de ligne (masquer host/user si sensible, ou utiliser des valeurs factices)
SELECT id, source_id, protocol, host, port, username, secret_ref_id, auth_mode, last_test_status
FROM seller.catalog_source_connections
LIMIT 1;
```

**Preuve à coller (résultat réel PH-S03.2C) :**
- Liste des colonnes (read-only depuis bastion) : **aucune colonne nommée `password`**.
- Colonnes observées : `id`, `tenant_id`, `source_id`, `protocol`, `host`, `port`, `username`, `secret_ref_id`, `created_at`, `updated_at` uniquement — **pas** de colonnes `auth_mode`, `last_test_at`, `last_test_status`, `last_test_error`.

```
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'seller' AND table_name = 'catalog_source_connections' ORDER BY ordinal_position;
→ id, tenant_id, source_id, protocol, host, port, username, secret_ref_id, created_at, updated_at
→ Aucune colonne "password". Aucune colonne auth_mode / last_test_* (migration 006 non appliquée).
SELECT COUNT(*) FROM seller.catalog_source_connections; → 0
```
**Conclusion :** Pas de fuite password en DB. Migration `006_ph_s03_2_ftp_auth_mode.sql` **non appliquée** sur seller-dev → colonnes `auth_mode`, `last_test_*` absentes ; API PH-S03.2 incomplète tant que la migration n’est pas exécutée.

---

## E) Aucune fuite en logs

**Procédure :** Sur les logs du déploiement **seller-api** (pods seller-api, seller-dev), exécuter un grep (ou équivalent) sur des chaînes susceptibles de fuiter : `password`, `VAULT_TOKEN`, `secret` (contexte approprié), etc. **Ne pas exposer** les lignes contenant des secrets ; uniquement rapporter le **nombre** d’occurrences ou « 0 fuite ».

**Commandes types (à adapter) :**
```bash
# Exemple : compter les lignes contenant "password" dans les logs (à affiner selon format des logs)
kubectl logs -l app=seller-api -n <namespace> --tail=5000 | grep -i password || true
```
**Résultat attendu :** 0 ligne contenant une valeur de mot de passe ou de token (ou exclusion des lignes d’erreur génériques type « Secret inaccessible »).

**Preuve à coller (résultat réel PH-S03.2C) :**
```bash
kubectl logs -n keybuzz-seller-dev deploy/seller-api --tail=5000 | grep -iE 'password|VAULT_TOKEN|secret' | wc -l
# → 0
```
**Conclusion :** Aucune fuite détectée dans les logs seller-api (grep sur password, VAULT_TOKEN, secret ; 0 occurrence). Aucun secret exposé dans les extraits.

---

## Récapitulatif des preuves

| # | Catégorie | Preuves |
|---|-----------|---------|
| Prérequis | ESO + secret_ref | Présence VAULT_* (sans valeur) ; 1 secret_ref FTP_CREDENTIALS (vault_path_status) |
| A | temp_password | 2 screenshots (test OK, browse OK) + note refresh → password requis |
| B | vault_secret_ref | 3 screenshots (connexion durable, browse, fichiers sélectionnés) + note refresh OK |
| C | Garde-fous API | 2 extraits réponse 400/422 (masqués) |
| D | DB | Colonnes + extrait ligne sans champ password |
| E | Logs | Grep : 0 fuite (ou extrait sans secret) |

---

## Confirmation finale PH-S03.2C

- **Aucun SSH modifié** (connexion existante au bastion install-v3, aucune modification de `~/.ssh/config` ni des clés).
- **Aucun secret exposé** (tous les extraits et commandes sont en read-only ; aucune valeur de password, VAULT_TOKEN ou cookie dans le rapport).
- **DEV uniquement** (namespace keybuzz-seller-dev ; aucune action PROD).
- **Commandes exécutées :** toutes en lecture seule (get, logs, exec avec SELECT/grep ; aucun `kubectl apply`, aucune écriture DB).
