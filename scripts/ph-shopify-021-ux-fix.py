#!/usr/bin/env python3
"""PH-SHOPIFY-02.1: UX fix — integrate Shopify into standard catalog/channel flow"""
import os, shutil

CLIENT = "/opt/keybuzz/keybuzz-client"
API = "/opt/keybuzz/keybuzz-api/src"

def backup(path):
    bak = path + '.bak-shopify-021'
    if not os.path.exists(bak):
        shutil.copy2(path, bak)

def patch(path, old, new, label):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    if old not in content:
        print(f"  WARN: [{label}] target not found in {path}")
        return False
    backup(path)
    content = content.replace(old, new, 1)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"  OK: {label}")
    return True

print("=== PH-SHOPIFY-02.1: UX FIX ===\n")

# ─────────────────────────────────────────────────────────────
# PART A: CLIENT — channels page
# ─────────────────────────────────────────────────────────────
PAGE = f"{CLIENT}/app/channels/page.tsx"
with open(PAGE, 'r', encoding='utf-8') as f:
    content = f.read()
backup(PAGE)

# ── A1: Remove dedicated Shopify block ──
# Find the block between the Catalog Modal comment and showCatalogModal
SHOPIFY_BLOCK_START = '          {/* \u2500\u2500 Shopify Connection \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */}'
SHOPIFY_BLOCK_END = "      {showCatalogModal && ("

if SHOPIFY_BLOCK_START in content:
    start_idx = content.index(SHOPIFY_BLOCK_START)
    end_idx = content.index(SHOPIFY_BLOCK_END, start_idx)
    # Remove everything between start and end (the Shopify block)
    content = content[:start_idx] + '\n' + content[end_idx:]
    print("  OK: A1 - Removed dedicated Shopify block")
else:
    print("  WARN: A1 - Shopify block marker not found")

# ── A2: Modify catalog entry click to detect Shopify ──
OLD_CATALOG_CLICK = 'onClick={() => handleAddChannel(entry.marketplace_key)}'
NEW_CATALOG_CLICK = """onClick={() => {
                          if (entry.provider === 'shopify') {
                            setShowCatalogModal(false);
                            setCatalogSearch('');
                            setShowShopifyModal(true);
                          } else {
                            handleAddChannel(entry.marketplace_key);
                          }
                        }}"""

if OLD_CATALOG_CLICK in content:
    content = content.replace(OLD_CATALOG_CLICK, NEW_CATALOG_CLICK, 1)
    print("  OK: A2 - Catalog click handler modified for Shopify")
else:
    print("  WARN: A2 - Catalog click handler not found")

# ── A3: Add Shopify buttons in channel cards ──
# After the Amazon active status span, add Shopify handling
AMAZON_ACTIVE = '''                  {ch.provider === "amazon" && ch.status === "active" && (
                    <span className="text-xs text-green-600 dark:text-green-400 flex items-center gap-1">'''

SHOPIFY_CHANNEL_BUTTONS = '''                  {ch.provider === "shopify" && ch.status === "pending" && (
                    <button
                      onClick={() => setShowShopifyModal(true)}
                      disabled={shopifyConnecting}
                      className="text-xs px-3 py-1.5 bg-[#96bf48] text-white rounded-lg hover:bg-[#7ea33a] disabled:opacity-50 inline-flex items-center gap-1"
                    >
                      {shopifyConnecting ? <Loader2 className="h-3 w-3 animate-spin" /> : <Link2 className="h-3 w-3" />}
                      Connecter Shopify
                    </button>
                  )}
                  {ch.provider === "shopify" && ch.status === "active" && (
                    <span className="text-xs text-green-600 dark:text-green-400 flex items-center gap-1">
                      <CheckCircle className="h-3 w-3" />
                      {shopifyStatus?.shopDomain || "Connect\u00e9"}
                    </span>
                  )}
'''

if AMAZON_ACTIVE in content:
    content = content.replace(AMAZON_ACTIVE, SHOPIFY_CHANNEL_BUTTONS + AMAZON_ACTIVE, 1)
    print("  OK: A3 - Shopify channel card buttons added")
else:
    print("  WARN: A3 - Amazon active marker not found")

# ── A4: Add Shopify disconnect in remove handler ──
OLD_REMOVE = 'if (ch.provider === "octopia" && ch.status === "active") handleOctopiaDisconnect();'
NEW_REMOVE = '''if (ch.provider === "octopia" && ch.status === "active") handleOctopiaDisconnect();
                          if (ch.provider === "shopify" && ch.status === "active") handleShopifyDisconnect();'''

if OLD_REMOVE in content:
    content = content.replace(OLD_REMOVE, NEW_REMOVE, 1)
    print("  OK: A4 - Shopify disconnect on remove added")
else:
    print("  WARN: A4 - Octopia remove handler not found")

# ── A5: Add Shopify connect modal (after Octopia modal) ──
# Find the end of the Octopia modal and insert the Shopify modal after it
OCTOPIA_MODAL_END = "      {/* \u2550\u2550\u2550 Octopia Connect Modal \u2550\u2550\u2550 */}"
SHOPIFY_MODAL = '''
      {/* ═══ Shopify Connect Modal ═══ */}
      {showShopifyModal && (
        <>
          <div className="fixed inset-0 bg-black/50 z-40" onClick={() => setShowShopifyModal(false)} />
          <div className="fixed inset-0 flex items-center justify-center z-50 p-4">
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-xl w-full max-w-md p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-3">
                  <img src="/marketplaces/shopify.svg" alt="Shopify" className="w-8 h-8" />
                  <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Connexion Shopify</h2>
                </div>
                <button onClick={() => setShowShopifyModal(false)} className="p-1 hover:bg-gray-100 dark:hover:bg-gray-700 rounded">
                  <X className="h-5 w-5 text-gray-500" />
                </button>
              </div>
              <div className="space-y-3 mb-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Domaine de la boutique</label>
                  <input
                    type="text"
                    value={shopifyDomain}
                    onChange={(e) => setShopifyDomain(e.target.value)}
                    placeholder="ma-boutique.myshopify.com"
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white text-sm focus:ring-2 focus:ring-blue-500"
                  />
                  <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                    Entrez le domaine Shopify de votre boutique (ex: ma-boutique.myshopify.com)
                  </p>
                </div>
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => setShowShopifyModal(false)}
                  className="flex-1 py-2 text-sm bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 font-medium"
                >
                  Annuler
                </button>
                <button
                  onClick={handleShopifyConnect}
                  disabled={shopifyConnecting || !shopifyDomain.trim()}
                  className="flex-1 py-2 text-sm bg-[#96bf48] text-white rounded-lg hover:bg-[#7ea33a] disabled:opacity-50 font-medium inline-flex items-center justify-center gap-1"
                >
                  {shopifyConnecting ? <Loader2 className="h-3 w-3 animate-spin" /> : null}
                  Connecter
                </button>
              </div>
            </div>
          </div>
        </>
      )}
'''

if OCTOPIA_MODAL_END in content:
    content = content.replace(OCTOPIA_MODAL_END, OCTOPIA_MODAL_END + SHOPIFY_MODAL, 1)
    print("  OK: A5 - Shopify connect modal added")
else:
    # Try without the exact comment
    # Look for the Octopia modal pattern end
    alt_marker = "showOctopiaModal && ("
    if alt_marker in content:
        # Find the end of the Octopia modal (closing </> tag pair)
        # Insert the Shopify modal after it
        print("  WARN: A5 - Exact Octopia comment not found, trying alternate insertion")
        # Find the last occurrence of the Octopia modal closing tag
        last_octopia_end = content.rfind("      {/* Octopia")
        if last_octopia_end > 0:
            content = content[:last_octopia_end] + SHOPIFY_MODAL + '\n' + content[last_octopia_end:]
            print("  OK: A5 - Shopify modal inserted (alternate)")
    else:
        print("  WARN: A5 - Could not find Octopia modal for Shopify modal insertion")

with open(PAGE, 'w', encoding='utf-8') as f:
    f.write(content)

print("\n  Client page patched.\n")

# ─────────────────────────────────────────────────────────────
# PART B: API — shopify callback activates tenant_channel
# ─────────────────────────────────────────────────────────────
print("[PART B] API: Patch shopify callback to activate tenant_channel")

ROUTES = f"{API}/modules/marketplaces/shopify/shopify.routes.ts"
with open(ROUTES, 'r', encoding='utf-8') as f:
    api_content = f.read()
backup(ROUTES)

# B1: Add import for channelsService
OLD_IMPORT = "import { normalizeShop, buildAuthUrl, storeOAuthState, popOAuthState, verifyHmac, exchangeToken, saveConnection, getStatus, disconnect } from './shopifyAuth.service';"
NEW_IMPORT = """import { normalizeShop, buildAuthUrl, storeOAuthState, popOAuthState, verifyHmac, exchangeToken, saveConnection, getStatus, disconnect } from './shopifyAuth.service';
import { addChannel, activateChannel } from '../../channels/channelsService';"""

if OLD_IMPORT in api_content:
    api_content = api_content.replace(OLD_IMPORT, NEW_IMPORT, 1)
    print("  OK: B1 - channelsService import added")
else:
    print("  WARN: B1 - Import marker not found")

# B2: After saveConnection in callback, add channel activation
OLD_CALLBACK_SAVE = """      await saveConnection(oauthState.tenantId, shop, tok.access_token, tok.scope);
      console.log(`[Shopify] Connected tenant=${oauthState.tenantId} shop=${shop}`);"""
NEW_CALLBACK_SAVE = """      const connId = await saveConnection(oauthState.tenantId, shop, tok.access_token, tok.scope);
      try {
        await addChannel(oauthState.tenantId, 'shopify-global');
        await activateChannel(oauthState.tenantId, 'shopify-global', undefined, connId);
      } catch (chErr: any) {
        console.warn('[Shopify] Channel activation warning:', chErr.message);
      }
      console.log(`[Shopify] Connected tenant=${oauthState.tenantId} shop=${shop}`);"""

if OLD_CALLBACK_SAVE in api_content:
    api_content = api_content.replace(OLD_CALLBACK_SAVE, NEW_CALLBACK_SAVE, 1)
    print("  OK: B2 - Channel activation added to callback")
else:
    print("  WARN: B2 - Callback save marker not found")

# B3: In disconnect, also deactivate tenant_channel
OLD_DISCONNECT = """  app.post('/disconnect', async (request, reply) => {
    const body = request.body as any || {};
    const tenantId = body.tenantId || request.headers['x-tenant-id'];
    if (!tenantId) return reply.status(400).send({ error: 'tenantId required' });
    try {
      const ok = await disconnect(tenantId as string);"""
NEW_DISCONNECT = """  app.post('/disconnect', async (request, reply) => {
    const body = request.body as any || {};
    const tenantId = body.tenantId || request.headers['x-tenant-id'];
    if (!tenantId) return reply.status(400).send({ error: 'tenantId required' });
    try {
      const ok = await disconnect(tenantId as string);
      try {
        const { getPool } = require('../../../config/database');
        const pool = await getPool();
        await pool.query("UPDATE tenant_channels SET status='removed', updated_at=NOW() WHERE tenant_id=$1 AND marketplace_key='shopify-global' AND status!='removed'", [tenantId]);
      } catch (_) {}"""

if OLD_DISCONNECT in api_content:
    api_content = api_content.replace(OLD_DISCONNECT, NEW_DISCONNECT, 1)
    print("  OK: B3 - Channel deactivation added to disconnect")
else:
    print("  WARN: B3 - Disconnect marker not found")

with open(ROUTES, 'w', encoding='utf-8') as f:
    f.write(api_content)

print("\n=== UX FIX COMPLETE ===")
print("Rebuild required for both API and Client.")
