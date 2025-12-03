#!/bin/bash
# Script de vérification du cluster PostgreSQL HA (Patroni)

set -e

POSTGRES_NODES=("10.0.0.120" "10.0.0.121" "10.0.0.122")
PATRONI_REST_API_PORT=8008

echo "=== PH7 - Vérification Cluster PostgreSQL HA ==="
echo ""

# Fonction pour vérifier le statut d'un nœud
check_node() {
    local ip=$1
    echo "--- Node $ip ---"
    
    # Statut systemd Patroni
    echo "Systemd status:"
    ssh -i /root/.ssh/id_rsa_keybuzz_v3 root@$ip "systemctl status patroni --no-pager | head -10" || echo "  ⚠️  Impossible de vérifier systemd"
    echo ""
    
    # Statut Patroni REST API
    echo "Patroni REST API health:"
    curl -s "http://$ip:$PATRONI_REST_API_PORT/health" | jq '.' || echo "  ⚠️  API non accessible"
    echo ""
    
    # Cluster status via REST API
    echo "Cluster status:"
    curl -s "http://$ip:$PATRONI_REST_API_PORT/cluster" | jq '.' || echo "  ⚠️  Cluster status non accessible"
    echo ""
}

# Vérifier chaque nœud
for ip in "${POSTGRES_NODES[@]}"; do
    check_node "$ip"
done

# Vérifier avec patronictl si disponible
echo "=== Vérification via patronictl ==="
if command -v patronictl &> /dev/null; then
    ssh -i /root/.ssh/id_rsa_keybuzz_v3 root@${POSTGRES_NODES[0]} "patronictl -c /etc/patroni.yml list" || echo "  ⚠️  patronictl non disponible"
else
    echo "  ⚠️  patronictl non installé"
fi

echo ""
echo "=== ✅ Vérification terminée ==="

