#!/usr/bin/env bash
###############################################################################
# PH-S03.5C: Preuves runtime seller-dev (ArgoCD + kubectl + curl)
# Exécuter sur une machine ayant accès au cluster (kubectl, argocd) et au réseau.
#
# Usage:
#   bash keybuzz-infra/scripts/ph-s035c-proof.sh
#   bash keybuzz-infra/scripts/ph-s035c-proof.sh 2>&1 | tee ph-s035c-proof-$(date +%Y%m%d-%H%M%S).log
###############################################################################

set -euo pipefail

SELLER_DEV_URL="${SELLER_DEV_URL:-https://seller-dev.keybuzz.io}"
NS="${NS:-keybuzz-seller-dev}"

echo "═══════════════════════════════════════════════════════════════"
echo "PH-S03.5C — Preuves runtime seller-dev"
echo "  SELLER_DEV_URL=$SELLER_DEV_URL"
echo "  NS=$NS"
echo "  $(date -Iseconds 2>/dev/null || date)"
echo "═══════════════════════════════════════════════════════════════"

echo ""
echo "--- 1) ArgoCD app keybuzz-seller-dev ---"
if command -v argocd &>/dev/null; then
  argocd app get keybuzz-seller-dev --show-operation 2>/dev/null || true
  argocd app get keybuzz-seller-dev -o json 2>/dev/null | jq -r '"Revision: \(.status.sync.revision // "n/a")", "Sync: \(.status.sync.status // "n/a")", "Health: \(.status.health.status // "n/a")"' 2>/dev/null || true
else
  echo "argocd CLI non installé — vérifier manuellement dans l'UI ArgoCD: révision, Sync status, Health."
fi

echo ""
echo "--- 2) Runtime images (kubectl) ---"
for name in seller-client seller-api; do
  echo "Deployment $name:"
  kubectl -n "$NS" get deploy "$name" -o jsonpath='  image: {.spec.template.spec.containers[0].image}' 2>/dev/null && echo "" || echo "  (get deploy failed)"
  echo "Pod $name imageID:"
  kubectl -n "$NS" get pod -l "app=$name" -o jsonpath='  {.items[0].status.containerStatuses[0].imageID}' 2>/dev/null && echo "" || echo "  (no pod or field)"
done

echo ""
echo "--- 3) Curl page Catalog Sources (HTML + status) ---"
HTTP_STATUS=$(curl -s -o /tmp/ph-s035c-catalog-sources.html -w "%{http_code}" "$SELLER_DEV_URL/catalog-sources" 2>/dev/null || echo "000")
echo "  GET $SELLER_DEV_URL/catalog-sources → HTTP $HTTP_STATUS"
if [[ -f /tmp/ph-s035c-catalog-sources.html ]]; then
  if grep -q "Unknown error" /tmp/ph-s035c-catalog-sources.html 2>/dev/null; then
    echo "  WARN: page content contains 'Unknown error' (bandeau possible)"
  else
    echo "  OK: no 'Unknown error' in initial HTML (SSR)."
  fi
  if grep -q "build " /tmp/ph-s035c-catalog-sources.html 2>/dev/null; then
    echo "  Build SHA in page: $(grep -o 'build [a-f0-9]\{7\}' /tmp/ph-s035c-catalog-sources.html | head -1)"
  fi
fi

echo ""
echo "--- 4) Preuve wizard (steps) — vérifier dans le HTML que step 5 = Finalisation ---"
if [[ -f /tmp/ph-s035c-catalog-sources.html ]]; then
  if grep -q "Finalisation" /tmp/ph-s035c-catalog-sources.html 2>/dev/null; then
    echo "  OK: 'Finalisation' trouvé (étape 5 wizard)."
  fi
  if grep -q "Mapping des colonnes" /tmp/ph-s035c-catalog-sources.html 2>/dev/null; then
    echo "  WARN: 'Mapping des colonnes' encore présent dans la page."
  else
    echo "  OK: no 'Mapping des colonnes' in page."
  fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "Fin preuves. Screenshots à prendre manuellement:"
echo "  - Page Catalog Sources au chargement (aucun bandeau 'Unknown error')"
echo "  - Wizard FTP: liste des étapes sans 'Mapping des colonnes'"
echo "  - Fiche source: onglet 'Colonnes (CSV)'"
echo "═══════════════════════════════════════════════════════════════"
