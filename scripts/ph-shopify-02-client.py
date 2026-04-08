#!/usr/bin/env python3
"""PH-SHOPIFY-02: Create Client BFF routes + service + logo + patch UI"""
import os, shutil

CLIENT_ROOT = "/opt/keybuzz/keybuzz-client"

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"  Created: {path}")

def patch_file(path, old, new, label):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    if old not in content:
        print(f"  WARN: target not found for [{label}] in {path}")
        return False
    bak = path + '.bak-shopify-02'
    if not os.path.exists(bak):
        shutil.copy2(path, bak)
    content = content.replace(old, new, 1)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"  OK: {label}")
    return True

print("=== PH-SHOPIFY-02: CLIENT MODULE ===\n")

# ── 1. Shopify service ───────────────────────────────────────
print("[1/7] shopify.service.ts")
write_file(f"{CLIENT_ROOT}/src/services/shopify.service.ts", r'''export interface ShopifyStatus {
  connected: boolean;
  shopDomain?: string;
  scopes?: string;
  connectedAt?: string;
  error?: string;
}

export async function getShopifyStatus(tenantId: string): Promise<ShopifyStatus> {
  try {
    const res = await fetch(`/api/shopify/status?tenantId=${tenantId}`);
    if (!res.ok) return { connected: false };
    return res.json();
  } catch {
    return { connected: false };
  }
}

export async function connectShopify(tenantId: string, shopDomain: string): Promise<{ authUrl?: string; error?: string }> {
  const res = await fetch('/api/shopify/connect', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ tenantId, shopDomain }),
  });
  return res.json();
}

export async function disconnectShopify(tenantId: string): Promise<{ disconnected: boolean }> {
  const res = await fetch('/api/shopify/disconnect', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ tenantId }),
  });
  return res.json();
}
''')

# ── 2. BFF: shopify/status ───────────────────────────────────
print("[2/7] BFF shopify/status")
write_file(f"{CLIENT_ROOT}/app/api/shopify/status/route.ts", r'''import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '../../auth/[...nextauth]/auth-options';

const API_URL = process.env.BACKEND_URL || process.env.API_URL_INTERNAL || '';

export async function GET(request: Request) {
  const session = await getServerSession(authOptions);
  if (!session?.user?.email) return NextResponse.json({ connected: false }, { status: 401 });
  const { searchParams } = new URL(request.url);
  const tenantId = searchParams.get('tenantId');
  if (!tenantId) return NextResponse.json({ error: 'tenantId required' }, { status: 400 });
  try {
    const res = await fetch(`${API_URL}/shopify/status?tenantId=${tenantId}`, {
      headers: { 'X-User-Email': session.user.email, 'X-Tenant-Id': tenantId },
    });
    const data = await res.json();
    return NextResponse.json(data);
  } catch (err: any) {
    return NextResponse.json({ connected: false, error: err.message });
  }
}
''')

# ── 3. BFF: shopify/connect ──────────────────────────────────
print("[3/7] BFF shopify/connect")
write_file(f"{CLIENT_ROOT}/app/api/shopify/connect/route.ts", r'''import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '../../auth/[...nextauth]/auth-options';

const API_URL = process.env.BACKEND_URL || process.env.API_URL_INTERNAL || '';

export async function POST(request: Request) {
  const session = await getServerSession(authOptions);
  if (!session?.user?.email) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const body = await request.json();
  const { tenantId, shopDomain } = body;
  if (!tenantId || !shopDomain) return NextResponse.json({ error: 'tenantId and shopDomain required' }, { status: 400 });
  try {
    const res = await fetch(`${API_URL}/shopify/connect`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-User-Email': session.user.email,
        'X-Tenant-Id': tenantId,
      },
      body: JSON.stringify({ tenantId, shopDomain }),
    });
    const data = await res.json();
    return NextResponse.json(data, { status: res.status });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
''')

# ── 4. BFF: shopify/disconnect ───────────────────────────────
print("[4/7] BFF shopify/disconnect")
write_file(f"{CLIENT_ROOT}/app/api/shopify/disconnect/route.ts", r'''import { NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '../../auth/[...nextauth]/auth-options';

const API_URL = process.env.BACKEND_URL || process.env.API_URL_INTERNAL || '';

export async function POST(request: Request) {
  const session = await getServerSession(authOptions);
  if (!session?.user?.email) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  const body = await request.json();
  const { tenantId } = body;
  if (!tenantId) return NextResponse.json({ error: 'tenantId required' }, { status: 400 });
  try {
    const res = await fetch(`${API_URL}/shopify/disconnect`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-User-Email': session.user.email,
        'X-Tenant-Id': tenantId,
      },
      body: JSON.stringify({ tenantId }),
    });
    const data = await res.json();
    return NextResponse.json(data, { status: res.status });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
''')

# ── 5. Shopify SVG logo ──────────────────────────────────────
print("[5/7] Shopify logo SVG")
write_file(f"{CLIENT_ROOT}/public/marketplaces/shopify.svg", r'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">
  <path d="M15.3 5.6c-.1 0-1.8-.1-1.8-.1s-1.2-1.2-1.4-1.3c-.1-.1-.3-.1-.4-.1l-.6 13.9 5.4-1.3S15.4 5.8 15.3 5.6z" fill="#5C6AC4"/>
  <path d="M12.1 4.1l-.3 1c-.4-.2-.9-.3-1.4-.3-1.1 0-1.1.7-1.1.9 0 1 2.6 1.3 2.6 3.6 0 1.8-1.1 2.9-2.6 2.9-1.8 0-2.7-.9-2.7-.9l.5-1.6s.9.8 1.7.8c.5 0 .7-.4.7-.7 0-1.2-2.1-1.3-2.1-3.4 0-1.7 1.2-3.4 3.7-3.4.9 0 1.4.3 1.4.3l-.4-.2z" fill="#fff"/>
  <path d="M11.1 4.1c-.2 0-.4.1-.5.1l-.3 1c-.4-.2-.9-.3-1.4-.3-1.1 0-1.1.7-1.1.9 0 .1 0 .2.1.4l3.3 8.9.6-13.9c-.3-.1-.5-.1-.7-.1z" fill="#95BF47"/>
  <rect x="3" y="2" width="18" height="20" rx="3" fill="none" stroke="#95BF47" stroke-width="1.5"/>
</svg>
''')

# ── 6. Patch channels registry ───────────────────────────────
print("[6/7] Patch channels registry")
REGISTRY = f"{CLIENT_ROOT}/app/api/channels/registry/route.ts"

patch_file(REGISTRY,
    """  { id: 'email',   label: 'Email',                 description: 'Emails directs',                   logo: '/marketplaces/email.svg',     status: 'coming_soon' },
];""",
    """  { id: 'email',   label: 'Email',                 description: 'Emails directs',                   logo: '/marketplaces/email.svg',     status: 'coming_soon' },
  { id: 'shopify', label: 'Shopify',               description: 'Boutique e-commerce Shopify',      logo: '/marketplaces/shopify.svg',   status: 'available' },
];""",
    "Registry: add Shopify entry"
)

# ── 7. Patch channels page ───────────────────────────────────
print("[7/7] Patch channels page")
CHANNELS_PAGE = f"{CLIENT_ROOT}/app/channels/page.tsx"

with open(CHANNELS_PAGE, 'r', encoding='utf-8') as f:
    content = f.read()

bak = CHANNELS_PAGE + '.bak-shopify-02'
if not os.path.exists(bak):
    shutil.copy2(CHANNELS_PAGE, bak)

# 7a. Add import
if 'shopify.service' not in content:
    content = content.replace(
        "} from \"@/src/services/octopia.service\";",
        """} from "@/src/services/octopia.service";
import {
  getShopifyStatus, connectShopify, disconnectShopify,
  type ShopifyStatus
} from "@/src/services/shopify.service";"""
    )
    print("  OK: import shopify.service")

# 7b. Add shopify to PROVIDER_LOGOS
if "'shopify'" not in content or 'shopify.svg' not in content:
    content = content.replace(
        '  darty: "/marketplaces/fnac.svg",\n};',
        '  darty: "/marketplaces/fnac.svg",\n  shopify: "/marketplaces/shopify.svg",\n};'
    )
    print("  OK: PROVIDER_LOGOS: add shopify")

# 7c. Add shopify state
if 'shopifyStatus' not in content:
    content = content.replace(
        '  const [octopiaStatus, setOctopiaStatus] = useState<OctopiaStatus | null>(null);',
        """  const [octopiaStatus, setOctopiaStatus] = useState<OctopiaStatus | null>(null);
  const [shopifyStatus, setShopifyStatus] = useState<ShopifyStatus | null>(null);
  const [showShopifyModal, setShowShopifyModal] = useState(false);
  const [shopifyDomain, setShopifyDomain] = useState('');
  const [shopifyConnecting, setShopifyConnecting] = useState(false);"""
    )
    print("  OK: shopify state vars")

# 7d. Add shopify status refresh
if 'getShopifyStatus' not in content:
    content = content.replace(
        '    try { setOctopiaStatus(await getOctopiaStatus(currentTenantId)); } catch { /* noop */ }',
        """    try { setOctopiaStatus(await getOctopiaStatus(currentTenantId)); } catch { /* noop */ }
    try { setShopifyStatus(await getShopifyStatus(currentTenantId)); } catch { /* noop */ }"""
    )
    print("  OK: shopify status refresh")

# 7e. Detect Shopify OAuth callback query params
if 'shopify_connected' not in content:
    content = content.replace(
        "      clearOAuthCallbackParams();\n    }",
        """      clearOAuthCallbackParams();
    }
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('shopify_connected') === 'true') {
      setSuccessMessage('Shopify connecté avec succès !');
      window.history.replaceState({}, '', '/channels');
    } else if (urlParams.get('shopify_error')) {
      setErrorMessage('Erreur Shopify : ' + urlParams.get('shopify_error'));
      window.history.replaceState({}, '', '/channels');
    }"""
    )
    print("  OK: shopify callback detection")

# 7f. Add Shopify handlers (before the return statement or at the end of handlers)
# Find a safe insertion point - after octopia handlers
if 'handleShopifyConnect' not in content:
    # Insert before the return statement
    return_idx = content.rfind('  return (')
    if return_idx > 0:
        shopify_handlers = """
  // ── Shopify ──────────────────────────────────────────────
  const handleShopifyConnect = async () => {
    if (!currentTenantId || !shopifyDomain.trim()) return;
    setShopifyConnecting(true);
    setErrorMessage(null);
    try {
      const result = await connectShopify(currentTenantId, shopifyDomain.trim());
      if (result.authUrl) {
        window.location.href = result.authUrl;
      } else if (result.error) {
        setErrorMessage('Erreur Shopify : ' + result.error);
      }
    } catch (err: any) {
      setErrorMessage('Erreur Shopify : ' + (err.message || 'Connexion impossible'));
    } finally {
      setShopifyConnecting(false);
    }
  };

  const handleShopifyDisconnect = async () => {
    if (!currentTenantId) return;
    setActionLoading(true);
    try {
      await disconnectShopify(currentTenantId);
      setShopifyStatus({ connected: false });
      setSuccessMessage('Shopify déconnecté');
      setShowShopifyModal(false);
    } catch (err: any) {
      setErrorMessage('Erreur : ' + err.message);
    } finally {
      setActionLoading(false);
    }
  };

"""
        content = content[:return_idx] + shopify_handlers + content[return_idx:]
        print("  OK: shopify handlers")

# 7g. Add Shopify section in the JSX (before the catalog modal or after the channels grid)
# Find the Octopia modal and add Shopify section after the main channels grid
if 'Shopify' not in content or 'showShopifyModal' not in content.split('return (')[1] if 'return (' in content else '':
    # Add Shopify card section. Find a good insertion point - after the channels list
    # Look for the closing of the main content area before the catalog modal
    shopify_section = """
          {/* ── Shopify Connection ────────────────────────── */}
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6 mt-6">
            <div className="flex items-center gap-3 mb-4">
              <img src="/marketplaces/shopify.svg" alt="Shopify" className="w-8 h-8" />
              <div>
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Shopify</h3>
                <p className="text-sm text-gray-500 dark:text-gray-400">Connecter votre boutique Shopify</p>
              </div>
              {shopifyStatus?.connected ? (
                <span className="ml-auto px-3 py-1 text-xs font-medium rounded-full bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400">
                  Connecté
                </span>
              ) : (
                <span className="ml-auto px-3 py-1 text-xs font-medium rounded-full bg-gray-100 dark:bg-gray-700 text-gray-500 dark:text-gray-400">
                  Non connecté
                </span>
              )}
            </div>

            {shopifyStatus?.connected ? (
              <div className="space-y-3">
                <div className="flex items-center gap-2 text-sm text-gray-700 dark:text-gray-300">
                  <Store className="w-4 h-4" />
                  <span>{shopifyStatus.shopDomain}</span>
                </div>
                <button
                  onClick={handleShopifyDisconnect}
                  disabled={actionLoading}
                  className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-red-700 bg-red-50 hover:bg-red-100 dark:bg-red-900/20 dark:text-red-400 dark:hover:bg-red-900/30 rounded-lg transition-colors"
                >
                  <Unlink className="w-4 h-4" />
                  Déconnecter
                </button>
              </div>
            ) : (
              <div className="space-y-3">
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={shopifyDomain}
                    onChange={(e) => setShopifyDomain(e.target.value)}
                    placeholder="ma-boutique.myshopify.com"
                    className="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg text-sm bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                  <button
                    onClick={handleShopifyConnect}
                    disabled={shopifyConnecting || !shopifyDomain.trim()}
                    className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-[#96bf48] hover:bg-[#7ea33a] rounded-lg transition-colors disabled:opacity-50"
                  >
                    {shopifyConnecting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Link2 className="w-4 h-4" />}
                    Connecter
                  </button>
                </div>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  Entrez le domaine de votre boutique Shopify puis autorisez l&apos;accès.
                </p>
              </div>
            )}
          </div>
"""
    # Insert before the catalog modal (showCatalogModal)
    modal_marker = '      {showCatalogModal && ('
    if modal_marker in content:
        content = content.replace(modal_marker, shopify_section + '\n' + modal_marker)
        print("  OK: Shopify UI section added")
    else:
        # Try alternative: insert before end of main container
        print("  WARN: Could not find catalog modal marker for Shopify UI insertion")

with open(CHANNELS_PAGE, 'w', encoding='utf-8') as f:
    f.write(content)

print("\n=== CLIENT MODULE COMPLETE ===")
