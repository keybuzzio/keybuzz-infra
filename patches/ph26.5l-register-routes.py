#!/usr/bin/env python3
"""
PH26.5L: Register AI context upload routes in main.ts
"""

TARGET = '/opt/keybuzz/keybuzz-backend/src/main.ts'

with open(TARGET, 'r') as f:
    content = f.read()

# Check if already registered
if 'aiContextUpload' in content or 'PH26.5L' in content:
    print('INFO: PH26.5L routes already registered')
    exit(0)

# Add import after other route imports
# Look for the last route import
import_marker = "import { registerAiTestRoutes }"
if import_marker in content:
    insert_pos = content.find(import_marker)
    end_of_line = content.find('\n', insert_pos)
    new_import = "\nimport { registerAiContextUploadRoutes } from './modules/ai/aiContextUpload.routes'; // PH26.5L"
    content = content[:end_of_line+1] + new_import + content[end_of_line+1:]
    print('OK: Added import for aiContextUpload.routes')
else:
    # Try alternative - find module imports section
    alt_marker = "import { registerAttachmentsRoutes }"
    if alt_marker in content:
        insert_pos = content.find(alt_marker)
        end_of_line = content.find('\n', insert_pos)
        new_import = "\nimport { registerAiContextUploadRoutes } from './modules/ai/aiContextUpload.routes'; // PH26.5L"
        content = content[:end_of_line+1] + new_import + content[end_of_line+1:]
        print('OK: Added import after attachments routes')
    else:
        print('WARNING: Could not find import marker, adding at top')
        content = "import { registerAiContextUploadRoutes } from './modules/ai/aiContextUpload.routes'; // PH26.5L\n" + content

# Add route registration
# Look for registerAiTestRoutes call
register_marker = "registerAiTestRoutes(app)"
if register_marker in content:
    insert_pos = content.find(register_marker)
    end_of_line = content.find('\n', insert_pos)
    new_register = "\n  registerAiContextUploadRoutes(app); // PH26.5L"
    content = content[:end_of_line] + new_register + content[end_of_line:]
    print('OK: Added registerAiContextUploadRoutes call')
else:
    # Try to find any register call
    alt_marker = "registerAttachmentsRoutes(app)"
    if alt_marker in content:
        insert_pos = content.find(alt_marker)
        end_of_line = content.find('\n', insert_pos)
        new_register = "\n  registerAiContextUploadRoutes(app); // PH26.5L"
        content = content[:end_of_line] + new_register + content[end_of_line:]
        print('OK: Added route registration after attachments')
    else:
        print('ERROR: Could not find registration point')
        exit(1)

with open(TARGET, 'w') as f:
    f.write(content)

print('Done')
