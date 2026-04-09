#!/bin/bash
# PH-PLAYBOOKS-V2: Patch playbook-seed.service.ts
# Fix: Set 8 key starters to 'active' instead of all 'disabled'
# Active: tracking_request(1), tracking_request(2), delivery_delay(3), 
#         return_request(4), payment_declined(6), defective_product(7),
#         invoice_request(9), order_cancelled(10)
# Disabled: negative_sentiment(5), wrong_description(8), 
#           incompatible_product(11), off_topic(12), vip_client(13),
#           unanswered_timeout(14), escalation_needed(15)
set -e

FILE="/opt/keybuzz/keybuzz-api/src/services/playbook-seed.service.ts"
cp "$FILE" "${FILE}.bak"

# Replace the single INSERT that creates all as 'disabled' with logic that sets status per priority
# Strategy: change the INSERT to use a computed status based on min_plan
# Starter playbooks (min_plan = 'starter') → 'active'  
# Pro/Autopilot playbooks (min_plan = 'pro' or 'autopilot') → 'disabled'
sed -i "s/VALUES (\$1, \$2, \$3, \$4, 'suggest', 'disabled', \$5, null, \$6, \$7, \$8, \$9, true, NOW(), NOW())/VALUES (\$1, \$2, \$3, \$4, 'suggest', CASE WHEN \$9 = 'starter' THEN 'active' ELSE 'disabled' END, \$5, null, \$6, \$7, \$8, \$9, true, NOW(), NOW())/" "$FILE"

echo "[PATCH] playbook-seed.service.ts - starter plan playbooks now default to 'active'"
grep "VALUES" "$FILE" | head -3
echo "DONE"
