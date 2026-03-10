#!/bin/bash
# PH26.5L: Fix context button - direct replacement

TARGET="/opt/keybuzz/keybuzz-client/src/features/ai-ui/AISuggestionSlideOver.tsx"

# Create the new button section
cat > /tmp/new_button_section.txt << 'NEWBUTTON'
                  <button
                    type="button"
                    onClick={() => setShowContextInput(!showContextInput)}
                    className="w-full flex items-center gap-2 px-3 py-2 text-sm font-medium text-indigo-600 dark:text-indigo-400 hover:bg-indigo-50 dark:hover:bg-indigo-900/20 rounded-lg border border-indigo-200 dark:border-indigo-800 mb-3 transition-colors"
                  >
                    {showContextInput ? <ChevronDown className="h-4 w-4" /> : <ChevronUp className="h-4 w-4 rotate-90" />}
                    <span>Ajouter du contexte (Seller Central, captures...)</span>
                  </button>
NEWBUTTON

# Use python for safe replacement
python3 << 'PYEOF'
import re

TARGET = '/opt/keybuzz/keybuzz-client/src/features/ai-ui/AISuggestionSlideOver.tsx'

with open(TARGET, 'r') as f:
    content = f.read()

# New button code
new_button = '''                  <button
                    type="button"
                    onClick={() => setShowContextInput(!showContextInput)}
                    className="w-full flex items-center gap-2 px-3 py-2 text-sm font-medium text-indigo-600 dark:text-indigo-400 hover:bg-indigo-50 dark:hover:bg-indigo-900/20 rounded-lg border border-indigo-200 dark:border-indigo-800 mb-3 transition-colors"
                  >
                    {showContextInput ? <ChevronDown className="h-4 w-4" /> : <ChevronUp className="h-4 w-4 rotate-90" />}
                    <span>Ajouter du contexte (Seller Central, captures...)</span>
                  </button>'''

# Pattern to find the old button (match anything between <button and </button> for context input)
# Use a simple approach: find the specific line pattern and replace
lines = content.split('\n')
new_lines = []
skip_until_close = False
button_start_idx = -1

for i, line in enumerate(lines):
    if 'onClick={() => setShowContextInput(!showContextInput)}' in line:
        # Found the button, mark to replace
        button_start_idx = i - 1  # The <button line is one before
        skip_until_close = True
        continue
    
    if skip_until_close:
        if '</button>' in line:
            # End of button, insert new button
            new_lines.append(new_button)
            skip_until_close = False
            print(f'OK: Replaced button (lines {button_start_idx+1}-{i+1})')
        continue
    
    if button_start_idx >= 0 and i == button_start_idx:
        # Skip the <button line
        continue
    
    new_lines.append(line)

if button_start_idx == -1:
    print('WARNING: Button not found')
else:
    with open(TARGET, 'w') as f:
        f.write('\n'.join(new_lines))
    print('OK: File updated')

PYEOF

echo "Verifying..."
grep -n "Ajouter du contexte" "$TARGET" | head -3
