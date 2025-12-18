#!/bin/bash
# PH9 - Tester SSH et nettoyer les anciennes clés host
# Ce script:
# 1. Nettoie les anciennes clés host dans known_hosts
# 2. Teste la connexion SSH vers chaque serveur depuis install-v3

set -e

SSH_KEY_PATH="/root/.ssh/id_rsa_keybuzz_v3"

# Liste des serveurs avec leurs IPs privées
declare -A SERVERS=(
    ["k8s-master-01"]="10.0.0.100"
    ["k8s-master-02"]="10.0.0.101"
    ["k8s-master-03"]="10.0.0.102"
    ["k8s-worker-01"]="10.0.0.110"
    ["k8s-worker-02"]="10.0.0.111"
    ["k8s-worker-03"]="10.0.0.112"
    ["k8s-worker-04"]="10.0.0.113"
    ["k8s-worker-05"]="10.0.0.114"
)

echo "=============================================="
echo "NETTOYAGE DES ANCIENNES CLÉS HOST SSH"
echo "=============================================="
echo ""

# Nettoyer les anciennes clés host pour chaque serveur
for hostname in "${!SERVERS[@]}"; do
    ip="${SERVERS[$hostname]}"
    echo "[INFO] Nettoyage des anciennes clés host pour $hostname ($ip)..."
    
    # Supprimer l'entrée par IP
    ssh-keygen -f /root/.ssh/known_hosts -R "$ip" 2>/dev/null || true
    
    # Supprimer aussi par hostname si présent
    ssh-keygen -f /root/.ssh/known_hosts -R "$hostname" 2>/dev/null || true
    
    echo "  [OK] Clés host supprimées pour $ip"
done

echo ""
echo "=============================================="
echo "TEST DES CONNEXIONS SSH"
echo "=============================================="
echo ""

SUCCESS=0
FAILED=0

for hostname in "${!SERVERS[@]}"; do
    ip="${SERVERS[$hostname]}"
    echo "[TEST] Connexion vers $hostname ($ip)..."
    
    if ssh -i "$SSH_KEY_PATH" \
        -o StrictHostKeyChecking=accept-new \
        -o ConnectTimeout=10 \
        -o BatchMode=yes \
        root@"$ip" \
        "echo 'OK - Connexion réussie'" 2>/dev/null; then
        echo "  ✅ $hostname: Connexion SSH OK"
        SUCCESS=$((SUCCESS + 1))
    else
        echo "  ❌ $hostname: Échec de connexion SSH"
        FAILED=$((FAILED + 1))
    fi
    echo ""
done

echo "=============================================="
echo "RÉSUMÉ"
echo "=============================================="
echo ""
echo "✅ Connexions réussies: $SUCCESS/8"
echo "❌ Connexions échouées: $FAILED/8"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 Toutes les connexions SSH fonctionnent correctement !"
    exit 0
else
    echo "⚠️  Certaines connexions SSH ont échoué. Vérifiez les clés déployées."
    exit 1
fi

