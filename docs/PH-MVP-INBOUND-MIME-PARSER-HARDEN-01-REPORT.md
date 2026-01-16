# PH-MVP-INBOUND-MIME-PARSER-HARDEN-01 — RAPPORT

**Date**: 2026-01-16  
**Objectif**: Corriger le parsing MIME Amazon inbound pour extraire correctement les PDFs

---

## 🎯 Problème Identifié

Les emails Amazon inbound avec pièces jointes (PDF) étaient stockés avec le contenu MIME brut dans le body du message, au lieu d'extraire:
1. Le texte du message comme body
2. Les fichiers attachés comme attachments séparés

### Exemple de body avant correction:
```
Content-Disposition: attachment; filename=DR9083685.pdf
JVBERi0xLjUKJeLjz9MKMyAwIG9iago8PC9MZW5ndGggNTUvRmlsdGVy...
```

---

## ✅ Solution Implémentée

### 1. Installation de mailparser
```bash
npm install mailparser @types/mailparser --save
```

### 2. Création du service mimeParser.service.ts

**Fichier**: `keybuzz-api/src/services/mimeParser.service.ts`

**Fonctionnalités**:
- Détection de contenu MIME (`isMimeContent()`)
- Détection de contenu binaire (`isBinaryContent()`)
- Parsing et extraction des attachments (`parseMimeContent()`)
- Support du format Amazon simplifié (Content-Disposition + base64)
- Support des filenames encodés RFC2231

**Règles appliquées**:
- Body = priorité text/plain UTF-8, fallback html→text
- Si Content-Disposition=attachment → extraire comme attachment
- Si content-type application/pdf ou image/* → extraire comme attachment
- Si body détecté binaire → body = "[Pièce jointe reçue]"

### 3. Intégration dans les routes inbound

**Fichier**: `keybuzz-api/src/modules/inbound/routes.ts`

Ajout du parsing MIME automatique pour:
- `POST /inbound/email`
- `POST /inbound/amazon-forward`

```typescript
if (isMimeContent(body.body)) {
  const mimeResult = await parseMimeContent(body.body);
  finalBody = mimeResult.body;
  extractedAttachments = [...extractedAttachments, ...mimeResult.attachments];
}
```

---

## 📊 Résultats

### Messages migrés: 18
| Message ID | Filename | Type | Size |
|------------|----------|------|------|
| cmmkhfra5naf79bf7b33320fc | DR9083685.pdf | application/pdf | 7266 |
| cmmkgwhwv4e3379d8687ee224 | Facture_SYSFR1129156 (1).pdf | application/pdf | 7239 |
| cmmkh7vep4d57598220b3a670 | DR9083685.pdf | application/pdf | 7267 |
| cmmkgjmaedfe70453b3e816c1 | e-mandat.pdf | application/pdf | 7268 |
| cmmkfr009vffc8048696b1ef3 | Social_Profile_Mirko.png | image/png | 7254 |
| ... | ... | ... | ... |

### Body après correction:
```
[Pièce jointe reçue]
```

### API Response:
```json
{
  "body": "[Pièce jointe reçue]",
  "attachments": [
    {
      "id": "att-a76187614108c5fe",
      "filename": "Facture_SYSFR1129156 (1).pdf",
      "mimeType": "application/pdf",
      "sizeBytes": 7239,
      "downloadUrl": "/attachments/att-a76187614108c5fe"
    }
  ]
}
```

---

## ⚠️ Limitations Connues

### Messages existants migrés
- Les métadonnées des attachments sont en DB
- Le contenu base64 original a été perdu lors de la migration
- Status = `pending_storage` (téléchargement non fonctionnel)

### Nouveaux messages
- Le parsing MIME fonctionne correctement
- Les attachments seront uploadés vers MinIO si configuré
- Sinon, stockés en `pending_storage` avec métadonnées

---

## 🔧 Fichiers Modifiés

| Fichier | Action |
|---------|--------|
| `keybuzz-api/src/services/mimeParser.service.ts` | **Créé** - Service de parsing MIME |
| `keybuzz-api/src/modules/inbound/routes.ts` | Modifié - Intégration du parser |
| `keybuzz-api/package.json` | Modifié - Ajout de mailparser |

---

## 🧪 Test du Parser

```bash
$ npx ts-node src/test_parser.ts

=== Is MIME content? ===
true

=== Parsing... ===
[MimeParser] Found attachment filename: DR9083685.pdf
[MimeParser] Extracted 128 base64 lines, size: 7266 bytes

=== Parse Result ===
Body: [Pièce jointe reçue]
Attachments count: 1

Attachment: DR9083685.pdf
  MIME type: application/pdf
  Size: 7266 bytes
```

---

## 📦 Déploiement

- **Image**: `ghcr.io/keybuzzio/keybuzz-api:v0.1.110-dev`
- **Déployé**: 2026-01-16 22:45 UTC

---

## 🟢 Verdict Final

| Critère | Statut |
|---------|--------|
| Body clean (pas de MIME brut) | ✅ |
| Attachments extraits en DB | ✅ |
| API retourne attachments[] | ✅ |
| Nouveaux messages parsés correctement | ✅ |
| Messages existants: métadonnées OK | ✅ |
| Messages existants: téléchargement | ⚠️ Contenu perdu |

**Résultat**: ✅ **MIME PARSER FONCTIONNEL**

Les futurs messages Amazon avec pièces jointes seront correctement parsés et les attachments seront visibles dans l'UI avec lien de téléchargement (si MinIO configuré).
