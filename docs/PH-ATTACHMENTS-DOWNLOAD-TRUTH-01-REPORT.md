# PH-ATTACHMENTS-DOWNLOAD-TRUTH-01 — RAPPORT

**Date**: 2026-01-17  
**Objectif**: Corriger l'erreur de téléchargement des attachments

---

## 🔴 Problème Initial

```bash
$ curl https://api-dev.keybuzz.io/attachments/att-f42907a7b6dc5452
HTTP/2 500
{"error":"Internal Server Error","message":"Failed to retrieve file"}
```

---

## 🔍 Diagnostic

### 1) Logs Backend

```json
{
  "level": 50,
  "streamError": {
    "name": "SignatureDoesNotMatch",
    "Code": "SignatureDoesNotMatch",
    "message": "The request signature we calculated does not match..."
  },
  "storageKey": null  // ⚠️ NULL !
}
```

### 2) DB Check

```sql
SELECT storage_key, status FROM message_attachments WHERE id = 'att-f42907a7b6dc5452';
-- storage_key: NULL
-- status: pending_storage
```

### 3) Cause Racine

| Type | storage_key | Status | Téléchargement |
|------|-------------|--------|----------------|
| Migration legacy | **NULL** | pending_storage | ❌ Échoue |
| Uploadés MinIO | Présent | stored | ✅ Fonctionne |

Les attachments créés par la migration n'ont jamais été uploadés vers MinIO.
Le backend tentait de streamer avec `storage_key = null`, causant une erreur de signature.

---

## ✅ Fix Appliqué

**Fichier**: `keybuzz-api/src/modules/attachments/routes.ts`

```typescript
// PH-ATTACHMENTS-DOWNLOAD-TRUTH-01: Check if storage_key exists
if (!attachment.storage_key) {
  app.log.warn({ attachmentId, status: attachment.status }, 'Attachment has no storage_key');
  return reply.status(404).send({
    error: 'Not Found',
    code: 'ATTACHMENT_NOT_UPLOADED',
    message: 'Le fichier n\'est pas disponible. L\'attachment a été créé mais le contenu n\'a pas été uploadé vers le stockage.',
    filename: attachment.filename,
    status: attachment.status || 'pending_storage'
  });
}
```

---

## 🧪 Tests E2E

### Attachment SANS storage_key (legacy)

```bash
$ curl https://api-dev.keybuzz.io/attachments/att-f42907a7b6dc5452 -H 'X-Tenant-Id: ecomlg-001'

{
  "error": "Not Found",
  "code": "ATTACHMENT_NOT_UPLOADED",
  "message": "Le fichier n'est pas disponible...",
  "filename": "DR9083685.pdf",
  "status": "pending_storage"
}
```
**HTTP 404** ✅ (au lieu de 500)

### Attachment AVEC storage_key

```bash
$ curl https://api-dev.keybuzz.io/attachments/att-test-e2e-001 -H 'X-Tenant-Id: ecomlg-001'

Test PDF content for E2E attachments render
```
**HTTP 200** ✅

---

## 📊 Résumé des Attachments

```sql
-- Attachments legacy (contenu perdu)
SELECT COUNT(*) FROM message_attachments WHERE storage_key IS NULL;
-- 16 attachments

-- Attachments uploadés (fonctionnels)
SELECT COUNT(*) FROM message_attachments WHERE storage_key IS NOT NULL;
-- 2 attachments
```

---

## 📦 Déploiement

- **Image**: `ghcr.io/keybuzzio/keybuzz-api:v0.1.112-dev`
- **SHA**: `1329d84ad8d620267776e12befd8c182873b955ff3bfa7b3acba5d935c177d4d`

---

## ⚠️ Limitations

Les attachments legacy (`storage_key = NULL`) ne peuvent pas être téléchargés car :
1. Le contenu base64 a été perdu lors de la migration
2. Le fichier n'a jamais été uploadé vers MinIO

Pour les **nouveaux messages inbound**, les attachments seront correctement uploadés vers MinIO et téléchargeables.

---

## 🟢 Verdict Final

| Critère | Avant | Après |
|---------|-------|-------|
| Attachment sans storage_key | 500 crash | 404 + message FR |
| Attachment avec storage_key | ✅ 200 | ✅ 200 |
| Message d'erreur | Générique | Explicite |
| Code d'erreur | - | `ATTACHMENT_NOT_UPLOADED` |

**Résultat**: ✅ **DOWNLOAD ERRORS FIXED**
