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

export const config = {
  api: {
    bodyParser: false,
  },
};
