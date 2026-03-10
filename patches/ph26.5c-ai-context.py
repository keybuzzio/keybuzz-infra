#!/usr/bin/env python3
# PH26.5C: Add user context field to AI Suggestion panel

TARGET = '/opt/keybuzz/keybuzz-client/src/features/ai-ui/AISuggestionSlideOver.tsx'

with open(TARGET, 'r') as f:
    content = f.read()

# 1. Add state for userContext after other useState declarations
old_state = '''  const [copied, setCopied] = useState(false);
  const [inserted, setInserted] = useState(false);'''

new_state = '''  const [copied, setCopied] = useState(false);
  const [inserted, setInserted] = useState(false);
  // PH26.5C: User context for AI (manual input to supplement missing history)
  const [userContext, setUserContext] = useState('');
  const [showContextInput, setShowContextInput] = useState(false);'''

if old_state in content and 'PH26.5C' not in content:
    content = content.replace(old_state, new_state)
    print('OK: Added userContext state')
elif 'PH26.5C: User context' in content:
    print('INFO: PH26.5C state already added')
else:
    print('WARNING: Could not find state pattern to patch')

# 2. Update the assistAI call to include additionalContext
old_assist = '''      const result = await assistAI({
        tenantId,
        contextType: 'conversation',
        conversationId,
        payload: {
          messages: lastMessageText ? [{ role: 'customer', content: lastMessageText }] : [],
        },
      });'''

new_assist = '''      // PH26.5C: Include user context in AI payload
      const result = await assistAI({
        tenantId,
        contextType: 'conversation',
        conversationId,
        payload: {
          messages: lastMessageText ? [{ role: 'customer', content: lastMessageText }] : [],
          additionalContext: userContext || undefined,
        },
      });'''

if old_assist in content:
    content = content.replace(old_assist, new_assist)
    print('OK: Updated assistAI call with additionalContext')
elif 'additionalContext: userContext' in content:
    print('INFO: additionalContext already included')
else:
    print('WARNING: Could not find assistAI call pattern')

# 3. Add UI for context input - look for a good insertion point
# We'll add it after the generate button area
# Looking for the section with "Generer une suggestion"

# Find a pattern where we can insert the context textarea
ui_insert_pattern = '''              {/* Confidence */}'''

ui_context_block = '''              {/* PH26.5C: User Context Input */}
              <div className="mb-4">
                <button
                  type="button"
                  onClick={() => setShowContextInput(!showContextInput)}
                  className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400 hover:text-indigo-600 dark:hover:text-indigo-400"
                >
                  <span>{showContextInput ? 'â–¼' : 'â–¶'}</span>
                  <span>Ajouter du contexte (copier-coller Seller Central, etc.)</span>
                </button>
                {showContextInput && (
                  <div className="mt-2">
                    <textarea
                      value={userContext}
                      onChange={(e) => setUserContext(e.target.value)}
                      placeholder="Collez ici le contexte supplÃ©mentaire (messages Seller Central, historique, etc.)..."
                      className="w-full h-32 px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                    />
                    <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                      Ce contexte aide l'IA Ã  comprendre la situation. Non envoyÃ© Ã  Amazon.
                    </p>
                  </div>
                )}
              </div>

              {/* Confidence */}'''

if ui_insert_pattern in content and 'PH26.5C: User Context Input' not in content:
    content = content.replace(ui_insert_pattern, ui_context_block)
    print('OK: Added context textarea UI')
elif 'PH26.5C: User Context Input' in content:
    print('INFO: Context UI already added')
else:
    print('WARNING: Could not find UI insertion point')

# 4. Add badge showing context was added - in the response section
badge_pattern = '''              {response && ('''

badge_with_context = '''              {/* PH26.5C: Show badge if user context was provided */}
              {userContext && response && (
                <div className="mb-2 flex items-center gap-2 text-xs text-indigo-600 dark:text-indigo-400">
                  <span className="inline-flex items-center px-2 py-0.5 rounded bg-indigo-100 dark:bg-indigo-900/30">
                    âœ“ Contexte utilisateur inclus
                  </span>
                </div>
              )}
              
              {response && ('''

if badge_pattern in content and 'PH26.5C: Show badge' not in content:
    content = content.replace(badge_pattern, badge_with_context)
    print('OK: Added context badge')
elif 'PH26.5C: Show badge' in content:
    print('INFO: Context badge already added')
else:
    print('WARNING: Could not find badge insertion point')

with open(TARGET, 'w') as f:
    f.write(content)

print('Done')
