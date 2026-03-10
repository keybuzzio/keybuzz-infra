#!/bin/bash
# PH26.5A: Fix boundary detection for Amazon format

TARGET="/opt/keybuzz/keybuzz-backend/src/modules/webhooks/attachmentParser.service.ts"

echo "=== PH26.5A: Fixing boundary detection ==="

# Create a patch to fix the extractMimePartsV2 function
# The issue: boundary is not found when there's no explicit boundary= header

# Backup current file
cp "$TARGET" "${TARGET}.bak2.$(date +%s)"

# Use sed to fix the boundary detection
# Old: const boundaryMatch = rawEmail.match(/boundary=['"]?([^'"\s;\r\n]+)/i);
# New: Also detect ------=_Part_ pattern when no explicit boundary

python3 << 'PYTHONSCRIPT'
import re

with open('/opt/keybuzz/keybuzz-backend/src/modules/webhooks/attachmentParser.service.ts', 'r') as f:
    content = f.read()

# Find and replace the boundary detection in extractMimePartsV2
old_code = '''function extractMimePartsV2(rawEmail: string): MimePart[] {
  const parts: MimePart[] = [];
  
  // Find boundary
  const boundaryMatch = rawEmail.match(/boundary=['"]?([^'"\s;\r\n]+)/i);
  if (!boundaryMatch) {
    console.log('[MimeParser PH26.5A] No boundary found, treating as single part');'''

new_code = '''function extractMimePartsV2(rawEmail: string): MimePart[] {
  const parts: MimePart[] = [];
  
  // Find boundary - first try explicit boundary= header, then detect from ------=_Part_ pattern
  let boundaryMatch = rawEmail.match(/boundary=['"]?([^'"\s;\r\n]+)/i);
  
  // PH26.5A FIX: If no explicit boundary, detect from Amazon format (------=_Part_...)
  if (!boundaryMatch) {
    const amazonBoundaryMatch = rawEmail.match(/(------=_Part_[^\\r\\n]+)/);
    if (amazonBoundaryMatch) {
      console.log('[MimeParser PH26.5A] Detected Amazon boundary pattern:', amazonBoundaryMatch[1].substring(0, 40));
      // Create a fake boundaryMatch result - the boundary is used without -- prefix in this case
      boundaryMatch = { 0: 'boundary=' + amazonBoundaryMatch[1], 1: amazonBoundaryMatch[1] } as any;
    }
  }
  
  if (!boundaryMatch) {
    console.log('[MimeParser PH26.5A] No boundary found, treating as single part');'''

if old_code in content:
    content = content.replace(old_code, new_code)
    print("SUCCESS: Patched boundary detection")
else:
    print("WARNING: Could not find exact code to patch, trying alternative...")
    # Try a more flexible replacement
    pattern = r"function extractMimePartsV2\(rawEmail: string\): MimePart\[\] \{\s+const parts: MimePart\[\] = \[\];\s+// Find boundary\s+const boundaryMatch = rawEmail\.match\(/boundary=\['\"]\?\(\[\^'\"\\s;\\r\\n]\+\)/i\);\s+if \(!boundaryMatch\) \{\s+console\.log\('\[MimeParser PH26\.5A\] No boundary found, treating as single part'\);"
    if re.search(pattern, content):
        content = re.sub(pattern, new_code, content)
        print("SUCCESS: Patched with regex")
    else:
        print("ERROR: Could not patch")
        exit(1)

# Also need to fix the boundary split - when using Amazon pattern, don't add --
old_split = '''  const boundary = '--' + boundaryMatch[1];
  console.log('[MimeParser PH26.5A] Boundary:', boundary.substring(0, 50));
  
  const rawParts = rawEmail.split(new RegExp(boundary.replace(/[-\\/\\\\^$*+?.()|[\\]{}]/g, '\\\\$&')));'''

new_split = '''  // For Amazon format, boundary is already complete; for standard MIME, add --
  const isAmazonFormat = rawEmail.startsWith('------=_Part') || !rawEmail.includes('boundary=');
  const boundary = isAmazonFormat ? boundaryMatch[1] : ('--' + boundaryMatch[1]);
  console.log('[MimeParser PH26.5A] Boundary:', boundary.substring(0, 50), '(Amazon format:', isAmazonFormat, ')');
  
  const rawParts = rawEmail.split(new RegExp(boundary.replace(/[-\\/\\\\^$*+?.()|[\\]{}]/g, '\\\\$&')));'''

if old_split in content:
    content = content.replace(old_split, new_split)
    print("SUCCESS: Patched boundary split")
else:
    print("WARNING: Could not patch boundary split")

with open('/opt/keybuzz/keybuzz-backend/src/modules/webhooks/attachmentParser.service.ts', 'w') as f:
    f.write(content)

print("File updated")
PYTHONSCRIPT

echo ""
echo "=== Verifying patch ==="
grep -n "isAmazonFormat\|Detected Amazon boundary" "$TARGET" | head -5

echo ""
echo "=== Done ==="
