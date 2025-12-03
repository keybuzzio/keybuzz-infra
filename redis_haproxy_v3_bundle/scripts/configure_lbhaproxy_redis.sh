#!/bin/bash
#
# configure_lbhaproxy_redis.sh
# Configure le load balancer Hetzner lb-haproxy pour exposer Redis (port 6379)
#
# Usage:
#   ./configure_lbhaproxy_redis.sh [LB_ID]
#
# Si LB_ID n'est pas fourni, le script tentera de le détecter automatiquement
# ou demandera à l'utilisateur de le fournir.
#

set -euo pipefail

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonctions de logging
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier que hcloud est installé
if ! command -v hcloud &> /dev/null; then
    log_error "hcloud CLI n'est pas installé"
    log_info "Installation: https://github.com/hetznercloud/cli"
    exit 1
fi

# Vérifier que hcloud est authentifié
if ! hcloud context list &> /dev/null; then
    log_error "hcloud n'est pas authentifié"
    log_info "Authentification: hcloud context create <name> --token <token>"
    exit 1
fi

# Récupérer le LB_ID
LB_ID="${1:-}"

if [ -z "$LB_ID" ]; then
    log_info "Recherche du load balancer lb-haproxy..."
    
    # Lister tous les load balancers
    LB_LIST=$(hcloud load-balancer list -o columns=id,name,ipv4 | grep -E "lb-haproxy|haproxy" || true)
    
    if [ -z "$LB_LIST" ]; then
        log_error "Aucun load balancer 'lb-haproxy' trouvé"
        log_info "Liste des load balancers disponibles:"
        hcloud load-balancer list
        log_info ""
        read -p "Entrez l'ID du load balancer: " LB_ID
    else
        log_info "Load balancers trouvés:"
        echo "$LB_LIST"
        log_info ""
        read -p "Entrez l'ID du load balancer lb-haproxy: " LB_ID
    fi
fi

if [ -z "$LB_ID" ]; then
    log_error "LB_ID requis"
    exit 1
fi

# Vérifier que le LB existe
if ! hcloud load-balancer describe "$LB_ID" &> /dev/null; then
    log_error "Load balancer $LB_ID introuvable"
    exit 1
fi

log_info "Configuration du load balancer: $LB_ID"

# Informations du LB
LB_NAME=$(hcloud load-balancer describe "$LB_ID" -o json | jq -r '.name')
LB_IP=$(hcloud load-balancer describe "$LB_ID" -o json | jq -r '.public_net.ipv4.ip')

log_info "Nom: $LB_NAME"
log_info "IP publique: $LB_IP"

# IPs des serveurs HAProxy
HAPROXY_01_IP="10.0.0.11"
HAPROXY_02_IP="10.0.0.12"

log_info ""
log_info "=========================================="
log_info "Configuration du service TCP 6379 (Redis)"
log_info "=========================================="

# Vérifier si le service existe déjà
if hcloud load-balancer describe "$LB_ID" -o json | jq -e '.services[] | select(.listen_port == 6379)' &> /dev/null; then
    log_warn "Le service TCP 6379 existe déjà"
    read -p "Voulez-vous le supprimer et le recréer? (y/N): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        log_info "Suppression du service existant..."
        hcloud load-balancer remove-service "$LB_ID" --listen-port 6379 || true
        sleep 2
    else
        log_info "Conservation du service existant"
    fi
fi

# Ajouter le service TCP 6379
log_info "Ajout du service TCP 6379..."
hcloud load-balancer add-service "$LB_ID" \
    --protocol tcp \
    --listen-port 6379 \
    --destination-port 6379

log_info "✅ Service TCP 6379 ajouté"

log_info ""
log_info "=========================================="
log_info "Configuration des targets (haproxy-01/02)"
log_info "=========================================="

# Récupérer les targets existants
EXISTING_TARGETS=$(hcloud load-balancer describe "$LB_ID" -o json | jq -r '.targets[] | "\(.type):\(.server.id // .ip.ip)"')

# Vérifier haproxy-01
HAPROXY_01_SERVER_ID=$(hcloud server list -o columns=id,name,ipv4 | grep -E "haproxy-01|10.0.0.11" | awk '{print $1}' | head -1 || echo "")

if [ -n "$HAPROXY_01_SERVER_ID" ]; then
    if echo "$EXISTING_TARGETS" | grep -q "server:$HAPROXY_01_SERVER_ID"; then
        log_warn "haproxy-01 est déjà un target"
    else
        log_info "Ajout de haproxy-01 (10.0.0.11) comme target..."
        hcloud load-balancer add-target "$LB_ID" \
            --type server \
            --server "$HAPROXY_01_SERVER_ID"
        log_info "✅ haproxy-01 ajouté"
    fi
else
    log_warn "haproxy-01 introuvable dans hcloud, ajout par IP..."
    hcloud load-balancer add-target "$LB_ID" \
        --type ip \
        --ip "$HAPROXY_01_IP"
    log_info "✅ haproxy-01 ajouté par IP"
fi

# Vérifier haproxy-02
HAPROXY_02_SERVER_ID=$(hcloud server list -o columns=id,name,ipv4 | grep -E "haproxy-02|10.0.0.12" | awk '{print $1}' | head -1 || echo "")

if [ -n "$HAPROXY_02_SERVER_ID" ]; then
    if echo "$EXISTING_TARGETS" | grep -q "server:$HAPROXY_02_SERVER_ID"; then
        log_warn "haproxy-02 est déjà un target"
    else
        log_info "Ajout de haproxy-02 (10.0.0.12) comme target..."
        hcloud load-balancer add-target "$LB_ID" \
            --type server \
            --server "$HAPROXY_02_SERVER_ID"
        log_info "✅ haproxy-02 ajouté"
    fi
else
    log_warn "haproxy-02 introuvable dans hcloud, ajout par IP..."
    hcloud load-balancer add-target "$LB_ID" \
        --type ip \
        --ip "$HAPROXY_02_IP"
    log_info "✅ haproxy-02 ajouté par IP"
fi

log_info ""
log_info "=========================================="
log_info "Vérification de la configuration"
log_info "=========================================="

# Afficher la configuration finale
log_info "Configuration du load balancer:"
hcloud load-balancer describe "$LB_ID" -o json | jq '{
    name: .name,
    ipv4: .public_net.ipv4.ip,
    private_net: .private_net[0].ip,
    services: [.services[] | select(.listen_port == 6379) | {
        protocol: .protocol,
        listen_port: .listen_port,
        destination_port: .destination_port
    }],
    targets: [.targets[] | {
        type: .type,
        server_id: .server.id,
        ip: .ip.ip
    }]
}'

log_info ""
log_info "=========================================="
log_info "✅ Configuration terminée"
log_info "=========================================="
log_info ""
log_info "Le load balancer expose maintenant:"
log_info "  - Port 6379 (TCP) → haproxy-01 (10.0.0.11:6379)"
log_info "                     → haproxy-02 (10.0.0.12:6379)"
log_info ""
log_info "Endpoint Redis pour les applications:"
log_info "  redis://:PASSWORD@10.0.0.10:6379/0"
log_info ""
log_info "Pour tester:"
log_info "  redis-cli -h 10.0.0.10 -p 6379 -a <PASSWORD> PING"
log_info ""
