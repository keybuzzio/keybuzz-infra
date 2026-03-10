#!/bin/bash
###############################################################################
# PH26.4C — Pre-commit hook pour Git
# 
# Installation :
#   cp scripts/gitops-guard-pre-commit.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# Ce hook bloque les commits contenant des images avec des tags non immuables
###############################################################################

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_ROOT="$(git rev-parse --show-toplevel)"

# Vérifier si le script de guard existe
GUARD_SCRIPT="$REPO_ROOT/scripts/gitops-guard-immutable-tags.sh"

if [[ ! -f "$GUARD_SCRIPT" ]]; then
    echo "WARNING: Guard script not found at $GUARD_SCRIPT"
    echo "Skipping immutable tag validation..."
    exit 0
fi

# Vérifier seulement les fichiers staged
STAGED_YAML=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(yaml|yml)$' | grep '^k8s/' || true)

if [[ -z "$STAGED_YAML" ]]; then
    # Pas de fichiers K8s modifiés
    exit 0
fi

echo "PH26.4C: Validation des tags immuables..."
echo ""

# Créer un répertoire temporaire avec les fichiers staged
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

mkdir -p "$TEMP_DIR/k8s"

while IFS= read -r file; do
    if [[ -n "$file" ]]; then
        dir=$(dirname "$file")
        mkdir -p "$TEMP_DIR/$dir"
        git show ":$file" > "$TEMP_DIR/$file" 2>/dev/null || true
    fi
done <<< "$STAGED_YAML"

# Exécuter le guard sur les fichiers staged
cd "$TEMP_DIR"
bash "$GUARD_SCRIPT" k8s/

exit $?
