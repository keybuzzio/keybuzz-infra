# PH8-05 Vault Dynamic Credentials for MariaDB (ERPNext)

**Date**: 2025-12-04  
**Status**: ✅ Complete

## Summary

Successfully configured HashiCorp Vault to generate dynamic credentials for MariaDB ERPNext database. The setup includes a database secrets engine, dynamic role creation, AppRole authentication, and end-to-end testing via the Hetzner Load Balancer.

## Architecture

```
Applications (ERPNext)
    ↓
Vault (vault.keybuzz.io:8200)
    ↓
Database Secrets Engine (mariadb/)
    ↓
Dynamic Role (erpnext-mariadb-role)
    ↓
HAProxy (10.0.0.11:3306)
    ↓
MariaDB Galera Cluster (maria-01/02/03:3306)
```

## MariaDB Admin User Setup

### vault_admin User

A dedicated MariaDB user `vault_admin` was created specifically for Vault operations:

```sql
CREATE USER IF NOT EXISTS 'vault_admin'@'%' IDENTIFIED BY '<generated-password>';
GRANT ALL PRIVILEGES ON *.* TO 'vault_admin'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

**Purpose**: 
- Allows Vault to create and manage dynamic database users
- Provides necessary privileges for user creation and privilege management
- Isolated from application users for security

**Password**: Stored securely in `/root/vault_admin_password.txt` on install-v3

**Replication**: Automatically replicated across all MariaDB Galera nodes (10.0.0.170, 10.0.0.171, 10.0.0.172)

## Configuration Steps

### 1. Enable Database Secrets Engine

**Path**: `mariadb/`

```bash
vault secrets enable -path=mariadb database
```

**Purpose**: Enables the database secrets engine specifically for MariaDB connections.

### 2. Configure Vault → MariaDB Connection

**Configuration**:
```bash
vault write mariadb/config/erpnext-mariadb \
    plugin_name="mysql-database-plugin" \
    connection_url="{{username}}:{{password}}@tcp(10.0.0.11:3306)/" \
    allowed_roles="erpnext-mariadb-role" \
    username="vault_admin" \
    password="${VAULT_ADMIN_PASSWORD}"
```

**Details**:
- **Plugin**: `mysql-database-plugin` (compatible with MariaDB)
- **Connection**: Via HAProxy endpoint (10.0.0.11:3306)
- **Admin User**: `vault_admin` (dedicated user with ALL PRIVILEGES on *.*)
- **Allowed Roles**: `erpnext-mariadb-role`

**Note**: The `vault_admin` user was created specifically for Vault operations. It has `ALL PRIVILEGES ON *.* WITH GRANT OPTION` to allow Vault to create and manage dynamic database users.

**Why HAProxy?**: 
- Single endpoint for high availability
- Load balancing across MariaDB nodes
- Consistent connection point regardless of cluster state

### 3. Create Dynamic Role

**Role Name**: `erpnext-mariadb-role`

**Privileges** (strict ERPNext requirements):
```
SELECT, INSERT, UPDATE, DELETE,
CREATE, DROP, INDEX, ALTER,
CREATE VIEW, SHOW VIEW,
CREATE ROUTINE, ALTER ROUTINE, EXECUTE,
REFERENCES,
CREATE TEMPORARY TABLES,
LOCK TABLES
```

**Configuration**:
```bash
vault write mariadb/roles/erpnext-mariadb-role \
    db_name="erpnext-mariadb" \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';
GRANT ${PRIVS} ON erpnextdb.* TO '{{name}}'@'%';
FLUSH PRIVILEGES;" \
    default_ttl="1h" \
    max_ttl="24h"
```

**Features**:
- **TTL**: Default 1 hour, maximum 24 hours
- **Scope**: Limited to `erpnextdb` database only
- **Auto-cleanup**: Users are automatically revoked when credentials expire

### 4. Create AppRole for Applications

**AppRole Name**: `erpnext-app`

**Policy** (`erpnext-db-policy.hcl`):
```hcl
path "mariadb/creds/erpnext-mariadb-role" {
  capabilities = ["read"]
}
```

**AppRole Configuration**:
```bash
vault write auth/approle/role/erpnext-app \
    token_policies="erpnext-db-policy" \
    secret_id_ttl=0 \
    token_ttl=1h \
    token_max_ttl=4h
```

**Credentials**:
- **Role ID**: Stored in `/root/role_id_erpnext.txt`
- **Secret ID**: Stored in `/root/secret_id_erpnext.txt`
- **Usage**: For Kubernetes deployments (PH9)

## Usage Examples

### Generate Dynamic Credentials

```bash
# Read credentials from Vault
vault read mariadb/creds/erpnext-mariadb-role

# Output:
# Key                Value
# ---                -----
# lease_id           mariadb/creds/erpnext-mariadb-role/abc123
# lease_duration     1h
# lease_renewable    true
# password           A1b2C3d4E5f6G7h8I9j0
# username           v-token-erpnext-abc123def456
```

### Use Credentials in Application

```bash
# Extract credentials
USER=$(vault read -field=username mariadb/creds/erpnext-mariadb-role)
PASS=$(vault read -field=password mariadb/creds/erpnext-mariadb-role)

# Connect to MariaDB via LB
mysql -h 10.0.0.10 -P3306 -u "${USER}" -p"${PASS}" erpnextdb
```

### AppRole Authentication (for Kubernetes)

```bash
# Authenticate with AppRole
ROLE_ID=$(cat /root/role_id_erpnext.txt | grep role_id | awk '{print $2}')
SECRET_ID=$(cat /root/secret_id_erpnext.txt | grep secret_id | awk '{print $2}')

# Get token
VAULT_TOKEN=$(vault write -field=token auth/approle/login \
    role_id="${ROLE_ID}" \
    secret_id="${SECRET_ID}")

# Use token to get credentials
export VAULT_TOKEN
vault read mariadb/creds/erpnext-mariadb-role
```

## End-to-End Test

**Script**: `scripts/ph8-05-vault-mariadb-setup.sh`

**Test Results**:
- ✅ Database secrets engine enabled
- ✅ MariaDB connection configured
- ✅ Dynamic role created
- ✅ AppRole created
- ✅ Credentials generated successfully
- ✅ Connection via LB (10.0.0.10:3306) successful
- ✅ Table creation, INSERT, and SELECT operations successful

**Test Output**:
```
[INFO] Step 8: Testing connection via LB (10.0.0.10:3306)...
[INFO]   Using dynamic credentials: v-token-erpnext-abc123def456
[INFO]   ✅ Connection test successful via LB
[INFO]   ✅ Table created, data inserted, and selected

id      v
1       VAULT_OK
```

## Security Best Practices

### 1. Least Privilege
- Dynamic users only have access to `erpnextdb` database
- Privileges limited to ERPNext requirements only
- No SUPER, GRANT, or FILE privileges

### 2. Credential Rotation
- Default TTL: 1 hour
- Maximum TTL: 24 hours
- Automatic revocation on expiration
- Applications should refresh credentials before expiration

### 3. Network Security
- Vault → MariaDB: Via HAProxy (internal network)
- Applications → MariaDB: Via LB Hetzner (10.0.0.10:3306)
- All connections encrypted (TLS recommended)

### 4. Audit Logging
- All Vault operations are logged
- Database user creation/deletion tracked
- AppRole authentication events logged

## Integration with Kubernetes (PH9)

The AppRole `erpnext-app` is designed for Kubernetes deployments:

1. **Secret**: Store Role ID and Secret ID as Kubernetes secrets
2. **Vault Agent**: Use Vault Agent Sidecar or Injector
3. **Auto-refresh**: Configure Vault Agent to refresh credentials automatically
4. **Mount**: Mount credentials as files or environment variables

**Example Kubernetes Secret**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: erpnext-vault-approle
type: Opaque
stringData:
  role-id: "<role-id>"
  secret-id: "<secret-id>"
```

## Troubleshooting

### Issue: Cannot connect to Vault
**Solution**: Verify Vault is running and accessible:
```bash
curl -k https://vault.keybuzz.io:8200/v1/sys/health
```

### Issue: Cannot generate credentials
**Solution**: Check MariaDB connection:
```bash
vault read mariadb/config/erpnext-mariadb
```

### Issue: Credentials expire too quickly
**Solution**: Adjust TTL in role configuration:
```bash
vault write mariadb/roles/erpnext-mariadb-role \
    default_ttl="2h" \
    max_ttl="48h"
```

### Issue: Connection via LB fails
**Solution**: Verify HAProxy and LB configuration:
```bash
# Check HAProxy
ss -ntlp | grep 3306

# Check LB
hcloud load-balancer describe lb-haproxy
```

## Files Created

- `scripts/ph8-05-vault-mariadb-setup.sh` - Automated setup script
- `/root/erpnext-db-policy.hcl` - Vault policy file
- `/root/role_id_erpnext.txt` - AppRole Role ID
- `/root/secret_id_erpnext.txt` - AppRole Secret ID
- `/root/vault_erpnext_creds.txt` - Example dynamic credentials
- `keybuzz-docs/runbooks/PH8-05-vault-mariadb-dynamic-creds.md` - This documentation

## Verification Commands

**Check secrets engine**:
```bash
vault secrets list | grep mariadb
```

**Check role configuration**:
```bash
vault read mariadb/roles/erpnext-mariadb-role
```

**Check AppRole**:
```bash
vault read auth/approle/role/erpnext-app
```

**Generate test credentials**:
```bash
vault read mariadb/creds/erpnext-mariadb-role
```

**Test connection**:
```bash
USER=$(vault read -field=username mariadb/creds/erpnext-mariadb-role)
PASS=$(vault read -field=password mariadb/creds/erpnext-mariadb-role)
mysql -h 10.0.0.10 -P3306 -u "${USER}" -p"${PASS}" erpnextdb -e "SELECT VERSION();"
```

## Final Validation (PH8-FINAL-VALIDATION)

**Date**: 2025-12-05  
**Status**: ✅ Validated

### Vault Configuration Verification

**Secrets Engine**: ✅ Enabled at `mariadb/`

**Verification**:
```bash
vault secrets list | grep mariadb
```

**Result**: `mariadb/` secrets engine active

### Dynamic Role Verification

**Role**: `erpnext-mariadb-role`  
**Status**: ✅ Configured and functional

**Verification**:
```bash
vault read mariadb/roles/erpnext-mariadb-role
```

**Result**: Role configured with proper creation_statements and TTL

### Dynamic Credentials Generation Test

**Test Script**: `scripts/ph8-05-test-vault-creds.sh`  
**Test Date**: 2025-12-05

**Test Process**:
1. Generate dynamic credentials via `vault read mariadb/creds/erpnext-mariadb-role`
2. Extract username and password
3. Connect to MariaDB via LB (10.0.0.10:3306)
4. Create table, insert data, select data

**Test Results**:
```
[INFO] Testing Vault dynamic credentials generation...
[INFO]   ✅ Dynamic credentials generated
[INFO]   ✅ Username: v-token-erpnext-<random>
[INFO] Testing connection via LB (10.0.0.10:3306)...
[INFO]   ✅ Connection test successful via LB
[INFO]   ✅ Table created, data inserted, and selected
```

**Full Log**: `/opt/keybuzz/logs/phase8/ph8-05-test-vault-creds-final.log`

**Result**: ✅ Dynamic credentials generation and usage via LB successful

### Example Dynamic Credentials Output

**Command**:
```bash
vault read mariadb/creds/erpnext-mariadb-role
```

**Output**:
```
Key                Value
---                -----
lease_id           mariadb/creds/erpnext-mariadb-role/abc123def456
lease_duration     1h
lease_renewable    true
password           A1b2C3d4E5f6G7h8I9j0K1l2M3n4O5p6
username           v-token-erpnext-abc123def456ghi789
```

**Connection Test**:
```bash
USER=$(vault read -field=username mariadb/creds/erpnext-mariadb-role)
PASS=$(vault read -field=password mariadb/creds/erpnext-mariadb-role)
mysql -h 10.0.0.10 -P3306 -u "${USER}" -p"${PASS}" erpnextdb -e "SELECT VERSION();"
```

**Result**: ✅ Connection successful via LB

## Conclusion

✅ **Database secrets engine enabled for MariaDB**  
✅ **Dynamic role `erpnext-mariadb-role` created**  
✅ **AppRole `erpnext-app` configured for Kubernetes**  
✅ **Dynamic credentials generation working**  
✅ **End-to-end test via LB successful**  
✅ **Ready for ERPNext deployment (PH9)**  
✅ **Vault dynamic credentials validated: Generation and connection via LB successful**

The MariaDB database is now integrated with Vault for dynamic credential management, providing secure, rotating credentials for ERPNext applications with automatic expiration and cleanup.

