#!/usr/bin/env python3
"""Ajouter les entrées /etc/hosts pour RabbitMQ cluster"""

import subprocess

hosts_map = {
    '10.0.0.126': 'queue-01',
    '10.0.0.127': 'queue-02',
    '10.0.0.128': 'queue-03'
}

ssh_key = '/root/.ssh/id_rsa_keybuzz_v3'

for ip, hostname in hosts_map.items():
    print(f"=== Configuration {hostname} ({ip}) ===")
    ssh_cmd = f"ssh -i {ssh_key} -o StrictHostKeyChecking=no root@{ip}"
    
    # Ajouter les entrées dans /etc/hosts si elles n'existent pas
    for target_ip, target_hostname in hosts_map.items():
        cmd = f"{ssh_cmd} 'grep -q \"{target_ip}.*{target_hostname}\" /etc/hosts || echo \"{target_ip} {target_hostname}\" >> /etc/hosts'"
        subprocess.run(cmd, shell=True)
    
    # Vérifier
    cmd = f"{ssh_cmd} 'cat /etc/hosts | grep queue'"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    print(result.stdout)
    print()

print("=== Test résolution DNS ===")
for ip, hostname in hosts_map.items():
    ssh_cmd = f"ssh -i {ssh_key} -o StrictHostKeyChecking=no root@{ip}"
    cmd = f"{ssh_cmd} 'ping -c 1 queue-01 >/dev/null 2>&1 && echo \"{hostname}: queue-01 résolu\" || echo \"{hostname}: queue-01 non résolu\"'"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    print(result.stdout.strip())

