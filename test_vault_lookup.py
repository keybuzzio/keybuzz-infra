#!/usr/bin/env python3
"""Tester le lookup Vault avec AppRole"""

import subprocess
import sys

print("=== Test Lookup Vault avec AppRole ===")
print()

# Lire role_id et secret_id
try:
    with open('/root/ansible_role_id.txt', 'r') as f:
        role_id = f.read().strip()
    with open('/root/ansible_secret_id.txt', 'r') as f:
        secret_id = f.read().strip()
except Exception as e:
    print(f"❌ Erreur lecture fichiers: {e}")
    sys.exit(1)

print(f"role_id: {role_id[:10]}... ({len(role_id)} caractères)")
print(f"secret_id: {secret_id[:10]}... ({len(secret_id)} caractères)")
print()

# Tester avec ansible localhost
test_cmd = f"""ansible localhost -m debug -a "msg={{ lookup('community.hashi_vault.hashi_vault', 'secret=kv/keybuzz/redis:password', url='https://vault.keybuzz.io:8200', auth_method='approle', role_id='{role_id}', secret_id='{secret_id}', verify=False) }}" 2>&1"""

result = subprocess.run(test_cmd, shell=True, capture_output=True, text=True)

print("Résultat du test:")
print(result.stdout)
if result.stderr:
    print("STDERR:")
    print(result.stderr)

if result.returncode == 0 and 'msg' in result.stdout:
    print("\n✅ Lookup Vault fonctionne avec AppRole")
else:
    print("\n❌ Erreur lors du test")

