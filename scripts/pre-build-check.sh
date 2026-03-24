#!/bin/bash
set -euo pipefail

# ============================================================
# PRE-BUILD CHECK — PH-SOURCE-OF-TRUTH-FIX-02
# Verifies all repos are clean before any build is allowed
# ============================================================

echo "=== PRE-BUILD CHECK ==="
FAILED=0

for REPO in /opt/keybuzz/keybuzz-client /opt/keybuzz/keybuzz-api /opt/keybuzz/keybuzz-infra; do
  REPO_NAME=$(basename "$REPO")
  cd "$REPO"
  
  DIRTY=$(git status --porcelain -- ':!dist/' ':!node_modules/' ':!.next/' 2>/dev/null | head -5)
  if [ -n "$DIRTY" ]; then
    echo "FAIL: $REPO_NAME has uncommitted changes:"
    echo "$DIRTY"
    FAILED=1
  else
    echo "PASS: $REPO_NAME is clean"
  fi
  
  LOCAL=$(git rev-parse HEAD)
  REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "no-upstream")
  if [ "$REMOTE" != "no-upstream" ] && [ "$LOCAL" != "$REMOTE" ]; then
    echo "WARN: $REPO_NAME has unpushed commits"
    FAILED=1
  fi
done

echo ""
if [ $FAILED -ne 0 ]; then
  echo "=================================================================="
  echo "  ABORT BUILD — DIRTY REPO DETECTED"
  echo "=================================================================="
  echo ""
  echo "  Commit and push all changes before building."
  echo "  Use build-from-git.sh which clones from GitHub."
  echo "=================================================================="
  exit 1
fi

echo "ALL REPOS CLEAN — BUILD ALLOWED"
exit 0
