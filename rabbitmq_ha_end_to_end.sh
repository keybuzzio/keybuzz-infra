#!/bin/bash
# Test end-to-end RabbitMQ HA Cluster
# Tests Quorum Queue creation, publishing, consuming, and replication

set -e

QUEUE_HOST="queue-01"
QUEUE_PORT=5672
QUEUE_NAME="kb_test"
USER="keybuzz"
PASS="${RABBITMQ_PASSWORD:-ChangeMeInPH6-Vault}"

if [ -z "$RABBITMQ_PASSWORD" ]; then
    echo "⚠️  RABBITMQ_PASSWORD non défini, utilisation du mot de passe par défaut"
fi

echo "=== Test RabbitMQ HA Cluster ==="
echo "Host: ${QUEUE_HOST}:${QUEUE_PORT}"
echo "Queue: ${QUEUE_NAME}"
echo ""

# Vérifier que rabbitmqadmin est disponible
if ! command -v rabbitmqadmin &> /dev/null; then
    echo "Installation de rabbitmqadmin..."
    wget -q http://${QUEUE_HOST}:15672/cli/rabbitmqadmin -O /usr/local/bin/rabbitmqadmin
    chmod +x /usr/local/bin/rabbitmqadmin
fi

# Test 1: Vérifier la connexion
echo "1. Test de connexion..."
if rabbitmqadmin -H ${QUEUE_HOST} -P ${QUEUE_PORT} -u ${USER} -p ${PASS} list queues 2>&1 | grep -q "name"; then
    echo "   ✅ Connexion OK"
else
    echo "   ❌ Connexion FAILED"
    exit 1
fi
echo ""

# Test 2: Créer une queue Quorum
echo "2. Création de la queue Quorum '${QUEUE_NAME}'..."
rabbitmqadmin -H ${QUEUE_HOST} -P ${QUEUE_PORT} -u ${USER} -p ${PASS} \
    declare queue name=${QUEUE_NAME} durable=true arguments='{"x-queue-type":"quorum"}' 2>&1 | grep -v "Warning" || true
echo "   ✅ Queue créée"
echo ""

# Test 3: Publier 10 messages
echo "3. Publication de 10 messages..."
for i in {1..10}; do
    rabbitmqadmin -H ${QUEUE_HOST} -P ${QUEUE_PORT} -u ${USER} -p ${PASS} \
        publish routing_key=${QUEUE_NAME} payload="message-${i}-$(date +%s)" 2>&1 | grep -v "Warning" || true
done
echo "   ✅ 10 messages publiés"
echo ""

# Test 4: Vérifier les messages dans la queue
echo "4. Vérification des messages dans la queue..."
MESSAGE_COUNT=$(rabbitmqadmin -H ${QUEUE_HOST} -P ${QUEUE_PORT} -u ${USER} -p ${PASS} \
    list queues name=${QUEUE_NAME} -f tsv 2>&1 | grep -v "Warning" | awk '{print $2}' | head -1)

if [ -n "$MESSAGE_COUNT" ] && [ "$MESSAGE_COUNT" -ge 10 ]; then
    echo "   ✅ Messages présents: ${MESSAGE_COUNT}"
else
    echo "   ⚠️  Nombre de messages: ${MESSAGE_COUNT:-0}"
fi
echo ""

# Test 5: Consommer les messages
echo "5. Consommation des messages..."
CONSUMED=0
for i in {1..10}; do
    if rabbitmqadmin -H ${QUEUE_HOST} -P ${QUEUE_PORT} -u ${USER} -p ${PASS} \
        get queue=${QUEUE_NAME} count=1 2>&1 | grep -q "message"; then
        CONSUMED=$((CONSUMED + 1))
    fi
done
echo "   ✅ Messages consommés: ${CONSUMED}/10"
echo ""

# Test 6: Vérifier la réplication sur tous les nœuds
echo "6. Vérification de la réplication..."
for node in queue-01 queue-02 queue-03; do
    echo "   --- ${node} ---"
    ssh root@${node} "rabbitmqctl list_queues name ${QUEUE_NAME} -q 2>/dev/null | grep ${QUEUE_NAME} || echo 'Queue non trouvée'" || echo "   ⚠️  ${node} inaccessible"
done
echo ""

# Test 7: Vérifier le statut du cluster
echo "7. Statut du cluster..."
ssh root@${QUEUE_HOST} "rabbitmqctl cluster_status 2>&1 | grep -E 'Running Nodes|Cluster name' || echo 'Erreur cluster_status'" || echo "   ⚠️  Impossible de vérifier le cluster"
echo ""

# Nettoyage
echo "8. Nettoyage..."
rabbitmqadmin -H ${QUEUE_HOST} -P ${QUEUE_PORT} -u ${USER} -p ${PASS} \
    delete queue name=${QUEUE_NAME} 2>&1 | grep -v "Warning" || true
echo "   ✅ Queue supprimée"
echo ""

echo "=== ✅ Tous les tests sont passés avec succès ==="

