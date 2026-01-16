# PH-MVP-ATTACHMENTS-FINALIZE-02 — RAPPORT

**Date**: 2026-01-17  
**Objectif**: Finaliser le système d'attachments inbound/outbound

---

## 🎯 Problèmes Résolus

### A) Message inbound non parsé (16/01 22:50:45)

**Message ID**: `cmmkhh2d9k4f30163c1a2f804`

**Avant** (MIME brut dans body):
```
_1605924392.1768603843439
Content-Disposition: attachment; filename=DR9083685.pdf
JVBERi0xLjUKJeLjz9MKMyAwIG9iago...
```

**Après** (parser v3):
```json
{
  "body": "[Pièce jointe reçue]",
  "attachments": [{
    "filename": "DR9083685.pdf",
    "mimeType": "application/pdf",
    "sizeBytes": 7266,
    "downloadUrl": "/attachments/att-f42907a7b6dc5452"
  }]
}
```

### B) mimeParser v3 - Conservation du texte

Le parser v3 améliore l'extraction:
- Conserve le texte lisible s'il est présent (ex: "facture")
- Ignore les identifiants numériques (`_1234567890.1234567890`)
- Extrait correctement le base64 des attachments
- Fallback sur `[Pièce jointe reçue]` seulement si pas de texte

**Fichier**: `keybuzz-api/src/services/mimeParser.service.ts`

### C) Règles de canal pour PJ outbound

**Endpoint**: `GET /attachments/channel-rules/:channel`

| Canal | PJ Autorisées | Message |
|-------|---------------|---------|
| **email** | ✅ Oui | - |
| **amazon** | ❌ Non | "Amazon n'accepte pas les pièces jointes via ce canal" |
| **whatsapp** | ✅ Oui | - |

**Test Amazon**:
```bash
$ curl https://api-dev.keybuzz.io/attachments/channel-rules/amazon
{
  "attachmentsAllowed": false,
  "maxSize": 0,
  "allowedTypes": [],
  "message": "Amazon n'accepte pas les pièces jointes via ce canal..."
}
```

**Test Email**:
```bash
$ curl https://api-dev.keybuzz.io/attachments/channel-rules/email
{
  "attachmentsAllowed": true,
  "maxSize": 10485760,
  "allowedTypes": ["image/jpeg", "image/png", "application/pdf", ...]
}
```

---

## ✅ Résultats E2E

### Test 1: Message inbound avec PJ
- **Message**: `cmmkhh2d9k4f30163c1a2f804`
- **Body**: `[Pièce jointe reçue]` ✅
- **Attachment**: `DR9083685.pdf` (7266 bytes) ✅
- **API retourne downloadUrl** ✅

### Test 2: Règles canal Amazon
- **attachmentsAllowed**: `false` ✅
- **message**: Explicite pour l'utilisateur ✅

### Test 3: Règles canal Email
- **attachmentsAllowed**: `true` ✅
- **Types autorisés**: PDF, images, texte ✅

---

## 📦 Fichiers Modifiés/Créés

| Fichier | Action |
|---------|--------|
| `keybuzz-api/src/services/mimeParser.service.ts` | **v3** - Conservation texte |
| `keybuzz-api/src/modules/attachments/routes.ts` | Ajout endpoint channel-rules |
| `keybuzz-api/src/modules/inbound/routes.ts` | Intégration parser v3 |

---

## 🔧 Image Déployée

- **Tag**: `ghcr.io/keybuzzio/keybuzz-api:v0.1.111-dev`
- **SHA**: `a034556a3abb60ee243226b862f3311540e5a93feb6af94f668211b919a8a436`

---

## ⚠️ Limitations Connues

1. **Attachments legacy** (status=pending_storage): Le contenu base64 n'a pas été stocké dans MinIO pendant la migration. Les métadonnées sont en DB mais le téléchargement ne fonctionnera pas pour ces fichiers.

2. **Futurs messages**: Le parsing MIME fonctionne correctement et les attachments seront uploadés vers MinIO si configuré.

---

## 🟢 Verdict Final

| Critère | Statut |
|---------|--------|
| Parser MIME v3 déployé | ✅ |
| Body texte conservé si présent | ✅ |
| Attachments extraits et en DB | ✅ |
| API retourne attachments[] | ✅ |
| Endpoint channel-rules | ✅ |
| Amazon bloque PJ | ✅ |
| Email autorise PJ | ✅ |

**Résultat**: ✅ **ATTACHMENTS FINALIZE COMPLET**
