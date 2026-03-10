#!/usr/bin/env python3
"""
PH26.5L: Fix context button - simple line replacement
"""

TARGET = '/opt/keybuzz/keybuzz-client/src/features/ai-ui/AISuggestionSlideOver.tsx'

with open(TARGET, 'r') as f:
    lines = f.readlines()

new_lines = []
for i, line in enumerate(lines):
    # Fix the line with unicode arrows
    if "showContextInput ? '" in line and "span" in line:
        # Replace this specific line
        new_line = "                    {showContextInput ? <ChevronDown className=\"h-4 w-4\" /> : <ChevronUp className=\"h-4 w-4 rotate-90\" />}\n"
        new_lines.append(new_line)
        print(f'OK: Fixed line {i+1} (unicode arrows)')
    # Improve button styling
    elif 'className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400 hover:text-indigo-600 dark:hover:text-indigo-400 mb-2"' in line:
        new_line = line.replace(
            'className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400 hover:text-indigo-600 dark:hover:text-indigo-400 mb-2"',
            'className="w-full flex items-center gap-2 px-3 py-2 text-sm font-medium text-indigo-600 dark:text-indigo-400 hover:bg-indigo-50 dark:hover:bg-indigo-900/20 rounded-lg border border-indigo-200 dark:border-indigo-800 mb-3 transition-colors"'
        )
        new_lines.append(new_line)
        print(f'OK: Fixed line {i+1} (button styling)')
    else:
        new_lines.append(line)

with open(TARGET, 'w') as f:
    f.writelines(new_lines)

print('Done - file updated')
