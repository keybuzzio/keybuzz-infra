#!/usr/bin/env python3
"""
PH7-05 - Test Vault PostgreSQL Dynamic Credentials
Tests the generation of dynamic PostgreSQL credentials from Vault
"""

import os
import sys
import subprocess
import json
import time

VAULT_ADDR = os.getenv("VAULT_ADDR", "https://vault.keybuzz.io:8200")
VAULT_SKIP_VERIFY = os.getenv("VAULT_SKIP_VERIFY", "true")
HAPROXY_IP = "10.0.0.11"
POSTGRES_PORT = 5432

# Roles to test
ROLES = [
    "keybuzz-api-db",
    "chatwoot-db",
    "n8n-db",
    "workers-db"
]

def run_vault_command(cmd):
    """Execute a vault command and return the output"""
    env = os.environ.copy()
    env["VAULT_ADDR"] = VAULT_ADDR
    env["VAULT_SKIP_VERIFY"] = VAULT_SKIP_VERIFY
    
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            env=env
        )
        return result.stdout, result.stderr, result.returncode
    except Exception as e:
        return "", str(e), 1

def get_vault_token():
    """Get Vault token from environment or file"""
    # Try environment variable
    token = os.getenv("VAULT_TOKEN")
    if token:
        return token
    
    # Try AppRole credentials
    role_id_file = "/root/ansible_role_id.txt"
    secret_id_file = "/root/ansible_secret_id.txt"
    
    if os.path.exists(role_id_file) and os.path.exists(secret_id_file):
        with open(role_id_file) as f:
            role_id = f.read().strip()
        with open(secret_id_file) as f:
            secret_id = f.read().strip()
        
        # Authenticate with AppRole
        cmd = f"vault write -format=json auth/approle/login role_id={role_id} secret_id={secret_id}"
        stdout, stderr, rc = run_vault_command(cmd)
        if rc == 0:
            data = json.loads(stdout)
            return data.get("auth", {}).get("client_token")
    
    return None

def test_role(role_name):
    """Test a specific Vault database role"""
    print(f"\n{'='*60}")
    print(f"Testing role: {role_name}")
    print(f"{'='*60}")
    
    # Get credentials from Vault
    token = get_vault_token()
    if not token:
        print("❌ ERROR: No Vault token available")
        print("   Set VAULT_TOKEN environment variable or configure AppRole")
        return False
    
    env = os.environ.copy()
    env["VAULT_ADDR"] = VAULT_ADDR
    env["VAULT_SKIP_VERIFY"] = VAULT_SKIP_VERIFY
    env["VAULT_TOKEN"] = token
    
    cmd = f"vault read -format=json database/creds/{role_name}"
    stdout, stderr, rc = run_vault_command(cmd)
    
    if rc != 0:
        print(f"❌ ERROR: Failed to get credentials from Vault")
        print(f"   stderr: {stderr}")
        return False
    
    try:
        data = json.loads(stdout)
        creds = data.get("data", {})
        username = creds.get("username")
        password = creds.get("password")
        lease_duration = creds.get("lease_duration")
        
        print(f"✅ Credentials obtained:")
        print(f"   Username: {username}")
        print(f"   Password: {password[:8]}...")
        print(f"   TTL: {lease_duration}s ({lease_duration//3600}h)")
        
        # Test PostgreSQL connection
        print(f"\n   Testing PostgreSQL connection...")
        test_cmd = f"PGPASSWORD='{password}' psql -h {HAPROXY_IP} -p {POSTGRES_PORT} -U {username} -d keybuzz -c 'SELECT now();'"
        result = subprocess.run(
            test_cmd,
            shell=True,
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            print(f"   ✅ PostgreSQL connection successful")
            print(f"   Output: {result.stdout.strip()[:50]}...")
            return True
        else:
            print(f"   ❌ PostgreSQL connection failed")
            print(f"   Error: {result.stderr}")
            return False
            
    except json.JSONDecodeError:
        print(f"❌ ERROR: Invalid JSON response from Vault")
        print(f"   stdout: {stdout}")
        return False
    except Exception as e:
        print(f"❌ ERROR: {e}")
        return False

def main():
    print("="*60)
    print("PH7-05 - Test Vault PostgreSQL Dynamic Credentials")
    print("="*60)
    print(f"Vault Address: {VAULT_ADDR}")
    print(f"PostgreSQL via HAProxy: {HAPROXY_IP}:{POSTGRES_PORT}")
    print()
    
    # Check Vault connectivity
    print("Checking Vault connectivity...")
    stdout, stderr, rc = run_vault_command("vault status")
    if rc != 0:
        print("❌ ERROR: Cannot connect to Vault")
        print(f"   Make sure Vault is running and accessible at {VAULT_ADDR}")
        print(f"   Error: {stderr}")
        sys.exit(1)
    
    print("✅ Vault is accessible")
    
    # Test each role
    results = {}
    for role in ROLES:
        results[role] = test_role(role)
        time.sleep(1)  # Small delay between tests
    
    # Summary
    print("\n" + "="*60)
    print("Summary")
    print("="*60)
    for role, success in results.items():
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"  {role}: {status}")
    
    # Exit code
    if all(results.values()):
        print("\n✅ All tests passed!")
        sys.exit(0)
    else:
        print("\n❌ Some tests failed")
        sys.exit(1)

if __name__ == "__main__":
    main()

