#!/bin/bash
# PH10-UI-DEPLOY-AUTO - Update K8s manifest DEV image to v1.0.1-dev
# KeyBuzz v3 - Mise à jour uniquement du manifest dev avec nouvelle image
# Ce script met à jour k8s/keybuzz-admin-dev/deployment.yaml avec v1.0.1-dev

set -euo pipefail

LOG_DIR="/opt/keybuzz/logs/ph10-ui"
LOG_FILE="$LOG_DIR/update-images-v101.log"
mkdir -p "$LOG_DIR"

log_info() { echo "[INFO] $1" | tee -a "$LOG_FILE"; }
log_error() { echo "[ERROR] $1" | tee -a "$LOG_FILE" >&2; }

DEPLOYMENT_FILE="/opt/keybuzz/keybuzz-infra/k8s/keybuzz-admin-dev/deployment.yaml"
OLD_IMAGE="ghcr.io/keybuzzio/keybuzz-admin:v1.0.0-dev"
NEW_IMAGE="ghcr.io/keybuzzio/keybuzz-admin:v1.0.1-dev"

log_info "Démarrage mise à jour image DEV vers v1.0.1-dev"

# Vérification du fichier
if [ ! -f "$DEPLOYMENT_FILE" ]; then
  log_error "Fichier deployment.yaml introuvable: $DEPLOYMENT_FILE"
  exit 1
fi

# Vérification que l'ancienne image est présente
if ! grep -q "$OLD_IMAGE" "$DEPLOYMENT_FILE"; then
  log_error "Image $OLD_IMAGE non trouvée dans $DEPLOYMENT_FILE"
  log_info "Vérification de l'image actuelle..."
  grep "image:" "$DEPLOYMENT_FILE" | tee -a "$LOG_FILE"
  exit 1
fi

# Remplacement de l'image
log_info "Remplacement $OLD_IMAGE -> $NEW_IMAGE dans $DEPLOYMENT_FILE"
sed -i "s|${OLD_IMAGE}|${NEW_IMAGE}|g" "$DEPLOYMENT_FILE"

# Vérification que le remplacement a fonctionné
if ! grep -q "$NEW_IMAGE" "$DEPLOYMENT_FILE"; then
  log_error "Échec du remplacement de l'image"
  exit 1
fi

log_info "Image mise à jour avec succès"

# Vérification YAML (si yq disponible)
if command -v yq >/dev/null 2>&1; then
  log_info "Validation YAML avec yq..."
  if yq eval '.' "$DEPLOYMENT_FILE" >/dev/null 2>&1; then
    log_info "YAML valide"
  else
    log_error "YAML invalide après modification"
    exit 1
  fi
else
  log_info "yq absent, validation YAML sautée (non bloquant)"
fi

# Git add et commit
log_info "Commit des mises à jour d'image"
cd /opt/keybuzz/keybuzz-infra

if git add "$DEPLOYMENT_FILE" >> "$LOG_FILE" 2>&1; then
  log_info "Fichier ajouté à l'index Git"
else
  log_error "Échec git add"
  exit 1
fi

if git commit -m "chore: bump keybuzz-admin dev image to v1.0.1-dev" >> "$LOG_FILE" 2>&1; then
  log_info "Commit effectué"
else
  log_error "Échec du commit (peut-être aucun changement?)"
  git status >> "$LOG_FILE" 2>&1
fi

log_info "Fin mise à jour image DEV"

