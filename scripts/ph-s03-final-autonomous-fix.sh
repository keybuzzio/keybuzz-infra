#!/usr/bin/env bash
###############################################################################
# PH-S03.FINAL: Correction définitive seller-client (Unknown error + Wizard 5 étapes)
# À exécuter sur le bastion install-v3
#
# Usage:
#   bash /opt/keybuzz/keybuzz-infra/scripts/ph-s03-final-autonomous-fix.sh
#
# Prérequis:
#   - Docker + docker login ghcr.io
#   - Git configuré pour push keybuzz-infra
#   - kubectl/argocd (optionnel, pour preuves)
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYBUZZ_ROOT="${KEYBUZZ_ROOT:-/opt/keybuzz}"
INFRA_DIR="${INFRA_DIR:-$KEYBUZZ_ROOT/keybuzz-infra}"
SELLER_DIR="${SELLER_DIR:-$KEYBUZZ_ROOT/keybuzz-seller}"
PATCH_DIR="$INFRA_DIR/patches"
IMAGE_NAME="ghcr.io/keybuzzio/seller-client"
VERSION="v1.0.2-ph-s03-final"
SELLER_DEV_URL="https://seller-dev.keybuzz.io"
LOG_DIR="${LOG_DIR:-$KEYBUZZ_ROOT/logs/ph-s03-final-$(date +%Y%m%d-%H%M%S)}"

mkdir -p "$LOG_DIR"

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_DIR/deploy.log"
}

error() {
  echo "[ERROR] $*" | tee -a "$LOG_DIR/deploy.log" >&2
  exit 1
}

log "═══════════════════════════════════════════════════════════════"
log "PH-S03.FINAL: Correction définitive seller-client"
log "  KEYBUZZ_ROOT=$KEYBUZZ_ROOT"
log "  VERSION=$VERSION"
log "  LOG_DIR=$LOG_DIR"
log "═══════════════════════════════════════════════════════════════"

###############################################################################
# PHASE 1: Appliquer les patches
###############################################################################
log ""
log "=== PHASE 1: Application des patches ==="

SELLER_CLIENT_SRC="$SELLER_DIR/seller-client/src/lib"
SELLER_CLIENT_PAGES="$SELLER_DIR/seller-client/app/(dashboard)/catalog-sources"

if [[ ! -d "$SELLER_DIR/seller-client" ]]; then
  error "seller-client introuvable: $SELLER_DIR/seller-client"
fi

# Backup
log "Création backups..."
mkdir -p "$LOG_DIR/backup"
cp "$SELLER_CLIENT_SRC/api.ts" "$LOG_DIR/backup/api.ts.bak" 2>/dev/null || true
cp "$SELLER_CLIENT_PAGES/page.tsx" "$LOG_DIR/backup/page.tsx.bak" 2>/dev/null || true

# Appliquer les patches
if [[ -f "$PATCH_DIR/ph-s03-final-seller-client-api.ts" ]]; then
  log "Application patch api.ts..."
  cp "$PATCH_DIR/ph-s03-final-seller-client-api.ts" "$SELLER_CLIENT_SRC/api.ts"
else
  log "WARN: Patch api.ts non trouvé, vérification inline..."
fi

if [[ -f "$PATCH_DIR/ph-s03-final-catalog-sources-page.tsx" ]]; then
  log "Application patch page.tsx..."
  cp "$PATCH_DIR/ph-s03-final-catalog-sources-page.tsx" "$SELLER_CLIENT_PAGES/page.tsx"
else
  log "WARN: Patch page.tsx non trouvé, vérification inline..."
fi

# Vérification du code
log "Vérification du code appliqué..."
if grep -q "totalSteps = needsFtp ? 5 : 3" "$SELLER_CLIENT_PAGES/page.tsx"; then
  log "  OK: totalSteps = 5 pour FTP"
else
  error "  FAIL: totalSteps incorrect dans page.tsx"
fi

if grep -q "getDisplayErrorMessage" "$SELLER_CLIENT_SRC/api.ts"; then
  log "  OK: getDisplayErrorMessage présent dans api.ts"
else
  error "  FAIL: getDisplayErrorMessage manquant dans api.ts"
fi

if grep -q "Mapping des colonnes" "$SELLER_CLIENT_PAGES/page.tsx"; then
  log "  WARN: 'Mapping des colonnes' encore présent dans le code"
else
  log "  OK: Pas de 'Mapping des colonnes' dans le wizard"
fi

###############################################################################
# PHASE 2: Build Docker
###############################################################################
log ""
log "=== PHASE 2: Build Docker ==="

cd "$SELLER_DIR/seller-client"
BUILD_SHA="$(git rev-parse HEAD 2>/dev/null || echo 'local')"
SHORT_SHA="${BUILD_SHA:0:7}"
FULL_TAG="${IMAGE_NAME}:${VERSION}-${SHORT_SHA}"

log "  BUILD_SHA=$BUILD_SHA"
log "  TAG=$FULL_TAG"

# Mettre à jour Dockerfile pour BUILD_SHA si nécessaire
if ! grep -q "ARG BUILD_SHA" Dockerfile; then
  log "  Ajout ARG BUILD_SHA au Dockerfile..."
  sed -i '/FROM base AS builder/a ARG BUILD_SHA\nENV NEXT_PUBLIC_BUILD_SHA=\${BUILD_SHA}' Dockerfile
fi

docker build --build-arg BUILD_SHA="$BUILD_SHA" -t "$FULL_TAG" . 2>&1 | tee -a "$LOG_DIR/docker-build.log"

###############################################################################
# PHASE 3: Push et récupération digest
###############################################################################
log ""
log "=== PHASE 3: Push Docker ==="

docker push "$FULL_TAG" 2>&1 | tee -a "$LOG_DIR/docker-push.log"
DIGEST=$(docker image inspect "$FULL_TAG" --format '{{index .RepoDigests 0}}' 2>/dev/null | sed 's/.*@//' || true)

if [[ -n "$DIGEST" ]]; then
  IMAGE_REF="${IMAGE_NAME}@${DIGEST}"
  log "  Tag: $FULL_TAG"
  log "  Digest: $DIGEST"
else
  IMAGE_REF="$FULL_TAG"
  log "  Tag: $FULL_TAG (digest non disponible)"
fi

echo "$FULL_TAG" > "$LOG_DIR/build_tag.txt"
echo "$DIGEST" > "$LOG_DIR/build_digest.txt"
echo "$BUILD_SHA" > "$LOG_DIR/build_sha.txt"

###############################################################################
# PHASE 4: Mise à jour GitOps
###############################################################################
log ""
log "=== PHASE 4: Mise à jour GitOps ==="

DEPLOY_FILE="$INFRA_DIR/k8s/keybuzz-seller-dev/deployment-client.yaml"

if [[ ! -f "$DEPLOY_FILE" ]]; then
  error "Fichier deployment introuvable: $DEPLOY_FILE"
fi

# Mise à jour image
log "  Mise à jour deployment-client.yaml..."
sed -i.bak "s|image: ghcr.io/keybuzzio/seller-client[@:][^[:space:]]*|image: $IMAGE_REF|" "$DEPLOY_FILE"
grep "image:" "$DEPLOY_FILE" | head -1 | tee -a "$LOG_DIR/deploy.log"

# Commit et push
log "  Commit + push keybuzz-infra..."
cd "$INFRA_DIR"
git add k8s/keybuzz-seller-dev/deployment-client.yaml patches/
git diff --cached --quiet || git commit -m "PH-S03.FINAL: seller-client $VERSION (digest: ${DIGEST:-tag}) - fix Unknown error + wizard 5 steps"
git push origin main 2>&1 | tee -a "$LOG_DIR/git-push.log" || log "WARN: git push failed (vérifier credentials)"

###############################################################################
# PHASE 5: Attendre ArgoCD sync
###############################################################################
log ""
log "=== PHASE 5: Attente ArgoCD sync ==="

if command -v argocd &>/dev/null; then
  log "  Déclenchement sync ArgoCD..."
  argocd app sync keybuzz-seller-dev --force 2>&1 | tee -a "$LOG_DIR/argocd-sync.log" || true
  
  # Attendre que le déploiement soit prêt
  for i in {1..30}; do
    STATUS=$(argocd app get keybuzz-seller-dev -o json 2>/dev/null | jq -r '.status.sync.status // "Unknown"' || echo "Unknown")
    HEALTH=$(argocd app get keybuzz-seller-dev -o json 2>/dev/null | jq -r '.status.health.status // "Unknown"' || echo "Unknown")
    log "  [$i/30] Sync: $STATUS, Health: $HEALTH"
    if [[ "$STATUS" == "Synced" && "$HEALTH" == "Healthy" ]]; then
      log "  ArgoCD: Synced + Healthy"
      break
    fi
    sleep 10
  done
else
  log "  argocd CLI non disponible, vérifier manuellement"
fi

###############################################################################
# PHASE 6: Preuves runtime
###############################################################################
log ""
log "=== PHASE 6: Preuves runtime ==="

if command -v kubectl &>/dev/null; then
  log "  Pods seller-client:"
  kubectl -n keybuzz-seller-dev get pod -l app=seller-client -o wide 2>&1 | tee -a "$LOG_DIR/kubectl-pods.log"
  
  log "  Image déployée:"
  kubectl -n keybuzz-seller-dev get deploy seller-client -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null | tee -a "$LOG_DIR/kubectl-image.log"
  echo "" | tee -a "$LOG_DIR/kubectl-image.log"
  
  log "  ImageID du pod:"
  kubectl -n keybuzz-seller-dev get pod -l app=seller-client -o jsonpath='{.items[0].status.containerStatuses[0].imageID}' 2>/dev/null | tee "$LOG_DIR/kubectl-imageID.log"
  echo ""
fi

###############################################################################
# PHASE 7: Preuves fonctionnelles (curl)
###############################################################################
log ""
log "=== PHASE 7: Preuves fonctionnelles ==="

# Attendre que le nouveau pod soit prêt
sleep 5

HTTP_STATUS=$(curl -s -o "$LOG_DIR/catalog-sources.html" -w "%{http_code}" "$SELLER_DEV_URL/catalog-sources" 2>/dev/null || echo "000")
log "  GET $SELLER_DEV_URL/catalog-sources -> HTTP $HTTP_STATUS"
echo "$HTTP_STATUS" > "$LOG_DIR/http_status.txt"

if [[ -f "$LOG_DIR/catalog-sources.html" ]]; then
  if grep -q "Unknown error" "$LOG_DIR/catalog-sources.html" 2>/dev/null; then
    log "  FAIL: 'Unknown error' présent dans le HTML"
    echo "FAIL" > "$LOG_DIR/unknown_error_check.txt"
  else
    log "  OK: Pas de 'Unknown error' dans le HTML"
    echo "OK" > "$LOG_DIR/unknown_error_check.txt"
  fi
  
  if grep -q "Mapping des colonnes" "$LOG_DIR/catalog-sources.html" 2>/dev/null; then
    log "  WARN: 'Mapping des colonnes' présent dans le HTML"
    echo "WARN" > "$LOG_DIR/mapping_check.txt"
  else
    log "  OK: Pas de 'Mapping des colonnes' dans le HTML"
    echo "OK" > "$LOG_DIR/mapping_check.txt"
  fi
fi

###############################################################################
# RÉSUMÉ
###############################################################################
log ""
log "═══════════════════════════════════════════════════════════════"
log "PH-S03.FINAL: TERMINÉ"
log "  Tag: $FULL_TAG"
log "  Digest: ${DIGEST:-n/a}"
log "  Build SHA: $BUILD_SHA"
log "  Preuves: $LOG_DIR"
log ""
log "VÉRIFICATION MANUELLE REQUISE:"
log "  1. Ouvrir $SELLER_DEV_URL/catalog-sources"
log "  2. Vérifier: pas de bandeau 'Unknown error'"
log "  3. Clic 'Ajouter une source' -> FTP CSV"
log "  4. Vérifier: 'Étape X sur 5' (pas 6)"
log "  5. Vérifier: pas d'étape 'Mapping des colonnes'"
log "═══════════════════════════════════════════════════════════════"
