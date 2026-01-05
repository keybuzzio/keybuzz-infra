# PH11-PRODUCT-03D â€” Fix badge source (HUMAN/AI) + non-rÃ©gression notes

## Date: 2026-01-05

## RÃ©sumÃ© du bug

**SymptÃ´me** : Un message envoyÃ© par un humain (KeyBuzz Agent) apparaissait avec un badge IA aprÃ¨s refresh.

**Cause racine** : La fonction `detectMessageSource()` dans le Client utilisait une heuristique basÃ©e sur `author.includes('keybuzz')` qui retournait `ai_auto` pour TOUS les messages dont l'auteur contenait "keybuzz", y compris "KeyBuzz Agent" (humain).

## Fix appliquÃ©

### Client (`keybuzz-client`)

1. **`src/features/ai-ui/types.ts`** - `detectMessageSource()` :
   - Ajout paramÃ¨tre `messageSource` (de l'API) comme source de vÃ©ritÃ©
   - Si `messageSource === 'AI'` â†’ badge IA
   - Si `messageSource === 'HUMAN'` â†’ badge humain
   - Fallback heuristique SEULEMENT si `messageSource` absent (vieux messages)
   - Heuristique plus stricte : `author.includes('keybuzz ia')` au lieu de `author.includes('keybuzz')`

2. **`app/inbox/InboxTripane.tsx`** :
   - Ajout `messageSource` dans interface `LocalMessage`
   - Mapping `message_source` de l'API vers `messageSource`
   - Passage de `messageSource` au composant `MessageSourceBadge`

3. **`src/features/ai-ui/MessageSourceBadge.tsx`** :
   - Interface mise Ã  jour pour accepter `messageSource`

### Admin (`keybuzz-admin`)

1. **`src/features/messages/components/MessageBubble.tsx`** :
   - Condition simplifiÃ©e : `messageSource === 'AI'` uniquement
   - Suppression du fallback heuristique `authorName.includes('KeyBuzz IA')`

## Versions dÃ©ployÃ©es

| Service | Version | Digest |
|---------|---------|--------|
| keybuzz-client | v0.2.16-dev | sha256:135a2130b83f... |
| keybuzz-admin | v1.0.57-dev | sha256:2e843d9430db... |

## Tests E2E

### Test A â€” Message humain
```
ID: msg-1767595903763-u8vgnkvr7
direction: outbound
visibility: public
message_source: HUMAN
author_name: KeyBuzz Agent
```
âœ… Badge humain (pas IA) aprÃ¨s refresh

### Test B â€” Note interne
```
ID: msg-1767595939800-s41bxxkqf
direction: internal_note
visibility: internal_note
message_source: HUMAN
author_name: KeyBuzz Agent
```
âœ… Reste note interne (jaune) aprÃ¨s refresh

### Test C â€” Message IA
```
ID: msg-ia-test-01
direction: outbound
visibility: public
message_source: AI
author_name: KeyBuzz IA
```
âœ… Badge IA visible

## Commits Git

| Repo | Commit | Description |
|------|--------|-------------|
| keybuzz-infra | 63dbcfd | feat(PH11-03D): bump client v0.2.16-dev + admin v1.0.57-dev |

## Fichiers de logs

```
/opt/keybuzz/logs/ph11-product/ph11-product-03d/
â”œâ”€â”€ 00_start.txt
â”œâ”€â”€ 01_db_messages.txt
â”œâ”€â”€ 02_api_response.json
â”œâ”€â”€ test_a_reply.json
â”œâ”€â”€ test_a_db.txt
â”œâ”€â”€ test_b_reply.json
â”œâ”€â”€ test_b_db.txt
â””â”€â”€ test_c_db.txt
```

## Pourquoi Ã§a arrivait

L'UI Client dÃ©duisait la source du message via le nom de l'auteur (`authorName`). Comme tous les messages agents avaient `authorName = "KeyBuzz Agent"` (contenant "keybuzz"), ils Ã©taient incorrectement classÃ©s comme IA.

La correction utilise maintenant `message_source` de l'API (HUMAN/AI/SYSTEM/TEMPLATE) comme vÃ©ritÃ© absolue.

---

**DEV ONLY â€” PROD INTACT âœ…**