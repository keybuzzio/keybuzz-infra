#!/usr/bin/env python3
"""
Find server by IP in Hetzner Cloud
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

print(f"Searching for server with IP: {target_ip}")
print("=" * 60)

# Get all servers
url = 'https://api.hetzner.cloud/v1/servers'
response = requests.get(url, headers=headers)
response.raise_for_status()

data = response.json()
servers = data.get('servers', [])

print(f"Total servers found: {len(servers)}")
print()

# Search by IP (both public and private)
found_server = None
for server in servers:
    # Check public IP
    public_ip = server.get('public_net', {}).get('ipv4', {}).get('ip', '')
    
    # Check private IPs
    private_ips = []
    for private_net in server.get('private_net', []):
        ips = private_net.get('ip', [])
        if isinstance(ips, list):
            for ip_obj in ips:
                if isinstance(ip_obj, dict):
                    private_ips.append(ip_obj.get('ip', ''))
                elif isinstance(ip_obj, str):
                    private_ips.append(ip_obj)
        elif isinstance(ips, str):
            private_ips.append(ips)
    
    # Check if IP matches
    if public_ip == target_ip or target_ip in private_ips:
        found_server = server
        break

if found_server:
    print("✓ SERVER FOUND!")
    print("=" * 60)
    print(f"Name: {found_server['name']}")
    print(f"ID: {found_server['id']}")
    print(f"Public IP: {found_server.get('public_net', {}).get('ipv4', {}).get('ip', 'N/A')}")
    print(f"Status: {found_server.get('status', 'N/A')}")
    
    # Check private IPs
    private_nets = found_server.get('private_net', [])
    if private_nets:
        print(f"Private Networks: {len(private_nets)}")
        for pnet in private_nets:
            print(f"  - Network: {pnet.get('network', 'N/A')}")
            ips = pnet.get('ip', [])
            if ips:
                for ip_info in ips:
                    print(f"    IP: {ip_info.get('ip', 'N/A')}")
    
    print()
    print("=" * 60)
    
    # Rename if needed
    if found_server['name'] != 'db-postgres-03':
        print(f"Renaming {found_server['name']} to db-postgres-03...")
        rename_url = f"https://api.hetzner.cloud/v1/servers/{found_server['id']}"
        rename_data = {'name': 'db-postgres-03'}
        rename_response = requests.put(rename_url, headers=headers, json=rename_data)
        rename_response.raise_for_status()
        print("✓ Successfully renamed to db-postgres-03")
    else:
        print("✓ Server already named db-postgres-03")
        
else:
    print("✗ Server with IP 65.21.251.198 NOT FOUND")
    print()
    print("Listing ALL servers with their IPs:")
    print("=" * 60)
    for server in sorted(servers, key=lambda x: x['name']):
        name = server['name']
        server_id = server['id']
        public_ip = server.get('public_net', {}).get('ipv4', {}).get('ip', 'N/A')
        status = server.get('status', 'N/A')
        print(f"{name:30} | ID: {server_id:10} | IP: {public_ip:20} | Status: {status}")
        
        # Also show private IPs
        private_nets = server.get('private_net', [])
        for pnet in private_nets:
            ips = pnet.get('ip', [])
            if ips:
                for ip_info in ips:
                    priv_ip = ip_info.get('ip', '')
                    if priv_ip:
                        print(f"{'':30} | Private IP: {priv_ip}")

