#!/usr/bin/env python3
"""
PH-MVP-MESSAGING-REALITY-01: Add attachment rendering to client inbox
"""

with open("/opt/keybuzz/keybuzz-client/app/inbox/InboxTripane.tsx", "r") as f:
    lines = f.readlines()

# Insert after line 994 (index 993) - after the </p> that closes sanitizeMessageBody
insert_after = 994

insert_code = '''                      {/* PH-MVP-MESSAGING-REALITY-01: Attachments */}
                      {msg.attachments && msg.attachments.length > 0 && (
                        <div className="mt-2 pt-2 border-t border-gray-200 dark:border-gray-700">
                          <p className="text-xs font-medium text-gray-500 dark:text-gray-400 mb-1">
                            Pieces jointes ({msg.attachments.length})
                          </p>
                          <div className="flex flex-wrap gap-2">
                            {msg.attachments.map((att) => (
                              <a
                                key={att.id}
                                href={`https://api-dev.keybuzz.io${att.downloadUrl}?tenantId=ecomlg-001`}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="flex items-center gap-2 px-2 py-1 bg-gray-100 dark:bg-gray-700 rounded text-xs hover:bg-gray-200 dark:hover:bg-gray-600"
                              >
                                <span>📎</span>
                                <span className="text-gray-700 dark:text-gray-300 max-w-[150px] truncate">{att.filename}</span>
                                <span className="text-gray-400">({Math.round(att.sizeBytes / 1024)}KB)</span>
                              </a>
                            ))}
                          </div>
                        </div>
                      )}
'''

lines.insert(insert_after, insert_code + "\n")

with open("/opt/keybuzz/keybuzz-client/app/inbox/InboxTripane.tsx", "w") as f:
    f.writelines(lines)

print("Done - inserted attachment rendering after line", insert_after + 1)
