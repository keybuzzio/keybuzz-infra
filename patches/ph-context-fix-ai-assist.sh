#!/bin/bash
# PH-CONTEXT-FIX: Fix AI assistant to respect user-provided context
# Bug: User context (additionalContext) was being IGNORED when building prompts
# Fix: Always include additionalContext with explicit instructions to the LLM

set -e

TARGET="/opt/keybuzz/keybuzz-api/src/modules/ai/ai-assist-routes.ts"

echo "[PH-CONTEXT-FIX] Checking $TARGET..."

# Check if already patched
if grep -q "PH-CONTEXT-FIX" "$TARGET" 2>/dev/null; then
    echo "[PH-CONTEXT-FIX] Already applied"
    exit 0
fi

# Backup
cp "$TARGET" "${TARGET}.bak.$(date +%Y%m%d_%H%M%S)"
echo "[PH-CONTEXT-FIX] Backup created"

# Use sed to find and insert the userContextInstruction block
# We'll add it just before the "if (payload?.messages" line

# First, let's create a temporary file with the new code
cat > /tmp/context_fix_insert.txt << 'CONTEXTFIX'
    // PH-CONTEXT-FIX: Build user context instruction if provided
    let userContextInstruction = '';
    if (payload?.additionalContext && payload.additionalContext.trim()) {
      userContextInstruction = `

=== INSTRUCTIONS UTILISATEUR (OBLIGATOIRES) ===
L'utilisateur a fourni des instructions specifiques que tu DOIS respecter:
\${payload.additionalContext.trim()}

Tu DOIS:
- Appliquer ces instructions a la lettre
- Si l'utilisateur demande le tutoiement, utilise "tu" et pas "vous"
- Si l'utilisateur fournit une signature, utilise-la exactement comme indiquee
- Ne pas ignorer ces instructions
=== FIN DES INSTRUCTIONS ===
`;
      console.log(\`[AI Assist] \${requestId} User context provided: \${payload.additionalContext.length} chars\`);
    }

CONTEXTFIX

echo "[PH-CONTEXT-FIX] Applying patch..."

# Use Python for reliable text replacement
python3 << 'PYFIX'
import re

target = "/opt/keybuzz/keybuzz-api/src/modules/ai/ai-assist-routes.ts"

with open(target, 'r') as f:
    content = f.read()

# 1. Add userContextInstruction block before the if/else chain
# Find the line that starts with "    if (payload?.messages"
insert_before = "    if (payload?.messages && payload.messages.length > 0) {"
insert_code = '''    // PH-CONTEXT-FIX: Build user context instruction if provided
    let userContextInstruction = '';
    if (payload?.additionalContext && payload.additionalContext.trim()) {
      userContextInstruction = `

=== INSTRUCTIONS UTILISATEUR (OBLIGATOIRES) ===
L'utilisateur a fourni des instructions specifiques que tu DOIS respecter:
${payload.additionalContext.trim()}

Tu DOIS:
- Appliquer ces instructions a la lettre
- Si l'utilisateur demande le tutoiement, utilise "tu" et pas "vous"
- Si l'utilisateur fournit une signature, utilise-la exactement comme indiquee
- Ne pas ignorer ces instructions
=== FIN DES INSTRUCTIONS ===
`;
      console.log(`[AI Assist] ${requestId} User context provided: ${payload.additionalContext.length} chars`);
    }

'''

if insert_before in content:
    content = content.replace(insert_before, insert_code + insert_before)
    print("OK: Inserted userContextInstruction block")
else:
    print("ERROR: Could not find insertion point")
    exit(1)

# 2. Update the message push to include userContextInstruction
# First branch - payload.messages
old1 = 'content: `Conversation:\\n${conversationContext}\\n\\nPropose une reponse appropriee et une analyse.`,'
new1 = 'content: `Conversation:\\n${conversationContext}${userContextInstruction}\\n\\nPropose une reponse appropriee et une analyse.`,'
if old1 in content:
    # Only replace the first two occurrences (payload.messages and conversationMessages branches)
    content = content.replace(old1, new1, 2)
    print("OK: Updated conversation branches to include userContextInstruction")
else:
    print("WARNING: Conversation content pattern not found")

# 3. Update orderData branch
old2 = 'content: `Commande: ${JSON.stringify(payload.orderData, null, 2)}\\n\\nAnalyse cette commande et propose des actions.`,'
new2 = 'content: `Commande: ${JSON.stringify(payload.orderData, null, 2)}${userContextInstruction}\\n\\nAnalyse cette commande et propose des actions.`,'
if old2 in content:
    content = content.replace(old2, new2)
    print("OK: Updated orderData branch to include userContextInstruction")
else:
    print("WARNING: orderData content pattern not found")

with open(target, 'w') as f:
    f.write(content)

print("DONE: PH-CONTEXT-FIX applied successfully")
PYFIX

echo "[PH-CONTEXT-FIX] Done patching"

# Verify patch was applied
if grep -q "PH-CONTEXT-FIX" "$TARGET"; then
    echo "[PH-CONTEXT-FIX] Verified: patch applied successfully"
else
    echo "[PH-CONTEXT-FIX] ERROR: patch verification failed"
    exit 1
fi

echo ""
echo "=== Next steps ==="
echo "1. cd /opt/keybuzz/keybuzz-api"
echo "2. docker build -t ghcr.io/keybuzzio/keybuzz-api:v1.X.Y-ph-context-fix ."
echo "3. docker push ghcr.io/keybuzzio/keybuzz-api:v1.X.Y-ph-context-fix"
echo "4. Update K8s deployment with new tag"
echo "5. kubectl rollout restart deployment/keybuzz-api -n keybuzz-backend-dev"
