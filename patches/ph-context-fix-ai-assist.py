#!/usr/bin/env python3
"""
PH-CONTEXT-FIX: Fix AI assistant to respect user-provided context
Bug: User context (additionalContext) was being IGNORED when building prompts
Fix: Always include additionalContext with explicit instructions to the LLM
"""

import re

# Path on the server
TARGET = '/opt/keybuzz/keybuzz-api/src/modules/ai/ai-assist-routes.ts'

with open(TARGET, 'r', encoding='utf-8') as f:
    content = f.read()

# Check if already patched
if 'PH-CONTEXT-FIX' in content:
    print('INFO: PH-CONTEXT-FIX already applied')
    exit(0)

# Pattern to find the prompt construction section
old_pattern = r'''(    if \(payload\?\.messages && payload\.messages\.length > 0\) \{
      const conversationContext = payload\.messages
        \.map\(m => `\$\{m\.role === 'customer' \|\| m\.role === 'user' \? 'Client' : 'Agent'\}: \$\{m\.content\}`\)
        \.join\('\\n\\n'\);
      messages\.push\(\{
        role: 'user',
        content: `Conversation:\\n\$\{conversationContext\}\\n\\nPropose une reponse appropriee et une analyse\.`,
      \}\);
    \} else if \(conversationMessages\.length > 0\) \{
      const conversationContext = conversationMessages
        \.map\(m => `\$\{m\.role === 'user' \? 'Client' : 'Agent'\}: \$\{m\.content\}`\)
        \.join\('\\n\\n'\);
      messages\.push\(\{
        role: 'user',
        content: `Conversation:\\n\$\{conversationContext\}\\n\\nPropose une reponse appropriee et une analyse\.`,
      \}\);
    \} else if \(payload\?\.orderData\) \{
      messages\.push\(\{
        role: 'user',
        content: `Commande: \$\{JSON\.stringify\(payload\.orderData, null, 2\)\}\\n\\nAnalyse cette commande et propose des actions\.`,
      \}\);
    \} else \{
      messages\.push\(\{
        role: 'user',
        content: `Contexte \$\{contextType\} ID: \$\{effectiveConversationId\}\\n\$\{payload\?\.additionalContext \|\| 'Propose une assistance generale\.'\}`,
      \}\);
    \})'''

new_content = '''    // PH-CONTEXT-FIX: Build user context instruction if provided
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

    if (payload?.messages && payload.messages.length > 0) {
      const conversationContext = payload.messages
        .map(m => `${m.role === 'customer' || m.role === 'user' ? 'Client' : 'Agent'}: ${m.content}`)
        .join('\\n\\n');
      messages.push({
        role: 'user',
        content: `Conversation:\\n${conversationContext}${userContextInstruction}\\n\\nPropose une reponse appropriee et une analyse.`,
      });
    } else if (conversationMessages.length > 0) {
      const conversationContext = conversationMessages
        .map(m => `${m.role === 'user' ? 'Client' : 'Agent'}: ${m.content}`)
        .join('\\n\\n');
      messages.push({
        role: 'user',
        content: `Conversation:\\n${conversationContext}${userContextInstruction}\\n\\nPropose une reponse appropriee et une analyse.`,
      });
    } else if (payload?.orderData) {
      messages.push({
        role: 'user',
        content: `Commande: ${JSON.stringify(payload.orderData, null, 2)}${userContextInstruction}\\n\\nAnalyse cette commande et propose des actions.`,
      });
    } else {
      messages.push({
        role: 'user',
        content: `Contexte ${contextType} ID: ${effectiveConversationId}\\n${payload?.additionalContext || 'Propose une assistance generale.'}`,
      });
    }'''

# Try a simpler approach - find and replace specific lines
# First, let's find the exact location

# Pattern to locate where to add the context instruction
add_context_after = "const messages: Array<{ role: 'system' | 'user' | 'assistant'; content: string }> = ["
add_context_after_line = "    { role: 'system', content: buildSystemPrompt(contextType, orderContext) },"
add_context_after_end = "    ];"

# Find where to insert our userContextInstruction
# Insert after the messages array is created but before the if/else chain

# Let's use a simpler direct replacement approach
# Find the pattern where we push messages based on payload.messages

old_block = '''    if (payload?.messages && payload.messages.length > 0) {
      const conversationContext = payload.messages
        .map(m => `${m.role === 'customer' || m.role === 'user' ? 'Client' : 'Agent'}: ${m.content}`)
        .join('\\n\\n');
      messages.push({
        role: 'user',
        content: `Conversation:\\n${conversationContext}\\n\\nPropose une reponse appropriee et une analyse.`,
      });'''

new_block = '''    // PH-CONTEXT-FIX: Build user context instruction if provided
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
      console.log('[AI Assist] ' + requestId + ' User context provided: ' + payload.additionalContext.length + ' chars');
    }

    if (payload?.messages && payload.messages.length > 0) {
      const conversationContext = payload.messages
        .map(m => `${m.role === 'customer' || m.role === 'user' ? 'Client' : 'Agent'}: ${m.content}`)
        .join('\\n\\n');
      messages.push({
        role: 'user',
        content: `Conversation:\\n${conversationContext}${userContextInstruction}\\n\\nPropose une reponse appropriee et une analyse.`,
      });'''

if old_block in content:
    content = content.replace(old_block, new_block)
    print('OK: Added userContextInstruction before if block')
else:
    print('WARNING: Could not find first block pattern')
    print('Looking for alternate pattern...')
    # Try with different escaping
    if 'if (payload?.messages && payload.messages.length > 0)' in content:
        print('Found if block, but pattern mismatch')
    else:
        print('ERROR: if block not found at all')
        exit(1)

# Now update the other branches to use userContextInstruction
# Update else if (conversationMessages.length > 0)
old_conv = '''    } else if (conversationMessages.length > 0) {
      const conversationContext = conversationMessages
        .map(m => `${m.role === 'user' ? 'Client' : 'Agent'}: ${m.content}`)
        .join('\\n\\n');
      messages.push({
        role: 'user',
        content: `Conversation:\\n${conversationContext}\\n\\nPropose une reponse appropriee et une analyse.`,
      });'''

new_conv = '''    } else if (conversationMessages.length > 0) {
      const conversationContext = conversationMessages
        .map(m => `${m.role === 'user' ? 'Client' : 'Agent'}: ${m.content}`)
        .join('\\n\\n');
      messages.push({
        role: 'user',
        content: `Conversation:\\n${conversationContext}${userContextInstruction}\\n\\nPropose une reponse appropriee et une analyse.`,
      });'''

if old_conv in content:
    content = content.replace(old_conv, new_conv)
    print('OK: Updated conversationMessages branch')
else:
    print('WARNING: conversationMessages branch not found or already updated')

# Update else if (payload?.orderData)
old_order = '''    } else if (payload?.orderData) {
      messages.push({
        role: 'user',
        content: `Commande: ${JSON.stringify(payload.orderData, null, 2)}\\n\\nAnalyse cette commande et propose des actions.`,
      });'''

new_order = '''    } else if (payload?.orderData) {
      messages.push({
        role: 'user',
        content: `Commande: ${JSON.stringify(payload.orderData, null, 2)}${userContextInstruction}\\n\\nAnalyse cette commande et propose des actions.`,
      });'''

if old_order in content:
    content = content.replace(old_order, new_order)
    print('OK: Updated orderData branch')
else:
    print('WARNING: orderData branch not found or already updated')

with open(TARGET, 'w', encoding='utf-8') as f:
    f.write(content)

print('Done - PH-CONTEXT-FIX applied')
print('Next: rebuild and deploy keybuzz-api')
