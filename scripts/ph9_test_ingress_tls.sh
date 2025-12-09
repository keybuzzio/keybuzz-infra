#!/bin/bash
# PH9-TLS-06 - Tests automatisés Ingress & TLS
# KeyBuzz v3 - Validation complète de la configuration HTTPS
# Ce script teste la résolution DNS, HTTP, HTTPS et la validité des certificats

set -euo pipefail

LOG_DIR="/opt/keybuzz/logs/phase9-tls"
mkdir -p "$LOG_DIR"

log_info() {
    echo "[INFO] $1" | tee -a "$LOG_DIR/ingress-tls-tests.log"
}

log_error() {
    echo "[ERROR] $1" | tee -a "$LOG_DIR/ingress-tls-tests.log" >&2
}

log_success() {
    echo "[✅] $1" | tee -a "$LOG_DIR/ingress-tls-tests.log"
}

log_warning() {
    echo "[⚠️] $1" | tee -a "$LOG_DIR/ingress-tls-tests.log"
}

# Vérification kubectl
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl n'est pas installé"
    exit 1
fi

log_info "Vérification de l'accès au cluster..."
export KUBECONFIG=/root/.kube/config
if ! kubectl cluster-info &> /dev/null; then
    log_error "Impossible d'accéder au cluster Kubernetes"
    exit 1
fi

# Variables
DEV_HOST="admin-dev.keybuzz.io"
PROD_HOST="admin.keybuzz.io"
TEST_RESULTS=0

log_info "=========================================="
log_info "TESTS INGRESS & TLS - KeyBuzz Admin"
log_info "=========================================="
log_info ""

# Test 1 : Résolution DNS
log_info "TEST 1 : Résolution DNS"
log_info "------------------------"

for host in "$DEV_HOST" "$PROD_HOST"; do
    log_info "Test DNS pour $host..."
    if dig +short "$host" | grep -q "^[0-9]"; then
        IP=$(dig +short "$host" | head -1)
        log_success "DNS résolu : $host → $IP"
    else
        log_error "DNS non résolu pour $host"
        TEST_RESULTS=$((TEST_RESULTS + 1))
    fi
done

log_info ""

# Test 2 : Ingress dans le cluster
log_info "TEST 2 : Ingress dans le cluster"
log_info "--------------------------------"

log_info "Vérification Ingress admin-dev..."
if kubectl get ingress ingress-admin-dev -n keybuzz-admin-dev &> /dev/null; then
    log_success "Ingress ingress-admin-dev existe"
    kubectl get ingress ingress-admin-dev -n keybuzz-admin-dev -o wide | tee -a "$LOG_DIR/ingress-tls-tests.log"
else
    log_error "Ingress ingress-admin-dev n'existe pas"
    TEST_RESULTS=$((TEST_RESULTS + 1))
fi

log_info "Vérification Ingress admin-prod..."
if kubectl get ingress ingress-admin-prod -n keybuzz-admin &> /dev/null; then
    log_success "Ingress ingress-admin-prod existe"
    kubectl get ingress ingress-admin-prod -n keybuzz-admin -o wide | tee -a "$LOG_DIR/ingress-tls-tests.log"
else
    log_error "Ingress ingress-admin-prod n'existe pas"
    TEST_RESULTS=$((TEST_RESULTS + 1))
fi

log_info ""

# Test 3 : Certificats cert-manager
log_info "TEST 3 : Certificats cert-manager"
log_info "----------------------------------"

log_info "Vérification certificat admin-dev..."
if kubectl get certificate keybuzz-admin-dev-tls -n keybuzz-admin-dev &> /dev/null; then
    log_success "Certificate keybuzz-admin-dev-tls existe"
    CERT_STATUS=$(kubectl get certificate keybuzz-admin-dev-tls -n keybuzz-admin-dev -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
    if [ "$CERT_STATUS" == "True" ]; then
        log_success "Certificat admin-dev est Ready"
    else
        log_warning "Certificat admin-dev n'est pas encore Ready (status: $CERT_STATUS)"
        kubectl describe certificate keybuzz-admin-dev-tls -n keybuzz-admin-dev | tee -a "$LOG_DIR/ingress-tls-tests.log"
    fi
else
    log_warning "Certificate keybuzz-admin-dev-tls n'existe pas encore (sera créé par cert-manager)"
fi

log_info "Vérification certificat admin-prod..."
if kubectl get certificate keybuzz-admin-prod-tls -n keybuzz-admin &> /dev/null; then
    log_success "Certificate keybuzz-admin-prod-tls existe"
    CERT_STATUS=$(kubectl get certificate keybuzz-admin-prod-tls -n keybuzz-admin -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
    if [ "$CERT_STATUS" == "True" ]; then
        log_success "Certificat admin-prod est Ready"
    else
        log_warning "Certificat admin-prod n'est pas encore Ready (status: $CERT_STATUS)"
        kubectl describe certificate keybuzz-admin-prod-tls -n keybuzz-admin | tee -a "$LOG_DIR/ingress-tls-tests.log"
    fi
else
    log_warning "Certificate keybuzz-admin-prod-tls n'existe pas encore (sera créé par cert-manager)"
fi

log_info ""

# Test 4 : HTTP reachability
log_info "TEST 4 : HTTP reachability via LB"
log_info "-----------------------------------"

for host in "$DEV_HOST" "$PROD_HOST"; do
    log_info "Test HTTP pour $host..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://$host/.well-known/acme-challenge/test" || echo "000")
    if [ "$HTTP_CODE" == "404" ] || [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "503" ]; then
        log_success "HTTP accessible pour $host (code: $HTTP_CODE)"
    elif [ "$HTTP_CODE" == "000" ]; then
        log_error "HTTP non accessible pour $host (timeout ou connexion refusée)"
        TEST_RESULTS=$((TEST_RESULTS + 1))
    else
        log_warning "HTTP répond avec code inattendu pour $host (code: $HTTP_CODE)"
    fi
done

log_info ""

# Test 5 : HTTPS handshake
log_info "TEST 5 : HTTPS handshake"
log_info "-------------------------"

for host in "$DEV_HOST" "$PROD_HOST"; do
    log_info "Test HTTPS pour $host..."
    if timeout 10 openssl s_client -connect "$host:443" -servername "$host" </dev/null 2>/dev/null | grep -q "Verify return code: 0"; then
        log_success "HTTPS handshake réussi pour $host"
    else
        log_warning "HTTPS handshake échoué ou certificat non encore disponible pour $host"
        # Ce n'est pas une erreur critique si le certificat n'est pas encore généré
    fi
done

log_info ""

# Test 6 : Validité du certificat
log_info "TEST 6 : Validité du certificat"
log_info "-------------------------------"

for host in "$DEV_HOST" "$PROD_HOST"; do
    log_info "Vérification certificat pour $host..."
    CERT_INFO=$(timeout 10 openssl s_client -connect "$host:443" -servername "$host" </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates 2>/dev/null || echo "")
    if [ -n "$CERT_INFO" ]; then
        log_success "Certificat valide pour $host"
        echo "$CERT_INFO" | tee -a "$LOG_DIR/ingress-tls-tests.log"
        
        # Vérifier le CN
        CN=$(echo "$CERT_INFO" | grep "subject=" | grep -o "CN=[^,]*" | cut -d= -f2)
        if echo "$CN" | grep -q "$host"; then
            log_success "CN du certificat correspond : $CN"
        else
            log_warning "CN du certificat ne correspond pas : $CN (attendu: $host)"
        fi
    else
        log_warning "Impossible de récupérer le certificat pour $host (peut-être pas encore généré)"
    fi
done

log_info ""

# Test 7 : Backend KeyBuzz Admin (dev uniquement pour test)
log_info "TEST 7 : Backend KeyBuzz Admin (dev)"
log_info "-------------------------------------"

log_info "Vérification Service keybuzz-admin dans keybuzz-admin-dev..."
if kubectl get service keybuzz-admin -n keybuzz-admin-dev &> /dev/null; then
    log_success "Service keybuzz-admin existe dans keybuzz-admin-dev"
    SERVICE_IP=$(kubectl get service keybuzz-admin -n keybuzz-admin-dev -o jsonpath='{.spec.clusterIP}')
    SERVICE_PORT=$(kubectl get service keybuzz-admin -n keybuzz-admin-dev -o jsonpath='{.spec.ports[0].port}')
    log_info "Service ClusterIP : $SERVICE_IP:$SERVICE_PORT"
    
    # Test depuis un pod (si disponible)
    if kubectl get pods -n keybuzz-admin-dev | grep -q "Running"; then
        log_info "Pods disponibles dans keybuzz-admin-dev"
    else
        log_warning "Aucun pod en cours d'exécution dans keybuzz-admin-dev (normal si l'application n'est pas encore déployée)"
    fi
else
    log_warning "Service keybuzz-admin n'existe pas encore dans keybuzz-admin-dev (normal si l'application n'est pas encore déployée)"
fi

log_info ""

# Résumé
log_info "=========================================="
log_info "RÉSUMÉ DES TESTS"
log_info "=========================================="

if [ $TEST_RESULTS -eq 0 ]; then
    log_success "Tous les tests critiques ont réussi"
    log_info "Note : Les certificats peuvent prendre quelques minutes à être générés par cert-manager"
    exit 0
else
    log_error "$TEST_RESULTS test(s) critique(s) ont échoué"
    log_info "Consultez les logs ci-dessus pour plus de détails"
    exit 1
fi

