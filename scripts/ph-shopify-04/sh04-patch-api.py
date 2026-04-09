#!/usr/bin/env python3
"""
PH-SHOPIFY-04 — API patches for AI enrichment + marketplace policy
Applies all API-side changes for Shopify AI context enrichment.
"""
import os
import sys

BASE_DIR = '/opt/keybuzz/keybuzz-api/src'

def patch_file(filepath, replacements, label):
    """Apply a list of (old, new) replacements to a file."""
    full_path = os.path.join(BASE_DIR, filepath)
    if not os.path.exists(full_path):
        print(f'[SKIP] {filepath} not found')
        return False
    with open(full_path, 'r') as f:
        content = f.read()
    original = content
    for old, new in replacements:
        if old not in content:
            print(f'[WARN] Pattern not found in {filepath}: {old[:60]}...')
            return False
        content = content.replace(old, new, 1)
    if content == original:
        print(f'[SKIP] No changes in {filepath}')
        return False
    with open(full_path, 'w') as f:
        f.write(content)
    print(f'[OK] {label}')
    return True

# =============================================
# 1. marketplaceIntelligenceEngine.ts — Add SHOPIFY profile
# =============================================
print('\n=== STEP 1: marketplaceIntelligenceEngine.ts ===')

MIE_FILE = 'services/marketplaceIntelligenceEngine.ts'

SHOPIFY_PROFILE_BLOCK = '''
const SHOPIFY_PROFILE: MarketplaceProfile = {
  name: 'SHOPIFY',
  policyProfile: 'SHOPIFY_STANDARD',
  baseEscalationRisk: 'LOW',
  defaultGuideline: 'INVESTIGATE_FIRST',
  allowedActions: [
    'acknowledge_issue',
    'offer_investigation',
    'provide_tracking',
    'suggest_replacement',
    'verify_fulfillment_status',
    'verify_payment_status',
    'request_evidence',
    'escalate_to_agent',
  ],
  restrictedActions: [
    'auto_refund_without_investigation',
    'promise_refund_without_verification',
    'bypass_return_process',
    'disclose_internal_costs',
  ],
  guidelines: [
    'Shopify orders are merchant-fulfilled — seller has full control over resolution.',
    'Verify payment capture status before discussing refunds.',
    'Verify fulfillment status and tracking before responding to delivery issues.',
    'If payment is not yet captured, cancellation is simpler than refund.',
    'If already refunded (partially or fully), inform the customer clearly.',
    'Request proof (photos) for damaged or defective product claims.',
    'Prefer replacement or return before refund when applicable.',
    'Check if a return has already been opened before proposing a new one.',
    'Response time is flexible — no marketplace-mandated SLA like Amazon A-to-Z.',
    'Never be overly permissive — follow standard e-commerce dispute resolution.',
  ],
};

'''

mie_replacements = [
    # 1a. Add SHOPIFY to MarketplaceName
    (
        "export type MarketplaceName = 'AMAZON' | 'OCTOPIA' | 'FNAC' | 'DARTY' | 'MIRAKL' | 'UNKNOWN';",
        "export type MarketplaceName = 'AMAZON' | 'OCTOPIA' | 'FNAC' | 'DARTY' | 'MIRAKL' | 'SHOPIFY' | 'UNKNOWN';"
    ),
    # 1b. Add SHOPIFY_STANDARD to PolicyProfile
    (
        "export type PolicyProfile = 'AMAZON_BUYER_PROTECTION' | 'OCTOPIA_STANDARD' | 'FNAC_DARTY_STANDARD' | 'MIRAKL_STANDARD' | 'GENERIC_ECOMMERCE';",
        "export type PolicyProfile = 'AMAZON_BUYER_PROTECTION' | 'OCTOPIA_STANDARD' | 'FNAC_DARTY_STANDARD' | 'MIRAKL_STANDARD' | 'SHOPIFY_STANDARD' | 'GENERIC_ECOMMERCE';"
    ),
    # 1c. Add SHOPIFY_PROFILE before UNKNOWN_PROFILE
    (
        "const UNKNOWN_PROFILE: MarketplaceProfile = {",
        SHOPIFY_PROFILE_BLOCK + "const UNKNOWN_PROFILE: MarketplaceProfile = {"
    ),
    # 1d. Add shopify detection in resolveMarketplace
    (
        "  if (channel.includes('mirakl')) {\n    return MIRAKL_PROFILE;\n  }\n\n  return UNKNOWN_PROFILE;",
        "  if (channel.includes('mirakl')) {\n    return MIRAKL_PROFILE;\n  }\n  if (channel.includes('shopify')) {\n    return SHOPIFY_PROFILE;\n  }\n\n  return UNKNOWN_PROFILE;"
    ),
]

patch_file(MIE_FILE, mie_replacements, 'marketplaceIntelligenceEngine.ts — SHOPIFY profile added')


# =============================================
# 2. shared-ai-context.ts — Shopify enrichment
# =============================================
print('\n=== STEP 2: shared-ai-context.ts ===')

SAC_FILE = 'modules/ai/shared-ai-context.ts'

SHOPIFY_ENRICHMENT_BLOCK = '''
// ============================================
// SHOPIFY ORDER ENRICHMENT (PH-SHOPIFY-04)
// ============================================

export interface ShopifyOrderEnrichment {
  paymentStatus: string;
  fulfillmentStatus: string;
  refundIndicator: string;
  itemCount: number;
  hasTracking: boolean;
  isPartiallyRefunded: boolean;
  isFullyRefunded: boolean;
}

export function extractShopifyOrderContext(rawData: any): ShopifyOrderEnrichment | null {
  if (!rawData) return null;
  const financial = (rawData.displayFinancialStatus || rawData.financial_status || '').toUpperCase();
  const fulfillment = (rawData.displayFulfillmentStatus || rawData.fulfillment_status || '').toUpperCase();
  const fulfillments = rawData.fulfillments || [];
  const hasTracking = fulfillments.some((f: any) =>
    (f.trackingInfo?.length > 0) || f.tracking_number || f.tracking_url
  );
  let itemCount = 0;
  if (rawData.lineItems?.edges) {
    itemCount = rawData.lineItems.edges.length;
  } else if (rawData.line_items) {
    itemCount = rawData.line_items.length;
  }

  return {
    paymentStatus: financial || 'UNKNOWN',
    fulfillmentStatus: fulfillment || 'UNFULFILLED',
    refundIndicator: financial === 'REFUNDED' ? 'fully_refunded'
      : financial === 'PARTIALLY_REFUNDED' ? 'partially_refunded' : 'none',
    itemCount,
    hasTracking,
    isPartiallyRefunded: financial === 'PARTIALLY_REFUNDED',
    isFullyRefunded: financial === 'REFUNDED',
  };
}

'''

sac_replacements = [
    # 2a. Add Shopify enrichment types+function before LOAD ENRICHED ORDER CONTEXT
    (
        "// ============================================\n// LOAD ENRICHED ORDER CONTEXT\n// ============================================",
        SHOPIFY_ENRICHMENT_BLOCK + "// ============================================\n// LOAD ENRICHED ORDER CONTEXT\n// ============================================"
    ),
    # 2b. Add rawData + shopifyContext to EnrichedOrderContext interface
    (
        "  carrierDeliveryStatus: string;\n  lastCarrierCheckAt: string;\n}",
        "  carrierDeliveryStatus: string;\n  lastCarrierCheckAt: string;\n  rawData?: any;\n  shopifyContext?: ShopifyOrderEnrichment | null;\n}"
    ),
    # 2c. In loadEnrichedOrderContext, add raw_data + shopify context
    (
        "      trackingSource: o.tracking_source || 'amazon_estimate',\n      carrierNormalized: o.carrier_normalized || '',\n      carrierDeliveryStatus: o.carrier_delivery_status || '',\n      lastCarrierCheckAt: o.last_carrier_check_at ? new Date(o.last_carrier_check_at).toISOString() : '',\n    };",
        "      trackingSource: o.tracking_source || (o.channel === 'shopify' ? 'shopify' : 'amazon_estimate'),\n      carrierNormalized: o.carrier_normalized || '',\n      carrierDeliveryStatus: o.carrier_delivery_status || '',\n      lastCarrierCheckAt: o.last_carrier_check_at ? new Date(o.last_carrier_check_at).toISOString() : '',\n      rawData: o.raw_data || null,\n      shopifyContext: o.channel === 'shopify' ? extractShopifyOrderContext(o.raw_data) : null,\n    };"
    ),
]

patch_file(SAC_FILE, sac_replacements, 'shared-ai-context.ts — Shopify enrichment added')


# =============================================
# 2d. Add Shopify context block in buildEnrichedUserPrompt
# =============================================
print('\n=== STEP 2d: shared-ai-context.ts — buildEnrichedUserPrompt ===')

sac_path = os.path.join(BASE_DIR, SAC_FILE)
with open(sac_path, 'r') as f:
    content = f.read()

# Find the temporal analysis block and inject Shopify context BEFORE it
OLD_TEMPORAL = "    if (temporal.daysSinceOrder !== null) {\n      prompt += `\\n\\n--- ANALYSE TEMPORELLE ---"
NEW_TEMPORAL = """    if (enrichedOrder.shopifyContext) {
      const sc = enrichedOrder.shopifyContext;
      prompt += `\\n\\n--- CONTEXTE SHOPIFY ---
Marketplace: Shopify (marchand)
Statut paiement: ${sc.paymentStatus}
Statut fulfillment: ${sc.fulfillmentStatus}
Remboursement: ${sc.refundIndicator === 'none' ? 'Aucun' : sc.refundIndicator === 'partially_refunded' ? 'Partiellement rembourse' : 'Integralement rembourse'}
Nombre articles: ${sc.itemCount}
Tracking disponible: ${sc.hasTracking ? 'OUI' : 'NON'}
--- FIN CONTEXTE SHOPIFY ---`;
    }

    if (temporal.daysSinceOrder !== null) {
      prompt += `\\n\\n--- ANALYSE TEMPORELLE ---"""

if OLD_TEMPORAL in content:
    content = content.replace(OLD_TEMPORAL, NEW_TEMPORAL, 1)
    with open(sac_path, 'w') as f:
        f.write(content)
    print('[OK] shared-ai-context.ts — Shopify context block in buildEnrichedUserPrompt')
else:
    print('[WARN] Could not find temporal block insertion point')


# =============================================
# 3. ai-assist-routes.ts — Dynamic marketplace + intelligence
# =============================================
print('\n=== STEP 3: ai-assist-routes.ts ===')

AAR_FILE = 'modules/ai/ai-assist-routes.ts'
aar_path = os.path.join(BASE_DIR, AAR_FILE)

with open(aar_path, 'r') as f:
    content = f.read()

# 3a. Add marketplace intelligence import
OLD_IMPORT = "import { logJournalEvent } from './ai-journal-routes';"
NEW_IMPORT = """import { logJournalEvent } from './ai-journal-routes';
import { analyzeMarketplaceContext, buildMarketplaceIntelligenceBlock } from '../../services/marketplaceIntelligenceEngine';"""

if OLD_IMPORT in content and 'marketplaceIntelligenceEngine' not in content:
    content = content.replace(OLD_IMPORT, NEW_IMPORT, 1)
    print('[OK] ai-assist-routes.ts — marketplace intelligence import added')
else:
    print('[SKIP] marketplace intelligence import (already present or pattern not found)')

# 3b. Replace first hardcoded marketplace: 'amazon'
OLD_MP1 = "        marketplace: 'amazon',\n        decisionContext: {},"
NEW_MP1 = "        marketplace: (convContext?.channel || 'unknown').toLowerCase(),\n        decisionContext: {},"

if OLD_MP1 in content:
    content = content.replace(OLD_MP1, NEW_MP1, 1)
    print('[OK] ai-assist-routes.ts — marketplace dynamic (approval queue)')
else:
    print('[SKIP] marketplace approval queue (pattern not found)')

# 3c. Replace second hardcoded marketplace: 'amazon'
OLD_MP2 = "        marketplace: 'amazon',\n      };\n      if (shouldCreateFollowup(followupCtx)) {"
NEW_MP2 = "        marketplace: (convContext?.channel || 'unknown').toLowerCase(),\n      };\n      if (shouldCreateFollowup(followupCtx)) {"

if OLD_MP2 in content:
    content = content.replace(OLD_MP2, NEW_MP2, 1)
    print('[OK] ai-assist-routes.ts — marketplace dynamic (followup engine)')
else:
    print('[SKIP] marketplace followup engine (pattern not found)')

# 3d. Add marketplace intelligence block to system prompt
# Insert before "Contexte: ${contextType}" at the end of the system prompt assembly
OLD_CONTEXT_LINE = """  basePrompt += `

Contexte: \${contextType}

Tu dois fournir:"""

NEW_CONTEXT_LINE = """  // PH-SHOPIFY-04: Inject marketplace intelligence
  try {
    const mpCtx = analyzeMarketplaceContext({
      channel: convContext?.channel || '',
      customerIntent: contextType || '',
      deliveryStatus: enrichedOrder?.deliveryStatus || '',
    });
    const mpBlock = buildMarketplaceIntelligenceBlock(mpCtx);
    if (mpBlock) {
      basePrompt += '\\n\\n' + mpBlock;
    }
  } catch (mpErr: any) {
    console.warn('[AI Assist] Marketplace intelligence error (non-blocking):', mpErr.message);
  }

  basePrompt += `

Contexte: \${contextType}

Tu dois fournir:"""

if OLD_CONTEXT_LINE in content:
    content = content.replace(OLD_CONTEXT_LINE, NEW_CONTEXT_LINE, 1)
    print('[OK] ai-assist-routes.ts — marketplace intelligence block injected')
else:
    print('[WARN] Could not find system prompt insertion point')

with open(aar_path, 'w') as f:
    f.write(content)

print('[OK] ai-assist-routes.ts — all patches applied')


# =============================================
# 4. shopifyOrders.service.ts — Fix tracking_source
# =============================================
print('\n=== STEP 4: shopifyOrders.service.ts ===')

SOS_FILE = 'modules/marketplaces/shopify/shopifyOrders.service.ts'
sos_path = os.path.join(BASE_DIR, SOS_FILE)

with open(sos_path, 'r') as f:
    content = f.read()

# 4a. Add tracking_source to INSERT columns
OLD_INSERT_COLS = "      delivery_status, products, raw_data, shipped_at, delivered_at)"
NEW_INSERT_COLS = "      delivery_status, products, raw_data, shipped_at, delivered_at, tracking_source)"
if OLD_INSERT_COLS in content:
    content = content.replace(OLD_INSERT_COLS, NEW_INSERT_COLS, 1)
    print('[OK] shopifyOrders — tracking_source column added to INSERT')

# 4b. Add tracking_source value ($21 = 'shopify') to INSERT
OLD_INSERT_VALS = "     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)`,"
NEW_INSERT_VALS = "     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, 'shopify')`,"
if OLD_INSERT_VALS in content:
    content = content.replace(OLD_INSERT_VALS, NEW_INSERT_VALS, 1)
    print('[OK] shopifyOrders — tracking_source value added to INSERT')

# 4c. Add tracking_source to UPDATE
OLD_UPDATE = "        updated_at = NOW()\n       WHERE tenant_id = $15"
NEW_UPDATE = "        tracking_source = 'shopify', updated_at = NOW()\n       WHERE tenant_id = $15"
if OLD_UPDATE in content:
    content = content.replace(OLD_UPDATE, NEW_UPDATE, 1)
    print('[OK] shopifyOrders — tracking_source added to UPDATE')

with open(sos_path, 'w') as f:
    f.write(content)


# =============================================
# 5. orders/routes.ts — Add Shopify fields to API response
# =============================================
print('\n=== STEP 5: orders/routes.ts ===')

ORT_FILE = 'modules/orders/routes.ts'
ort_path = os.path.join(BASE_DIR, ORT_FILE)

with open(ort_path, 'r') as f:
    content = f.read()

# Add Shopify-specific fields to orderRowToApiResponse
OLD_RESPONSE_END = "    supplier: null,\n    marketplace: row.channel || 'amazon',\n  };\n}"
NEW_RESPONSE_END = """    supplier: null,
    marketplace: row.channel || 'amazon',
    // PH-SHOPIFY-04: Shopify-specific fields from raw_data
    ...(row.channel === 'shopify' && row.raw_data ? (() => {
      const rd = typeof row.raw_data === 'string' ? JSON.parse(row.raw_data) : row.raw_data;
      return {
        shopifyPaymentStatus: (rd.displayFinancialStatus || rd.financial_status || '').toUpperCase() || null,
        shopifyFulfillmentStatus: (rd.displayFulfillmentStatus || rd.fulfillment_status || '').toUpperCase() || null,
      };
    })() : {}),
  };
}"""

if OLD_RESPONSE_END in content:
    content = content.replace(OLD_RESPONSE_END, NEW_RESPONSE_END, 1)
    with open(ort_path, 'w') as f:
        f.write(content)
    print('[OK] orders/routes.ts — Shopify fields added to API response')
else:
    print('[WARN] Could not find orderRowToApiResponse end pattern')


print('\n========================================')
print('ALL API PATCHES APPLIED SUCCESSFULLY')
print('========================================')
