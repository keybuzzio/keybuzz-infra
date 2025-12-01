#!/usr/bin/env python3
"""
Attach volumes v3 - Quick script to attach all kbv3-* volumes to their servers
Used when playbook is stuck or needs manual completion
"""

import json
import subprocess
import sys
import os
import time
from pathlib import Path

def run_hcloud(cmd):
    """Run hcloud command and return stdout."""
    try:
        result = subprocess.run(
            ["hcloud"] + cmd.split(),
            capture_output=True,
            text=True,
            check=True,
            env=os.environ
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error: {e.stderr}", file=sys.stderr)
        return None

def main():
    script_dir = Path(__file__).parent
    infra_dir = script_dir.parent
    
    # Load volume plan
    volume_diff_file = infra_dir / "servers" / "volume_diff_v3.json"
    
    if not volume_diff_file.exists():
        print(f"Error: {volume_diff_file} not found")
        return 1
    
    with open(volume_diff_file, "r") as f:
        diff_data = json.load(f)
    
    volumes_to_attach = diff_data.get("volumes_to_create", [])
    
    if not volumes_to_attach:
        print("No volumes to attach")
        return 0
    
    print(f"Attaching {len(volumes_to_attach)} volumes...")
    print()
    
    success = 0
    failed = 0
    
    for vol in volumes_to_attach:
        volume_name = vol["volume_name"]
        hostname = vol["hostname"]
        
        print(f"Attaching {volume_name} to {hostname}...", end=" ")
        
        result = run_hcloud(f"volume attach --server {hostname} {volume_name}")
        
        # Wait a bit for attach to complete
        time.sleep(2)
        
        # Verify attachment
        verify_result = subprocess.run(
            ["hcloud", "volume", "describe", volume_name, "-o", "json"],
            capture_output=True,
            text=True,
            env=os.environ
        )
        
        if verify_result.returncode == 0:
            vol_info = json.loads(verify_result.stdout)
            server = vol_info.get("server")
            server_name = None
            if server:
                if isinstance(server, dict):
                    server_name = server.get("name")
                elif isinstance(server, int):
                    # Server is an ID, need to get name
                    server_info = subprocess.run(
                        ["hcloud", "server", "describe", str(server), "-o", "json"],
                        capture_output=True,
                        text=True,
                        env=os.environ
                    )
                    if server_info.returncode == 0:
                        server_data = json.loads(server_info.stdout)
                        server_name = server_data.get("name")
            
            if server_name == hostname:
                print("OK")
                success += 1
            else:
                print(f"FAILED (expected: {hostname}, got: {server_name})")
                failed += 1
        else:
            print("FAILED (describe error)")
            failed += 1
    
    print()
    print(f"Success: {success}/{len(volumes_to_attach)}")
    if failed > 0:
        print(f"Failed: {failed}/{len(volumes_to_attach)}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())

