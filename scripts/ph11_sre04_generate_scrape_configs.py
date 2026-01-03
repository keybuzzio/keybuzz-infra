#!/usr/bin/env python3
"""
PH11-SRE-04: Generate Prometheus scrape configs from servers_v3.tsv
Generates static_configs for external VMs (non-K8s)
"""

import csv
import yaml
import sys
from pathlib import Path

# Server groups to scrape
SCRAPE_GROUPS = {
    "db_postgres": {
        "role": "db-postgres",
        "port": 9100,
        "job_name": "node_exporter_postgres"
    },
    "patroni": {
        "role": "db-postgres",
        "port": 8008,
        "job_name": "patroni",
        "metrics_path": "/metrics"
    },
    "redis": {
        "role": "redis",
        "port": 9100,
        "job_name": "node_exporter_redis"
    },
    "rabbitmq": {
        "role": "rabbitmq",
        "port": 9100,
        "job_name": "node_exporter_rabbitmq"
    },
    "mariadb": {
        "role": "db-mariadb",
        "port": 9100,
        "job_name": "node_exporter_mariadb"
    },
    "proxysql": {
        "role": "db-proxysql",
        "port": 9100,
        "job_name": "node_exporter_proxysql"
    },
    "haproxy": {
        "role": "lb-internal",
        "port": 9100,
        "job_name": "node_exporter_haproxy"
    },
    "vault": {
        "role": "vault",
        "port": 9100,
        "job_name": "node_exporter_vault"
    },
    "monitoring": {
        "roles": ["monitoring", "siem", "backup"],
        "port": 9100,
        "job_name": "node_exporter_monitoring"
    },
    "mail": {
        "role": "mail-core",
        "port": 9100,
        "job_name": "node_exporter_mail"
    }
}


def read_servers(tsv_path):
    """Read servers from TSV file"""
    servers = []
    with open(tsv_path, 'r') as f:
        reader = csv.DictReader(f, delimiter='\t')
        for row in reader:
            servers.append(row)
    return servers


def generate_scrape_configs(servers):
    """Generate Prometheus scrape configs"""
    configs = []
    
    for group_name, group_config in SCRAPE_GROUPS.items():
        targets = []
        
        for server in servers:
            role = server.get('ROLE_V3', '')
            private_ip = server.get('IP_PRIVEE', '')
            hostname = server.get('LOGICAL_NAME_V3', server.get('HOSTNAME', ''))
            
            # Skip LBs and empty IPs
            if not private_ip or private_ip in ['10.0.0.10', '10.0.0.20']:
                continue
            
            # Check if server matches this group
            if 'roles' in group_config:
                if role in group_config['roles']:
                    targets.append({
                        'ip': private_ip,
                        'hostname': hostname
                    })
            elif role == group_config.get('role'):
                targets.append({
                    'ip': private_ip,
                    'hostname': hostname
                })
        
        if targets:
            job = {
                'job_name': group_config['job_name'],
                'static_configs': [{
                    'targets': [f"{t['ip']}:{group_config['port']}" for t in targets],
                    'labels': {
                        'group': group_name
                    }
                }],
                'relabel_configs': [
                    {
                        'source_labels': ['__address__'],
                        'target_label': 'instance',
                        'regex': '([^:]+):\\d+',
                        'replacement': '${1}'
                    }
                ]
            }
            configs.append(job)
    
    return configs


def main():
    script_dir = Path(__file__).parent
    tsv_path = script_dir.parent / 'servers' / 'servers_v3.tsv'
    output_path = script_dir.parent / 'k8s' / 'observability' / 'prometheus-additional-scrape-configs.yaml'
    
    if not tsv_path.exists():
        print(f"ERROR: {tsv_path} not found")
        sys.exit(1)
    
    servers = read_servers(tsv_path)
    configs = generate_scrape_configs(servers)
    
    # Ensure output directory exists
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Write YAML
    with open(output_path, 'w') as f:
        yaml.dump(configs, f, default_flow_style=False, sort_keys=False)
    
    print(f"Generated scrape configs: {output_path}")
    print(f"Jobs: {[c['job_name'] for c in configs]}")
    
    # Also print for verification
    print("\n--- Generated config ---")
    print(yaml.dump(configs, default_flow_style=False, sort_keys=False))


if __name__ == '__main__':
    main()
