#!/usr/bin/env bash
# PH-S03.2G: Build + push seller-api avec routes PH-S03.2 (tag immuable)
# Usage: SELLER_API_DIR=/path/to/keybuzz-seller/seller-api ./ph_s032g_build_seller_api.sh
# Prérequis: docker, git, accès push ghcr.io/keybuzzio/seller-api
set -e

IMAGE_NAME="${IMAGE_NAME:-ghcr.io/keybuzzio/seller-api}"
VERSION_TAG="v1.8.3-ph-s03.2"

# Répertoire seller-api (keybuzz-seller/seller-api)
if [ -n "$SELLER_API_DIR" ]; then
  BUILD_DIR="$SELLER_API_DIR"
else
  # Depuis keybuzz-infra/scripts, keybuzz-seller peut être ../../keybuzz-seller
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  for candidate in "$SCRIPT_DIR/../../keybuzz-seller/seller-api" "$SCRIPT_DIR/../keybuzz-seller/seller-api" "./seller-api"; do
    if [ -f "$candidate/Dockerfile" ] && [ -f "$candidate/src/main.py" ]; then
      BUILD_DIR="$candidate"
      break
    fi
  done
  if [ -z "$BUILD_DIR" ]; then
    echo "ERREUR: keybuzz-seller/seller-api introuvable. Exportez SELLER_API_DIR."
    exit 1
  fi
fi

cd "$BUILD_DIR"
SHORT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo 'norev')"
FULL_TAG="${IMAGE_NAME}:${VERSION_TAG}+${SHORT_SHA}"

echo "Build seller-api depuis: $BUILD_DIR"
echo "Tag: $FULL_TAG"

docker build -t "$FULL_TAG" .

# Preuve locale: OpenAPI doit contenir les routes FTP (sans démarrer le serveur)
echo "Vérification OpenAPI (routes FTP)..."
FTP_PATHS=$(docker run --rm "$FULL_TAG" python -c "
from src.main import app
paths = list(app.openapi().get('paths', {}).keys())
ftp_paths = [p for p in paths if 'ftp' in p]
print('\n'.join(ftp_paths) if ftp_paths else '')
" 2>/dev/null || true)

if [ -z "$FTP_PATHS" ]; then
  echo "ERREUR: Aucune route FTP dans l'image buildée. STOP (Dockerfile/build context incorrect)."
  exit 1
fi

if ! echo "$FTP_PATHS" | grep -q "ftp/test-connection"; then
  echo "ERREUR: Route ftp/test-connection absente. STOP."
  exit 1
fi
if ! echo "$FTP_PATHS" | grep -q "ftp/browse"; then
  echo "ERREUR: Route ftp/browse absente. STOP."
  exit 1
fi
echo "OK: Routes FTP présentes dans l'image:"
echo "$FTP_PATHS"

# Push (nécessite docker login ghcr.io)
echo "Push $FULL_TAG..."
docker push "$FULL_TAG"

# Digest pour déploiement par digest (optionnel)
DIGEST=$(docker image inspect "$FULL_TAG" --format '{{index .RepoDigests 0}}' 2>/dev/null || docker inspect "$FULL_TAG" --format '{{.Id}}')
echo ""
echo "=== PH-S03.2G Build OK ==="
echo "Tag:    $FULL_TAG"
echo "Digest: $DIGEST"
echo "Commit: $(git rev-parse HEAD 2>/dev/null || echo 'n/a')"
echo ""
echo "Mettre à jour keybuzz-infra/k8s/keybuzz-seller-dev/deployment-api.yaml:"
echo "  image: $FULL_TAG"
echo "  # ou image: ${IMAGE_NAME}@${DIGEST#*@}"
echo "Puis commit/push et sync ArgoCD (DEV only)."
