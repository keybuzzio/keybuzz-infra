#!/bin/bash
#
# configure_lbhaproxy_postgres.sh
# Configure le load balancer Hetzner lb-haproxy pour exposer PostgreSQL (port 5432)
#
# Usage:
#   ./configure_lbhaproxy_postgres.sh [LB_ID]
#

set -euo pipefail

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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
    exit 1
fi

# Récupérer le LB_ID
LB_ID="${1:-}"

if [ -z "$LB_ID" ]; then
    log_info "Recherche du load balancer lb-haproxy..."
    LB_LIST=$(hcloud load-balancer list -o columns=id,name,ipv4 | grep -E "lb-haproxy|haproxy" || true)
    
    if [ -z "$LB_LIST" ]; then
        log_error "Aucun load balancer 'lb-haproxy' trouvé"
        hcloud load-balancer list
        read -p "Entrez l'ID du load balancer: " LB_ID
    else
        echo "$LB_LIST"
        read -p "Entrez l'ID du load balancer lb-haproxy: " LB_ID
    fi
fi

if [ -z "$LB_ID" ]; then
    log_error "LB_ID requis"
    exit 1
fi

log_info "Configuration du load balancer: $LB_ID"

LB_NAME=$(hcloud load-balancer describe "$LB_ID" -o json | jq -r '.name')
LB_IP=$(hcloud load-balancer describe "$LB_ID" -o json | jq -r '.public_net.ipv4.ip')

log_info "Nom: $LB_NAME"
log_info "IP publique: $LB_IP"

HAPROXY_01_IP="10.0.0.11"
HAPROXY_02_IP="10.0.0.12"

log_info ""
log_info "=========================================="
log_info "Configuration du service TCP 5432 (PostgreSQL)"
log_info "=========================================="

# Vérifier si le service existe déjà
if hcloud load-balancer describe "$LB_ID" -o json | jq -e '.services[] | select(.listen_port == 5432)' &> /dev/null; then
    log_warn "Le service TCP 5432 existe déjà"
    read -p "Voulez-vous le supprimer et le recréer? (y/N): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        log_info "Suppression du service existant..."
        hcloud load-balancer remove-service "$LB_ID" --listen-port 5432 || true
        sleep 2
    fi
fi

# Ajouter le service TCP 5432
log_info "Ajout du service TCP 5432..."
hcloud load-balancer add-service "$LB_ID" \
    --protocol tcp \
    --listen-port 5432 \
    --destination-port 5432

log_info "✅ Service TCP 5432 ajouté"

log_info ""
log_info "=========================================="
log_info "Configuration des targets (haproxy-01/02)"
log_info "=========================================="

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
fi

log_info ""
log_info "=========================================="
log_info "✅ Configuration terminée"
log_info "=========================================="
log_info ""
log_info "Le load balancer expose maintenant:"
log_info "  - Port 5432 (TCP) → haproxy-01 (10.0.0.11:5432)"
log_info "                     → haproxy-02 (10.0.0.12:5432)"
log_info ""
log_info "Endpoint PostgreSQL pour les applications:"
log_info "  postgresql://postgres:POSTGRES_PASSWORD@10.0.0.10:5432/"
log_info ""

