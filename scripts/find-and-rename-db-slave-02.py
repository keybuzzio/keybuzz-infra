#!/usr/bin/env python3
"""Find and rename db-slave-02"""
import os
import sys
import requests

token = os.environ.get('HETZNER_API_TOKEN')
if not token:
    # Load from file
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

headers = {'Authorization': f'Bearer {token}'}
url = 'https://api.hetzner.cloud/v1/servers'
response = requests.get(url, headers=headers)
servers = response.json().get('servers', [])

target_ip = '65.21.251.198'
target_id = None
target_name = None

for server in servers:
    ip = server.get('public_net', {}).get('ipv4', {}).get('ip', '')
    if ip == target_ip:
        target_id = server['id']
        target_name = server['name']
        print(f"Found server: {target_name} (ID: {target_id}, IP: {ip})")
        
        if target_name != 'db-postgres-03':
            print(f"Renaming {target_name} to db-postgres-03...")
            rename_url = f'https://api.hetzner.cloud/v1/servers/{target_id}'
            data = {'name': 'db-postgres-03'}
            response = requests.put(rename_url, headers=headers, json=data)
            response.raise_for_status()
            print("✓ Successfully renamed to db-postgres-03")
        else:
            print(f"✓ Server already named db-postgres-03")
        break
else:
    print(f"Server with IP {target_ip} not found")
    print("\nAll servers:")
    for s in sorted(servers, key=lambda x: x['name']):
        ip = s.get('public_net', {}).get('ipv4', {}).get('ip', 'N/A')
        print(f"  {s['name']:30} {s['id']:12} {ip}")

