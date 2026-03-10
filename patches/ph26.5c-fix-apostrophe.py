#!/usr/bin/env python3
# Fix apostrophe for React

TARGET = '/opt/keybuzz/keybuzz-client/src/features/ai-ui/AISuggestionSlideOver.tsx'

with open(TARGET, 'r') as f:
    content = f.read()

# Fix the unescaped apostrophe
content = content.replace("l'IA", "l&apos;IA")
content = content.replace("Ãƒ ", "Ã ")
content = content.replace("ÃƒÂ©", "Ã©")
content = content.replace("Ã¢", "'")

with open(TARGET, 'w') as f:
    f.write(content)

print('Fixed apostrophe and encoding')
