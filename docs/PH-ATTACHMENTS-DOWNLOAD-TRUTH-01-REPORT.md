# PH-ATTACHMENTS-DOWNLOAD-TRUTH-01 — RAPPORT FINAL

**Date**: 2026-01-17  
**Objectif**: Corriger le téléchargement des attachments

---

## 🔴 Problème Initial

**1) Erreur de téléchargement:**
```bash
$ curl https://api-dev.keybuzz.io/attachments/att-f42907a7b6dc5452
HTTP 500: {"error":"Internal Server Error","message":"Failed to retrieve file"}
```

**2) Messages avec MIME brut:**
```
Body: Content-Disposition: attachment; filename=DR9083685.pdf
      JVBERi0xLjUK... (base64)
```
Au lieu de `"[Pièce jointe reçue]"` + attachment téléchargeable.

---

## 🔍 Diagnostic

### Cause 1: storage_key = NULL
Les attachments créés par migration n'avaient pas été uploadés vers MinIO.

```json
// Logs backend
{
  "streamError": {
    "name": "SignatureDoesNotMatch"
  },
  "storageKey": null  // ⚠️ NULL !
}
```

### Cause 2: Parser MIME non appelé
Le service `keybuzz-backend/inboxConversation.service.ts` créait les messages sans appeler le parser d'attachments.

---

## ✅ Fix 1: Gestion gracieuse storage_key = NULL

**Fichier**: `keybuzz-api/src/modules/attachments/routes.ts`

```typescript
// PH-ATTACHMENTS-DOWNLOAD-TRUTH-01: Check if storage_key exists
if (!attachment.storage_key) {
  return reply.status(404).send({
    error: 'Not Found',
    code: 'ATTACHMENT_NOT_UPLOADED',
    message: 'Le fichier n\'est pas disponible. L\'attachment a été créé mais le contenu n\'a pas été uploadé vers le stockage.',
    filename: attachment.filename,
    status: attachment.status || 'pending_storage'
  });
}
```

**Image déployée**: `ghcr.io/keybuzzio/keybuzz-api:v0.1.112-dev`

---

## ✅ Fix 2: Intégration du parser MIME dans keybuzz-backend

**Fichier**: `keybuzz-backend/src/modules/webhooks/inboxConversation.service.ts`

```typescript
// ===== PROCESS MIME ATTACHMENTS (PH-ATTACHMENTS-DOWNLOAD-TRUTH-01) =====
if (rawBody && (rawBody.includes('Content-Disposition:') || rawBody.includes('Content-Type:') || /JVBERi0[A-Za-z0-9+\\/=]{50,}/.test(rawBody))) {
  console.log('[InboxConversation] Detected MIME content, parsing for attachments...');
  
  const parsed = parseMimeEmail(rawBody);
  
  if (parsed.attachments.length > 0) {
    const stored = await storeAttachments({
      tenantId,
      messageId: msgId,
      attachments: parsed.attachments,
    });
    
    // Update message body
    await productDb.query(
      'UPDATE messages SET body = $1 WHERE id = $2',
      [parsed.textBody || '[Pièce jointe reçue]', msgId]
    );
  }
}
```

**Image déployée**: `ghcr.io/keybuzzio/keybuzz-backend:v1.0.29-attachments`

---

## ✅ Fix 3: Migration des messages existants

Script `migrate_simple_mime.ts` pour re-parser les messages avec MIME brut.

### Résultats:
```
[Migration] Processing: cmmki0ckobf93bd6e911fb24d
[Parser] Found attachment: DR9083685.pdf
[Parser] Decoded 7266 bytes
[Migration] Uploaded to MinIO: ecomlg-001/1768640106975-att-mki2nkkfzvgukzuc-DR9083685.pdf
[Migration] Created attachment record: att-mki2nkkfzvgukzuc
[Migration] Updated message body to: "[Pièce jointe reçue]"

[Migration] Complete! Success: 3, Failed: 0
```

---

## 🧪 Validation

### Test 1: Download attachment migré
```bash
$ curl -sk 'https://api-dev.keybuzz.io/attachments/att-mki2nkkfzvgukzuc' -H 'X-Tenant-Id: ecomlg-001'

%PDF-1.5
%����
3 0 obj
...
```
✅ **PDF téléchargé avec succès**

### Test 2: État DB
```sql
SELECT m.id, LEFT(m.body, 50), ma.filename, ma.status, ma.storage_key IS NOT NULL
FROM messages m LEFT JOIN message_attachments ma ON m.id = ma.message_id 
WHERE m.conversation_id = 'cmmkgwhwu97f61c3178fa1393';
```

| Message ID | Body | Filename | Status | MinIO |
|------------|------|----------|--------|-------|
| cmmki0ckobf93bd6e911fb24d | [Pièce jointe reçue] | DR9083685.pdf | uploaded | ✅ |
| cmmkhib6cw0769eec36245683 | [Pièce jointe reçue] | DR9083685.pdf | uploaded | ✅ |
| cmmkhi5zyc7987a9819458e17 | [Pièce jointe reçue] | DR9083685.pdf | uploaded | ✅ |

---

## 📦 Images Déployées

| Service | Image | SHA |
|---------|-------|-----|
| keybuzz-api | v0.1.112-dev | 1329d84ad8d6... |
| keybuzz-backend | v1.0.29-attachments | ebf3e3d48f7e... |

---

## 🟢 Verdict Final

| Problème | Avant | Après |
|----------|-------|-------|
| Download storage_key=NULL | 500 crash | 404 + message FR |
| Download storage_key OK | ✅ 200 | ✅ 200 |
| Nouveaux messages MIME | MIME brut en body | Body clean + PJ MinIO |
| Messages legacy migrés | 3 messages | ✅ 3/3 uploadés |

**Résultat**: ✅ **ATTACHMENTS DOWNLOAD FIXED**

---

## 📋 Prochaines étapes

1. Tester avec un **nouveau message** envoyé par Ludovic pour valider le flux complet
2. Vérifier l'affichage dans l'UI KeyBuzz
