# Phase 8 - MariaDB Galera HA + ProxySQL

**Date**: 2025-12-04  
**Statut**: 🚧 En cours de déploiement  
**Objectif**: Déployer un cluster MariaDB Galera HA avec ProxySQL pour ERPNext et autres applications

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Applications                             │
│              (ERPNext, autres apps)                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ mysql://10.0.0.10:3306
                     │
         ┌───────────▼───────────┐
         │   HAProxy / LB        │
         │   (10.0.0.10:3306)   │
         └───────────┬───────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
    ┌────▼────┐            ┌────▼────┐
    │ProxySQL │            │ProxySQL │
    │-01     │            │-02     │
    │6033    │            │6033    │
    └────┬────┘            └────┬────┘
         │                      │
         └──────────┬───────────┘
                    │
         ┌──────────┴──────────┐
         │                     │
    ┌────▼────┐  ┌────▼────┐  ┌────▼────┐
    │maria-01│  │maria-02│  │maria-03│
    │10.0.0.170│ │10.0.0.171│ │10.0.0.172│
    │Galera   │  │Galera   │  │Galera   │
    └─────────┘  └─────────┘  └─────────┘
         │            │            │
         └────────────┴────────────┘
              Galera Replication
```

## Composants

### MariaDB Galera Cluster

- **3 nœuds**:
  - maria-01 (10.0.0.170)
  - maria-02 (10.0.0.171)
  - maria-03 (10.0.0.172)

- **Version**: MariaDB 10.11 avec Galera 4
- **Data Directory**: `/data/mariadb/data` (XFS monté)
- **Port**: 3306
- **Cluster Name**: `keybuzz-mariadb-galera`

### ProxySQL

- **2 nœuds**:
  - proxysql-01 (10.0.0.173)
  - proxysql-02 (10.0.0.174)

- **Version**: ProxySQL 2.6
- **Admin Port**: 6032
- **MySQL Port**: 6033
- **Fonction**: Load balancing et routing vers le cluster MariaDB

### HAProxy / Load Balancer

- **Endpoint**: 10.0.0.10:3306 (à configurer dans PH8-02)
- **Fonction**: Point d'entrée unique pour les applications

## Configuration Galera

### Paramètres Principaux

- **wsrep_cluster_name**: `keybuzz-mariadb-galera`
- **wsrep_cluster_address**: `gcomm://10.0.0.170,10.0.0.171,10.0.0.172`
- **wsrep_sst_method**: `rsync`
- **galera_gcache_size**: `512M`
- **binlog_format**: `ROW`
- **default_storage_engine**: `InnoDB`

### SST (State Snapshot Transfer)

- **Méthode**: rsync
- **User**: `sst_user`
- **Port**: 4444

## Commandes Utiles

### Vérifier le statut du cluster

```bash
# Sur n'importe quel nœud MariaDB
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_local_state_comment';"
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_state_uuid';"
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_%';"
```

### Vérifier ProxySQL

```bash
# Se connecter à l'interface admin
mysql -h proxysql-01 -P6032 -uadmin -padmin

# Vérifier les serveurs backend
SELECT * FROM mysql_servers;

# Vérifier les utilisateurs
SELECT * FROM mysql_users;

# Charger la configuration
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
```

### Scripts de vérification

```bash
# Vérifications complètes
bash scripts/mariadb_ha_checks.sh

# Test end-to-end
bash scripts/mariadb_ha_end_to_end.sh
```

## Points d'Attention

### 1. Initialisation du Cluster

- Le premier nœud (maria-01) doit être initialisé avec `galera_new_cluster`
- Les autres nœuds rejoignent le cluster automatiquement
- Ne jamais démarrer plusieurs nœuds en même temps sans cluster existant

### 2. SST (State Snapshot Transfer)

- **rsync**: Méthode par défaut, simple mais peut être lent sur grandes bases
- **mariabackup**: Plus rapide, recommandé pour production (à configurer plus tard)
- Nécessite un utilisateur avec privilèges `RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT`

### 3. Gcache (Galera Cache)

- Taille configurée: 512M
- Stocke les transactions récentes pour IST (Incremental State Transfer)
- Si gcache trop petit, SST complet nécessaire lors de la récupération

### 4. Quorum

- Cluster nécessite une majorité de nœuds (2 sur 3)
- Si 2 nœuds tombent, le cluster passe en mode "non-primary"
- Nécessite intervention manuelle pour récupérer

### 5. Write Conflicts

- Galera détecte les conflits d'écriture
- `wsrep_log_conflicts = ON` pour logging
- Applications doivent gérer les erreurs de conflit

## Déploiement

### Étape 1: MariaDB Galera

```bash
ansible-playbook \
  -i ansible/inventory/hosts.yml \
  ansible/playbooks/mariadb_galera_v3.yml \
  | tee /opt/keybuzz/logs/phase8/mariadb-galera-deploy.log
```

### Étape 2: ProxySQL

```bash
ansible-playbook \
  -i ansible/inventory/hosts.yml \
  ansible/playbooks/proxysql_v3.yml \
  | tee /opt/keybuzz/logs/phase8/proxysql-deploy.log
```

### Étape 3: Vérifications

```bash
bash scripts/mariadb_ha_checks.sh
bash scripts/mariadb_ha_end_to_end.sh
```

## Variables Ansible

### group_vars/mariadb.yml

- `mariadb_version`: "10.11"
- `mariadb_data_dir`: "/data/mariadb"
- `galera_cluster_name`: "keybuzz-mariadb-galera"
- `mariadb_root_password`: "CHANGE_ME_LATER_VIA_VAULT"
- `mariadb_cluster_user`: "sst_user"
- `mariadb_cluster_password`: "CHANGE_ME_LATER_VIA_VAULT"

### group_vars/proxysql.yml

- `proxysql_admin_port`: 6032
- `proxysql_mysql_port`: 6033
- `mariadb_backend_hosts`: Liste des nœuds MariaDB

## Prochaines Étapes

1. **PH8-02**: Configuration HAProxy / LB pour exposer MariaDB sur 10.0.0.10:3306
2. **PH8-03**: Migration des secrets vers Vault
3. **PH8-04**: Configuration read/write split dans ProxySQL
4. **PH8-05**: Tests de charge et performance
5. **PH8-06**: Intégration avec ERPNext

## Troubleshooting

### Cluster ne démarre pas

```bash
# Vérifier les logs
journalctl -u mariadb -n 100

# Vérifier la configuration
cat /etc/mysql/my.cnf
cat /etc/mysql/conf.d/galera.cnf

# Vérifier les permissions
ls -la /data/mariadb/data
```

### Nœud ne rejoint pas le cluster

```bash
# Vérifier la connectivité réseau
ping 10.0.0.170
ping 10.0.0.171
ping 10.0.0.172

# Vérifier les ports
ss -ntlp | grep 3306
ss -ntlp | grep 4444

# Vérifier les credentials SST
mysql -u root -p -e "SELECT user, host FROM mysql.user WHERE user='sst_user';"
```

### ProxySQL ne route pas correctement

```bash
# Vérifier la configuration
mysql -h proxysql-01 -P6032 -uadmin -padmin -e "SELECT * FROM mysql_servers;"

# Recharger la configuration
mysql -h proxysql-01 -P6032 -uadmin -padmin -e "LOAD MYSQL SERVERS TO RUNTIME; SAVE MYSQL SERVERS TO DISK;"
```

## Références

- [MariaDB Galera Documentation](https://mariadb.com/kb/en/galera-cluster/)
- [ProxySQL Documentation](https://proxysql.com/documentation/)
- [Galera Cluster Configuration](https://mariadb.com/kb/en/galera-cluster-system-variables/)

