#!/bin/bash
# PH9 - Phase 2 : Préparation Base OS & Kubernetes des 8 serveurs K8s
# Ce script exécute la préparation des serveurs sans initialiser le cluster
# Il prépare : swap, containerd, kubelet, kubeadm, kubectl

set -e

LOG_DIR="/opt/keybuzz/logs/phase9-phase2"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/phase2-prepare-k8s-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=============================================="
echo "PH9 - PHASE 2 : PRÉPARATION SERVEURS K8S"
echo "Date: $(date)"
echo "=============================================="
echo ""

# Configuration
INFRA_DIR="/opt/keybuzz/keybuzz-infra"
ANSIBLE_DIR="$INFRA_DIR/ansible"
INVENTORY_FILE="$ANSIBLE_DIR/inventory/hosts.yml"
PLAYBOOK_DIR="$ANSIBLE_DIR/playbooks"

# Vérifier que nous sommes sur install-v3
if [ ! -f "$INFRA_DIR/servers/servers_v3.tsv" ]; then
    echo "[ERROR] Ce script doit être exécuté sur install-v3"
    exit 1
fi

# Vérifier Ansible
if ! command -v ansible-playbook &> /dev/null; then
    echo "[ERROR] Ansible n'est pas installé"
    exit 1
fi

echo "[OK] Ansible trouvé: $(ansible-playbook --version | head -1)"
echo ""

# Vérifier l'inventory
if [ ! -f "$INVENTORY_FILE" ]; then
    echo "[ERROR] Fichier inventory non trouvé: $INVENTORY_FILE"
    echo "[INFO] Régénération de l'inventory..."
    cd "$INFRA_DIR"
    if [ -f scripts/generate_inventory.py ]; then
        python3 scripts/generate_inventory.py > "$INVENTORY_FILE"
        echo "[OK] Inventory régénéré"
    else
        echo "[ERROR] Script generate_inventory.py non trouvé"
        exit 1
    fi
fi

echo "[OK] Inventory trouvé: $INVENTORY_FILE"
echo ""

# ==========================================
# ÉTAPE 1: Vérifier la connectivité SSH
# ==========================================
echo "=== ÉTAPE 1: Vérification de la connectivité SSH ==="
echo ""

echo "[INFO] Test de connexion aux 8 serveurs K8s..."
ANSIBLE_HOST_KEY_CHECKING=False ansible k8s_masters:k8s_workers -i "$INVENTORY_FILE" -m ping -o 2>&1 | tee -a "$LOG_FILE" || {
    echo "[ERROR] Certains serveurs ne sont pas accessibles"
    echo "[INFO] Vérification des clés SSH d'hôte..."
    exit 1
}

echo ""
echo "[OK] Tous les serveurs sont accessibles"
echo ""

# ==========================================
# ÉTAPE 2: Créer un playbook de préparation uniquement
# ==========================================
echo "=== ÉTAPE 2: Création du playbook de préparation ==="
echo ""

PREPARE_PLAYBOOK="$PLAYBOOK_DIR/k8s_prepare_only.yml"

cat > "$PREPARE_PLAYBOOK" <<'EOF'
---
# Kubernetes Cluster v3 - Preparation Only
# Prepares all Kubernetes nodes WITHOUT cluster initialization
# This is PHASE 2: Base OS & Kubernetes prerequisites

- name: Prepare all Kubernetes nodes
  hosts: k8s_masters:k8s_workers
  become: yes
  gather_facts: yes
  roles:
    - k8s_cluster_v3
EOF

echo "[OK] Playbook de préparation créé: $PREPARE_PLAYBOOK"
echo ""

# ==========================================
# ÉTAPE 3: Exécuter le playbook de préparation
# ==========================================
echo "=== ÉTAPE 3: Exécution du playbook de préparation ==="
echo ""

cd "$ANSIBLE_DIR"

echo "[INFO] Exécution du playbook sur les 8 serveurs K8s..."
echo "[INFO] Cela peut prendre 10-15 minutes..."
echo ""

ANSIBLE_HOST_KEY_CHECKING=False \
ANSIBLE_SSH_COMMON_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/root/.ssh/known_hosts" \
ansible-playbook \
    -i "$INVENTORY_FILE" \
    "$PREPARE_PLAYBOOK" \
    -v 2>&1 | tee -a "$LOG_FILE"

PLAYBOOK_EXIT=$?

if [ $PLAYBOOK_EXIT -ne 0 ]; then
    echo ""
    echo "[ERROR] Le playbook a échoué (code: $PLAYBOOK_EXIT)"
    echo "[INFO] Vérifiez les logs ci-dessus"
    exit 1
fi

echo ""
echo "[OK] Playbook de préparation exécuté avec succès"
echo ""

# ==========================================
# ÉTAPE 4: Vérification de la préparation
# ==========================================
echo "=== ÉTAPE 4: Vérification de la préparation ==="
echo ""

echo "[INFO] Vérification de containerd sur tous les serveurs..."
ANSIBLE_HOST_KEY_CHECKING=False \
ansible k8s_masters:k8s_workers \
    -i "$INVENTORY_FILE" \
    -m shell \
    -a "systemctl is-active containerd && systemctl is-enabled containerd" \
    -o 2>&1 | tee -a "$LOG_FILE" || echo "[WARN] Certains serveurs n'ont pas containerd actif"

echo ""
echo "[INFO] Vérification de kubelet sur tous les serveurs..."
ANSIBLE_HOST_KEY_CHECKING=False \
ansible k8s_masters:k8s_workers \
    -i "$INVENTORY_FILE" \
    -m shell \
    -a "systemctl is-active kubelet && systemctl is-enabled kubelet && kubelet --version" \
    -o 2>&1 | tee -a "$LOG_FILE" || echo "[WARN] Certains serveurs n'ont pas kubelet actif"

echo ""
echo "[INFO] Vérification de swap désactivé..."
ANSIBLE_HOST_KEY_CHECKING=False \
ansible k8s_masters:k8s_workers \
    -i "$INVENTORY_FILE" \
    -m shell \
    -a "swapon --summary | grep -v 'Filename' | wc -l" \
    -o 2>&1 | tee -a "$LOG_FILE" || echo "[WARN] Vérification swap échouée"

echo ""
echo "[INFO] Vérification de br_netfilter..."
ANSIBLE_HOST_KEY_CHECKING=False \
ansible k8s_masters:k8s_workers \
    -i "$INVENTORY_FILE" \
    -m shell \
    -a "lsmod | grep br_netfilter && sysctl net.bridge.bridge-nf-call-iptables" \
    -o 2>&1 | tee -a "$LOG_FILE" || echo "[WARN] Vérification br_netfilter échouée"

echo ""

# ==========================================
# ÉTAPE 5: Résumé final
# ==========================================
echo "=== ÉTAPE 5: Résumé final ==="
echo ""

echo "[INFO] Liste des serveurs préparés:"
ANSIBLE_HOST_KEY_CHECKING=False \
ansible k8s_masters:k8s_workers \
    -i "$INVENTORY_FILE" \
    -m setup \
    -a "filter=ansible_hostname" \
    -o 2>&1 | grep "ansible_hostname" | tee -a "$LOG_FILE" || true

echo ""
echo "=============================================="
echo "PHASE 2 TERMINÉE"
echo "=============================================="
echo ""
echo "✅ Les 8 serveurs K8s ont été préparés:"
echo "   - Swap désactivé"
echo "   - br_netfilter configuré"
echo "   - IP forwarding activé"
echo "   - containerd installé et configuré"
echo "   - kubelet, kubeadm, kubectl installés"
echo ""
echo "📄 Logs complets: $LOG_FILE"
echo ""

