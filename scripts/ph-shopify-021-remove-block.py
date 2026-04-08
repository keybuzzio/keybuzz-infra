#!/usr/bin/env python3
"""Remove the dedicated Shopify block from channels page"""
PAGE = '/opt/keybuzz/keybuzz-client/app/channels/page.tsx'
with open(PAGE, 'r', encoding='utf-8') as f:
    content = f.read()

marker_start = '{/* \u2500\u2500 Shopify Connection'
marker_end = '      {showCatalogModal && ('

if marker_start in content and marker_end in content:
    start = content.index(marker_start)
    while start > 0 and content[start-1] != '\n':
        start -= 1
    end = content.index(marker_end, start)
    removed = content[start:end]
    content = content[:start] + '\n' + content[end:]
    with open(PAGE, 'w', encoding='utf-8') as f:
        f.write(content)
    lines_removed = len(removed.split('\n'))
    print(f'OK: Removed Shopify block ({lines_removed} lines)')
else:
    print('FAIL: Markers not found')
    if marker_start not in content:
        print('  Missing start marker')
    if marker_end not in content:
        print('  Missing end marker')
