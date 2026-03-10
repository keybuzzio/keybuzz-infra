#!/usr/bin/env bash
# PH-S03.2I: Build + push seller-api v1.8.4-ph-s03.2 (tag immuable), preuve OpenAPI, output DIGEST
# À exécuter sur une machine avec Docker + accès push ghcr.io (ex: bastion ou CI).
# Sortie: TAG, DIGEST (sha256), COMMIT_SHA + fichier PH-S03.2I-BUILD-OUTPUT.txt pour deploy script
set -e

IMAGE_NAME="${IMAGE_NAME:-ghcr.io/keybuzzio/seller-api}"
VERSION_TAG="v1.8.4-ph-s03.2"
OUTPUT_FILE="${OUTPUT_FILE:-/tmp/PH-S03.2I-BUILD-OUTPUT.txt}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -n "$SELLER_API_DIR" ]; then
  BUILD_DIR="$SELLER_API_DIR"
else
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
COMMIT_SHA="$(git rev-parse HEAD 2>/dev/null || echo 'norev')"
SHORT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo 'norev')"
FULL_TAG="${IMAGE_NAME}:${VERSION_TAG}+${SHORT_SHA}"

echo "Build seller-api depuis: $BUILD_DIR"
echo "Tag: $FULL_TAG"

docker build -t "$FULL_TAG" .

# Preuve: OpenAPI doit contenir /ftp/test-connection AVANT déploiement
echo "Preuve OpenAPI dans l'image (routes FTP)..."
FTP_PATHS=$(docker run --rm "$FULL_TAG" python -c "
from src.main import app
paths = list(app.openapi().get('paths', {}).keys())
ftp_paths = [p for p in paths if 'ftp' in p]
print('\n'.join(ftp_paths) if ftp_paths else '')
" 2>/dev/null || true)

if ! echo "$FTP_PATHS" | grep -q "ftp/test-connection"; then
  echo "ERREUR: Route ftp/test-connection absente dans l'image. STOP (build context incorrect)."
  exit 1
fi
echo "OK: Routes FTP présentes (dont ftp/test-connection)"

# Push (docker login ghcr.io requis)
echo "Push $FULL_TAG..."
PUSH_OUTPUT=$(docker push "$FULL_TAG" 2>&1) || {
  echo "ERREUR: docker push a échoué. Vérifier: docker login ghcr.io"
  echo "$PUSH_OUTPUT"
  exit 1
}

# Récupérer le digest (push output ou inspect)
DIGEST_FULL=$(echo "$PUSH_OUTPUT" | grep -oE 'sha256:[a-f0-9]+' | tail -1)
if [ -z "$DIGEST_FULL" ]; then
  DIGEST_FULL=$(docker image inspect "$FULL_TAG" --format '{{index .RepoDigests 0}}' 2>/dev/null || true)
fi
if [ -z "$DIGEST_FULL" ]; then
  DIGEST_FULL=$(docker image inspect "$FULL_TAG" --format '{{.Id}}' 2>/dev/null || true)
fi
# Format pour deployment: ghcr.io/keybuzzio/seller-api@sha256:xxx
DIGEST_SHA256="${DIGEST_FULL#*@}"
[ -z "$DIGEST_SHA256" ] && DIGEST_SHA256="$DIGEST_FULL"
IMAGE_BY_DIGEST="${IMAGE_NAME}@${DIGEST_SHA256}"

echo ""
echo "=== PH-S03.2I Build+Push OK ==="
echo "TAG=$FULL_TAG"
echo "DIGEST=$DIGEST_SHA256"
echo "IMAGE_BY_DIGEST=$IMAGE_BY_DIGEST"
echo "COMMIT_SHA=$COMMIT_SHA"
echo ""

# Fichier pour deploy script
cat > "$OUTPUT_FILE" << EOF
TAG=$FULL_TAG
DIGEST=$DIGEST_SHA256
IMAGE_BY_DIGEST=$IMAGE_BY_DIGEST
COMMIT_SHA=$COMMIT_SHA
EOF
echo "Sortie écrite dans: $OUTPUT_FILE"
echo "Lancer le déploiement: source $OUTPUT_FILE; ./ph_s032i_deploy_verify.sh (depuis keybuzz-infra)"
