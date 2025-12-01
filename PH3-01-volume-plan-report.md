# PH3-01 – Volume Plan v3 Report

**Ticket Linear:** KEY-40 (PH3-01)  
**Date:** 2024-12-01  
**Statut:** ✅ Plan généré - Prêt pour PH3-02

---

## 🎯 Objectif

Construire un plan complet, structuré, documenté des volumes à gérer en PHASE 3 avant toute action destructive :
- Lister tous les serveurs rebuildables (47)
- Définir les volumes cibles pour chaque serveur
- Lister tous les volumes Hetzner existants
- Générer un diff clair entre volumes existants et volumes cibles
- **Aucune destruction, aucun formatage dans ce ticket**

---

## ✅ Résultats

### Fichiers Générés

1. **`servers/volume_plan_v3.json`** - Plan complet des volumes cibles
2. **`servers/existing_volumes_hetzner.json`** - État actuel des volumes Hetzner
3. **`servers/volume_diff_v3.json`** - Diff entre volumes existants et cibles

### Scripts Créés

1. **`scripts/generate_volume_plan.py`** - Génère le plan de volumes à partir de `servers_v3.tsv`
2. **`scripts/list_existing_volumes.py`** - Liste les volumes existants via Hetzner API
3. **`scripts/compare_volume_plan.py`** - Compare et génère le diff

---

## 📊 Résumé Exécutif

- **Nombre de serveurs rebuildables :** 47
- **Volumes cibles à créer :** 47
- **Volumes existants :** 40
- **Volumes à supprimer :** 40 (Option A - Destroy & Recreate All)
- **Taille totale des volumes cibles :** 2,800 GB (2.8 TB)

---

## 📋 Plan des Volumes Cibles

### Convention de Nommage

- **Nom de volume :** `kbv3-<hostname>-data`
- **Point de montage :** `/data/<role_v3>`
- **Taille :** Définie selon le rôle (voir tableau ci-dessous)

### Mapping Rôle → Taille

| Rôle v3 | Taille (GB) | Exemples de serveurs |
|---------|-------------|---------------------|
| k8s-master | 20 | k8s-master-01, k8s-master-02, k8s-master-03 |
| k8s-worker | 50 | k8s-worker-01 à k8s-worker-05 |
| db-postgres | 100 | db-postgres-01, db-postgres-02, db-postgres-03 |
| db-mariadb | 100 | maria-01, maria-02, maria-03 |
| db-proxysql | 20 | proxysql-01, proxysql-02 |
| db-temporal | 50 | temporal-db-01 |
| db-analytics | 50 | analytics-db-01 |
| redis | 20 | redis-01, redis-02, redis-03 |
| rabbitmq | 30 | queue-01, queue-02, queue-03 |
| minio | 200 | minio-01, minio-02, minio-03 |
| vault | 20 | vault-01 |
| backup | 500 | backup-01 |
| vector-db | 50 | vector-db-01 |
| mail-core | 50 | mail-core-01 |
| mail-mx | 30 | mail-mx-01, mail-mx-02 |
| builder | 20 | builder-01 |
| apps_misc | 20 | analytics-01, api-gateway-01, baserow-01, crm-01, etl-01, litellm-01, ml-platform-01, nocodb-01, temporal-01 |
| lb-internal | 10 | haproxy-01, haproxy-02 |
| siem | 50 | siem-01 |
| monitoring | 50 | monitor-01 |

### Liste Complète des Serveurs Rebuildables

| Hostname | Rôle v3 | IP Privée | Volume Name | Taille (GB) | Mountpoint |
|----------|---------|-----------|-------------|-------------|------------|
| analytics-01 | app-analytics | 10.0.0.139 | kbv3-analytics-01-data | 20 | /data/apps_misc |
| analytics-db-01 | db-analytics | 10.0.0.130 | kbv3-analytics-db-01-data | 50 | /data/db_analytics |
| api-gateway-01 | lb-apigw | 10.0.0.135 | kbv3-api-gateway-01-data | 20 | /data/apps_misc |
| backup-01 | backup | 10.0.0.153 | kbv3-backup-01-data | 500 | /data/backup |
| baserow-01 | app-nocode | 10.0.0.144 | kbv3-baserow-01-data | 20 | /data/apps_misc |
| builder-01 | builder | 10.0.0.200 | kbv3-builder-01-data | 20 | /data/builder |
| crm-01 | app-crm | 10.0.0.133 | kbv3-crm-01-data | 20 | /data/apps_misc |
| db-postgres-01 | db-postgres | 10.0.0.120 | kbv3-db-postgres-01-data | 100 | /data/db_postgres |
| db-postgres-02 | db-postgres | 10.0.0.121 | kbv3-db-postgres-02-data | 100 | /data/db_postgres |
| db-postgres-03 | db-postgres | 10.0.0.122 | kbv3-db-postgres-03-data | 100 | /data/db_postgres |
| etl-01 | app-etl | 10.0.0.140 | kbv3-etl-01-data | 20 | /data/apps_misc |
| haproxy-01 | lb-internal | 10.0.0.11 | kbv3-haproxy-01-data | 10 | /data/lb_internal |
| haproxy-02 | lb-internal | 10.0.0.12 | kbv3-haproxy-02-data | 10 | /data/lb_internal |
| k8s-master-01 | k8s-master | 10.0.0.100 | kbv3-k8s-master-01-data | 20 | /data/k8s_master |
| k8s-master-02 | k8s-master | 10.0.0.101 | kbv3-k8s-master-02-data | 20 | /data/k8s_master |
| k8s-master-03 | k8s-master | 10.0.0.102 | kbv3-k8s-master-03-data | 20 | /data/k8s_master |
| k8s-worker-01 | k8s-worker | 10.0.0.110 | kbv3-k8s-worker-01-data | 50 | /data/k8s_worker |
| k8s-worker-02 | k8s-worker | 10.0.0.111 | kbv3-k8s-worker-02-data | 50 | /data/k8s_worker |
| k8s-worker-03 | k8s-worker | 10.0.0.112 | kbv3-k8s-worker-03-data | 50 | /data/k8s_worker |
| k8s-worker-04 | k8s-worker | 10.0.0.113 | kbv3-k8s-worker-04-data | 50 | /data/k8s_worker |
| k8s-worker-05 | k8s-worker | 10.0.0.114 | kbv3-k8s-worker-05-data | 50 | /data/k8s_worker |
| litellm-01 | llm-proxy | 10.0.0.137 | kbv3-litellm-01-data | 20 | /data/apps_misc |
| mail-core-01 | mail-core | 10.0.0.160 | kbv3-mail-core-01-data | 50 | /data/mail_core |
| mail-mx-01 | mail-mx | 10.0.0.161 | kbv3-mail-mx-01-data | 30 | /data/mail_mx |
| mail-mx-02 | mail-mx | 10.0.0.162 | kbv3-mail-mx-02-data | 30 | /data/mail_mx |
| maria-01 | db-mariadb | 10.0.0.170 | kbv3-maria-01-data | 100 | /data/db_mariadb |
| maria-02 | db-mariadb | 10.0.0.171 | kbv3-maria-02-data | 100 | /data/db_mariadb |
| maria-03 | db-mariadb | 10.0.0.172 | kbv3-maria-03-data | 100 | /data/db_mariadb |
| minio-01 | minio | 10.0.0.134 | kbv3-minio-01-data | 200 | /data/minio |
| minio-02 | minio | 10.0.0.131 | kbv3-minio-02-data | 200 | /data/minio |
| minio-03 | minio | 10.0.0.132 | kbv3-minio-03-data | 200 | /data/minio |
| ml-platform-01 | ml-platform | 10.0.0.143 | kbv3-ml-platform-01-data | 20 | /data/apps_misc |
| monitor-01 | monitoring | 10.0.0.152 | kbv3-monitor-01-data | 50 | /data/monitoring |
| nocodb-01 | app-nocode | 10.0.0.142 | kbv3-nocodb-01-data | 20 | /data/apps_misc |
| proxysql-01 | db-proxysql | 10.0.0.173 | kbv3-proxysql-01-data | 20 | /data/db_proxysql |
| proxysql-02 | db-proxysql | 10.0.0.174 | kbv3-proxysql-02-data | 20 | /data/db_proxysql |
| queue-01 | rabbitmq | 10.0.0.126 | kbv3-queue-01-data | 30 | /data/rabbitmq |
| queue-02 | rabbitmq | 10.0.0.127 | kbv3-queue-02-data | 30 | /data/rabbitmq |
| queue-03 | rabbitmq | 10.0.0.128 | kbv3-queue-03-data | 30 | /data/rabbitmq |
| redis-01 | redis | 10.0.0.123 | kbv3-redis-01-data | 20 | /data/redis |
| redis-02 | redis | 10.0.0.124 | kbv3-redis-02-data | 20 | /data/redis |
| redis-03 | redis | 10.0.0.125 | kbv3-redis-03-data | 20 | /data/redis |
| siem-01 | siem | 10.0.0.151 | kbv3-siem-01-data | 50 | /data/siem |
| temporal-01 | app-temporal | 10.0.0.138 | kbv3-temporal-01-data | 20 | /data/apps_misc |
| temporal-db-01 | db-temporal | 10.0.0.129 | kbv3-temporal-db-01-data | 50 | /data/db_temporal |
| vault-01 | vault | 10.0.0.150 | kbv3-vault-01-data | 20 | /data/vault |
| vector-db-01 | vector-db | 10.0.0.136 | kbv3-vector-db-01-data | 50 | /data/vector_db |

---

## 📦 Volumes Hetzner Existants

### Résumé

- **Total volumes existants :** 40
- **Volumes attachés :** 40
- **Volumes détachés :** 0
- **Zones :** nbg1 (Nuremberg), hel1 (Helsinki)

### Convention de Nommage Actuelle

Les volumes existants utilisent l'ancienne convention de nommage :
- Format : `vol-<hostname>` ou `vol-<role>-<number>`
- Exemples : `vol-minio-01`, `vol-haproxy-02`, `vol-db-master-01`, `vol-db-slave-01`

**Note :** Aucun volume existant n'utilise la nouvelle convention `kbv3-<hostname>-data`.

### Volumes Existants (échantillon)

| ID | Nom | Taille (GB) | Serveur | Zone |
|----|-----|-------------|---------|------|
| 104011392 | vol-minio-01 | 100 | minio-01 | nbg1 |
| 104011393 | vol-haproxy-02 | 10 | haproxy-02 | nbg1 |
| 104011394 | vol-haproxy-01 | 10 | haproxy-01 | nbg1 |
| 104011395 | vol-backup-01 | 200 | backup-01 | nbg1 |
| 104011399 | vol-analytics-01 | 20 | analytics-01 | nbg1 |
| 104011410 | vol-api-gateway-01 | 10 | api-gateway-01 | nbg1 |
| ... | ... | ... | ... | ... |

**Liste complète disponible dans :** `servers/existing_volumes_hetzner.json`

---

## 🔄 Diff : Volumes Existants vs Volumes Cibles

### Stratégie : Option A - Destroy & Recreate All

**Approche :** Tous les volumes existants seront détruits et recréés avec la nouvelle convention de nommage et les nouvelles tailles.

### Résumé du Diff

| Métrique | Valeur |
|----------|--------|
| Volumes existants | 40 |
| Volumes cibles | 47 |
| Volumes à supprimer | 40 |
| Volumes à créer | 47 |
| Volumes OK (référence) | 0 |

### Volumes à Supprimer

**Total :** 40 volumes

Tous les volumes existants doivent être supprimés car :
- Ils utilisent l'ancienne convention de nommage (`vol-*`)
- Les tailles peuvent différer des cibles
- Option A nécessite un nettoyage complet

**Liste complète disponible dans :** `servers/volume_diff_v3.json` → `volumes_to_delete`

### Volumes à Créer

**Total :** 47 volumes

Tous les serveurs rebuildables auront un nouveau volume créé avec :
- Nom : `kbv3-<hostname>-data`
- Taille : Selon le rôle (voir tableau ci-dessus)
- Zone : Selon la région du serveur (nbg1 principalement)

**Liste complète disponible dans :** `servers/volume_diff_v3.json` → `volumes_to_create`

### Exemples de Diff

#### Volumes à Supprimer (exemples)

| ID | Nom Actuel | Serveur | Raison |
|----|------------|---------|--------|
| 104011392 | vol-minio-01 | minio-01 | Ne correspond pas à la convention v3 |
| 104011395 | vol-backup-01 | backup-01 | Ne correspond pas à la convention v3 |
| 104011414 | vol-db-master-01 | db-postgres-01 | Ne correspond pas à la convention v3 |
| 104011411 | vol-db-slave-02 | db-postgres-03 | Ne correspond pas à la convention v3 |

#### Volumes à Créer (exemples)

| Hostname | Nom Volume | Taille (GB) | Mountpoint |
|----------|------------|-------------|------------|
| minio-01 | kbv3-minio-01-data | 200 | /data/minio |
| backup-01 | kbv3-backup-01-data | 500 | /data/backup |
| db-postgres-01 | kbv3-db-postgres-01-data | 100 | /data/db_postgres |

---

## 🔧 Scripts Utilisés

### 1. `generate_volume_plan.py`

**Fonction :** Génère le plan complet des volumes cibles à partir de `servers_v3.tsv`

**Sortie :** `servers/volume_plan_v3.json`

**Exécution :**
```bash
cd /opt/keybuzz/keybuzz-infra
python3 scripts/generate_volume_plan.py
```

### 2. `list_existing_volumes.py`

**Fonction :** Liste tous les volumes existants via Hetzner Cloud API (`hcloud` CLI)

**Prérequis :**
- `hcloud` CLI installé
- Token Hetzner configuré (`HCLOUD_TOKEN`)

**Sortie :** `servers/existing_volumes_hetzner.json`

**Exécution :**
```bash
cd /opt/keybuzz/keybuzz-infra
source /opt/keybuzz/credentials/hcloud.env
export HCLOUD_TOKEN
python3 scripts/list_existing_volumes.py
```

### 3. `compare_volume_plan.py`

**Fonction :** Compare les volumes existants avec les volumes cibles et génère un diff

**Entrées :**
- `servers/volume_plan_v3.json`
- `servers/existing_volumes_hetzner.json`

**Sortie :** `servers/volume_diff_v3.json`

**Exécution :**
```bash
cd /opt/keybuzz/keybuzz-infra
python3 scripts/compare_volume_plan.py
```

---

## ⚠️ Avertissements et Notes

### Option A - Destroy & Recreate All

**Cette stratégie implique :**
- ✅ Tous les volumes existants seront supprimés
- ✅ Tous les volumes seront recréés avec la nouvelle convention
- ✅ Aucune migration de données (données perdues)
- ⚠️ **Les données présentes sur les volumes actuels seront perdues**

### Convention de Nommage Validée

- ✅ Tous les volumes cibles utilisent : `kbv3-<hostname>-data`
- ✅ Format cohérent et prévisible
- ✅ Facilite la gestion et l'identification

### Points de Montage

- ✅ Tous les volumes seront montés sur `/data/<role_v3>`
- ✅ Format normalisé avec underscores (`db_postgres`, `k8s_master`, etc.)
- ✅ Les apps individuelles partagent `/data/apps_misc`

---

## 📁 Fichiers de Référence

### Fichiers Générés

1. **`servers/volume_plan_v3.json`**
   - Plan complet des 47 volumes cibles
   - Métadonnées, hostname, rôle, IP, nom de volume, taille, mountpoint

2. **`servers/existing_volumes_hetzner.json`**
   - Snapshot des 40 volumes existants
   - ID, nom, taille, zone, serveur attaché

3. **`servers/volume_diff_v3.json`**
   - Diff entre volumes existants et cibles
   - Listes : `volumes_to_delete`, `volumes_to_create`, `volumes_ok`

### Fichiers Sources

1. **`servers/servers_v3.tsv`**
   - Source de vérité pour les serveurs
   - Contient HOSTNAME, IP_PRIVEE, ROLE_V3

2. **`servers/rebuild_order_v3.json`**
   - Métadonnées de rebuild (référence)

---

## ✅ Validation

### Vérifications Effectuées

- ✅ 47 serveurs rebuildables identifiés
- ✅ Tous les volumes cibles définis avec nom, taille, mountpoint
- ✅ 40 volumes existants listés et analysés
- ✅ Diff généré avec stratégie Option A
- ✅ Convention de nommage validée
- ✅ Aucune action destructive effectuée

### Prêt pour PH3-02

**PH3-02** détruira les volumes listés dans `volumes_to_delete` et créera les volumes listés dans `volumes_to_create`.

**Fichiers prêts pour PH3-02 :**
- ✅ `servers/volume_plan_v3.json` - Plan complet
- ✅ `servers/volume_diff_v3.json` - Liste des actions à effectuer

---

## 🚀 Prochaines Étapes

### PH3-02 : Destruction & Création des Volumes

**Actions prévues :**
1. Détacher tous les volumes existants (40)
2. Supprimer tous les volumes existants (40)
3. Créer tous les nouveaux volumes (47)
4. Attacher les nouveaux volumes aux serveurs
5. Vérifier l'attachement

**Fichiers de référence :**
- `servers/volume_diff_v3.json` → `volumes_to_delete`
- `servers/volume_diff_v3.json` → `volumes_to_create`

---

**Généré le :** 2024-12-01  
**Exécuté le :** 2025-12-01T07:20:40+00:00  
**Status :** ✅ **VALIDÉ - Plan généré, prêt pour PH3-02 (destruction & création)**

