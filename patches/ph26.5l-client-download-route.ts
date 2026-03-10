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
