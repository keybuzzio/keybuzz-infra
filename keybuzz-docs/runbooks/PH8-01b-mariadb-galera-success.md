# PH8-01b - MariaDB Galera HA Deployment Status

**Date**: 2025-12-04  
**Statut**: 🚧 En cours - Bootstrap en cours de résolution  
**Objectif**: Déployer un cluster MariaDB Galera HA opérationnel avec 3 nœuds

## Résumé

Déploiement de la structure complète pour MariaDB Galera HA + ProxySQL. Le bootstrap du cluster rencontre des difficultés techniques liées au démarrage de MariaDB avec Galera.

## État Actuel

### Structure Créée ✅

- **Ansible Roles**:
  - `ansible/roles/mariadb_galera_v3/` (tasks, templates, handlers)
  - `ansible/roles/proxysql_v3/` (tasks, templates, handlers)

- **Configuration**:
  - `ansible/group_vars/mariadb.yml`
  - `ansible/group_vars/proxysql.yml`
  - `ansible/playbooks/mariadb_galera_v3.yml`
  - `ansible/playbooks/proxysql_v3.yml`

- **Scripts**:
  - `scripts/mariadb_ha_checks.sh`
  - `scripts/mariadb_ha_end_to_end.sh`
  - `scripts/mariadb_bootstrap_simple.sh`
  - `scripts/mariadb_bootstrap_direct.sh`
  - `scripts/mariadb_galera_bootstrap_final.sh`

- **Documentation**:
  - `keybuzz-docs/runbooks/phase8_mariadb_ha.md`
  - `keybuzz-docs/runbooks/PH8-00-mariadb-init.md`

### Problèmes Rencontrés

1. **Mirrors MariaDB**: Problèmes de connectivité réseau avec les mirrors officiels (résolu avec fallback)
2. **Bootstrap Galera**: `galera_new_cluster` timeout lors du démarrage via systemd
3. **maria-01 inaccessible**: Problème de connectivité SSH temporaire
4. **Démarrage MariaDB**: Signal fatal lors du démarrage avec configuration Galera

### Configuration Appliquée

**MariaDB Galera**:
- Version: 10.11.15
- Cluster: 3 nœuds (10.0.0.170, 10.0.0.171, 10.0.0.172)
- Data dir: `/data/mariadb/data`
- SST method: rsync
- Gcache: 512M

**ProxySQL**:
- Version: 2.6
- 2 nœuds (10.0.0.173, 10.0.0.174)
- Admin port: 6032
- MySQL port: 6033

## Prochaines Étapes

1. **Résoudre le bootstrap**:
   - Utiliser `mysqld_safe` directement avec options Galera
   - Ou créer un service systemd personnalisé pour le bootstrap
   - Vérifier les permissions et la configuration

2. **Bootstrap sur maria-02**:
   - Une fois le bootstrap réussi, ajouter maria-03 au cluster
   - Ajouter maria-01 quand il sera accessible

3. **Déployer ProxySQL**:
   - Une fois le cluster MariaDB opérationnel

4. **Tests**:
   - Vérifier `wsrep_cluster_size = 3`
   - Tester la réplication
   - Tester ProxySQL

## Commandes Utiles

### Bootstrap manuel

```bash
# Sur le nœud de bootstrap
systemctl stop mariadb
rm -rf /data/mariadb/data/*
mysqld --initialize-insecure --datadir=/data/mariadb/data --user=mysql
chown -R mysql:mysql /data/mariadb/data

# Modifier galera.cnf temporairement
sed -i 's|wsrep_cluster_address = .*|wsrep_cluster_address = gcomm://|' /etc/mysql/conf.d/galera.cnf

# Démarrer
systemctl start mariadb

# Après démarrage, restaurer la config
sed -i 's|wsrep_cluster_address = gcomm://|wsrep_cluster_address = gcomm://10.0.0.170,10.0.0.171,10.0.0.172|' /etc/mysql/conf.d/galera.cnf
systemctl restart mariadb
```

### Vérifier le cluster

```bash
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_local_state_comment';"
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_state_uuid';"
```

## Notes Techniques

- Le bootstrap Galera nécessite `wsrep_cluster_address = gcomm://` (sans nœuds)
- Après bootstrap, restaurer la configuration complète avec tous les nœuds
- Les nœuds suivants rejoignent automatiquement le cluster
- Vérifier que les ports 3306, 4444, 4567 sont ouverts entre les nœuds

## Conclusion

Structure complète créée et commitée. Le déploiement nécessite la résolution du problème de bootstrap Galera. Les scripts et la documentation sont prêts pour finaliser le déploiement une fois le bootstrap résolu.

