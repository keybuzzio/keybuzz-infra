#!/usr/bin/env python3
"""
PH-AUTOPILOT-SHOPIFY: Patch autopilot engine.ts for Shopify support
4 modifications:
  A. Outbound delivery routing for Shopify (provider=smtp)
  B. Inject Marketplace Intelligence into system prompt
  C. Enrich user prompt with Shopify context
  D. Channel-aware fulfillment info (replace FBA/FBM hardcode)
"""

import sys

TARGET = "/opt/keybuzz/keybuzz-api/src/modules/autopilot/engine.ts"

with open(TARGET, "r") as f:
    content = f.read()

original = content
changes = 0

# === A. Add Shopify outbound delivery routing ===
OLD_OUTBOUND = "else if (channel === 'email' && targetAddress.includes('@')) provider = 'smtp';"
NEW_OUTBOUND = """else if (channel === 'email' && targetAddress.includes('@')) provider = 'smtp';
      else if (channel === 'shopify') provider = 'smtp';"""

if OLD_OUTBOUND in content and "channel === 'shopify'" not in content.split(OLD_OUTBOUND)[1][:100]:
    content = content.replace(OLD_OUTBOUND, NEW_OUTBOUND, 1)
    changes += 1
    print("[A] Outbound Shopify routing added")
else:
    print("[A] SKIP - already patched or pattern not found")

# === B. Add import for marketplace intelligence ===
OLD_IMPORT = "} from '../ai/shared-ai-context';"
NEW_IMPORT = """} from '../ai/shared-ai-context';
import { analyzeMarketplaceContext, buildMarketplaceIntelligenceBlock } from '../../services/marketplaceIntelligenceEngine';"""

if "analyzeMarketplaceContext" not in content:
    content = content.replace(OLD_IMPORT, NEW_IMPORT, 1)
    changes += 1
    print("[B1] Marketplace intelligence import added")
else:
    print("[B1] SKIP - import already present")

# === B2. Inject marketplace intelligence block into system prompt ===
OLD_SYSTEM_PROMPT_END = """- Au lieu de "Je n'ai pas votre numéro de commande" → "Pourriez-vous me communiquer votre numéro de commande ? Je pourrai ainsi vérifier votre dossier immédiatement."`;"""

NEW_SYSTEM_PROMPT_END = """- Au lieu de "Je n'ai pas votre numéro de commande" → "Pourriez-vous me communiquer votre numéro de commande ? Je pourrai ainsi vérifier votre dossier immédiatement."`;

    // PH-AUTOPILOT-SHOPIFY: Inject marketplace intelligence into system prompt
    try {
      const mpCtx = analyzeMarketplaceContext({
        channel: context.channel || 'unknown',
        customerIntent: 'GENERAL',
        deliveryStatus: orderContext?.deliveryStatus || 'UNKNOWN',
      });
      const mpBlock = buildMarketplaceIntelligenceBlock(mpCtx);
      if (mpBlock) {
        systemPrompt += '\\n\\n' + mpBlock;
      }
    } catch (mpErr) {
      console.log('[Autopilot] Marketplace intelligence injection skipped:', mpErr.message);
    }"""

if "analyzeMarketplaceContext({" not in content.split("systemPrompt")[3] if content.count("systemPrompt") > 3 else True:
    if OLD_SYSTEM_PROMPT_END in content and "PH-AUTOPILOT-SHOPIFY: Inject marketplace" not in content:
        content = content.replace(OLD_SYSTEM_PROMPT_END, NEW_SYSTEM_PROMPT_END, 1)
        changes += 1
        print("[B2] Marketplace intelligence injection added after system prompt")
    else:
        print("[B2] SKIP - pattern not found or already patched")
else:
    print("[B2] SKIP - already present")

# === C. Enrich user prompt with Shopify context ===
# Insert after the products block and before the carrier/tracking block
OLD_CARRIER_BLOCK = """      if (orderContext.carrier || orderContext.trackingCode) {"""

NEW_SHOPIFY_CONTEXT_PLUS_CARRIER = """      // PH-AUTOPILOT-SHOPIFY: Inject Shopify-specific order context
      if (orderContext.channel === 'shopify' && orderContext.shopifyContext) {
        const sc = orderContext.shopifyContext;
        userPrompt += `\\n\\n--- CONTEXTE SHOPIFY ---
Statut paiement: ${sc.paymentStatus || 'Non disponible'}
Statut fulfillment: ${sc.fulfillmentStatus || 'Non disponible'}
Indicateur remboursement: ${sc.refundIndicator || 'none'}
Nombre d\\'articles: ${sc.itemCount || 0}
Tracking disponible: ${sc.hasTracking ? 'Oui' : 'Non'}
Remboursement partiel: ${sc.isPartiallyRefunded ? 'Oui' : 'Non'}
Remboursement total: ${sc.isFullyRefunded ? 'Oui' : 'Non'}`;
      }

      if (orderContext.carrier || orderContext.trackingCode) {"""

if "CONTEXTE SHOPIFY" not in content.split("userPrompt")[0] if "userPrompt" in content else True:
    if OLD_CARRIER_BLOCK in content and "PH-AUTOPILOT-SHOPIFY: Inject Shopify" not in content:
        content = content.replace(OLD_CARRIER_BLOCK, NEW_SHOPIFY_CONTEXT_PLUS_CARRIER, 1)
        changes += 1
        print("[C] Shopify context enrichment added to user prompt")
    else:
        print("[C] SKIP - pattern not found or already patched")
else:
    print("[C] SKIP - already present")

# === D. Channel-aware fulfillment info ===
OLD_FULFILLMENT = """Mode d'expédition: ${orderContext.fulfillmentChannel === 'AFN' ? 'Expédié par Amazon (FBA)' : 'Expédié par le vendeur (FBM)'}"""

NEW_FULFILLMENT = """Mode d'expédition: ${orderContext.channel === 'shopify' ? (orderContext.shopifyContext?.fulfillmentStatus || 'Shopify standard') : (orderContext.channel === 'amazon' ? (orderContext.fulfillmentChannel === 'AFN' ? 'Expédié par Amazon (FBA)' : 'Expédié par le vendeur (FBM)') : (orderContext.fulfillmentChannel || 'Standard'))}"""

if OLD_FULFILLMENT in content:
    content = content.replace(OLD_FULFILLMENT, NEW_FULFILLMENT, 1)
    changes += 1
    print("[D] Channel-aware fulfillment info applied")
else:
    print("[D] SKIP - pattern not found or already patched")

# === Write result ===
if changes > 0:
    # systemPrompt must be let not const for B2 to work (we append to it)
    if "const systemPrompt = `Tu es" in content and "let systemPrompt = `Tu es" not in content:
        content = content.replace("const systemPrompt = `Tu es", "let systemPrompt = `Tu es", 1)
        print("[B2-fix] Changed const systemPrompt to let systemPrompt")
    
    with open(TARGET, "w") as f:
        f.write(content)
    print(f"\n=== {changes} patches applied successfully ===")
else:
    print("\n=== No changes needed ===")

sys.exit(0)
