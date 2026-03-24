#!/bin/bash
# ============================================================
# DOCKER BUILD GUARD — PH-SOURCE-OF-TRUTH-FIX-02
# 
# Replaces direct `docker build` usage on the bastion.
# If anyone tries to use docker build directly on a KeyBuzz
# repo, they MUST go through build-from-git.sh instead.
# ============================================================

echo ""
echo "=================================================================="
echo "  INTERDIT — docker build direct est BLOQUE"
echo "=================================================================="
echo ""
echo "  Raison : les builds directs depuis le bastion causent"
echo "  des contaminations (fichiers non commits, code dirty)."
echo ""
echo "  Utilisez UNIQUEMENT :"
echo ""
echo "    build-from-git.sh <dev|prod> <tag> [branch]"
echo ""
echo "  Exemple :"
echo "    cd /opt/keybuzz/keybuzz-infra/scripts"
echo "    ./build-from-git.sh dev v3.5.83-feature-name-dev fix/signup-redirect-v2"
echo ""
echo "  Documentation : PH-TD-08-SAFE-DEPLOY-PIPELINE.md"
echo "=================================================================="
echo ""
exit 1
