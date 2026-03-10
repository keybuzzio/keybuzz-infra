#!/usr/bin/env bash
###############################################################################
# PH-S03.5C: Build + push seller-client v1.0.1 (Catalog Sources + Wizard sans mapping)
# GitOps only: après push, mettre à jour keybuzz-infra deployment-client.yaml
#   image: ghcr.io/keybuzzio/seller-client:v1.0.1
# puis commit+push keybuzz-infra → ArgoCD sync.
#
# Usage (depuis bastion ou machine avec docker + accès ghcr.io):
#   export BUILD_SHA=$(git -C /path/to/keybuzz-seller rev-parse HEAD)
#   bash keybuzz-infra/scripts/ph-s035c-build-seller-client.sh
#
# Ou depuis la racine du repo keybuzz-seller:
#   cd seller-client && docker build --build-arg BUILD_SHA=$(git rev-parse HEAD) -t ghcr.io/keybuzzio/seller-client:v1.0.1 . && docker push ghcr.io/keybuzzio/seller-client:v1.0.1
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
SELLER_CLIENT_DIR="${SELLER_CLIENT_DIR:-$REPO_ROOT/keybuzz-seller/seller-client}"
VERSION="${VERSION:-v1.0.1}"
IMAGE="${IMAGE:-ghcr.io/keybuzzio/seller-client:$VERSION}"

if [[ ! -d "$SELLER_CLIENT_DIR" ]]; then
  echo "ERROR: seller-client dir not found: $SELLER_CLIENT_DIR"
  echo "Set SELLER_CLIENT_DIR or run from repo root containing keybuzz-seller/seller-client"
  exit 1
fi

# BUILD_SHA = commit du repo keybuzz-seller (pour preuve version dans le footer)
KEYBUZZ_SELLER_ROOT="$(cd "$SELLER_CLIENT_DIR/../.." 2>/dev/null && pwd || dirname "$SELLER_CLIENT_DIR")"
BUILD_SHA="${BUILD_SHA:-$(git -C "$KEYBUZZ_SELLER_ROOT" rev-parse HEAD 2>/dev/null || echo "unknown")}"

echo "[PH-S03.5C] Building seller-client $VERSION with BUILD_SHA=$BUILD_SHA"
echo "  SELLER_CLIENT_DIR=$SELLER_CLIENT_DIR"
echo "  IMAGE=$IMAGE"

docker build \
  --build-arg BUILD_SHA="$BUILD_SHA" \
  -t "$IMAGE" \
  "$SELLER_CLIENT_DIR"

echo "[PH-S03.5C] Pushing $IMAGE ..."
docker push "$IMAGE"

echo "[PH-S03.5C] Done. Next: ensure keybuzz-infra k8s/keybuzz-seller-dev/deployment-client.yaml"
echo "  has image: $IMAGE"
echo "  then commit+push keybuzz-infra → ArgoCD will sync."
