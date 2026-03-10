#!/usr/bin/env python3
# PH26.5C: Add user context UI to AI Suggestion panel

TARGET = '/opt/keybuzz/keybuzz-client/src/features/ai-ui/AISuggestionSlideOver.tsx'

with open(TARGET, 'r') as f:
    content = f.read()

# Find the section where we show "Obtenir une suggestion" and add context input before it
old_pattern = '''              {/* PH25.10D: Actions-based prompt */}
              {!hasResponse && !isLoading && ('''

new_pattern = '''              {/* PH26.5C: User Context Input */}
              {!hasResponse && !isLoading && (
                <div className="mb-4">
                  <button
                    type="button"
                    onClick={() => setShowContextInput(!showContextInput)}
                    className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400 hover:text-indigo-600 dark:hover:text-indigo-400 mb-2"
                  >
                    <span className="text-xs">{showContextInput ? 'â–¼' : 'â–¶'}</span>
                    <span>Ajouter du contexte (copier-coller Seller Central...)</span>
                  </button>
                  {showContextInput && (
                    <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-3 border border-gray-200 dark:border-gray-700">
                      <textarea
                        value={userContext}
                        onChange={(e) => setUserContext(e.target.value)}
                        placeholder="Collez ici le contexte supplÃ©mentaire (messages Seller Central, historique, notes internes...)&#10;&#10;Ce contexte aide l'IA Ã  comprendre la situation."
                        className="w-full h-32 px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 resize-none"
                      />
                      <p className="mt-2 text-xs text-gray-500 dark:text-gray-400 flex items-center gap-1">
                        <span>âš ï¸</span>
                        <span>Ce contexte est envoyÃ© Ã  l'IA mais pas Ã  Amazon.</span>
                      </p>
                      {userContext && (
                        <div className="mt-2 flex items-center gap-2">
                          <span className="inline-flex items-center px-2 py-0.5 rounded text-xs bg-indigo-100 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300">
                            âœ“ {userContext.length} caractÃ¨res ajoutÃ©s
                          </span>
                        </div>
                      )}
                    </div>
                  )}
                </div>
              )}

              {/* PH25.10D: Actions-based prompt */}
              {!hasResponse && !isLoading && ('''

if old_pattern in content and 'PH26.5C: User Context Input' not in content:
    content = content.replace(old_pattern, new_pattern)
    print('OK: Added context UI before prompt section')
elif 'PH26.5C: User Context Input' in content:
    print('INFO: Context UI already added')
else:
    print('WARNING: Could not find UI insertion point')

# Add badge showing context was used in response
badge_pattern = '''              {/* Loading */}
              {isLoading && ('''

badge_with_context = '''              {/* PH26.5C: Badge showing context was included */}
              {userContext && hasResponse && (
                <div className="mb-3 flex items-center gap-2">
                  <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-indigo-100 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300 border border-indigo-200 dark:border-indigo-800">
                    âœ“ Contexte utilisateur inclus ({userContext.length} car.)
                  </span>
                </div>
              )}

              {/* Loading */}
              {isLoading && ('''

if badge_pattern in content and 'PH26.5C: Badge showing context' not in content:
    content = content.replace(badge_pattern, badge_with_context)
    print('OK: Added context badge')
elif 'PH26.5C: Badge showing context' in content:
    print('INFO: Context badge already added')
else:
    print('WARNING: Could not find badge insertion point')

with open(TARGET, 'w') as f:
    f.write(content)

print('Done')
