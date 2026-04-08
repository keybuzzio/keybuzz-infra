#!/usr/bin/env python3
"""
PH-PLAYBOOKS-V2: Apply all 4 patches
1. API engine: remove 'commande' from tracking_request keywords
2. API seed: set starter-plan playbooks to 'active' by default
3. API routes: add auto-seed on empty tenant
4. BFF simulate: fix tracking keyword + days_late
"""
import os
import shutil
import sys

def backup(path):
    bak = path + '.bak-pb-v2'
    if not os.path.exists(bak):
        shutil.copy2(path, bak)
        print(f"  Backup: {bak}")

def patch_file(path, old, new, label):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    if old not in content:
        print(f"  WARNING: patch target not found in {path} for [{label}]")
        print(f"  Looking for: {repr(old[:80])}")
        return False
    content = content.replace(old, new, 1)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"  OK: {label}")
    return True

# ============================================================
# PATCH 1: playbook-engine.service.ts — remove 'commande'
# ============================================================
print("\n=== PATCH 1: playbook-engine.service.ts ===")
f1 = "/opt/keybuzz/keybuzz-api/src/services/playbook-engine.service.ts"
backup(f1)

patch_file(f1,
    "keywords: ['suivi', 'tracking', 'colis', 'livraison', 'commande'],",
    "keywords: ['suivi', 'tracking', 'colis', 'livraison'],",
    "Remove 'commande' from tracking_request keywords"
)

# ============================================================
# PATCH 2: playbook-seed.service.ts — active status for starters
# ============================================================
print("\n=== PATCH 2: playbook-seed.service.ts ===")
f2 = "/opt/keybuzz/keybuzz-api/src/services/playbook-seed.service.ts"
backup(f2)

# Change the INSERT to compute status based on min_plan
patch_file(f2,
    """      await client.query(
        `INSERT INTO ai_rules (id, tenant_id, name, description, mode, status, priority, channel, trigger_type, scope, intelligence_level, min_plan, is_starter, created_at, updated_at)
         VALUES ($1, $2, $3, $4, 'suggest', 'disabled', $5, null, $6, $7, $8, $9, true, NOW(), NOW())`,
        [ruleId, tenantId, pb.name, pb.description, pb.priority, pb.trigger_type, pb.scope, pb.intelligence_level, pb.min_plan]""",
    """      const seedStatus = pb.min_plan === 'starter' ? 'active' : 'disabled';
      await client.query(
        `INSERT INTO ai_rules (id, tenant_id, name, description, mode, status, priority, channel, trigger_type, scope, intelligence_level, min_plan, is_starter, created_at, updated_at)
         VALUES ($1, $2, $3, $4, 'suggest', $10, $5, null, $6, $7, $8, $9, true, NOW(), NOW())`,
        [ruleId, tenantId, pb.name, pb.description, pb.priority, pb.trigger_type, pb.scope, pb.intelligence_level, pb.min_plan, seedStatus]""",
    "Seed: starter-plan playbooks default to 'active'"
)

# ============================================================
# PATCH 3: playbooks/routes.ts — auto-seed + import
# ============================================================
print("\n=== PATCH 3: playbooks/routes.ts ===")
f3 = "/opt/keybuzz/keybuzz-api/src/modules/playbooks/routes.ts"
backup(f3)

# Add import
patch_file(f3,
    "import { getPool } from '../../config/database';",
    "import { getPool } from '../../config/database';\nimport { seedStarterPlaybooks } from '../../services/playbook-seed.service';",
    "Add seedStarterPlaybooks import"
)

# Add auto-seed logic
patch_file(f3,
    """    const pool = await getPool();
    const rules = await pool.query(
      'SELECT * FROM ai_rules WHERE tenant_id = $1 ORDER BY priority ASC, created_at DESC',
      [tenantId]
    );

    // Fetch conditions and actions for each rule
    const playbooks = [];""",
    """    const pool = await getPool();
    let rules = await pool.query(
      'SELECT * FROM ai_rules WHERE tenant_id = $1 ORDER BY priority ASC, created_at DESC',
      [tenantId]
    );

    // Auto-seed starter playbooks if tenant has none
    if (rules.rows.length === 0) {
      try {
        await seedStarterPlaybooks(tenantId);
        rules = await pool.query(
          'SELECT * FROM ai_rules WHERE tenant_id = $1 ORDER BY priority ASC, created_at DESC',
          [tenantId]
        );
        console.log(`[Playbooks] Auto-seeded ${rules.rows.length} starters for ${tenantId}`);
      } catch (seedErr: any) {
        console.error('[Playbooks] Auto-seed failed:', seedErr.message);
      }
    }

    // Fetch conditions and actions for each rule
    const playbooks = [];""",
    "Auto-seed on empty tenant GET"
)

# ============================================================
# PATCH 4: BFF simulate/route.ts — fix keywords + days_late
# ============================================================
print("\n=== PATCH 4: BFF simulate/route.ts ===")
f4 = "/opt/keybuzz/keybuzz-client/app/api/playbooks/[id]/simulate/route.ts"
backup(f4)

# Fix 4a: Remove 'commande' from tracking_request keywords
patch_file(f4,
    "keywords: ['suivi', 'tracking', 'colis', 'livraison', 'commande'],",
    "keywords: ['suivi', 'tracking', 'colis', 'livraison'],",
    "BFF: Remove 'commande' from tracking_request keywords"
)

# Fix 4b: Add daysLate to body destructuring
patch_file(f4,
    "const { messageContent, tenantId, channel, orderStatus, hasTracking, orderAmount } = body;",
    "const { messageContent, tenantId, channel, orderStatus, hasTracking, orderAmount, daysLate } = body;",
    "BFF: Add daysLate to body destructuring"
)

# Fix 4c: Use daysLate from body instead of hardcoded 0
patch_file(f4,
    """      case 'days_late':
        actual = 0;
        break;""",
    """      case 'days_late':
        actual = Number(daysLate) || 0;
        break;""",
    "BFF: Use daysLate from request body"
)

print("\n=== ALL PATCHES APPLIED ===")
print("Files modified:")
print(f"  1. {f1}")
print(f"  2. {f2}")
print(f"  3. {f3}")
print(f"  4. {f4}")
