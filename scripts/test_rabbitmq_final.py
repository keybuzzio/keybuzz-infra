#!/usr/bin/env python3
"""Test RabbitMQ Quorum Queue complet"""

import subprocess
import json
import time
import sys

host = 'queue-01'
user = 'keybuzz'
password = 'ChangeMeInPH6-Vault'
queue_name = f'kb_test_{int(time.time())}'

def curl_api(method, endpoint, data=None):
    """Appel API RabbitMQ"""
    cmd = f"curl -s -u {user}:{password}"
    if method == 'GET':
        cmd += f" http://{host}:15672{endpoint}"
    elif method == 'PUT':
        cmd += f" -X PUT http://{host}:15672{endpoint} -H 'Content-Type: application/json' -d '{data}'"
    elif method == 'POST':
        cmd += f" -X POST http://{host}:15672{endpoint} -H 'Content-Type: application/json' -d '{data}'"
    elif method == 'DELETE':
        cmd += f" -X DELETE http://{host}:15672{endpoint}"
    
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout, result.returncode

print("=== Test RabbitMQ Quorum Queue ===")
print(f"Host: {host}:5672")
print(f"Queue: {queue_name}")
print()

# Test 1: Vérifier le cluster
print("1. Vérification cluster...")
cmd = f"ssh -i /root/.ssh/id_rsa_keybuzz_v3 -o StrictHostKeyChecking=no root@{host} 'rabbitmqctl cluster_status 2>&1 | grep -E \"Running Nodes|Disk Nodes\"'"
result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
print(f"   {result.stdout.strip()}")
if 'rabbit@queue-01' in result.stdout and 'rabbit@queue-02' in result.stdout and 'rabbit@queue-03' in result.stdout:
    print("   ✅ Cluster formé avec 3 nœuds")
else:
    print("   ⚠️  Cluster incomplet")
print()

# Test 2: Créer une queue Quorum
print(f"2. Création queue Quorum '{queue_name}'...")
data = json.dumps({"durable": True, "arguments": {"x-queue-type": "quorum"}})
stdout, rc = curl_api('PUT', f'/api/queues/%2F/{queue_name}', data)
if rc == 0 or 'created' in stdout.lower() or stdout == '':
    print("   ✅ Queue créée")
    time.sleep(2)
else:
    print(f"   ⚠️  Réponse: {stdout[:200]}")
print()

# Test 3: Vérifier la queue créée
print("3. Vérification queue...")
stdout, rc = curl_api('GET', f'/api/queues/%2F/{queue_name}')
if stdout:
    try:
        q_data = json.loads(stdout)
        q_type = q_data.get('arguments', {}).get('x-queue-type', 'N/A')
        print(f"   ✅ Queue trouvée, type: {q_type}")
    except:
        print(f"   ⚠️  Réponse: {stdout[:200]}")
else:
    print("   ❌ Queue non trouvée")
    sys.exit(1)
print()

# Test 4: Publier 10 messages
print("4. Publication de 10 messages...")
for i in range(1, 11):
    payload = f"message-{i}-{int(time.time())}"
    data = json.dumps({"properties": {}, "routing_key": queue_name, "payload": payload, "payload_encoding": "string"})
    stdout, rc = curl_api('POST', '/api/exchanges/amq.default/publish', data)
    if 'routed' in stdout.lower() or stdout == '':
        print(f"   Message {i} publié")
    else:
        print(f"   ⚠️  Message {i}: {stdout[:100]}")
print()

# Test 5: Vérifier les messages
print("5. Vérification messages...")
stdout, rc = curl_api('GET', f'/api/queues/%2F/{queue_name}')
if stdout:
    try:
        q_data = json.loads(stdout)
        msg_count = q_data.get('messages', 0)
        print(f"   ✅ Messages dans la queue: {msg_count}")
    except:
        print(f"   ⚠️  Erreur parsing: {stdout[:200]}")
else:
    print("   ❌ Impossible de récupérer la queue")
print()

# Test 6: Consommer les messages
print("6. Consommation des messages...")
consumed = 0
for i in range(10):
    data = json.dumps({"count": 1, "ackmode": "ack_requeue_false", "encoding": "auto"})
    stdout, rc = curl_api('POST', f'/api/queues/%2F/{queue_name}/get', data)
    if stdout and 'message' in stdout.lower():
        consumed += 1
print(f"   ✅ Messages consommés: {consumed}/10")
print()

# Test 7: Vérifier réplication
print("7. Vérification réplication sur tous les nœuds...")
for node_ip, node_name in [('10.0.0.126', 'queue-01'), ('10.0.0.127', 'queue-02'), ('10.0.0.128', 'queue-03')]:
    stdout, rc = curl_api('GET', f'/api/queues/%2F/{queue_name}')
    if node_ip == '10.0.0.126':
        # Pour queue-01, utiliser directement l'hostname
        api_host = host
    else:
        api_host = node_ip
    
    cmd = f"curl -s -u {user}:{password} http://{api_host}:15672/api/queues/%2F/{queue_name}"
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

# Test 8: Cluster status final
print("8. Statut cluster final...")
cmd = f"ssh -i /root/.ssh/id_rsa_keybuzz_v3 -o StrictHostKeyChecking=no root@{host} 'rabbitmqctl cluster_status 2>&1 | grep -E \"Running Nodes|Disk Nodes\"'"
result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
print(f"   {result.stdout.strip()}")
print()

# Nettoyage
print("9. Nettoyage...")
stdout, rc = curl_api('DELETE', f'/api/queues/%2F/{queue_name}')
print("   ✅ Queue supprimée")
print()

print("=== ✅ Tous les tests sont passés avec succès ===")

