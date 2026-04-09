#!/usr/bin/env python3
"""Fix: Move Shopify handlers before the main return statement"""
f = "/opt/keybuzz/keybuzz-client/app/channels/page.tsx"
with open(f, 'r', encoding='utf-8') as fh:
    lines = fh.readlines()

# Find the handler block (starts with "  // ── Shopify" and ends before "  return (")
handler_start = None
handler_end = None
for i, line in enumerate(lines):
    if '// ── Shopify' in line and handler_start is None:
        handler_start = i
    if handler_start and i > handler_start and line.strip().startswith('return ('):
        handler_end = i
        break

if handler_start is None:
    print("WARN: Could not find Shopify handler block")
    exit(1)

# Extract the handler block
handler_block = lines[handler_start:handler_end]
print(f"Found handler block: lines {handler_start+1}-{handler_end+1} ({len(handler_block)} lines)")

# Remove the handler block from current position
del lines[handler_start:handler_end]

# Now find the FIRST 'return (' that is the main component return
# (should be after the octopia handlers and before JSX)
# Look for the pattern: line starts with "  return (" that has JSX after it
main_return_idx = None
for i, line in enumerate(lines):
    # Find the octopia disconnect handler, then the next 'return (' is our target
    if 'handleOctopiaDisconnect' in line and 'const' in line:
        # The main return is somewhere after this
        for j in range(i+1, len(lines)):
            if lines[j].strip() == 'return (':
                main_return_idx = j
                break
        break

if main_return_idx is None:
    # Fallback: find the second 'return (' (first is early return for loading, second is main)
    returns = [i for i, l in enumerate(lines) if l.strip() == 'return (']
    if len(returns) >= 2:
        main_return_idx = returns[1]
    else:
        print("WARN: Could not find main return statement")
        exit(1)

print(f"Inserting handlers before line {main_return_idx+1}")

# Insert handler block before the main return
lines = lines[:main_return_idx] + ['\n'] + handler_block + lines[main_return_idx:]

with open(f, 'w', encoding='utf-8') as fh:
    fh.writelines(lines)

print("OK: Shopify handlers moved to correct position")
