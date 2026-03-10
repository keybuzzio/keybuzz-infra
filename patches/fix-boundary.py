#!/usr/bin/env python3
# PH26.5A: Fix boundary detection for Amazon MIME format

import sys

TARGET = '/opt/keybuzz/keybuzz-backend/src/modules/webhooks/attachmentParser.service.ts'

with open(TARGET, 'r') as f:
    content = f.read()

# Patch 1: Boundary detection - add Amazon format fallback
old_boundary = """  // Find boundary
  const boundaryMatch = rawEmail.match(/boundary=['"]?([^'"\\s;\\r\\n]+)/i);
  if (!boundaryMatch) {
    console.log('[MimeParser PH26.5A] No boundary found, treating as single part');"""

new_boundary = """  // Find boundary - first try explicit boundary= header, then detect from ------=_Part_ pattern
  let boundaryMatch = rawEmail.match(/boundary=['"]?([^'"\\s;\\r\\n]+)/i);
  
  // PH26.5A FIX: If no explicit boundary, detect from Amazon format (------=_Part_...)
  if (!boundaryMatch) {
    const amazonBoundaryMatch = rawEmail.match(/(------=_Part_[^\\r\\n]+)/);
    if (amazonBoundaryMatch) {
      console.log('[MimeParser PH26.5A] Detected Amazon boundary:', amazonBoundaryMatch[1].substring(0, 40));
      boundaryMatch = [null, amazonBoundaryMatch[1]];
    }
  }
  
  if (!boundaryMatch) {
    console.log('[MimeParser PH26.5A] No boundary found, treating as single part');"""

if old_boundary in content:
    content = content.replace(old_boundary, new_boundary)
    print('OK: Patched boundary detection')
else:
    print('ERROR: Old boundary code not found')
    sys.exit(1)

# Patch 2: Boundary split - handle Amazon format where boundary is already complete
old_split = """  const boundary = '--' + boundaryMatch[1];
  console.log('[MimeParser PH26.5A] Boundary:', boundary.substring(0, 50));"""

new_split = """  // For Amazon format (starts with ------=), boundary is already complete; else add --
  const isAmazonDirect = rawEmail.trim().startsWith('------=_Part');
  const boundary = isAmazonDirect ? boundaryMatch[1] : ('--' + boundaryMatch[1]);
  console.log('[MimeParser PH26.5A] Boundary:', boundary.substring(0, 50), 'Amazon:', isAmazonDirect);"""

if old_split in content:
    content = content.replace(old_split, new_split)
    print('OK: Patched boundary split')
else:
    print('WARNING: Old split code not found (may already be patched)')

with open(TARGET, 'w') as f:
    f.write(content)

print('Done - file updated')
