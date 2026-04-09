#!/bin/bash
# PH-PLAYBOOKS-V2: Patch playbooks/routes.ts
# Fix: Add auto-seed on GET if tenant has 0 playbooks
set -e

FILE="/opt/keybuzz/keybuzz-api/src/modules/playbooks/routes.ts"
cp "$FILE" "${FILE}.bak"

# Add import for seedStarterPlaybooks at the top (after existing imports)
sed -i "s|import { getPool } from '../../config/database';|import { getPool } from '../../config/database';\nimport { seedStarterPlaybooks } from '../../services/playbook-seed.service';|" "$FILE"

# Add auto-seed logic in the GET / handler, after the initial query
# We inject code after "const rules = await pool.query("
# Strategy: after fetching rules, if 0 rows, call seedStarterPlaybooks then re-fetch
cat > /tmp/autoseed_patch.py << 'PYEOF'
import re

with open("/opt/keybuzz/keybuzz-api/src/modules/playbooks/routes.ts", "r") as f:
    content = f.read()

old_block = """    const rules = await pool.query(
      'SELECT * FROM ai_rules WHERE tenant_id = $1 ORDER BY priority ASC, created_at DESC',
      [tenantId]
    );

    // Fetch conditions and actions for each rule
    const playbooks = [];"""

new_block = """    let rules = await pool.query(
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
    const playbooks = [];"""

content = content.replace(old_block, new_block)

with open("/opt/keybuzz/keybuzz-api/src/modules/playbooks/routes.ts", "w") as f:
    f.write(content)

print("Auto-seed patch applied")
PYEOF

python3 /tmp/autoseed_patch.py

echo "[PATCH] playbooks/routes.ts - auto-seed on empty tenant"
grep -n "Auto-seed" "$FILE" | head -3
echo "DONE"
