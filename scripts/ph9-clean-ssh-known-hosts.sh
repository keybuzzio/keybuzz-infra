#!/bin/bash
# PH9 - Nettoyer les clés d'hôte SSH après rebuild des serveurs K8s
# Ce script supprime les anciennes clés d'hôte SSH et accepte les nouvelles

set -e

LOG_DIR="/opt/keybuzz/logs/phase9-hcloud-rebuild"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/clean-ssh-known-hosts-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================================="
echo "PH9 - NETTOYAGE DES CLÉS D'HÔTE SSH"
echo "Date: $(date)"
echo "=============================================="
echo ""

# IPs privées des serveurs K8s
MASTERS=("10.0.0.100" "10.0.0.101" "10.0.0.102")
WORKERS=("10.0.0.110" "10.0.0.111" "10.0.0.112" "10.0.0.113" "10.0.0.114")
ALL_SERVERS=("${MASTERS[@]}" "${WORKERS[@]}")

KNOWN_HOSTS_FILE="/root/.ssh/known_hosts"

# Vérifier que le fichier known_hosts existe
if [ ! -f "$KNOWN_HOSTS_FILE" ]; then
    echo "[WARN] Fichier $KNOWN_HOSTS_FILE n'existe pas, création..."
    mkdir -p /root/.ssh
    touch "$KNOWN_HOSTS_FILE"
    chmod 600 "$KNOWN_HOSTS_FILE"
fi

echo "[INFO] Fichier known_hosts: $KNOWN_HOSTS_FILE"
echo ""

# ==========================================
# Nettoyer les anciennes clés d'hôte
# ==========================================
echo "=== Nettoyage des anciennes clés d'hôte SSH ==="
echo ""

CLEANED=0

for ip in "${ALL_SERVERS[@]}"; do
    echo "[INFO] Nettoyage des clés d'hôte pour $ip..."
    
    # Supprimer les entrées pour cette IP dans known_hosts
    if ssh-keygen -f "$KNOWN_HOSTS_FILE" -R "$ip" &>/dev/null; then
        echo "  [OK] Anciennes clés supprimées pour $ip"
        CLEANED=$((CLEANED + 1))
    else
        echo "  [SKIP] Aucune clé trouvée pour $ip (ou déjà supprimée)"
    fi
    
    # Supprimer aussi par hostname (au cas où)
    hostname=$(nslookup "$ip" 2>/dev/null | grep "name =" | awk '{print $NF}' | sed 's/\.$//' || echo "")
    if [ -n "$hostname" ]; then
        ssh-keygen -f "$KNOWN_HOSTS_FILE" -R "$hostname" &>/dev/null || true
    fi
done

echo ""
echo "Résumé: $CLEANED entrées nettoyées"
echo ""

# ==========================================
# Accepter les nouvelles clés d'hôte
# ==========================================
echo "=== Acceptation des nouvelles clés d'hôte SSH ==="
echo ""

ACCEPTED=0
FAILED=0

accept_host_key() {
    local ip=$1
    local hostname=$2
    
    echo "[INFO] Acceptation de la nouvelle clé d'hôte pour $ip ($hostname)..."
    
    # Se connecter avec StrictHostKeyChecking=accept-new pour accepter automatiquement
    # Utiliser un timeout court pour éviter d'attendre si le serveur n'est pas prêt
    if ssh -o StrictHostKeyChecking=accept-new \
           -o UserKnownHostsFile="$KNOWN_HOSTS_FILE" \
           -o ConnectTimeout=10 \
           -o BatchMode=yes \
           root@"$ip" "echo OK" &>/dev/null; then
        echo "  [OK] Nouvelle clé acceptée pour $ip"
        return 0
    else
        echo "  [WARN] Impossible d'accepter la clé pour $ip (serveur peut-être pas encore prêt)"
        return 1
    fi
}

for ip in "${ALL_SERVERS[@]}"; do
    # Déterminer le hostname basé sur l'IP
    case "$ip" in
        10.0.0.100) hostname="k8s-master-01" ;;
        10.0.0.101) hostname="k8s-master-02" ;;
        10.0.0.102) hostname="k8s-master-03" ;;
        10.0.0.110) hostname="k8s-worker-01" ;;
        10.0.0.111) hostname="k8s-worker-02" ;;
        10.0.0.112) hostname="k8s-worker-03" ;;
        10.0.0.113) hostname="k8s-worker-04" ;;
        10.0.0.114) hostname="k8s-worker-05" ;;
        *) hostname="unknown" ;;
    esac
    
    if accept_host_key "$ip" "$hostname"; then
        ACCEPTED=$((ACCEPTED + 1))
    else
        FAILED=$((FAILED + 1))
    fi
    
    sleep 1
done

echo ""
echo "Résumé acceptation: $ACCEPTED acceptées, $FAILED échecs"
echo ""

# ==========================================
# Vérification finale
# ==========================================
echo "=== Vérification finale ==="
echo ""

echo "[INFO] Tentative de connexion aux serveurs pour vérifier..."
VERIFIED=0

for ip in "${ALL_SERVERS[@]}"; do
    if ssh -o StrictHostKeyChecking=yes \
           -o ConnectTimeout=5 \
           -o BatchMode=yes \
           root@"$ip" "echo OK" &>/dev/null; then
        echo "  ✓ $ip: Connexion OK (clé d'hôte acceptée)"
        VERIFIED=$((VERIFIED + 1))
    else
        echo "  ✗ $ip: Connexion échouée (peut nécessiter une intervention manuelle)"
    fi
done

echo ""
echo "=============================================="
echo "NETTOYAGE TERMINÉ"
echo "=============================================="
echo ""
echo "📋 RÉSUMÉ:"
echo "  - Entrées nettoyées: $CLEANED"
echo "  - Nouvelles clés acceptées: $ACCEPTED"
echo "  - Connexions vérifiées: $VERIFIED/${#ALL_SERVERS[@]}"
echo ""

if [ $VERIFIED -eq ${#ALL_SERVERS[@]} ]; then
    echo "✅ Toutes les clés d'hôte SSH sont à jour"
    echo "✅ Aucun avertissement SSH ne devrait plus apparaître"
else
    echo "⚠️  Certaines connexions échouent encore"
    echo "ℹ️  Vous pouvez réessayer plus tard ou accepter manuellement les clés"
fi

echo ""
echo "📄 Logs complets: $LOG_FILE"
echo ""

