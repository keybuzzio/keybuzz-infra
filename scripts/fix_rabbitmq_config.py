#!/usr/bin/env python3
"""Script pour corriger la configuration RabbitMQ sur tous les nœuds"""

import subprocess
import sys

hosts = {
    'queue-01': '10.0.0.126',
    'queue-02': '10.0.0.127',
    'queue-03': '10.0.0.128'
}

ssh_key = '/root/.ssh/id_rsa_keybuzz_v3'

for hostname, ip in hosts.items():
    print(f"=== Correction {hostname} ({ip}) ===")
    
    ssh_cmd = f"ssh -i {ssh_key} -o StrictHostKeyChecking=no root@{ip}"
    
    # Supprimer les lignes invalides de rabbitmq.conf
    cmd1 = f"{ssh_cmd} 'sed -i \"/^data_dir/d\" /etc/rabbitmq/rabbitmq.conf && sed -i \"/^quorum_queues.default_quorum_initial_group_size/d\" /etc/rabbitmq/rabbitmq.conf'"
    result1 = subprocess.run(cmd1, shell=True, capture_output=True)
    
    # Ajouter RABBITMQ_MNESIA_DIR dans rabbitmq-env.conf
    cmd2 = f"{ssh_cmd} 'grep -q \"RABBITMQ_MNESIA_DIR\" /etc/rabbitmq/rabbitmq-env.conf || echo \"RABBITMQ_MNESIA_DIR=/data/rabbitmq\" >> /etc/rabbitmq/rabbitmq-env.conf'"
    result2 = subprocess.run(cmd2, shell=True, capture_output=True)
    
    # Vérifier la configuration
    cmd3 = f"{ssh_cmd} 'cat /etc/rabbitmq/rabbitmq.conf | tail -3'"
    result3 = subprocess.run(cmd3, shell=True, capture_output=True, text=True)
    print(f"  Dernières lignes rabbitmq.conf:")
    print(f"  {result3.stdout.strip()}")
    
    # Démarrer RabbitMQ
    cmd4 = f"{ssh_cmd} 'systemctl start rabbitmq-server && sleep 5 && systemctl status rabbitmq-server --no-pager | head -10'"
    result4 = subprocess.run(cmd4, shell=True, capture_output=True, text=True)
    
    if 'active (running)' in result4.stdout:
        print(f"  ✅ {hostname} démarré avec succès")
    else:
        print(f"  ❌ {hostname} échec démarrage")
        print(f"  {result4.stdout}")
    
    print()

print("=== Vérification finale ===")
for hostname, ip in hosts.items():
    ssh_cmd = f"ssh -i {ssh_key} -o StrictHostKeyChecking=no root@{ip}"
    cmd = f"{ssh_cmd} 'systemctl is-active rabbitmq-server && rabbitmqctl status 2>&1 | head -5'"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    print(f"{hostname}: {result.stdout.strip()}")

