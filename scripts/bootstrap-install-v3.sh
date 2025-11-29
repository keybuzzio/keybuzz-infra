#!/bin/bash
# Bootstrap script for install-v3 bastion
# KeyBuzz v3 - Idempotent setup script
# This script prepares install-v3 as the official bastion for KeyBuzz v3

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REPOS_DIR="/opt/keybuzz"
SSH_KEY_PATH="$HOME/.ssh/id_rsa_keybuzz_v3"
GITHUB_ORG="keybuzzio"
REPOS=(
    "keybuzz-infra"
    "keybuzz-db"
    "keybuzz-k8s"
    "keybuzz-automation"
    "keybuzz-apps"
    "keybuzz-docs"
)

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    log_error "This script should not be run as root. Run as a regular user with sudo privileges."
    exit 1
fi

log_info "Starting bootstrap for install-v3 bastion..."

# 1. Install base packages
log_info "Installing base packages..."
sudo apt-get update
sudo apt-get install -y \
    git \
    curl \
    wget \
    vim \
    htop \
    python3 \
    python3-pip \
    jq \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release

# 2. Install Ansible
if ! command -v ansible &> /dev/null; then
    log_info "Installing Ansible..."
    sudo pip3 install ansible
else
    log_info "Ansible already installed: $(ansible --version | head -n1)"
fi

# 3. Install Terraform
if ! command -v terraform &> /dev/null; then
    log_info "Installing Terraform..."
    TERRAFORM_VERSION="1.6.0"
    wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    unzip -q "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    sudo mv terraform /usr/local/bin/
    rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    log_info "Terraform ${TERRAFORM_VERSION} installed"
else
    log_info "Terraform already installed: $(terraform version | head -n1)"
fi

# 4. Install kubectl
if ! command -v kubectl &> /dev/null; then
    log_info "Installing kubectl..."
    KUBECTL_VERSION="v1.28.0"
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    log_info "kubectl ${KUBECTL_VERSION} installed"
else
    log_info "kubectl already installed: $(kubectl version --client --short 2>/dev/null || echo 'installed')"
fi

# 5. Install Helm
if ! command -v helm &> /dev/null; then
    log_info "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    log_info "Helm installed"
else
    log_info "Helm already installed: $(helm version --short)"
fi

# 6. Install GitHub CLI
if ! command -v gh &> /dev/null; then
    log_info "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y gh
    log_info "GitHub CLI installed"
else
    log_info "GitHub CLI already installed: $(gh --version | head -n1)"
fi

# 7. Create repos directory
log_info "Creating repositories directory: $REPOS_DIR"
sudo mkdir -p "$REPOS_DIR"
sudo chown "$USER:$USER" "$REPOS_DIR"

# 8. Clone or update repositories
log_info "Cloning/updating GitHub repositories..."
cd "$REPOS_DIR"

for repo in "${REPOS[@]}"; do
    repo_path="$REPOS_DIR/$repo"
    repo_url="https://github.com/${GITHUB_ORG}/${repo}.git"
    
    if [[ -d "$repo_path" ]]; then
        log_info "Repository $repo exists, updating..."
        cd "$repo_path"
        git fetch origin
        git pull origin main || git pull origin master || log_warn "Could not pull $repo"
        cd "$REPOS_DIR"
    else
        log_info "Cloning $repo..."
        git clone "$repo_url" || log_error "Failed to clone $repo"
    fi
done

# 9. Generate SSH key for install-v3 (idempotent)
log_info "Setting up SSH key for install-v3..."
if [[ ! -f "$SSH_KEY_PATH" ]]; then
    log_info "Generating new SSH key: $SSH_KEY_PATH"
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N "" -C "install-v3-keybuzz-v3"
    log_info "SSH key generated"
else
    log_info "SSH key already exists: $SSH_KEY_PATH"
fi

# Add key to SSH agent if not already added
if ! ssh-add -l | grep -q "$SSH_KEY_PATH"; then
    log_info "Adding SSH key to agent..."
    eval "$(ssh-agent -s)"
    ssh-add "$SSH_KEY_PATH" || log_warn "Could not add key to agent"
fi

# 10. Display public key for manual distribution
log_info "SSH Public Key for install-v3:"
echo "=========================================="
cat "${SSH_KEY_PATH}.pub"
echo "=========================================="
log_warn "Copy this public key to all servers in servers_v3.tsv (except install-01 and install-v3)"
log_warn "You can use: ssh-copy-id -i ${SSH_KEY_PATH}.pub user@host"

# 11. Create symlinks for easy access
log_info "Creating convenience symlinks..."
mkdir -p "$HOME/bin"
for repo in "${REPOS[@]}"; do
    if [[ ! -L "$HOME/bin/$repo" ]]; then
        ln -s "$REPOS_DIR/$repo" "$HOME/bin/$repo"
    fi
done

log_info "Bootstrap completed successfully!"
log_info "Repositories are available in: $REPOS_DIR"
log_info "Next steps:"
log_info "  1. Copy the SSH public key above to all target servers"
log_info "  2. Configure GitHub authentication: gh auth login"
log_info "  3. Test Ansible connectivity: ansible all -m ping -i $REPOS_DIR/keybuzz-infra/ansible/inventory/hosts.yml"

