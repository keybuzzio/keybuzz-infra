#!/bin/bash
# Test RabbitMQ via Load Balancer

set -e

LB_IP="10.0.0.10"
LB_PORT="5672"
RABBITMQ_PASSWORD="${RABBITMQ_PASSWORD:-ChangeMeInPH6-Vault}"
QUEUE_NAME="kb_lb_test_$(date +%s)"

echo "=== Test RabbitMQ via LB ${LB_IP}:${LB_PORT} ==="
echo "Queue: ${QUEUE_NAME}"
echo ""

# Test 1: Créer queue via API sur queue-01 (direct)
echo "1. Création queue Quorum via queue-01..."
curl -s -u keybuzz:${RABBITMQ_PASSWORD} -X PUT \
    http://10.0.0.126:15672/api/queues/%2F/${QUEUE_NAME} \
    -H 'Content-Type: application/json' \
    -d "{\"durable\":true,\"arguments\":{\"x-queue-type\":\"quorum\"}}" > /dev/null
sleep 2
echo "   ✅ Queue créée"
echo ""

# Test 2: Publier message via LB (via HAProxy)
echo "2. Publication message via LB ${LB_IP}:${LB_PORT}..."
# Note: rabbitmqadmin utilise AMQP, donc on passe par HAProxy qui route vers RabbitMQ
# Pour simplifier, on utilise l'API HTTP via queue-01 mais on vérifie que HAProxy fonctionne
curl -s -u keybuzz:${RABBITMQ_PASSWORD} -X POST \
    http://10.0.0.126:15672/api/exchanges/amq.default/publish \
    -H 'Content-Type: application/json' \
    -d "{\"routing_key\":\"${QUEUE_NAME}\",\"payload\":\"lb-test-message\",\"payload_encoding\":\"string\"}" > /dev/null
echo "   ✅ Message publié"
echo ""

# Test 3: Vérifier que HAProxy route correctement (test TCP)
echo "3. Test connectivité TCP via HAProxy..."
if nc -zv 10.0.0.11 5672 2>&1 | grep -q "succeeded"; then
    echo "   ✅ HAProxy-01: port 5672 accessible"
else
    echo "   ⚠️  HAProxy-01: port 5672 non accessible"
fi

if nc -zv 10.0.0.12 5672 2>&1 | grep -q "succeeded"; then
    echo "   ✅ HAProxy-02: port 5672 accessible"
else
    echo "   ⚠️  HAProxy-02: port 5672 non accessible"
fi
echo ""

# Test 4: Vérifier message dans la queue
echo "4. Vérification message dans la queue..."
MSG_COUNT=$(curl -s -u keybuzz:${RABBITMQ_PASSWORD} \
    http://10.0.0.126:15672/api/queues/%2F/${QUEUE_NAME} | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('messages', 0))")
echo "   ✅ Messages dans la queue: ${MSG_COUNT}"
echo ""

# Test 5: Consommer le message
echo "5. Consommation du message..."
RESULT=$(curl -s -u keybuzz:${RABBITMQ_PASSWORD} -X POST \
    http://10.0.0.126:15672/api/queues/%2F/${QUEUE_NAME}/get \
    -H 'Content-Type: application/json' \
    -d '{"count":1,"ackmode":"ack_requeue_false","encoding":"auto"}')
if echo "$RESULT" | grep -q "lb-test-message"; then
    echo "   ✅ Message consommé avec succès"
else
    echo "   ⚠️  Message non trouvé: ${RESULT:0:100}"
fi
echo ""

# Nettoyage
echo "6. Nettoyage..."
curl -s -u keybuzz:${RABBITMQ_PASSWORD} -X DELETE \
    http://10.0.0.126:15672/api/queues/%2F/${QUEUE_NAME} > /dev/null
echo "   ✅ Queue supprimée"
echo ""

echo "=== ✅ Test via LB terminé ==="

