/**
 * PH26.5A Test: Validate MIME parser with attachment fixture
 * Run with: npx ts-node ph26.5a-test-parser.ts
 */

import { parseMimeEmail, parseMimeEmailAsync } from '../src/modules/webhooks/attachmentParser.service';

const FIXTURE_MIME = `MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="------=_Part_1234567_8901234.1234567890"

------=_Part_1234567_8901234.1234567890
Content-Type: multipart/alternative; boundary="------=_Part_9876543_2109876.1234567890"

------=_Part_9876543_2109876.1234567890
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

------=_Part_9876543_2109876.1234567890
Content-Type: text/html; charset=UTF-8
Content-Transfer-Encoding: quoted-printable

<!DOCTYPE html>
<html>
<body>
<p>Bonjour, voici ma preuve de d=C3=A9p=C3=B4t pour le retour de ma commande.</p>
</body>
</html>

------=_Part_9876543_2109876.1234567890--

------=_Part_1234567_8901234.1234567890
Content-Type: application/pdf; name="preuve_depot_20260130.pdf"
Content-Disposition: attachment; filename="preuve_depot_20260130.pdf"
Content-Transfer-Encoding: base64

JVBERi0xLjQKMSAwIG9iago8PAovVHlwZSAvQ2F0YWxvZwo+PgplbmRvYmoK

------=_Part_1234567_8901234.1234567890--`;

async function runTest() {
  console.log('=== PH26.5A PARSER TEST ===\n');
  
  // Test sync parser
  console.log('--- Testing parseMimeEmail (sync) ---');
  const syncResult = parseMimeEmail(FIXTURE_MIME);
  console.log('textBody length:', syncResult.textBody.length);
  console.log('textBody (first 200 chars):', syncResult.textBody.substring(0, 200));
  console.log('attachments count:', syncResult.attachments.length);
  if (syncResult.attachments.length > 0) {
    console.log('attachment[0]:', {
      filename: syncResult.attachments[0].filename,
      mimeType: syncResult.attachments[0].mimeType,
      size: syncResult.attachments[0].content.length,
    });
  }
  
  // Validation
  console.log('\n--- Validation ---');
  const hasText = syncResult.textBody.length > 50 && !syncResult.textBody.includes('[Pièce jointe reçue]');
  const hasAttachment = syncResult.attachments.length > 0;
  const textContainsMessage = syncResult.textBody.includes('preuve') || syncResult.textBody.includes('dépôt');
  
  console.log('✓ Has non-placeholder text:', hasText);
  console.log('✓ Has attachment:', hasAttachment);
  console.log('✓ Text contains expected content:', textContainsMessage);
  
  if (hasText && hasAttachment && textContainsMessage) {
    console.log('\n✅ TEST PASSED: Parser extracts both text and attachment correctly');
  } else {
    console.log('\n❌ TEST FAILED: Parser did not extract text correctly');
    process.exit(1);
  }
}

runTest().catch(console.error);
