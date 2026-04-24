#!/bin/bash
set -e

echo "=== PH-WEBSITE-IMAGE-DIAG ==="
echo "Date: $(date)"
echo ""

cd /opt/keybuzz/keybuzz-website

echo "=== 1. Dimensions PNG (from IHDR chunk) ==="
for f in public/brand/icon.png public/brand/marketplaces/fnac.png public/brand/marketplaces/darty.png public/brand/marketplaces/ebay.png; do
    W=$(od -A n -t u4 -j 16 -N 4 "$f" | tr -d ' ')
    H=$(od -A n -t u4 -j 20 -N 4 "$f" | tr -d ' ')
    SIZE=$(stat -c%s "$f")
    echo "  $f: ${W}x${H} (${SIZE} bytes)"
done

echo ""
echo "=== 2. JPEG info ==="
for f in public/images/ludovic.jpg public/brand/marketplaces/cdiscount.jpg; do
    SIZE=$(stat -c%s "$f")
    echo "  $f: JPEG (${SIZE} bytes)"
done

echo ""
echo "=== 3. PNG alpha channel check (color type in IHDR) ==="
for f in public/brand/icon.png public/brand/marketplaces/fnac.png public/brand/marketplaces/darty.png public/brand/marketplaces/ebay.png; do
    CT=$(od -A n -t u1 -j 25 -N 1 "$f" | tr -d ' ')
    case $CT in
        0) TYPE="Grayscale" ;;
        2) TYPE="RGB (no alpha)" ;;
        3) TYPE="Palette (indexed)" ;;
        4) TYPE="Grayscale + Alpha" ;;
        6) TYPE="RGBA (with alpha)" ;;
        *) TYPE="Unknown ($CT)" ;;
    esac
    echo "  $f: color_type=$CT ($TYPE)"
done

echo ""
echo "=== 4. Git diff (uncommitted changes) ==="
git diff --stat

echo ""
echo "=== 5. Git log for image-related commits ==="
git log --oneline --all | head -20

echo ""
echo "=== 6. Dockerfile diff (uncommitted) ==="
git diff Dockerfile

echo ""
echo "=== 7. Current deployed image in pods ==="
echo "DEV:"
kubectl get deploy keybuzz-website -n keybuzz-website-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
echo "PROD:"
kubectl get deploy keybuzz-website -n keybuzz-website-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

echo ""
echo "=== 8. Pod logs (last 30 lines, errors only) ==="
kubectl logs -n keybuzz-website-prod keybuzz-website-7f9ff7b9bc-248qg --tail=30 2>&1 | grep -i "error\|fail\|EACCES" || echo "  (no errors in last 30 lines)"

echo ""
echo "=== DIAG COMPLETE ==="
