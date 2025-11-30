#!/usr/bin/env python3
"""
List all servers and search for specific IP
"""
import os
import sys
import requests
import json

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

print(f"Searching for server with IP: {target_ip}")
print("=" * 70)

# Get all servers
url = 'https://api.hetzner.cloud/v1/servers'
response = requests.get(url, headers=headers)
response.raise_for_status()

data = response.json()
servers = data.get('servers', [])

print(f"Total servers found: {len(servers)}")
print()

# Search by IP
found_server = None
for server in servers:
    # Check public IP
    public_ip = server.get('public_net', {}).get('ipv4', {}).get('ip', '')
    
    if public_ip == target_ip:
        found_server = server
        break

if found_server:
    print("✓✓✓ SERVER FOUND! ✓✓✓")
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
    print(f"✗ Server with IP {target_ip} NOT FOUND in public IPs")
    print()
    print("Listing ALL servers with their public IPs:")
    print("=" * 70)
    print(f"{'Name':<30} {'ID':<12} {'Public IP':<20} {'Status':<15}")
    print("-" * 70)
    
    for server in sorted(servers, key=lambda x: x['name']):
        name = server['name']
        server_id = server['id']
        public_ip = server.get('public_net', {}).get('ipv4', {}).get('ip', 'N/A')
        status = server.get('status', 'N/A')
        print(f"{name:<30} {str(server_id):<12} {public_ip:<20} {status:<15}")
    
    print()
    print("=" * 70)
    print("Searching for similar IPs or checking if server might be in a different state...")
    
    # Check if any server has a similar IP
    for server in servers:
        public_ip = server.get('public_net', {}).get('ipv4', {}).get('ip', '')
        if '251.198' in public_ip or '65.21' in public_ip:
            print(f"Found similar IP: {server['name']} has IP {public_ip}")

