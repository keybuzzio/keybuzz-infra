#!/usr/bin/env python3
"""
List Existing Hetzner Volumes - PH3-01
Lists all existing Hetzner volumes via hcloud CLI or API.
Generates existing_volumes_hetzner.json.
"""

import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path


def run_hcloud_command(cmd):
    """Run hcloud command and return JSON output."""
    try:
        result = subprocess.run(
            ["hcloud"] + cmd.split() + ["-o", "json"],
            capture_output=True,
            text=True,
            check=True
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error running hcloud command: {e.stderr}", file=sys.stderr)
        return None
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}", file=sys.stderr)
        return None


def get_all_volumes():
    """Get all volumes from Hetzner Cloud."""
    volumes_data = run_hcloud_command("volume list")
    
    if volumes_data is None:
        return []
    
    # hcloud volume list returns a list directly
    if isinstance(volumes_data, list):
        return volumes_data
    
    # Sometimes it might return a dict with volumes key
    if isinstance(volumes_data, dict) and "volumes" in volumes_data:
        return volumes_data["volumes"]
    
    return []


def get_server_name(server_id):
    """Get server name from server ID."""
    if not server_id:
        return None
    try:
        result = subprocess.run(
            ["hcloud", "server", "describe", str(server_id), "-o", "json"],
            capture_output=True,
            text=True,
            check=True
        )
        server_info = json.loads(result.stdout)
        return server_info.get("name")
    except (subprocess.CalledProcessError, json.JSONDecodeError, KeyError):
        return None


def main():
    script_dir = Path(__file__).parent
    infra_dir = script_dir.parent
    
    print("🔍 Fetching existing Hetzner volumes...")
    
    volumes_raw = get_all_volumes()
    
    if not volumes_raw:
        print("⚠️  No volumes found or error fetching volumes")
        # Create empty structure
        volumes_processed = []
    else:
        print(f"   Found {len(volumes_raw)} volumes")
        print("   Processing volume details...")
        
        volumes_processed = []
        for vol in volumes_raw:
            volume_id = vol.get("id")
            name = vol.get("name", "unknown")
            size_gb = vol.get("size", 0)
            
            # Get server info - server field is an ID (int) or null
            server_id = vol.get("server")
            server_info = None
            if server_id:
                server_name = get_server_name(server_id)
                server_info = {
                    "id": server_id,
                    "name": server_name
                }
            
            volume_entry = {
                "id": volume_id,
                "name": name,
                "size_gb": size_gb,
                "zone": vol.get("location", {}).get("name", "unknown"),
                "server": server_info
            }
            
            volumes_processed.append(volume_entry)
    
    # Build final JSON structure
    result = {
        "metadata": {
            "created": datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
            "purpose": "Existing Hetzner volumes snapshot - PH3-01",
            "total_volumes": len(volumes_processed)
        },
        "volumes": sorted(volumes_processed, key=lambda x: x["name"])
    }
    
    # Write JSON
    output_file = infra_dir / "servers" / "existing_volumes_hetzner.json"
    output_file.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Generated {output_file}")
    print(f"   Total volumes: {len(volumes_processed)}")
    
    # Show summary
    attached = sum(1 for v in volumes_processed if v["server"] is not None)
    detached = len(volumes_processed) - attached
    print(f"   Attached: {attached}")
    print(f"   Detached: {detached}")
    
    return 0


if __name__ == "__main__":
    exit(main())

