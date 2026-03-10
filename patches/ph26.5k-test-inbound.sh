#!/bin/bash
# PH26.5K Validation: Simulate inbound message with MIME content

echo "=== Simulating inbound email with MIME attachment ==="

# Create a test MIME message
TEST_BODY='Content-Type: multipart/mixed; boundary="----=_Part_12345"

------=_Part_12345
Content-Type: text/plain; charset=utf-8

Bonjour, ceci est un message de test PH26.5K avec une pièce jointe simulée.
Cordialement.

------=_Part_12345
Content-Type: image/jpeg; name="test-image.jpg"
Content-Disposition: attachment; filename="test-image.jpg"
Content-Transfer-Encoding: base64

/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRof
Hh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAALCAABAAEBAREA/8QAFAAB
AAAAAAAAAAAAAAAAAAAACP/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AVN//2Q==
------=_Part_12345--'

# URL encode the body (basic)
ENCODED_BODY=$(echo "$TEST_BODY" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")

# Call the inbound webhook
echo "Calling inbound webhook..."
curl -s -X POST "http://10.244.118.119:4000/api/v1/webhooks/email/inbound" \
  -H "Content-Type: application/json" \
  -H "X-Tenant-Id: ecomlg-001" \
  -d "{
    \"from\": \"test-ph265k@example.com\",
    \"to\": \"support@keybuzz.io\",
    \"subject\": \"Test PH26.5K Raw MIME Storage\",
    \"body\": \"$TEST_BODY\",
    \"threadId\": \"test-thread-ph265k-$(date +%s)\",
    \"orderId\": \"TEST-PH265K-001\"
  }" | head -20

echo ""
echo "=== Done ==="
