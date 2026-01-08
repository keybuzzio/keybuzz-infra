# PH15-INBOUND-MESSAGE-NORMALIZATION-01 — Rapport

**Date** : 2026-01-08  
**Statut** : ✅ TERMINÉ

---

## Résumé

Tous les messages inbound (Amazon aujourd'hui, autres marketplaces demain) sont maintenant normalisés avant insertion dans l'Inbox :
- **Body propre** : texte humain uniquement, sans artefacts techniques
- **Metadata riche** : contexte marketplace, orderRef, liens, brut tronqué

---

## 1. Point d'Entrée

**Service** : `keybuzz-backend/src/modules/webhooks/inboxConversation.service.ts`

**Fonction centrale** : `normalizeInboundMessage()` dans `messageNormalizer.service.ts`

Appelée **obligatoirement** avant insertion du message en DB produit.

---

## 2. Normalisation MIME

| Étape | Action |
|-------|--------|
| Quoted-printable | Décode `=XX` et soft line breaks |
| HTML | Convertit en texte (strip tags, decode entities) |
| Whitespace | Normalise sauts de ligne, trim |

---

## 3. Extraction Amazon

### Marqueurs Reconnus

**Début** :
- `------------- Message:`
- `---- Message original ----`
- `Message de l'acheteur :`
- `Buyer Message:`

**Fin** :
- `------------- Fin du message`
- `------------- End of message`
- `---`

### Patterns de Nettoyage

| Pattern | Supprimé |
|---------|----------|
| MIME boundaries | `------=_Part_*` |
| Headers techniques | `Content-Type`, `Content-Transfer-Encoding` |
| Footer juridique | `Droits d'auteur`, `Copyright` |
| Footer Amazon | `Important :`, `Ne pas répondre`, `Cet e-mail a-t-il été utile` |
| Liens tracking | URLs sellercentral, feedback, messaging |
| Email quoted | `> ...`, `On ... wrote:` |

---

## 4. Exemple Avant/Après

### AVANT (body brut)

```
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: quoted-printable
MIME-Version: 1.0

------=_Part_1234567_890123456.1234567890123

------------- Message:

Bonjour,

Je n'ai pas reçu ma commande 405-1234567-8901234. Pouvez-vous me dire où elle en est ?

Merci d'avance,
Client Test

------------- Fin du message

Important : Ne répondez pas directement à ce message...

https://sellercentral.amazon.fr/messaging/thread/abc123

Droits d'auteur © 2026 Amazon.com, Inc...
Cet e-mail a-t-il été utile ? [Oui] [Non]

------=_Part_1234567_890123456.1234567890123--
```

### APRÈS (body normalisé)

```
Bonjour,

Je n'ai pas reçu ma commande 405-1234567-8901234. Pouvez-vous me dire où elle en est ?

Merci d'avance,
Client Test
```

**Résultat** : 125 caractères (vs ~600+ brut)

---

## 5. Structure Metadata

```json
{
  "source": "AMAZON",
  "extractionMethod": "amazon_markers",
  "parserVersion": "v1.0",
  "rawSubject": "Question concernant la commande 405-1234567-8901234",
  "rawFrom": "Amazon Customer via marketplace.amazon.fr <abcd1234@marketplace.amazon.fr>",
  "orderRef": "405-1234567-8901234",
  "marketplaceLinks": [
    "https://sellercentral.amazon.fr/messaging/thread/abc123"
  ],
  "rawPreview": "Content-Type: text/plain; charset=UTF-8..."
}
```

### Champs

| Champ | Description |
|-------|-------------|
| `source` | AMAZON, FNAC, CDISCOUNT, EMAIL, OTHER |
| `extractionMethod` | amazon_markers, generic_cleanup, email_cleanup, raw |
| `parserVersion` | Version du parser (v1.0) |
| `orderRef` | Numéro de commande extrait |
| `marketplaceLinks` | Liens marketplace trouvés (max 5) |
| `rawPreview` | Premiers 4KB du brut pour debug |

---

## 6. Schéma DB Modifié

**Table** : `messages` (DB keybuzz product)

```sql
ALTER TABLE messages ADD COLUMN metadata JSONB DEFAULT '{}';
```

---

## 7. Fallback Générique

Si aucun marqueur Amazon n'est trouvé :

1. Supprime les patterns connus (footers, MIME, etc.)
2. Garde les 1-3 premiers paragraphes significatifs
3. Tronque à 2000 caractères max

**Ne jamais afficher** :
- Footer juridique
- Liens tracking
- HTML brut
- Quoted-printable non décodé

---

## 8. Tests E2E

### Requête Test

```bash
curl -X POST https://backend-dev.keybuzz.io/api/v1/webhooks/inbound-email \
  -H "Content-Type: application/json" \
  -H "X-Internal-Key: ***" \
  -d @test_amazon_message.json
```

### Réponse

```json
{
  "success": true,
  "conversation": {
    "conversationId": "cmmk5x1ue51b79525179799ba",
    "messageId": "cmmk5x1uejc9bf9a91b90c63f",
    "isNew": true,
    "normalized": {
      "cleanBodyLength": 125,
      "extractionMethod": "amazon_markers"
    }
  }
}
```

### Vérification DB

```sql
SELECT body, metadata->>'extractionMethod' as method
FROM messages WHERE id = 'cmmk5x1uejc9bf9a91b90c63f';

-- body: "Bonjour, Je n'ai pas reçu ma commande..."
-- method: "amazon_markers"
```

---

## 9. Versions

| Composant | Version |
|-----------|---------|
| keybuzz-backend | v1.0.6-dev |
| Parser Version | v1.0 |
| Commit | 36defe4 |

---

## 10. Fichiers Créés/Modifiés

| Fichier | Action |
|---------|--------|
| `src/modules/webhooks/messageNormalizer.service.ts` | CRÉÉ |
| `src/modules/webhooks/inboxConversation.service.ts` | MODIFIÉ |
| `package.json` | MODIFIÉ (version 1.0.6) |
| `keybuzz.messages.metadata` | ALTER TABLE ADD COLUMN |

---

## 11. Résultat Inbox

L'Inbox KeyBuzz affiche maintenant :
- ✅ Message propre (texte humain uniquement)
- ✅ Aucun footer Amazon
- ✅ Aucune boundary MIME
- ✅ Aucun lien parasite
- ✅ OrderRef extrait automatiquement

---

**Fin du rapport PH15-INBOUND-MESSAGE-NORMALIZATION-01**
