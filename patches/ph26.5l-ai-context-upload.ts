/**
 * PH26.5L: AI Context File Upload Routes
 * Allows users to upload files (jpg/png/pdf) to provide context to AI
 */

import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { Client as MinioClient } from 'minio';
import { createHash, randomBytes } from 'crypto';
import { productDb } from '../../lib/productDb';

// Parse MinIO endpoint
function parseMinioEndpoint(endpoint: string): { host: string; port: number; useSSL: boolean } {
  if (!endpoint) return { host: '10.0.0.11', port: 9000, useSSL: false };
  const urlMatch = endpoint.match(/^(https?):\/\/([^:]+):?(\d+)?$/);
  if (urlMatch) {
    return {
      host: urlMatch[2],
      port: urlMatch[3] ? parseInt(urlMatch[3]) : (urlMatch[1] === 'https' ? 443 : 9000),
      useSSL: urlMatch[1] === 'https',
    };
  }
  const hostPortMatch = endpoint.match(/^([^:]+):(\d+)$/);
  if (hostPortMatch) {
    return { host: hostPortMatch[1], port: parseInt(hostPortMatch[2]), useSSL: false };
  }
  return { host: endpoint, port: 9000, useSSL: false };
}

const minioConfig = parseMinioEndpoint(process.env.MINIO_ENDPOINT || '');
const minioClient = new MinioClient({
  endPoint: minioConfig.host,
  port: minioConfig.port,
  useSSL: minioConfig.useSSL,
  accessKey: process.env.MINIO_ACCESS_KEY || 'keybuzz',
  secretKey: process.env.MINIO_SECRET_KEY || 'keybuzz123',
});

const AI_CONTEXT_BUCKET = 'keybuzz-ai-context';
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
const MAX_FILES_PER_ACTION = 5;
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'application/pdf'];

// Generate unique ID
function createId(): string {
  const timestamp = Date.now().toString(36);
  const random = randomBytes(6).toString('hex');
  return `aic_${timestamp}${random}`;
}

interface AuthUser {
  email: string;
  tenantId: string;
}

interface UploadedFile {
  id: string;
  filename: string;
  mimeType: string;
  sizeBytes: number;
  minioKey: string;
}

export function registerAiContextUploadRoutes(app: FastifyInstance) {
  // Ensure bucket exists on startup
  (async () => {
    try {
      const exists = await minioClient.bucketExists(AI_CONTEXT_BUCKET);
      if (!exists) {
        await minioClient.makeBucket(AI_CONTEXT_BUCKET);
        console.log(`[PH26.5L] Created bucket: ${AI_CONTEXT_BUCKET}`);
      }
    } catch (err) {
      console.warn('[PH26.5L] Could not check/create bucket:', err);
    }
  })();

  /**
   * POST /api/v1/ai/context/upload
   * Upload context files for AI assistance
   */
  app.post('/api/v1/ai/context/upload', {
    preHandler: (app as any).devAuthenticateOrJwt,
    config: {
      // Enable multipart
    },
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const user = (request as any).user as AuthUser;
    const tenantId = user.tenantId;

    if (!tenantId) {
      return reply.status(400).send({ error: 'Missing tenantId' });
    }

    try {
      // Parse multipart
      const parts = request.parts();
      let conversationId = '';
      let aiActionLogId = '';
      let additionalContextText = '';
      const uploadedFiles: UploadedFile[] = [];

      for await (const part of parts) {
        if (part.type === 'field') {
          if (part.fieldname === 'conversationId') {
            conversationId = part.value as string;
          } else if (part.fieldname === 'aiActionLogId') {
            aiActionLogId = part.value as string;
          } else if (part.fieldname === 'additionalContextText') {
            additionalContextText = part.value as string;
          }
        } else if (part.type === 'file') {
          // Validate file count
          if (uploadedFiles.length >= MAX_FILES_PER_ACTION) {
            console.warn(`[PH26.5L] Max files exceeded for ${tenantId}`);
            continue;
          }

          // Validate file type
          const mimeType = part.mimetype;
          if (!ALLOWED_TYPES.includes(mimeType)) {
            console.warn(`[PH26.5L] Invalid file type: ${mimeType}`);
            continue;
          }

          // Read file buffer
          const chunks: Buffer[] = [];
          let totalSize = 0;
          for await (const chunk of part.file) {
            totalSize += chunk.length;
            if (totalSize > MAX_FILE_SIZE) {
              console.warn(`[PH26.5L] File too large: ${part.filename}`);
              break;
            }
            chunks.push(chunk);
          }

          if (totalSize > MAX_FILE_SIZE) {
            continue;
          }

          const buffer = Buffer.concat(chunks);
          const sha256 = createHash('sha256').update(buffer).digest('hex');
          const fileId = createId();
          const safeFilename = (part.filename || 'file').replace(/[^a-zA-Z0-9._-]/g, '_');
          const minioKey = `ai-context/${tenantId}/${conversationId || 'general'}/${fileId}/${safeFilename}`;

          // Upload to MinIO
          await minioClient.putObject(AI_CONTEXT_BUCKET, minioKey, buffer, buffer.length, {
            'Content-Type': mimeType,
            'x-amz-meta-tenant-id': tenantId,
            'x-amz-meta-conversation-id': conversationId,
            'x-amz-meta-sha256': sha256,
          });

          // Insert into DB
          await productDb.query(
            `INSERT INTO ai_context_attachments 
             (id, tenant_id, conversation_id, ai_action_log_id, minio_key, filename, mime_type, size_bytes, sha256, created_by)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
            [fileId, tenantId, conversationId, aiActionLogId || null, minioKey, safeFilename, mimeType, buffer.length, sha256, user.email]
          );

          uploadedFiles.push({
            id: fileId,
            filename: safeFilename,
            mimeType,
            sizeBytes: buffer.length,
            minioKey,
          });

          console.log(`[PH26.5L] Uploaded: ${minioKey} (${buffer.length} bytes)`);
        }
      }

      return reply.send({
        success: true,
        conversationId,
        aiActionLogId,
        additionalContextText,
        uploadedFiles,
        summary: `${uploadedFiles.length} file(s) uploaded`,
      });

    } catch (error: any) {
      console.error('[PH26.5L] Upload error:', error);
      return reply.status(500).send({ error: 'Upload failed', details: error.message });
    }
  });

  /**
   * GET /api/v1/ai/context/attachments
   * List context attachments for a conversation
   */
  app.get('/api/v1/ai/context/attachments', {
    preHandler: (app as any).devAuthenticateOrJwt,
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const user = (request as any).user as AuthUser;
    const { conversationId, aiActionLogId } = request.query as { conversationId?: string; aiActionLogId?: string };

    if (!conversationId && !aiActionLogId) {
      return reply.status(400).send({ error: 'conversationId or aiActionLogId required' });
    }

    try {
      let query = `SELECT id, filename, mime_type, size_bytes, created_at 
                   FROM ai_context_attachments 
                   WHERE tenant_id = $1`;
      const params: any[] = [user.tenantId];

      if (conversationId) {
        query += ` AND conversation_id = $2`;
        params.push(conversationId);
      }
      if (aiActionLogId) {
        query += ` AND ai_action_log_id = $${params.length + 1}`;
        params.push(aiActionLogId);
      }

      query += ` ORDER BY created_at DESC LIMIT 50`;

      const result = await productDb.query(query, params);
      return reply.send({ attachments: result.rows || [] });

    } catch (error: any) {
      console.error('[PH26.5L] List error:', error);
      return reply.status(500).send({ error: 'Failed to list attachments' });
    }
  });

  /**
   * GET /api/v1/ai/context/download/:id
   * Download a context attachment
   */
  app.get('/api/v1/ai/context/download/:id', {
    preHandler: (app as any).devAuthenticateOrJwt,
  }, async (request: FastifyRequest, reply: FastifyReply) => {
    const user = (request as any).user as AuthUser;
    const { id } = request.params as { id: string };

    try {
      const result = await productDb.query(
        `SELECT minio_key, filename, mime_type, tenant_id 
         FROM ai_context_attachments 
         WHERE id = $1`,
        [id]
      );

      if (!result.rows || result.rows.length === 0) {
        return reply.status(404).send({ error: 'Attachment not found' });
      }

      const att = result.rows[0];
      if (att.tenant_id !== user.tenantId) {
        return reply.status(403).send({ error: 'Access denied' });
      }

      const stream = await minioClient.getObject(AI_CONTEXT_BUCKET, att.minio_key);
      
      reply.header('Content-Type', att.mime_type);
      reply.header('Content-Disposition', `attachment; filename="${att.filename}"`);
      return reply.send(stream);

    } catch (error: any) {
      console.error('[PH26.5L] Download error:', error);
      return reply.status(500).send({ error: 'Download failed' });
    }
  });

  console.log('[PH26.5L] AI Context Upload routes registered');
}

export default { registerAiContextUploadRoutes };
