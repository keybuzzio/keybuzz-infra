#!/bin/bash
# PH9 - Bootstrap Cluster Kubernetes HA avec bonnes pratiques
# Ce script ex??cute le bootstrap en suivant la s??quence s??quentielle recommand??e
# 
# S??QUENCE :
# 1. Master-01 : kubeadm init (bootstrap)
# 2. Attendre que master-01 soit pr??t
# 3. Master-02 : kubeadm join --control-plane
# 4. Attendre que master-02 soit int??gr??
# 5. Master-03 : kubeadm join --control-plane
# 6. Workers : kubeadm join (parall??le apr??s masters)

set -e

LOG_DIR="/opt/keybuzz/logs/phase9-bootstrap"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/bootstrap-k8s-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================================="
echo "PH9 - BOOTSTRAP CLUSTER K8S HA (BONNES PRATIQUES)"
echo "Date: $(date)"
echo "=============================================="
echo ""

INFRA_DIR="/opt/keybuzz/keybuzz-infra"
ANSIBLE_DIR="$INFRA_DIR/ansible"
INVENTORY_FILE="$ANSIBLE_DIR/inventory/hosts.yml"
PLAYBOOK_BEST_PRACTICES="$ANSIBLE_DIR/playbooks/k8s_cluster_v3_best_practices.yml"

# V??rifier Ansible
if ! command -v ansible-playbook &> /dev/null; then
    echo "[ERROR] Ansible n'est pas install??"
    exit 1
fi

echo "[OK] Ansible trouv??: $(ansible-playbook --version | head -1)"
echo ""

# V??rifier l'inventory
if [ ! -f "$INVENTORY_FILE" ]; then
    echo "[ERROR] Fichier inventory non trouv??: $INVENTORY_FILE"
    exit 1
fi

echo "[OK] Inventory trouv??: $INVENTORY_FILE"
echo ""

# V??rifier le playbook best practices
if [ ! -f "$PLAYBOOK_BEST_PRACTICES" ]; then
    echo "[WARN] Playbook best practices non trouv??: $PLAYBOOK_BEST_PRACTICES"
    echo "[INFO] Utilisation du playbook standard..."
    PLAYBOOK_BEST_PRACTICES="$ANSIBLE_DIR/playbooks/k8s_cluster_v3.yml"
fi

echo "[OK] Playbook: $PLAYBOOK_BEST_PRACTICES"
echo ""

# Afficher le document de bonnes pratiques
echo "=============================================="
echo "???? BONNES PRATIQUES APPLIQU??ES"
echo "=============================================="
echo ""
echo "??? S??quence s??quentielle : master-01 ??? master-02 ??? master-03"
echo "??? Configuration DNS avant bootstrap"
echo "??? Utilisation de fichiers de configuration kubeadm (IPs priv??es uniquement)"
echo "??? Certificats etcd avec SANs pour toutes les IPs priv??es"
echo "??? Attente entre chaque ??tape pour stabilit??"
echo "??? V??rifications de sant?? apr??s chaque ??tape"
echo ""
read -p "Appuyez sur ENTER pour continuer, ou Ctrl+C pour annuler..."
echo ""

# Ex??cuter le playbook
echo "=============================================="
echo "EX??CUTION DU PLAYBOOK"
echo "=============================================="
echo ""

cd "$ANSIBLE_DIR"

ANSIBLE_HOST_KEY_CHECKING=False \
ANSIBLE_SSH_COMMON_ARGS="-o StrictHostKeyChecking=no" \
ansible-playbook \
    -i "$INVENTORY_FILE" \
    "$PLAYBOOK_BEST_PRACTICES" \
    -v 2>&1 | tee -a "$LOG_FILE"

PLAYBOOK_EXIT=$?

if [ $PLAYBOOK_EXIT -ne 0 ]; then
    echo ""
    echo "[ERROR] Le playbook a ??chou?? (code: $PLAYBOOK_EXIT)"
    echo "[INFO] V??rifiez les logs ci-dessus"
    exit 1
fi

echo ""
echo "=============================================="
echo "BOOTSTRAP TERMIN??"
echo "=============================================="
echo ""
echo "???? R??SUM??:"
echo "  - Master-01 : Initialis??"
echo "  - Master-02 : Joint au control plane"
echo "  - Master-03 : Joint au control plane"
echo "  - Workers : Joints au cluster"
echo ""
echo "??? Cluster Kubernetes HA pr??t"
echo ""
echo "???? Logs complets: $LOG_FILE"
echo ""

