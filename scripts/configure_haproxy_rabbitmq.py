#!/usr/bin/env python3
"""Configurer HAProxy pour RabbitMQ"""

import subprocess

haproxy_hosts = ['10.0.0.11', '10.0.0.12']
ssh_key = '/root/.ssh/id_rsa_keybuzz_v3'

config_block = """listen rabbitmq
    mode tcp
    bind *:5672
    balance roundrobin
    option tcp-check
    timeout client  1m
    timeout server  1m
    timeout connect 5s
    tcp-check connect port 5672
    server queue-01 10.0.0.126:5672 check inter 2000 fall 2 rise 2
    server queue-02 10.0.0.127:5672 check inter 2000 fall 2 rise 2 backup
    server queue-03 10.0.0.128:5672 check inter 2000 fall 2 rise 2 backup
"""

def run_ssh(ip, cmd):
    ssh_cmd = f"ssh -i {ssh_key} -o StrictHostKeyChecking=no root@{ip}"
    result = subprocess.run(f"{ssh_cmd} '{cmd}'", shell=True, capture_output=True, text=True)
    return result.stdout.strip(), result.returncode

for host_ip in haproxy_hosts:
    print(f"=== Configuration HAProxy {host_ip} ===")
    
    # Vérifier si la config existe déjà
    stdout, rc = run_ssh(host_ip, "grep -q 'listen rabbitmq' /etc/haproxy/haproxy.cfg && echo 'EXISTS' || echo 'NOT_EXISTS'")
    
    if 'EXISTS' in stdout:
        print(f"  ⚠️  Configuration RabbitMQ existe déjà, suppression...")
        # Supprimer l'ancienne config
        run_ssh(host_ip, "sed -i '/listen rabbitmq/,/^$/d' /etc/haproxy/haproxy.cfg")
    
    # Ajouter la nouvelle config
    print(f"  Ajout de la configuration RabbitMQ...")
    cmd = f"cat >> /etc/haproxy/haproxy.cfg << 'EOF'\n{config_block}\nEOF"
    stdout, rc = run_ssh(host_ip, cmd)
    
    # Valider la config
    print(f"  Validation de la configuration...")
    stdout, rc = run_ssh(host_ip, "haproxy -c -f /etc/haproxy/haproxy.cfg")
    if rc == 0:
        print(f"  ✅ Configuration valide")
    else:
        print(f"  ❌ Erreur validation: {stdout}")
        continue
    
    # Redémarrer HAProxy
    print(f"  Redémarrage de HAProxy...")
    stdout, rc = run_ssh(host_ip, "systemctl restart haproxy && systemctl status haproxy --no-pager | head -5")
    if rc == 0:
        print(f"  ✅ HAProxy redémarré")
    else:
        print(f"  ⚠️  Erreur redémarrage: {stdout}")
    
    # Vérifier le port
    stdout, rc = run_ssh(host_ip, "netstat -tlnp | grep 5672 || ss -tlnp | grep 5672")
    if '5672' in stdout:
        print(f"  ✅ Port 5672 en écoute")
    else:
        print(f"  ⚠️  Port 5672 non trouvé")
    
    print()

print("=== ✅ Configuration HAProxy terminée ===")

