# PH15-AMAZON-THREADING-ENCODING-01 — Rapport

**Date** : 2026-01-08  
**Statut** : ✅ TERMINÉ

---

## Résumé

1. **Encodage fixé** : Les caractères mojibake (Ã§a → ça) sont maintenant corrigés automatiquement
2. **Threading Amazon** : Plusieurs messages d'un même échange sont regroupés dans une seule conversation

---

## 1. Fix Encodage (Mojibake)

### Problème

Les emails Amazon arrivent parfois avec un encodage corrompu :
- `Ã§a` au lieu de `ça`
- `Ã©tÃ©` au lieu de `été`
- `trÃ¨s` au lieu de `très`

### Solution

Ajout d'une fonction `fixEncoding()` qui :

1. **Détecte le mojibake** : Recherche des patterns comme `Ã` suivi de caractères Latin1
2. **Re-encode** : Essaie de convertir Latin1 → UTF-8 si détecté
3. **Applique des remplacements** : Table de correspondance pour les cas courants

### Exemple Avant/Après

**AVANT** :
```
Ã§a fait longtemps que j'attends. C'est Ã©tÃ© et il fait trÃ¨s chaud.
```

**APRÈS** :
```
ça fait longtemps que j'attends. C'est été et il fait très chaud.
```

### Test E2E

```json
{
  "normalized": {
    "cleanBodyLength": 122,
    "encodingFixed": true
  }
}
```

---

## 2. Threading Amazon

### Problème

Chaque message Amazon créait une nouvelle conversation, même si c'était une réponse dans le même échange.

### Solution

Ajout d'une `threadKey` stable extraite dans cet ordre de priorité :

| Priorité | Source | Format |
|----------|--------|--------|
| 1 | Headers Amazon | `header:<threadId>` |
| 2 | URL Seller Central (`?t=...`) | `sc:<threadId>` |
| 3 | Order Reference | `order:<orderRef>` |
| 4 | Hash (from + subject) | `hash:<12chars>` |

### Schéma DB

```sql
ALTER TABLE conversations ADD COLUMN thread_key TEXT;
CREATE INDEX idx_conversations_thread_key ON conversations(tenant_id, channel, thread_key);
```

### Logique de Grouping

```
1. Rechercher conversation existante par thread_key
2. Si pas trouvée, rechercher par order_ref
3. Si pas trouvée, créer nouvelle conversation
4. Stocker thread_key dans la conversation
```

### Test E2E : 2 Messages → 1 Conversation

**Message 1** :
```json
{
  "conversationId": "cmmk5y8qdk8bec251cfb09182",
  "isNew": true,
  "isThreaded": false,
  "normalized": {
    "threadKey": "sc:THREAD-XYZ-001"
  }
}
```

**Message 2** (même thread) :
```json
{
  "conversationId": "cmmk5y8qdk8bec251cfb09182",  // ← MÊME ID !
  "isNew": false,
  "isThreaded": true,  // ← THREADED !
  "normalized": {
    "threadKey": "sc:THREAD-XYZ-001"
  }
}
```

### Vérification DB

```sql
SELECT id, subject, thread_key FROM conversations 
WHERE id = 'cmmk5y8qdk8bec251cfb09182';

-- Résultat:
-- id                         | subject                                   | thread_key
-- cmmk5y8qdk8bec251cfb09182 | Question sur commande 789-1111111-2222222 | sc:THREAD-XYZ-001

SELECT id, body, created_at FROM messages 
WHERE conversation_id = 'cmmk5y8qdk8bec251cfb09182';

-- Résultat: 2 messages dans la même conversation
```

---

## 3. Metadata Enrichie

La metadata stockée inclut maintenant :

```json
{
  "source": "AMAZON",
  "extractionMethod": "amazon_markers",
  "parserVersion": "v1.1",
  "threadKey": "sc:THREAD-XYZ-001",
  "orderRef": "789-1111111-2222222",
  "encodingFixed": true,
  "marketplaceLinks": [
    "https://sellercentral.amazon.fr/messaging/thread/ABC123?t=THREAD-XYZ-001"
  ]
}
```

---

## 4. Versions

| Composant | Version |
|-----------|---------|
| keybuzz-backend | v1.0.7-dev |
| Parser Version | v1.1 |
| Commit | 7b445d8 |

---

## 5. Fichiers Modifiés

| Fichier | Action |
|---------|--------|
| `messageNormalizer.service.ts` | MODIFIÉ (encoding fix + threadKey) |
| `inboxConversation.service.ts` | MODIFIÉ (grouping par threadKey) |
| `package.json` | MODIFIÉ (version 1.0.7) |
| `keybuzz.conversations.thread_key` | ALTER TABLE ADD COLUMN |

---

## 6. Résultat Inbox

L'Inbox KeyBuzz affiche maintenant :
- ✅ Caractères correctement encodés (ça, été, très)
- ✅ Messages groupés par thread
- ✅ Thread key visible dans metadata
- ✅ Ordre chronologique préservé

---

**Fin du rapport PH15-AMAZON-THREADING-ENCODING-01**
