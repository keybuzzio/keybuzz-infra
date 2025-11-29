#!/usr/bin/env python3
"""
Rename PostgreSQL servers in Hetzner Cloud via API
db-master-01 → db-postgres-01
db-slave-01 → db-postgres-02
db-slave-02 → db-postgres-03
"""
import os
import sys
import requests
import time

HETZNER_API_TOKEN = os.environ.get('HETZNER_API_TOKEN')
HETZNER_API_BASE = 'https://api.hetzner.cloud/v1'

if not HETZNER_API_TOKEN:
    print("ERROR: HETZNER_API_TOKEN environment variable not set")
    sys.exit(1)

renames = [
    ('db-master-01', 'db-postgres-01'),
    ('db-slave-01', 'db-postgres-02'),
    ('db-slave-02', 'db-postgres-03'),
]

headers = {
    'Authorization': f'Bearer {HETZNER_API_TOKEN}',
    'Content-Type': 'application/json'
}

def get_server_id(name):
    """Get server ID by name"""
    url = f'{HETZNER_API_BASE}/servers'
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    
    servers = response.json().get('servers', [])
    for server in servers:
        if server['name'] == name:
            return server['id']
    return None

def rename_server(server_id, new_name):
    """Rename server"""
    url = f'{HETZNER_API_BASE}/servers/{server_id}'
    data = {'name': new_name}
    response = requests.put(url, headers=headers, json=data)
    response.raise_for_status()
    return response.json()

def main():
    print("Renaming PostgreSQL servers in Hetzner Cloud...")
    print("=" * 60)
    
    for old_name, new_name in renames:
        print(f"\nProcessing: {old_name} → {new_name}")
        
        # Get server ID
        server_id = get_server_id(old_name)
        if not server_id:
            print(f"  ERROR: Server {old_name} not found in Hetzner Cloud")
            sys.exit(1)
        
        print(f"  Found server ID: {server_id}")
        
        # Rename server
        try:
            result = rename_server(server_id, new_name)
            print(f"  ✓ Successfully renamed to {new_name}")
            print(f"  Server status: {result['server']['status']}")
        except requests.exceptions.HTTPError as e:
            print(f"  ERROR: Failed to rename server: {e}")
            if e.response.status_code == 403:
                print("  → Check API token permissions")
            sys.exit(1)
        
        # Wait a bit between renames
        time.sleep(2)
    
    print("\n" + "=" * 60)
    print("Verification: Listing PostgreSQL servers...")
    
    # Verify renames
    url = f'{HETZNER_API_BASE}/servers'
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    
    servers = response.json().get('servers', [])
    postgres_servers = [s for s in servers if 'postgres' in s['name']]
    
    print(f"\nFound {len(postgres_servers)} PostgreSQL servers:")
    for server in sorted(postgres_servers, key=lambda x: x['name']):
        print(f"  - {server['name']} (ID: {server['id']}, Status: {server['status']})")
    
    # Check if all expected servers exist
    expected_names = ['db-postgres-01', 'db-postgres-02', 'db-postgres-03']
    found_names = [s['name'] for s in postgres_servers]
    
    if set(expected_names) == set(found_names):
        print("\n✓ All PostgreSQL servers renamed successfully!")
    else:
        print(f"\n⚠ Warning: Expected {expected_names}, found {found_names}")
        sys.exit(1)

if __name__ == '__main__':
    main()

