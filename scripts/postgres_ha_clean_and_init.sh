#!/bin/bash
# Script pour nettoyer et réinitialiser le cluster PostgreSQL HA

set -e

POSTGRES_NODES=("10.0.0.120" "10.0.0.121" "10.0.0.122")
SSH_KEY="/root/.ssh/id_rsa_keybuzz_v3"
DATA_DIR="/data/db_postgres/data"

echo "=== PH7 - Nettoyage et Réinitialisation Cluster PostgreSQL HA ==="
echo ""

# Fonction pour nettoyer un nœud
clean_node() {
    local ip=$1
    echo "--- Nettoyage de $ip ---"
    
    # Arrêter Patroni
    echo "  Arrêt de Patroni..."
    ssh -i "$SSH_KEY" root@$ip "systemctl stop patroni" || true
    
    # Sauvegarder les fichiers de config
    echo "  Sauvegarde des fichiers de configuration..."
    ssh -i "$SSH_KEY" root@$ip "mkdir -p /tmp/postgres_config_backup && cp -f $DATA_DIR/postgresql.conf $DATA_DIR/pg_hba.conf /tmp/postgres_config_backup/ 2>/dev/null || true"
    
    # Supprimer le contenu du répertoire de données (sauf les fichiers de config sauvegardés)
    echo "  Suppression du contenu du répertoire de données..."
    ssh -i "$SSH_KEY" root@$ip "rm -rf $DATA_DIR/* $DATA_DIR/.* 2>/dev/null || true"
    
    # Restaurer les fichiers de config
    echo "  Restauration des fichiers de configuration..."
    ssh -i "$SSH_KEY" root@$ip "cp -f /tmp/postgres_config_backup/* $DATA_DIR/ 2>/dev/null || true"
    
    # Redémarrer Patroni
    echo "  Redémarrage de Patroni..."
    ssh -i "$SSH_KEY" root@$ip "systemctl start patroni"
    
    echo "  ✅ Nettoyage terminé"
    echo ""
}

# Nettoyer tous les nœuds
for ip in "${POSTGRES_NODES[@]}"; do
    clean_node "$ip"
done

echo "Attente de 10 secondes pour que Patroni démarre..."
sleep 10

# Initialiser le cluster sur le premier nœud
echo "=== Initialisation du cluster ==="
FIRST_NODE="${POSTGRES_NODES[0]}"
echo "Initialisation sur $FIRST_NODE..."

# Utiliser l'API Patroni pour initialiser
INIT_RESULT=$(ssh -i "$SSH_KEY" root@$FIRST_NODE "curl -s -X POST http://127.0.0.1:8008/initialize -H 'Content-Type: application/json' -d '{\"initdb\": []}'" || echo "ERROR")

if echo "$INIT_RESULT" | grep -q "already initialized\|already exists"; then
    echo "  ⚠️  Cluster déjà initialisé"
elif echo "$INIT_RESULT" | grep -q "message\|success"; then
    echo "  ✅ Cluster initialisé"
else
    echo "  ⚠️  Réponse: $INIT_RESULT"
fi

echo ""
echo "Attente de 30 secondes pour la formation du cluster..."
sleep 30

# Vérifier le statut
echo "=== Vérification du statut du cluster ==="
CLUSTER_STATUS=$(ssh -i "$SSH_KEY" root@$FIRST_NODE "curl -s http://127.0.0.1:8008/cluster" || echo "{}")

if echo "$CLUSTER_STATUS" | jq -e '.members[] | select(.role=="leader" and .state=="running")' > /dev/null 2>&1; then
    LEADER=$(echo "$CLUSTER_STATUS" | jq -r '.members[] | select(.role=="leader") | "\(.name) (\(.host):\(.port))"')
    echo "  ✅ Cluster formé avec leader: $LEADER"
    echo ""
    echo "Membres du cluster:"
    echo "$CLUSTER_STATUS" | jq -r '.members[] | "  - \(.name): \(.role) (\(.state))"'
else
    echo "  ⚠️  Aucun leader trouvé ou cluster non formé"
    echo "  Statut: $CLUSTER_STATUS"
fi

echo ""
echo "=== ✅ Opération terminée ==="

