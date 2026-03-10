#!/usr/bin/env bash
###############################################################################
# PH-S03.5D: Pipeline autonome — build / push / update GitOps / preuves
# Exécuté par CE depuis install-v3 (aucune action Ludovic).
# Prérequis sur le bastion: Docker, docker login ghcr.io, git (push keybuzz-infra),
#   kubectl + argocd (optionnel, pour preuves runtime).
#
# Usage sur install-v3:
#   export KEYBUZZ_ROOT=/opt/keybuzz   # ou défaut si repos sous /opt/keybuzz
#   bash /opt/keybuzz/keybuzz-infra/scripts/ph-s035d-autonomous-build-deploy-proof.sh
#
# Sortie: tag/digest, mise à jour deployment-client.yaml, commit+push, preuves
#   (HTML catalog-sources, curl status, optionnel Argo/kubectl).
###############################################################################

set -euo pipefail

KEYBUZZ_ROOT="${KEYBUZZ_ROOT:-/opt/keybuzz}"
SELLER_CLIENT_DIR="${SELLER_CLIENT_DIR:-$KEYBUZZ_ROOT/keybuzz-seller/seller-client}"
INFRA_DIR="${INFRA_DIR:-$KEYBUZZ_ROOT/keybuzz-infra}"
DEPLOY_FILE="$INFRA_DIR/k8s/keybuzz-seller-dev/deployment-client.yaml"
IMAGE_NAME="ghcr.io/keybuzzio/seller-client"
VERSION_PREFIX="v1.0.1"
SELLER_DEV_URL="${SELLER_DEV_URL:-https://seller-dev.keybuzz.io}"
PROOF_DIR="${PROOF_DIR:-$KEYBUZZ_ROOT/logs/ph-s035d-$(date +%Y%m%d-%H%M%S)}"

echo "═══════════════════════════════════════════════════════════════"
echo "PH-S03.5D — Pipeline autonome seller-client (install-v3)"
echo "  KEYBUZZ_ROOT=$KEYBUZZ_ROOT"
echo "  SELLER_CLIENT_DIR=$SELLER_CLIENT_DIR"
echo "  INFRA_DIR=$INFRA_DIR"
echo "  PROOF_DIR=$PROOF_DIR"
echo "═══════════════════════════════════════════════════════════════"

mkdir -p "$PROOF_DIR"

# --- A) Environnement build ---
echo ""
echo "--- A) Vérification Docker + GHCR ---"
if ! command -v docker &>/dev/null; then
  echo "ERREUR: docker introuvable. Installer Docker sur install-v3."
  exit 1
fi
if ! docker info &>/dev/null; then
  echo "ERREUR: docker info échoue. Vérifier Docker daemon et droits."
  exit 1
fi
# Test push (manifest pull only) — pas de push réel ici, on fait le push plus bas
echo "Docker OK."

if [[ ! -d "$SELLER_CLIENT_DIR" ]] || [[ ! -f "$SELLER_CLIENT_DIR/Dockerfile" ]]; then
  echo "ERREUR: seller-client introuvable: $SELLER_CLIENT_DIR"
  exit 1
fi

KEYBUZZ_SELLER_ROOT="$(cd "$SELLER_CLIENT_DIR/../.." 2>/dev/null && pwd || dirname "$SELLER_CLIENT_DIR")"
BUILD_SHA="$(git -C "$KEYBUZZ_SELLER_ROOT" rev-parse HEAD 2>/dev/null || echo "unknown")"
SHORT_SHA="$(echo "$BUILD_SHA" | cut -c1-7)"
TAG="${VERSION_PREFIX}-${SHORT_SHA}"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

echo ""
echo "--- B) Build seller-client ---"
echo "  BUILD_SHA=$BUILD_SHA"
echo "  TAG=$TAG"
echo "  FULL_IMAGE=$FULL_IMAGE"

docker build \
  --build-arg BUILD_SHA="$BUILD_SHA" \
  -t "$FULL_IMAGE" \
  "$SELLER_CLIENT_DIR"

echo ""
echo "--- C) Push et récupération digest ---"
PUSH_OUT=$(docker push "$FULL_IMAGE" 2>&1) || { echo "$PUSH_OUT"; exit 1; }
echo "$PUSH_OUT"
DIGEST=""
if echo "$PUSH_OUT" | grep -q "digest:"; then
  DIGEST=$(echo "$PUSH_OUT" | grep -oE 'sha256:[a-f0-9]+' | tail -1)
fi
if [[ -z "$DIGEST" ]]; then
  DIGEST=$(docker image inspect "$FULL_IMAGE" --format '{{index .RepoDigests 0}}' 2>/dev/null | sed 's/.*@//' || true)
fi
if [[ -z "$DIGEST" ]]; then
  echo "WARN: digest non récupéré. Utiliser le tag immuable: $FULL_IMAGE"
  IMAGE_REF="$FULL_IMAGE"
else
  IMAGE_REF="${IMAGE_NAME}@${DIGEST}"
fi

echo ""
echo "  Tag immuable: $FULL_IMAGE"
echo "  Digest: ${DIGEST:-n/a}"
echo "  Image par digest: ${IMAGE_REF:-$FULL_IMAGE}"

# Écrire pour le rapport
echo "$FULL_IMAGE" > "$PROOF_DIR/build_tag.txt"
echo "${DIGEST:-}" > "$PROOF_DIR/build_digest.txt"
echo "$BUILD_SHA" > "$PROOF_DIR/build_sha.txt"

# --- D) Mise à jour GitOps ---
echo ""
echo "--- D) Mise à jour deployment-client.yaml ---"
if [[ ! -f "$DEPLOY_FILE" ]]; then
  echo "ERREUR: $DEPLOY_FILE introuvable."
  exit 1
fi

# Mise à jour par digest si disponible, sinon par tag immuable
if [[ -n "$DIGEST" ]]; then
  sed -i.bak "s|image: ghcr.io/keybuzzio/seller-client[@:][^[:space:]]*|image: $IMAGE_REF|" "$DEPLOY_FILE"
else
  sed -i.bak "s|image: ghcr.io/keybuzzio/seller-client[@:][^[:space:]]*|image: $FULL_IMAGE|" "$DEPLOY_FILE"
fi
echo "  Fichier mis à jour: $DEPLOY_FILE"
grep "image:" "$DEPLOY_FILE" | head -1

# Commit + push keybuzz-infra (GitOps)
echo ""
echo "--- E) Commit + push keybuzz-infra ---"
cd "$INFRA_DIR"
git add k8s/keybuzz-seller-dev/deployment-client.yaml
if git diff --cached --quiet; then
  echo "  Aucun changement (image déjà à jour)."
else
  git commit -m "PH-S03.5D: seller-client ${TAG} (digest: ${DIGEST:-tag})"
  if git push origin main 2>/dev/null || git push origin master 2>/dev/null; then
    echo "  Push OK. ArgoCD sync automatique (auto/selfHeal)."
  else
    echo "  WARN: git push échoué (droits? remote?). Mettre à jour le manifest manuellement ou vérifier accès."
  fi
fi

# --- F) Preuves runtime (read-only) ---
echo ""
echo "--- F) Preuves runtime (si kubectl/argocd disponibles) ---"
if command -v argocd &>/dev/null; then
  argocd app get keybuzz-seller-dev 2>/dev/null | tee "$PROOF_DIR/argocd_app.txt" || true
fi
if command -v kubectl &>/dev/null; then
  kubectl -n keybuzz-seller-dev get deploy seller-client seller-api -o wide 2>/dev/null | tee "$PROOF_DIR/kubectl_deploy.txt" || true
  kubectl -n keybuzz-seller-dev get pod -l app=seller-client -o jsonpath='{.items[0].status.containerStatuses[0].imageID}' 2>/dev/null | tee "$PROOF_DIR/seller_client_imageID.txt" || true
fi

# --- G) Preuves fonctionnelles (HTML + curl) ---
echo ""
echo "--- G) Preuves fonctionnelles (catalog-sources) ---"
HTTP_STATUS=$(curl -s -o "$PROOF_DIR/catalog-sources.html" -w "%{http_code}" "$SELLER_DEV_URL/catalog-sources" 2>/dev/null || echo "000")
echo "  GET $SELLER_DEV_URL/catalog-sources → HTTP $HTTP_STATUS"
echo "$HTTP_STATUS" > "$PROOF_DIR/catalog_sources_http_status.txt"

if grep -q "Unknown error" "$PROOF_DIR/catalog-sources.html" 2>/dev/null; then
  echo "  WARN: 'Unknown error' présent dans le HTML (bandeau possible)."
  echo "FAIL" > "$PROOF_DIR/unknown_error_check.txt"
else
  echo "  OK: pas de 'Unknown error' dans le HTML initial."
  echo "OK" > "$PROOF_DIR/unknown_error_check.txt"
fi
if grep -q "Mapping des colonnes" "$PROOF_DIR/catalog-sources.html" 2>/dev/null; then
  echo "  WARN: 'Mapping des colonnes' encore présent."
  echo "FAIL" > "$PROOF_DIR/wizard_mapping_check.txt"
else
  echo "  OK: pas de 'Mapping des colonnes' dans la page."
  echo "OK" > "$PROOF_DIR/wizard_mapping_check.txt"
fi
if grep -q "Finalisation" "$PROOF_DIR/catalog-sources.html" 2>/dev/null; then
  echo "  OK: 'Finalisation' trouvé (étape 5 wizard)."
fi
if grep -q "Colonnes (CSV)" "$PROOF_DIR/catalog-sources.html" 2>/dev/null; then
  echo "  OK: onglet 'Colonnes (CSV)' présent."
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "PH-S03.5D — Fin pipeline. Preuves dans: $PROOF_DIR"
echo "  Tag: $FULL_IMAGE"
echo "  Digest: ${DIGEST:-n/a}"
echo "═══════════════════════════════════════════════════════════════"
