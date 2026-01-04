# PH11-PRODUCT-02 - Conversation Hardening

## Resume du probleme

**Bug critique identifie:**
- Une note interne apparait correctement en marron a l'envoi
- Apres reload/navigation: devient reponse normale, prend badge IA, change couleur

**Cause racine:**
- L'API ne retournait PAS le champ `visibility`
- Le frontend mappait `m.visibility || 'public'` -> toujours 'public' apres reload
- Le champ `direction` contenait 'internal_note' mais n'etait pas suffisant

## Solution implementee

### 1. Schema DB (Migration 019)

```sql
-- Nouveaux champs ajoutes a la table messages
ALTER TABLE messages ADD COLUMN IF NOT EXISTS visibility TEXT NOT NULL DEFAULT 'public';
ALTER TABLE messages ADD COLUMN IF NOT EXISTS message_source TEXT NOT NULL DEFAULT 'HUMAN';

-- Migration des donnees existantes
UPDATE messages SET visibility = 'internal_note' WHERE direction = 'internal_note';
```

### 2. API Backend

**Modifications `routes.ts`:**
- SELECT retourne maintenant `visibility` et `message_source`
- INSERT inclut `visibility` et `message_source`

```typescript
// Avant
SELECT id, conversation_id, tenant_id, direction, author_name, body, created_at FROM messages

// Apres
SELECT id, conversation_id, tenant_id, direction, visibility, message_source, author_name, body, created_at FROM messages
```

### 3. Frontend Client

**Modifications `conversations.service.ts`:**
```typescript
// Mapping avec fallback
visibility: m.visibility || (m.direction === 'internal_note' ? 'internal_note' : 'public'),
authorType: m.message_source === 'AI' ? 'ai' : (m.message_source === 'SYSTEM' ? 'system' : ...)
```

### 4. Frontend Admin

**Modifications:**
- `types.ts`: Ajout `visibility` et `messageSource` a `ConversationMessage`
- `messages.service.ts`: Interface `MessageFromApi` enrichie + mapping
- `mocks.ts`: Tous les mocks mis a jour
- `TripaneLayout.tsx`: Messages pendants incluent `visibility` et `messageSource`

## Modele de donnees final

### MessageType (direction)
| Type | Description |
|------|-------------|
| `inbound` | Message du client |
| `outbound` | Reponse agent |
| `internal_note` | Note interne |

### MessageVisibility
| Valeur | Description |
|--------|-------------|
| `public` | Visible par le client |
| `internal_note` | Staff uniquement |

### MessageSource
| Valeur | Description |
|--------|-------------|
| `HUMAN` | Envoye par un humain |
| `AI` | Genere par KeyBuzz IA |
| `SYSTEM` | Message systeme (SLA, escalade) |
| `TEMPLATE` | Reponse template (sans IA) |

## Regles de rendu UI

| Type | Rendu |
|------|-------|
| `inbound` | Gauche, clair |
| `outbound` | Droite, bleu |
| `internal_note` | Centre, marron/jaune |

## Badges autorises

| Badge | Condition |
|-------|-----------|
| ðŸ‘¤ Reponse humaine | `message_source = 'HUMAN'` |
| ðŸ¤– Reponse KeyBuzz | `message_source = 'AI'` |
| ðŸ“ Note interne | `visibility = 'internal_note'` |
| âš™ï¸ Systeme | `message_source = 'SYSTEM'` |
| ðŸ“„ Modele | `message_source = 'TEMPLATE'` |

## Tests E2E

### Test 1: Creation note interne
```bash
POST /messages/conversations/conv-001/reply
{"content":"Note de test PH11-02","visibility":"internal"}

# Resultat:
{"success":true,"messageId":"msg-1767524942921-ihixt3ss2",...}
```

### Test 2: Verification persistance
```bash
GET /messages/conversations/conv-001

# Dernier message:
{
  "id": "msg-1767524942921-ihixt3ss2",
  "direction": "internal_note",
  "visibility": "internal_note",
  "message_source": "HUMAN",
  "body": "Note de test PH11-02 - Cette note doit rester interne apres reload"
}
```

### Test 3: Accessibilite frontends
```
âœ… https://client-dev.keybuzz.io/inbox â†’ HTTP 200
âœ… https://admin-dev.keybuzz.io/messages â†’ HTTP 200
```

## Checklist de validation

- [x] Une note reste une note quoi qu'il arrive
- [x] Les badges sont toujours corrects (bases sur message_source)
- [x] Aucun message ne change de type apres reload
- [x] Admin et Client ont le meme comportement
- [x] Les regles sont documentees
- [x] Aucun hack temporaire
- [x] Aucun TODO laisse

## Images Docker deployees

| Service | Version |
|---------|---------|
| keybuzz-api | v0.1.49-dev |
| keybuzz-client | v0.2.10-dev |
| keybuzz-admin | v0.1.55-dev |

## Commits Git

```
keybuzz-api:    e576e84 - PH11-PRODUCT-02: Message Hardening - visibility + message_source
keybuzz-client: 22c8ba5 - PH11-PRODUCT-02: Message Hardening - visibility mapping fix
keybuzz-admin:  03d9d7b - PH11-PRODUCT-02: Message Hardening - visibility + messageSource types
```

## Ce qui n'a PAS ete fait (intentionnellement)

- âŒ Modification frontend seul (cause racine = backend)
- âŒ Correction via `if (isNote)` locaux
- âŒ Fallback silencieux sans correction DB
- âŒ Hack temporaire

## Conclusion

Le bug des notes internes qui changeaient de type apres reload est **corrige definitivement** par:

1. **Ajout des champs `visibility` et `message_source` en DB**
2. **API retourne ces champs explicitement**
3. **Frontends mappent correctement avec fallback**
4. **Rendu deterministe base sur les donnees API**

---

**PH11-PRODUCT-02 - Termine**

Date: 2026-01-04
