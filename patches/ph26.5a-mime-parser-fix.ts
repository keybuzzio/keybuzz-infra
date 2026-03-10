/**
 * PH26.5A: MIME Attachment Parser - FIX
 * 
 * PROBLÈME: Le texte du message est perdu quand une PJ est présente
 * CAUSE: Le regex text/plain ne matche pas tous les formats Amazon
 * FIX: 
 *   1. Extraire TOUTES les parts MIME avec métadonnées
 *   2. Priorité: text/plain non vide > text/html converti > fallback
 *   3. PJ = toutes les parts avec disposition=attachment OU filename
 *   4. Ne jamais écraser le body avec une PJ
 */

// ============================================================
// NOUVELLE FONCTION: parseMimeEmailManual CORRIGÉE
// À REMPLACER dans attachmentParser.service.ts
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
function extractMimeParts(rawEmail: string): MimePart[] {
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
  console.log(`[MimeParser PH26.5A] Boundary: ${boundary}`);
  
  const rawParts = rawEmail.split(boundary);
  console.log(`[MimeParser PH26.5A] Found ${rawParts.length} raw parts`);
  
  for (let i = 0; i < rawParts.length; i++) {
    const rawPart = rawParts[i];
    
    // Skip empty parts and closing boundary
    if (!rawPart || rawPart.trim() === '--' || rawPart.trim().length < 10) {
      continue;
    }
    
    // Split headers from content (double newline)
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
    
    // LOG METADATA (PH26.5A DEBUG - sans contenu PII)
    console.log(`[MimeParser PH26.5A] Part ${i}: type=${contentType}, disposition=${contentDisposition}, filename=${filename || 'none'}, encoding=${transferEncoding}, charset=${charset}, size=${content.length}, isText=${isTextCandidate}, isAttachment=${isAttachmentCandidate}`);
  }
  
  return parts;
}

/**
 * PH26.5A: Decode part content based on transfer encoding and charset
 */
function decodePartContent(part: MimePart): string {
  let content = part.content;
  
  // Decode transfer encoding
  if (part.transferEncoding === 'base64') {
    try {
      content = Buffer.from(content.replace(/[\s\r\n]/g, ''), 'base64').toString('utf-8');
    } catch (err) {
      console.warn(`[MimeParser PH26.5A] Base64 decode failed for part ${part.index}`);
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
      console.warn(`[MimeParser PH26.5A] Charset conversion failed for ${part.charset}`);
    }
  }
  
  return content;
}

/**
 * PH26.5A: Main parser function - CORRECTED
 */
function parseMimeEmailManualFixed(rawEmail: string): ParsedEmail {
  const result: ParsedEmail = {
    textBody: '',
    htmlBody: '',
    attachments: [],
  };
  
  console.log('[MimeParser PH26.5A] === Starting MIME parsing ===');
  console.log(`[MimeParser PH26.5A] Raw email length: ${rawEmail.length}`);
  
  // Extract all parts
  const parts = extractMimeParts(rawEmail);
  console.log(`[MimeParser PH26.5A] Extracted ${parts.length} parts`);
  
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
  
  console.log(`[MimeParser PH26.5A] Text candidates: ${textParts.length}, Attachment candidates: ${attachmentParts.length}`);
  
  // ===== EXTRACT BODY (PRIORITY: text/plain > text/html) =====
  // PH26.5A FIX: Never overwrite body with attachment, use first non-empty text
  
  // Priority 1: text/plain
  for (const part of textParts) {
    if (part.contentType === 'text/plain' || part.contentType.startsWith('text/plain;')) {
      const decoded = decodePartContent(part);
      const cleaned = decoded.trim();
      if (cleaned.length > 0) {
        console.log(`[MimeParser PH26.5A] Using text/plain from part ${part.index} (${cleaned.length} chars)`);
        result.textBody = cleaned;
        break;
      }
    }
  }
  
  // Priority 2: text/html (converted to text)
  if (!result.textBody) {
    for (const part of textParts) {
      if (part.contentType === 'text/html' || part.contentType.startsWith('text/html;')) {
        const decoded = decodePartContent(part);
        const converted = htmlToText(decoded);
        if (converted.length > 0) {
          console.log(`[MimeParser PH26.5A] Using text/html (converted) from part ${part.index} (${converted.length} chars)`);
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
      part.filename = `attachment_${part.index}_${Date.now()}`;
    }
    
    // Determine MIME type
    let mimeType = part.contentType;
    if (mimeType === 'application/octet-stream') {
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
        console.warn(`[MimeParser PH26.5A] Failed to decode base64 for ${part.filename}`);
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
      console.log(`[MimeParser PH26.5A] Extracted attachment: ${part.filename} (${buffer.length} bytes, ${mimeType})`);
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
    ];
    
    for (const pattern of amazonPatterns) {
      const match = rawEmail.match(pattern);
      if (match && match[1]) {
        const extracted = match[1].trim();
        if (extracted.length > 5) {
          console.log(`[MimeParser PH26.5A] Extracted Amazon message: ${extracted.substring(0, 100)}...`);
          result.textBody = extracted;
          break;
        }
      }
    }
  }
  
  // ===== FINAL FALLBACK =====
  if (!result.textBody && result.attachments.length > 0) {
    console.log('[MimeParser PH26.5A] No text found, using placeholder');
    result.textBody = '[Pièce jointe reçue - texte non disponible]';
  }
  
  console.log(`[MimeParser PH26.5A] === Result: textBody=${result.textBody.length} chars, attachments=${result.attachments.length} ===`);
  
  return result;
}

function htmlToText(html: string): string {
  return html
    .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<\/p>/gi, '\n\n')
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>')
    .replace(/&quot;/gi, '"')
    .trim();
}

// Export for integration
export { parseMimeEmailManualFixed, extractMimeParts, MimePart };
