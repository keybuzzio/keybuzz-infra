#!/usr/bin/env python3
"""
Verify XFS Mounts v3 - PH3-03
Verifies that all volumes are formatted, mounted, and configured in /etc/fstab
"""

import json
import subprocess
import sys
import os
from pathlib import Path

def run_ssh_command(hostname, ip_private, command):
    """Run SSH command on remote host."""
    ssh_key = "/root/.ssh/id_rsa_keybuzz_v3"
    ssh_cmd = [
        "ssh",
        "-i", ssh_key,
        "-o", "StrictHostKeyChecking=no",
        "-o", "ConnectTimeout=5",
        "-o", "BatchMode=yes",
        f"root@{ip_private}",
        command
    ]
    try:
        result = subprocess.run(
            ssh_cmd,
            capture_output=True,
            text=True,
            timeout=10
        )
        return result.returncode == 0, result.stdout.strip(), result.stderr.strip()
    except subprocess.TimeoutExpired:
        return False, "", "Timeout"
    except Exception as e:
        return False, "", str(e)

def get_volume_id_from_hcloud(volume_name):
    """Get volume ID from Hetzner API."""
    hcloud_token = os.environ.get("HCLOUD_TOKEN")
    if not hcloud_token:
        # Try to load from file
        env_file = Path("/opt/keybuzz/credentials/hcloud.env")
        if env_file.exists():
            with open(env_file) as f:
                for line in f:
                    if line.startswith("HCLOUD_TOKEN="):
                        hcloud_token = line.split("'")[1] if "'" in line else line.split('"')[1]
                        break
    
    if not hcloud_token:
        return None
    
    env = os.environ.copy()
    env["HCLOUD_TOKEN"] = hcloud_token
    
    try:
        result = subprocess.run(
            ["hcloud", "volume", "describe", volume_name, "-o", "json"],
            capture_output=True,
            text=True,
            env=env,
            timeout=10
        )
        if result.returncode == 0:
            vol_data = json.loads(result.stdout)
            return vol_data.get("id")
    except:
        pass
    
    return None

def main():
    script_dir = Path(__file__).parent
    infra_dir = script_dir.parent
    
    # Load volume plan
    volume_plan_file = infra_dir / "servers" / "volume_plan_v3.json"
    
    if not volume_plan_file.exists():
        print(f"Error: {volume_plan_file} not found")
        return 1
    
    with open(volume_plan_file, "r") as f:
        volume_plan = json.load(f)
    
    servers = volume_plan.get("servers", [])
    
    if not servers:
        print("No servers found in volume plan")
        return 1
    
    print("=" * 60)
    print("PH3-03 - XFS Mount Verification")
    print("=" * 60)
    print()
    
    results = []
    total = len(servers)
    mounted = 0
    fstab_ok = 0
    xfs_type = 0
    
    for server in servers:
        hostname = server["hostname"]
        ip_private = server["ip_private"]
        volume_name = server["volume_name"]
        mountpoint = server["mountpoint"]
        
        print(f"Checking {hostname}...")
        
        # Get volume ID
        volume_id = get_volume_id_from_hcloud(volume_name)
        if not volume_id:
            print(f"  ⚠️  Could not get volume ID for {volume_name}")
            results.append({
                "hostname": hostname,
                "mounted": False,
                "fstab": False,
                "fstype": "unknown",
                "error": "Could not get volume ID"
            })
            continue
        
        device_path = f"/dev/disk/by-id/scsi-0HC_Volume_{volume_id}"
        
        # Check mount
        success, stdout, stderr = run_ssh_command(
            hostname, ip_private,
            f"mountpoint -q '{mountpoint}' && echo 'OK' || echo 'FAIL'"
        )
        is_mounted = success and "OK" in stdout
        
        # Check df -h
        success, df_out, _ = run_ssh_command(
            hostname, ip_private,
            f"df -h | grep '{mountpoint}'"
        )
        has_df_entry = success and mountpoint in df_out
        
        # Check fstype
        success, blkid_out, _ = run_ssh_command(
            hostname, ip_private,
            f"blkid {device_path}"
        )
        is_xfs = success and "TYPE=\"xfs\"" in blkid_out
        
        # Check fstab
        success, fstab_out, _ = run_ssh_command(
            hostname, ip_private,
            f"grep '{mountpoint}' /etc/fstab"
        )
        has_fstab = success and mountpoint in fstab_out
        
        if is_mounted:
            mounted += 1
        if has_fstab:
            fstab_ok += 1
        if is_xfs:
            xfs_type += 1
        
        status = "✅" if (is_mounted and has_fstab and is_xfs) else "❌"
        
        results.append({
            "hostname": hostname,
            "mounted": is_mounted,
            "fstab": has_fstab,
            "fstype": "xfs" if is_xfs else "unknown",
            "mountpoint": mountpoint
        })
        
        print(f"  {status} Mount: {'✓' if is_mounted else '✗'}, fstab: {'✓' if has_fstab else '✗'}, XFS: {'✓' if is_xfs else '✗'}")
    
    print()
    print("=" * 60)
    print("Summary")
    print("=" * 60)
    print(f"Total servers: {total}")
    print(f"Mounted: {mounted}/{total}")
    print(f"fstab configured: {fstab_ok}/{total}")
    print(f"XFS formatted: {xfs_type}/{total}")
    print()
    
    # Check failures
    failures = [r for r in results if not (r["mounted"] and r["fstab"] and r["fstype"] == "xfs")]
    
    if failures:
        print("Failures:")
        for r in failures:
            print(f"  - {r['hostname']}: mounted={r['mounted']}, fstab={r['fstab']}, type={r['fstype']}")
        print()
        return 1
    
    print("✅ All volumes are properly mounted, formatted, and configured!")
    return 0

if __name__ == "__main__":
    exit(main())

