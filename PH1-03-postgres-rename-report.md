# PH1-03 – Renommage des serveurs PostgreSQL dans Hetzner

**Ticket:** KEY-11 (PH1-03)  
**Date:** 2024-11-30  
**Statut:** ✅ Renommage effectué (2/3 serveurs)

## Résumé technique

### Ce qui a été fait

1. **Identification des serveurs PostgreSQL** ✅
   - Serveurs identifiés via API Hetzner par IP publique
   - 2 serveurs trouvés et renommés avec succès

2. **Renommage effectué** ✅
   - `db-master-01` → `db-postgres-01` ✅
   - `db-slave-01` → `db-postgres-02` ✅
   - `db-slave-02` → `db-postgres-03` ⚠️ (serveur non trouvé dans Hetzner)

### Détails des renommages

#### Serveur 1: db-master-01 → db-postgres-01 ✅

- **Server ID:** 109781629
- **IP Publique:** 195.201.122.106
- **IP Privée:** 10.0.0.120
- **Ancien nom:** db-master-01
- **Nouveau nom:** db-postgres-01
- **Statut:** ✅ Renommé avec succès
- **Commande exécutée:**
  ```bash
  hcloud server update 109781629 --name db-postgres-01
  ```

#### Serveur 2: db-slave-01 → db-postgres-02 ✅

- **Server ID:** 109783838
- **IP Publique:** 91.98.169.31
- **IP Privée:** 10.0.0.121
- **Ancien nom:** db-slave-01
- **Nouveau nom:** db-postgres-02
- **Statut:** ✅ Renommé avec succès
- **Commande exécutée:**
  ```bash
  hcloud server update 109783838 --name db-postgres-02
  ```

#### Serveur 3: db-slave-02 → db-postgres-03 ⚠️

- **IP Publique attendue:** 65.21.251.198
- **IP Privée attendue:** 10.0.0.122
- **Statut:** ⚠️ Serveur non trouvé dans Hetzner Cloud
- **Raison:** Le serveur avec l'IP 65.21.251.198 n'existe pas dans le compte Hetzner
- **Action:** Le serveur n'a pas pu être renommé car il n'existe pas

### Commandes exécutées

```bash
# Script Python utilisé (API Hetzner directe)
source /opt/keybuzz/credentials/hcloud.env
export HETZNER_API_TOKEN
python3 /tmp/rename-postgres-api.py
```

### Vérification finale

**Serveurs PostgreSQL dans Hetzner après renommage:**
- ✅ `db-postgres-01` (ID: 109781629, IP: 195.201.122.106, Status: running)
- ✅ `db-postgres-02` (ID: 109783838, IP: 91.98.169.31, Status: running)
- ⚠️ `db-postgres-03` (non trouvé dans Hetzner)

**Total serveurs PostgreSQL dans Hetzner:** 2/3

### Fichiers GitHub - Vérification de cohérence

#### servers_v3.tsv ✅
- Ligne 10: `db-postgres-01` (195.201.122.106) ✅
- Ligne 11: `db-postgres-02` (91.98.169.31) ✅
- Ligne 12: `db-postgres-03` (65.21.251.198) ✅ (défini mais serveur non créé)

#### rebuild_order_v3.json ✅
- Contient `db-postgres-01`, `db-postgres-02`, `db-postgres-03` ✅

#### ansible/inventory/hosts.yml ✅
- Groupe `db_postgres` contient les 3 serveurs ✅

**Note:** Les fichiers GitHub sont cohérents avec la configuration attendue. Le serveur `db-postgres-03` est défini dans l'inventaire mais n'existe pas encore dans Hetzner Cloud.

### Fichiers modifiés

**Scripts créés:**
- `scripts/rename-postgres-api.py` - Script Python utilisant l'API Hetzner directe
- `scripts/find-and-rename-db-slave-02.py` - Script de recherche pour db-slave-02

**Aucune modification nécessaire dans les fichiers versionnés** - Les fichiers sont déjà à jour avec les nouveaux noms depuis PH1-01.

### Commit GitHub

Aucun commit nécessaire - Les fichiers étaient déjà à jour.

### Logs importants

```
✓ db-master-01 → db-postgres-01 (ID: 109781629, IP: 195.201.122.106)
✓ db-slave-01 → db-postgres-02 (ID: 109783838, IP: 91.98.169.31)
⚠ db-slave-02 (65.21.251.198) not found in Hetzner Cloud
```

### Observations

1. **2 serveurs renommés avec succès** ✅
2. **1 serveur non trouvé** - L'IP 65.21.251.198 n'existe pas dans Hetzner Cloud
3. **Cohérence des fichiers** - Tous les fichiers GitHub sont alignés sur les nouveaux noms
4. **Prêt pour PHASE 1** - Les 2 serveurs existants sont correctement nommés

### Conclusion

- ✅ **2/3 serveurs PostgreSQL renommés** avec succès dans Hetzner
- ✅ **Fichiers GitHub cohérents** avec les nouveaux noms
- ⚠️ **db-postgres-03 non créé** - Le serveur défini dans servers_v3.tsv n'existe pas encore dans Hetzner
- ✅ **Prêt pour PHASE 1** - Les serveurs existants sont correctement configurés

### Recommandation

Le serveur `db-postgres-03` sera créé lors de PHASE 1 rebuild si nécessaire, ou doit être créé manuellement dans Hetzner Cloud avec l'IP 65.21.251.198.

## Statut final

- ✅ **Ticket partiellement résolu:** 2/3 serveurs renommés
- ✅ **Fichiers GitHub cohérents**
- ⚠️ **Note:** db-postgres-03 n'existe pas dans Hetzner (sera créé en PHASE 1)

### Prochaine étape

Ticket suivant: **PH1-04** ou exécution PHASE 1 rebuild

---

**Scripts utilisés:** `scripts/rename-postgres-api.py`

