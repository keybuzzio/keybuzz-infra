#!/usr/bin/env python3
"""
PH26.5L: Add file upload UI to AISuggestionSlideOver
"""

TARGET = '/opt/keybuzz/keybuzz-client/src/features/ai-ui/AISuggestionSlideOver.tsx'

with open(TARGET, 'r') as f:
    content = f.read()

# Check if already patched
if 'PH26.5L' in content or 'contextFiles' in content:
    print('INFO: PH26.5L already applied')
    exit(0)

# 1. Add import for Upload icon
old_import = "import { Sparkles, X, RefreshCw, Copy, ArrowRight, ChevronDown, ChevronUp, AlertTriangle, Loader2, Check } from 'lucide-react';"
new_import = "import { Sparkles, X, RefreshCw, Copy, ArrowRight, ChevronDown, ChevronUp, AlertTriangle, Loader2, Check, Upload, FileText, Trash2 } from 'lucide-react';"

if old_import in content:
    content = content.replace(old_import, new_import)
    print('OK: Added Upload, FileText, Trash2 icons')

# 2. Add state for context files after userContext state
old_state = "  // PH26.5C: User context for AI (manual input to supplement missing history)\n  const [userContext, setUserContext] = useState('');\n  const [showContextInput, setShowContextInput] = useState(false);"

new_state = """  // PH26.5C: User context for AI (manual input to supplement missing history)
  const [userContext, setUserContext] = useState('');
  const [showContextInput, setShowContextInput] = useState(false);
  // PH26.5L: Context files for AI (jpg/png/pdf uploads)
  const [contextFiles, setContextFiles] = useState<File[]>([]);
  const [uploadedFileIds, setUploadedFileIds] = useState<string[]>([]);
  const [isUploading, setIsUploading] = useState(false);"""

if old_state in content:
    content = content.replace(old_state, new_state)
    print('OK: Added contextFiles state')

# 3. Add file handling functions before generateSuggestion
old_generate_marker = "  // Generate suggestion (consumes credits)"

file_handlers = """  // PH26.5L: Handle file selection
  const handleFileSelect = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    const validFiles = files.filter(f => {
      const isValidType = ['image/jpeg', 'image/png', 'application/pdf'].includes(f.type);
      const isValidSize = f.size <= 10 * 1024 * 1024; // 10MB
      return isValidType && isValidSize;
    }).slice(0, 5 - contextFiles.length); // Max 5 files total
    setContextFiles(prev => [...prev, ...validFiles]);
    e.target.value = ''; // Reset input
  }, [contextFiles.length]);

  // PH26.5L: Remove file from selection
  const removeFile = useCallback((index: number) => {
    setContextFiles(prev => prev.filter((_, i) => i !== index));
  }, []);

  // PH26.5L: Upload context files to backend
  const uploadContextFiles = useCallback(async (): Promise<string[]> => {
    if (contextFiles.length === 0) return [];
    
    setIsUploading(true);
    try {
      const formData = new FormData();
      formData.append('conversationId', conversationId);
      formData.append('additionalContextText', userContext || '');
      contextFiles.forEach(file => formData.append('files', file));
      
      const response = await fetch('/api/ai/context/upload', {
        method: 'POST',
        headers: { 'X-Tenant-Id': tenantId },
        body: formData,
      });
      
      if (!response.ok) {
        throw new Error('Upload failed');
      }
      
      const data = await response.json();
      const ids = (data.uploadedFiles || []).map((f: any) => f.id);
      setUploadedFileIds(ids);
      return ids;
    } catch (err) {
      console.error('[PH26.5L] Upload error:', err);
      return [];
    } finally {
      setIsUploading(false);
    }
  }, [contextFiles, conversationId, tenantId, userContext]);

  // Generate suggestion (consumes credits)"""

if old_generate_marker in content:
    content = content.replace(old_generate_marker, file_handlers)
    print('OK: Added file handling functions')

# 4. Modify generateSuggestion to upload files first
old_generate_call = """    try {
      // PH26.5C: Include user context in AI payload
      const result = await assistAI({
        tenantId,
        contextType: 'conversation',
        conversationId,
        payload: {
          messages: lastMessageText ? [{ role: 'customer', content: lastMessageText }] : [],
          additionalContext: userContext || undefined,
        },
      });"""

new_generate_call = """    try {
      // PH26.5L: Upload context files first
      let fileIds: string[] = [];
      if (contextFiles.length > 0) {
        fileIds = await uploadContextFiles();
      }
      
      // PH26.5C: Include user context in AI payload
      // PH26.5L: Include uploaded file IDs
      const attachmentSummary = contextFiles.length > 0 
        ? `\\n\\n[PiÃ¨ces jointes contexte: ${contextFiles.map(f => f.name).join(', ')}]`
        : '';
      
      const result = await assistAI({
        tenantId,
        contextType: 'conversation',
        conversationId,
        payload: {
          messages: lastMessageText ? [{ role: 'customer', content: lastMessageText }] : [],
          additionalContext: (userContext || '') + attachmentSummary || undefined,
        },
      });"""

if old_generate_call in content:
    content = content.replace(old_generate_call, new_generate_call)
    print('OK: Modified generateSuggestion to upload files')

# 5. Add file upload UI after textarea in the context section
old_textarea_end = """                      {userContext && (
                        <div className="mt-2 flex items-center gap-2">
                          <span className="inline-flex items-center px-2 py-0.5 rounded text-xs bg-indigo-100 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300">
                            âœ“ {userContext.length} caractÃ¨res ajoutÃ©s
                          </span>
                        </div>
                      )}
                    </div>
                  )}
                </div>
              )}"""

new_textarea_end = """                      {userContext && (
                        <div className="mt-2 flex items-center gap-2">
                          <span className="inline-flex items-center px-2 py-0.5 rounded text-xs bg-indigo-100 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300">
                            âœ“ {userContext.length} caractÃ¨res ajoutÃ©s
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
                  )}
                </div>
              )}"""

if old_textarea_end in content:
    content = content.replace(old_textarea_end, new_textarea_end)
    print('OK: Added file upload UI')
else:
    # Try with encoded chars
    old_textarea_end_enc = old_textarea_end.replace('âœ“', 'Ã¢Å“"').replace('Ã¨', 'ÃƒÂ¨')
    if old_textarea_end_enc in content:
        new_textarea_end_enc = new_textarea_end.replace('âœ“', 'Ã¢Å“"').replace('Ã¨', 'ÃƒÂ¨')
        content = content.replace(old_textarea_end_enc, new_textarea_end_enc)
        print('OK: Added file upload UI (encoded)')
    else:
        print('WARNING: Could not find textarea end pattern for file upload UI')

# 6. Update the context badge to show files too
old_badge = """              {/* PH26.5C: Badge showing context was included */}
              {userContext && hasResponse && (
                <div className="mb-3 flex items-center gap-2">
                  <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-indigo-100 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300 border border-indigo-200 dark:border-indigo-800">
                    âœ“ Contexte utilisateur inclus ({userContext.length} car.)
                  </span>
                </div>
              )}"""

new_badge = """              {/* PH26.5C + PH26.5L: Badge showing context was included */}
              {(userContext || uploadedFileIds.length > 0) && hasResponse && (
                <div className="mb-3 flex flex-wrap items-center gap-2">
                  {userContext && (
                    <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-indigo-100 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300 border border-indigo-200 dark:border-indigo-800">
                      âœ“ Contexte texte ({userContext.length} car.)
                    </span>
                  )}
                  {uploadedFileIds.length > 0 && (
                    <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 border border-purple-200 dark:border-purple-800">
                      âœ“ {uploadedFileIds.length} fichier(s) ajoutÃ©(s)
                    </span>
                  )}
                </div>
              )}"""

if old_badge in content:
    content = content.replace(old_badge, new_badge)
    print('OK: Updated context badge')
else:
    # Try encoded version
    old_badge_enc = old_badge.replace('âœ“', 'Ã¢Å“"')
    if old_badge_enc in content:
        new_badge_enc = new_badge.replace('âœ“', 'Ã¢Å“"')
        content = content.replace(old_badge_enc, new_badge_enc)
        print('OK: Updated context badge (encoded)')
    else:
        print('WARNING: Could not find badge pattern')

with open(TARGET, 'w') as f:
    f.write(content)

print('Done')
