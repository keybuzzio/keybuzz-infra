#!/bin/bash
# PH10-UI-DEPLOY-AUTO A.3 - Mettre à jour les images K8s dev/prod et commit
set -euo pipefail

LOG_DIR="/opt/keybuzz/logs/ph10-ui"
LOG_FILE="$LOG_DIR/update-images.log"
mkdir -p "$LOG_DIR"

DEV_FILE="/opt/keybuzz/keybuzz-infra/k8s/keybuzz-admin-dev/deployment.yaml"
PROD_FILE="/opt/keybuzz/keybuzz-infra/k8s/keybuzz-admin/deployment.yaml"

DEV_IMAGE="ghcr.io/keybuzzio/keybuzz-admin:v1.0.0-dev"
PROD_IMAGE="ghcr.io/keybuzzio/keybuzz-admin:v1.0.0"

log_info() { echo "[INFO] $1" | tee -a "$LOG_FILE"; }
log_error() { echo "[ERROR] $1" | tee -a "$LOG_FILE" >&2; }

log_info "Démarrage mise à jour images K8s"

for f in "$DEV_FILE" "$PROD_FILE"; do
  if [ ! -f "$f" ]; then
    log_error "Fichier manquant: $f"
    exit 1
  fi
done

update_image() {
  local file=$1
  local placeholder=$2
  local image=$3

  if grep -q "$image" "$file"; then
    log_info "Image déjà définie dans $file"
    return
  fi

  if grep -q "$placeholder" "$file"; then
    log_info "Remplacement $placeholder -> $image dans $file"
    sed -i "s|$placeholder|$image|g" "$file"
  else
    log_info "Placeholder introuvable dans $file, aucune modification"
  fi
}

update_image "$DEV_FILE" "REGISTRY_PLACEHOLDER/keybuzz-admin:DEV_TAG" "$DEV_IMAGE"
update_image "$PROD_FILE" "REGISTRY_PLACEHOLDER/keybuzz-admin:PROD_TAG" "$PROD_IMAGE"

# Validation YAML
if ! command -v yq >/dev/null 2>&1; then
  log_info "yq absent, validation YAML sautée (non bloquant)"
else
  log_info "Validation YAML avec yq"
  yq eval '.' "$DEV_FILE" >/dev/null
  yq eval '.' "$PROD_FILE" >/dev/null
fi

cd /opt/keybuzz/keybuzz-infra

git add k8s/keybuzz-admin-dev/deployment.yaml k8s/keybuzz-admin/deployment.yaml
if git diff --cached --quiet; then
  log_info "Aucun changement à committer"
else
  log_info "Commit des mises à jour d'images"
  git commit -m "chore: update keybuzz-admin images to ghcr.io v1.0.0(-dev)"
  log_info "Commit effectué"
fi

log_info "Fin mise à jour images K8s"

