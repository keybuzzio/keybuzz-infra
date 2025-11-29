#!/usr/bin/env python3
"""
Generate rebuild_order_v3.json from servers_v3.tsv
"""
import csv
import json
from datetime import datetime
from collections import defaultdict

def get_volume_size(role_v3):
    """Get volume size based on role"""
    sizes = {
        'k8s-master': 20,
        'k8s-worker': 50,
        'db-postgres': 100,
        'db-mariadb': 100,
        'db-proxysql': 20,
        'db-temporal': 50,
        'db-analytics': 50,
        'redis': 20,
        'rabbitmq': 30,
        'minio': 200,
        'vault': 20,
        'backup': 500,
        'monitoring': 50,
        'builder': 100,
        'vector-db': 50,
        'mail-core': 30,
        'mail-mx': 20,
        'lb-internal': 10,
        'lb-apigw': 20,
        'app-temporal': 30,
        'app-analytics': 30,
        'app-crm': 20,
        'app-etl': 30,
        'app-nocode': 30,
        'ml-platform': 50,
        'llm-proxy': 30,
        'siem': 50,
    }
    return sizes.get(role_v3, 20)

def main():
    tsv_file = 'servers/servers_v3.tsv'
    batch_size = 5
    
    # Read TSV
    servers = []
    with open(tsv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f, delimiter='\t')
        for row in reader:
            if row['HOSTNAME'] and row['HOSTNAME'] not in ['install-01', 'install-v3']:
                servers.append(row)
    
    # Build server list for rebuild
    rebuild_servers = []
    for server in servers:
        role_v3 = server['ROLE_V3']
        volume_size = get_volume_size(role_v3)
        
        server_obj = {
            'hostname': server['HOSTNAME'],
            'ip_public': server['IP_PUBLIQUE'],
            'ip_private': server['IP_PRIVEE'],
            'role_v3': role_v3,
            'region': 'nbg1',  # Default region
            'server_type': '',  # Can be filled later
            'volumes': []
        }
        
        # Add logical_name_v3 if present
        if server.get('LOGICAL_NAME_V3'):
            server_obj['logical_name_v3'] = server['LOGICAL_NAME_V3']
        
        # Add volume if role requires one (most roles do)
        if role_v3 not in ['lb-internal', 'lb-apigw']:  # Load balancers may not need volumes
            server_obj['volumes'].append({
                'name': f"{server['HOSTNAME']}-data",
                'size_gb': volume_size,
                'type': 'data'
            })
        
        rebuild_servers.append(server_obj)
    
    # Create batches
    batches = []
    for i in range(0, len(rebuild_servers), batch_size):
        batch_servers = rebuild_servers[i:i+batch_size]
        batches.append({
            'batch_number': len(batches) + 1,
            'servers': [s['hostname'] for s in batch_servers]
        })
    
    # Build final JSON
    result = {
        'metadata': {
            'created': datetime.now().strftime('%Y-%m-%d'),
            'purpose': 'Ordered list of servers to rebuild for KeyBuzz v3',
            'batch_size': batch_size,
            'excluded_servers': ['install-01', 'install-v3'],
            'total_servers': len(rebuild_servers),
            'total_batches': len(batches)
        },
        'servers': rebuild_servers,
        'batches': batches
    }
    
    # Write JSON
    output_file = 'servers/rebuild_order_v3.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
    
    print(f"Generated {output_file}")
    print(f"Total servers: {len(rebuild_servers)}")
    print(f"Total batches: {len(batches)}")

if __name__ == '__main__':
    main()

