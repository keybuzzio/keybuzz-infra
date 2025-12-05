# PH8-03 MariaDB via HAProxy + LB End-to-End

**Date**: 2025-12-04  
**Status**: ✅ Complete (Full Fix Applied)

## Installation Method

**ProxySQL Installation**: Via official .deb package (v2.6.2)  
- Downloaded from GitHub releases  
- Installed via `dpkg -i` on Ubuntu 24.04  
- Service enabled and started successfully

## Summary

Successfully configured HAProxy and Hetzner Load Balancer to expose MariaDB Galera HA cluster on a single endpoint (10.0.0.10:3306) and verified end-to-end connectivity.

## Architecture

```
Applications
    ↓
LB Hetzner (10.0.0.10:3306)
    ↓
HAProxy (haproxy-01/02:3306)
    ↓
MariaDB Galera Cluster (maria-01/02/03:3306)
```

## HAProxy Configuration

**Role**: `ansible/roles/mariadb_haproxy_v3`

**Configuration** (`/etc/haproxy/haproxy.cfg`):
```conf
# MariaDB Galera Cluster - Port 3306
listen mariadb
    mode tcp
    bind *:3306
    balance roundrobin
    option tcp-check
    tcp-check connect port 3306
    timeout client  1m
    timeout server  1m
    timeout connect 5s
    server maria-01 10.0.0.170:3306 check inter 2000 fall 2 rise 2
    server maria-02 10.0.0.171:3306 check inter 2000 fall 2 rise 2
    server maria-03 10.0.0.172:3306 check inter 2000 fall 2 rise 2
```

**Deployment**:
- Deployed on `haproxy-01` (10.0.0.11) and `haproxy-02` (10.0.0.12)
- Playbook: `ansible/playbooks/haproxy_mariadb_v3.yml`
- Verification: `ss -ntlp | grep 3306` on both HAProxy nodes

## Hetzner Load Balancer Configuration

**LB Name**: `lb-haproxy`  
**Private IP**: `10.0.0.10`  
**Service**: Port 3306 (TCP) → Port 3306  
**Targets**: 
- `haproxy-01` (10.0.0.11)
- `haproxy-02` (10.0.0.12)

**Configuration Command**:
```bash
hcloud load-balancer add-service lb-haproxy \
    --listen-port 3306 \
    --destination-port 3306 \
    --protocol tcp

hcloud load-balancer add-target lb-haproxy --type server --server haproxy-01
hcloud load-balancer add-target lb-haproxy --type server --server haproxy-02
```

**Script**: `scripts/configure_lbhaproxy_mariadb.sh`

## End-to-End Test

**Script**: `scripts/mariadb_ha_end_to_end_via_lb.sh`

**Test Results**:
- ✅ Connection to MariaDB via LB (10.0.0.10:3306)
- ✅ Database creation (`kb_mariadb_lb_test`)
- ✅ Table creation (`lb_test_table`)
- ✅ INSERT operations successful
- ✅ SELECT operations successful
- ✅ Cluster status verified (`wsrep_cluster_size = 3`)

**Test Output**:
```
[INFO] Test 1: Connecting to MariaDB via LB...
[INFO]   ✅ Connection successful

[INFO] Test 2: Creating database kb_mariadb_lb_test...
[INFO]   ✅ Database created

[INFO] Test 3: Creating table lb_test_table...
[INFO]   ✅ Table created

[INFO] Test 4: Inserting test data...
[INFO]   ✅ Data inserted

[INFO] Test 5: Reading data...
[INFO]   ✅ Data read successfully

[INFO] Test 6: Checking Galera cluster status...
wsrep_cluster_size = 3
wsrep_local_state_comment = Synced
```

## Endpoint for Applications

**Connection String**:
```
mysql://root:<password>@10.0.0.10:3306/<database>
```

**Example**:
```bash
mysql -h 10.0.0.10 -P 3306 -u root -p<password> -e "SHOW DATABASES;"
```

## Files Created/Modified

- `ansible/roles/mariadb_haproxy_v3/tasks/main.yml` - HAProxy role tasks
- `ansible/roles/mariadb_haproxy_v3/handlers/main.yml` - HAProxy handlers
- `ansible/playbooks/haproxy_mariadb_v3.yml` - HAProxy deployment playbook
- `scripts/mariadb_ha_end_to_end_via_lb.sh` - End-to-end test script
- `scripts/configure_lbhaproxy_mariadb.sh` - LB configuration script
- `keybuzz-docs/runbooks/PH8-03-mariadb-haproxy-lb-e2e.md` - This documentation

## Verification Commands

**Check HAProxy on haproxy nodes**:
```bash
ss -ntlp | grep 3306
systemctl status haproxy
```

**Check LB configuration**:
```bash
hcloud load-balancer describe lb-haproxy
```

**Test connection**:
```bash
mysql -h 10.0.0.10 -P 3306 -u root -p<password> -e "SELECT VERSION();"
```

**Check cluster status via LB**:
```bash
mysql -h 10.0.0.10 -P 3306 -u root -p<password> -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
```

## Final Validation (PH8-FINAL-VALIDATION)

**Date**: 2025-12-05  
**Status**: ✅ Validated

### HAProxy Verification

**haproxy-01 (10.0.0.11)**:
```
Port 3306: LISTEN
Process: haproxy (pid=138246)
Status: ✅ Active
```

**haproxy-02 (10.0.0.12)**:
```
Port 3306: LISTEN
Process: haproxy (pid=158016)
Status: ✅ Active
```

**Verification Command**:
```bash
ssh root@10.0.0.11 "ss -ntlp | grep 3306"
ssh root@10.0.0.12 "ss -ntlp | grep 3306"
```

**Result**: ✅ Both HAProxy nodes listening on port 3306

### Load Balancer Verification

**LB Name**: `lb-haproxy`  
**Service**: Port 3306 (TCP) → Port 3306  
**Status**: ✅ Configured

**Verification**:
```bash
hcloud load-balancer describe lb-haproxy | grep -A 5 "3306"
```

**Result**: ✅ Service 3306 exists and is configured

## Conclusion

✅ **HAProxy configured and deployed on haproxy-01/02**  
✅ **Hetzner LB configured for MariaDB (10.0.0.10:3306)**  
✅ **End-to-end tests successful**  
✅ **Single endpoint available for applications: `mysql://root:<pwd>@10.0.0.10:3306/<db>`**  
✅ **HAProxy validated: Port 3306 listening on both nodes**  
✅ **Load Balancer validated: Service 3306 configured**

The MariaDB Galera HA cluster is now accessible via a single endpoint through HAProxy and the Hetzner Load Balancer, providing high availability and load balancing for database connections.

