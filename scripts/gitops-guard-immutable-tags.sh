#!/bin/bash
###############################################################################
# PH26.4C - Guard GitOps : Tags immuables OBLIGATOIRES
# 
# Ce script bloque tout commit/deploiement contenant des images avec :
# - :dev (seul, pas v1.0.0-dev)
# - :latest
# - Pas de tag du tout
# - Tags generiques non versionnes
#
# Usage :
#   ./gitops-guard-immutable-tags.sh [directory]
#   
#   directory : Repertoire a scanner (defaut: k8s/)
#
# Exit codes :
#   0 = OK, tous les tags sont immuables
#   1 = ERREUR, tags non immuables detectes
###############################################################################

SCAN_DIR="${1:-k8s/}"

echo "=============================================="
echo "  PH26.4C - Guard GitOps Tags Immuables"
echo "=============================================="
echo ""
echo "Scanning directory: $SCAN_DIR"
echo ""

# Fichier temporaire pour les resultats
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# Compteurs
ERRORS=0
WARNINGS=0
CHECKED=0

echo "Recherche des fichiers YAML..."

# Trouver toutes les images dans les fichiers YAML
grep -rn "image:" "$SCAN_DIR" --include="*.yaml" --include="*.yml" 2>/dev/null | \
grep -v "imagePullPolicy" | \
grep -v "#" | \
while IFS= read -r line; do
    # Extraire fichier:numero:contenu
    file=$(echo "$line" | cut -d: -f1)
    linenum=$(echo "$line" | cut -d: -f2)
    content=$(echo "$line" | cut -d: -f3-)
    
    # Extraire l'image
    image=$(echo "$content" | sed 's/.*image:[[:space:]]*//' | tr -d '"' | tr -d "'" | tr -d ' ')
    
    # Ignorer si pas d'image valide
    if [ -z "$image" ] || [ "$image" = "{{" ]; then
        continue
    fi
    
    # Extraire le tag
    if echo "$image" | grep -q ":"; then
        tag="${image##*:}"
    else
        tag=""
    fi
    
    # Verifier les tags interdits
    ERROR=""
    WARNING=""
    
    if [ -z "$tag" ]; then
        ERROR="Image sans tag (= :latest implicite)"
    elif [ "$tag" = "dev" ]; then
        ERROR="Tag :dev interdit (utiliser v1.0.0-dev)"
    elif [ "$tag" = "latest" ]; then
        ERROR="Tag :latest interdit"
    elif [ "$tag" = "main" ] || [ "$tag" = "master" ]; then
        ERROR="Tag :$tag interdit (branche)"
    elif echo "$tag" | grep -qE "^[a-z]+$" && [ ${#tag} -lt 10 ]; then
        WARNING="Tag simple potentiellement non immuable"
    fi
    
    if [ -n "$ERROR" ]; then
        echo "E|$file|$linenum|$image|$ERROR" >> "$TEMP_FILE"
    elif [ -n "$WARNING" ]; then
        echo "W|$file|$linenum|$image|$WARNING" >> "$TEMP_FILE"
    else
        echo "OK|$file|$linenum|$image|" >> "$TEMP_FILE"
    fi
done

# Afficher les resultats
echo ""
echo "Validation des images..."
echo ""

ERRORS=0
WARNINGS=0
CHECKED=0

if [ -f "$TEMP_FILE" ]; then
    while IFS='|' read -r status file linenum image msg; do
        CHECKED=$((CHECKED + 1))
        
        case "$status" in
            E)
                ERRORS=$((ERRORS + 1))
                echo "[ERREUR] $msg"
                echo "  Fichier: $file:$linenum"
                echo "  Image: $image"
                echo ""
                ;;
            W)
                WARNINGS=$((WARNINGS + 1))
                echo "[AVERTISSEMENT] $msg"
                echo "  Fichier: $file:$linenum"
                echo "  Image: $image"
                echo ""
                ;;
            OK)
                echo "[OK] $image"
                ;;
        esac
    done < "$TEMP_FILE"
fi

# Resume
echo ""
echo "=============================================="
echo "  RESUME"
echo "=============================================="
echo ""
echo "Images verifiees: $CHECKED"
echo "Erreurs: $ERRORS"
echo "Avertissements: $WARNINGS"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo "=============================================="
    echo "  ECHEC - TAGS NON IMMUABLES DETECTES"
    echo "=============================================="
    echo ""
    echo "Les tags suivants sont INTERDITS :"
    echo "  - :dev (seul)"
    echo "  - :latest"
    echo "  - :main / :master"
    echo "  - Pas de tag"
    echo ""
    echo "Tags ACCEPTES (exemples) :"
    echo "  - v1.0.0"
    echo "  - 1.0.20-dev"
    echo "  - 0.2.121-attach-1768687798"
    echo "  - v1.0.35-ph264b"
    echo "  - sha-abc123"
    echo ""
    exit 1
else
    echo "=============================================="
    echo "  SUCCES - TOUS LES TAGS SONT IMMUABLES"
    echo "=============================================="
    exit 0
fi
