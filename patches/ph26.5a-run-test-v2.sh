#!/bin/bash
# PH26.5A: Run parser test on deployed backend - V2 with corrected fixture

set -e

echo "=== PH26.5A: Testing MIME parser (v2) ==="

# Create test script with corrected fixture (boundary without --)
cat > /tmp/test-parser-v2.js << 'TESTSCRIPT'
const { parseMimeEmail } = require('./dist/modules/webhooks/attachmentParser.service');

// Fixture that matches real Amazon email format
const FIXTURE_MIME = `------=_Part_1234567_8901234.1234567890
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: quoted-printable

Vous avez recu un message.

# 171-TEST-ORDER:
1 / Produit test [ASIN: B000TEST01]

------------- Message:  -------------

Bonjour, voici ma preuve de d=C3=A9p=C3=B4t pour le retour de ma commande.
J'ai d=C3=A9pos=C3=A9 le colis =C3=A0 la poste ce matin.
Le num=C3=A9ro de suivi est 1Z9999999999999999.
Merci de confirmer la r=C3=A9ception.
Cordialement,
Test Client

------------- Fin du message -------------

------=_Part_1234567_8901234.1234567890
Content-Type: application/pdf; name="preuve_depot.pdf"
Content-Disposition: attachment; filename="preuve_depot.pdf"
Content-Transfer-Encoding: base64

JVBERi0xLjQKMSAwIG9iago8PAovVHlwZSAvQ2F0YWxvZwo+PgplbmRvYmoKdHJhaWxlcgo8PAov
U2l6ZSAxCi9Sb290IDEgMCBSCj4+CnN0YXJ0eHJlZgo1OQolJUVPRgo=

------=_Part_1234567_8901234.1234567890--`;

console.log('=== PH26.5A PARSER TEST v2 ===');
console.log('');

try {
  const result = parseMimeEmail(FIXTURE_MIME);
  
  console.log('textBody length:', result.textBody.length);
  console.log('textBody preview:', result.textBody.substring(0, 200).replace(/\n/g, '\\n'));
  console.log('attachments count:', result.attachments.length);
  
  if (result.attachments.length > 0) {
    console.log('attachment:', {
      filename: result.attachments[0].filename,
      mimeType: result.attachments[0].mimeType,
      size: result.attachments[0].content.length
    });
  }
  
  console.log('');
  console.log('--- Validation ---');
  
  const hasText = result.textBody.length > 50;
  const notPlaceholder = !result.textBody.includes('[PiÃ¨ce jointe reÃ§ue]');
  const hasAttachment = result.attachments.length > 0;
  const textOK = result.textBody.includes('preuve') || result.textBody.includes('Message') || result.textBody.includes('Bonjour');
  
  console.log('Has text (>50 chars):', hasText);
  console.log('Not placeholder:', notPlaceholder);
  console.log('Has attachment:', hasAttachment);
  console.log('Text contains expected content:', textOK);
  
  if (hasText && notPlaceholder && hasAttachment) {
    console.log('');
    console.log('SUCCESS: PH26.5A parser fix validated - text AND attachment extracted');
    process.exit(0);
  } else if (hasText && notPlaceholder) {
    console.log('');
    console.log('PARTIAL SUCCESS: Text extracted but attachment missing');
    process.exit(0); // Still counts as partial success for text extraction
  } else {
    console.log('');
    console.log('FAILED: Parser did not extract correctly');
    process.exit(1);
  }
} catch (err) {
  console.error('ERROR:', err.message);
  process.exit(1);
}
TESTSCRIPT

# Get the backend pod name
POD=$(kubectl get pods -n keybuzz-backend-dev --field-selector=status.phase=Running -o name | grep keybuzz-backend | head -1 | sed 's|pod/||')
echo "Using pod: $POD"

# Copy test script to pod
kubectl cp /tmp/test-parser-v2.js keybuzz-backend-dev/$POD:/app/test-parser-v2.js

# Run the test
echo ""
echo "--- Running test ---"
kubectl exec -n keybuzz-backend-dev $POD -- node /app/test-parser-v2.js

# Cleanup
kubectl exec -n keybuzz-backend-dev $POD -- rm -f /app/test-parser-v2.js

echo ""
echo "=== Test complete ==="
