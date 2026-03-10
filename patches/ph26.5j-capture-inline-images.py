#!/usr/bin/env python3
# PH26.5J: Capture inline images as attachments

TARGET = '/opt/keybuzz/keybuzz-backend/src/modules/webhooks/attachmentParser.service.ts'

with open(TARGET, 'r') as f:
    content = f.read()

# Fix 1: Modify isAttachmentCandidate to include inline images > 50KB
old_selection = '''    const isTextCandidate = contentType.startsWith('text/') && !filename && contentDisposition !== 'attachment';
    const isAttachmentCandidate = !!filename || contentDisposition === 'attachment';'''

new_selection = '''    const isTextCandidate = contentType.startsWith('text/') && !filename && contentDisposition !== 'attachment';
    // PH26.5J: Capture inline images > 50KB (likely photos, not email signatures)
    const isInlineImage = contentType.startsWith('image/') && content.length > 50000;
    const isAttachmentCandidate = !!filename || contentDisposition === 'attachment' || isInlineImage;'''

if old_selection in content and 'PH26.5J' not in content:
    content = content.replace(old_selection, new_selection)
    print('OK: Fixed isAttachmentCandidate to include inline images > 50KB')
elif 'PH26.5J' in content:
    print('INFO: PH26.5J fix already applied')
else:
    print('WARNING: Could not find selection pattern')

# Fix 2: Enhance logging to show inline image detection
old_log = "console.log('[MimeParser PH26.5A] Part', i, ': type=' + contentType + ', disp=' + contentDisposition + ', file=' + (filename || 'none') + ', enc=' + transferEncoding + ', size=' + content.length + ', isText=' + isTextCandidate + ', isAtt=' + isAttachmentCandidate);"

new_log = "console.log('[MimeParser PH26.5A] Part', i, ': type=' + contentType + ', disp=' + contentDisposition + ', file=' + (filename || 'none') + ', enc=' + transferEncoding + ', size=' + content.length + ', isText=' + isTextCandidate + ', isAtt=' + isAttachmentCandidate + ', isInlineImg=' + isInlineImage);"

if old_log in content:
    content = content.replace(old_log, new_log)
    print('OK: Enhanced logging with isInlineImage flag')
else:
    print('INFO: Log already enhanced or different format')

# Fix 3: Generate filename for inline images without filename
old_filename_gen = '''      if (!part.filename) {
        part.filename = 'attachment_' + part.index + '_' + Date.now();
      }'''

new_filename_gen = '''      if (!part.filename) {
        // PH26.5J: Generate meaningful filename for inline images
        const ext = part.contentType.split('/')[1]?.split(';')[0] || 'bin';
        part.filename = 'inline_image_' + part.index + '_' + Date.now() + '.' + ext;
      }'''

if old_filename_gen in content:
    content = content.replace(old_filename_gen, new_filename_gen)
    print('OK: Improved filename generation for inline images')
elif 'inline_image_' in content:
    print('INFO: Filename generation already improved')
else:
    print('WARNING: Could not find filename generation pattern')

with open(TARGET, 'w') as f:
    f.write(content)

print('Done')
