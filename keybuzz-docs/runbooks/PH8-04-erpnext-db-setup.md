# PH8-04 ERPNext MariaDB Database Setup

**Date**: 2025-12-04  
**Status**: ✅ Complete

## Summary

Successfully created ERPNext database (`erpnextdb`) and user (`erpnext`) on MariaDB Galera HA cluster with proper privileges, charset/collation, and ProxySQL integration. Verified end-to-end connectivity via Load Balancer (10.0.0.10:3306).

## Database Configuration

### Database Creation

**Database**: `erpnextdb`  
**Character Set**: `utf8mb4`  
**Collation**: `utf8mb4_unicode_ci`

**SQL Command**:
```sql
CREATE DATABASE IF NOT EXISTS erpnextdb
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
```

**Executed on**: maria-02 (10.0.0.171) - Cluster leader

### User Creation

**Username**: `erpnext`  
**Host**: `%` (all hosts)  
**Password**: Generated temporary password (will be migrated to Vault in PH8-05)

**Privileges Granted**:
- `SELECT, INSERT, UPDATE, DELETE` - Basic CRUD operations
- `CREATE, DROP, INDEX, ALTER` - Schema modifications
- `CREATE VIEW, SHOW VIEW` - View management
- `CREATE ROUTINE, ALTER ROUTINE, EXECUTE` - Stored procedures/functions
- `REFERENCES` - Foreign key constraints
- `CREATE TEMPORARY TABLES` - Temporary table creation
- `LOCK TABLES` - Table locking

**SQL Command**:
```sql
CREATE USER IF NOT EXISTS 'erpnext'@'%' IDENTIFIED BY '<password>';

GRANT 
  SELECT, INSERT, UPDATE, DELETE,
  CREATE, DROP, INDEX, ALTER,
  CREATE VIEW, SHOW VIEW,
  CREATE ROUTINE, ALTER ROUTINE, EXECUTE,
  REFERENCES,
  CREATE TEMPORARY TABLES,
  LOCK TABLES
ON erpnextdb.* TO 'erpnext'@'%';

FLUSH PRIVILEGES;
```

## Galera Replication Verification

**Cluster Status**:
- `wsrep_cluster_size = 3` ✅
- Database replicated to all 3 nodes:
  - maria-01 (10.0.0.170) ✅
  - maria-02 (10.0.0.171) ✅
  - maria-03 (10.0.0.172) ✅

**Verification Commands**:
```bash
# Check cluster size
mysql -u root -p<password> -e "SHOW STATUS LIKE 'wsrep_cluster_size';"

# Verify database on each node
mysql -u root -p<password> -e "SHOW DATABASES LIKE 'erpnextdb';"
```

## ProxySQL Integration

**User injected into ProxySQL**:
- proxysql-01 (10.0.0.173) ✅
- proxysql-02 (10.0.0.174) ✅

**ProxySQL Configuration**:
```sql
INSERT INTO mysql_users (username, password, default_hostgroup, active)
VALUES ('erpnext', '<password>', 0, 1)
ON DUPLICATE KEY UPDATE password='<password>', active=1;

LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
```

**Default Hostgroup**: `0` (write group)

## End-to-End Test via Load Balancer

**Test Script**: `scripts/mariadb_erpnext_test.sh`

**LB Endpoint**: `10.0.0.10:3306`

**Test Results**:
- ✅ Connection to MariaDB via LB successful
- ✅ Database access (`erpnextdb`) successful
- ✅ Table creation successful
- ✅ INSERT operation successful
- ✅ SELECT operation successful (returns `OK_FROM_LB`)

**Test Output**:
```
[INFO] Test 1: Connecting to MariaDB via LB...
[INFO]   ✅ Connection successful

[INFO] Test 2: Accessing erpnextdb...
[INFO]   ✅ Database access successful

[INFO] Test 3: Creating test table...
[INFO]   ✅ Table created

[INFO] Test 4: Inserting test data...
[INFO]   ✅ Data inserted

[INFO] Test 5: Reading data...
id  v
1   OK_FROM_LB
[INFO]   ✅ Data read successfully
```

## Connection String

**For Applications**:
```
mysql://erpnext:<password>@10.0.0.10:3306/erpnextdb
```

**Example**:
```bash
mysql -h 10.0.0.10 -P 3306 -u erpnext -p<password> erpnextdb
```

## Files Created/Modified

- `scripts/ph8-04-erpnext-db-setup.sh` - Complete ERPNext database setup script
- `scripts/mariadb_erpnext_test.sh` - End-to-end test script via LB
- `keybuzz-docs/runbooks/PH8-04-erpnext-db-setup.md` - This documentation

## Future Integration with Vault

**PH8-05** (planned):
- Migrate ERPNext password to Vault
- Use Vault dynamic credentials for ERPNext
- Rotate passwords automatically
- Integrate with Kubernetes secrets

**Current Status**: Using temporary password stored in script variables. Password will be migrated to Vault in next phase.

## Verification Commands

**Check database exists**:
```bash
mysql -h 10.0.0.10 -P 3306 -u root -p<password> -e "SHOW DATABASES LIKE 'erpnextdb';"
```

**Check user privileges**:
```bash
mysql -h 10.0.0.10 -P 3306 -u root -p<password> -e "SHOW GRANTS FOR 'erpnext'@'%';"
```

**Check ProxySQL users**:
```bash
mysql -h 10.0.0.173 -P 6032 -u admin -padmin -e "SELECT * FROM mysql_users WHERE username='erpnext';"
```

**Test connection as erpnext user**:
```bash
mysql -h 10.0.0.10 -P 3306 -u erpnext -p<password> erpnextdb -e "SELECT DATABASE();"
```

## Final Validation (PH8-FINAL-VALIDATION)

**Date**: 2025-12-05  
**Status**: ✅ Validated

### ERPNext User Verification

**User Status**: ✅ Exists and functional

**Verification**:
```bash
mysql -u root -p"$MARIADB_ROOT_PASSWORD" -e "SELECT User, Host FROM mysql.user WHERE User='erpnext';"
```

**Result**: User `erpnext@%` exists

### End-to-End Test via LB

**Test Script**: `scripts/mariadb_erpnext_test.sh`  
**LB Endpoint**: `10.0.0.10:3306`  
**Test Date**: 2025-12-05

**Test Results**:
```
[INFO] Test 1: Connecting to MariaDB via LB...
VERSION()
10.11.15-MariaDB-ubu2404
[INFO]   ✅ Connection successful

[INFO] Test 2: Accessing erpnextdb...
[INFO]   ✅ Database access successful

[INFO] Test 3: Creating test table...
[INFO]   ✅ Table created

[INFO] Test 4: Inserting test data...
[INFO]   ✅ Data inserted

[INFO] Test 5: Reading data...
id      v
1       OK_FROM_LB
[INFO]   ✅ Data read successfully

[INFO] ✅ All tests passed!
```

**Full Log**: `/opt/keybuzz/logs/phase8/mariadb_erpnext_test_final.log`

**Result**: ✅ All tests passed via LB endpoint

### ProxySQL Integration Status

**ProxySQL Status**: ✅ User integrated

**Verification**:
```bash
mysql -h 10.0.0.173 -P6032 -u admin -padmin -e "SELECT username, active FROM mysql_users WHERE username='erpnext';"
```

**Result**: User `erpnext` present in ProxySQL on both nodes (proxysql-01, proxysql-02)

## Conclusion

✅ **Database `erpnextdb` created with utf8mb4 charset**  
✅ **User `erpnext` created with required privileges**  
✅ **Database replicated across all 3 Galera nodes**  
✅ **User integrated into ProxySQL**  
✅ **End-to-end test via LB successful**  
✅ **Ready for ERPNext application deployment**  
✅ **ERPNext user validated: Connection, CREATE, INSERT, SELECT via LB all successful**

The ERPNext database is now ready for use. The database and user are properly configured with the required privileges, charset, and collation. All operations are verified to work through the Load Balancer endpoint (10.0.0.10:3306).

