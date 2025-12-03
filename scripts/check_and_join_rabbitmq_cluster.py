#!/usr/bin/env python3
"""Vérifier l'état du cluster RabbitMQ et former le cluster si nécessaire"""

import subprocess
import sys

hosts = {
    'queue-01': '10.0.0.126',
    'queue-02': '10.0.0.127',
    'queue-03': '10.0.0.128'
}

ssh_key = '/root/.ssh/id_rsa_keybuzz_v3'

def run_ssh(ip, cmd):
    ssh_cmd = f"ssh -i {ssh_key} -o StrictHostKeyChecking=no root@{ip}"
    result = subprocess.run(f"{ssh_cmd} '{cmd}'", shell=True, capture_output=True, text=True)
    return result.stdout.strip(), result.returncode

print("=== Vérification état RabbitMQ ===")
print()

# Vérifier que tous les services sont actifs
all_active = True
for hostname, ip in hosts.items():
    stdout, rc = run_ssh(ip, 'systemctl is-active rabbitmq-server')
    if stdout == 'active':
        print(f"✅ {hostname} ({ip}): RabbitMQ actif")
    else:
        print(f"❌ {hostname} ({ip}): RabbitMQ inactif")
        all_active = False

if not all_active:
    print("\n⚠️  Certains services ne sont pas actifs. Corrigez avant de continuer.")
    sys.exit(1)

print()
print("=== État du cluster ===")

# Vérifier le cluster_status sur queue-01
stdout, rc = run_ssh(hosts['queue-01'], 'rabbitmqctl cluster_status')
print(f"\nqueue-01 cluster_status:")
print(stdout[:500])

# Vérifier si les autres nœuds sont dans le cluster
if 'rabbit@queue-02' in stdout and 'rabbit@queue-03' in stdout:
    print("\n✅ Cluster déjà formé avec les 3 nœuds")
else:
    print("\n⚠️  Cluster non formé, formation nécessaire...")
    print()
    
    # Joindre queue-02
    print("Joining queue-02 to cluster...")
    run_ssh(hosts['queue-02'], 'rabbitmqctl stop_app')
    run_ssh(hosts['queue-02'], 'rabbitmqctl reset')
    stdout, rc = run_ssh(hosts['queue-02'], 'rabbitmqctl join_cluster rabbit@queue-01')
    if rc == 0:
        print("✅ queue-02 joined")
    else:
        print(f"❌ queue-02 join failed: {stdout}")
    run_ssh(hosts['queue-02'], 'rabbitmqctl start_app')
    
    # Joindre queue-03
    print("Joining queue-03 to cluster...")
    run_ssh(hosts['queue-03'], 'rabbitmqctl stop_app')
    run_ssh(hosts['queue-03'], 'rabbitmqctl reset')
    stdout, rc = run_ssh(hosts['queue-03'], 'rabbitmqctl join_cluster rabbit@queue-01')
    if rc == 0:
        print("✅ queue-03 joined")
    else:
        print(f"❌ queue-03 join failed: {stdout}")
    run_ssh(hosts['queue-03'], 'rabbitmqctl start_app')
    
    import time
    print("\nAttente stabilisation (10s)...")
    time.sleep(10)
    
    # Vérifier le cluster final
    stdout, rc = run_ssh(hosts['queue-01'], 'rabbitmqctl cluster_status')
    print("\n=== Cluster status final ===")
    print(stdout[:800])

