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
SSH_KEY_PATH="/root/.ssh/id_rsa_keybuzz_v3"
GITHUB_ORG="keybuzzio"
SERVERS_TSV="$REPOS_DIR/keybuzz-infra/servers/servers_v3.tsv"
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
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root for SSH key deployment."
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
mkdir -p "$REPOS_DIR"

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
mkdir -p /root/.ssh
chmod 700 /root/.ssh

if [[ ! -f "$SSH_KEY_PATH" ]]; then
    log_info "Generating new SSH key: $SSH_KEY_PATH"
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N "" -C "install-v3-keybuzz-v3"
    chmod 600 "$SSH_KEY_PATH"
    chmod 644 "${SSH_KEY_PATH}.pub"
    log_info "SSH key generated"
else
    log_info "SSH key already exists: $SSH_KEY_PATH"
fi

# Add key to SSH agent if not already added
if ! ssh-add -l 2>/dev/null | grep -q "$SSH_KEY_PATH"; then
    log_info "Adding SSH key to agent..."
    eval "$(ssh-agent -s)" > /dev/null 2>&1
    ssh-add "$SSH_KEY_PATH" 2>/dev/null || log_warn "Could not add key to agent"
fi

# 10. Deploy SSH key to all servers (SSH mesh)
log_info "Deploying SSH key to all servers in servers_v3.tsv..."

if [[ ! -f "$SERVERS_TSV" ]]; then
    log_warn "servers_v3.tsv not found at $SERVERS_TSV, skipping SSH deployment"
    log_warn "SSH Public Key for manual distribution:"
    echo "=========================================="
    cat "${SSH_KEY_PATH}.pub"
    echo "=========================================="
else
    log_info "Reading servers from $SERVERS_TSV..."
    
    # Install sshpass if not available
    if ! command -v sshpass &> /dev/null; then
        log_info "Installing sshpass for automated SSH key deployment..."
        apt-get install -y sshpass
    fi
    
    # Read TSV file (skip header and empty lines)
    deployed=0
    failed=0
    skipped=0
    
    while IFS=$'\t' read -r env ip_public hostname ip_private fqdn user_ssh pool role subrole docker_stack core notes role_v3; do
        # Skip header and empty lines
        [[ "$hostname" == "HOSTNAME" ]] && continue
        [[ -z "$hostname" ]] && continue
        [[ "$hostname" == "install-01" ]] && { ((skipped++)); continue; }
        [[ "$hostname" == "install-v3" ]] && { ((skipped++)); continue; }
        
        if [[ -z "$ip_public" ]] || [[ -z "$user_ssh" ]]; then
            log_warn "Skipping $hostname: missing IP or user"
            ((skipped++))
            continue
        fi
        
        log_info "Deploying SSH key to $hostname ($ip_public)..."
        
        # Try to copy key using sshpass (assuming password auth initially)
        # In production, you might want to use a temporary password or pre-shared key
        if sshpass -p "TEMPORARY_PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no -i "${SSH_KEY_PATH}.pub" "${user_ssh}@${ip_public}" 2>/dev/null; then
            log_info "✓ SSH key deployed to $hostname"
            ((deployed++))
            
            # Test connection via private IP
            if [[ -n "$ip_private" ]]; then
                log_info "  Testing connection via private IP $ip_private..."
                if ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no -o ConnectTimeout=5 "${user_ssh}@${ip_private}" "echo 'Connection successful'" 2>/dev/null; then
                    log_info "  ✓ Private IP connection successful"
                else
                    log_warn "  ✗ Private IP connection failed (may need network setup)"
                fi
            fi
        else
            log_warn "✗ Failed to deploy SSH key to $hostname (may need manual setup)"
            ((failed++))
        fi
        
    done < <(tail -n +2 "$SERVERS_TSV")
    
    log_info "SSH deployment summary:"
    log_info "  Deployed: $deployed"
    log_info "  Failed: $failed"
    log_info "  Skipped: $skipped"
    
    if [[ $failed -gt 0 ]]; then
        log_warn "Some servers failed. You may need to deploy keys manually:"
        log_warn "  ssh-copy-id -i ${SSH_KEY_PATH}.pub user@host"
    fi
fi

# 11. Create symlinks for easy access
log_info "Creating convenience symlinks..."
mkdir -p /root/bin
for repo in "${REPOS[@]}"; do
    if [[ ! -L "/root/bin/$repo" ]]; then
        ln -s "$REPOS_DIR/$repo" "/root/bin/$repo"
    fi
done

log_info "Bootstrap completed successfully!"
log_info "Repositories are available in: $REPOS_DIR"
log_info "SSH key is available at: $SSH_KEY_PATH"
log_info "Next steps:"
log_info "  1. Verify SSH connectivity: ansible all -m ping -i $REPOS_DIR/keybuzz-infra/ansible/inventory/hosts.yml"
log_info "  2. Configure GitHub authentication: gh auth login"
log_info "  3. Test private IP connectivity from install-v3"

