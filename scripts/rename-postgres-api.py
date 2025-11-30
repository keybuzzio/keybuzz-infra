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

# Load token from environment or file
HETZNER_API_TOKEN = os.environ.get('HETZNER_API_TOKEN')

if not HETZNER_API_TOKEN:
    # Try to load from hcloud.env
    env_file = '/opt/keybuzz/credentials/hcloud.env'
    if os.path.exists(env_file):
        with open(env_file, 'r') as f:
            for line in f:
                if line.startswith('export HETZNER_API_TOKEN='):
                    HETZNER_API_TOKEN = line.split('"')[1]
                    break

if not HETZNER_API_TOKEN:
    print("ERROR: HETZNER_API_TOKEN not found")
    sys.exit(1)

HETZNER_API_BASE = 'https://api.hetzner.cloud/v1'

renames = [
    ('db-master-01', 'db-postgres-01', '195.201.122.106'),
    ('db-slave-01', 'db-postgres-02', '91.98.169.31'),
    ('db-slave-02', 'db-postgres-03', '65.21.251.198'),
]

headers = {
    'Authorization': f'Bearer {HETZNER_API_TOKEN}',
    'Content-Type': 'application/json'
}

def get_server_by_name(name):
    """Get server by name"""
    url = f'{HETZNER_API_BASE}/servers'
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    
    servers = response.json().get('servers', [])
    for server in servers:
        if server['name'] == name:
            return server
    return None

def get_server_by_ip(ip):
    """Get server by IP"""
    url = f'{HETZNER_API_BASE}/servers'
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    
    servers = response.json().get('servers', [])
    for server in servers:
        if server.get('public_net', {}).get('ipv4', {}).get('ip') == ip:
            return server
    return None

def rename_server(server_id, new_name):
    """Rename server"""
    url = f'{HETZNER_API_BASE}/servers/{server_id}'
    data = {'name': new_name}
    response = requests.put(url, headers=headers, json=data)
    response.raise_for_status()
    return response.json()

def main():
    print("PH1-03 - Renaming PostgreSQL servers in Hetzner Cloud")
    print("=" * 60)
    print("")
    
    renamed = []
    
    for old_name, new_name, expected_ip in renames:
        print(f"Processing: {old_name} → {new_name}")
        print(f"Expected IP: {expected_ip}")
        
        # Try to find by name first
        server = get_server_by_name(old_name)
        
        # If not found, try by IP
        if not server:
            print(f"  Server {old_name} not found, searching by IP {expected_ip}...")
            server = get_server_by_ip(expected_ip)
        
        if not server:
            print(f"  ⚠ Server {old_name} ({expected_ip}) not found (may already be renamed)")
            # Check if new name already exists
            new_server = get_server_by_name(new_name)
            if new_server:
                print(f"  ✓ Server {new_name} already exists")
                renamed.append({'old': old_name, 'new': new_name, 'id': new_server['id'], 'ip': new_server.get('public_net', {}).get('ipv4', {}).get('ip', 'N/A')})
            continue
        
        server_id = server['id']
        server_ip = server.get('public_net', {}).get('ipv4', {}).get('ip', 'N/A')
        current_name = server['name']
        
        if current_name == new_name:
            print(f"  ✓ Server {new_name} ({server_ip}) already has correct name")
            renamed.append({'old': old_name, 'new': new_name, 'id': server_id, 'ip': server_ip})
            continue
        
        print(f"  Current name: {current_name}")
        print(f"  Server ID: {server_id}")
        print(f"  Server IP: {server_ip}")
        print(f"  Renaming to: {new_name}...")
        
        try:
            result = rename_server(server_id, new_name)
            print(f"  ✓ Successfully renamed to {new_name}")
            renamed.append({'old': old_name, 'new': new_name, 'id': server_id, 'ip': server_ip})
        except requests.exceptions.HTTPError as e:
            print(f"  ✗ Failed to rename: {e}")
            if e.response.status_code == 422:
                print(f"    (Server may already have this name)")
            else:
                sys.exit(1)
        
        # Wait between renames
        time.sleep(2)
        print("")
    
    # Verify final state
    print("=" * 60)
    print("Verification - PostgreSQL servers:")
    print("=" * 60)
    
    url = f'{HETZNER_API_BASE}/servers'
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    
    servers = response.json().get('servers', [])
    postgres_servers = [s for s in servers if 'postgres' in s['name'] or s['name'] in ['db-postgres-01', 'db-postgres-02', 'db-postgres-03']]
    
    print(f"\nFound {len(postgres_servers)} PostgreSQL servers:")
    for server in sorted(postgres_servers, key=lambda x: x['name']):
        print(f"  - {server['name']} (ID: {server['id']}, IP: {server.get('public_net', {}).get('ipv4', {}).get('ip', 'N/A')}, Status: {server['status']})")
    
    # Summary
    print("")
    print("=" * 60)
    print("Rename Summary:")
    print("=" * 60)
    for r in renamed:
        print(f"  ✓ {r['old']} → {r['new']} (ID: {r['id']}, IP: {r['ip']})")
    
    expected_names = ['db-postgres-01', 'db-postgres-02', 'db-postgres-03']
    found_names = [s['name'] for s in postgres_servers]
    
    if set(expected_names) == set(found_names):
        print("")
        print("✓ All PostgreSQL servers renamed successfully!")
        return 0
    else:
        print(f"\n⚠ Warning: Expected {expected_names}, found {found_names}")
        return 1

if __name__ == '__main__':
    sys.exit(main())

