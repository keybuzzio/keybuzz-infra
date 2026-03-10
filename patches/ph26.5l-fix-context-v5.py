#!/usr/bin/env python3
"""
PH26.5L: Fix context section - always visible, fix encoding, better wording
"""

TARGET = '/opt/keybuzz/keybuzz-client/src/features/ai-ui/AISuggestionSlideOver.tsx'

with open(TARGET, 'r') as f:
    content = f.read()

# 1. Remove the toggle button and make content always visible
# Replace the entire context section

old_section = '''              {/* PH26.5C: User Context Input */}
              {!hasResponse && !isLoading && (
                <div className="mb-4">
                  <button
                    type="button"
                    onClick={() => setShowContextInput(!showContextInput)}
                    className="w-full flex items-center gap-2 px-3 py-2 text-sm font-medium text-indigo-600 dark:text-indigo-400 hover:bg-indigo-50 dark:hover:bg-indigo-900/20 rounded-lg border border-indigo-200 dark:border-indigo-800 mb-3 transition-colors"
                  >
                    {showContextInput ? <ChevronDown className="h-4 w-4" /> : <ChevronUp className="h-4 w-4 rotate-90" />}
                    <span>Ajouter du contexte (copier-coller Seller Central...)</span>
                  </button>
                  {showContextInput && (
                    <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-3 border border-gray-200 dark:border-gray-700">
                      <textarea
                        value={userContext}
                        onChange={(e) => setUserContext(e.target.value)}
                        placeholder="Collez ici le contexte supplémentaire (messages Seller Central, historique, notes internes...)&#10;&#10;Ce contexte aide l&apos;IA à comprendre la situation."
                        className="w-full h-32 px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 resize-none"
                      />
                      <p className="mt-2 text-xs text-gray-500 dark:text-gray-400 flex items-center gap-1">
                        <span>⚠️</span>
                        <span>Ce contexte est envoyé à l&apos;IA mais pas à Amazon.</span>
                      </p>
                      {userContext && (
                        <div className="mt-2 flex items-center gap-2">
                          <span className="inline-flex items-center px-2 py-0.5 rounded text-xs bg-indigo-100 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300">
                            ✓ {userContext.length} caractères ajoutés
                          </span>
                        </div>
                      )}'''

new_section = '''              {/* PH26.5C + PH26.5L: User Context Input - Always visible */}
              {!hasResponse && !isLoading && (
                <div className="mb-4">
                  <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-3 border border-gray-200 dark:border-gray-700">
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      Contexte supplementaire (optionnel)
                    </label>
                    <textarea
                      value={userContext}
                      onChange={(e) => setUserContext(e.target.value)}
                      placeholder="Ajoutez des informations pour personnaliser la reponse IA :&#10;- Historique client, notes internes&#10;- Consignes specifiques (ton, politique...)&#10;- Tout element utile pour mieux repondre"
                      className="w-full h-28 px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 resize-none"
                    />
                    <p className="mt-2 text-xs text-gray-500 dark:text-gray-400">
                      Ces informations aident KeyBuzz IA a generer une reponse adaptee a votre situation.
                    </p>
                    {userContext && (
                      <div className="mt-2 flex items-center gap-2">
                        <span className="inline-flex items-center px-2 py-0.5 rounded text-xs bg-indigo-100 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300">
                          {userContext.length} caracteres ajoutes
                        </span>
                      </div>
                    )}'''

if old_section in content:
    content = content.replace(old_section, new_section)
    print('OK: Replaced context section (clean)')
else:
    # Try with mojibake encoding
    print('INFO: Trying with encoded characters...')
    
    # Read file again with different handling
    with open(TARGET, 'rb') as f:
        raw = f.read()
    
    content = raw.decode('utf-8', errors='replace')
    
    # Build patterns that match mojibake
    patterns_to_find = [
        ('Collez ici le contexte suppl', 'placeholder pattern'),
        ('showContextInput &&', 'toggle pattern'),
    ]
    
    # Just do line-by-line replacement
    lines = content.split('\n')
    new_lines = []
    skip_mode = False
    found_context_section = False
    
    for i, line in enumerate(lines):
        # Detect start of context section
        if 'PH26.5C: User Context Input' in line:
            found_context_section = True
            # Replace with new section header
            new_lines.append('              {/* PH26.5C + PH26.5L: User Context Input - Always visible */}')
            continue
        
        # Skip the toggle button entirely
        if found_context_section and '<button' in line and 'setShowContextInput' in line:
            skip_mode = True
            continue
        
        if skip_mode:
            if '</button>' in line:
                skip_mode = False
            continue
        
        # Skip the conditional wrapper for content
        if found_context_section and 'showContextInput &&' in line:
            continue
        
        # Fix textarea placeholder
        if 'placeholder=' in line and ('Collez' in line or 'contexte' in line.lower()):
            new_lines.append('                      placeholder="Ajoutez des informations pour personnaliser la reponse IA :&#10;- Historique client, notes internes&#10;- Consignes specifiques (ton, politique...)&#10;- Tout element utile pour mieux repondre"')
            print(f'OK: Fixed placeholder at line {i+1}')
            continue
        
        # Fix warning text
        if 'envoy' in line and 'IA' in line and 'Amazon' in line:
            new_lines.append('                      <p className="mt-2 text-xs text-gray-500 dark:text-gray-400">')
            new_lines.append('                        Ces informations aident KeyBuzz IA a generer une reponse adaptee.')
            new_lines.append('                      </p>')
            # Skip the next closing tag if it's part of this
            print(f'OK: Fixed warning text at line {i+1}')
            continue
        
        # Skip lines with mojibake warning icons
        if 'span' in line and ('⚠' in line or 'âš' in line):
            continue
        
        new_lines.append(line)
    
    content = '\n'.join(new_lines)

# Write the result
with open(TARGET, 'w', encoding='utf-8') as f:
    f.write(content)

print('Done')
