#!/bin/bash
# Script pour initialiser automatiquement le cluster PostgreSQL HA
# Patroni initialise automatiquement si le répertoire de données est complètement vide

set -e

POSTGRES_NODES=("10.0.0.120" "10.0.0.121" "10.0.0.122")
SSH_KEY="/root/.ssh/id_rsa_keybuzz_v3"
DATA_DIR="/data/db_postgres/data"

echo "=== PH7-02 - Initialisation Automatique Cluster PostgreSQL HA ==="
echo ""

# Fonction pour nettoyer complètement un nœud
clean_node_completely() {
    local ip=$1
    echo "--- Nettoyage complet de $ip ---"
    
    # Arrêter Patroni
    echo "  Arrêt de Patroni..."
    ssh -i "$SSH_KEY" root@$ip "systemctl stop patroni" || true
    sleep 2
    
    # Supprimer COMPLÈTEMENT le répertoire de données (y compris fichiers cachés)
    echo "  Suppression complète du répertoire de données..."
    ssh -i "$SSH_KEY" root@$ip "rm -rf $DATA_DIR/* $DATA_DIR/.[!.]* $DATA_DIR/..?* 2>/dev/null || true"
    ssh -i "$SSH_KEY" root@$ip "find $DATA_DIR -mindepth 1 -delete 2>/dev/null || true"
    
    # Vérifier que le répertoire est vide
    FILE_COUNT=$(ssh -i "$SSH_KEY" root@$ip "find $DATA_DIR -type f 2>/dev/null | wc -l" || echo "0")
    if [ "$FILE_COUNT" -gt 0 ]; then
        echo "  ⚠️  Le répertoire contient encore $FILE_COUNT fichier(s)"
        ssh -i "$SSH_KEY" root@$ip "ls -la $DATA_DIR/"
    else
        echo "  ✅ Répertoire complètement vide"
    fi
    
    # Redémarrer Patroni
    echo "  Redémarrage de Patroni..."
    ssh -i "$SSH_KEY" root@$ip "systemctl start patroni"
    
    echo "  ✅ Nettoyage terminé"
    echo ""
}

# Nettoyer tous les nœuds
for ip in "${POSTGRES_NODES[@]}"; do
    clean_node_completely "$ip"
done

echo "Attente de 30 secondes pour que Patroni initialise automatiquement..."
sleep 30

# Vérifier le statut du cluster
echo "=== Vérification du statut du cluster ==="
FIRST_NODE="${POSTGRES_NODES[0]}"
CLUSTER_STATUS=$(ssh -i "$SSH_KEY" root@$FIRST_NODE "curl -s http://127.0.0.1:8008/cluster" || echo "{}")

# Vérifier si un leader existe
LEADER=$(echo "$CLUSTER_STATUS" | jq -r '.members[] | select(.role=="leader" and .state=="running") | .name' 2>/dev/null || echo "")

if [ -n "$LEADER" ]; then
    echo "  ✅ Leader détecté : $LEADER"
    echo ""
    echo "Membres du cluster :"
    echo "$CLUSTER_STATUS" | jq -r '.members[] | "  - \(.name): \(.role) (\(.state))"'
    echo ""
    echo "État final du cluster :"
    echo "$CLUSTER_STATUS" | jq .
else
    echo "  ⚠️  Aucun leader trouvé"
    echo "  Statut actuel :"
    echo "$CLUSTER_STATUS" | jq .
    echo ""
    echo "Attente supplémentaire de 30 secondes..."
    sleep 30
    
    # Nouvelle vérification
    CLUSTER_STATUS=$(ssh -i "$SSH_KEY" root@$FIRST_NODE "curl -s http://127.0.0.1:8008/cluster" || echo "{}")
    LEADER=$(echo "$CLUSTER_STATUS" | jq -r '.members[] | select(.role=="leader" and .state=="running") | .name' 2>/dev/null || echo "")
    
    if [ -n "$LEADER" ]; then
        echo "  ✅ Leader détecté après attente supplémentaire : $LEADER"
        echo "$CLUSTER_STATUS" | jq .
    else
        echo "  ❌ Le cluster n'a pas été initialisé automatiquement"
        echo "  Vérifiez les logs Patroni :"
        echo "    journalctl -u patroni -f"
    fi
fi

echo ""
echo "=== ✅ Opération terminée ==="

