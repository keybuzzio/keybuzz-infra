#!/bin/bash
# PH9 - Afficher la clé SSH publique pour redéploiement

SSH_PUB_KEY="/root/.ssh/id_rsa_keybuzz_v3.pub"
SSH_PRIV_KEY="/root/.ssh/id_rsa_keybuzz_v3"

echo "=============================================="
echo "CLÉ SSH POUR KEYBUZZ V3"
echo "=============================================="
echo ""

if [ -f "$SSH_PUB_KEY" ]; then
    echo "✅ Clé publique trouvée: $SSH_PUB_KEY"
    echo ""
    echo "📋 CLÉ SSH PUBLIQUE (à copier sur les 8 serveurs):"
    echo "=============================================="
    cat "$SSH_PUB_KEY"
    echo "=============================================="
    echo ""
    echo "📝 Commande pour redéployer sur un serveur:"
    echo "   echo '$(cat $SSH_PUB_KEY)' >> ~/.ssh/authorized_keys"
    echo ""
    echo "📝 Ou avec ssh-copy-id (si mot de passe root disponible):"
    echo "   ssh-copy-id -i $SSH_PUB_KEY root@<IP_PUBLIQUE>"
    echo ""
else
    echo "❌ Clé publique non trouvée à: $SSH_PUB_KEY"
    echo ""
    echo "Vérifiez que la clé existe ou générez-la avec:"
    echo "   ssh-keygen -t rsa -b 4096 -f $SSH_PRIV_KEY -N '' -C 'install-v3-keybuzz-v3'"
fi

echo ""
echo "📍 Emplacement de la clé privée (sur install-v3):"
echo "   $SSH_PRIV_KEY"

echo ""
echo "📍 Liste des serveurs Kubernetes:"
echo "   Masters:"
echo "   - k8s-master-01: 10.0.0.100 (public: 91.98.124.228)"
echo "   - k8s-master-02: 10.0.0.101 (public: 91.98.117.26)"
echo "   - k8s-master-03: 10.0.0.102 (public: 91.98.165.238)"
echo ""
echo "   Workers:"
echo "   - k8s-worker-01: 10.0.0.110 (public: 116.203.135.192)"
echo "   - k8s-worker-02: 10.0.0.111 (public: 91.99.164.62)"
echo "   - k8s-worker-03: 10.0.0.112 (public: 157.90.119.183)"
echo "   - k8s-worker-04: 10.0.0.113 (public: 91.98.200.38)"
echo "   - k8s-worker-05: 10.0.0.114 (public: 188.245.45.242)"

