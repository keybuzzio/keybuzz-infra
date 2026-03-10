#!/usr/bin/env python3
# PH26.5F: Fix PJ truncation - proper binary streaming

TARGET = '/opt/keybuzz/keybuzz-client/app/api/attachments/[id]/route.ts'

NEW_CONTENT = '''/**
 * PH-ATTACHMENTS-TENANT-PROXY-FIX-01: Proxy pour les pieces jointes
 * PH26.5F: Fix binary streaming to avoid truncation
 */

import { NextRequest, NextResponse } from "next/server";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || "https://api-dev.keybuzz.io";

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const attachmentId = params.id;
    if (!attachmentId) {
      return NextResponse.json({ error: "ID manquant" }, { status: 400 });
    }

    // Get tenantId from query param (passed from client-side localStorage)
    const { searchParams } = new URL(request.url);
    const tenantId = searchParams.get("tenantId") || "";

    if (!tenantId) {
      console.error("[AttachmentProxy] Tenant manquant - URL:", request.url);
      return NextResponse.json({ 
        error: "Tenant manquant", 
        hint: "Le tenantId doit etre passe en query param: /api/attachments/<id>?tenantId=xxx" 
      }, { status: 400 });
    }

    // Call backend with X-Tenant-Id header
    const downloadEndpoint = `${API_BASE_URL}/attachments/${attachmentId}`;
    console.log(`[AttachmentProxy] Fetching: ${downloadEndpoint} for tenant ${tenantId}`);
    
    const response = await fetch(downloadEndpoint, {
      method: "GET",
      headers: {
        "X-Tenant-Id": tenantId,
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`[AttachmentProxy] Backend error ${response.status}:`, errorText);
      return NextResponse.json(
        { error: "Piece jointe introuvable", details: errorText },
        { status: response.status }
      );
    }

    // PH26.5F: Get binary data as ArrayBuffer and convert to Uint8Array
    // This ensures we handle binary data correctly without truncation
    const arrayBuffer = await response.arrayBuffer();
    const uint8Array = new Uint8Array(arrayBuffer);
    
    // Get headers from backend response
    const contentType = response.headers.get("content-type") || "application/octet-stream";
    const backendContentDisposition = response.headers.get("content-disposition") || "";
    
    // Extract filename from backend Content-Disposition or use default
    let filename = "attachment";
    const filenameMatch = backendContentDisposition.match(/filename[*]?=(?:UTF-8\'\')?["']?([^"';\\n]+)/i);
    if (filenameMatch) {
      filename = decodeURIComponent(filenameMatch[1]);
    }
    
    // PH26.5F: Use actual buffer size as Content-Length (not backend header which may be wrong)
    const actualSize = uint8Array.length;
    
    console.log(`[AttachmentProxy] Streaming ${actualSize} bytes, type: ${contentType}, filename: ${filename}`);

    // PH26.5D+5F: Force download with correct binary response
    return new NextResponse(uint8Array, {
      status: 200,
      headers: {
        "Content-Type": contentType,
        "Content-Disposition": `attachment; filename="${filename.replace(/"/g, '\\\\"')}"`,
        "Content-Length": actualSize.toString(),
        "Cache-Control": "private, max-age=86400",
      },
    });
  } catch (error) {
    console.error("[AttachmentProxy] Error:", error);
    return NextResponse.json(
      { error: "Erreur lors de la recuperation de la piece jointe" },
      { status: 500 }
    );
  }
}
'''

with open(TARGET, 'w') as f:
    f.write(NEW_CONTENT)

print(f'OK: Rewrote {TARGET} with PH26.5F binary fix')
print(f'Changes:')
print('  - Use arrayBuffer() instead of blob()')
print('  - Convert to Uint8Array for proper binary handling')
print('  - Calculate actual Content-Length from buffer size')
print('  - Extract and sanitize filename from backend header')
