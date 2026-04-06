#!/bin/bash
set -euo pipefail

# ============================================================
# PH142-M — Assert Git Committed Before Build
#
# OBLIGATOIRE avant tout build Docker.
# Verifie que TOUTES les modifications sont commitees dans Git.
# Bloque le build si des modifications non commitees existent.
#
# Usage:
#   ./assert-git-committed.sh /opt/keybuzz/keybuzz-client
#   ./assert-git-committed.sh /opt/keybuzz/keybuzz-api
#   ./assert-git-committed.sh   (verifie client + api)
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPOS=("$@")
if [ ${#REPOS[@]} -eq 0 ]; then
  REPOS=("/opt/keybuzz/keybuzz-client" "/opt/keybuzz/keybuzz-api")
fi

BLOCKED=0

for REPO in "${REPOS[@]}"; do
  REPO_NAME=$(basename "$REPO")
  
  if [ ! -d "$REPO/.git" ]; then
    echo -e "${RED}ERREUR: $REPO n'est pas un repo Git${NC}"
    BLOCKED=1
    continue
  fi

  cd "$REPO"

  MODIFIED=$(git status --porcelain -- ':!*.bak*' ':!dist/' ':!node_modules/' ':!.next/' 2>/dev/null | { grep '^ M\| M ' || true; } | wc -l)
  UNTRACKED=$(git status --porcelain -- ':!*.bak*' ':!dist/' ':!node_modules/' ':!.next/' 2>/dev/null | { grep '^??' || true; } | wc -l)
  STAGED=$(git status --porcelain -- ':!*.bak*' ':!dist/' ':!node_modules/' ':!.next/' 2>/dev/null | { grep '^[MADRC]' || true; } | wc -l)

  if [ "$MODIFIED" -gt 0 ] || [ "$UNTRACKED" -gt 0 ]; then
    echo ""
    echo -e "${RED}=================================================================="
    echo "  BLOQUE — $REPO_NAME a des modifications non commitees"
    echo "==================================================================${NC}"
    echo ""
    
    if [ "$MODIFIED" -gt 0 ]; then
      echo -e "${YELLOW}  Fichiers modifies ($MODIFIED):${NC}"
      git status --porcelain -- ':!*.bak*' ':!dist/' ':!node_modules/' ':!.next/' | grep '^ M\| M ' | head -20
      echo ""
    fi
    
    if [ "$UNTRACKED" -gt 0 ]; then
      echo -e "${YELLOW}  Fichiers non suivis ($UNTRACKED):${NC}"
      git status --porcelain -- ':!*.bak*' ':!dist/' ':!node_modules/' ':!.next/' | grep '^??' | head -20
      echo ""
    fi

    echo "  Pour corriger :"
    echo "    cd $REPO"
    echo "    git add -A"
    echo "    git commit -m \"PH-XXX: description des changements\""
    echo "    git push origin $(git branch --show-current)"
    echo ""
    BLOCKED=1
  else
    SHA=$(git rev-parse --short HEAD)
    BRANCH=$(git branch --show-current)
    echo -e "${GREEN}  OK  $REPO_NAME — propre (${BRANCH}@${SHA})${NC}"
  fi
done

echo ""
if [ "$BLOCKED" -ne 0 ]; then
  echo -e "${RED}=================================================================="
  echo "  BUILD INTERDIT"
  echo ""
  echo "  Git est la source de verite."
  echo "  Toute modification DOIT etre commitee AVANT le build."
  echo "  Utiliser build-from-git.sh apres le commit."
  echo "==================================================================${NC}"
  exit 1
fi

echo -e "${GREEN}  TOUS LES REPOS PROPRES — BUILD AUTORISE${NC}"
exit 0
