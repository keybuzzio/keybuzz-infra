#!/usr/bin/env python3
"""
Exhaustive search for server with IP 65.21.251.198
Includes all server states and pagination
"""
import os
import sys
import requests

# Load token
token = os.environ.get('HETZNER_API_TOKEN')
if not token:
    env_file = '/opt/keybuzz/credentials/hcloud.env'
    if os.path.exists(env_file):
        with open(env_file, 'r') as f:
            for line in f:
                if 'HETZNER_API_TOKEN=' in line:
                    token = line.split('"')[1]
                    break

if not token:
    print("ERROR: Token not found")
    sys.exit(1)

target_ip = '65.21.251.198'
headers = {'Authorization': f'Bearer {token}'}

print(f"Exhaustive search for server with IP: {target_ip}")
print("=" * 70)

# Get ALL servers with pagination
all_servers = []
url = 'https://api.hetzner.cloud/v1/servers'
page = 1
per_page = 50

while True:
    params = {'page': page, 'per_page': per_page}
    response = requests.get(url, headers=headers, params=params)
    response.raise_for_status()
    
    data = response.json()
    servers = data.get('servers', [])
    
    if not servers:
        break
    
    all_servers.extend(servers)
    print(f"Page {page}: Found {len(servers)} servers (Total so far: {len(all_servers)})")
    
    # Check if there's a next page
    meta = data.get('meta', {})
    pagination = meta.get('pagination', {})
    if pagination.get('next_page') is None:
        break
    
    page += 1

print(f"\nTotal servers found across all pages: {len(all_servers)}")
print("=" * 70)

# Search by IP in all servers
found_server = None
for server in all_servers:
    # Check public IP
    public_ip = server.get('public_net', {}).get('ipv4', {}).get('ip', '')
    
    if public_ip == target_ip:
        found_server = server
        break

if found_server:
    print("\n✓✓✓ SERVER FOUND! ✓✓✓")
    print("=" * 70)
    print(f"Name: {found_server['name']}")
    print(f"ID: {found_server['id']}")
    print(f"Public IP: {found_server.get('public_net', {}).get('ipv4', {}).get('ip', 'N/A')}")
    print(f"Status: {found_server.get('status', 'N/A')}")
    print()
    print("=" * 70)
    
    # Rename if needed
    if found_server['name'] != 'db-postgres-03':
        print(f"Renaming {found_server['name']} to db-postgres-03...")
        rename_url = f"https://api.hetzner.cloud/v1/servers/{found_server['id']}"
        rename_data = {'name': 'db-postgres-03'}
        rename_response = requests.put(rename_url, headers=headers, json=rename_data)
        rename_response.raise_for_status()
        print("✓✓✓ Successfully renamed to db-postgres-03 ✓✓✓")
        
        # Verify
        verify_response = requests.get(rename_url, headers=headers)
        verify_response.raise_for_status()
        updated_server = verify_response.json().get('server', {})
        print(f"✓ Verified: Server is now named {updated_server.get('name', 'N/A')}")
    else:
        print("✓ Server already named db-postgres-03")
        
else:
    print(f"\n✗ Server with IP {target_ip} NOT FOUND in any server state")
    print()
    print("Checking for servers with similar IPs (65.21.x.x)...")
    print("=" * 70)
    
    similar_servers = []
    for server in all_servers:
        public_ip = server.get('public_net', {}).get('ipv4', {}).get('ip', '')
        if public_ip.startswith('65.21.'):
            similar_servers.append((server['name'], public_ip, server['status']))
    
    if similar_servers:
        print("Servers with IPs starting with 65.21.x.x:")
        for name, ip, status in similar_servers:
            print(f"  - {name}: {ip} ({status})")
    else:
        print("No servers found with IPs starting with 65.21.x.x")
    
    print()
    print("All servers sorted by name:")
    print("=" * 70)
    print(f"{'Name':<30} {'ID':<12} {'Public IP':<20} {'Status':<15}")
    print("-" * 70)
    
    for server in sorted(all_servers, key=lambda x: x['name']):
        name = server['name']
        server_id = server['id']
        public_ip = server.get('public_net', {}).get('ipv4', {}).get('ip', 'N/A')
        status = server.get('status', 'N/A')
        print(f"{name:<30} {str(server_id):<12} {public_ip:<20} {status:<15}")

