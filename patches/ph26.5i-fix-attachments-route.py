#!/usr/bin/env python3
# PH26.5I: Fix attachments route to use correct DB (productDb/message_attachments)

TARGET = '/opt/keybuzz/keybuzz-backend/src/modules/attachments/attachments.routes.ts'

NEW_CONTENT = '''/**
 * PH-PROD-MINIO-HA-02: Attachments API Routes
 * PH26.5I: Fixed to use productDb (keybuzz.message_attachments)
 */

import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import '@fastify/multipart';
import { Client as MinioClient } from 'minio';
import { devAuthenticateOrJwt } from '../../lib/devAuthMiddleware';
import { productDb } from '../../lib/productDb';

// MinIO client (internal only - via HAProxy)
const minioEndpoint = process.env.MINIO_ENDPOINT?.replace('http://', '').split(':')[0] || '10.0.0.11';
const minioPort = parseInt(process.env.MINIO_PORT || '9000');
const BUCKET = 'keybuzz-attachments';

const minioClient = new MinioClient({
  endPoint: minioEndpoint,
  port: minioPort,
  useSSL: false,
  accessKey: process.env.MINIO_ACCESS_KEY || 'keybuzz-admin',
  secretKey: process.env.MINIO_SECRET_KEY || '',
});

interface AttachmentParams {
  id: string;
}

interface AuthUser {
  tenantId: string;
  role: string;
}

export function registerAttachmentsRoutes(app: FastifyInstance) {
  /**
   * GET /api/v1/attachments/:id
   * Download attachment via API (stream from MinIO)
   * PH26.5I: Fixed to use productDb.message_attachments
   */
  app.get<{ Params: AttachmentParams }>(
    '/api/v1/attachments/:id',
    { preHandler: devAuthenticateOrJwt },
    async (request: FastifyRequest<{ Params: AttachmentParams }>, reply: FastifyReply) => {
      const { id } = request.params;
      const user = (request as any).user as AuthUser;

      try {
        // PH26.5I: Use productDb (keybuzz.message_attachments) not prisma
        const result = await productDb.query(
          `SELECT id, tenant_id, filename, mime_type, size_bytes, storage_key
           FROM message_attachments
           WHERE id = $1
           LIMIT 1`,
          [id]
        );

        if (!result.rows || result.rows.length === 0) {
          return reply.status(404).send({ error: 'Attachment not found' });
        }

        const att = result.rows[0];

        // Verify tenant access
        if (att.tenant_id !== user.tenantId) {
          return reply.status(403).send({ error: 'Access denied' });
        }

        // PH26.5I: Get actual object size from MinIO
        let actualSize = att.size_bytes;
        try {
          const stat = await minioClient.statObject(BUCKET, att.storage_key);
          actualSize = stat.size;
          console.log(`[Attachments] PH26.5I: DB size=${att.size_bytes}, MinIO size=${stat.size}`);
        } catch (statErr) {
          console.warn(`[Attachments] PH26.5I: Could not stat MinIO object, using DB size`);
        }

        // Stream from MinIO
        const stream = await minioClient.getObject(BUCKET, att.storage_key);

        // Set response headers - PH26.5F+5I: Use actual size
        reply.header('Content-Type', att.mime_type);
        reply.header('Content-Disposition', `attachment; filename="${att.filename}"`);
        reply.header('Content-Length', actualSize);
        reply.header('Cache-Control', 'private, max-age=3600');

        // Stream response
        return reply.send(stream);
      } catch (error: any) {
        app.log.error({ err: error, attachmentId: id }, 'Attachment download error');
        
        if (error.code === 'NoSuchKey') {
          return reply.status(404).send({ error: 'Attachment file not found in storage' });
        }
        
        return reply.status(500).send({ error: 'Failed to download attachment' });
      }
    }
  );

  /**
   * GET /api/v1/attachments/:id/info
   * Get attachment metadata only
   */
  app.get<{ Params: AttachmentParams }>(
    '/api/v1/attachments/:id/info',
    { preHandler: devAuthenticateOrJwt },
    async (request: FastifyRequest<{ Params: AttachmentParams }>, reply: FastifyReply) => {
      const { id } = request.params;
      const user = (request as any).user as AuthUser;

      const result = await productDb.query(
        `SELECT id, tenant_id, filename, mime_type, size_bytes, created_at
         FROM message_attachments
         WHERE id = $1
         LIMIT 1`,
        [id]
      );

      if (!result.rows || result.rows.length === 0) {
        return reply.status(404).send({ error: 'Attachment not found' });
      }

      const att = result.rows[0];

      if (att.tenant_id !== user.tenantId) {
        return reply.status(403).send({ error: 'Access denied' });
      }

      return reply.send({
        id: att.id,
        filename: att.filename,
        mimeType: att.mime_type,
        size: att.size_bytes,
        createdAt: att.created_at,
        downloadUrl: `/api/v1/attachments/${att.id}`,
      });
    }
  );

  /**
   * POST /api/v1/attachments/upload
   * Upload attachment for outbound message
   */
  app.post(
    '/api/v1/attachments/upload',
    { preHandler: devAuthenticateOrJwt },
    async (request: FastifyRequest, reply: FastifyReply) => {
      const user = (request as any).user as AuthUser;
      
      try {
        const data = await request.file();
        if (!data) {
          return reply.status(400).send({ error: 'No file uploaded' });
        }

        const filename = data.filename;
        const mimeType = data.mimetype;
        
        const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png', 'image/gif'];
        if (!allowedTypes.includes(mimeType)) {
          return reply.status(400).send({ 
            error: 'Invalid file type', 
            message: 'Seuls les fichiers PDF et images (JPG, PNG, GIF) sont autorises'
          });
        }

        const chunks: Buffer[] = [];
        for await (const chunk of data.file) {
          chunks.push(chunk);
        }
        const fileBuffer = Buffer.concat(chunks);
        
        const maxSize = 10 * 1024 * 1024;
        if (fileBuffer.length > maxSize) {
          return reply.status(400).send({ 
            error: 'File too large', 
            message: 'La taille maximale est de 10 Mo'
          });
        }

        const attachmentId = 'att_' + Date.now().toString(36) + Math.random().toString(36).substring(2, 8);
        const storageKey = `${user.tenantId}/outbound/${attachmentId}-${filename}`;

        await minioClient.putObject(BUCKET, storageKey, fileBuffer, fileBuffer.length, {
          'Content-Type': mimeType,
        });

        app.log.info({ attachmentId, filename, size: fileBuffer.length, tenantId: user.tenantId }, 'Outbound attachment uploaded');

        return reply.send({
          id: attachmentId,
          filename,
          mimeType,
          size: fileBuffer.length,
          storageKey,
          status: 'uploaded',
        });
      } catch (error: any) {
        app.log.error({ err: error }, 'Upload error');
        return reply.status(500).send({ error: 'Upload failed', message: error.message });
      }
    }
  );

  /**
   * GET /api/v1/attachments/channel-rules/:channel
   */
  app.get<{ Params: { channel: string } }>(
    '/api/v1/attachments/channel-rules/:channel',
    async (request: FastifyRequest<{ Params: { channel: string } }>, reply: FastifyReply) => {
      const { channel } = request.params;
      
      if (channel === 'amazon') {
        return reply.send({
          canSendAttachments: false,
          reason: "Amazon Messaging n'accepte pas les pieces jointes.",
          maxSize: 0,
          allowedTypes: []
        });
      }
      
      return reply.send({
        canSendAttachments: true,
        reason: null,
        maxSize: 10 * 1024 * 1024,
        allowedTypes: ['application/pdf', 'image/jpeg', 'image/png', 'image/gif']
      });
    }
  );
}
'''

with open(TARGET, 'w') as f:
    f.write(NEW_CONTENT)

print('OK: Rewrote attachments.routes.ts to use productDb/message_attachments')
print('Changes:')
print('  - Use productDb instead of prisma')
print('  - Query message_attachments table (keybuzz DB)')
print('  - Get actual size from MinIO stat')
print('  - Log DB vs MinIO size for debugging')
