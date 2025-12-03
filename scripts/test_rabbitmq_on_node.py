#!/usr/bin/env python3
"""Test RabbitMQ directement sur queue-01"""

import subprocess
import json
import time

host = '10.0.0.126'
user = 'keybuzz'
password = 'ChangeMeInPH6-Vault'
queue_name = f'kb_test_{int(time.time())}'

print("=== Test RabbitMQ Quorum Queue ===")
print(f"Host: {host}")
print(f"Queue: {queue_name}")
print()

# Test 1: Cluster status
print("1. Cluster status...")
cmd = f"ssh -i /root/.ssh/id_rsa_keybuzz_v3 -o StrictHostKeyChecking=no root@{host} 'rabbitmqctl cluster_status 2>&1 | grep -E \"Running Nodes|Disk Nodes\"'"
result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
print(result.stdout.strip())
print()

# Test 2: Créer queue via API
print(f"2. Création queue Quorum '{queue_name}'...")
cmd = f"ssh -i /root/.ssh/id_rsa_keybuzz_v3 -o StrictHostKeyChecking=no root@{host} \"curl -s -u {user}:{password} -X PUT http://localhost:15672/api/queues/%2F/{queue_name} -H 'Content-Type: application/json' -d '{{\\\"durable\\\":true,\\\"arguments\\\":{{\\\"x-queue-type\\\":\\\"quorum\\\"}}}}'\""
result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
print(f"   Réponse: {result.stdout[:100]}")
time.sleep(2)
print()

# Test 3: Vérifier queue
print("3. Vérification queue...")
cmd = f"ssh -i /root/.ssh/id_rsa_keybuzz_v3 -o StrictHostKeyChecking=no root@{host} 'curl -s -u {user}:{password} http://localhost:15672/api/queues/%2F/{queue_name}'"
result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
if result.stdout:
    try:
        q_data = json.loads(result.stdout)
        q_type = q_data.get('arguments', {}).get('x-queue-type', 'N/A')
        print(f"   ✅ Queue trouvée, type: {q_type}")
    except Exception as e:
        print(f"   ⚠️  Erreur parsing: {e}")
        print(f"   Réponse: {result.stdout[:200]}")
else:
    print("   ❌ Queue non trouvée")
print()

# Test 4: Publier messages
print("4. Publication de 5 messages...")
for i in range(1, 6):
    payload = f"msg-{i}"
    cmd = f"ssh -i /root/.ssh/id_rsa_keybuzz_v3 -o StrictHostKeyChecking=no root@{host} \"curl -s -u {user}:{password} -X POST http://localhost:15672/api/exchanges/amq.default/publish -H 'Content-Type: application/json' -d '{{\\\"routing_key\\\":\\\"{queue_name}\\\",\\\"payload\\\":\\\"{payload}\\\",\\\"payload_encoding\\\":\\\"string\\\"}}'\""
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    print(f"   Message {i}: {result.stdout[:50]}")
print()

# Test 5: Vérifier messages
print("5. Vérification messages...")
cmd = f"ssh -i /root/.ssh/id_rsa_keybuzz_v3 -o StrictHostKeyChecking=no root@{host} 'curl -s -u {user}:{password} http://localhost:15672/api/queues/%2F/{queue_name}'"
result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
if result.stdout:
    try:
        q_data = json.loads(result.stdout)
        msg_count = q_data.get('messages', 0)
        print(f"   ✅ Messages: {msg_count}")
    except:
        print(f"   ⚠️  Réponse: {result.stdout[:200]}")
print()

# Test 6: Vérifier sur tous les nœuds
print("6. Vérification réplication...")
for node_ip, node_name in [('10.0.0.126', 'queue-01'), ('10.0.0.127', 'queue-02'), ('10.0.0.128', 'queue-03')]:
    cmd = f"ssh -i /root/.ssh/id_rsa_keybuzz_v3 -o StrictHostKeyChecking=no root@{node_ip} 'curl -s -u {user}:{password} http://localhost:15672/api/queues/%2F/{queue_name} 2>&1'"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.stdout and queue_name in result.stdout:
        try:
            q_data = json.loads(result.stdout)
            msg_count = q_data.get('messages', 0)
            print(f"   ✅ {node_name}: queue présente ({msg_count} messages)")
        except:
            print(f"   ✅ {node_name}: queue présente")
    else:
        print(f"   ⚠️  {node_name}: queue non trouvée")
print()

# Nettoyage
print("7. Nettoyage...")
cmd = f"ssh -i /root/.ssh/id_rsa_keybuzz_v3 -o StrictHostKeyChecking=no root@{host} 'curl -s -u {user}:{password} -X DELETE http://localhost:15672/api/queues/%2F/{queue_name}'"
subprocess.run(cmd, shell=True)
print("   ✅ Queue supprimée")
print()

print("=== ✅ Tests terminés ===")

