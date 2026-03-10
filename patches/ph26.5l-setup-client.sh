#!/bin/bash
# PH26.5L: Setup client routes for AI context upload

set -e

echo "=== Creating directories ==="
mkdir -p /opt/keybuzz/keybuzz-client/app/api/ai/context/upload
mkdir -p /opt/keybuzz/keybuzz-client/app/api/ai/context/download/[id]

echo "=== Copying route files ==="
cat > /opt/keybuzz/keybuzz-client/app/api/ai/context/upload/route.ts << 'EOF'
// app/api/ai/context/upload/route.ts
// PH26.5L: Proxy for AI context file upload

import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '../../../auth/[...nextauth]/auth-options';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'https://api-dev.keybuzz.io';

export async function POST(request: Request) {
  try {
    const session = await getServerSession(authOptions);
    
    if (!session?.user?.email) {
      return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
    }

    const userEmail = session.user.email;
    const tenantId = (session as any).tenantId || request.headers.get('X-Tenant-Id');

    if (!tenantId) {
      return NextResponse.json({ error: 'Missing tenantId' }, { status: 400 });
    }

    // Forward the multipart request to backend
    const formData = await request.formData();
    
    const response = await fetch(`${API_URL}/api/v1/ai/context/upload`, {
      method: 'POST',
      headers: {
        'X-User-Email': userEmail,
        'X-Tenant-Id': tenantId,
      },
      body: formData,
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('[AI Context Upload] API error:', response.status, errorText.substring(0, 200));
      return NextResponse.json(
        { error: 'Upload failed', details: errorText.substring(0, 100) },
        { status: response.status }
      );
    }

    const data = await response.json();
    return NextResponse.json(data);

  } catch (error) {
    console.error('[AI Context Upload] Error:', error);
    return NextResponse.json(
      { error: 'Internal error', details: (error as Error).message },
      { status: 500 }
    );
  }
}
EOF

cat > '/opt/keybuzz/keybuzz-client/app/api/ai/context/download/[id]/route.ts' << 'EOF'
// app/api/ai/context/download/[id]/route.ts
// PH26.5L: Proxy for AI context file download

import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '../../../../auth/[...nextauth]/auth-options';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'https://api-dev.keybuzz.io';

export async function GET(
  request: Request,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions);
    
    if (!session?.user?.email) {
      return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
    }

    const userEmail = session.user.email;
    const tenantId = (session as any).tenantId || request.headers.get('X-Tenant-Id');

    if (!tenantId) {
      return NextResponse.json({ error: 'Missing tenantId' }, { status: 400 });
    }

    const response = await fetch(`${API_URL}/api/v1/ai/context/download/${params.id}`, {
      method: 'GET',
      headers: {
        'X-User-Email': userEmail,
        'X-Tenant-Id': tenantId,
      },
    });

    if (!response.ok) {
      return NextResponse.json(
        { error: 'Download failed' },
        { status: response.status }
      );
    }

    const arrayBuffer = await response.arrayBuffer();
    const contentType = response.headers.get('content-type') || 'application/octet-stream';
    const contentDisposition = response.headers.get('content-disposition') || 'attachment';

    return new NextResponse(arrayBuffer, {
      status: 200,
      headers: {
        'Content-Type': contentType,
        'Content-Disposition': contentDisposition,
        'Content-Length': arrayBuffer.byteLength.toString(),
      },
    });

  } catch (error) {
    console.error('[AI Context Download] Error:', error);
    return NextResponse.json(
      { error: 'Internal error' },
      { status: 500 }
    );
  }
}
EOF

echo "=== Done ==="
ls -la /opt/keybuzz/keybuzz-client/app/api/ai/context/
