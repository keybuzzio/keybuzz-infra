#!/usr/bin/env python3
"""
PH26.5L: Fix import formatting
"""

TARGET = '/opt/keybuzz/keybuzz-backend/src/main.ts'

with open(TARGET, 'r') as f:
    content = f.read()

# Fix the malformed import
old = "// PH26.5Limport"
new = "// PH26.5L\nimport"

if old in content:
    content = content.replace(old, new)
    print('OK: Fixed import formatting')
else:
    print('INFO: Import already formatted correctly')

with open(TARGET, 'w') as f:
    f.write(content)

print('Done')
