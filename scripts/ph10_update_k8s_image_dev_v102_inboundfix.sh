#!/bin/bash
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/ph10-ui/update-images-v102-inboundfix.log"
mkdir -p "$(dirname "$LOG_FILE")"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== PH10-UI-DEPLOY-FIX-AMAZON-INBOUND - Update K8s Manifest ==="
echo "Date: $(date)"
echo ""

# Trouver le fichier deployment
DEPLOY_FILE=$(find . -name "*deployment*.yaml" -path "*/keybuzz-admin-dev/*" | head -1)
if [ -z "$DEPLOY_FILE" ]; then
  DEPLOY_FILE=$(find . -name "*admin-dev*.yaml" | head -1)
fi

if [ -z "$DEPLOY_FILE" ]; then
  echo "❌ Fichier deployment admin-dev non trouvé"
  exit 1
fi

echo "Fichier deployment: $DEPLOY_FILE"

# Nouvelle image
TAG="v1.0.2-dev"
NEW_IMAGE="ghcr.io/keybuzzio/keybuzz-admin:${TAG}"

echo "Nouvelle image: $NEW_IMAGE"
echo ""

# Vérifier l'image actuelle
CURRENT_IMAGE=$(grep -E "ghcr.io/keybuzzio/keybuzz-admin:v[0-9.]+-dev" "$DEPLOY_FILE" | head -1 | sed 's/.*image: *//' | sed 's/ *$//')
echo "Image actuelle: $CURRENT_IMAGE"

# Mettre à jour
sed -i "s#ghcr.io/keybuzzio/keybuzz-admin:v[0-9.]\+-dev#${NEW_IMAGE}#g" "$DEPLOY_FILE"

# Vérifier
UPDATED_IMAGE=$(grep -E "ghcr.io/keybuzzio/keybuzz-admin:v[0-9.]+-dev" "$DEPLOY_FILE" | head -1 | sed 's/.*image: *//' | sed 's/ *$//')
echo "Image après update: $UPDATED_IMAGE"

if [ "$UPDATED_IMAGE" != "$NEW_IMAGE" ]; then
  echo "❌ Erreur: l'image n'a pas été mise à jour correctement"
  exit 1
fi

# Commit + push
git add "$DEPLOY_FILE"
git commit -m "chore(admin-dev): bump to v1.0.2-dev (PH10-UI-FIX-AMAZON-INBOUND)" || echo "Rien à committer"
git push origin main

INFRA_SHA=$(git rev-parse HEAD)
echo ""
echo "=== RÉSUMÉ ==="
echo "INFRA_SHA: $INFRA_SHA"
echo "IMAGE_TAG: $TAG"
echo "✅ Manifest mis à jour"

