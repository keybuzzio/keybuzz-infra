#!/usr/bin/env python3
"""
PH26.5L Fix: Improve context button visibility and fix encoding
"""

TARGET = '/opt/keybuzz/keybuzz-client/src/features/ai-ui/AISuggestionSlideOver.tsx'

with open(TARGET, 'r') as f:
    content = f.read()

# Fix 1: Replace unicode arrows with ChevronDown/ChevronRight icons (already imported)
old_button = """                  <button
                    type="button"
                    onClick={() => setShowContextInput(!showContextInput)}
                    className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400 hover:text-indigo-600 dark:hover:text-indigo-400 mb-2"
                  >
                    <span className="text-xs">{showContextInput ? 'Ã¢â€“Â¼' : 'Ã¢â€“Â¶'}</span>
                    <span>Ajouter du contexte (copier-coller Seller Central...)</span>
                  </button>"""

new_button = """                  <button
                    type="button"
                    onClick={() => setShowContextInput(!showContextInput)}
                    className="w-full flex items-center gap-2 px-3 py-2 text-sm font-medium text-indigo-600 dark:text-indigo-400 hover:bg-indigo-50 dark:hover:bg-indigo-900/20 rounded-lg border border-indigo-200 dark:border-indigo-800 mb-2 transition-colors"
                  >
                    {showContextInput ? <ChevronDown className="h-4 w-4" /> : <ChevronUp className="h-4 w-4 rotate-90" />}
                    <span>Ajouter du contexte (Seller Central, captures...)</span>
                  </button>"""

if old_button in content:
    content = content.replace(old_button, new_button)
    print('OK: Fixed context button style')
else:
    print('WARNING: Could not find old button pattern')

# Fix 2: Fix encoding issues in placeholder and other texts
fixes = [
    ('supplÃƒÂ©mentaire', 'supplÃ©mentaire'),
    ('l&apos;IA Ãƒ ', "l'IA Ã "),
    ('envoyÃƒÂ© Ãƒ ', 'envoyÃ© Ã '),
    ('caractÃƒÂ¨res ajoutÃƒÂ©s', 'caractÃ¨res ajoutÃ©s'),
    ('Ã¢Å“"', 'âœ“'),
    ('Ã¢Å¡ Ã¯Â¸', 'âš ï¸'),
]

for old, new in fixes:
    if old in content:
        content = content.replace(old, new)
        print(f'OK: Fixed encoding: {old[:20]}...')

with open(TARGET, 'w') as f:
    f.write(content)

print('Done')
