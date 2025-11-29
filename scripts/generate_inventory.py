#!/usr/bin/env python3
"""
Generate Ansible inventory from servers_v3.tsv
"""
import csv
import sys
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

def role_to_group(role_v3):
    """Map role_v3 to Ansible group"""
    mapping = {
        'k8s-master': 'k8s_masters',
        'k8s-worker': 'k8s_workers',
        'db-postgres': 'db_postgres',
        'db-mariadb': 'db_mariadb',
        'db-proxysql': 'db_proxysql',
        'db-temporal': 'db_temporal',
        'db-analytics': 'db_analytics',
        'redis': 'redis',
        'rabbitmq': 'rabbitmq',
        'minio': 'minio',
        'vector-db': 'vector_db',
        'vault': 'vault',
        'siem': 'siem',
        'monitoring': 'monitoring',
        'backup': 'backup',
        'mail-core': 'mail_core',
        'mail-mx': 'mail_mx',
        'builder': 'builder',
        'lb-internal': 'lb_internal',
        'lb-apigw': 'apps_misc',
        'bastion-legacy': 'bastions',
        'bastion-v3': 'bastions',
        'app-temporal': 'apps_misc',
        'app-analytics': 'apps_misc',
        'app-crm': 'apps_misc',
        'app-etl': 'apps_misc',
        'app-nocode': 'apps_misc',
        'ml-platform': 'apps_misc',
        'llm-proxy': 'apps_misc',
    }
    return mapping.get(role_v3, 'apps_misc')

def main():
    tsv_file = 'servers/servers_v3.tsv'
    
    # Read TSV
    servers = []
    with open(tsv_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f, delimiter='\t')
        for row in reader:
            if row['HOSTNAME']:  # Skip empty lines
                servers.append(row)
    
    # Group by Ansible group
    groups = defaultdict(list)
    for server in servers:
        group = role_to_group(server['ROLE_V3'])
        groups[group].append(server)
    
    # Generate YAML
    print("---")
    print("# KeyBuzz v3 Ansible Inventory")
    print("# Generated from servers_v3.tsv")
    print("")
    print("all:")
    print("  vars:")
    print("    ansible_user: root")
    print("    ansible_python_interpreter: /usr/bin/python3")
    print("    ansible_ssh_private_key_file: /root/.ssh/id_rsa_keybuzz_v3")
    print("    os_version: ubuntu-24.04")
    print("")
    print("  children:")
    
    # Output groups
    group_order = [
        'bastions', 'k8s_masters', 'k8s_workers',
        'db_postgres', 'db_mariadb', 'db_proxysql', 'db_temporal', 'db_analytics',
        'redis', 'rabbitmq', 'minio', 'vector_db',
        'vault', 'siem', 'monitoring', 'backup',
        'mail_core', 'mail_mx', 'builder',
        'apps_misc', 'lb_internal'
    ]
    
    for group_name in group_order:
        if group_name in groups:
            print(f"    {group_name}:")
            print("      hosts:")
            for server in sorted(groups[group_name], key=lambda x: x['HOSTNAME']):
                hostname = server['HOSTNAME']
                ip_private = server['IP_PRIVEE']
                ip_public = server['IP_PUBLIQUE']
                role_v3 = server['ROLE_V3']
                logical_name = server.get('LOGICAL_NAME_V3', hostname)
                fqdn = server.get('FQDN', '')
                
                print(f"        {hostname}:")
                print(f"          ansible_host: {ip_private}")
                print(f"          ip_public: {ip_public}")
                print(f"          role_v3: {role_v3}")
                if logical_name and logical_name != hostname:
                    print(f"          logical_name_v3: {logical_name}")
                if fqdn:
                    print(f"          fqdn: {fqdn}")

if __name__ == '__main__':
    main()

