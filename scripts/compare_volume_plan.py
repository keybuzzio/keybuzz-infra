#!/usr/bin/env python3
"""
Compare Volume Plan - PH3-01
Compares volume_plan_v3.json (target) vs existing_volumes_hetzner.json (current).
Generates volume_diff_v3.json with volumes to delete and create.
"""

import json
import sys
from datetime import datetime
from pathlib import Path


def load_json_file(filepath):
    """Load and parse a JSON file."""
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: {filepath} not found", file=sys.stderr)
        return None
    except json.JSONDecodeError as e:
        print(f"Error parsing {filepath}: {e}", file=sys.stderr)
        return None


def main():
    script_dir = Path(__file__).parent
    infra_dir = script_dir.parent
    
    # Load files
    volume_plan_file = infra_dir / "servers" / "volume_plan_v3.json"
    existing_volumes_file = infra_dir / "servers" / "existing_volumes_hetzner.json"
    
    print("📊 Comparing volume plans...")
    print(f"   Target: {volume_plan_file}")
    print(f"   Current: {existing_volumes_file}")
    
    volume_plan = load_json_file(volume_plan_file)
    existing_volumes = load_json_file(existing_volumes_file)
    
    if volume_plan is None or existing_volumes is None:
        return 1
    
    # Extract data
    target_servers = {s["hostname"]: s for s in volume_plan.get("servers", [])}
    existing_vols = existing_volumes.get("volumes", [])
    
    # Build mapping of target volume names
    target_volume_names = {s["volume_name"]: s for s in target_servers.values()}
    
    # Analyze existing volumes
    volumes_to_delete = []
    volumes_ok = []
    
    for vol in existing_vols:
        vol_name = vol.get("name", "")
        vol_id = vol.get("id")
        server = vol.get("server")
        server_name = server.get("name") if server else None
        
        # Check if this volume matches a target volume name
        if vol_name in target_volume_names:
            # Volume exists and matches target naming - mark as OK
            # (but in Option A, we still destroy and recreate everything)
            volumes_ok.append({
                "id": vol_id,
                "name": vol_name,
                "size_gb": vol.get("size_gb", 0),
                "server": server_name
            })
        else:
            # Volume doesn't match target naming - mark for deletion
            volumes_to_delete.append({
                "id": vol_id,
                "name": vol_name,
                "size_gb": vol.get("size_gb", 0),
                "server": server_name,
                "reason": "Does not match v3 naming convention (kbv3-<hostname>-data)"
            })
    
    # All target volumes need to be created (Option A: destroy & recreate)
    volumes_to_create = []
    for server_data in target_servers.values():
        volumes_to_create.append({
            "hostname": server_data["hostname"],
            "volume_name": server_data["volume_name"],
            "size_gb": server_data["size_gb"],
            "role_v3": server_data["role_v3"],
            "mountpoint": server_data["mountpoint"],
            "ip_private": server_data["ip_private"]
        })
    
    # Build diff result
    result = {
        "metadata": {
            "created": datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
            "purpose": "Volume diff: existing vs target - PH3-01",
            "strategy": "Option A - Destroy & Recreate All",
            "total_existing_volumes": len(existing_vols),
            "total_target_volumes": len(target_servers),
            "volumes_to_delete": len(volumes_to_delete),
            "volumes_to_create": len(volumes_to_create),
            "volumes_ok_count": len(volumes_ok)
        },
        "volumes_to_delete": sorted(volumes_to_delete, key=lambda x: x["name"]),
        "volumes_to_create": sorted(volumes_to_create, key=lambda x: x["hostname"]),
        "volumes_ok": sorted(volumes_ok, key=lambda x: x["name"])  # For reference only
    }
    
    # Write JSON
    output_file = infra_dir / "servers" / "volume_diff_v3.json"
    output_file.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Generated {output_file}")
    print()
    print("Summary:")
    print(f"   Existing volumes: {len(existing_vols)}")
    print(f"   Volumes to delete: {len(volumes_to_delete)}")
    print(f"   Volumes to create: {len(volumes_to_create)}")
    print(f"   Volumes OK (reference): {len(volumes_ok)}")
    print()
    print("⚠️  Strategy: Option A - All volumes will be destroyed and recreated")
    print("   (volumes_ok list is for reference only, all will be recreated in PH3-02)")
    
    return 0


if __name__ == "__main__":
    exit(main())

