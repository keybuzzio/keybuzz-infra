/**
 * PH26.5K: Raw MIME Replay Service
 * Reprocesses stored raw MIME to fix body/attachments
 */

import { Client as MinioClient } from 'minio';
import { productDb } from '../../lib/productDb';
import { parseMimeEmail, storeAttachments } from './attachmentParser.service';

const RAW_MIME_BUCKET = process.env.MINIO_BUCKET_RAW_MIME || 'keybuzz-raw-mime';

const minioClient = new MinioClient({
  endPoint: process.env.MINIO_ENDPOINT || 'minio.keybuzz-backend-dev.svc.cluster.local',
  port: parseInt(process.env.MINIO_PORT || '9000'),
  useSSL: process.env.MINIO_USE_SSL === 'true',
  accessKey: process.env.MINIO_ACCESS_KEY || 'keybuzz',
  secretKey: process.env.MINIO_SECRET_KEY || 'keybuzz123',
});

interface ReplayResult {
  messageId: string;
  success: boolean;
  bodyChanged: boolean;
  attachmentsAdded: number;
  error?: string;
}

/**
 * Replay parsing for a single message
 */
export async function replayParsing(messageId: string): Promise<ReplayResult> {
  const result: ReplayResult = {
    messageId,
    success: false,
    bodyChanged: false,
    attachmentsAdded: 0,
  };

  try {
    // Get message with raw_mime_key
    const msgResult = await productDb.query(
      `SELECT id, tenant_id, conversation_id, body, raw_mime_key, raw_mime_sha256
       FROM messages WHERE id = $1`,
      [messageId]
    );

    if (!msgResult.rows || msgResult.rows.length === 0) {
      result.error = 'Message not found';
      return result;
    }

    const msg = msgResult.rows[0];
    
    if (!msg.raw_mime_key) {
      result.error = 'No raw MIME stored for this message';
      return result;
    }

    // Fetch raw MIME from MinIO
    const stream = await minioClient.getObject(RAW_MIME_BUCKET, msg.raw_mime_key);
    const chunks: Buffer[] = [];
    
    for await (const chunk of stream) {
      chunks.push(chunk);
    }
    
    const rawMime = Buffer.concat(chunks).toString('utf-8');
    console.log(`[PH26.5K Replay] Loaded raw MIME for ${messageId}: ${rawMime.length} bytes`);

    // Parse the raw MIME
    const parsed = parseMimeEmail(rawMime);
    console.log(`[PH26.5K Replay] Parsed: textBody=${parsed.textBody.length} chars, attachments=${parsed.attachments.length}`);

    // Check if body needs update
    const oldBody = msg.body || '';
    const newBody = parsed.textBody || '';
    
    if (newBody.length > 0 && newBody !== oldBody && 
        (oldBody === '[PiÃ¨ce jointe reÃ§ue]' || oldBody.length < 10 || oldBody.includes('Content-Type:'))) {
      await productDb.query(
        'UPDATE messages SET body = $1 WHERE id = $2',
        [newBody, messageId]
      );
      result.bodyChanged = true;
      console.log(`[PH26.5K Replay] Updated body for ${messageId}`);
    }

    // Check if attachments need to be added
    if (parsed.attachments.length > 0) {
      // Check existing attachments
      const existingAtts = await productDb.query(
        'SELECT id, filename FROM message_attachments WHERE message_id = $1',
        [messageId]
      );
      
      const existingFilenames = new Set((existingAtts.rows || []).map((a: any) => a.filename));
      
      // Filter out already stored attachments
      const newAttachments = parsed.attachments.filter(att => !existingFilenames.has(att.filename));
      
      if (newAttachments.length > 0) {
        const stored = await storeAttachments({
          tenantId: msg.tenant_id,
          messageId: messageId,
          attachments: newAttachments,
        });
        result.attachmentsAdded = stored.length;
        console.log(`[PH26.5K Replay] Added ${stored.length} new attachment(s) for ${messageId}`);
      }
    }

    result.success = true;
    return result;

  } catch (err: any) {
    result.error = err.message || 'Unknown error';
    console.error(`[PH26.5K Replay] Error for ${messageId}:`, err);
    return result;
  }
}

/**
 * Replay parsing for all messages with placeholder body
 */
export async function replayAllPlaceholders(tenantId: string, limit: number = 100): Promise<ReplayResult[]> {
  const results: ReplayResult[] = [];

  const msgResult = await productDb.query(
    `SELECT id FROM messages 
     WHERE tenant_id = $1 
       AND raw_mime_key IS NOT NULL
       AND (body = '[PiÃ¨ce jointe reÃ§ue]' OR body IS NULL OR LENGTH(body) < 10)
     ORDER BY created_at DESC
     LIMIT $2`,
    [tenantId, limit]
  );

  for (const row of msgResult.rows || []) {
    const result = await replayParsing(row.id);
    results.push(result);
  }

  return results;
}

export default {
  replayParsing,
  replayAllPlaceholders,
};
