#!/usr/bin/env python3
"""Synchroniser les cookies Erlang entre tous les nœuds RabbitMQ"""

import subprocess

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

# Récupérer le cookie de queue-01 (master)
print("Récupération du cookie depuis queue-01...")
cookie, rc = run_ssh(hosts['queue-01'], 'cat /var/lib/rabbitmq/.erlang.cookie')
if rc != 0:
    print(f"❌ Impossible de lire le cookie: {cookie}")
    exit(1)

print(f"Cookie: {cookie[:20]}...")
print()

# Copier le cookie sur queue-02 et queue-03
for hostname, ip in [('queue-02', hosts['queue-02']), ('queue-03', hosts['queue-03'])]:
    print(f"=== Synchronisation {hostname} ({ip}) ===")
    
    # Arrêter RabbitMQ
    run_ssh(ip, 'systemctl stop rabbitmq-server')
    
    # Écrire le cookie
    cmd = f"echo '{cookie}' > /var/lib/rabbitmq/.erlang.cookie && chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie && chmod 400 /var/lib/rabbitmq/.erlang.cookie"
    stdout, rc = run_ssh(ip, cmd)
    
    if rc == 0:
        print(f"✅ Cookie copié sur {hostname}")
    else:
        print(f"❌ Erreur copie cookie: {stdout}")
    
    # Vérifier
    cookie_check, _ = run_ssh(ip, 'cat /var/lib/rabbitmq/.erlang.cookie')
    if cookie_check == cookie:
        print(f"✅ Cookie vérifié sur {hostname}")
    else:
        print(f"❌ Cookie différent sur {hostname}")
    
    # Redémarrer RabbitMQ
    run_ssh(ip, 'systemctl start rabbitmq-server')
    print()

print("Attente stabilisation (5s)...")
import time
time.sleep(5)

# Vérifier que tous les services sont actifs
print("\n=== Vérification finale ===")
all_ok = True
for hostname, ip in hosts.items():
    stdout, rc = run_ssh(ip, 'systemctl is-active rabbitmq-server')
    if stdout == 'active':
        print(f"✅ {hostname}: actif")
    else:
        print(f"❌ {hostname}: inactif")
        all_ok = False

if all_ok:
    print("\n✅ Tous les services sont actifs, prêt pour cluster join")
else:
    print("\n⚠️  Certains services ne sont pas actifs")

