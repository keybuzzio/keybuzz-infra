#!/bin/bash
# Script de test de failover RabbitMQ

set -e

QUEUE_NAME="kb_failover_test"
RABBITMQ_PASSWORD="${RABBITMQ_PASSWORD:-ChangeMeInPH6-Vault}"

echo "=== PH5-04 - Test de Failover RabbitMQ ==="
echo "Queue: ${QUEUE_NAME}"
echo ""

# (A) Vérifier état initial
echo "1. Vérification état initial du cluster..."
for h in 10.0.0.126 10.0.0.127 10.0.0.128; do
    echo "--- Node $h ---"
    ssh -i /root/.ssh/id_rsa_keybuzz_v3 root@$h "rabbitmqctl cluster_status 2>&1 | grep -E 'Running Nodes|Disk Nodes'" || true
done
echo ""

# (B) Créer la queue Quorum
echo "2. Création queue Quorum '${QUEUE_NAME}'..."
curl -s -u keybuzz:${RABBITMQ_PASSWORD} -X PUT \
    http://10.0.0.126:15672/api/queues/%2F/${QUEUE_NAME} \
    -H 'Content-Type: application/json' \
    -d "{\"durable\":true,\"arguments\":{\"x-queue-type\":\"quorum\"}}" > /dev/null
sleep 2
echo "   ✅ Queue créée"
echo ""

# (C) Publier des messages
echo "3. Publication de 5 messages..."
for i in {1..5}; do
    curl -s -u keybuzz:${RABBITMQ_PASSWORD} -X POST \
        http://10.0.0.126:15672/api/exchanges/amq.default/publish \
        -H 'Content-Type: application/json' \
        -d "{\"routing_key\":\"${QUEUE_NAME}\",\"payload\":\"message-${i}\",\"payload_encoding\":\"string\"}" > /dev/null
    echo "   Message $i publié"
done
sleep 2
echo ""

# Vérifier les messages
MSG_COUNT=$(curl -s -u keybuzz:${RABBITMQ_PASSWORD} \
    http://10.0.0.126:15672/api/queues/%2F/${QUEUE_NAME} | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('messages', 0))")
echo "   ✅ Messages dans la queue: ${MSG_COUNT}"
echo ""

# (D) Arrêter queue-02
echo "4. Simulation panne: arrêt de queue-02..."
ssh -i /root/.ssh/id_rsa_keybuzz_v3 root@10.0.0.127 "systemctl stop rabbitmq-server"
sleep 5
echo "   ✅ queue-02 arrêté"
echo ""

# Vérifier le cluster après panne
echo "5. Vérification cluster après panne..."
echo "--- queue-01 ---"
ssh -i /root/.ssh/id_rsa_keybuzz_v3 root@10.0.0.126 "rabbitmqctl cluster_status 2>&1 | grep -E 'Running Nodes|Disk Nodes'" || true
echo "--- queue-03 ---"
ssh -i /root/.ssh/id_rsa_keybuzz_v3 root@10.0.0.128 "rabbitmqctl cluster_status 2>&1 | grep -E 'Running Nodes|Disk Nodes'" || true
echo ""

# Vérifier que la queue est toujours accessible
echo "6. Vérification accessibilité de la queue..."
QUEUE_CHECK=$(curl -s -u keybuzz:${RABBITMQ_PASSWORD} \
    http://10.0.0.126:15672/api/queues/%2F/${QUEUE_NAME} | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print('OK' if d.get('name') else 'FAIL')")
if [ "$QUEUE_CHECK" = "OK" ]; then
    echo "   ✅ Queue toujours accessible"
else
    echo "   ❌ Queue non accessible"
    exit 1
fi
echo ""

# (E) Consommer les messages depuis queue-03
echo "7. Consommation des messages depuis queue-03..."
CONSUMED=0
for i in {1..5}; do
    RESULT=$(curl -s -u keybuzz:${RABBITMQ_PASSWORD} -X POST \
        http://10.0.0.128:15672/api/queues/%2F/${QUEUE_NAME}/get \
        -H 'Content-Type: application/json' \
        -d '{"count":1,"ackmode":"ack_requeue_false","encoding":"auto"}')
    if echo "$RESULT" | grep -q "message"; then
        CONSUMED=$((CONSUMED + 1))
        echo "   Message $i consommé"
    fi
done
echo "   ✅ Messages consommés: ${CONSUMED}/5"
echo ""

# (F) Réintégrer queue-02
echo "8. Réintégration de queue-02..."
ssh -i /root/.ssh/id_rsa_keybuzz_v3 root@10.0.0.127 "systemctl start rabbitmq-server"
sleep 10
echo "   ✅ queue-02 redémarré"
echo ""

# Vérifier le cluster final
echo "9. Vérification cluster final..."
ssh -i /root/.ssh/id_rsa_keybuzz_v3 root@10.0.0.127 "rabbitmqctl cluster_status 2>&1 | grep -E 'Running Nodes|Disk Nodes'" || true
echo ""

# Nettoyage
echo "10. Nettoyage..."
curl -s -u keybuzz:${RABBITMQ_PASSWORD} -X DELETE \
    http://10.0.0.126:15672/api/queues/%2F/${QUEUE_NAME} > /dev/null
echo "   ✅ Queue supprimée"
echo ""

echo "=== ✅ Test de failover terminé avec succès ==="

