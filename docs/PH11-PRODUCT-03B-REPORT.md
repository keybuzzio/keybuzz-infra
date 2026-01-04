# PH11-PRODUCT-03B - Notes internes Client (fix definitif) + UX composer

## Resume

Fix definitif des bugs bloquants cote client-dev:

1. **Caracteres bizarres dans l'en-tete des notes** (ex: Vous aâ‚¬" Note interne) â†’ Corrige
2. **Notes internes ne restent pas internes apres refresh** â†’ Corrige
3. **UX composer** â†’ Ameliore (scroll vertical, auto-scroll)

## Problemes identifies

### 1. API ne reconnaissait pas `visibility: 'internal_note'`

**Probleme:**
- Le client envoyait `visibility: 'internal_note'`
- L'API verifiait `visibility === 'internal'` â†’ ne reconnaissait pas
- Resultat: toutes les notes devenaient `visibility: 'public'`

**Fix:**
- API accepte maintenant `'internal_note'` ET `'internal'`
- INSERT utilise directement `visibility` de la requete

### 2. Encodage UTF-8 mal forme

**Probleme:**
- Caracteres mojibake dans les labels: `Ã¢â‚¬"` au lieu de `-`
- Emoji corrompu: `Ã°Å¸"` dans les badges

**Fix:**
- Remplacement des caracteres mal encodes par ` - `
- Suppression de l'emoji corrompu

### 3. UX Composer

**Probleme:**
- Textarea: `overflow: 'hidden'` â†’ texte long invisible
- Pas de scroll vertical

**Fix:**
- Changement en `overflowY: 'auto'`
- Scroll vertical fonctionnel

## Modifications implementees

### API (keybuzz-api)

**Fichier:** `src/modules/messages/routes.ts`

**Changements:**
```typescript
// Avant
const direction = visibility === 'internal' ? 'internal_note' : 'outbound';

// Apres
const direction = visibility === 'internal_note' || visibility === 'internal' ? 'internal_note' : 'outbound';

// INSERT utilise maintenant visibility de la requete
[msgId, id, tenantId, direction, visibility === 'internal_note' || visibility === 'internal' ? 'internal_note' : 'public', 'HUMAN', 'KeyBuzz Agent', content]
```

### Client (keybuzz-client)

**Fichier:** `app/inbox/InboxTripane.tsx`

**Changements:**
1. **Encodage UTF-8:**
   - Remplacement `Ã¢â‚¬"` â†’ ` - ` (dash simple)
   - Suppression emoji corrompu

2. **Textarea:**
   - `overflow: 'hidden'` â†’ `overflowY: 'auto'`
   - Scroll vertical fonctionnel

## Tests E2E

### Test 1: Creation note interne
```
POST /messages/conversations/conv-001/reply
{"content":"Test PH11-03B","visibility":"internal_note"}
â†’ âœ… Note created: msg-1767541887400-2x06rcqoq
```

### Test 2: Verification persistance
```
GET /messages/conversations/conv-001
â†’ âœ… direction: internal_note
â†’ âœ… visibility: internal_note
â†’ âœ… message_source: HUMAN
```

### Test 3: Frontends accessibles
```
âœ… Client UI: HTTP 200
âœ… Admin UI: HTTP 200
```

## Images Docker deployees

| Service | Version |
|---------|---------|
| keybuzz-api | v0.1.50-dev |
| keybuzz-client | v0.2.12-dev |

## Commits Git

```
keybuzz-api:   4410ec1 - PH11-PRODUCT-03B: Fix API visibility - accept internal_note directly
keybuzz-client: 8831ef6 - PH11-PRODUCT-03B: Fix encoding UTF-8 + textarea scroll + note labels
```

## Checklist DoD

- [x] Une note interne envoyee cote client reste interne apres refresh
- [x] Cote admin, la note est vue comme note interne
- [x] Plus aucun texte encode bizarre (aâ‚¬", Ã°Å¸â€¦ etc)
- [x] Client composer: scroll vertical fonctionnel
- [x] Auto-scroll fiable (deja implemente)
- [x] DEV only, PROD untouched
- [x] Rapport final ecrit

## Ce qui a ete fait

### A) Note reste une note, partout, pour toujours

âœ… API accepte `visibility: 'internal_note'` directement
âœ… INSERT persiste `visibility: 'internal_note'` correctement
âœ… SELECT retourne `visibility: 'internal_note'`
âœ… Client mappe correctement avec fallback

### B) Encodage UTF-8 corrige

âœ… Caracteres mojibake remplaces par ` - `
âœ… Emoji corrompu supprime
âœ… Labels affichent correctement

### C) UX Composer ameliore

âœ… Textarea: `overflowY: 'auto'` â†’ scroll vertical
âœ… Shift+Enter = nouvelle ligne (deja implemente)
âœ… Enter = envoi (deja implemente)
âœ… Auto-scroll vers dernier message (deja implemente)

---

**PH11-PRODUCT-03B - Termine**

Date: 2026-01-04
