#!/bin/bash
# PH26.5L: Fix context button

TARGET="/opt/keybuzz/keybuzz-client/src/features/ai-ui/AISuggestionSlideOver.tsx"

# Backup
cp "$TARGET" "${TARGET}.bak.ph265l"

# Replace the entire button section using sed
# First, find the line with the button and replace

python3 << 'PYEOF'
import re

TARGET = '/opt/keybuzz/keybuzz-client/src/features/ai-ui/AISuggestionSlideOver.tsx'

with open(TARGET, 'r', encoding='utf-8', errors='replace') as f:
    content = f.read()

# Pattern to match the button regardless of unicode encoding issues
# Match from <button to </button>
pattern = r'(<button\s+type="button"\s+onClick=\{\(\) => setShowContextInput\(!showContextInput\)\}\s+className="flex items-center gap-2 text-sm[^"]*"\s*>\s*<span className="text-xs">\{showContextInput \? )[^}]+(} : )[^}]+(\}</span>\s*<span>Ajouter du contexte[^<]*</span>\s*</button>)'

replacement = r'''\1<ChevronDown className="h-4 w-4" />\2<ChevronUp className="h-4 w-4 rotate-90" />\3'''

new_content, count = re.subn(pattern, replacement, content, flags=re.DOTALL)

if count > 0:
    # Also fix the className for better visibility
    new_content = new_content.replace(
        'className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400 hover:text-indigo-600 dark:hover:text-indigo-400 mb-2"',
        'className="w-full flex items-center gap-2 px-3 py-2 text-sm font-medium text-indigo-600 dark:text-indigo-400 hover:bg-indigo-50 dark:hover:bg-indigo-900/20 rounded-lg border border-indigo-200 dark:border-indigo-800 mb-3 transition-colors"'
    )
    with open(TARGET, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print(f'OK: Fixed button ({count} replacement)')
else:
    print('WARNING: Pattern not found, trying alternate approach')
    # Alternate: just fix the span content directly
    # Replace any garbled unicode with proper JSX
    lines = content.split('\n')
    new_lines = []
    for i, line in enumerate(lines):
        if "showContextInput ? '" in line and "showContextInput : '" in line:
            # This is the problematic line, replace it entirely
            new_line = "                    {showContextInput ? <ChevronDown className=\"h-4 w-4\" /> : <ChevronUp className=\"h-4 w-4 rotate-90\" />}"
            new_lines.append(new_line)
            print(f'OK: Fixed line {i+1}')
        else:
            new_lines.append(line)
    
    new_content = '\n'.join(new_lines)
    with open(TARGET, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print('OK: Applied alternate fix')

PYEOF

echo "Done"
