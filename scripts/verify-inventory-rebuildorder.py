#!/usr/bin/env python3
"""
Verify consistency of inventory and rebuild_order files
"""
import json
import yaml
import sys

print("PH1-04 - Verification of Inventory and Rebuild Order")
print("=" * 70)

# Load inventory
print("\n1. Loading ansible/inventory/hosts.yml...")
try:
    with open('ansible/inventory/hosts.yml', 'r', encoding='utf-8') as f:
        inventory = yaml.safe_load(f)
    print("   ✓ Inventory loaded successfully")
except Exception as e:
    print(f"   ✗ ERROR loading inventory: {e}")
    sys.exit(1)

# Load rebuild_order
print("\n2. Loading servers/rebuild_order_v3.json...")
try:
    with open('servers/rebuild_order_v3.json', 'r', encoding='utf-8') as f:
        rebuild_order = json.load(f)
    print("   ✓ Rebuild order loaded successfully")
except Exception as e:
    print(f"   ✗ ERROR loading rebuild_order: {e}")
    sys.exit(1)

# Count servers in inventory
print("\n3. Counting servers in inventory...")
all_hosts = set()
children = inventory.get('all', {}).get('children', {})
group_counts = {}
for group_name, group_data in children.items():
    hosts = group_data.get('hosts', {})
    host_count = len(hosts)
    group_counts[group_name] = host_count
    all_hosts.update(hosts.keys())

total_inventory = len(all_hosts)
print(f"   Total servers in inventory: {total_inventory}")

print("\n   Group breakdown:")
for group, count in sorted(group_counts.items()):
    print(f"     - {group}: {count}")

# Check rebuild_order metadata
print("\n4. Checking rebuild_order metadata...")
metadata = rebuild_order.get('metadata', {})
total_servers_rebuild = metadata.get('total_servers', 0)
total_batches = metadata.get('total_batches', 0)
excluded = metadata.get('excluded_servers', [])
batch_size = metadata.get('batch_size', 0)

print(f"   Total servers to rebuild: {total_servers_rebuild}")
print(f"   Total batches: {total_batches}")
print(f"   Batch size: {batch_size}")
print(f"   Excluded servers: {excluded}")

# Check rebuild_order servers
print("\n5. Checking rebuild_order servers...")
rebuild_servers = rebuild_order.get('servers', [])
rebuild_hostnames = {s['hostname'] for s in rebuild_servers}

print(f"   Servers in rebuild list: {len(rebuild_hostnames)}")

# Verify excluded servers are not in rebuild list
print("\n6. Verifying excluded servers...")
for excluded_host in excluded:
    if excluded_host in rebuild_hostnames:
        print(f"   ✗ ERROR: {excluded_host} should be excluded but is in rebuild list!")
    else:
        print(f"   ✓ {excluded_host} correctly excluded")

# Verify no duplicates in rebuild list
print("\n7. Checking for duplicates...")
if len(rebuild_servers) == len(rebuild_hostnames):
    print(f"   ✓ No duplicate hostnames in rebuild list")
else:
    print(f"   ✗ ERROR: Duplicate hostnames found!")

# Check volumes
print("\n8. Checking volumes...")
volumes_ok = True
zero_volumes = []
for server in rebuild_servers:
    volumes = server.get('volumes', [])
    if not volumes:
        if server.get('role_v3') not in ['lb-internal', 'lb-apigw']:
            zero_volumes.append(server['hostname'])
    else:
        for vol in volumes:
            size = vol.get('size_gb', 0)
            if size == 0:
                zero_volumes.append(f"{server['hostname']}:{vol.get('name', 'unknown')}")

if zero_volumes:
    print(f"   ✗ ERROR: Found volumes with size 0:")
    for item in zero_volumes:
        print(f"     - {item}")
    volumes_ok = False
else:
    print(f"   ✓ All volumes have valid sizes")

# Check batches
print("\n9. Checking batches...")
batches = rebuild_order.get('batches', [])
print(f"   Total batches: {len(batches)}")

all_batch_servers = set()
for batch in batches:
    batch_num = batch.get('batch_number', 0)
    servers = batch.get('servers', [])
    all_batch_servers.update(servers)
    print(f"     Batch {batch_num}: {len(servers)} servers")

if len(all_batch_servers) == len(rebuild_hostnames):
    print(f"   ✓ All servers are in batches")
else:
    missing = rebuild_hostnames - all_batch_servers
    extra = all_batch_servers - rebuild_hostnames
    if missing:
        print(f"   ✗ ERROR: Servers missing from batches: {missing}")
    if extra:
        print(f"   ✗ ERROR: Extra servers in batches: {extra}")

# Check expected totals
print("\n10. Final verification...")
print(f"   Expected total servers: 49")
print(f"   Actual inventory servers: {total_inventory}")
print(f"   Expected rebuild servers: 47 (49 - 2 excluded)")
print(f"   Actual rebuild servers: {total_servers_rebuild}")

all_ok = True
if total_inventory != 49:
    print(f"   ✗ ERROR: Inventory should have 49 servers, found {total_inventory}")
    all_ok = False
else:
    print(f"   ✓ Inventory has correct number of servers")

if total_servers_rebuild != 47:
    print(f"   ✗ ERROR: Rebuild order should have 47 servers, found {total_servers_rebuild}")
    all_ok = False
else:
    print(f"   ✓ Rebuild order has correct number of servers")

if total_batches != 10:
    print(f"   ✗ ERROR: Should have 10 batches, found {total_batches}")
    all_ok = False
else:
    print(f"   ✓ Correct number of batches")

# Expected groups
print("\n11. Checking expected groups...")
expected_groups = [
    'bastions', 'k8s_masters', 'k8s_workers',
    'db_postgres', 'db_mariadb', 'db_proxysql', 'db_temporal', 'db_analytics',
    'redis', 'rabbitmq', 'minio', 'vector_db',
    'vault', 'siem', 'monitoring', 'backup',
    'mail_core', 'mail_mx', 'builder',
    'apps_misc', 'lb_internal'
]

found_groups = set(children.keys())
missing_groups = set(expected_groups) - found_groups
extra_groups = found_groups - set(expected_groups)

if missing_groups:
    print(f"   ✗ Missing groups: {missing_groups}")
    all_ok = False
else:
    print(f"   ✓ All expected groups present")

if extra_groups:
    print(f"   ⚠ Extra groups found: {extra_groups}")

print("\n" + "=" * 70)
if all_ok and volumes_ok:
    print("✓✓✓ ALL VERIFICATIONS PASSED ✓✓✓")
    sys.exit(0)
else:
    print("✗✗✗ SOME VERIFICATIONS FAILED ✗✗✗")
    sys.exit(1)

