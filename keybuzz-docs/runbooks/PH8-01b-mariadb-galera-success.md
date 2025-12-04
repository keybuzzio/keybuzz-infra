# PH8-01b - MariaDB Galera HA Deployment Status

**Date**: 2025-12-04  
**Statut**: 🚧 En cours - Scripts de bootstrap créés, déploiement en cours  
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

## Scripts Créés pour le Bootstrap

Les scripts suivants ont été créés pour automatiser le bootstrap :

1. **`scripts/ph8-01-full-bootstrap.sh`** : Bootstrap complet sur maria-02 puis ajout de maria-03
2. **`scripts/ph8-01-bootstrap-complete.sh`** : Bootstrap avec vérifications
3. **`scripts/ph8-01-diagnose-and-fix.sh`** : Diagnostic et correction automatique
4. **`scripts/ph8-01-check-cluster.sh`** : Vérification du statut du cluster
5. **`scripts/ph8-01-join-node.sh`** : Ajout d'un nœud au cluster
6. **`scripts/ph8-01-final-verification.sh`** : Vérification finale et déploiement ProxySQL

## État Actuel du Déploiement

### Connectivité
- **maria-01 (10.0.0.170)** : ❌ Inaccessible (problème SSH)
- **maria-02 (10.0.0.171)** : ⚠️ Intermittent (parfois inaccessible)
- **maria-03 (10.0.0.172)** : ✅ Accessible

### Bootstrap
- Scripts de bootstrap créés et testés
- Configuration Ansible prête
- Problèmes de connectivité réseau à résoudre

## Prochaines Étapes

1. **Résoudre les problèmes de connectivité**:
   - Vérifier l'état des serveurs maria-01 et maria-02
   - Vérifier les règles de firewall
   - Vérifier les clés SSH

2. **Exécuter le bootstrap**:
   ```bash
   cd /opt/keybuzz/keybuzz-infra
   bash scripts/ph8-01-full-bootstrap.sh
   ```

3. **Vérifier le cluster**:
   ```bash
   bash scripts/ph8-01-check-cluster.sh
   bash scripts/mariadb_ha_checks.sh
   ```

4. **Déployer ProxySQL**:
   ```bash
   ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/proxysql_v3.yml
   ```

5. **Tests end-to-end**:
   ```bash
   bash scripts/mariadb_ha_end_to_end.sh
   ```

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


