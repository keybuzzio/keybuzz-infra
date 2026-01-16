#!/bin/bash
# PH-SEC-DB-CREDS-VAULT-ONLY-01
# Guard anti-régression : bloque les commits contenant des secrets en clair
# Usage: ./secret_scan_guard.sh <directory>
# Integrer dans CI/CD ou pre-commit hook

set -e

TARGET_DIR="${1:-.}"
FOUND_SECRETS=0

echo "🔒 Secret Scan Guard - Scanning $TARGET_DIR"
echo "============================================"

# Patterns à bloquer (regex)
PATTERNS=(
  "PGPASSWORD=['\"][^'\"]*['\"]"       # PGPASSWORD="..." ou PGPASSWORD='...'
  "KeyBuzz_Dev_"                        # Ancien pattern compromis
  "KeyBuzz_Prod_"                       # Pattern prod
  "password=['\"][A-Za-z0-9!@#$%^&*_+-]{8,}['\"]"  # password="..."
  "DATABASE_URL=.*:.*@"                 # Connection strings avec password
)

# Fichiers à exclure
EXCLUDE_DIRS="node_modules|.git|dist|build|vendor|__pycache__"
EXCLUDE_FILES="secret_scan_guard.sh|package-lock.json|yarn.lock"

for pattern in "${PATTERNS[@]}"; do
  echo ""
  echo "Checking pattern: $pattern"
  
  # Chercher dans les fichiers
  MATCHES=$(grep -rn --include="*.sh" --include="*.py" --include="*.ts" --include="*.js" \
                     --include="*.yaml" --include="*.yml" --include="*.json" --include="*.md" \
                     --include="*.sql" --include="*.env*" \
                     -E "$pattern" "$TARGET_DIR" 2>/dev/null | \
            grep -vE "$EXCLUDE_DIRS" | \
            grep -vE "$EXCLUDE_FILES" || true)
  
  if [ -n "$MATCHES" ]; then
    echo "❌ FOUND SECRETS:"
    echo "$MATCHES" | while read line; do
      # Masquer la valeur du secret dans l'output
      echo "$line" | sed -E 's/(PGPASSWORD=|password=|PASSWORD=)(['"'"'"])[^'"'"'"]*(['"'"'"])/\1\2***REDACTED***\3/g'
    done
    FOUND_SECRETS=1
  else
    echo "✅ Clean"
  fi
done

echo ""
echo "============================================"

if [ "$FOUND_SECRETS" -eq 1 ]; then
  echo "❌ SECRETS DETECTED - COMMIT BLOCKED"
  echo ""
  echo "Actions requises:"
  echo "1. Supprimer les secrets en clair des fichiers"
  echo "2. Utiliser Vault/ESO pour les credentials"
  echo "3. Utiliser job-psql-debug.yaml pour les debug DB"
  exit 1
else
  echo "✅ No secrets found - OK to commit"
  exit 0
fi
