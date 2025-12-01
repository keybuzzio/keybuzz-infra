#!/usr/bin/env python3
"""Verify volumes are attached"""
import json
import subprocess
import sys
import os

vols_json = subprocess.run(
    ["hcloud", "volume", "list", "-o", "json"],
    capture_output=True,
    text=True,
    env=os.environ
).stdout

vols = json.loads(vols_json)
kbv3_vols = [v for v in vols if v.get("name", "").startswith("kbv3-")]
attached = [v for v in kbv3_vols if v.get("server")]

print(f"Total kbv3- volumes: {len(kbv3_vols)}")
print(f"Attached: {len(attached)}")
print(f"Not attached: {len(kbv3_vols) - len(attached)}")

if len(attached) < len(kbv3_vols):
    print("\nNot attached volumes:")
    for v in kbv3_vols:
        if not v.get("server"):
            print(f"  - {v['name']}")

sys.exit(0 if len(attached) == len(kbv3_vols) else 1)

