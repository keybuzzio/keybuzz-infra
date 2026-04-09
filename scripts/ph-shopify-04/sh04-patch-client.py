#!/usr/bin/env python3
"""
PH-SHOPIFY-04 — Client patches for OrderSidePanel Shopify enrichment.
Adds payment status and fulfillment status display for Shopify orders.
"""
import os

CLIENT_DIR = '/opt/keybuzz/keybuzz-client'

# =============================================
# OrderSidePanel.tsx — Add Shopify-specific fields
# =============================================
print('\n=== OrderSidePanel.tsx — Shopify enrichment ===')

OSP_FILE = os.path.join(CLIENT_DIR, 'src/features/inbox/components/OrderSidePanel.tsx')

with open(OSP_FILE, 'r') as f:
    content = f.read()

# 1. Add Shopify-specific optional fields to OrderSummary interface
OLD_INTERFACE = """  totalAmount: number;
  currency: string;
}"""

NEW_INTERFACE = """  totalAmount: number;
  currency: string;
  shopifyPaymentStatus?: string | null;
  shopifyFulfillmentStatus?: string | null;
}"""

if OLD_INTERFACE in content and 'shopifyPaymentStatus' not in content:
    content = content.replace(OLD_INTERFACE, NEW_INTERFACE, 1)
    print('[OK] OrderSummary interface — Shopify fields added')
else:
    print('[SKIP] Shopify fields already present or pattern not found')


# 2. Add Shopify payment/fulfillment display block after the delivery section
# Insert a new section between "Livraison" and "Articles" when channel is shopify
OLD_ARTICLES_SECTION = """        {/* Articles */}
        {order.products && order.products.length > 0 && ("""

SHOPIFY_STATUS_BLOCK = """        {/* PH-SHOPIFY-04: Shopify Status */}
        {order.channel === 'shopify' && (order.shopifyPaymentStatus || order.shopifyFulfillmentStatus) && (
          <div className="bg-white dark:bg-gray-800 rounded-xl p-4 border border-gray-200 dark:border-gray-700 shadow-sm">
            <h4 className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-3 flex items-center gap-1">
              <CreditCard className="h-3.5 w-3.5" />
              Statut Shopify
            </h4>
            <div className="space-y-2">
              {order.shopifyPaymentStatus && (
                <div className="flex items-center justify-between">
                  <span className="text-xs text-gray-500 dark:text-gray-400">Paiement</span>
                  <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${
                    order.shopifyPaymentStatus === 'PAID' ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400' :
                    order.shopifyPaymentStatus === 'PENDING' ? 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400' :
                    order.shopifyPaymentStatus === 'REFUNDED' ? 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400' :
                    order.shopifyPaymentStatus === 'PARTIALLY_REFUNDED' ? 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-400' :
                    'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-400'
                  }`}>
                    {order.shopifyPaymentStatus === 'PAID' ? 'Pay\\u00e9' :
                     order.shopifyPaymentStatus === 'PENDING' ? 'En attente' :
                     order.shopifyPaymentStatus === 'REFUNDED' ? 'Rembours\\u00e9' :
                     order.shopifyPaymentStatus === 'PARTIALLY_REFUNDED' ? 'Partiellement rembours\\u00e9' :
                     order.shopifyPaymentStatus === 'VOIDED' ? 'Annul\\u00e9' :
                     order.shopifyPaymentStatus}
                  </span>
                </div>
              )}
              {order.shopifyFulfillmentStatus && (
                <div className="flex items-center justify-between">
                  <span className="text-xs text-gray-500 dark:text-gray-400">Fulfillment</span>
                  <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${
                    order.shopifyFulfillmentStatus === 'FULFILLED' ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400' :
                    order.shopifyFulfillmentStatus === 'IN_PROGRESS' ? 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400' :
                    order.shopifyFulfillmentStatus === 'UNFULFILLED' ? 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400' :
                    'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-400'
                  }`}>
                    {order.shopifyFulfillmentStatus === 'FULFILLED' ? 'Exp\\u00e9di\\u00e9' :
                     order.shopifyFulfillmentStatus === 'IN_PROGRESS' ? 'En cours' :
                     order.shopifyFulfillmentStatus === 'UNFULFILLED' ? 'Non exp\\u00e9di\\u00e9' :
                     order.shopifyFulfillmentStatus === 'PARTIALLY_FULFILLED' ? 'Partiellement exp\\u00e9di\\u00e9' :
                     order.shopifyFulfillmentStatus}
                  </span>
                </div>
              )}
            </div>
          </div>
        )}

"""

if OLD_ARTICLES_SECTION in content and 'Statut Shopify' not in content:
    content = content.replace(OLD_ARTICLES_SECTION, SHOPIFY_STATUS_BLOCK + OLD_ARTICLES_SECTION, 1)
    print('[OK] OrderSidePanel — Shopify status block added')
else:
    print('[SKIP] Shopify status block (already present or pattern not found)')

with open(OSP_FILE, 'w') as f:
    f.write(content)

print('\n========================================')
print('CLIENT PATCHES APPLIED SUCCESSFULLY')
print('========================================')
