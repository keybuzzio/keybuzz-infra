# PH8-00 - MariaDB Galera HA Initial Deployment

**Date**: 2025-12-04  
**Statut**: 🚧 En cours  
**Objectif**: Initialiser le cluster MariaDB Galera HA avec ProxySQL

## Résumé

Déploiement complet d'un cluster MariaDB Galera HA (3 nœuds) avec ProxySQL (2 nœuds) pour fournir une base de données haute disponibilité pour ERPNext et autres applications KeyBuzz.

## Architecture Déployée

```
Applications
    │
    ▼
HAProxy/LB (10.0.0.10:3306) [PH8-02]
    │
    ├── ProxySQL-01 (10.0.0.173:6033)
    └── ProxySQL-02 (10.0.0.174:6033)
            │
            ├── maria-01 (10.0.0.170:3306) [Leader]
            ├── maria-02 (10.0.0.171:3306) [Replica]
            └── maria-03 (10.0.0.172:3306) [Replica]
```

## Ordre d'Exécution

### 1. Préparation

- ✅ Vérification de l'inventory Ansible
- ✅ Vérification du montage XFS sur `/data/mariadb`
- ✅ Création de l'arborescence Ansible

### 2. Déploiement MariaDB Galera

**Playbook**: `ansible/playbooks/mariadb_galera_v3.yml`

**Étapes**:
1. Installation MariaDB 10.11 + Galera 4
2. Configuration `my.cnf` et `galera.cnf`
3. Bootstrap du cluster sur maria-01
4. Ajout de maria-02 et maria-03 au cluster
5. Vérification `wsrep_cluster_size = 3`

**Commande**:
```bash
ansible-playbook \
  -i ansible/inventory/hosts.yml \
  ansible/playbooks/mariadb_galera_v3.yml \
  | tee /opt/keybuzz/logs/phase8/mariadb-galera-deploy.log
```

### 3. Déploiement ProxySQL

**Playbook**: `ansible/playbooks/proxysql_v3.yml`

**Étapes**:
1. Installation ProxySQL 2.6
2. Configuration `proxysql.cnf`
3. Ajout des backends MariaDB
4. Configuration des utilisateurs
5. Activation du service

**Commande**:
```bash
ansible-playbook \
  -i ansible/inventory/hosts.yml \
  ansible/playbooks/proxysql_v3.yml \
  | tee /opt/keybuzz/logs/phase8/proxysql-deploy.log
```

### 4. Vérifications

**Script**: `scripts/mariadb_ha_checks.sh`

**Vérifications**:
- Cluster size = 3 sur tous les nœuds
- Statut des nœuds (Synced, Donor, etc.)
- ProxySQL admin et MySQL ports ouverts
- Backends configurés dans ProxySQL

**Commande**:
```bash
bash scripts/mariadb_ha_checks.sh
```

### 5. Tests End-to-End

**Script**: `scripts/mariadb_ha_end_to_end.sh`

**Tests**:
- Connexion via ProxySQL
- Création de base de données
- Création de table
- Insertion de données
- Lecture de données
- Vérification de réplication sur tous les nœuds

**Commande**:
```bash
bash scripts/mariadb_ha_end_to_end.sh
```

## Résultats Attendus

### MariaDB Cluster

```sql
-- Sur n'importe quel nœud
SHOW STATUS LIKE 'wsrep_cluster_size';
-- Résultat attendu: Value = 3

SHOW STATUS LIKE 'wsrep_local_state_comment';
-- Résultat attendu: Synced

SHOW STATUS LIKE 'wsrep_cluster_state_uuid';
-- Résultat attendu: UUID identique sur tous les nœuds
```

### ProxySQL

```sql
-- Sur proxysql-01 ou proxysql-02
SELECT * FROM mysql_servers;
-- Résultat attendu: 3 serveurs ONLINE

SELECT * FROM mysql_users;
-- Résultat attendu: Utilisateurs configurés
```

## Fichiers Créés

### Ansible

- `ansible/roles/mariadb_galera_v3/`
  - `tasks/main.yml`
  - `templates/my.cnf.j2`
  - `templates/galera.cnf.j2`
  - `handlers/main.yml`

- `ansible/roles/proxysql_v3/`
  - `tasks/main.yml`
  - `templates/proxysql.cnf.j2`
  - `handlers/main.yml`

- `ansible/group_vars/mariadb.yml`
- `ansible/group_vars/proxysql.yml`

- `ansible/playbooks/mariadb_galera_v3.yml`
- `ansible/playbooks/proxysql_v3.yml`

### Scripts

- `scripts/mariadb_ha_checks.sh`
- `scripts/mariadb_ha_end_to_end.sh`

### Documentation

- `keybuzz-docs/runbooks/phase8_mariadb_ha.md`
- `keybuzz-docs/runbooks/PH8-00-mariadb-init.md`

## Configuration Clé

### MariaDB Galera

```ini
[mysqld]
wsrep_on = ON
wsrep_provider = /usr/lib/galera/libgalera_smm.so
wsrep_cluster_name = "keybuzz-mariadb-galera"
wsrep_cluster_address = "gcomm://10.0.0.170,10.0.0.171,10.0.0.172"
wsrep_sst_method = rsync
wsrep_sst_auth = "sst_user:<password>"
```

### ProxySQL

```ini
admin_variables=
{
    admin_credentials="admin:admin"
    mysql_ifaces="0.0.0.0:6032"
}

mysql_variables=
{
    interfaces="0.0.0.0:6033"
    max_connections=2048
}
```

## Prochaines Étapes

1. **PH8-01**: ✅ Déploiement initial (ce ticket)
2. **PH8-02**: Configuration HAProxy / LB pour 10.0.0.10:3306
3. **PH8-03**: Migration des secrets vers Vault
4. **PH8-04**: Configuration read/write split
5. **PH8-05**: Tests de performance
6. **PH8-06**: Intégration ERPNext

## Notes Importantes

- Les mots de passe sont des placeholders et doivent être migrés vers Vault
- Le cluster Galera nécessite une majorité de nœuds (2 sur 3)
- ProxySQL doit être configuré avec les bons backends avant utilisation
- Les tests end-to-end vérifient la réplication complète

