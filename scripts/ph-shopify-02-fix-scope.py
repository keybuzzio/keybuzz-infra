#!/usr/bin/env python3
"""Fix: Move Shopify handlers BEFORE the if(tenantLoading) block"""
f = "/opt/keybuzz/keybuzz-client/app/channels/page.tsx"
with open(f, 'r', encoding='utf-8') as fh:
    content = fh.read()

# Extract the handler block (between the markers)
import re
handler_block = """
  // ── Shopify ──────────────────────────────────────────────
  const handleShopifyConnect = async () => {
    if (!currentTenantId || !shopifyDomain.trim()) return;
    setShopifyConnecting(true);
    setErrorMessage(null);
    try {
      const result = await connectShopify(currentTenantId, shopifyDomain.trim());
      if (result.authUrl) {
        window.location.href = result.authUrl;
      } else if (result.error) {
        setErrorMessage('Erreur Shopify : ' + result.error);
      }
    } catch (err: any) {
      setErrorMessage('Erreur Shopify : ' + (err.message || 'Connexion impossible'));
    } finally {
      setShopifyConnecting(false);
    }
  };

  const handleShopifyDisconnect = async () => {
    if (!currentTenantId) return;
    setActionLoading(true);
    try {
      await disconnectShopify(currentTenantId);
      setShopifyStatus({ connected: false });
      setSuccessMessage('Shopify d\\xe9connect\\xe9');
      setShowShopifyModal(false);
    } catch (err: any) {
      setErrorMessage('Erreur : ' + err.message);
    } finally {
      setActionLoading(false);
    }
  };

"""

# First, remove the handler block from its current (wrong) position
# It's inside the "if (tenantLoading) {" block
# Find the exact text to remove
lines = content.split('\n')
start_line = None
end_line = None
for i, line in enumerate(lines):
    if '// ── Shopify' in line and 'const handleShopify' not in line:
        start_line = i
    if start_line and i > start_line and 'setActionLoading(false);' in line:
        # Find the closing brace and empty line after
        for j in range(i+1, min(i+5, len(lines))):
            if lines[j].strip() == '};':
                end_line = j + 1
                break
        break

if start_line is None or end_line is None:
    print("WARN: Could not locate handler block")
    exit(1)

print(f"Removing handler block from lines {start_line+1}-{end_line+1}")

# Remove old handler block (including leading empty line if present)
while start_line > 0 and lines[start_line - 1].strip() == '':
    start_line -= 1
del lines[start_line:end_line + 1]

content = '\n'.join(lines)

# Now insert the handler block BEFORE "if (tenantLoading)"
target = "  if (tenantLoading) {"
if target in content:
    content = content.replace(target, handler_block + target)
    print("OK: Handlers inserted before if(tenantLoading)")
else:
    print("WARN: Could not find if(tenantLoading)")
    exit(1)

with open(f, 'w', encoding='utf-8') as fh:
    fh.write(content)

print("DONE: Shopify handlers in correct scope")
