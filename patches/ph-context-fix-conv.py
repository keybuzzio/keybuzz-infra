#!/usr/bin/env python3
target = "/opt/keybuzz/keybuzz-api/src/modules/ai/ai-assist-routes.ts"

with open(target, 'r', encoding='utf-8') as f:
    content = f.read()

# Update conversation branches to include userContextInstruction
old1 = 'content: `Conversation:\\n${conversationContext}\\n\\nPropose une réponse appropriée et une analyse.`,'
new1 = 'content: `Conversation:\\n${conversationContext}${userContextInstruction}\\n\\nPropose une réponse appropriée et une analyse.`,'

count = content.count(old1)
print(f"Found {count} occurrences of conversation pattern")

if count > 0:
    content = content.replace(old1, new1)
    print(f"Replaced {count} occurrences")
    with open(target, 'w', encoding='utf-8') as f:
        f.write(content)
    print("DONE: Conversation branches updated")
else:
    # Check if already updated
    if '${conversationContext}${userContextInstruction}' in content:
        print("Already updated!")
    else:
        print("Pattern not found - checking alternatives...")
        # Try without the accent
        old2 = 'content: `Conversation:\\n${conversationContext}\\n\\nPropose une reponse appropriee et une analyse.`,'
        new2 = 'content: `Conversation:\\n${conversationContext}${userContextInstruction}\\n\\nPropose une reponse appropriee et une analyse.`,'
        
        count2 = content.count(old2)
        print(f"Found {count2} occurrences of no-accent pattern")
        
        if count2 > 0:
            content = content.replace(old2, new2)
            with open(target, 'w', encoding='utf-8') as f:
                f.write(content)
            print("DONE: Updated with no-accent pattern")
