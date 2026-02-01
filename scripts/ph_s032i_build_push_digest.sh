#!/usr/bin/env bash
# PH-S03.2I: Build + push seller-api par DIGEST, preuve OpenAPI dans l'image, mise à jour deployment
# Exécuter sur bastion install-v3 (ou machine avec docker + docker login ghcr.io)
# Usage:
#   SELLER_API_DIR=/path/to/keybuzz-seller/seller-api [INFRA_DIR=/path/to/keybuzz-infra] ./ph_s032i_build_push_digest.sh
set -e

IMAGE_NAME="${IMAGE_NAME:-ghcr.io/keybuzzio/seller-api}"
VERSION_TAG="v1.8.4-ph-s03.2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Répertoire seller-api
if [ -n "$SELLER_API_DIR" ]; then
  BUILD_DIR="$SELLER_API_DIR"
else
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
SHORT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo 'local')"
COMMIT_SHA="$(git rev-parse HEAD 2>/dev/null || echo 'local')"
# Tag sans '+' (Docker n'accepte pas + dans le tag)
FULL_TAG="${IMAGE_NAME}:${VERSION_TAG}-${SHORT_SHA}"

echo "=== PH-S03.2I Build seller-api ==="
echo "Build dir: $BUILD_DIR"
echo "Tag: $FULL_TAG"
echo "Commit: $COMMIT_SHA"

docker build -t "$FULL_TAG" .

# A) Preuve que l'image contient les routes AVANT déploiement
echo "=== Preuve OpenAPI (routes FTP) dans l'image ==="
FTP_PATHS=$(docker run --rm "$FULL_TAG" python -c "
from src.main import app
paths = list(app.openapi().get('paths', {}).keys())
ftp_paths = [p for p in paths if 'ftp' in p]
print('\n'.join(ftp_paths) if ftp_paths else '')
" 2>/dev/null || true)

if [ -z "$FTP_PATHS" ]; then
  echo "ERREUR: Aucune route FTP dans l'image. STOP (build context incorrect)."
  exit 1
fi
if ! echo "$FTP_PATHS" | grep -q "ftp/test-connection"; then
  echo "ERREUR: Route ftp/test-connection absente. STOP."
  exit 1
fi
echo "OK: Routes FTP présentes:"
echo "$FTP_PATHS"

# Push et capture digest
echo "=== Push $FULL_TAG ==="
PUSH_OUT=$(docker push "$FULL_TAG" 2>&1) || { echo "$PUSH_OUT"; exit 1; }
echo "$PUSH_OUT"

# Digest: depuis la sortie push (digest: sha256:xxx) ou inspect
DIGEST=""
if echo "$PUSH_OUT" | grep -q "digest:"; then
  DIGEST=$(echo "$PUSH_OUT" | grep -oE 'sha256:[a-f0-9]+' | tail -1)
fi
if [ -z "$DIGEST" ]; then
  DIGEST=$(docker image inspect "$FULL_TAG" --format '{{index .RepoDigests 0}}' 2>/dev/null | sed 's/.*@//')
fi
if [ -z "$DIGEST" ]; then
  echo "ERREUR: Impossible d'obtenir le digest. Vérifiez docker push."
  exit 1
fi

IMAGE_BY_DIGEST="${IMAGE_NAME}@${DIGEST}"
echo ""
echo "=== PH-S03.2I Build OK ==="
echo "Tag:    $FULL_TAG"
echo "Digest: $DIGEST"
echo "Image:  $IMAGE_BY_DIGEST"
echo "Commit: $COMMIT_SHA"

# Mise à jour deployment par digest (si INFRA_DIR fourni)
DEPLOY_FILE=""
if [ -n "$INFRA_DIR" ]; then
  DEPLOY_FILE="$INFRA_DIR/k8s/keybuzz-seller-dev/deployment-api.yaml"
elif [ -d "$SCRIPT_DIR/../k8s/keybuzz-seller-dev" ]; then
  DEPLOY_FILE="$SCRIPT_DIR/../k8s/keybuzz-seller-dev/deployment-api.yaml"
fi

if [ -n "$DEPLOY_FILE" ] && [ -f "$DEPLOY_FILE" ]; then
  echo ""
  echo "=== Mise à jour deployment par digest ==="
  if sed -i.bak "s|image: ghcr.io/keybuzzio/seller-api[@:][^[:space:]]*|image: $IMAGE_BY_DIGEST|" "$DEPLOY_FILE"; then
    echo "Fichier mis à jour: $DEPLOY_FILE"
    echo "Rollback: mv ${DEPLOY_FILE}.bak $DEPLOY_FILE"
  else
    echo "Échec sed. Mettez à jour manuellement: image: $IMAGE_BY_DIGEST"
  fi
else
  echo ""
  echo "Mettez à jour keybuzz-infra/k8s/keybuzz-seller-dev/deployment-api.yaml:"
  echo "  image: $IMAGE_BY_DIGEST"
fi

echo ""
echo "Prochaines étapes:"
echo "  1) Commit + push keybuzz-infra (deployment-api.yaml)"
echo "  2) ArgoCD sync keybuzz-seller-dev"
echo "  3) Vérifier: curl -s https://seller-api-dev.keybuzz.io/openapi.json | grep -E '/ftp/test-connection'"
echo "  4) Vérifier: curl -s -o /dev/null -w '%{http_code}' -X POST https://seller-dev.keybuzz.io/api/seller/api/catalog-sources/00000000-0000-0000-0000-000000000001/ftp/test-connection -H 'Content-Type: application/json' -d '{}'  -> 400/401/422 (pas 404)"
