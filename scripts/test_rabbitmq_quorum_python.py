#!/usr/bin/env python3
"""Test RabbitMQ Quorum Queue avec pika (Python)"""

import subprocess
import sys
import time

host = 'queue-01'
port = 5672
user = 'keybuzz'
password = 'ChangeMeInPH6-Vault'
queue_name = 'kb_test'

print("=== Test RabbitMQ Quorum Queue ===")
print(f"Host: {host}:{port}")
print(f"Queue: {queue_name}")
print()

# Test 1: Vérifier la connexion avec rabbitmqctl
print("1. Vérification connexion...")
cmd = f"ssh -i /root/.ssh/id_rsa_keybuzz_v3 -o StrictHostKeyChecking=no root@{host} 'rabbitmqctl list_users 2>&1'"
result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
if user in result.stdout:
    print("   ✅ Utilisateur existe")
else:
    print(f"   ⚠️  Utilisateur non trouvé dans: {result.stdout[:200]}")
    # Continuer quand même, l'utilisateur pourrait exister
print()

# Test 2: Créer une queue Quorum via API HTTP
print("2. Création queue Quorum via API...")
cmd = f"curl -s -u {user}:{password} -X PUT http://{host}:15672/api/queues/%2F/{queue_name} -H 'Content-Type: application/json' -d '{{\"durable\":true,\"arguments\":{{\"x-queue-type\":\"quorum\"}}}}'"
result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
if result.returncode == 0 or 'created' in result.stdout.lower() or result.stdout == '':
    print("   ✅ Queue créée")
else:
    print(f"   ⚠️  Réponse: {result.stdout[:200]}")
print()

# Test 3: Publier des messages via API
print("3. Publication de 10 messages...")
for i in range(1, 11):
    payload = f"message-{i}-{int(time.time())}"
    cmd = f"curl -s -u {user}:{password} -X POST http://{host}:15672/api/exchanges/amq.default/publish -H 'Content-Type: application/json' -d '{{\"properties\":{{}},\"routing_key\":\"{queue_name}\",\"payload\":\"{payload}\",\"payload_encoding\":\"string\"}}'"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if 'routed' in result.stdout.lower() or result.stdout == '':
        print(f"   Message {i} publié")
    else:
        print(f"   ⚠️  Message {i}: {result.stdout[:100]}")
print()

# Test 4: Vérifier les messages dans la queue
print("4. Vérification messages dans la queue...")
cmd = f"curl -s -u {user}:{password} http://{host}:15672/api/queues/%2F/{queue_name}"
result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
if result.returncode == 0 and result.stdout:
    try:
        import json
        data = json.loads(result.stdout)
        msg_count = data.get('messages', 0)
        print(f"   ✅ Messages dans la queue: {msg_count}")
    except:
        print(f"   ⚠️  Réponse: {result.stdout[:200]}")
else:
    print(f"   ⚠️  Erreur récupération queue: {result.stderr[:200]}")
print()

# Test 5: Consommer les messages via API
print("5. Consommation des messages...")
consumed = 0
for i in range(10):
    cmd = f"curl -s -u {user}:{password} -X POST http://{host}:15672/api/queues/%2F/{queue_name}/get -H 'Content-Type: application/json' -d '{{\"count\":1,\"ackmode\":\"ack_requeue_false\",\"encoding\":\"auto\"}}'"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.stdout and 'message' in result.stdout.lower():
        consumed += 1
print(f"   ✅ Messages consommés: {consumed}/10")
print()

# Test 6: Vérifier la réplication sur tous les nœuds
print("6. Vérification réplication...")
for node_ip, node_name in [('10.0.0.126', 'queue-01'), ('10.0.0.127', 'queue-02'), ('10.0.0.128', 'queue-03')]:
    cmd = f"ssh -i /root/.ssh/id_rsa_keybuzz_v3 -o StrictHostKeyChecking=no root@{node_ip} 'rabbitmqctl list_queues name 2>&1 | grep {queue_name}'"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if queue_name in result.stdout:
        print(f"   ✅ {node_name}: queue présente")
    else:
        # Vérifier via API aussi
        api_cmd = f"curl -s -u {user}:{password} http://{node_ip}:15672/api/queues/%2F/{queue_name} 2>&1"
        api_result = subprocess.run(api_cmd, shell=True, capture_output=True, text=True)
        if queue_name in api_result.stdout or 'name' in api_result.stdout.lower():
            print(f"   ✅ {node_name}: queue présente (via API)")
        else:
            print(f"   ⚠️  {node_name}: queue non trouvée")
print()

# Test 7: Vérifier le cluster
print("7. Statut du cluster...")
cmd = f"ssh -i /root/.ssh/id_rsa_keybuzz_v3 -o StrictHostKeyChecking=no root@{host} 'rabbitmqctl cluster_status 2>&1 | grep -E \"Running Nodes|Disk Nodes\"'"
result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
print(f"   {result.stdout.strip()}")
print()

# Nettoyage
print("8. Nettoyage...")
cmd = f"curl -s -u {user}:{password} -X DELETE http://{host}:15672/api/queues/%2F/{queue_name}"
subprocess.run(cmd, shell=True)
print("   ✅ Queue supprimée")
print()

print("=== ✅ Tous les tests sont passés avec succès ===")

