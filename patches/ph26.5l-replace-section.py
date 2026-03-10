#!/usr/bin/env python3
"""
PH26.5L: Replace entire context section
"""

TARGET = '/opt/keybuzz/keybuzz-client/src/features/ai-ui/AISuggestionSlideOver.tsx'

# New section content
NEW_SECTION = '''              {/* PH26.5C + PH26.5L: User Context Input - Always visible */}
              {!hasResponse && !isLoading && (
                <div className="mb-4">
                  <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-3 border border-gray-200 dark:border-gray-700">
                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                      Contexte supplementaire (optionnel)
                    </label>
                    <textarea
                      value={userContext}
                      onChange={(e) => setUserContext(e.target.value)}
                      placeholder="Donnez des informations pour personnaliser la reponse :&#10;- Historique client, notes internes&#10;- Consignes (ton, politique de retour...)&#10;- Ligne directive pour cette reponse"
                      className="w-full h-24 px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 resize-none"
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
                    )}
                      
                    {/* PH26.5L: File upload */}
                    <div className="mt-3 pt-3 border-t border-gray-200 dark:border-gray-700">
                      <label className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400 cursor-pointer hover:text-indigo-600 dark:hover:text-indigo-400">
                        <Upload className="h-4 w-4" />
                        <span>Ajouter des fichiers (jpg, png, pdf - max 10Mo)</span>
                        <input
                          type="file"
                          accept=".jpg,.jpeg,.png,.pdf"
                          multiple
                          onChange={handleFileSelect}
                          className="hidden"
                          disabled={contextFiles.length >= 5}
                        />
                      </label>
                        
                      {contextFiles.length > 0 && (
                        <div className="mt-2 space-y-1">
                          {contextFiles.map((file, idx) => (
                            <div key={idx} className="flex items-center justify-between gap-2 px-2 py-1 bg-gray-100 dark:bg-gray-800 rounded text-sm">
                              <div className="flex items-center gap-2 min-w-0">
                                <FileText className="h-4 w-4 text-gray-400 flex-shrink-0" />
                                <span className="truncate text-gray-700 dark:text-gray-300">{file.name}</span>
                                <span className="text-xs text-gray-500">({(file.size / 1024).toFixed(0)} Ko)</span>
                              </div>
                              <button
                                onClick={() => removeFile(idx)}
                                className="p-1 text-gray-400 hover:text-red-500"
                              >
                                <Trash2 className="h-3 w-3" />
                              </button>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              )}

'''

with open(TARGET, 'r') as f:
    lines = f.readlines()

new_lines = []
skip_until_actions = False
start_line = -1

for i, line in enumerate(lines):
    # Find start of context section
    if 'PH26.5C: User Context Input' in line:
        start_line = i
        skip_until_actions = True
        # Insert new section
        new_lines.append(NEW_SECTION)
        print(f'OK: Found start at line {i+1}, inserting new section')
        continue
    
    # Skip until we find the actions section
    if skip_until_actions:
        if 'PH25.10D: Actions-based prompt' in line:
            skip_until_actions = False
            new_lines.append('              {/* PH25.10D: Actions-based prompt */}\n')
            print(f'OK: Found end at line {i+1}')
            continue
        else:
            continue  # Skip this line
    
    new_lines.append(line)

if start_line == -1:
    print('ERROR: Could not find context section start')
    exit(1)

with open(TARGET, 'w') as f:
    f.writelines(new_lines)

print('Done - section replaced')
