#!/usr/bin/env python3
"""
Generate Volume Plan v3 - PH3-01
Creates a complete plan for volumes to be managed in PHASE 3.
Reads servers_v3.tsv and generates volume_plan_v3.json with target volumes.
"""

import csv
import json
from datetime import datetime
from pathlib import Path

# Mapping role_v3 to volume size (GB)
ROLE_SIZE_MAP = {
    "k8s-master": 20,
    "k8s-worker": 50,
    "db-postgres": 100,
    "db-mariadb": 100,
    "db-proxysql": 20,
    "db-temporal": 50,
    "db-analytics": 50,
    "redis": 20,
    "rabbitmq": 30,
    "minio": 200,
    "vault": 20,
    "backup": 500,
    "vector-db": 50,
    "mail-core": 50,
    "mail-mx": 30,
    "builder": 20,
    "apps_misc": 20,
    "lb-internal": 10,
    "siem": 50,
    "monitoring": 50,
}

# Additional mappings for app-* roles that should be grouped as apps_misc
APP_ROLES = {
    "app-temporal": "apps_misc",
    "app-analytics": "apps_misc",
    "app-crm": "apps_misc",
    "app-etl": "apps_misc",
    "app-nocode": "apps_misc",
    "llm-proxy": "apps_misc",
    "ml-platform": "apps_misc",
    "lb-apigw": "apps_misc",
}


def normalize_role_for_mountpoint(role_v3: str) -> str:
    """Convert role_v3 to mountpoint path format."""
    # Convert app-* roles to apps_misc for mountpoint
    if role_v3 in APP_ROLES:
        return "apps_misc"
    # Replace dashes with underscores for mountpoint
    return role_v3.replace("-", "_")


def get_volume_size(role_v3: str) -> int:
    """Get volume size in GB for a given role_v3."""
    # Check if it's an app role that should be grouped
    if role_v3 in APP_ROLES:
        mapped_role = APP_ROLES[role_v3]
        return ROLE_SIZE_MAP.get(mapped_role, 20)
    return ROLE_SIZE_MAP.get(role_v3, 20)  # Default to 20GB if not found


def main():
    script_dir = Path(__file__).parent
    infra_dir = script_dir.parent
    
    tsv_file = infra_dir / "servers" / "servers_v3.tsv"
    
    if not tsv_file.exists():
        print(f"Error: {tsv_file} not found")
        return 1
    
    # Read servers_v3.tsv
    servers = []
    excluded_hosts = {"install-01", "install-v3"}
    
    with open(tsv_file, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            hostname = row.get("HOSTNAME", "").strip()
            
            # Skip excluded hosts
            if hostname in excluded_hosts:
                continue
            
            # Skip empty rows
            if not hostname:
                continue
            
            role_v3 = row.get("ROLE_V3", "").strip()
            ip_private = row.get("IP_PRIVEE", "").strip()
            
            if not role_v3 or not ip_private:
                print(f"Warning: Skipping {hostname} - missing role_v3 or IP_PRIVEE")
                continue
            
            # Generate volume name: kbv3-<hostname>-data
            volume_name = f"kbv3-{hostname}-data"
            
            # Get mountpoint: /data/<role_v3_normalized>
            mountpoint_role = normalize_role_for_mountpoint(role_v3)
            mountpoint = f"/data/{mountpoint_role}"
            
            # Get volume size
            size_gb = get_volume_size(role_v3)
            
            servers.append({
                "hostname": hostname,
                "role_v3": role_v3,
                "ip_private": ip_private,
                "volume_name": volume_name,
                "mountpoint": mountpoint,
                "size_gb": size_gb
            })
    
    # Build final JSON structure
    result = {
        "metadata": {
            "created": datetime.now().strftime("%Y-%m-%d"),
            "purpose": "Volume plan for KeyBuzz v3 infrastructure - PHASE 3",
            "total_servers": len(servers),
            "excluded_servers": list(excluded_hosts)
        },
        "servers": sorted(servers, key=lambda x: x["hostname"])
    }
    
    # Write JSON
    output_file = infra_dir / "servers" / "volume_plan_v3.json"
    output_file.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Generated {output_file}")
    print(f"   Total servers: {len(servers)}")
    print(f"   Total volume size: {sum(s['size_gb'] for s in servers)} GB")
    
    return 0


if __name__ == "__main__":
    exit(main())

