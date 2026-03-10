#!/bin/bash
# PH26.5A: Apply MIME parser fix
# This script patches attachmentParser.service.ts with improved text extraction

set -e

TARGET="/opt/keybuzz/keybuzz-backend/src/modules/webhooks/attachmentParser.service.ts"
BACKUP="${TARGET}.bak.ph265a.$(date +%Y%m%d_%H%M%S)"

echo "=== PH26.5A: Applying MIME parser fix ==="
echo "Target: $TARGET"
echo "Backup: $BACKUP"

# Backup
cp "$TARGET" "$BACKUP"
echo "Backup created"

# Create the new parser function
cat > /tmp/ph265a_new_parser.ts << 'NEWPARSER'

// ============================================================
// PH26.5A: IMPROVED MIME PARSER
// FIX: Text extraction priority + never overwrite with PJ
// ============================================================

interface MimePart {
  index: number;
  contentType: string;
  contentDisposition: string;
  filename: string | null;
  transferEncoding: string;
  charset: string;
  size: number;
  isTextCandidate: boolean;
  isAttachmentCandidate: boolean;
  content: string;
}

/**
 * PH26.5A: Extract all MIME parts with metadata for debugging
 */
function extractMimePartsV2(rawEmail: string): MimePart[] {
  const parts: MimePart[] = [];
  
  // Find boundary
  const boundaryMatch = rawEmail.match(/boundary=['"]?([^'"\s;\r\n]+)/i);
  if (!boundaryMatch) {
    console.log('[MimeParser PH26.5A] No boundary found, treating as single part');
    return [{
      index: 0,
      contentType: 'text/plain',
      contentDisposition: '',
      filename: null,
      transferEncoding: '',
      charset: 'utf-8',
      size: rawEmail.length,
      isTextCandidate: true,
      isAttachmentCandidate: false,
      content: rawEmail,
    }];
  }
  
  const boundary = '--' + boundaryMatch[1];
  console.log('[MimeParser PH26.5A] Boundary:', boundary.substring(0, 50));
  
  const rawParts = rawEmail.split(new RegExp(boundary.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')));
  console.log('[MimeParser PH26.5A] Found', rawParts.length, 'raw parts');
  
  for (let i = 0; i < rawParts.length; i++) {
    const rawPart = rawParts[i];
    
    // Skip empty parts and closing boundary
    if (!rawPart || rawPart.trim() === '--' || rawPart.trim().length < 10) {
      continue;
    }
    
    // Split headers from content (double newline - handle both \n\n and \r\n\r\n)
    const headerEndMatch = rawPart.match(/\r?\n\r?\n/);
    if (!headerEndMatch) {
      continue;
    }
    
    const headerEndIdx = rawPart.indexOf(headerEndMatch[0]);
    const headers = rawPart.substring(0, headerEndIdx);
    const content = rawPart.substring(headerEndIdx + headerEndMatch[0].length);
    
    // Parse headers
    const contentTypeMatch = headers.match(/Content-Type:\s*([^;\r\n]+)/i);
    const contentType = contentTypeMatch ? contentTypeMatch[1].trim().toLowerCase() : 'text/plain';
    
    const dispositionMatch = headers.match(/Content-Disposition:\s*([^;\r\n]+)/i);
    const contentDisposition = dispositionMatch ? dispositionMatch[1].trim().toLowerCase() : '';
    
    const filenameMatch = headers.match(/filename[*]?=['"]?([^'"\r\n;]+)/i);
    let filename = filenameMatch ? filenameMatch[1].trim() : null;
    if (filename && filename.includes("''")) {
      try { filename = decodeURIComponent(filename.split("''")[1] || filename); } catch {}
    }
    
    const encodingMatch = headers.match(/Content-Transfer-Encoding:\s*([^\r\n]+)/i);
    const transferEncoding = encodingMatch ? encodingMatch[1].trim().toLowerCase() : '';
    
    const charsetMatch = headers.match(/charset=['"]?([^'"\s;]+)/i);
    const charset = charsetMatch ? charsetMatch[1].trim().toLowerCase() : 'utf-8';
    
    const isTextCandidate = contentType.startsWith('text/') && !filename && contentDisposition !== 'attachment';
    const isAttachmentCandidate = !!filename || contentDisposition === 'attachment';
    
    const part: MimePart = {
      index: i,
      contentType,
      contentDisposition,
      filename,
      transferEncoding,
      charset,
      size: content.length,
      isTextCandidate,
      isAttachmentCandidate,
      content,
    };
    
    parts.push(part);
    
    // LOG METADATA (PH26.5A DEBUG - no PII content)
    console.log('[MimeParser PH26.5A] Part', i, ': type=' + contentType + ', disp=' + contentDisposition + ', file=' + (filename || 'none') + ', enc=' + transferEncoding + ', size=' + content.length + ', isText=' + isTextCandidate + ', isAtt=' + isAttachmentCandidate);
  }
  
  return parts;
}

/**
 * PH26.5A: Decode part content based on transfer encoding and charset
 */
function decodePartContentV2(part: MimePart): string {
  let content = part.content;
  
  // Decode transfer encoding
  if (part.transferEncoding === 'base64') {
    try {
      content = Buffer.from(content.replace(/[\s\r\n]/g, ''), 'base64').toString('utf-8');
    } catch (err) {
      console.warn('[MimeParser PH26.5A] Base64 decode failed for part', part.index);
    }
  } else if (part.transferEncoding === 'quoted-printable') {
    content = content
      .replace(/=\r?\n/g, '')
      .replace(/=([0-9A-Fa-f]{2})/g, (_, hex) => String.fromCharCode(parseInt(hex, 16)));
  }
  
  // Handle charset conversion if needed
  if (part.charset && part.charset !== 'utf-8' && part.charset !== 'us-ascii') {
    try {
      // For iso-8859-1 / windows-1252, convert to utf-8
      if (part.charset.includes('8859') || part.charset.includes('1252')) {
        const buf = Buffer.from(content, 'latin1');
        content = buf.toString('utf-8');
      }
    } catch (err) {
      console.warn('[MimeParser PH26.5A] Charset conversion failed for', part.charset);
    }
  }
  
  return content;
}

NEWPARSER

# Now create the replacement for parseMimeEmailManual function
# We need to replace the entire function

cat > /tmp/ph265a_replacement.ts << 'REPLACEMENT'
/**
 * PH26.5A: Manual MIME parser - FIXED VERSION
 * Ensures text body is never overwritten by attachments
 */
function parseMimeEmailManual(rawEmail: string): ParsedEmail {
  const result: ParsedEmail = {
    textBody: '',
    htmlBody: '',
    attachments: [],
  };
  
  console.log('[MimeParser PH26.5A] === Starting MIME parsing ===');
  console.log('[MimeParser PH26.5A] Raw email length:', rawEmail.length);
  
  // Check for Amazon simple format (Content-Disposition without proper MIME)
  const hasAttachment = rawEmail.includes('Content-Disposition: attachment;') || rawEmail.includes('Content-Disposition:attachment;');
  const hasBoundary = rawEmail.includes('------=_Part') || rawEmail.match(/boundary=['"]?([^'"\s;\r\n]+)/i);
  
  console.log('[MimeParser PH26.5A] hasAttachment:', hasAttachment, ', hasBoundary:', !!hasBoundary);
  
  if (hasBoundary) {
    // Parse multipart MIME
    const parts = extractMimePartsV2(rawEmail);
    console.log('[MimeParser PH26.5A] Extracted', parts.length, 'parts');
    
    // Separate text candidates and attachments
    const textParts: MimePart[] = [];
    const attachmentParts: MimePart[] = [];
    
    for (const part of parts) {
      if (part.isAttachmentCandidate) {
        attachmentParts.push(part);
      } else if (part.isTextCandidate) {
        textParts.push(part);
      }
    }
    
    console.log('[MimeParser PH26.5A] Text candidates:', textParts.length, ', Attachment candidates:', attachmentParts.length);
    
    // ===== EXTRACT BODY (PRIORITY: text/plain > text/html) =====
    // PH26.5A FIX: Never overwrite body with attachment, use first non-empty text
    
    // Priority 1: text/plain
    for (const part of textParts) {
      if (part.contentType === 'text/plain' || part.contentType.startsWith('text/plain;')) {
        const decoded = decodePartContentV2(part);
        const cleaned = decoded.trim();
        if (cleaned.length > 0 && !isBase64Noise(cleaned)) {
          console.log('[MimeParser PH26.5A] Using text/plain from part', part.index, '(', cleaned.length, 'chars)');
          result.textBody = cleaned;
          break;
        }
      }
    }
    
    // Priority 2: text/html (converted to text)
    if (!result.textBody) {
      for (const part of textParts) {
        if (part.contentType === 'text/html' || part.contentType.startsWith('text/html;')) {
          const decoded = decodePartContentV2(part);
          const converted = htmlToText(decoded);
          if (converted.length > 0) {
            console.log('[MimeParser PH26.5A] Using text/html (converted) from part', part.index, '(', converted.length, 'chars)');
            result.textBody = converted;
            result.htmlBody = decoded;
            break;
          }
        }
      }
    }
    
    // ===== EXTRACT ATTACHMENTS =====
    for (const part of attachmentParts) {
      if (!part.filename) {
        part.filename = 'attachment_' + part.index + '_' + Date.now();
      }
      
      // Determine MIME type
      let mimeType = part.contentType;
      if (mimeType === 'application/octet-stream' || !mimeType.includes('/')) {
        const ext = part.filename.toLowerCase().split('.').pop();
        if (ext === 'pdf') mimeType = 'application/pdf';
        else if (ext === 'jpg' || ext === 'jpeg') mimeType = 'image/jpeg';
        else if (ext === 'png') mimeType = 'image/png';
        else if (ext === 'gif') mimeType = 'image/gif';
      }
      
      // Decode content
      let buffer: Buffer;
      if (part.transferEncoding === 'base64') {
        const base64Content = part.content.replace(/[\s\r\n]/g, '');
        try {
          buffer = Buffer.from(base64Content, 'base64');
        } catch (err) {
          console.warn('[MimeParser PH26.5A] Failed to decode base64 for', part.filename);
          continue;
        }
      } else {
        buffer = Buffer.from(part.content, 'utf-8');
      }
      
      if (buffer.length > 0) {
        result.attachments.push({
          filename: part.filename,
          mimeType,
          content: buffer,
          isInline: part.contentDisposition === 'inline',
        });
        console.log('[MimeParser PH26.5A] Extracted attachment:', part.filename, '(', buffer.length, 'bytes,', mimeType, ')');
      }
    }
  }
  
  // ===== FALLBACK: If no text found, try Amazon-specific extraction =====
  if (!result.textBody) {
    console.log('[MimeParser PH26.5A] No text found in parts, trying Amazon extraction');
    
    // Look for Amazon message markers in raw email
    const amazonPatterns = [
      /------------- Message:\s*([\s\S]*?)\s*------------- Fin/i,
      /Message de l'acheteur\s*:\s*([\s\S]*?)(?:\n{2,}|---)/i,
      /Message:\s*-{5,}\s*\n\n([\s\S]*?)(?:\n{2,}------)/i,
      /Buyer Message:\s*([\s\S]*?)(?:\n{2,}|---|\Z)/i,
    ];
    
    for (const pattern of amazonPatterns) {
      const match = rawEmail.match(pattern);
      if (match && match[1]) {
        let extracted = match[1].trim();
        // Decode quoted-printable if needed
        if (extracted.includes('=') && extracted.match(/=[0-9A-Fa-f]{2}/)) {
          extracted = extracted
            .replace(/=\r?\n/g, '')
            .replace(/=([0-9A-Fa-f]{2})/g, (_, hex) => String.fromCharCode(parseInt(hex, 16)));
        }
        if (extracted.length > 5 && !isBase64Noise(extracted)) {
          console.log('[MimeParser PH26.5A] Extracted Amazon message:', extracted.substring(0, 100) + '...');
          result.textBody = extracted;
          break;
        }
      }
    }
  }
  
  // ===== LEGACY FALLBACK for Amazon simple format =====
  if (!result.textBody && hasAttachment) {
    // Try the old extraction method as last resort
    const textPlainMatch = rawEmail.match(/Content-Type:\s*text\/plain[;\s][^]*?\n\n([\s\S]*?)(?=------=_Part|$)/i);
    if (textPlainMatch && textPlainMatch[1]) {
      let extractedText = textPlainMatch[1].trim();
      // Decode quoted-printable
      extractedText = extractedText.replace(/=\r?\n/g, '');
      extractedText = extractedText.replace(/=([0-9A-Fa-f]{2})/g, (_, hex) => String.fromCharCode(parseInt(hex, 16)));
      
      if (extractedText.length > 0 && !isBase64Noise(extractedText)) {
        console.log('[MimeParser PH26.5A] Legacy extraction found text:', extractedText.substring(0, 100));
        result.textBody = extractedText;
      }
    }
  }
  
  // ===== FINAL FALLBACK =====
  if (!result.textBody) {
    if (result.attachments.length > 0) {
      console.log('[MimeParser PH26.5A] No text found, using placeholder');
      result.textBody = '[PiÃ¨ce jointe reÃ§ue - texte non disponible]';
    } else {
      // Clean the raw email as last resort
      result.textBody = cleanBodyText(rawEmail);
    }
  }
  
  console.log('[MimeParser PH26.5A] === Result: textBody=' + result.textBody.length + ' chars, attachments=' + result.attachments.length + ' ===');
  
  return result;
}

/**
 * Check if text is mostly base64 noise
 */
function isBase64Noise(text: string): boolean {
  const base64Chars = text.replace(/[^A-Za-z0-9+/=]/g, '');
  return base64Chars.length > text.length * 0.8 && text.length > 100;
}

REPLACEMENT

echo "Patches created, applying to target file..."

# Read the original file and replace the parseMimeEmailManual function
# This is complex, so we'll use a Python script for precise replacement

python3 << 'PYTHONSCRIPT'
import re

with open('/opt/keybuzz/keybuzz-backend/src/modules/webhooks/attachmentParser.service.ts', 'r') as f:
    content = f.read()

# Read the new parser code
with open('/tmp/ph265a_new_parser.ts', 'r') as f:
    new_parser = f.read()

# Read the replacement function
with open('/tmp/ph265a_replacement.ts', 'r') as f:
    replacement = f.read()

# Find and replace the parseMimeEmailManual function
# We need to find the function start and end

# First, add the MimePart interface and helper functions after the imports
# Find the line after the last import or after ParsedEmail interface
insert_point = content.find('export interface ParsedEmail')
if insert_point == -1:
    print("ERROR: Could not find ParsedEmail interface")
    exit(1)

# Find the end of ParsedEmail interface
pe_end = content.find('}', insert_point)
pe_end = content.find('\n', pe_end) + 1

# Insert new types and helpers after ParsedEmail
content = content[:pe_end] + new_parser + content[pe_end:]

# Now find and replace parseMimeEmailManual function
# Pattern to match the entire function
pattern = r'function parseMimeEmailManual\(rawEmail: string\): ParsedEmail \{[\s\S]*?^\}'
match = re.search(pattern, content, re.MULTILINE)

if match:
    content = content[:match.start()] + replacement.strip() + content[match.end():]
    print("SUCCESS: parseMimeEmailManual function replaced")
else:
    print("WARNING: Could not find parseMimeEmailManual function, appending replacement")
    content = content + "\n\n" + replacement

with open('/opt/keybuzz/keybuzz-backend/src/modules/webhooks/attachmentParser.service.ts', 'w') as f:
    f.write(content)

print("File updated successfully")
PYTHONSCRIPT

echo ""
echo "=== Verification ==="
grep -n "PH26.5A" "$TARGET" | head -10

echo ""
echo "=== Done ==="
echo "Next: rebuild backend image and deploy"
