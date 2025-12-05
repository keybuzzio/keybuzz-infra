# PH8-02 MariaDB Galera Rebuild Success

**Date**: 2025-12-04  
**Status**: ✅ Complete

## Summary

Successfully rebuilt and deployed MariaDB Galera HA cluster on 3 nodes (maria-01, maria-02, maria-03) with clean configuration after removing unsupported variables.

## Actions Performed

### 1. SSH Key Deployment
- ✅ SSH keys deployed to all 5 servers (maria-01/02/03, proxysql-01/02)
- ✅ All servers accessible via SSH from install-v3

### 2. Volume Formatting
- ✅ XFS volumes formatted and mounted on all servers
- ✅ MariaDB volumes: `/data/mariadb` on maria-01/02/03
- ✅ ProxySQL volumes: `/data/proxysql` on proxysql-01/02

### 3. Configuration Cleanup
- ✅ Analyzed all Galera config files for unsupported variables
- ✅ Removed parasite files containing `wsrep_replicate_myisam` and `pxc_strict_mode`
- ✅ Added Ansible task to remove existing configs before deployment
- ✅ Re-deployed clean `galera.cnf` from template

### 4. MariaDB Deployment
- ✅ MariaDB 10.11 + Galera installed on all 3 nodes
- ✅ Clean `galera.cnf` deployed (no unsupported variables)
- ✅ MariaDB service restarted successfully

### 5. MariaDB Initialization
- ✅ MariaDB initialized using `mariadb-install-db` (replaces `mysqld --initialize-insecure`)
- ✅ Tables système créées dans `/data/mariadb/data/mysql/`
- ✅ Galera désactivé pendant l'initialisation
- ✅ Galera réactivé après initialisation

### 6. Galera Bootstrap (Correct Sequence)
- ✅ Bootstrap performed on maria-02 (10.0.0.171) using `galera_new_cluster`
- ✅ **CRITICAL**: maria-02 NOT restarted after bootstrap
- ✅ maria-01 (10.0.0.170) started and joined cluster
- ✅ maria-03 (10.0.0.172) started and joined cluster
- ✅ **Bootstrap sequence**: Stop all → Bootstrap maria-02 → Start maria-01/03 → Verify cluster

## Cluster Status

### Final Verification

**Cluster Size**: `wsrep_cluster_size = 3` ✅

**Node States**:
- maria-01: `wsrep_local_state_comment = Synced` ✅
- maria-02: `wsrep_local_state_comment = Synced` ✅
- maria-03: `wsrep_local_state_comment = Synced` ✅

### Configuration Files

**galera.cnf** (clean, no unsupported variables):
```ini
[mysqld]
# Galera Configuration
wsrep_on = ON
wsrep_provider = /usr/lib/galera/libgalera_smm.so
wsrep_cluster_name = "keybuzz-mariadb-galera"
wsrep_cluster_address = "gcomm://10.0.0.170,10.0.0.171,10.0.0.172"
wsrep_node_name = "{{ inventory_hostname }}"
wsrep_node_address = "{{ ansible_host }}"
wsrep_node_incoming_address = "{{ ansible_host }}"

# SST (State Snapshot Transfer) Configuration
wsrep_sst_method = rsync
wsrep_sst_auth = "sst_user:CHANGE_ME_LATER_VIA_VAULT"
wsrep_sst_receive_address = "{{ ansible_host }}:4444"

# Galera Cache
wsrep_provider_options = "gcache.size=512M"

# Galera Settings
wsrep_slave_threads = 4
wsrep_load_data_splitting = ON

# Galera Logging
wsrep_log_conflicts = ON
```

**Removed Variables** (not supported in MariaDB 10.11):
- ❌ `wsrep_replicate_myisam = OFF` (removed)
- ❌ `pxc_strict_mode = PERMISSIVE` (removed)

## Files Removed

The following parasite files were removed from all nodes:
- `/etc/mysql/conf.d/galera.cnf` (old version with unsupported variables)
- `/etc/mysql/conf.d/galera.cnf.dpkg-dist`
- `/etc/mysql/conf.d/galera.cnf.dpkg-old`
- `/etc/mysql/conf.d/galera.cnf.rpmnew`
- `/etc/mysql/conf.d/galera.cnf.rpmsave`
- `/etc/mysql/mariadb.conf.d/galera.cnf`

## Ansible Changes

Added cleanup task in `ansible/roles/mariadb_galera_v3/tasks/main.yml`:
```yaml
- name: Remove existing galera configs (cleanup)
  file:
    path: "{{ item }}"
    state: absent
  loop:
    - /etc/mysql/conf.d/galera.cnf
    - /etc/mysql/mariadb.conf.d/galera.cnf
    - /etc/mysql/conf.d/galera.cnf.dpkg-dist
    - /etc/mysql/conf.d/galera.cnf.dpkg-old
    - /etc/mysql/conf.d/galera.cnf.rpmnew
    - /etc/mysql/conf.d/galera.cnf.rpmsave
  ignore_errors: yes
```

## Scripts Created

- `scripts/ph8-02-analyze-galera-files.sh` - Analyze Galera config files
- `scripts/ph8-02-remove-parasite-files.sh` - Remove parasite files
- `scripts/ph8-02-fix-galera-final.sh` - Fix galera.cnf files
- `scripts/ph8-02-check-cluster.sh` - Check cluster status
- `scripts/ph8-02-reinit-mariadb.sh` - Reinitialize MariaDB databases (uses `mariadb-install-db`)
- `scripts/ph8-02-final-init.sh` - Final initialization script (disable Galera, init, bootstrap)
- `scripts/ph8-02-init-with-install-db.sh` - Complete initialization with `mariadb-install-db` and Galera bootstrap
- `scripts/ph8-02-correct-bootstrap.sh` - Correct bootstrap sequence (no restart after galera_new_cluster)

## ProxySQL Deployment

- ✅ ProxySQL deployed on proxysql-01 and proxysql-02
- ✅ Backend servers configured (maria-01, maria-02, maria-03)
- ✅ Read/write split configured

## End-to-End Tests

- ✅ Connection via ProxySQL successful
- ✅ Database creation successful
- ✅ Table creation successful
- ✅ INSERT operations successful
- ✅ SELECT operations successful

## Next Steps

1. ✅ Deploy ProxySQL - **COMPLETE**
2. ✅ Run end-to-end tests - **COMPLETE**
3. ⏳ Configure HAProxy/LB for MariaDB endpoint (pending)

## Final Validation (PH8-FINAL-VALIDATION)

**Date**: 2025-12-05  
**Status**: ✅ Validated

### Cluster Status Verification

**All 3 nodes verified**:
```
Node 10.0.0.170 (maria-01):
  wsrep_cluster_size = 3
  wsrep_local_state_comment = Synced

Node 10.0.0.171 (maria-02):
  wsrep_cluster_size = 3
  wsrep_local_state_comment = Synced

Node 10.0.0.172 (maria-03):
  wsrep_cluster_size = 3
  wsrep_local_state_comment = Synced
```

**Verification Command**:
```bash
for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
  ssh root@$ip "mysql -u root -p\"\$MARIADB_ROOT_PASSWORD\" -e \"SHOW STATUS LIKE 'wsrep_cluster_size'; SHOW STATUS LIKE 'wsrep_local_state_comment';\""
done
```

**Result**: ✅ All nodes show `wsrep_cluster_size = 3` and `wsrep_local_state_comment = Synced`

## Conclusion

✅ **MariaDB Galera HA cluster is operational with 3 nodes**  
✅ **All configuration files are clean (no unsupported variables)**  
✅ **Cluster is synchronized and ready for ProxySQL deployment**  
✅ **Cluster validated: wsrep_cluster_size=3, all nodes Synced**
