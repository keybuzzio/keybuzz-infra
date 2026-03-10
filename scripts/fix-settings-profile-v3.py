#!/usr/bin/env python3
"""
PH28.23B v3: Fix the settings page - use tenantId instead of currentTenantId in saveSettings
"""

settings_path = '/opt/keybuzz/keybuzz-client/app/settings/page.tsx'
with open(settings_path, 'r') as f:
    content = f.read()

# The saveSettings references currentTenantId but it's declared later
# Change it to use only tenantId (which is set from getCurrentTenantId())
# and remove currentTenantId from the dependency array

old_save = '''const effectiveTenantId = currentTenantId || tenantId;'''
new_save = '''const effectiveTenantId = tenantId;'''

if old_save in content:
    content = content.replace(old_save, new_save)
    print('Fixed effectiveTenantId in saveSettings')
else:
    print('WARNING: Could not find effectiveTenantId line')

# Remove currentTenantId from the dependency array
old_deps = '''}, [profile, hours, vacations, autoMessages, notifications, outOfHours, holidaysEnabled, focusMode, tenantId, currentTenantId]);'''
new_deps = '''}, [profile, hours, vacations, autoMessages, notifications, outOfHours, holidaysEnabled, focusMode, tenantId]);'''

if old_deps in content:
    content = content.replace(old_deps, new_deps)
    print('Removed currentTenantId from saveSettings deps')
else:
    print('WARNING: Could not find dependency array to fix')

with open(settings_path, 'w') as f:
    f.write(content)
print(f'Updated {settings_path}')

print('\\nDone!')
